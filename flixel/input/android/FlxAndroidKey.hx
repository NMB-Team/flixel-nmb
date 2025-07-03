package flixel.input.android;

#if android
import flixel.system.macros.FlxMacroUtil;

/**
 * Maps enum values and strings to integer keycodes.
 */
enum abstract FlxAndroidKey(Int) from Int to Int {
	public static var fromStringMap(default, null):Map<String, FlxAndroidKey> = FlxMacroUtil.buildMap("flixel.input.android.FlxAndroidKey");
	public static var toStringMap(default, null):Map<FlxAndroidKey, String> = FlxMacroUtil.buildMap("flixel.input.android.FlxAndroidKey", true);

	final ANY = -2;
	final NONE = -1;
	final MENU = 0x4000010C;
	final BACK = 0x4000010E;

	@:from public static inline function fromString(s:String) {
		s = s.toUpperCase();
		return fromStringMap.exists(s) ? fromStringMap.get(s) : NONE;
	}

	@:to public inline function toString():String {
		return toStringMap.get(this);
	}
}
#end
