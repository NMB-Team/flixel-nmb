package flixel.input.mouse;

#if FLX_MOUSE
import flixel.FlxG;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.IFlxInputManager;
import flixel.input.mouse.FlxMouseButton.FlxMouseButtonID;
import flixel.system.FlxAssets;
import flixel.system.replay.MouseRecord;
import flixel.util.FlxDestroyUtil;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.ui.Mouse;
#if FLX_NATIVE_CURSOR
import flash.ui.MouseCursorData;
import openfl.Vector;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.ui.MouseCursor;
#end

@:bitmap("assets/images/ui/cursor.png")
private final class GraphicCursor extends BitmapData {}

/**
 * This class helps contain and track the mouse pointer in your game.
 * Automatically accounts for parallax scrolling, etc.
 * Normally accessed via `FlxG.mouse`.
 */
class FlxMouse extends FlxPointer implements IFlxInputManager {
	/**
	 * Whether or not mouse input is currently enabled.
	 * @since 4.1.0
	 */
	public var enabled = true;

	/**
	 * Current "delta" value of mouse wheel. If the wheel was just scrolled up,
	 * it will have a positive value and vice versa. Otherwise the value will be 0.
	 */
	public var wheel(default, null) = 0;

	/**
	 * A display container for the mouse cursor. It is a child of FlxGame and
	 * sits at the right "height". Not used on flash with the native cursor API.
	 */
	public var cursorContainer(default, null):Sprite;

	/**
	 * The current cursor bitmap, if there is one. To set, use the `load` function.
	 */
	public var cursor(default, null):Null<Bitmap>;

	/**
	 * Used to toggle the visiblity of the mouse cursor - works on both
	 * the flixel and the system cursor, depending on which one is active.
	 */
	public var visible(default, set) = #if (mobile || switch) false #else true #end;

	/**
	 * Tells flixel to use the default system mouse cursor instead of custom Flixel mouse cursors.
	 */
	public var useSystemCursor(default, set) = false;

	/**
	 * Check to see if the mouse has just been moved.
	 * @since 4.4.0
	 */
	public var justMoved(get, never):Bool;

	/**
	 * Distance in pixels the mouse has moved since the last frame in the X direction.
	 */
	public var deltaX(get, never):Int;

	/**
	 * Distance in pixels the mouse has moved since the last frame in the Y direction.
	 */
	public var deltaY(get, never):Int;

	/**
	 * Distance in pixels the mouse has moved in view space since the last frame in the X direction.
	 * @since 5.9.0
	 */
	public var deltaViewX(get, never):Int;

	/**
	 * Distance in pixels the mouse has moved in view space since the last frame in the Y direction.
	 * @since 5.9.0
	 */
	public var deltaViewY(get, never):Int;

	/**
	 * Check to see if the left mouse button is currently pressed.
	 */
	public var pressed(get, never):Bool;

	/**
	 * Check to see if the left mouse button has just been pressed.
	 */
	public var justPressed(get, never):Bool;

	/**
	 * Check to see if the left mouse button is currently not pressed.
	 * @since 5.0.0
	 */
	public var released(get, never):Bool;

	/**
	 * Check to see if the left mouse button has just been released.
	 */
	public var justReleased(get, never):Bool;

	/**
	 * Time in ticks of last left mouse button press.
	 * @since 4.3.0
	 */
	public var justPressedTimeInTicks(get, never):Float;

	#if FLX_MOUSE_ADVANCED
	/**
	 * Check to see if the right mouse button is currently pressed.
	 */
	public var pressedRight(get, never):Bool;

	/**
	 * Check to see if the right mouse button has just been pressed.
	 */
	public var justPressedRight(get, never):Bool;

	/**
	 * Check to see if the right mouse button is currently not pressed.
	 * @since 5.0.0
	 */
	public var releasedRight(get, never):Bool;

	/**
	 * Check to see if the right mouse button has just been released.
	 */
	public var justReleasedRight(get, never):Bool;

	/**
	 * Time in ticks of last right mouse button press.
	 * @since 4.3.0
	 */
	public var justPressedTimeInTicksRight(get, never):Float;

	/**
	 * Check to see if the middle mouse button is currently pressed.
	 */
	public var pressedMiddle(get, never):Bool;

	/**
	 * Check to see if the middle mouse button has just been pressed.
	 */
	public var justPressedMiddle(get, never):Bool;

	/**
	 * Check to see if the middle mouse button is currently not pressed.
	 * @since 5.0.0
	 */
	public var releasedMiddle(get, never):Bool;

	/**
	 * Check to see if the middle mouse button has just been released.
	 */
	public var justReleasedMiddle(get, never):Bool;

	/**
	 * Time in ticks of last middle mouse button press.
	 * @since 4.3.0
	 */
	public var justPressedTimeInTicksMiddle(get, never):Float;
	#end

	/**
	 * The left mouse button.
	 */
	@:allow(flixel.input.mouse.FlxMouseButton)
	var _leftButton:FlxMouseButton;

	#if FLX_MOUSE_ADVANCED
	/**
	 * The middle mouse button.
	 */
	@:allow(flixel.input.mouse.FlxMouseButton)
	var _middleButton:FlxMouseButton;

	/**
	 * The right mouse button.
	 */
	@:allow(flixel.input.mouse.FlxMouseButton)
	var _rightButton:FlxMouseButton;
	#end

	var _cursorBitmapData:BitmapData;
	var _wheelUsed = false;
	var _visibleWhenFocusLost = true;

	/**
	 * Helper variables for recording purposes.
	 */
	var _lastX = 0;

	var _lastY = 0;
	var _lastWheel = 0;
	var _lastLeftButtonState:FlxInputState;

	/**
	 * Helper variables to see if the mouse has moved since the last update, and by how much.
	 */
	var _prevX = 0;
	var _prevY = 0;
	var _prevViewX = 0;
	var _prevViewY = 0;

	// Helper variable for cleaning up memory
	var _stage:Stage;

	/**
	 * Helper variables for flash native cursors
	 */
	#if FLX_NATIVE_CURSOR
	final _cursorDefaultName = "defaultCursor";
	var _currentNativeCursor:String;
	var _matrix = new Matrix();
	#end

	/**
	 * Load a new mouse cursor graphic - if you're using native cursors on flash,
	 * check registerNativeCursor() for more control.
	 *
	 * @param   graphic   The image you want to use for the cursor.
	 * @param   scale     Change the size of the cursor.
	 * @param   xOffset   The number of pixels between the mouse's screen position and the graphic's top left corner.
	 *                    Has to be positive when using native cursors.
	 * @param   yOffset   The number of pixels between the mouse's screen position and the graphic's top left corner.
	 *                    Has to be positive when using native cursors.
	 */
	public function load(?graphic:Dynamic, scale = 1., xOffset = 0, yOffset = 0):Void {
		#if !FLX_NATIVE_CURSOR
		if (cursor != null) FlxDestroyUtil.removeChild(cursorContainer, cursor);
		#end

		if (graphic == null) graphic ??= new GraphicCursor(0, 0);
		
		if ((graphic is Class))
			cursor = Type.createInstance(graphic, []);
		else if ((graphic is BitmapData))
			cursor = new Bitmap(cast graphic);
		else if ((graphic is String))
			cursor = new Bitmap(FlxG.assets.getBitmapData(graphic, false));
		else
			cursor = new Bitmap(new GraphicCursor(0, 0));

		cursor.x = xOffset;
		cursor.y = yOffset;
		cursor.scaleX = scale;
		cursor.scaleY = scale;

		#if FLX_NATIVE_CURSOR
		if (xOffset < 0 || yOffset < 0) FlxG.log.critical("Negative offsets aren't supported for native cursors.");
		if (scale < 0) FlxG.log.critical("Negative scale isn't supported for native cursors.");

		final scaledWidth = Std.int(scale * cursor.bitmapData.width);
		final scaledHeight = Std.int(scale * cursor.bitmapData.height);

		final bitmapWidth = scaledWidth + xOffset;
		final bitmapHeight = scaledHeight + yOffset;

		final cursorBitmap = new BitmapData(bitmapWidth, bitmapHeight, true, 0x0);
		if (_matrix != null) {
			_matrix.identity();
			_matrix.scale(scale, scale);
			_matrix.translate(xOffset, yOffset);
		}
		cursorBitmap.draw(cursor.bitmapData, _matrix);
		setSimpleNativeCursorData(_cursorDefaultName, cursorBitmap);
		#else
		cursorContainer.addChild(cursor);
		#end
	}

	/**
	 * Unload the current cursor graphic. If the current cursor is visible,
	 * then the default system cursor is loaded up to replace the old one.
	 */
	public function unload():Void {
		if (cursor != null) {
			if (cursorContainer.visible)
				load();
			else
				cursor = FlxDestroyUtil.removeChild(cursorContainer, cursor);
		}
	}

	#if FLX_NATIVE_CURSOR
	/**
	 * Set a Native cursor that has been registered by name
	 * Warning, you need to use registerNativeCursor() before you use it here
	 *
	 * @param   name   The name ID used when registered
	 */
	public function setNativeCursor(name:String):Void {
		_currentNativeCursor = name;

		Mouse.show();

		// Flash requires the use of AUTO before a custom cursor to work
		Mouse.cursor = MouseCursor.AUTO;
		Mouse.cursor = _currentNativeCursor;
	}

	/**
	 * Shortcut to register a native cursor in flash
	 *
	 * @param   name         The ID name used for the cursor
	 * @param   cursorData   MouseCursorData contains the bitmap, hotspot etc
	 */
	public inline function registerNativeCursor(name:String, cursorData:MouseCursorData):Void {
		untyped Mouse.registerCursor(name, cursorData);
	}

	/**
	 * Shortcut to register a simple MouseCursorData
	 *
	 * @param   name         The ID name used for the cursor
	 * @param   cursorData   MouseCursorData contains the bitmap, hotspot etc
	 * @since   4.2.0
	 */
	public function registerSimpleNativeCursorData(name:String, cursorBitmap:BitmapData, ?hotSpot:Point):MouseCursorData {
		final cursorVector = new Vector<BitmapData>();
		cursorVector[0] = cursorBitmap;

		if (cursorBitmap.width > 32 || cursorBitmap.height > 32)
			FlxG.log.critical("BitmapData files used for native cursors cannot exceed 32x32 pixels due to an OS limitation.");

		if (hotSpot == null)
			hotSpot = new Point();
		else if (hotSpot.x < 0 || hotSpot.y < 0 || hotSpot.x > cursorBitmap.width || hotSpot.y > cursorBitmap.height)
			FlxG.log.critical('Invalid hotSpot: $hotSpot');

		final cursorData = new MouseCursorData();
		cursorData.hotSpot = hotSpot;
		cursorData.data = cursorVector;

		registerNativeCursor(name, cursorData);

		return cursorData;
	}

	/**
	 * Shortcut to create and set a simple MouseCursorData
	 *
	 * @param   name         The ID name used for the cursor
	 * @param   cursorData   MouseCursorData contains the bitmap, hotspot etc
	 */
	public function setSimpleNativeCursorData(name:String, cursorBitmap:BitmapData):MouseCursorData {
		final data = registerSimpleNativeCursorData(name, cursorBitmap);
		setNativeCursor(name);
		Mouse.show();
		return data;
	}
	#end

	/**
	 * Clean up memory. Internal use only.
	 */
	@:noCompletion public function destroy():Void {
		if (_stage != null) {
			_stage.removeEventListener(MouseEvent.MOUSE_DOWN, _leftButton.onDown);
			_stage.removeEventListener(MouseEvent.MOUSE_UP, _leftButton.onUp);

			#if FLX_MOUSE_ADVANCED
			_stage.removeEventListener(untyped MouseEvent.MIDDLE_MOUSE_DOWN, _middleButton.onDown);
			_stage.removeEventListener(untyped MouseEvent.MIDDLE_MOUSE_UP, _middleButton.onUp);
			_stage.removeEventListener(untyped MouseEvent.RIGHT_MOUSE_DOWN, _rightButton.onDown);
			_stage.removeEventListener(untyped MouseEvent.RIGHT_MOUSE_UP, _rightButton.onUp);

			_stage.removeEventListener(Event.MOUSE_LEAVE, onMouseLeave);
			#end

			_stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}

		cursorContainer = null;
		cursor = null;

		#if FLX_NATIVE_CURSOR
		_matrix = null;
		#end

		_leftButton = FlxDestroyUtil.destroy(_leftButton);
		#if FLX_MOUSE_ADVANCED
		_middleButton = FlxDestroyUtil.destroy(_middleButton);
		_rightButton = FlxDestroyUtil.destroy(_rightButton);
		#end

		_cursorBitmapData = FlxDestroyUtil.dispose(_cursorBitmapData);
		FlxG.signals.postGameStart.remove(onGameStart);
	}

	/**
	 * Resets the just pressed/just released flags and sets mouse to not pressed.
	 */
	public function reset():Void {
		_leftButton.reset();

		#if FLX_MOUSE_ADVANCED
		_middleButton.reset();
		_rightButton.reset();
		#end
	}

	/**
	 * @param   cursorContainer   The cursor container sprite passed by FlxGame
	 */
	@:allow(flixel.FlxG)
	private function new(cursorContainer:Sprite) {
		super();
		this.cursorContainer = cursorContainer;
		this.cursorContainer.mouseChildren = false;
		this.cursorContainer.mouseEnabled = false;

		_leftButton = new FlxMouseButton(FlxMouseButtonID.LEFT);

		_stage = Lib.current.stage;
		_stage.addEventListener(MouseEvent.MOUSE_DOWN, _leftButton.onDown);
		_stage.addEventListener(MouseEvent.MOUSE_UP, _leftButton.onUp);

		#if FLX_MOUSE_ADVANCED
		_middleButton = new FlxMouseButton(FlxMouseButtonID.MIDDLE);
		_rightButton = new FlxMouseButton(FlxMouseButtonID.RIGHT);

		_stage.addEventListener(untyped MouseEvent.MIDDLE_MOUSE_DOWN, _middleButton.onDown);
		_stage.addEventListener(untyped MouseEvent.MIDDLE_MOUSE_UP, _middleButton.onUp);
		_stage.addEventListener(untyped MouseEvent.RIGHT_MOUSE_DOWN, _rightButton.onDown);
		_stage.addEventListener(untyped MouseEvent.RIGHT_MOUSE_UP, _rightButton.onUp);

		_stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeave);
		#end

		_stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);

		FlxG.signals.postGameStart.add(onGameStart);
		Mouse.hide();
	}

	/**
	 * Called by the internal game loop to update the mouse pointer's position in the game world.
	 * Also updates the just pressed/just released flags.
	 */
	private function update():Void {
		_prevX = x;
		_prevY = y;
		_prevViewX = viewX;
		_prevViewY = viewY;

		#if FLX_UNIT_TEST // Travis segfaults when game.mouseX / Y is accessed
		setRawPositionUnsafe(0, 0);
		#else
		setRawPositionUnsafe(FlxG.game.mouseX, FlxG.game.mouseY);

		// actually position the flixel mouse cursor graphic
		if (cursorContainer.visible) {
			cursorContainer.x = FlxG.game.mouseX;
			cursorContainer.y = FlxG.game.mouseY;
		}
		#end

		// Update the buttons
		_leftButton.update();
		#if FLX_MOUSE_ADVANCED
		_middleButton.update();
		_rightButton.update();
		#end

		// Update the wheel
		if (!_wheelUsed) wheel = 0;
		_wheelUsed = false;
	}

	/**
	 * Called from the main Event.ACTIVATE that is dispatched in FlxGame
	 */
	private function onFocus():Void {
		reset();

		#if !FLX_NATIVE_CURSOR
		set_useSystemCursor(useSystemCursor);

		visible = _visibleWhenFocusLost;
		#end
	}

	/**
	 * Called from the main Event.DEACTIVATE that is dispatched in FlxGame
	 */
	private function onFocusLost():Void {
		#if !FLX_NATIVE_CURSOR
		_visibleWhenFocusLost = visible;

		if (visible) visible = false;

		Mouse.show();
		#end
	}

	private function onGameStart():Void {
		// Call set_visible with the value visible has been initialized with
		// (unless set in create() of the initial state)
		set_visible(visible);
	}

	/**
	 * Internal event handler for input and focus.
	 */
	private function onMouseWheel(flashEvent:MouseEvent):Void {
		if (enabled) {
			_wheelUsed = true;
			wheel = flashEvent.delta;
		}
	}

	#if FLX_MOUSE_ADVANCED
	/**
	 * We're detecting the mouse leave event to prevent a bug where `pressed` remains true
	 * for the middle and right mouse button when pressed and dragged outside the window.
	 */
	inline function onMouseLeave(_):Void {
		_rightButton.onUp();
		_middleButton.onUp();
	}
	#end

	inline function get_justMoved():Bool {
		return _prevX != x || _prevY != y;
	}

	inline function get_deltaX():Int {
		return x - _prevX;
	}

	inline function get_deltaY():Int {
		return y - _prevY;
	}

	inline function get_deltaViewX():Int {
		return viewX - _prevViewX;
	}

	inline function get_deltaViewY():Int {
		return viewY - _prevViewY;
	}

	inline function get_pressed():Bool {
		return _leftButton.pressed;
	}

	inline function get_justPressed():Bool {
		return _leftButton.justPressed;
	}

	inline function get_released():Bool {
		return _leftButton.released;
	}

	inline function get_justReleased():Bool {
		return _leftButton.justReleased;
	}

	inline function get_justPressedTimeInTicks():Float {
		return _leftButton.justPressedTimeInTicks;
	}

	#if FLX_MOUSE_ADVANCED
	inline function get_pressedRight():Bool {
		return _rightButton.pressed;
	}

	inline function get_justPressedRight():Bool {
		return _rightButton.justPressed;
	}

	inline function get_releasedRight():Bool {
		return _rightButton.released;
	}

	inline function get_justReleasedRight():Bool {
		return _rightButton.justReleased;
	}

	inline function get_justPressedTimeInTicksRight():Float {
		return _rightButton.justPressedTimeInTicks;
	}

	inline function get_pressedMiddle():Bool {
		return _middleButton.pressed;
	}

	inline function get_justPressedMiddle():Bool {
		return _middleButton.justPressed;
	}

	inline function get_releasedMiddle():Bool {
		return _middleButton.released;
	}

	inline function get_justReleasedMiddle():Bool {
		return _middleButton.justReleased;
	}

	inline function get_justPressedTimeInTicksMiddle():Float {
		return _middleButton.justPressedTimeInTicks;
	}
	#end

	private function showSystemCursor():Void {
		#if FLX_NATIVE_CURSOR
		Mouse.cursor = MouseCursor.AUTO;
		#else
		cursorContainer.visible = false;
		#end

		Mouse.show();
	}

	private function hideSystemCursor():Void {
		#if FLX_NATIVE_CURSOR
		if (_currentNativeCursor != null)
			setNativeCursor(_currentNativeCursor);
		#else
		Mouse.hide();

		if (visible)
			cursorContainer.visible = true;
		#end
	}

	private function set_useSystemCursor(value:Bool):Bool {
		if (value) showSystemCursor();
		else hideSystemCursor();

		return useSystemCursor = value;
	}

	private function showCursor():Void {
		if (!useSystemCursor) {
			if (cursor == null) load();

			#if FLX_NATIVE_CURSOR
			Mouse.show();
			#else
			cursorContainer.visible = true;
			Mouse.hide();
			#end
		} else
			Mouse.show();
	}

	private function hideCursor():Void {
		cursorContainer.visible = false;
		Mouse.hide();
	}

	private function set_visible(value:Bool):Bool {
		if (value) showCursor();
		else hideCursor();

		return visible = value;
	}

	@:allow(flixel.system.replay.FlxReplay)
	private function record():MouseRecord {
		if ((_lastX == gameX)
			&& (_lastY == gameY)
			&& (_lastLeftButtonState == _leftButton.current)
			&& (_lastWheel == wheel))
		{
			return null;
		}

		_lastX = gameX;
		_lastY = gameY;
		_lastLeftButtonState = _leftButton.current;
		_lastWheel = wheel;
		return new MouseRecord(_lastX, _lastY, _leftButton.current, _lastWheel);
	}

	@:allow(flixel.system.replay.FlxReplay)
	private function playback(record:MouseRecord):Void {
		// Manually dispatch a MOUSE_UP event so that, e.g., FlxButtons click correctly on playback.
		// Note: some clicks are fast enough to not pass through a frame where they are PRESSED
		// and JUST_RELEASED is swallowed by FlxButton and others, but not third-party code
		if ((_lastLeftButtonState == PRESSED || _lastLeftButtonState == JUST_PRESSED) && (record.button == RELEASED || record.button == JUST_RELEASED))
			_stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP, true, false, record.x, record.y));
		_lastLeftButtonState = _leftButton.current = record.button;
		wheel = record.wheel;
		_rawX = record.x;
		_rawY = record.y;
		updatePositions();
	}
}
#end