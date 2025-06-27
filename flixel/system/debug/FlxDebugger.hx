package flixel.system.debug;

import openfl.display.BitmapData;
import openfl.display.Sprite;
#if FLX_DEBUG
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.system.debug.completion.CompletionList;
import flixel.system.debug.console.Console;
import flixel.system.debug.interaction.Interaction;
import flixel.system.debug.log.BitmapLog;
import flixel.system.debug.log.Log;
import flixel.system.debug.stats.Stats;
import flixel.system.debug.watch.Tracker;
import flixel.system.debug.watch.Watch;
import flixel.system.ui.FlxSystemButton;
import flixel.util.FlxAlign;
import flixel.util.FlxDestroyUtil;
import openfl.display.DisplayObject;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;

using flixel.util.FlxArrayUtil;
#end

/**
 * Container for the new debugger overlay. Most of the functionality is in the debug folder widgets,
 * but this class instantiates the widgets and handles their basic formatting and arrangement.
 */
class FlxDebugger extends openfl.display.Sprite {
	#if FLX_DEBUG
	/**
	 * The scale of the debug windows must be set before the `FlxGame` is made.
	 * Can also use the compile flag `-DFLX_DEBUGGER_SCALE=2`
	 */
	public static final defaultScale = #if FLX_DEBUGGER_SCALE Std.parseInt('${haxe.macro.Compiler.getDefine("FLX_DEBUGGER_SCALE")}') #else 1 #end;

	/**
	 * Internal, used to space out windows from the edges.
	 */
	public static inline final GUTTER = 2;

	/**
	 * Internal, used to space out windows from the edges.
	 */
	public static inline final TOP_HEIGHT = 20;

	public var stats:Stats;
	public var log:Log;
	public var watch:Watch;
	public var bitmapLog:BitmapLog;
	public var vcr:VCR;
	public var console:Console;
	public var interaction:Interaction;
	public var scale:Int;

	var completionList:CompletionList;

	/**
	 * Internal, tracks what debugger window layout user has currently selected.
	 */
	var _layout = FlxDebuggerLayout.STANDARD;

	/**
	 * Internal, stores width and height of the game.
	 */
	var _screen = new Point();

	/**
	 * Stores the bounds in which the windows can move.
	 */
	var _screenBounds:Rectangle;

	var _buttons:Map<FlxHorizontalAlign, Array<FlxSystemButton>> = [LEFT => [], CENTER => [], RIGHT => []];

	/**
	 * The flash Sprite used for the top bar of the debugger ui
	**/
	var _topBar:Sprite;

	var _windows:Array<Window> = [];

	var _usingSystemCursor = false;
	var _wasMouseVisible = true;
	var _wasUsingSystemCursor = false;

	/**
	 * Instantiates the debugger overlay.
	 *
	 * @param   width   The width of the screen.
	 * @param   height  The height of the screen.
	 * @param   scale   The scale of the debugger relative to the stage size
	 */
	@:allow(flixel.FlxGame)
	function new(width:Float, height:Float, scale = 0) {
		super();

		if (scale == 0) scale = defaultScale;
		scaleX = scale;
		scaleY = scale;

		visible = tabChildren = false;

		Tooltip.init(this);

		_topBar = new Sprite();
		_topBar.graphics.beginFill(0x000000, 0xAA / 255);
		_topBar.graphics.drawRect(0, 0, FlxG.stage.stageWidth / scaleX, TOP_HEIGHT);
		_topBar.graphics.endFill();
		addChild(_topBar);

		final txt = new TextField();
		txt.height = 20;
		txt.selectable = false;
		txt.y = -9;
		txt.multiline = false;
		txt.embedFonts = true;

		final format = new TextFormat(FlxAssets.FONT_DEBUGGER, 12, 0xffffff);
		txt.defaultTextFormat = format;
		txt.autoSize = TextFieldAutoSize.LEFT;
		txt.text = Std.string(FlxG.VERSION);

		addWindow(log = new Log());
		addWindow(bitmapLog = new BitmapLog());
		addWindow(watch = new Watch());
		completionList = new CompletionList(5);
		addWindow(console = new Console(completionList));
		addWindow(stats = new Stats());
		addWindow(interaction = new Interaction(this));

		vcr = new VCR(this);

		addButton(LEFT, Icon.flixel, openHomepage);
		addButton(LEFT, null, openGitHub).addChild(txt);

		addWindowToggleButton(interaction, Icon.interactive);
		addWindowToggleButton(bitmapLog, Icon.bitmapLog);
		addWindowToggleButton(log, Icon.log);

		addWindowToggleButton(watch, Icon.watch);
		addWindowToggleButton(console, Icon.console);
		addWindowToggleButton(stats, Icon.stats);

		final drawDebugButton = addButton(RIGHT, Icon.drawDebug, toggleDrawDebug, true);
		drawDebugButton.toggled = !FlxG.debugger.drawDebug;
		FlxG.debugger.drawDebugChanged.add(() -> drawDebugButton.toggled = !FlxG.debugger.drawDebug);

		#if FLX_RECORD
		addButton(CENTER).addChild(vcr.runtimeDisplay);
		#end

		addChild(completionList);

		onResize(width, height);

		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

		FlxG.signals.preStateSwitch.add(Tracker.onStateSwitch);
	}

	/**
	 * Clean up memory.
	 */
	public function destroy():Void {
		_screen = null;
		_buttons = FlxArrayUtil.clear(_buttons);

		_topBar = FlxDestroyUtil.removeChild(this, _topBar);

		if (log != null) removeChild(log);
		log = FlxDestroyUtil.destroy(log);

		if (watch != null) removeChild(watch);
		watch = FlxDestroyUtil.destroy(watch);

		if (bitmapLog != null) removeChild(bitmapLog);
		bitmapLog = FlxDestroyUtil.destroy(bitmapLog);

		if (stats != null) removeChild(stats);
		stats = FlxDestroyUtil.destroy(stats);

		if (console != null) removeChild(console);
		console = FlxDestroyUtil.destroy(console);

		_windows = FlxArrayUtil.clearArray(_windows);

		removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}

	public function update():Void {
		for (window in _windows) window.update();
	}

	/**
	 * Change the way the debugger's windows are laid out.
	 *
	 * @param   layout   The layout codes can be found in FlxDebugger, for example FlxDebugger.MICRO
	 */
	public inline function setLayout(layout:FlxDebuggerLayout):Void {
		_layout = layout;
		resetLayout();
	}

	/**
	 * Forces the debugger windows to reset to the last specified layout.
	 * The default layout is STANDARD.
	 */
	public function resetLayout():Void {
		final screenW = _screen.x;
		final screenH = _screen.y;
		final halfW = screenW * 0.5;
		final thirdW = screenW / 3;
		final quarterW = screenW * .25;
		final quarterH = screenH * .25;
		final halfH = screenH * .5;
		final consoleH = 35;

		inline function bottom(y:Float)
			return screenH - y;
		inline function right(x:Float)
			return screenW - x;

		switch (_layout) {
			case MICRO:
				log.resize(quarterW, 68);
				log.reposition(0, screenH);

				console.resize(halfW - GUTTER * 4, consoleH);
				console.reposition(log.x + log.width + GUTTER, screenH);

				watch.resize(quarterW, 68);
				watch.reposition(screenW, screenH);

				stats.reposition(screenW, 0);

				bitmapLog.resize(quarterW, 68);
				bitmapLog.reposition(0, screenH - 68 * 2 - GUTTER * 2);

			case BIG:
				console.resize(right(GUTTER * 2), consoleH);
				console.reposition(GUTTER, screenH);

				final logW = (right(GUTTER * 3)) * .5;
				final logH = halfH;
				log.resize(logW, logH);
				log.reposition(0, bottom(logH + consoleH + GUTTER * 1.5));

				watch.resize(logW, halfH);
				watch.reposition(screenW, bottom(halfH + consoleH + GUTTER * 1.5));

				stats.reposition(screenW, 0);

				final bitmapH = right(GUTTER * 2) - halfH - consoleH * 2;
				bitmapLog.resize(logW, bitmapH);
				bitmapLog.reposition(0, GUTTER * 1.5);

			case TOP:
				console.resize(right(GUTTER * 2), consoleH);
				console.reposition(0, 0);

				final logW = right(GUTTER * 3) * .5;
				log.resize(logW, quarterH);
				log.reposition(0, consoleH + GUTTER + 15);

				watch.resize(logW, quarterH);
				watch.reposition(screenW, consoleH + GUTTER + 15);

				stats.reposition(screenW, screenH);

				bitmapLog.resize(logW, quarterH);
				bitmapLog.reposition(0, consoleH + (GUTTER * 2) + 15 + quarterH + GUTTER);

			case LEFT, RIGHT:
				console.resize(right(GUTTER * 2), consoleH);
				console.reposition(GUTTER, screenH);

				final logH = (screenH - 15 - GUTTER * 2.5) * .5 - consoleH * .5 - GUTTER;
				log.resize(thirdW, logH);
				watch.resize(thirdW, logH + GUTTER);

				final baseX = (_layout == LEFT) ? 0 : screenW;

				log.reposition(baseX, 0);
				watch.reposition(baseX, log.y + log.height + GUTTER);

				stats.reposition((_layout == LEFT) ? screenW : 0, 0);

				bitmapLog.resize(thirdW, logH);
				final bitmapX = (_layout == LEFT) ? thirdW + GUTTER * 2 : right(GUTTER * 2) - (thirdW * 2);

				bitmapLog.reposition(bitmapX, 0);

			case STANDARD:
				console.resize(right(GUTTER * 2), consoleH);
				console.reposition(GUTTER, screenH);

				final logW = right(GUTTER * 3) * .5;
				log.resize(logW, quarterH);
				log.reposition(0, bottom(quarterH + consoleH + GUTTER * 1.5));

				watch.resize(logW, halfH);
				watch.reposition(screenW, bottom(halfH + consoleH + GUTTER * 1.5));

				stats.reposition(screenW, 0);

				bitmapLog.resize(logW, quarterH);
				bitmapLog.reposition(0, log.y - GUTTER - quarterH);
		}
	}

	public function onResize(width:Float, height:Float, scale = 0):Void {
		if (scale == 0) scale = defaultScale;

		this.scale = scale;
		_screen.x = width / scale;
		_screen.y = height / scale;

		updateBounds();
		_topBar.width = FlxG.stage.stageWidth / scaleX;
		resetButtonLayout();
		resetLayout();

		scaleX = scaleY = scale;
		x = -FlxG.scaleMode.offset.x;
		y = -FlxG.scaleMode.offset.y;
	}

	function updateBounds():Void {
		_screenBounds = new Rectangle(GUTTER, TOP_HEIGHT + GUTTER * .5, _screen.x - GUTTER * 2, _screen.y - GUTTER * 2 - TOP_HEIGHT);
		for (window in _windows)
			window.updateBounds(_screenBounds);
	}

	/**
	 * Align an array of debugger buttons, used for the middle and right layouts
	 */
	function hAlignButtons(sprites:Array<FlxSystemButton>, padding = .0, set = true, leftOffset = .0):Float {
		var width = .0;
		var last = leftOffset;

		for (i in 0...sprites.length) {
			final o:Sprite = sprites[i];
			width += o.width + padding;
			if (set) o.x = last;
			last = o.x + o.width + padding;
		}

		return width;
	}

	/**
	 * Position the debugger buttons
	 */
	function resetButtonLayout():Void {
		hAlignButtons(_buttons[FlxHorizontalAlign.LEFT], 10, true, 10);

		final offset = FlxG.stage.stageWidth / scaleX * .5 - hAlignButtons(_buttons[FlxHorizontalAlign.CENTER], 10, false) * .5;
		hAlignButtons(_buttons[FlxHorizontalAlign.CENTER], 10, true, offset);

		final offset = FlxG.stage.stageWidth / scaleX - hAlignButtons(_buttons[FlxHorizontalAlign.RIGHT], 10, false);
		hAlignButtons(_buttons[FlxHorizontalAlign.RIGHT], 10, true, offset);
	}

	/**
	 * Create and add a new debugger button.
	 *
	 * @param   position       Either LEFT, CENTER or RIGHT.
	 * @param   icon           The icon to use for the button
	 * @param   upHandler      The function to be called when the button is pressed.
	 * @param   toggleMode     Whether this is a toggle button or not.
	 * @param   updateLayout   Whether to update the button layout.
	 * @return  The added button.
	 */
	public function addButton(position:FlxHorizontalAlign, ?icon:BitmapData, ?upHandler:Void -> Void, toggleMode = false, updateLayout = false):FlxSystemButton {
		final button = new FlxSystemButton(icon, upHandler, toggleMode);
		button.y = (TOP_HEIGHT * .5) - (button.height * .5);
		_buttons[position].push(button);
		addChild(button);

		if (updateLayout) resetButtonLayout();

		return button;
	}

	/**
	 * Removes and destroys a button from the debugger.
	 *
	 * @param   button         The FlxSystemButton instance to remove.
	 * @param   updateLayout   Whether to update the button layout.
	 */
	public function removeButton(button:FlxSystemButton, updateLayout = true):Void {
		removeChild(button);
		button.destroy();

		_buttons[FlxHorizontalAlign.LEFT].remove(button);
		_buttons[FlxHorizontalAlign.CENTER].remove(button);
		_buttons[FlxHorizontalAlign.RIGHT].remove(button);

		if (updateLayout) resetButtonLayout();
	}

	public function addWindowToggleButton(window:Window, icon:FlxGraphicSource):Void {
		final button = addButton(RIGHT, icon.resolveBitmapData(), window.toggleVisible, true, true);
		window.toggleButton = button;
		button.toggled = !window.visible;
	}

	public inline function addWindow(window:Window):Window {
		_windows.push(window);
		addChild(window);

		if (_screenBounds != null) {
			updateBounds();
			window.bound();
		}

		return window;
	}

	public inline function removeWindow(window:Window):Void {
		if (contains(window)) removeChild(window);
		_windows.fastSplice(window);
	}

	override public function addChild(child:DisplayObject):DisplayObject {
		final result = super.addChild(child);
		// hack to make sure the completion list always stays on top
		if (completionList != null) super.addChild(completionList);
		return result;
	}

	/**
	 * Mouse handler that helps with fake "mouse focus" type behavior.
	 */
	function onMouseOver(_):Void {
		onMouseFocus();
	}

	/**
	 * Mouse handler that helps with fake "mouse focus" type behavior.
	 */
	function onMouseOut(_):Void {
		onMouseFocusLost();
	}

	function onMouseFocus():Void {
		#if FLX_MOUSE
		FlxG.mouse.enabled = false;
		_wasMouseVisible = FlxG.mouse.visible;
		_wasUsingSystemCursor = FlxG.mouse.useSystemCursor;
		FlxG.mouse.useSystemCursor = _usingSystemCursor = true;
		#end
	}

	@:allow(flixel.system.debug)
	function onMouseFocusLost():Void {
		#if FLX_MOUSE
		// Disable mouse input if the interaction tool is in use,
		// so users can select interactable elements, e.g. buttons.
		FlxG.mouse.enabled = !interaction.isInUse();

		if (_usingSystemCursor) {
			FlxG.mouse.useSystemCursor = _wasUsingSystemCursor;
			FlxG.mouse.visible = _wasMouseVisible;
		}
		#end
	}

	inline function toggleDrawDebug():Void {
		FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
	}

	inline function openHomepage():Void {
		FlxG.openURL("https://haxeflixel.com");
	}

	inline function openGitHub():Void {
		var url = "https://github.com/dtwotwo/flixel-dtwotwo";
		if (!flixel.util.FlxStringUtil.isNullOrEmpty(sha)) url += '/commit/${FlxVersion.sha}';
		FlxG.openURL(url);
	}
	#end
}

enum FlxDebuggerLayout {
	STANDARD;
	MICRO;
	BIG;
	TOP;
	LEFT;
	RIGHT;
}
