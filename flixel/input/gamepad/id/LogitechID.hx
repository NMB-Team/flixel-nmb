package flixel.input.gamepad.id;

import flixel.input.gamepad.FlxGamepadAnalogStick;

/**
 * IDs for Logitech controllers (key codes based on Cordless Rumblepad 2)
 */
enum abstract LogitechID(Int) to Int {
	final ONE = 0;
	final TWO = 1;
	final THREE = 2;
	final FOUR = 3;
	final FIVE = 4;
	final SIX = 5;
	final SEVEN = 6;
	final EIGHT = 7;
	final NINE = 8;
	final TEN = 9;
	final LEFT_STICK_CLICK = 10;
	final RIGHT_STICK_CLICK = 11;

	// "fake" IDs, we manually watch for hat axis changes and then send events using these otherwise unused joystick button codes
	final DPAD_UP = 16;
	final DPAD_DOWN = 17;
	final DPAD_LEFT = 18;
	final DPAD_RIGHT = 19;

	// TODO: Someone needs to look this up and define it! (NOTE: not all logitech controllers have this)
	final LOGITECH = -5;

	final LEFT_STICK_UP = 24;
	final LEFT_STICK_DOWN = 25;
	final LEFT_STICK_LEFT = 26;
	final LEFT_STICK_RIGHT = 27;

	final RIGHT_STICK_UP = 28;
	final RIGHT_STICK_DOWN = 29;
	final RIGHT_STICK_LEFT = 30;
	final RIGHT_STICK_RIGHT = 31;

	public static final LEFT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<LogitechID>(0, 1, {
		up: LEFT_STICK_UP,
		down: LEFT_STICK_DOWN,
		left: LEFT_STICK_LEFT,
		right: LEFT_STICK_RIGHT
	});

	public static final RIGHT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<LogitechID>(2, 3, {
		up: RIGHT_STICK_UP,
		down: RIGHT_STICK_DOWN,
		left: RIGHT_STICK_LEFT,
		right: RIGHT_STICK_RIGHT
	});
}
