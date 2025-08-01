package flixel.util;

import flixel.math.FlxAngle;

/**
 * Uses bit flags to create a list of orthogonal directions. useful for
 * many `FlxObject` features like `allowCollisions` and `touching`.
 * @since 4.10.0
 */
enum abstract FlxDirectionFlags(Int) {
	final LEFT = 0x0001; // FlxDirection.LEFT;
	final RIGHT = 0x0010; // FlxDirection.RIGHT;
	final UP = 0x0100; // FlxDirection.UP;
	final DOWN = 0x1000; // FlxDirection.DOWN;
	// Directions values can't be constructed from other direction values, due to a bug in haxe.
	// https://github.com/HaxeFoundation/haxe/issues/10237
	// We'll just define all these using literal hex values, otherwise they can't be used as
	// default values for function arguments.

	/** Special-case constant meaning no directions. */
	final NONE = 0x0000;

	/** Special-case constant meaning "up". */
	final CEILING = 0x0100; // UP;

	/** Special-case constant meaning "down" */
	final FLOOR = 0x1000; // DOWN;

	/** Special-case constant meaning "left" and "right". */
	final WALL = 0x0011; // LEFT | RIGHT;

	/** Special-case constant meaning any, or all directions. */
	final ANY = 0x1111; // LEFT | RIGHT | UP | DOWN;

	var self(get, never):FlxDirectionFlags;

	inline function get_self():FlxDirectionFlags {
		return abstract;
	}

	/**
	 * Calculates the angle (in degrees) of the facing flags.
	 * Returns 0 if two opposing flags are true.
	 * @since 5.0.0
	 */
	public var degrees(get, never):Float;
	function get_degrees():Float {
		return switch self {
			case RIGHT: 0;
			case DOWN: 90;
			case UP: -90;
			case LEFT: 180;
			case f if (f == DOWN | RIGHT): 45;
			case f if (f == DOWN | LEFT): 135;
			case f if (f == UP | RIGHT): -45;
			case f if (f == UP | LEFT): -135;
			default: 0;
		}
	}

	/**
	 * Calculates the angle (in radians) of the facing flags.
	 * Returns 0 if two opposing flags are true.
	 * @since 5.0.0
	 */
	public var radians(get, never):Float;
	inline function get_radians():Float {
		return degrees * FlxAngle.TO_RAD;
	}

	/** Whether this has the `UP` flag **/
	public var up(get, never):Bool;
	inline function get_up() return has(UP);

	/** Whether this has the `DOWN` flag **/
	public var down(get, never):Bool;
	inline function get_down() return has(DOWN);

	/** Whether this has the `LEFT` flag **/
	public var left(get, never):Bool;
	inline function get_left() return has(LEFT);

	/** Whether this has the `RIGHT` flag **/
	public var right(get, never):Bool;
	inline function get_right() return has(RIGHT);

	inline function new(value:Int) {
		this = value;
	}

	/**
	 * Returns true if this contains **all** of the supplied flags.
	 */
	public inline function has(dir:FlxDirectionFlags):Bool {
		return this & dir.toInt() == dir.toInt();
	}

	/**
	 * Returns true if this contains **any** of the supplied flags.
	 */
	public inline function hasAny(dir:FlxDirectionFlags):Bool {
		return this & dir.toInt() > 0;
	}

	/**
	 * Creates a new `FlxDirections` that includes the supplied directions.
	 */
	public inline function with(dir:FlxDirectionFlags):FlxDirectionFlags {
		return fromInt(this | dir.toInt());
	}

	/**
	 * Creates a new `FlxDirections` that excludes the supplied directions.
	 */
	public inline function without(dir:FlxDirectionFlags):FlxDirectionFlags {
		return fromInt(this & ~dir.toInt());
	}

	public inline function not():FlxDirectionFlags {
		return fromInt((~this & ANY.toInt()));
	}

	public inline function toInt():Int {
		return this;
	}

	public function toString() {
		if (self == NONE) return "NONE";

		var str = "";
		if (has(LEFT)) str += " | L";
		if (has(RIGHT)) str += " | R";
		if (has(UP)) str += " | U";
		if (has(DOWN)) str += " | D";

		// remove the first " | "
		return str.substr(3);
	}

	/**
	 * Generates a FlxDirectonFlags instance from 2 bools
	 * @since 6.2.0
	 */
	public static function fromSidesBools(left:Bool, right:Bool):FlxDirectionFlags {
		return (left ? LEFT : NONE) | (right ? RIGHT : NONE);
	}

	/**
	 * Generates a FlxDirectonFlags instance from 4 bools
	 * @since 5.0.0
	 */
	public static function fromBools(left:Bool, right:Bool, up:Bool, down:Bool):FlxDirectionFlags {
		return (left  ? LEFT  : NONE)
			|  (right ? RIGHT : NONE)
			|  (up    ? UP    : NONE)
			|  (down  ? DOWN  : NONE);
	}

	public static inline function fromInt(value:Int):FlxDirectionFlags {
		return new FlxDirectionFlags(value);
	}

	@:from static inline function fromDir(dir:FlxDirection):FlxDirectionFlags {
		return fromInt(dir.toInt());
	}

	@:op(A | B) static function or(a:FlxDirectionFlags, b:FlxDirectionFlags):FlxDirectionFlags;
}
