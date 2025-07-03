package flixel.input.actions;

import flixel.input.FlxInput;
import flixel.input.actions.FlxActionInput.FlxInputType;
import flixel.input.actions.FlxActionInput.FlxInputDevice;
import flixel.input.actions.FlxActionInput.FlxInputDeviceID;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.mouse.FlxMouseButton.FlxMouseButtonID;
#if FLX_STEAMWRAP
import steamwrap.api.Controller.ControllerAnalogActionData;
#end

/**
 * @since 4.6.0
 */
enum abstract FlxAnalogState(Int) from Int {
	final JUST_STOPPED = cast FlxInputState.JUST_RELEASED; // became 0 on this frame
	final STOPPED = cast FlxInputState.RELEASED; // is 0
	final MOVED = cast FlxInputState.PRESSED; // is !0
	final JUST_MOVED = cast FlxInputState.JUST_PRESSED; // became !0 on this frame

	public var moved(get, never):Bool;
	inline function get_moved() {
		return this == MOVED || justMoved;
	}

	public var justMoved(get, never):Bool;
	inline function get_justMoved() {
		return this == JUST_MOVED;
	}

	public var justStopped(get, never):Bool;
	inline function get_justStopped() {
		return this == JUST_STOPPED;
	}

	public var stopped(get, never):Bool;
	inline function get_stopped() {
		return this == STOPPED || justStopped;
	}
}

/**
 * @since 4.6.0
 */
class FlxActionInputAnalogClickAndDragMouseMotion extends FlxActionInputAnalogMouseMotion {
	var button:FlxMouseButtonID;

	/**
	 * Mouse input -- same as FlxActionInputAnalogMouseMotion, but requires a particular mouse button to be PRESSED
	 * Very useful for e.g. panning a map or canvas around
	 * @param	buttonID	Button identifier (FlxMouseButtonID.LEFT / MIDDLE / RIGHT)
	 * @param	trigger	What state triggers this action (MOVED, JUST_MOVED, STOPPED, JUST_STOPPED)
	 * @param	axis	which axes to monitor for triggering: X, Y, EITHER, or BOTH
	 * @param	pixelsPerUnit	How many pixels of movement = 1.0 in analog motion (lower: more sensitive, higher: less sensitive)
	 * @param	deadZone	Minimum analog value before motion will be reported
	 * @param	invertY	Invert the Y axis
	 * @param	invertX	Invert the X axis
	 */
	public function new(buttonID:FlxMouseButtonID, trigger:FlxAnalogState, axis = FlxAnalogAxis.EITHER, pixelsPerUnit = 10, deadZone = .1, invertY = false, invertX = false) {
		super(trigger, axis, pixelsPerUnit, deadZone, invertY, invertX);
		button = buttonID;
	}

	override function updateValues(x:Float, y:Float):Void {
		var pass = false;
		#if !FLX_NO_MOUSE
		pass = switch (button) {
			case FlxMouseButtonID.LEFT: FlxG.mouse.pressed;
			case FlxMouseButtonID.RIGHT: FlxG.mouse.pressedRight;
			case FlxMouseButtonID.MIDDLE: FlxG.mouse.pressedMiddle;
		}
		#end
		if (!pass) x = y = 0;
		super.updateValues(x, y);
	}
}

/**
 * @since 4.6.0
 */
class FlxActionInputAnalogMouseMotion extends FlxActionInputAnalog {
	var lastX = .0;
	var lastY = .0;
	var pixelsPerUnit:Int;
	var deadZone:Float;
	var invertX:Bool;
	var invertY:Bool;

	/**
	 * Mouse input -- X/Y is the RELATIVE motion of the mouse since the last frame
	 * @param	trigger	What state triggers this action (MOVED, JUST_MOVED, STOPPED, JUST_STOPPED)
	 * @param	axis	which axes to monitor for triggering: X, Y, EITHER, or BOTH
	 * @param	pixelsPerUnit	How many pixels of movement = 1.0 in analog motion (lower: more sensitive, higher: less sensitive)
	 * @param	deadZone	Minimum analog value before motion will be reported
	 * @param	invertY	Invert the Y axis
	 * @param	invertX	Invert the X axis
	 */
	public function new(trigger:FlxAnalogState, axis:FlxAnalogAxis = EITHER, pixelsPerUnit = 10, deadZone = .1, invertY = false, invertX = false) {
		this.pixelsPerUnit = pixelsPerUnit;
		if (this.pixelsPerUnit < 1) this.pixelsPerUnit = 1;
		this.deadZone = deadZone;
		this.invertX = invertX;
		this.invertY = invertY;

		super(FlxInputDevice.MOUSE, -1, trigger, axis);
	}

	override public function update():Void {
		#if !FLX_NO_MOUSE
		updateXYPosition(FlxG.mouse.x, FlxG.mouse.y);
		#end
	}

	private function updateXYPosition(x:Float, y:Float):Void {
		var xDiff = x - lastX;
		var yDiff = y - lastY;

		lastX = x;
		lastY = y;

		if (invertX) xDiff *= -1;
		if (invertY) yDiff *= -1;

		xDiff /= (pixelsPerUnit);
		yDiff /= (pixelsPerUnit);

		if (Math.abs(xDiff) < deadZone) xDiff = 0;
		if (Math.abs(yDiff) < deadZone) yDiff = 0;

		updateValues(xDiff, yDiff);
	}
}

/**
 * @since 4.6.0
 */
class FlxActionInputAnalogMousePosition extends FlxActionInputAnalog {
	/**
	 * Mouse input -- X/Y is the mouse's absolute screen position
	 * @param	Trigger What state triggers this action (MOVED, JUST_MOVED, STOPPED, JUST_STOPPED)
	 * @param	Axis which axes to monitor for triggering: X, Y, EITHER, or BOTH
	 */
	public function new(trigger:FlxAnalogState, axis:FlxAnalogAxis = EITHER) {
		super(FlxInputDevice.MOUSE, -1, trigger, axis);
	}

	override public function update():Void {
		#if !FLX_NO_MOUSE
		updateValues(FlxG.mouse.x, FlxG.mouse.y);
		#end
	}

	override function updateValues(x:Float, y:Float):Void {
		if (x != this.x) xMoved.press();
		else xMoved.release();

		if (y != this.y) yMoved.press();
		else yMoved.release();

		this.x = x;
		this.y = y;
	}
}

/**
 * @since 4.6.0
 */
class FlxActionInputAnalogGamepad extends FlxActionInputAnalog {
	/**
	 * Gamepad action input for analog (trigger, joystick, touchpad, etc) events
	 * @param	inputID "universal" gamepad input ID (LEFT_TRIGGER, RIGHT_ANALOG_STICK, TILT_PITCH, etc)
	 * @param	trigger What state triggers this action (MOVED, JUST_MOVED, STOPPED, JUST_STOPPED)
	 * @param	axis which axes to monitor for triggering: X, Y, EITHER, or BOTH
	 * @param	gamepadID specific gamepad ID, or FlxInputDeviceID.FIRST_ACTIVE / ALL
	 */
	public function new(inputID:FlxGamepadInputID, trigger:FlxAnalogState, axis:FlxAnalogAxis = EITHER, gamepadID:Int = FlxInputDeviceID.FIRST_ACTIVE) {
		super(FlxInputDevice.GAMEPAD, inputID, trigger, axis, gamepadID);
	}

	override public function update():Void {
		if (deviceID == FlxInputDeviceID.ALL) return; // analog data is only meaningful on an individual device

		#if !FLX_NO_GAMEPAD
		var gamepad:FlxGamepad = null;

		if (deviceID == FlxInputDeviceID.FIRST_ACTIVE)
			gamepad = FlxG.gamepads.getFirstActiveGamepad();
		else if (deviceID >= 0)
			gamepad = FlxG.gamepads.getByID(deviceID);

		if (gamepad != null) {
			switch (inputID) {
				case FlxGamepadInputID.LEFT_ANALOG_STICK:
					updateValues(gamepad.analog.value.LEFT_STICK_X, gamepad.analog.value.LEFT_STICK_Y);

				case FlxGamepadInputID.RIGHT_ANALOG_STICK:
					updateValues(gamepad.analog.value.RIGHT_STICK_X, gamepad.analog.value.RIGHT_STICK_Y);

				case FlxGamepadInputID.LEFT_TRIGGER:
					updateValues(gamepad.analog.value.LEFT_TRIGGER, 0);

				case FlxGamepadInputID.RIGHT_TRIGGER:
					updateValues(gamepad.analog.value.RIGHT_TRIGGER, 0);

				case FlxGamepadInputID.POINTER_X:
					updateValues(gamepad.analog.value.POINTER_X, 0);

				case FlxGamepadInputID.POINTER_Y:
					updateValues(gamepad.analog.value.POINTER_Y, 0);

				case FlxGamepadInputID.DPAD:
					updateValues(gamepad.pressed.DPAD_LEFT ? -1 : gamepad.pressed.DPAD_RIGHT ? 1 : 0,
						gamepad.pressed.DPAD_UP ? -1 : gamepad.pressed.DPAD_DOWN ? 1 : 0);
			}
		} else
			updateValues(0, 0);
		#end
	}
}

/**
 * @since 4.6.0
 */
class FlxActionInputAnalogSteam extends FlxActionInputAnalog {
	/**
	 * Steam Controller action input for analog (trigger, joystick, touchpad, etc) events
	 * @param	actionHandle handle received from FlxSteamController.getAnalogActionHandle()
	 * @param	trigger what state triggers this action (MOVING, JUST_MOVED, STOPPED, JUST_STOPPED)
	 * @param	axis which axes to monitor for triggering: X, Y, EITHER, or BOTH
	 * @param	deviceHandle handle received from FlxSteamController.getConnectedControllers(), or FlxInputDeviceID.ALL / FlxInputDeviceID.FIRST_ACTIVE
	 */
	@:allow(flixel.input.actions.FlxActionSet)
	function new(actionHandle:Int, trigger:FlxAnalogState, axis:FlxAnalogAxis = EITHER, deviceID:Int = FlxInputDeviceID.ALL) {
		super(FlxInputDevice.STEAM_CONTROLLER, actionHandle, trigger, axis, deviceID);
		#if FLX_NO_STEAM
		FlxG.log.warn("steamwrap library not installed; steam inputs will be ignored.");
		#end
	}

	override public function update():Void {
		#if FLX_STEAMWRAP
		var handle = deviceID;
		if (handle == FlxInputDeviceID.NONE)
			return;
		else if (deviceID == FlxInputDeviceID.FIRST_ACTIVE)
			handle = FlxSteamController.getFirstActiveHandle();

		analogActionData = FlxSteamController.getAnalogActionData(handle, inputID, analogActionData);
		updateValues(analogActionData.x, analogActionData.y);
		#end
	}

	#if FLX_STEAMWRAP
	private static var analogActionData = new ControllerAnalogActionData();
	#end
}

/**
 * @since 4.6.0
 */
@:access(flixel.input.actions.FlxAction)
class FlxActionInputAnalog extends FlxActionInput {
	public var axis(default, null):FlxAnalogAxis;

	public var x(default, null) = .0;
	public var y(default, null) = .0;
	public var xMoved(default, null):FlxInput<Int>;
	public var yMoved(default, null):FlxInput<Int>;

	static inline var A_X = true;
	static inline var A_Y = false;

	private function new(device:FlxInputDevice, inputID:Int, trigger:FlxAnalogState, axis:FlxAnalogAxis = EITHER, deviceID:Int = FlxInputDeviceID.FIRST_ACTIVE) {
		super(FlxInputType.ANALOG, device, inputID, cast trigger, deviceID);

		this.axis = axis;

		xMoved = new FlxInput<Int>(0);
		yMoved = new FlxInput<Int>(1);
	}

	override public function check(action:FlxAction):Bool {
		final returnVal = switch (axis) {
			case X: compareState(trigger, xMoved.current);
			case Y: compareState(trigger, yMoved.current);
			case BOTH: compareState(trigger, xMoved.current) && compareState(trigger, yMoved.current);
			// in practice, "both pressed" and "both released" could be useful, whereas
			// "both just pressed" and "both just released" seem like very unlikely real-world events
			case EITHER:
				switch (trigger)
				{
					case PRESSED: checkAxis(A_X, PRESSED) || checkAxis(A_Y, PRESSED); // either one pressed
					case RELEASED: checkAxis(A_X, RELEASED) || checkAxis(A_Y, RELEASED); // either one NOT pressed

					case JUST_PRESSED: (checkAxis(A_X, JUST_PRESSED) && checkAxis(A_Y, JUST_PRESSED)) || // both just pressed == whole stick just pressed
						(checkAxis(A_X, JUST_PRESSED) && checkAxis(A_Y, RELEASED)) || // one just pressed & other NOT pressed == whole stick just pressed
						(checkAxis(A_X, RELEASED) && checkAxis(A_Y, JUST_PRESSED));

					case JUST_RELEASED: (checkAxis(A_X,
							JUST_RELEASED) && checkAxis(A_Y,
								RELEASED)) || (checkAxis(A_X,
							RELEASED) && checkAxis(A_Y, JUST_RELEASED)); // one just released & other NOT pressed = whole stick just released
				}
		}

		if (returnVal) {
			action._x ??= x;
			action._y ??= y;
		}

		return returnVal;
	}

	private function checkAxis(isX:Bool, state:FlxInputState):Bool {
		final input = isX ? xMoved : yMoved;
		return compareState(state, input.current);
	}

	private function updateValues(x:Float, y:Float):Void {
		if (x != 0) xMoved.press();
		else xMoved.release();

		if (y != 0) yMoved.press();
		else yMoved.release();

		this.x = x;
		this.y = y;
	}
}

/**
 * @since 4.6.0
 */
enum abstract FlxAnalogAxis(Int) from Int{
	final X = 0;
	final Y = 1;
	final BOTH = 2;
	final EITHER = 3;
}
