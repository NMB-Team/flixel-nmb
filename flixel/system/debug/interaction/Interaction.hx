package flixel.system.debug.interaction;

import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.display.DisplayObject;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.FlxPointer;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.debug.Window;
import flixel.system.debug.interaction.tools.Transform;
import flixel.system.debug.interaction.tools.Eraser;
import flixel.system.debug.interaction.tools.LogBitmap;
import flixel.system.debug.interaction.tools.Mover;
import flixel.system.debug.interaction.tools.Pointer;
import flixel.system.debug.interaction.tools.Tool;
import flixel.system.debug.interaction.tools.ToggleBounds;
import flixel.system.debug.interaction.tools.TrackObject;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
#if !(FLX_NATIVE_CURSOR && FLX_MOUSE)
import openfl.display.Bitmap;
#end

/**
 * Adds a new functionality to Flixel debugger that allows any object
 * on the screen to be dragged, moved or deleted while the game is
 * still running.
 *
 * @author	Fernando Bevilacqua (dovyski@gmail.com)
 */
class Interaction extends Window
{
	static inline final BUTTONS_PER_LINE = 2;
	static inline final SPACING = 25;
	static inline final PADDING = 10;

	public var activeTool(default, null):Tool;
	public var selectedItems(default, null):FlxTypedGroup<FlxObject> = new FlxTypedGroup();

	public var flixelPointer:FlxPoint = new FlxPoint();
	public var pointerJustPressed:Bool = false;
	public var pointerJustReleased:Bool = false;
	public var pointerPressed:Bool = false;

	/**
	 * Control if an outline should be drawn on selected elements.
	 * Tools can set this property to `false` if they want to draw custom
	 * selection marks, for instance.
	 */
	public var shouldDrawItemsSelection:Bool = true;

	/**
	 * Whether or not the user is using a mac keyboard, determines whether to use command or ctrl
	 */
	public final macKeyboard:Bool =
		#if mac
		true;
		#elseif (js && html5)
		untyped js.Syntax.code("/AppleWebKit/.test (navigator.userAgent) && /Mobile\\/\\w+/.test (navigator.userAgent) || /Mac/.test (navigator.platform)");
		#else
		false;
		#end

	var _container:Sprite;
	var _customCursor:Sprite;
	var _tools:Array<Tool> = [];
	var _turn:Int = 2;
	var _keysDown:Map<Int, Bool> = new Map();
	var _keysUp:Map<Int, Int> = new Map();
	var _wasMouseVisible:Bool;
	var _wasUsingSystemCursor:Bool;
	var _debuggerInteraction:Bool = false;
	var _flixelPointer:FlxPointer = new FlxPointer();

	public function new(container:Sprite)
	{
		super("Tools", Icon.interactive, 40, 25, false);
		reposition(2, 100);
		_container = container;

		_customCursor = new Sprite();
		_customCursor.mouseEnabled = false;
		_customCursor.mouseChildren = false;
		_container.addChild(_customCursor);

		// Add all built-in tools
		addTool(new Pointer());
		addTool(new Mover());
		addTool(new Eraser());
		addTool(new Transform());
		addTool(new ToggleBounds());
		addTool(new LogBitmap());
		addTool(new TrackObject());

		FlxG.signals.postDraw.add(postDraw);
		FlxG.debugger.visibilityChanged.add(handleDebuggerVisibilityChanged);

		FlxG.stage.addEventListener(MouseEvent.MOUSE_MOVE, updateMouse);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_DOWN, handleMouseClick);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_UP, handleMouseClick);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyEvent);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, handleKeyEvent);

		_container.addEventListener(MouseEvent.MOUSE_OVER, handleMouseInDebugger);
		_container.addEventListener(MouseEvent.MOUSE_OUT, handleMouseInDebugger);
	}

	function handleDebuggerVisibilityChanged():Void
	{
		if (FlxG.debugger.visible)
			saveSystemCursorInfo();
		else
			restoreSystemCursor();
	}

	function updateMouse(event:MouseEvent):Void
	{
		#if js // openfl/openfl#1305
		if (event.stageX == null || event.stageY == null)
			return;
		#end

		_customCursor.x = event.stageX;
		_customCursor.y = event.stageY;

		#if FLX_MOUSE
		// Calculate in-game coordinates based on mouse position and camera.
		_flixelPointer.setRawPositionUnsafe(Std.int(FlxG.game.mouseX), Std.int(FlxG.game.mouseY));

		// Store Flixel mouse coordinates to speed up all
		// internal calculations (overlap, etc)
		flixelPointer.x = _flixelPointer.x;
		flixelPointer.y = _flixelPointer.y;
		#end
	}

	function handleMouseClick(event:MouseEvent):Void
	{
		// Did the user click a debugger UI element instead of performing
		// a click related to a tool?
		if (event.type == MouseEvent.MOUSE_DOWN && objectBelongsToDebugger(event.target))
			return;

		pointerJustPressed = event.type == MouseEvent.MOUSE_DOWN;
		pointerJustReleased = event.type == MouseEvent.MOUSE_UP;

		if (pointerJustPressed)
			pointerPressed = true;
		else if (pointerJustReleased)
			pointerPressed = false;
	}

	function objectBelongsToDebugger(object:openfl.utils.Object):Bool
	{
		return object is DisplayObject && belongsToDebugger(cast object);
	}

	function belongsToDebugger(object:DisplayObject):Bool
	{
		if (object == null)
			return false;
		else if ((object is FlxDebugger))
			return true;
		return belongsToDebugger(object.parent);
	}

	function handleMouseInDebugger(event:MouseEvent):Void
	{
		// If we are not active, we don't really care about
		// mouse events in the debugger.
		if (!isActive())
			return;

		if (event.type == MouseEvent.MOUSE_OVER)
			_debuggerInteraction = true;
		else if (event.type == MouseEvent.MOUSE_OUT)
			_debuggerInteraction = false;

		event.stopPropagation();
	}

	function handleKeyEvent(event:KeyboardEvent):Void
	{
		if (event.type == KeyboardEvent.KEY_DOWN)
			_keysDown.set(event.keyCode, true);
		else if (event.type == KeyboardEvent.KEY_UP)
		{
			_keysDown.set(event.keyCode, false);
			_keysUp.set(event.keyCode, _turn);
		}
	}

	function countToolsWithUIButton():Int
	{
		var count = 0;
		for (tool in _tools)
			if (tool.button != null)
				count++;
		return count;
	}

	/**
	 * Add a new tool to the interaction system.
	 *
	 * Any tool added to the interaction system must extend the class
	 * `flixel.system.debug.interaction.tools.Tool`. The class contains several methods
	 * that can be used to provide new funcionalities to the interaction, or they can be
	 * overridden to alter existing behavior. For instance, tools can draw things on the
	 * screen, they can be activated when the user clicks a button, and so on. Check
	 * the classes in the package `flixel.system.debug.interaction.tools` for examples.
	 *
	 * @param   tool  instance of a tool that will be added to the interaction system.
	 */
	public function addTool(tool:Tool):Void
	{
		tool.init(this);
		_tools.push(tool);

		// If the tool has no button, it is not added to the interaction window
		var button = tool.button;
		if (button == null)
			return;

		final buttons = countToolsWithUIButton();
		final row = Math.ceil(buttons / BUTTONS_PER_LINE);
		final column = (buttons - 1) % BUTTONS_PER_LINE;

		button.x = PADDING + column * SPACING;
		button.y = 20 * row;

		addChild(button);
		resizeByTotal(buttons);
	}

	/**
	 * Removes the tool, if possible. If the tool has a button, all other buttons will be moved and
	 * the containing window will be resized, if needed.
	 *
	 * @param   tool  The tool to be removed
	 * @since 5.4.0
	 */
	public function removeTool(tool)
	{
		if (!_tools.contains(tool))
			return;

		// If there's no button just remove it
		if (tool.button == null)
		{
			_tools.remove(tool);
			return;
		}

		// if there is a button move all the following buttons
		var index = _tools.indexOf(tool);
		var prevX = tool.button.x;
		var prevY = tool.button.y;

		_tools.remove(tool);
		removeChild(tool.button);

		while (index < _tools.length)
		{
			final tool = _tools[index];
			if (tool.button != null)
			{
				// store button pos
				final tempX = tool.button.x;
				final tempY = tool.button.y;
				// set to prev pos
				tool.button.x = prevX;
				tool.button.y = prevY;
				// store prev pos
				prevX = tempX;
				prevY = tempY;
			}
			index++;
		}

		autoResize();
	}

	inline function autoResize()
	{
		resizeByTotal(countToolsWithUIButton());
	}

	inline function resizeByTotal(total:Int)
	{
		final spacing = 25;
		final padding = 10;
		final rows = Math.ceil(total / BUTTONS_PER_LINE);
		final columns = Math.min(total, BUTTONS_PER_LINE);
		resize(spacing * columns + padding, spacing * rows + padding);
	}

	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		FlxG.signals.postDraw.remove(postDraw);
		FlxG.debugger.visibilityChanged.remove(handleDebuggerVisibilityChanged);

		FlxG.stage.removeEventListener(MouseEvent.MOUSE_MOVE, updateMouse);
		FlxG.stage.removeEventListener(MouseEvent.MOUSE_DOWN, handleMouseClick);
		FlxG.stage.removeEventListener(MouseEvent.MOUSE_UP, handleMouseClick);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleKeyEvent);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, handleKeyEvent);

		if (_container != null)
		{
			_container.removeEventListener(MouseEvent.MOUSE_OVER, handleMouseInDebugger);
			_container.removeEventListener(MouseEvent.MOUSE_OUT, handleMouseInDebugger);
		}

		if (_customCursor != null)
		{
			_customCursor.parent.removeChild(_customCursor);
			_customCursor = null;
		}

		_tools = FlxDestroyUtil.destroyArray(_tools);
		selectedItems = FlxDestroyUtil.destroy(selectedItems);
		flixelPointer = FlxDestroyUtil.destroy(flixelPointer);

		_keysDown = null;
		_keysUp = null;
	}

	public function isActive():Bool
	{
		return FlxG.debugger.visible && visible;
	}

	override public function update():Void
	{
		if (!isActive())
			return;

		updateCustomCursors();

		for (tool in _tools)
			tool.update();

		pointerJustPressed = false;
		pointerJustReleased = false;
		_turn++;
	}

	/**
	 * Called after the game state has been drawn.
	 */
	function postDraw():Void
	{
		if (!isActive())
			return;

		for (tool in _tools)
			tool.draw();

		if (shouldDrawItemsSelection)
			drawItemsSelection();
	}

	public function getDebugGraphics():Graphics
	{
		if (FlxG.render.blit)
		{
			FlxSpriteUtil.flashGfx.clear();
			return FlxSpriteUtil.flashGfx;
		}

		#if FLX_DEBUG
		return FlxG.camera.debugLayer.graphics;
		#end

		return null;
	}

	function drawItemsSelection():Void
	{
		var gfx:Graphics = getDebugGraphics();
		if (gfx == null)
			return;

		for (member in selectedItems)
		{
			if (member != null && member.scrollFactor != null && member.isOnScreen())
			{
				final margin = 0.5;
				final scroll = FlxG.camera.scroll;
				// Render a white rectangle centered at the selected item
				gfx.lineStyle(1.0, 0xFFFFFF, 0.75);
				gfx.drawRect(member.x - scroll.x - margin, member.y - scroll.y - margin, member.width + margin * 2, member.height + margin * 2);
			}
		}

		// Draw the debug info to the main camera buffer.
		if (FlxG.render.blit)
			FlxG.camera.buffer.draw(FlxSpriteUtil.flashGfxSprite);
	}

	/**
	 * Obtain a reference to a tool that has been added to the interaction system and is
	 * available for use. This method can be used to access information provided by any
	 * tool in the system, or to change their behavior.
	 *
	 * @param className name of the class to be fetched, e.g. `flixel.system.debug.interaction.tools.Pointer`.
	 * @return Tool reference to the first tool found whose type matches the class name provided. If no tool is found, `null` is returned.
	 */
	public function getTool(className:Class<Tool>):Tool
	{
		for (tool in _tools)
			if (Std.isOfType(tool, className))
				return tool;
		return null;
	}

	override public function toggleVisible():Void
	{
		super.toggleVisible();

		if (!visible)
		{
			// De-select any activate tool
			setActiveTool(null);
			restoreSystemCursor();
		}
	}

	public function registerCustomCursor(name:String, icon:BitmapData, offsetX = 0.0, offsetY = 0.0):Void
	{
		if (icon == null)
			return;

		#if (FLX_NATIVE_CURSOR && FLX_MOUSE)
		FlxG.mouse.registerSimpleNativeCursorData(name, icon, new Point(-offsetX, -offsetY));
		#else
		var sprite = new Sprite();
		sprite.x = offsetX;
		sprite.y = offsetY;
		sprite.visible = false;
		sprite.name = name;
		sprite.addChild(new Bitmap(icon));
		_customCursor.addChild(sprite);
		#end
	}

	public function updateCustomCursors():Void
	{
		#if FLX_MOUSE
		// Do we have an active tool and we are not interacting
		// with the debugger (e.g. moving the cursor over the
		// tools bar or the top bar)?
		if (activeTool != null && !_debuggerInteraction)
		{
			// Yes, there is an active tool. Does it has a cursor of its own?
			if (activeTool.cursor != null)
			{
				// Yep. Let's show it then
				var cursorInUse = activeTool.cursorInUse == "" ? activeTool.getName() : activeTool.cursorInUse;
				#if FLX_NATIVE_CURSOR
				// We have lag-free native cursors available, yay!
				// Activate it then.
				FlxG.mouse.setNativeCursor(cursorInUse);
				#else
				// No fancy native cursors, so we have to emulate it.
				// Let's make the currently active tool's fake cursor visible
				for (i in 0..._customCursor.numChildren)
				{
					var sprite = _customCursor.getChildAt(i);
					sprite.visible = sprite.name == cursorInUse;
				}
				if (FlxG.mouse.visible)
					FlxG.mouse.visible = false;
				#end
			}
			else
			{
				// No, the current tool has no cursor of its own.
				// Let's show the system cursor then for navigation
				FlxG.mouse.useSystemCursor = true;
			}
		}
		else
		{
			// No active tool or we are using the debugger.
			// Let's show the system cursor for navigation.
			FlxG.mouse.useSystemCursor = true;
		}
		#end
	}

	function saveSystemCursorInfo():Void
	{
		#if FLX_MOUSE
		_wasMouseVisible = FlxG.mouse.visible;
		_wasUsingSystemCursor = FlxG.mouse.useSystemCursor;
		#end
	}

	function restoreSystemCursor():Void
	{
		#if FLX_MOUSE
		FlxG.mouse.useSystemCursor = _wasUsingSystemCursor;
		FlxG.mouse.visible = _wasMouseVisible;
		_customCursor.visible = false;
		#end
	}

	public function setActiveTool(value:Tool):Void
	{
		if (activeTool != null)
		{
			activeTool.deactivate();
			activeTool.button.toggled = true;
		}

		// If the requested new tool is the same as the already active one,
		// we deactive it (toggle behavior).
		if (activeTool == value)
			value = null;

		activeTool = value;

		if (activeTool != null)
		{
			// A tool is active. Enable cursor specific cursors
			setToolsCursorVisibility(true);

			activeTool.button.toggled = false;
			activeTool.activate();
			updateCustomCursors();
		}
		else
		{
			// No tool is active. Enable the system cursor
			// so the user can click buttons, drag windows, etc.
			setSystemCursorVisibility(true);
		}

		#if FLX_MOUSE
		// Allow mouse input only if the interaction tool is visible
		// and no tool is active.
		FlxG.mouse.enabled = !isInUse();
		#end
	}

	function setSystemCursorVisibility(status:Bool):Void
	{
		#if FLX_MOUSE
		FlxG.mouse.useSystemCursor = status;
		#end
		_customCursor.visible = !status;
	}

	function setToolsCursorVisibility(status:Bool):Void
	{
		#if FLX_MOUSE
		FlxG.mouse.useSystemCursor = #if FLX_NATIVE_CURSOR status #else false #end;
		#end
		_customCursor.visible = status;

		if (status)
			return;

		// Hide any display-list-based custom cursor.
		// The proper cursor will be marked as visible
		// in the update loop.
		for (i in 0..._customCursor.numChildren)
			_customCursor.getChildAt(i).visible = false;
	}

	public function clearSelection():Void
	{
		selectedItems.clear();
	}

	public function keyPressed(key:Int):Bool
	{
		return _keysDown.get(key);
	}

	public function keyJustPressed(key:Int):Bool
	{
		var value:Int = _keysUp.get(key) == null ? 0 : _keysUp.get(key);
		return (_turn - value) == 1;
	}

	/**
	 * Informs whether the interactive debug is in use or not. Usage is defined
	 * as the interactive debug being visible and one of its tools is selected/active.
	 *
	 * @return `true` if the interactive debug is visible and one of its tools is selected/active.
	 */
	public function isInUse():Bool
	{
		return FlxG.debugger.visible && visible && activeTool != null;
	}

	/**
	 * Returns a list all items in the state and substate that are within the given area
	 *
	 * @param   state  The state to search
	 * @param   area   The rectangular area to search
	 * @since 5.6.0
	 */
	public function getItemsWithinState(state:FlxState, area:FlxRect):Array<FlxObject>
	{
		final items:Array<FlxObject> = [];

		addItemsWithinArea(items, state.members, area);
		if (state.subState != null)
			addItemsWithinState(items, state.subState, area);

		return items;
	}

	/**
	 * finds all items in the state and substate that are within the given area and
	 * adds them to the given list.
	 *
	 * @param   items  The list to add the items
	 * @param   state  The state to search
	 * @param   area   The rectangular area to search
	 * @since 5.6.0
	 */
	public function addItemsWithinState(items:Array<FlxObject>, state:FlxState, area:FlxRect):Void
	{
		addItemsWithinArea(items, state.members, area);
		if (state.subState != null)
			addItemsWithinState(items, state.subState, area);
	}

	/**
	 * Finds and returns top-most item in the state and substate within the given area
	 *
	 * @param   state  The state to search
	 * @param   area   The rectangular area to search
	 * @since 5.6.0
	 */
	public function getTopItemWithinState(state:FlxState, area:FlxRect):FlxObject
	{
		if (state.subState != null)
			return getTopItemWithinState(state.subState, area);

		return getTopItemWithinArea(state.members, area);
	}

	function isOverObject(object:FlxObject, area:FlxRect):Bool
	{
		return area.overlaps(object.getHitbox(FlxRect.weak()));
	}

	function isOverSprite(sprite:FlxSprite, area:FlxRect):Bool
	{
		// Ignore sprites' alpha when clicking a point
		return (area.width > 1 || area.height > 1)
			? isOverObject(sprite, area)
			: sprite.pixelsOverlapPoint(flixelPointer, 0x10);
	}

	/**
	 * Find all items within an area. In order to improve performance and reduce temporary allocations,
	 * the method has no return, you must pass an array where items will be placed. The method decides
	 * if an item is within the searching area or not by checking if the item's hitbox (obtained from
	 * `getHitbox()`) overlaps the area parameter.
	 *
	 * @param   items    Array where the method will place all found items. Any previous content in the array will be preserved.
	 * @param   members  Array where the method will recursively search for items.
	 * @param   area     A rectangle that describes the area where the method should search within.
	 * @since 5.6.0
	 */
	public function addItemsWithinArea(items:Array<FlxObject>, members:Array<FlxBasic>, area:FlxRect):Void
	{
		// we iterate backwards to get the sprites on top first
		var i = members.length;
		while (i-- > 0)
		{
			final member = members[i];
			// Ignore invisible or non-existent entities
			if (member == null || !member.visible || !member.exists)
				continue;

			final group = FlxTypedGroup.resolveSelectionGroup(member);
			if (group != null)
			{
				addItemsWithinArea(items, group.members, area);
			}
			else if (member is FlxSprite)
			{
				final sprite:FlxSprite = cast member;
				if (isOverSprite(sprite, area))
					items.push(sprite);
			}
			else if (member is FlxObject)
			{
				final object:FlxObject = cast member;
				if (isOverObject(object, area))
					items.push(object);
			}
		}
	}

	/**
	 * Searches the members for the top-most object inside the given rectangle
	 *
	 * @param   members  The list of FlxObjects or FlxGroups
	 * @param   area     The rectangular area to search
	 * @return  The top-most item
	 * @since 5.6.0
	 */
	@:access(flixel.group.FlxTypedGroup)
	public function getTopItemWithinArea(members:Array<FlxBasic>, area:FlxRect):FlxObject
	{
		// we iterate backwards to get the sprites on top first
		var i = members.length;
		while (i-- > 0)
		{
			final member = members[i];
			// Ignore invisible or non-existent entities
			if (member == null || !member.visible || !member.exists)
				continue;

			final group = FlxTypedGroup.resolveGroup(member);
			if (group != null)
			{
				final result = getTopItemWithinArea(group.members, area);
				if (result != null)
					return result;
			}

			if (member is FlxSprite)
			{
				final sprite:FlxSprite = cast member;
				if (isOverSprite(sprite, area))
					return sprite;
			}
			else if (member is FlxObject)
			{
				final object:FlxObject = cast member;
				if (isOverObject(object, area))
					return object;
			}
		}
		return null;
	}

	public function toDebugX(worldX:Float, camera:FlxCamera)
	{
		if (FlxG.render.tile)
			return camera.canvas.localToGlobal(new Point(worldX, 0)).x;
		else
			@:privateAccess
			return camera._flashBitmap.localToGlobal(new Point(worldX, 0)).x;
	}

	public function toDebugY(worldY:Float, camera:FlxCamera)
	{
		if (FlxG.render.tile)
			return camera.canvas.localToGlobal(new Point(0, worldY)).y;
		else
			@:privateAccess
			return camera._flashBitmap.localToGlobal(new Point(0, worldY)).y;
	}
}
