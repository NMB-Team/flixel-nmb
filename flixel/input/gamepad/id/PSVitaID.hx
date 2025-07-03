package flixel.input.gamepad.id;

import flixel.input.gamepad.FlxGamepadAnalogStick;

/**
 * Native PSVita input values.
 * (The only way to use these is to actually be using a PSVita with the upcoming openfl vita target!)
 *
 * This will ONLY work with the gamepad API (available only in OpenFL "next", not "legacy") and will NOT work with the joystick API
 */
enum abstract PSVitaID(Int) to Int {
	final X = 6;
	final CIRCLE = 7;
	final SQUARE = 8;
	final TRIANGLE = 9;
	final SELECT = 10;
	final START = 12;
	final L = 15;
	final R = 16;

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

	public static final LEFT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<PSVitaID>(0, 1, {
		up: LEFT_STICK_UP,
		down: LEFT_STICK_DOWN,
		left: LEFT_STICK_LEFT,
		right: LEFT_STICK_RIGHT
	});

	public static final RIGHT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<PSVitaID>(2, 3, {
		up: RIGHT_STICK_UP,
		down: RIGHT_STICK_DOWN,
		left: RIGHT_STICK_LEFT,
		right: RIGHT_STICK_RIGHT
	});
}
