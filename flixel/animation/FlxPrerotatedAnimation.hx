package flixel.animation;

/**
 * @author Zaphod
 */
class FlxPrerotatedAnimation extends FlxBaseAnimation {
	public static inline final PREROTATED = "prerotated_animation";

	var rotations:Int;
	var baked:Float;

	public function new(parent:FlxAnimationController, baked:Float) {
		super(parent, PREROTATED);
		this.baked = baked;
		rotations = Math.round(360 / baked);
	}

	public var angle(default, set) = .0;

	private function set_angle(value:Float):Float {
		if (Math.isNaN(value))
			FlxG.log.critical("angle must not be NaN");

		final oldIndex = curIndex;
		var angleHelper = Math.floor(value % 360);

		while (angleHelper < 0) angleHelper += 360;

		final newIndex = Math.floor(angleHelper / baked + .5);
		newIndex = Std.int(newIndex % rotations);
		if (oldIndex != newIndex) curIndex = newIndex;

		return angle = value;
	}

	override function set_curIndex(value:Int):Int {
		curIndex = value;
		parent?.frameIndex = value;
		return value;
	}

	override public function clone(parent:FlxAnimationController):FlxPrerotatedAnimation {
		return new FlxPrerotatedAnimation(parent, baked);
	}
}
