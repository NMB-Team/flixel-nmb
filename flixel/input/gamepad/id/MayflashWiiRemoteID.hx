package flixel.input.gamepad.id;

import flixel.input.gamepad.FlxGamepadAnalogStick;

/**
 * WiiRemote hardware input ID's when using "Mode 3" of the MayFlash DolphinBar accessory
 *
 * @author larsiusprime
 */
enum abstract MayflashWiiRemoteID(Int) to Int {
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

	final REMOTE_MINUS = 4;
	final REMOTE_PLUS = 5;

	final REMOTE_HOME = 11;

	// Nunchuk attachment:
	final NUNCHUK_Z = 6;
	final NUNCHUK_C = 7;

	final NUNCHUK_DPAD_DOWN = 12;
	final NUNCHUK_DPAD_UP = 13;
	final NUNCHUK_DPAD_LEFT = 14;
	final NUNCHUK_DPAD_RIGHT = 15;

	final NUNCHUK_MINUS = 4;
	final NUNCHUK_PLUS = 5;

	final NUNCHUK_HOME = 11;

	final NUNCHUK_ONE = 0;
	final NUNCHUK_TWO = 1;
	final NUNCHUK_A = 2;
	final NUNCHUK_B = 3;

	// classic controller attachment:
	final CLASSIC_Y = 0; // Identical to WiiRemote 1
	final CLASSIC_X = 1; // Identical to WiiRemote 2
	final CLASSIC_B = 2; // Identical to WiiRemote A
	final CLASSIC_A = 3; // Identical to WiiRemote B

	final CLASSIC_L = 4; // Identical to MINUS and PLUS
	final CLASSIC_R = 5;
	final CLASSIC_ZL = 6; // Identical to C and Z
	final CLASSIC_ZR = 7;

	final CLASSIC_SELECT = 8;
	final CLASSIC_START = 9;

	final CLASSIC_HOME = 11;

	final CLASSIC_DPAD_DOWN = 12;
	final CLASSIC_DPAD_UP = 13;
	final CLASSIC_DPAD_LEFT = 14;
	final CLASSIC_DPAD_RIGHT = 15;

	final CLASSIC_ONE = -1;
	final CLASSIC_TWO = -1;
	#else // gamepad API
	// Standard Wii Remote inputs:
	final REMOTE_ONE = 8;
	final REMOTE_TWO = 9;
	final REMOTE_A = 10;
	final REMOTE_B = 11;

	final REMOTE_MINUS = 12;
	final REMOTE_PLUS = 13;

	final REMOTE_HOME = 19;

	// Nunchuk attachment:
	final NUNCHUK_Z = 14;
	final NUNCHUK_C = 15;

	final NUNCHUK_DPAD_UP = 4;
	final NUNCHUK_DPAD_DOWN = 5;
	final NUNCHUK_DPAD_LEFT = 6;
	final NUNCHUK_DPAD_RIGHT = 7;

	final NUNCHUK_MINUS = 12;
	final NUNCHUK_PLUS = 13;

	final NUNCHUK_HOME = 19;

	final NUNCHUK_A = 10;
	final NUNCHUK_B = 11;

	final NUNCHUK_ONE = 8;
	final NUNCHUK_TWO = 9;

	// classic controller attachment:
	final CLASSIC_Y = 8;
	final CLASSIC_X = 9;
	final CLASSIC_B = 10;
	final CLASSIC_A = 11;

	final CLASSIC_L = 12;
	final CLASSIC_R = 13;
	final CLASSIC_ZL = 14;
	final CLASSIC_ZR = 15;

	final CLASSIC_SELECT = 16;
	final CLASSIC_START = 17;

	final CLASSIC_HOME = 19;

	final CLASSIC_ONE = -1;
	final CLASSIC_TWO = -1;

	// (input "10" does not seem to be defined)
	final CLASSIC_DPAD_UP = 4;
	final CLASSIC_DPAD_DOWN = 5;
	final CLASSIC_DPAD_LEFT = 6;
	final CLASSIC_DPAD_RIGHT = 7;
	#end
	// Axis indices
	final NUNCHUK_POINTER_X = 2;
	final NUNCHUK_POINTER_Y = 3;

	final LEFT_STICK_UP = 26;
	final LEFT_STICK_DOWN = 27;
	final LEFT_STICK_LEFT = 28;
	final LEFT_STICK_RIGHT = 29;

	final RIGHT_STICK_UP = 30;
	final RIGHT_STICK_DOWN = 31;
	final RIGHT_STICK_LEFT = 32;
	final RIGHT_STICK_RIGHT = 33;

	// these aren't real axes, they're simulated when the right digital buttons are pushed
	final LEFT_TRIGGER_FAKE = 4;
	final RIGHT_TRIGGER_FAKE = 5;

	// "fake" IDs
	final REMOTE_DPAD_UP = 22;
	final REMOTE_DPAD_DOWN = 23;
	final REMOTE_DPAD_LEFT = 24;
	final REMOTE_DPAD_RIGHT = 25;

	// Yes, the WiiRemote DPAD is treated as ANALOG for some reason...so we have to pass in some "fake" ID's to get simulated digital inputs
	public static final REMOTE_DPAD = new FlxTypedGamepadAnalogStick<MayflashWiiRemoteID>(0, 1, {
		up: REMOTE_DPAD_UP,
		down: REMOTE_DPAD_DOWN,
		left: REMOTE_DPAD_LEFT,
		right: REMOTE_DPAD_RIGHT,
		threshold: .5,
		mode: ONLY_DIGITAL
	});

	public static final LEFT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<MayflashWiiRemoteID>(0, 1, {
		up: LEFT_STICK_UP,
		down: LEFT_STICK_DOWN,
		left: LEFT_STICK_LEFT,
		right: LEFT_STICK_RIGHT
	}); // the nunchuk only has the "left" analog stick

	public static final RIGHT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<MayflashWiiRemoteID>(2, 3, {
		up: RIGHT_STICK_UP,
		down: RIGHT_STICK_DOWN,
		left: RIGHT_STICK_LEFT,
		right: RIGHT_STICK_RIGHT
	}); // the classic controller has both the "left" and "right" analog sticks
}

