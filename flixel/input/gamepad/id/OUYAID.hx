package flixel.input.gamepad.id;

import flixel.input.gamepad.FlxGamepadAnalogStick;

/**
 * IDs for OUYA controllers
 */
enum abstract OUYAID(Int) to Int {
	final O = 6;
	final U = 8;
	final Y = 9;
	final A = 7;
	final LB = 15;
	final RB = 16;
	final LEFT_STICK_CLICK = 13;
	final RIGHT_STICK_CLICK = 14;
	final HOME = 0x01000012;	// Not sure if press HOME is taken in account on OUYA
	final LEFT_TRIGGER = 4;
	final RIGHT_TRIGGER = 5;

	// "fake" IDs, we manually watch for hat axis changes and then send events using these otherwise unused joystick button codes
	final DPAD_LEFT = 19;
	final DPAD_RIGHT = 20;
	final DPAD_DOWN = 18;
	final DPAD_UP = 17;

	final LEFT_STICK_UP = 23;
	final LEFT_STICK_DOWN = 24;
	final LEFT_STICK_LEFT = 25;
	final LEFT_STICK_RIGHT = 26;

	final RIGHT_STICK_UP = 27;
	final RIGHT_STICK_DOWN = 28;
	final RIGHT_STICK_LEFT = 29;
	final RIGHT_STICK_RIGHT = 30;

	// If TRIGGER axis returns value > 0 then LT is being pressed, and if it's < 0 then RT is being pressed
	public static final LEFT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<OUYAID>(0, 1, {
		up: LEFT_STICK_UP,
		down: LEFT_STICK_DOWN,
		left: LEFT_STICK_LEFT,
		right: LEFT_STICK_RIGHT
	});

	public static final RIGHT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<OUYAID>(2, 3, {
		up: RIGHT_STICK_UP,
		down: RIGHT_STICK_DOWN,
		left: RIGHT_STICK_LEFT,
		right: RIGHT_STICK_RIGHT
	});
}

