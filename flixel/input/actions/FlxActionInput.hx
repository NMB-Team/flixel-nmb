package flixel.input.actions;

import flixel.input.FlxInput.FlxInputState;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

/**
 * @since 4.6.0
 */
@:allow(flixel.input.actions.FlxActionInputDigital, flixel.input.actions.FlxActionInputAnalog)
class FlxActionInput implements IFlxDestroyable {
	/**
	 * Digital or Analog
	 */
	public var type:FlxInputType;

	/**
	 * Mouse, Keyboard, Gamepad, SteamController, etc.
	 */
	public var device:FlxInputDevice;

	/**
	 * Gamepad ID or Steam Controller handle (ignored for Mouse & Keyboard)
	 */
	public var deviceID:Int;

	public var destroyed(default, null) = false;

	/**
	 * Input code (FlxMouseButtonID, FlxKey, FlxGamepadInputID, or Steam Controller action handle)
	 */
	public var inputID(default, null):Int;

	/**
	 * What state triggers this action (PRESSED, JUST_PRESSED, RELEASED, JUST_RELEASED)
	 */
	public var trigger(default, null):FlxInputState;

	private function new(inputType:FlxInputType, device:FlxInputDevice, inputID:Int, trigger:FlxInputState, deviceID:Int = FlxInputDeviceID.FIRST_ACTIVE) {
		type = inputType;
		this.device = device;
		this.inputID = inputID;
		this.trigger = trigger;
		this.deviceID = deviceID;
	}

	public function update():Void {}

	public function destroy():Void {
		destroyed = true;
	}

	/**
	 * Check whether this action has just been triggered
	 */
	public function check(action:FlxAction):Bool {
		return false;
	}

	/**
	 * Check whether `state` fulfills `condition`. Note: order of operations is
	 * important here. `compareState(JUST_PRESSED, PRESSED) == false`, while
	 * `compareState(PRESSED, JUST_PRESSED) == true`.
	 * @return Whether or not the condition is satisfied by state.
	 */
	inline function compareState(condition:FlxInputState, state:FlxInputState):Bool {
		return switch (condition) {
			case PRESSED: state == PRESSED || state == JUST_PRESSED;
			case RELEASED: state == RELEASED || state == JUST_RELEASED;
			case JUST_PRESSED: state == JUST_PRESSED;
			case JUST_RELEASED: state == JUST_RELEASED;
			default: false;
		}
	}
}

/**
 * @since 4.6.0
 */
enum FlxInputType {
	DIGITAL;
	ANALOG;
}

/**
 * @since 4.6.0
 */
enum FlxInputDevice {
	UNKNOWN;
	MOUSE;
	MOUSE_WHEEL;
	KEYBOARD;
	GAMEPAD;
	STEAM_CONTROLLER;
	IFLXINPUT_OBJECT;
	OTHER;
	ANDROID;
	ALL;
	NONE;
}

/**
 * Just a bucket for some handy sentinel values.
 * @since 4.6.0
 */
enum abstract FlxInputDeviceID(Int) from Int to Int {
	/**
	 * Means "every connected device of the given type" (ie all gamepads, all steam controllers, etc)
	 */
	final ALL = -1;

	/**
	 * Means "the first connected device that has an active input" (ie a pressed button or moved analog stick/trigger/etc)
	 */
	final FIRST_ACTIVE = -2;

	/**
	 * Means "no device"
	 */
	final NONE = -3;
}

/**
 * Just a bucket for being able to refer to a specific device by type & slot number
 * @since 4.6.0
 */
class FlxInputDeviceObject {
	public var device:FlxInputDevice;
	public var id:Int;
	public var model:String;

	public function new(device:FlxInputDevice, id:Int, model = "") {
		this.device = device;
		this.id = id;
		this.model = model;
	}

	public function toString():String {
		return "{device:" + device + ",id:" + id + ",model:" + model + "}";
	}
}
