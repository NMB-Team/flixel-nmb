package flixel.input.keyboard;

import flixel.system.macros.FlxMacroUtil;

/**
 * Maps enum values and strings to integer keycodes.
 */
enum abstract FlxKey(Int) from Int to Int {
	public static var fromStringMap(default, null):Map<String, FlxKey> = FlxMacroUtil.buildMap("flixel.input.keyboard.FlxKey", false, []);
	public static var toStringMap(default, null):Map<FlxKey, String> = FlxMacroUtil.buildMap("flixel.input.keyboard.FlxKey", true, []);

	// Key Indicies
	final ANY = -2;
	final NONE = -1;
	final A = 65;
	final B = 66;
	final C = 67;
	final D = 68;
	final E = 69;
	final F = 70;
	final G = 71;
	final H = 72;
	final I = 73;
	final J = 74;
	final K = 75;
	final L = 76;
	final M = 77;
	final N = 78;
	final O = 79;
	final P = 80;
	final Q = 81;
	final R = 82;
	final S = 83;
	final T = 84;
	final U = 85;
	final V = 86;
	final W = 87;
	final X = 88;
	final Y = 89;
	final Z = 90;
	final ZERO = 48;
	final ONE = 49;
	final TWO = 50;
	final THREE = 51;
	final FOUR = 52;
	final FIVE = 53;
	final SIX = 54;
	final SEVEN = 55;
	final EIGHT = 56;
	final NINE = 57;
	final PAGEUP = 33;
	final PAGEDOWN = 34;
	final HOME = 36;
	final END = 35;
	final INSERT = 45;
	final ESCAPE = 27;
	final MINUS = 189;
	final PLUS = 187;
	final DELETE = 46;
	final BACKSPACE = 8;
	final LBRACKET = 219;
	final RBRACKET = 221;
	final BACKSLASH = 220;
	final CAPSLOCK = 20;
	final SCROLL_LOCK = 145;
	final NUMLOCK = 144;
	final SEMICOLON = 186;
	final QUOTE = 222;
	final ENTER = 13;
	final SHIFT = 16;
	final COMMA = 188;
	final PERIOD = 190;
	final SLASH = 191;
	final GRAVEACCENT = 192;
	final CONTROL = 17;
	final ALT = 18;
	final SPACE = 32;
	final UP = 38;
	final DOWN = 40;
	final LEFT = 37;
	final RIGHT = 39;
	final TAB = 9;
	final WINDOWS = 15;
	final MENU = 302;
	final PRINTSCREEN = 301;
	final BREAK = 19;
	final F1 = 112;
	final F2 = 113;
	final F3 = 114;
	final F4 = 115;
	final F5 = 116;
	final F6 = 117;
	final F7 = 118;
	final F8 = 119;
	final F9 = 120;
	final F10 = 121;
	final F11 = 122;
	final F12 = 123;
	final NUMPADZERO = 96;
	final NUMPADONE = 97;
	final NUMPADTWO = 98;
	final NUMPADTHREE = 99;
	final NUMPADFOUR = 100;
	final NUMPADFIVE = 101;
	final NUMPADSIX = 102;
	final NUMPADSEVEN = 103;
	final NUMPADEIGHT = 104;
	final NUMPADNINE = 105;
	final NUMPADMINUS = 109;
	final NUMPADPLUS = 107;
	final NUMPADPERIOD = 110;
	final NUMPADMULTIPLY = 106;
	final NUMPADSLASH = 111;

	@:from public static inline function fromString(s:String) {
		s = s.toUpperCase();
		return fromStringMap.exists(s) ? fromStringMap.get(s) : NONE;
	}

	@:to public inline function toString():String {
		return toStringMap.get(this);
	}
}
