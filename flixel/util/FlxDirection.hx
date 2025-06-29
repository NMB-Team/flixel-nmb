package flixel.util;

/**
 * Simple enum for orthogonal directions. Can be combined into `FlxDirectionFlags`.
 * @since 4.10.0
 */
enum abstract FlxDirection(Int) {
	final LEFT = 0x0001;
	final RIGHT = 0x0010;
	final UP = 0x0100;
	final DOWN = 0x1000;

	var self(get, never):FlxDirection;
	inline function get_self():FlxDirection {
		return abstract;
	}

	inline function new(value:Int) {
		this = value;
	}

	public function toString() {
		return switch self {
			case LEFT: "L";
			case RIGHT: "R";
			case UP: "U";
			case DOWN: "D";
		}
	}

	public inline function toInt() {
		return this;
	}

	public static inline function fromInt(value:Int):FlxDirection {
		return new FlxDirection(value);
	}
}
