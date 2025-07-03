package flixel.input.gamepad.id;

import flixel.input.gamepad.FlxGamepadAnalogStick;

/**
 * IDs for MFi controllers
 */
enum abstract MFiID(Int) to Int {
	final LEFT_TRIGGER = 4;
	final RIGHT_TRIGGER = 5;

	final A = 6;
	final B = 7;
	final X = 8;
	final Y = 9;
	final LB = 15;
	final RB = 16;
	final BACK = 10;
	final GUIDE = 11;
	final START = 12;
	final LEFT_STICK_CLICK = 13;
	final RIGHT_STICK_CLICK = 14;

	final DPAD_UP = 17;
	final DPAD_DOWN = 18;
	final DPAD_LEFT = 19;
	final DPAD_RIGHT = 20;

	final LEFT_STICK_UP = 21;
	final LEFT_STICK_DOWN = 22;
	final LEFT_STICK_LEFT = 23;
	final LEFT_STICK_RIGHT = 24;

	final RIGHT_STICK_UP = 25;
	final RIGHT_STICK_DOWN = 26;
	final RIGHT_STICK_LEFT = 27;
	final RIGHT_STICK_RIGHT = 28;

	public static final LEFT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<MFiID>(0, 1, {
		up: LEFT_STICK_UP,
		down: LEFT_STICK_DOWN,
		left: LEFT_STICK_LEFT,
		right: LEFT_STICK_RIGHT
	});

	public static final RIGHT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<MFiID>(2, 3, {
		up: RIGHT_STICK_UP,
		down: RIGHT_STICK_DOWN,
		left: RIGHT_STICK_LEFT,
		right: RIGHT_STICK_RIGHT
	});
}

