package flixel.input.gamepad.id;

import flixel.input.gamepad.FlxGamepadAnalogStick;

/**
	* IDs for generic XInput controllers
	*
	* Compatible with the Xbox 360 controller, the Xbox One controller, and anything that masquerades as either of those.
	*
	*-------
	* NOTES
	*-------
	*
	* WINDOWS: we assume the user is using the default drivers that ship with windows.
	*
	* LINUX: we assume the user is using the xpad driver, specifically Valve's version, steamos-xpad-dkms
	* (we got weird errors when using xboxdrv). For full instructions on installation, see:
	* http://askubuntu.com/questions/165210/how-do-i-get-an-xbox-360-controller-working/441548#441548
	*
	* MAC: we assume the user is using the 360 Controller driver, specifically this one:
	* https://github.com/360Controller/360Controller/releases
 */
enum abstract XInputID(Int) to Int {
	#if FLX_GAMEINPUT_API
	final A = 6;
	final B = 7;
	final X = 8;
	final Y = 9;

	final BACK = 10;
	final GUIDE = #if mac 11 #else - 1 #end;
	final START = 12;

	final LEFT_STICK_CLICK = 13;
	final RIGHT_STICK_CLICK = 14;

	final LB = 15;
	final RB = 16;

	final DPAD_UP = 17;
	final DPAD_DOWN = 18;
	final DPAD_LEFT = 19;
	final DPAD_RIGHT = 20;

	static inline final LEFT_X = 0;
	static inline final LEFT_Y = 1;
	static inline final RIGHT_X = 2;
	static inline final RIGHT_Y = 3;

	final LEFT_STICK_UP = 21;
	final LEFT_STICK_DOWN = 22;
	final LEFT_STICK_LEFT = 23;
	final LEFT_STICK_RIGHT = 24;

	final RIGHT_STICK_UP = 25;
	final RIGHT_STICK_DOWN = 26;
	final RIGHT_STICK_LEFT = 27;
	final RIGHT_STICK_RIGHT = 28;

	final LEFT_TRIGGER = 4;
	final RIGHT_TRIGGER = 5;
	#elseif FLX_JOYSTICK_API
	#if (windows || linux)
	final A = 0;
	final B = 1;
	final X = 2;
	final Y = 3;

	final LB = 4;
	final RB = 5;

	final BACK = 6;
	final START = 7;

	#if linux
	final LEFT_STICK_CLICK = 9;
	final RIGHT_STICK_CLICK = 10;
	final GUIDE = 8;
	#elseif windows
	final LEFT_STICK_CLICK = 8;
	final RIGHT_STICK_CLICK = 9;
	final GUIDE = 10;
	#end

	// "fake" IDs, we manually watch for hat axis changes and then send events using
	// these otherwise unused joystick button codes
	final DPAD_UP = 11;
	final DPAD_DOWN = 12;
	final DPAD_LEFT = 13;
	final DPAD_RIGHT = 14;

	final LEFT_TRIGGER = 2;
	final RIGHT_TRIGGER = 5;

	static inline final LEFT_X = 0;
	static inline final LEFT_Y = 1;
	static inline final RIGHT_X = 3;
	static inline final RIGHT_Y = 4;

	final LEFT_STICK_UP = 21;
	final LEFT_STICK_DOWN = 22;
	final LEFT_STICK_LEFT = 23;
	final LEFT_STICK_RIGHT = 24;

	final RIGHT_STICK_UP = 25;
	final RIGHT_STICK_DOWN = 26;
	final RIGHT_STICK_LEFT = 27;
	final RIGHT_STICK_RIGHT = 28;
	#else // mac
	final A = 0;
	final B = 1;
	final X = 2;
	final Y = 3;

	final LB = 4;
	final RB = 5;

	final LEFT_STICK_CLICK = 6;
	final RIGHT_STICK_CLICK = 7;

	final BACK = 9;
	final START = 8;

	final GUIDE = 10;

	final DPAD_UP = 11;
	final DPAD_DOWN = 12;
	final DPAD_LEFT = 13;
	final DPAD_RIGHT = 14;

	final LEFT_TRIGGER = 2;
	final RIGHT_TRIGGER = 5;

	static inline final LEFT_X = 0;
	static inline final LEFT_Y = 1;
	static inline final RIGHT_X = 3;
	static inline final RIGHT_Y = 4;

	final LEFT_STICK_UP = 21;
	final LEFT_STICK_DOWN = 22;
	final LEFT_STICK_LEFT = 23;
	final LEFT_STICK_RIGHT = 24;

	final RIGHT_STICK_UP = 25;
	final RIGHT_STICK_DOWN = 26;
	final RIGHT_STICK_LEFT = 27;
	final RIGHT_STICK_RIGHT = 28;
	#end
	#end

	public static final LEFT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<XInputID>(LEFT_X, LEFT_Y, {
		up: LEFT_STICK_UP,
		down: LEFT_STICK_DOWN,
		left: LEFT_STICK_LEFT,
		right: LEFT_STICK_RIGHT
	});

	public static var RIGHT_ANALOG_STICK = new FlxTypedGamepadAnalogStick<XInputID>(RIGHT_X, RIGHT_Y, {
		up: RIGHT_STICK_UP,
		down: RIGHT_STICK_DOWN,
		left: RIGHT_STICK_LEFT,
		right: RIGHT_STICK_RIGHT
	});
}

