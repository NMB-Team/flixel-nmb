package flixel.input.gamepad.id;

import flixel.input.gamepad.FlxGamepadAnalogStick;

/**
 * IDs for Switch's Right JoyCon controllers
 *
 *-------
 * NOTES
 *-------
 *
 * WINDOWS: untested.
 *
 * LINUX: untested.
 *
 * MAC: Worked on html out of box for me when connected via microUSB cable or Bluetooth.
 * which is weird because The pro worked wirelessly.
 *
 * @since 4.8.0
 */

enum abstract SwitchJoyconRightID(Int) to Int {
	final ZR = 5;
	final A = 6;
	final X = 7;
	final B = 8;
	final Y = 9;
	final R = 10;
	final HOME = 11;
	final PLUS = 12;
	final LEFT_STICK_CLICK = 13;
	final SL = 15;
	final SR = 16;

	final LEFT_STICK_UP = 22;
	final LEFT_STICK_DOWN = 23;
	final LEFT_STICK_LEFT = 24;
	final LEFT_STICK_RIGHT = 25;

	public static final LEFT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<SwitchJoyconRightID>(0, 1, {
		up: LEFT_STICK_UP,
		down: LEFT_STICK_DOWN,
		left: LEFT_STICK_LEFT,
		right: LEFT_STICK_RIGHT
	});
}
