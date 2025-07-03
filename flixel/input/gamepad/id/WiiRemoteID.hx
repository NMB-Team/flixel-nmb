package flixel.input.gamepad.id;

import flixel.input.gamepad.FlxGamepadAnalogStick;

/**
 * WiiRemote hardware input ID's when using the device directly
 * Hardware ID's: "Nintendo RVL-CNT-01-TR" and "Nintendo RVL-CNT-01" -- the latter does not have the Motion-Plus attachment
 *
 * NOTE: On Windows this requires the HID-Wiimote driver by Julian Löhr, available here:
 * https://github.com/jloehr/HID-Wiimote
 *
 * @author larsiusprime
 */
enum abstract WiiRemoteID(Int) to Int {
	/**
	 * Things to add:
	 * - Accelerometer (in both remote and nunchuk)
	 * - Gyroscope (in Motion-Plus version only)
	 * - IR camera (position tracking)
	 * - Rumble
	 * - Speaker
	 */
	#if FLX_JOYSTICK_API
	// Standard Wii Remote inputs:
	final REMOTE_ONE = 0;
	final REMOTE_TWO = 1;
	final REMOTE_A = 2;
	final REMOTE_B = 3;
	final REMOTE_PLUS = 4;
	final REMOTE_MINUS = 5;
	final REMOTE_HOME = 6;

	// Nunchuk attachment:
	final NUNCHUK_A = 0;
	final NUNCHUK_B = 1;
	final NUNCHUK_C = 2;
	final NUNCHUK_Z = 3;
	final NUNCHUK_ONE = 4;
	final NUNCHUK_TWO = 5;
	final NUNCHUK_PLUS = 6;
	final NUNCHUK_MINUS = 7;
	final NUNCHUK_HOME = 8;

	// classic controller attachment:
	final CLASSIC_A = 0;
	final CLASSIC_B = 1;
	final CLASSIC_Y = 2;
	final CLASSIC_X = 3;
	final CLASSIC_L = 4;
	final CLASSIC_R = 5;
	final CLASSIC_ZL = 6;
	final CLASSIC_ZR = 7;
	final CLASSIC_START = 8;
	final CLASSIC_SELECT = 9;
	final CLASSIC_HOME = 10;
	final CLASSIC_ONE = 11;
	final CLASSIC_TWO = 12;

	final REMOTE_TILT_PITCH = 2;
	final REMOTE_TILT_ROLL = 3;

	final NUNCHUK_TILT_PITCH = 3;
	final NUNCHUK_TILT_ROLL = 2;

	final REMOTE_NULL_AXIS = 4;
	final NUNCHUK_NULL_AXIS = 4;

	final LEFT_STICK_UP = 32;
	final LEFT_STICK_DOWN = 33;
	final LEFT_STICK_LEFT = 34;
	final LEFT_STICK_RIGHT = 35;

	final RIGHT_STICK_UP = 36;
	final RIGHT_STICK_DOWN = 37;
	final RIGHT_STICK_LEFT = 38;
	final RIGHT_STICK_RIGHT = 39;

	// these aren't real axes, they're simulated when the right digital buttons are pushed
	final LEFT_TRIGGER_FAKE = 4;
	final RIGHT_TRIGGER_FAKE = 5;

	// "fake" ID's
	final REMOTE_DPAD_UP = 14;
	final REMOTE_DPAD_DOWN = 15;
	final REMOTE_DPAD_LEFT = 16;
	final REMOTE_DPAD_RIGHT = 17;

	final REMOTE_DPAD_X = 18;
	final REMOTE_DPAD_Y = 19;

	final CLASSIC_DPAD_DOWN = 24;
	final CLASSIC_DPAD_UP = 25;
	final CLASSIC_DPAD_LEFT = 26;
	final CLASSIC_DPAD_RIGHT = 27;

	final NUNCHUK_DPAD_DOWN = 28;
	final NUNCHUK_DPAD_UP = 29;
	final NUNCHUK_DPAD_LEFT = 30;
	final NUNCHUK_DPAD_RIGHT = 31;
	#else // gamepad API
	// Standard Wii Remote inputs:
	final REMOTE_ONE = 9;
	final REMOTE_TWO = 10;
	final REMOTE_A = 11;
	final REMOTE_B = 12;
	final REMOTE_PLUS = 13;
	final REMOTE_MINUS = 14;
	final REMOTE_HOME = 15;

	// Nunchuk attachment:
	final NUNCHUK_A = 9;
	final NUNCHUK_B = 10;
	final NUNCHUK_C = 11;
	final NUNCHUK_Z = 12;
	final NUNCHUK_ONE = 13;
	final NUNCHUK_TWO = 14;
	final NUNCHUK_PLUS = 15;
	final NUNCHUK_MINUS = 16;
	final NUNCHUK_HOME = 17;

	final NUNCHUK_DPAD_UP = 5;
	final NUNCHUK_DPAD_DOWN = 6;
	final NUNCHUK_DPAD_LEFT = 7;
	final NUNCHUK_DPAD_RIGHT = 8;

	// classic controller attachment:
	final CLASSIC_A = 9;
	final CLASSIC_B = 10;
	final CLASSIC_Y = 11;
	final CLASSIC_X = 12;
	final CLASSIC_L = 13;
	final CLASSIC_R = 14;
	final CLASSIC_ZL = 15;
	final CLASSIC_ZR = 16;
	final CLASSIC_START = 17;
	final CLASSIC_SELECT = 18;
	final CLASSIC_HOME = 19;
	final CLASSIC_ONE = 20;
	final CLASSIC_TWO = 21;

	final CLASSIC_DPAD_UP = 5;
	final CLASSIC_DPAD_DOWN = 6;
	final CLASSIC_DPAD_LEFT = 7;
	final CLASSIC_DPAD_RIGHT = 8;

	final REMOTE_TILT_PITCH = 2;
	final REMOTE_TILT_ROLL = 3;

	final NUNCHUK_TILT_PITCH = 3;
	final NUNCHUK_TILT_ROLL = 2;

	final REMOTE_NULL_AXIS = 4;
	final NUNCHUK_NULL_AXIS = 4;

	final LEFT_STICK_UP = 28;
	final LEFT_STICK_DOWN = 29;
	final LEFT_STICK_LEFT = 30;
	final LEFT_STICK_RIGHT = 31;

	final RIGHT_STICK_UP = 32;
	final RIGHT_STICK_DOWN = 33;
	final RIGHT_STICK_LEFT = 34;
	final RIGHT_STICK_RIGHT = 35;

	// these aren't real axes, they're simulated when the right digital buttons are pushed
	final LEFT_TRIGGER_FAKE = 4;
	final RIGHT_TRIGGER_FAKE = 5;

	// "fake" ID's
	final REMOTE_DPAD_UP = 22;
	final REMOTE_DPAD_DOWN = 23;
	final REMOTE_DPAD_LEFT = 24;
	final REMOTE_DPAD_RIGHT = 25;

	final REMOTE_DPAD_X = 26;
	final REMOTE_DPAD_Y = 27;
	#end

	// Yes, the WiiRemote DPAD is treated as ANALOG for some reason...
	// so we have to pass in some "fake" ID's to get simulated digital inputs
	public static final REMOTE_DPAD = new FlxTypedGamepadAnalogStick<WiiRemoteID>(0, 1, {
		up: REMOTE_DPAD_UP,
		down: REMOTE_DPAD_DOWN,
		left: REMOTE_DPAD_LEFT,
		right: REMOTE_DPAD_RIGHT,
		threshold: .5,
		mode: ONLY_DIGITAL
	});

	/**
	 * the nunchuk only has the "left" analog stick
	 */
	public static final LEFT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<WiiRemoteID>(0, 1, {
		up: LEFT_STICK_UP,
		down: LEFT_STICK_DOWN,
		left: LEFT_STICK_LEFT,
		right: LEFT_STICK_RIGHT
	});

	/**
	 * the classic controller has both the "left" and "right" analog sticks
	 */
	public static final RIGHT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<WiiRemoteID>(2, 3, {
		up: RIGHT_STICK_UP,
		down: RIGHT_STICK_DOWN,
		left: RIGHT_STICK_LEFT,
		right: RIGHT_STICK_RIGHT
	});
}

