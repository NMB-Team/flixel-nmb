package flixel.input.gamepad;

import flixel.input.FlxInput.FlxInputState;
import flixel.input.gamepad.FlxGamepadMappedInput;
import flixel.input.gamepad.lists.FlxGamepadAnalogList;
import flixel.input.gamepad.lists.FlxGamepadButtonList;
import flixel.input.gamepad.lists.FlxGamepadMotionValueList;
import flixel.input.gamepad.lists.FlxGamepadPointerValueList;
import flixel.input.gamepad.mappings.FlxGamepadMapping;
import flixel.input.gamepad.mappings.LogitechMapping;
import flixel.input.gamepad.mappings.MFiMapping;
import flixel.input.gamepad.mappings.MayflashWiiRemoteMapping;
import flixel.input.gamepad.mappings.OUYAMapping;
import flixel.input.gamepad.mappings.PS4Mapping;
import flixel.input.gamepad.mappings.PSVitaMapping;
import flixel.input.gamepad.mappings.WiiRemoteMapping;
import flixel.input.gamepad.mappings.SwitchProMapping;
import flixel.input.gamepad.mappings.SwitchJoyconLeftMapping;
import flixel.input.gamepad.mappings.SwitchJoyconRightMapping;
import flixel.input.gamepad.mappings.XInputMapping;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxStringUtil;
#if FLX_GAMEINPUT_API
import openfl.ui.GameInputControl;
import openfl.ui.GameInputDevice;
import flixel.math.FlxMath;
#elseif FLX_JOYSTICK_API
import flixel.math.FlxPoint;
#end

@:allow(flixel.input.gamepad)
class FlxGamepad implements IFlxDestroyable {
	public var id(default, null):Int;

	#if FLX_GAMEINPUT_API
	/**
	 * The device name. Used to determine the `model`.
	 */
	public var name(get, never):String;
	#end

	/**
	 * The gamepad model used for the mapping of the IDs.
	 * Defaults to `detectedModel`, but can be changed manually.
	 */
	public var model(default, set):FlxGamepadModel;

	/**
	 * The gamepad model this gamepad has been identified as.
	 */
	public var detectedModel(default, null):FlxGamepadModel;

	/**
	 * The mapping that is used to map the raw hardware IDs to the values in `FlxGamepadInputID`.
	 * Determined by the current `model`.
	 * It's also possible to create a custom mapping and assign it here.
	 */
	public var mapping:FlxGamepadMapping;

	public var connected(default, null) = true;

	/**
	 * For gamepads that can have things plugged into them (the Wii Remote, basically).
	 * Making the user set this helps Flixel properly interpret inputs properly.
	 * EX: if you plug a nunchuk into the Wii Remote, you will get different values for
	 * certain buttons than with the Wii Remote alone.
	 * (This is probably why Wii games ask the player what control scheme they are using.)
	 *
	 * In the future, this could also be used for any attachment that exposes new API features
	 * to the controller, e.g. a microphone or headset
	 */
	public var attachment(default, set):FlxGamepadAttachment;

	/**
	 * Gamepad deadzone. The lower, the more sensitive the gamepad.
	 * Should be between 0.0 and 1.0. Defaults to 0.15.
	 */
	public var deadZone(get, set):Float;

	/**
	 * Which dead zone mode to use for analog sticks.
	 */
	public var deadZoneMode:FlxGamepadDeadZoneMode = INDEPENDENT_AXES;

	/**
	 * Helper class to check if a button is pressed.
	 */
	public var pressed(default, null):FlxGamepadButtonList;

	/**
	 * Helper class to check if a button is released
	 */
	public var released(default, null):FlxGamepadButtonList;

	/**
	 * Helper class to check if a button was just pressed.
	 */
	public var justPressed(default, null):FlxGamepadButtonList;

	/**
	 * Helper class to check if a button was just released.
	 */
	public var justReleased(default, null):FlxGamepadButtonList;

	/**
	 * Helper class to get the justMoved, justReleased, and float values of analog input.
	 */
	public var analog(default, null):FlxGamepadAnalogList;

	/**
	 * Helper class to get the float values of motion-sensing input, if it is supported
	 */
	public var motion(default, null):FlxGamepadMotionValueList;

	/**
	 * Helper class to get the float values of mouse-like pointer input, if it is supported.
	 * (contains continously updated X and Y coordinates, each between 0.0 and 1.0)
	 */
	public var pointer(default, null):FlxGamepadPointerValueList;

	#if FLX_JOYSTICK_API
	public var hat(default, null) = FlxPoint.get();
	public var ball(default, null) = FlxPoint.get();
	#end

	var axis:Array<Float> = [for (i in 0...6) 0];
	var axisActive = false;

	var manager:FlxGamepadManager;
	var _deadZone = .15;

	#if FLX_GAMEINPUT_API
	var _device:GameInputDevice;
	#end

	var buttons:Array<FlxGamepadButton> = [];

	public function new(ID:Int, manager:FlxGamepadManager, ?model:FlxGamepadModel, ?attachment:FlxGamepadAttachment) {
		id = ID;

		this.manager = manager;

		pressed = new FlxGamepadButtonList(FlxInputState.PRESSED, this);
		released = new FlxGamepadButtonList(FlxInputState.RELEASED, this);
		justPressed = new FlxGamepadButtonList(FlxInputState.JUST_PRESSED, this);
		justReleased = new FlxGamepadButtonList(FlxInputState.JUST_RELEASED, this);
		analog = new FlxGamepadAnalogList(this);
		motion = new FlxGamepadMotionValueList(this);
		pointer = new FlxGamepadPointerValueList(this);

		if (model == null) {
			#if vita
			model = PSVITA;
			#elseif ps4
			model = PS4;
			#elseif xbox1
			model = XINPUT;
			#else
			model = XINPUT;
			#end
		}

		attachment ??= NONE;

		this.model = model;
		detectedModel = model;
	}

	private function getButton(rawID:Int):FlxGamepadButton {
		if (rawID == -1) return null;

		var gamepadButton:FlxGamepadButton = buttons[rawID];

		if (gamepadButton == null) {
			gamepadButton = new FlxGamepadButton(rawID);
			buttons[rawID] = gamepadButton;
		}

		return gamepadButton;
	}

	inline function applyAxisFlip(axisValue:Float, axisID:Int):Float {
		if (mapping.isAxisFlipped(axisID)) axisValue *= -1;
		return axisValue;
	}

	/**
	 * Updates the key states (for tracking just pressed, just released, etc).
	 */
	public function update():Void {
		#if FLX_GAMEINPUT_API
		var control:GameInputControl;
		var button:FlxGamepadButton;

		if (_device == null) return;

		for (i in 0..._device.numControls) {
			control = _device.getControlAt(i);

			// quick absolute value for analog sticks
			button = getButton(i);

			if (isAxisForAnalogStick(i))
				handleAxisMove(i, control.value, button.value);

			button.value = control.value;

			final value = Math.abs(control.value);
			if (value < deadZone) button.release();
			else if (value > deadZone) button.press();
		}
		#elseif FLX_JOYSTICK_API
		for (i in 0...axis.length) {
			// do a reverse axis lookup to get a "fake" RawID and generate a button state object
			final button = getButton(mapping.axisIndexToRawID(i));
			if (button != null) {
				// TODO: account for circular deadzone if an analog stick input is detected?
				final value = applyAxisFlip(Math.abs(axis[i]), i);
				if (value > deadZone) button.press();
				else if (value < deadZone) button.release();
			}

			axisActive = false;
		}
		#end

		for (button in buttons)
			button?.update();
	}

	public function reset():Void {
		for (button in buttons)
			button?.reset();

		final numAxis = axis.length;

		for (i in 0...numAxis) axis[i] = 0;

		#if FLX_JOYSTICK_API
		hat.set();
		ball.set();
		#end
	}

	public function destroy():Void {
		connected = false;

		buttons = null;
		axis = null;
		manager = null;

		#if FLX_JOYSTICK_API
		hat = FlxDestroyUtil.put(hat);
		ball = FlxDestroyUtil.put(ball);

		hat = null;
		ball = null;
		#end
	}

	/**
	 * Check the status of a "universal" button ID, auto-mapped to this gamepad (something like FlxGamepadInputID.A).
	 *
	 * @param	ID			"universal" gamepad input ID
	 * @param	Status		The key state to check for
	 * @return	Whether the provided button has the specified status
	 */
	public inline function checkStatus(ID:FlxGamepadInputID, status:FlxInputState):Bool {
		return switch (ID) {
			case FlxGamepadInputID.ANY: anyButton(status);
			case FlxGamepadInputID.NONE: !anyButton(status);
			default: checkStatusRaw(mapping.getRawID(ID), status);
		}
	}

	/**
	 * Check the status of a raw button ID (like XInputID.A).
	 *
	 * @param	rawID	Index into buttons array.
	 * @param	status	The key state to check for
	 * @return	Whether the provided button has the specified status
	 */
	public inline function checkStatusRaw(rawID:Int, status:FlxInputState):Bool {
		final button = buttons[rawID];
		return button != null && button.hasState(status);
	}

	/**
	 * Helper function to check the status of an array of buttons
	 *
	 * @param	IDArray	An array of button IDs
	 * @param	state	The button state to check for
	 * @return	Whether at least one of the keys has the specified status
	 */
	private function checkButtonArrayState(IDArray:Array<FlxGamepadInputID>, status:FlxInputState):Bool {
		if (IDArray == null) return false;

		for (code in IDArray)
			if (checkStatus(code, status))
				return true;

		return false;
	}

	/**
	 * Helper function to check the status of an array of buttons
	 *
	 * @param	IDArray	An array of keys as Strings
	 * @param	state	The key state to check for
	 * @return	Whether at least one of the keys has the specified status
	 */
	private function checkButtonArrayStateRaw(IDArray:Array<Int>, status:FlxInputState):Bool {
		if (IDArray == null) return false;

		for (code in IDArray)
			if (checkStatusRaw(code, status))
				return true;

		return false;
	}

	/**
	 * Check if at least one button from an array of button IDs is pressed.
	 *
	 * @param	IDArray	An array of "universal" gamepad input IDs
	 * @return	Whether at least one of the buttons is pressed
	 */
	public inline function anyPressed(IDArray:Array<FlxGamepadInputID>):Bool {
		return checkButtonArrayState(IDArray, PRESSED);
	}

	/**
	 * Check if at least one button from an array of raw button IDs is pressed.
	 *
	 * @param	rawIDArray	An array of raw button IDs
	 * @return	Whether at least one of the buttons is pressed
	 */
	public inline function anyPressedRaw(rawIDArray:Array<Int>):Bool {
		return checkButtonArrayStateRaw(rawIDArray, PRESSED);
	}

	/**
	 * Check if at least one button from an array of universal button IDs was just pressed.
	 *
	 * @param	IDArray	An array of "universal" gamepad input IDs
	 * @return	Whether at least one of the buttons was just pressed
	 */
	public inline function anyJustPressed(IDArray:Array<FlxGamepadInputID>):Bool {
		return checkButtonArrayState(IDArray, JUST_PRESSED);
	}

	/**
	 * Check if at least one button from an array of raw button IDs was just pressed.
	 *
	 * @param	rawIDArray	An array of raw button IDs
	 * @return	Whether at least one of the buttons was just pressed
	 */
	public inline function anyJustPressedRaw(rawIDArray:Array<Int>):Bool {
		return checkButtonArrayStateRaw(rawIDArray, JUST_PRESSED);
	}

	/**
	 * Check if at least one button from an array of gamepad input IDs was just released.
	 *
	 * @param	IDArray	An array of "universal" gamepad input IDs
	 * @return	Whether at least one of the buttons was just released
	 */
	public inline function anyJustReleased(IDArray:Array<FlxGamepadInputID>):Bool {
		return checkButtonArrayState(IDArray, JUST_RELEASED);
	}

	/**
	 * Check if at least one button from an array of raw button IDs was just released.
	 *
	 * @param	rawIDArray	An array of raw button IDs
	 * @return	Whether at least one of the buttons was just released
	 */
	public inline function anyJustReleasedRaw(rawIDArray:Array<Int>):Bool {
		return checkButtonArrayStateRaw(rawIDArray, JUST_RELEASED);
	}

	/**
	 * Get the first found "universal" ID of the button which is currently pressed.
	 * Returns NONE if no button is pressed.
	 */
	public inline function firstPressedID():FlxGamepadInputID {
		final id = firstPressedRawID();
		if (id < 0) return id;

		return mapping.getID(id);
	}

	/**
	 * Get the first found raw ID of the button which is currently pressed.
	 * Returns -1 if no button is pressed.
	 */
	public function firstPressedRawID():Int {
		for (button in buttons)
			if (button != null && button.pressed)
				return button.ID;

		return -1;
	}

	/**
	 * Get the first found "universal" ButtonID of the button which has been just pressed.
	 * Returns NONE if no button was just pressed.
	 */
	public inline function firstJustPressedID():FlxGamepadInputID {
		final id = firstJustPressedRawID();
		if (id < 0) return id;

		return mapping.getID(id);
	}

	/**
	 * Get the first found raw ID of the button which has been just pressed.
	 * Returns -1 if no button was just pressed.
	 */
	public function firstJustPressedRawID():Int {
		for (button in buttons)
			if (button != null && button.justPressed)
				return button.ID;

		return -1;
	}

	/**
	 * Get the first found "universal" ButtonID of the button which has been just released.
	 * Returns NONE if no button was just released.
	 */
	public inline function firstJustReleasedID():FlxGamepadInputID {
		final id = firstJustReleasedRawID();
		if (id < 0) return id;

		return mapping.getID(id);
	}

	/**
	 * Get the first found raw ID of the button which has been just released.
	 * Returns -1 if no button was just released.
	 */
	public function firstJustReleasedRawID():Int {
		for (button in buttons)
			if (button != null && button.justReleased)
				return button.ID;

		return -1;
	}

	/**
	 * Gets the value of the specified axis using the "universal" ButtonID -
	 * use this only for things like FlxGamepadButtonID.LEFT_TRIGGER,
	 * use getXAxis() / getYAxis() for analog sticks!
	 */
	public function getAxis(axisButtonID:FlxGamepadInputID):Float {
		#if !FLX_JOYSTICK_API
		return getAxisRaw(mapping.getRawID(axisButtonID));
		#else
		final fakeAxisRawID:Int = mapping.checkForFakeAxis(axisButtonID);
		if (fakeAxisRawID == -1) {
			// return the regular axis value
			final rawID = mapping.getRawID(axisButtonID);
			return applyAxisFlip(getAxisRaw(rawID), axisButtonID);
		} else {
			// if analog isn't supported for this input, return the correct digital button input instead
			final btn = getButton(fakeAxisRawID);
			if (btn == null) return 0;
			if (btn.pressed) return 1;
		}
		return 0;
		#end
	}

	/**
	 * Gets the value of the specified axis using the raw ID -
	 * use this only for things like XInputID.LEFT_TRIGGER,
	 * use getXAxis() / getYAxis() for analog sticks!
	 */
	public inline function getAxisRaw(rawAxisID:Int):Float {
		final axisValue = getAxisValue(rawAxisID);
		if (Math.abs(axisValue) > deadZone)	return axisValue;

		return 0;
	}

	private function isAxisForAnalogStick(axisIndex:Int):Bool {
		final leftStick = mapping.leftStick;
		final rightStick = mapping.rightStick;

		if (leftStick != null) {
			if (axisIndex == leftStick.x || axisIndex == leftStick.y)
				return true;
		}

		if (rightStick != null) {
			if (axisIndex == rightStick.x || axisIndex == rightStick.y)
				return true;
		}

		return false;
	}

	inline function getAnalogStickByAxis(axisIndex:Int):FlxGamepadAnalogStick {
		final leftStick = mapping.leftStick;
		final rightStick = mapping.rightStick;

		if (leftStick != null && axisIndex == leftStick.x || axisIndex == leftStick.y)
			return leftStick;
		if (rightStick != null && axisIndex == rightStick.x || axisIndex == rightStick.y)
			return rightStick;
		return null;
	}

	/**
	 * Given a ButtonID for an analog stick, gets the value of its x axis
	 * @param	axesButtonID an analog stick like FlxGamepadButtonID.LEFT_STICK
	 */
	public inline function getXAxis(axesButtonID:FlxGamepadInputID):Float {
		return getAnalogXAxisValue(mapping.getAnalogStick(axesButtonID));
	}

	/**
	 * Given both raw IDs for the axes of an analog stick, gets the value of its x axis
	 */
	public inline function getXAxisRaw(stick:FlxGamepadAnalogStick):Float {
		return getAnalogXAxisValue(stick);
	}

	/**
	 * Given a ButtonID for an analog stick, gets the value of its y axis
	 * @param	axesButtonID an analog stick like FlxGamepadButtonID.LEFT_STICK
	 */
	public inline function getYAxis(axesButtonID:FlxGamepadInputID):Float {
		return getYAxisRaw(mapping.getAnalogStick(axesButtonID));
	}

	/**
	 * Given both raw ID's for the axes of an analog stick, gets the value of its Y axis
	 */
	public function getYAxisRaw(stick:FlxGamepadAnalogStick):Float {
		return getAnalogYAxisValue(stick);
	}

	/**
	 * Convenience method that wraps `getXAxis()` and `getYAxis()` into a `FlxPoint`.
	 *
	 * @param	axesButtonID an analog stick like `FlxGamepadButtonID.LEFT_STICK`
	 * @since	4.3.0
	 */
	public function getAnalogAxes(axesButtonID:FlxGamepadInputID):FlxPoint {
		return FlxPoint.get(getXAxis(axesButtonID), getYAxis(axesButtonID));
	}

	/**
	 * Whether any buttons have the specified input state.
	 */
	public function anyButton(state:FlxInputState = PRESSED):Bool {
		for (button in buttons)
			if (button != null && button.hasState(state))
				return true;

		return false;
	}

	/**
	 * Check to see if any buttons are pressed right or Axis, Ball and Hat moved now.
	 */
	public function anyInput():Bool {
		if (anyButton()) return true;

		final numAxis = axis.length;

		for (i in 0...numAxis)
			if (axis[0] != 0)
				return true;

		#if FLX_JOYSTICK_API
		if (ball.x != 0 || ball.y != 0) return true;
		if (hat.x != 0 || hat.y != 0) return true;
		#end

		return false;
	}

	private function getAxisValue(axisID:Int):Float {
		var axisValue = .0;

		#if FLX_GAMEINPUT_API
		if (axisID == -1) return 0;
		if (_device != null && _device.enabled && FlxMath.inBounds(axisID, 0, _device.numControls - 1)) axisValue = _device.getControlAt(axisID).value;
		#else
		if (axisID < 0 || axisID >= axis.length) return 0;
		axisValue = axis[axisID];
		#end

		if (isAxisForAnalogStick(axisID))
			axisValue = applyAxisFlip(axisValue, axisID);

		return axisValue;
	}

	private function getAnalogXAxisValue(stick:FlxGamepadAnalogStick):Float {
		if (stick == null) return 0;

		return
			if (deadZoneMode == CIRCULAR)
				getAnalogAxisValueCircular(stick, stick.x);
			else
				getAnalogAxisValueIndependent(stick.x);
	}

	private function getAnalogYAxisValue(stick:FlxGamepadAnalogStick):Float {
		if (stick == null) return 0;

		return
			if (deadZoneMode == CIRCULAR)
				getAnalogAxisValueCircular(stick, stick.y);
			else
				getAnalogAxisValueIndependent(stick.y);
	}

	private function getAnalogAxisValueCircular(stick:FlxGamepadAnalogStick, axisID:Int):Float {
		if (stick == null) return 0;

		final xAxis = getAxisValue(stick.x);
		final yAxis = getAxisValue(stick.y);

		final vector = FlxPoint.get(xAxis, yAxis);
		final length = vector.length;
		vector.put();

		if (length > deadZone) return getAxisValue(axisID);

		return 0;
	}

	private function getAnalogAxisValueIndependent(axisID:Int):Float {
		final axisValue = getAxisValue(axisID);
		if (Math.abs(axisValue) > deadZone) return axisValue;

		return 0;
	}

	private function handleAxisMove(axis:Int, newValue:Float, oldValue:Float) {
		newValue = applyAxisFlip(newValue, axis);
		oldValue = applyAxisFlip(oldValue, axis);

		// check to see if we should send digital inputs as well as analog
		final stick = getAnalogStickByAxis(axis);
		if (stick.mode == ONLY_DIGITAL || stick.mode == BOTH) {
			handleAxisMoveSub(stick, axis, newValue, oldValue, 1);
			handleAxisMoveSub(stick, axis, newValue, oldValue, -1);

			if (stick.mode == ONLY_DIGITAL) {} // still haven't figured out how to suppress the analog inputs properly. Oh well.
		}
	}

	private function handleAxisMoveSub(stick:FlxGamepadAnalogStick, axis:Int, value:Float, oldValue:Float, sign = 1.) {
		var digitalButton = -1;

		if (axis == stick.x)
			digitalButton = (sign < 0) ? stick.rawLeft : stick.rawRight;
		else if (axis == stick.y)
			digitalButton = (sign < 0) ? stick.rawUp : stick.rawDown;

		final threshold = stick.digitalThreshold;
		final valueSign = value * sign;
		final oldValueSign = oldValue * sign;

		if (valueSign > threshold && oldValueSign <= threshold) {
			final btn = getButton(digitalButton);
			btn?.press();
		} else if (valueSign <= threshold && oldValueSign > threshold) {
			final btn = getButton(digitalButton);
			btn?.release();
		}
	}

	private function createMappingForModel(model:FlxGamepadModel):FlxGamepadMapping {
		return switch (model) {
			case LOGITECH: new LogitechMapping(attachment);
			case OUYA: new OUYAMapping(attachment);
			case PS4 | PS5: new PS4Mapping(attachment);
			case PSVITA: new PSVitaMapping(attachment);
			case XINPUT: new XInputMapping(attachment);
			case MAYFLASH_WII_REMOTE: new MayflashWiiRemoteMapping(attachment);
			case WII_REMOTE: new WiiRemoteMapping(attachment);
			case MFI: new MFiMapping(attachment);
			case SWITCH_PRO: new SwitchProMapping(attachment);
			case SWITCH_JOYCON_LEFT: new SwitchJoyconLeftMapping(attachment);
			case SWITCH_JOYCON_RIGHT: new SwitchJoyconRightMapping(attachment);
			// default to XInput if we don't have a mapping for this
			case _: new XInputMapping(attachment);
		}
	}

	#if FLX_GAMEINPUT_API
	private function get_name():String {
		if (_device == null) return null;
		return _device.name;
	}
	#end

	private function set_model(model:FlxGamepadModel):FlxGamepadModel {
		this.model = model;
		mapping = createMappingForModel(this.model);

		return this.model;
	}

	private function set_attachment(attachment:FlxGamepadAttachment):FlxGamepadAttachment {
		this.attachment = attachment;
		mapping.attachment = attachment;
		return this.attachment;
	}

	private function get_deadZone():Float {
		return (manager == null || manager.globalDeadZone == null) ? _deadZone : manager.globalDeadZone;
	}

	inline function set_deadZone(deadZone:Float):Float {
		return _deadZone = deadZone;
	}

	/**
	 * A string representing the label of the target input. For instance, on a PS4 gamepad
	 * `A` is "x", while Xbox is "a" and the Switch pro controller is "B"
	 * @since 4.8.0
	 */
	public inline function getInputLabel(id:FlxGamepadInputID) {
		return mapping.getInputLabel(id);
	}

	/**
	 * The value of the target gamepad input. For instance, on a PS4 gamepad `A` is `PS4(PS4ID.X)`,
	 * while Xbox is `X_INPUT(XInputID.A)` and the Switch pro controller is `SWITCH_PRO(SwitchProID.B)`
	 * @since 5.9.0
	 */
	public function getMappedInput(id:FlxGamepadInputID):FlxGamepadMappedInput {
		return mapping.getMappedInput(id);
	}

	public function toString():String {
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("id", id),
			LabelValuePair.weak("model", model),
			LabelValuePair.weak("deadZone", deadZone)
		]);
	}
}

enum FlxGamepadDeadZoneMode {
	/**
	 * The value of each axis is compared to the deadzone individually.
	 * Works better when an analog stick is used like arrow keys for 4-directional-input.
	 */
	INDEPENDENT_AXES;

	/**
	 * X and y are combined against the deadzone combined.
	 * Works better when an analog stick is used as a two-dimensional control surface.
	 */
	CIRCULAR;
}

enum FlxGamepadModel {
	LOGITECH;
	OUYA;
	PS4;
	PS5;
	PSVITA;
	XINPUT;
	MAYFLASH_WII_REMOTE;
	WII_REMOTE;
	MFI;

	/**
	 * @since 4.8.0
	 */
	SWITCH_PRO; // also dual joycons

	/**
	 * @since 4.8.0
	 */
	SWITCH_JOYCON_LEFT;

	/**
	 * @since 4.8.0
	 */
	SWITCH_JOYCON_RIGHT;

	UNKNOWN;
}

enum FlxGamepadAttachment {
	WII_NUNCHUCK;
	WII_CLASSIC_CONTROLLER;
	NONE;
}
