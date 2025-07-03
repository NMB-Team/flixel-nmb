package flixel.input.gamepad.id;

import flixel.input.gamepad.FlxGamepadAnalogStick;

/**
	* IDs for PlayStation 4 controllers
	*
	*-------
	* NOTES
	*-------
	*
	* WINDOWS: seems to work fine without any special drivers on Windows 10 (and I seem to recall the same on Windows 7).
	* DS4Windows is the popular 3rd-party utility here, but it will make the PS4 controller look like a 360 controller, which
	* means that it will be indistinguishable from an XInput device to flixel (DS4Windows: http://ds4windows.com).
	*
	* LINUX: the PS4 controller will be detected as an XInput device when using xpad (see notes in XInputID.hx)
	*
	* MAC: the PS4 controller seemed to work perfectly without anything special installed, and was not detected in the 360Controller
	* control panel, so it might just work right out of the box!
 */
enum abstract PS4ID(Int) to Int {
	#if FLX_GAMEINPUT_API
	// #if (html5 || windows || mac || linux)
	final X = 6;
	final CIRCLE = 7;
	final SQUARE = 8;
	final TRIANGLE = 9;
	final PS = 11;
	final OPTIONS = 12;
	final LEFT_STICK_CLICK = 13;
	final RIGHT_STICK_CLICK = 14;
	final L1 = 15;
	final R1 = 16;

	#if ps4
	final TOUCHPAD_CLICK = 10; // On an actual PS4, share is reserved by the system, and the touchpad click can serve more or less as a replacement for the "back/select" button

	static inline final LEFT_X = 0;
	static inline final LEFT_Y = 1;
	static inline final RIGHT_X = 2;
	static inline final RIGHT_Y = 3;

	final LEFT_STICK_UP = 32;
	final LEFT_STICK_DOWN = 33;
	final LEFT_STICK_LEFT = 34;
	final LEFT_STICK_RIGHT = 35;

	final RIGHT_STICK_UP = 36;
	final RIGHT_STICK_DOWN = 37;
	final RIGHT_STICK_LEFT = 38;
	final RIGHT_STICK_RIGHT = 39;

	final SHARE = 40; // Not accessible on an actual PS4, just setting it to a dummy value
	#else
	final SHARE = 10; // This is only accessible when not using an actual Playstation 4, otherwise it's reserved by the system

	static inline final LEFT_X = 0;
	static inline final LEFT_Y = 1;
	static inline final RIGHT_X = 2;
	static inline final RIGHT_Y = 3;

	final LEFT_STICK_UP = 22;
	final LEFT_STICK_DOWN = 23;
	final LEFT_STICK_LEFT = 24;
	final LEFT_STICK_RIGHT = 25;

	final RIGHT_STICK_UP = 26;
	final RIGHT_STICK_DOWN = 27;
	final RIGHT_STICK_LEFT = 28;
	final RIGHT_STICK_RIGHT = 29;

	final TOUCHPAD_CLICK = 30; // I don't believe this is normally accessible on PC, just setting it to a dummy value
	#end
	final L2 = 4;
	final R2 = 5;

	final DPAD_UP = 17;
	final DPAD_DOWN = 18;
	final DPAD_LEFT = 19;
	final DPAD_RIGHT = 20;

	// On linux the drivers we're testing with just make the PS4 controller look like an XInput device,
	// So strictly speaking these ID's will probably not be used, but the compiler needs something or
	// else it will not compile on Linux
	#else // "legacy"
	final SQUARE = 0;
	final X = 1;
	final CIRCLE = 2;
	final TRIANGLE = 3;
	final L1 = 4;
	final R1 = 5;

	final SHARE = 8;
	final OPTIONS = 9;
	final LEFT_STICK_CLICK = 10;
	final RIGHT_STICK_CLICK = 11;
	final PS = 12;
	final TOUCHPAD_CLICK = 13;

	final L2 = 3;
	final R2 = 4;

	static inline final LEFT_X = 0;
	static inline final LEFT_Y = 1;
	static inline final RIGHT_X = 2;
	static inline final RIGHT_Y = 5;

	final LEFT_STICK_UP = 27;
	final LEFT_STICK_DOWN = 28;
	final LEFT_STICK_LEFT = 29;
	final LEFT_STICK_RIGHT = 30;

	final RIGHT_STICK_UP = 31;
	final RIGHT_STICK_DOWN = 32;
	final RIGHT_STICK_LEFT = 33;
	final RIGHT_STICK_RIGHT = 34;

	// "fake" IDs, we manually watch for hat axis changes and then send events using these otherwise unused joystick button codes
	final DPAD_LEFT = 15;
	final DPAD_RIGHT = 16;
	final DPAD_DOWN = 17;
	final DPAD_UP = 18;
	#end

	public static final LEFT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<PS4ID>(LEFT_X, LEFT_Y, {
		up: LEFT_STICK_UP,
		down: LEFT_STICK_DOWN,
		left: LEFT_STICK_LEFT,
		right: LEFT_STICK_RIGHT
	});

	public static final RIGHT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<PS4ID>(RIGHT_X, RIGHT_Y, {
		up: RIGHT_STICK_UP,
		down: RIGHT_STICK_DOWN,
		left: RIGHT_STICK_LEFT,
		right: RIGHT_STICK_RIGHT
	});
}

