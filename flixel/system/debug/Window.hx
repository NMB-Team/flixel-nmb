package flixel.system.debug;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.system.ui.FlxSystemButton;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

/**
 * A generic, Flash-based window class, created for use in FlxDebugger.
 */
class Window extends Sprite
{
	/**
	 * The background color of the window.
	 */
	public static inline final BG_COLOR:FlxColor = 0xDD5F5F5F;

	public static inline final HEADER_COLOR:FlxColor = 0xBB000000;
	public static inline final HEADER_ALPHA:Float = 0.8;
	public static inline final HEADER_HEIGHT:Int = 15;

	/**
	 * How many windows there are currently in total.
	 */
	static var windowAmount:Int = 0;

	public var minSize:Point;
	public var maxSize:Point;
	public var toggleButton:FlxSystemButton;

	/**
	 * Width of the window. Using Sprite.width is super unreliable for some reason!
	 */
	var _width:Int;

	/**
	 * Height of the window. Using Sprite.height is super unreliable for some reason!
	 */
	var _height:Int;

	/**
	 * Controls where the window is allowed to be positioned.
	 */
	var _bounds:Rectangle;

	/**
	 * Window elements
	 */
	var _background:Bitmap;

	var _header:Bitmap;
	var _shadow:Bitmap;
	var _title:TextField;
	var _handle:Bitmap;
	var _icon:Bitmap;
	var _closeButton:FlxSystemButton;

	/**
	 * Interaction helpers.
	 */
	var _overHeader:Bool;

	var _overHandle:Bool;
	var _drag:Point;
	var _dragging:Bool;
	var _resizing:Bool;
	var _resizable:Bool;

	var _closable:Bool;
	var _alwaysOnTop:Bool;

	/**
	 * The ID of this window.
	 */
	var _id:Int;

	/**
	 * Creates a new window object.  This Flash-based class is mainly (only?) used by FlxDebugger.
	 *
	 * @param   title       The name of the window, displayed in the header bar.
	 * @param   icon	    The icon to use for the window header.
	 * @param   width       The initial width of the window.
	 * @param   height      The initial height of the window.
	 * @param   resizable   Whether you can change the size of the window with a drag handle.
	 * @param   bounds      A rectangle indicating the valid screen area for the window.
	 * @param   closable    Whether this window has a close button that removes the window.
	 * @param   alwaysOnTop Whether this window should be forcibly put in front of any other window when clicked.
	 */
	public function new(title, ?icon, width = 0.0, height = 0.0, resizable = true, ?bounds, closable = false, alwaysOnTop = true)
	{
		super();

		minSize = new Point(50, 30);

		_width = Std.int(Math.abs(width));
		_height = Std.int(Math.abs(height));
		updateBounds(bounds);
		_drag = new Point();
		_resizable = resizable;
		_closable = closable;
		_alwaysOnTop = alwaysOnTop;

		_shadow = new Bitmap(new BitmapData(1, 2, true, FlxColor.BLACK));
		_background = new Bitmap(new BitmapData(1, 1, true, BG_COLOR));
		_header = new Bitmap(new BitmapData(1, HEADER_HEIGHT, true, HEADER_COLOR));
		_background.y = _header.height;

		_title = DebuggerUtil.createTextField(2, -1);
		_title.alpha = HEADER_ALPHA;
		_title.text = title;

		addChild(_shadow);
		addChild(_background);
		addChild(_header);
		addChild(_title);

		if (icon != null)
		{
			DebuggerUtil.fixSize(icon);
			_icon = new Bitmap(icon);
			_icon.x = 5;
			_icon.y = 2;
			_icon.alpha = HEADER_ALPHA;
			_title.x = _icon.x + _icon.width + 2;
			addChild(_icon);
		}

		if (_resizable)
		{
			_handle = new Bitmap(DebuggerUtil.fixSize(Icon.windowHandle));
			addChild(_handle);
		}

		if (_closable)
		{
			_closeButton = new FlxSystemButton(Icon.close, close);
			_closeButton.alpha = HEADER_ALPHA;
			addChild(_closeButton);
		}
		else
		{
			_id = windowAmount;
			#if FLX_SAVE
			loadSaveData();
			#end
			windowAmount++;
		}

		if (_width != 0 || _height != 0)
		{
			updateSize();
		}
		bound();

		addEventListener(Event.ENTER_FRAME, init);
	}

	/**
	 * Clean up memory.
	 */
	public function destroy():Void
	{
		minSize = null;
		maxSize = null;
		_bounds = null;
		if (_shadow != null)
		{
			removeChild(_shadow);
		}
		_shadow = null;
		if (_background != null)
		{
			removeChild(_background);
		}
		_background = null;
		if (_header != null)
		{
			removeChild(_header);
		}
		_header = null;
		if (_title != null)
		{
			removeChild(_title);
		}
		_title = null;
		if (_handle != null)
		{
			removeChild(_handle);
		}
		_handle = null;
		_drag = null;
		_closeButton = FlxDestroyUtil.destroy(_closeButton);

		var stage = FlxG.stage;
		if (stage.hasEventListener(MouseEvent.MOUSE_MOVE))
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		if (hasEventListener(MouseEvent.MOUSE_DOWN))
		{
			removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		}
		if (stage.hasEventListener(MouseEvent.MOUSE_UP))
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
	}

	/**
	 * Resize the window.  Subject to pre-specified minimums, maximums, and bounding rectangles.
	 *
	 * @param 	Width	How wide to make the window.
	 * @param 	Height	How tall to make the window.
	 */
	public function resize(Width:Float, Height:Float):Void
	{
		_width = Std.int(Math.abs(Width));
		_height = Std.int(Math.abs(Height));
		updateSize();
	}

	/**
	 * Change the position of the window.  Subject to pre-specified bounding rectangles.
	 *
	 * @param 	X	Desired X position of top left corner of the window.
	 * @param 	Y	Desired Y position of top left corner of the window.
	 */
	public function reposition(X:Float, Y:Float):Void
	{
		x = X;
		y = Y;
		bound();
	}

	public function updateBounds(Bounds:Rectangle):Void
	{
		_bounds = Bounds;
		if (_bounds != null)
		{
			maxSize = new Point(_bounds.width, _bounds.height);
		}
		else
		{
			maxSize = new Point(FlxMath.MAX_VALUE_FLOAT, FlxMath.MAX_VALUE_FLOAT);
		}
	}

	public function setVisible(Value:Bool):Void
	{
		visible = Value;

		#if FLX_SAVE
		if (!_closable && FlxG.save.isBound)
			saveWindowVisibility();
		#end

		if (toggleButton != null)
			toggleButton.toggled = !visible;

		if (visible && _alwaysOnTop)
			putOnTop();
	}

	public function toggleVisible():Void
	{
		setVisible(!visible);
	}

	public inline function putOnTop():Void
	{
		parent.addChild(this);
	}

	#if FLX_SAVE
	function loadSaveData():Void
	{
		if (!FlxG.save.isBound)
			return;

		if (FlxG.save.data.windowSettings == null)
		{
			initWindowsSave();
			FlxG.save.flush();
		}
		visible = FlxG.save.data.windowSettings[_id];
	}

	function initWindowsSave()
	{
		var maxWindows = 10; // arbitrary
		FlxG.save.data.windowSettings = [for (_ in 0...maxWindows) true];
	}

	function saveWindowVisibility()
	{
		if (FlxG.save.data.windowSettings == null)
			initWindowsSave();

		FlxG.save.data.windowSettings[_id] = visible;
		FlxG.save.flush();
	}
	#end

	public function update():Void {}

	//***EVENT HANDLERS***//

	/**
	 * Used to set up basic mouse listeners..
	 */
	function init(?_:Event):Void
	{
		if (stage == null)
		{
			return;
		}
		removeEventListener(Event.ENTER_FRAME, init);

		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		// it's important that the mouse down event listener is added to the window sprite, not the stage - this way
		// only the window on top receives the event and we don't have to deal with overlapping windows ourselves.
		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
	}

	/**
	 * Mouse movement handler.  Figures out if mouse is over handle or header bar or what.
	 */
	function onMouseMove(?_:MouseEvent):Void
	{
		// mouseX / Y can be negative, which messes with the resizing if dragging in the opposite direction
		var mouseX:Float = (this.mouseX < 0) ? 0 : this.mouseX;
		var mouseY:Float = (this.mouseY < 0) ? 0 : this.mouseY;

		if (!parent.visible)
		{
			_overHandle = _overHeader = false;
			return;
		}

		if (_dragging) // user is moving the window around
		{
			_overHeader = true;
			reposition(parent.mouseX - _drag.x, parent.mouseY - _drag.y);
		}
		else if (_resizing)
		{
			_overHandle = true;
			resize(mouseX - _drag.x, mouseY - _drag.y);
		}
		else if ((mouseX >= 0) && (mouseX <= _width) && (mouseY >= 0) && (mouseY <= _height))
		{ // not dragging, mouse is over the window
			_overHeader = (mouseX <= _header.width) && (mouseY <= _header.height);
			if (_resizable)
			{
				_overHandle = (mouseX >= _width - _handle.width) && (mouseY >= _height - _handle.height);
			}
		}
		else
		{ // not dragging, mouse is NOT over window
			_overHandle = _overHeader = false;
		}
	}

	/**
	 * Figure out if window is being repositioned (clicked on header) or resized (clicked on handle).
	 */
	function onMouseDown(?_:MouseEvent):Void
	{
		if (_overHeader)
		{
			if (_alwaysOnTop)
				putOnTop();
			_dragging = true;
			_drag.x = mouseX;
			_drag.y = mouseY;
		}
		else if (_overHandle)
		{
			if (_alwaysOnTop)
				putOnTop();
			_resizing = true;
			_drag.x = mouseX - _width;
			_drag.y = mouseY - _height;
		}
	}

	/**
	 * User let go of header bar or handler (or nothing), so turn off drag and resize behaviors.
	 */
	function onMouseUp(?_:MouseEvent):Void
	{
		_dragging = false;
		_resizing = false;
	}

	/**
	 * Keep the window within the pre-specified bounding rectangle.
	 */
	public function bound():Void
	{
		if (_bounds != null)
		{
			x = FlxMath.bound(x, _bounds.left, _bounds.right - _width);
			y = FlxMath.bound(y, _bounds.top, _bounds.bottom - _height);
		}
	}

	/**
	 * Update the Flash shapes to match the new size, and reposition the header, shadow, and handle accordingly.
	 */
	function updateSize():Void
	{
		_width = Std.int(FlxMath.bound(_width, minSize.x, maxSize.x));
		_height = Std.int(FlxMath.bound(_height, minSize.y, maxSize.y));

		_header.scaleX = _width;
		_background.scaleX = _width;
		_background.scaleY = _height - _header.height;
		_shadow.scaleX = _width;
		_shadow.y = _height;
		_title.width = _width - 4;
		if (_resizable)
		{
			_handle.x = _width - _handle.width;
			_handle.y = _height - _handle.height;
		}
		if (_closeButton != null)
		{
			_closeButton.x = _width - _closeButton.width - 3;
			_closeButton.y = 3;
		}
	}

	public function close():Void
	{
		destroy();
		#if FLX_DEBUG
		FlxG.game.debugger.removeWindow(this);
		#end
	}
}
