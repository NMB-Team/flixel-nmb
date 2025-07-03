package flixel.input.gamepad.id;

import flixel.input.gamepad.FlxGamepadAnalogStick;

/**
 * IDs for Switch's Left JoyCon controllers
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
enum abstract SwitchJoyconLeftID(Int) to Int {
	final ZL = 4;
	final DOWN = 6;
	final RIGHT = 7;
	final LEFT = 8;
	final UP = 9;
	final L = 10;
	final MINUS = 12;
	final LEFT_STICK_CLICK = 13;
	final SL = 15;
	final SR = 16;
	final CAPTURE = 21;

	final LEFT_STICK_UP = 22;
	final LEFT_STICK_DOWN = 23;
	final LEFT_STICK_LEFT = 24;
	final LEFT_STICK_RIGHT = 25;

	public static final LEFT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<SwitchJoyconLeftID>(0, 1, {
		up: LEFT_STICK_UP,
		down: LEFT_STICK_DOWN,
		left: LEFT_STICK_LEFT,
		right: LEFT_STICK_RIGHT
	});
}
