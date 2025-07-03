package flixel.input.gamepad.id;

import flixel.input.gamepad.FlxGamepadAnalogStick;

/**
 * IDs for Switch Pro controllers
 *
 *-------
 * NOTES
 *-------
 *
 * WINDOWS: untested.
 *
 * LINUX: untested
 *
 * MAC: Worked out of box for me when connected via microUSB cable or Bluetooth
 *
 * @since 4.8.0
 */
enum abstract SwitchProID(Int) to Int {
	final ZL = 4;
	final ZR = 5;
	final B = 6;
	final A = 7;
	final Y = 8;
	final X = 9;
	final MINUS = 10;
	final HOME = 11;
	final PLUS = 12;
	final LEFT_STICK_CLICK = 13;
	final RIGHT_STICK_CLICK = 14;
	final L = 15;
	final R = 16;
	final DPAD_UP = 17;
	final DPAD_DOWN = 18;
	final DPAD_LEFT = 19;
	final DPAD_RIGHT = 20;
	final CAPTURE = 21;

	final LEFT_STICK_UP = 22;
	final LEFT_STICK_DOWN = 23;
	final LEFT_STICK_LEFT = 24;
	final LEFT_STICK_RIGHT = 25;

	final RIGHT_STICK_UP = 26;
	final RIGHT_STICK_DOWN = 27;
	final RIGHT_STICK_LEFT = 28;
	final RIGHT_STICK_RIGHT = 29;

	public static final LEFT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<SwitchProID>(0, 1, {
		up: LEFT_STICK_UP,
		down: LEFT_STICK_DOWN,
		left: LEFT_STICK_LEFT,
		right: LEFT_STICK_RIGHT
	});

	public static final RIGHT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<SwitchProID>(2, 3, {
		up: RIGHT_STICK_UP,
		down: RIGHT_STICK_DOWN,
		left: RIGHT_STICK_LEFT,
		right: RIGHT_STICK_RIGHT
	});
}
