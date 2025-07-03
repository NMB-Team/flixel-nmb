package flixel.tweens.motion;

import flixel.math.FlxMath;

/**
 * Determines a circular motion.
 */
class CircularMotion extends Motion {
	/**
	 * The current position on the circle.
	 */
	public var angle(default, null) = .0;

	/**
	 * The circumference of the current circle motion.
	 */
	public var circumference(get, never):Float;

	// Circle information.
	var _centerX = .0;
	var _centerY = .0;
	var _radius = .0;
	var _angleStart = .0;
	var _angleFinish = .0;

	final twoPI = Math.PI * 2;

	/**
	 * Starts moving along a circle.
	 *
	 * @param	centerX			X position of the circle's center.
	 * @param	centerY			Y position of the circle's center.
	 * @param	radius			Radius of the circle.
	 * @param	angle			Starting position on the circle.
	 * @param	clockwise		If the motion is clockwise.
	 * @param	durationOrSpeed	Duration of the movement.
	 * @param	useDuration		Duration of the movement.
	 */
	public function setMotion(centerX:Float, centerY:Float, radius:Float, angle:Float, clockwise:Bool, durationOrSpeed:Float, useDuration = true):CircularMotion {
		_centerX = centerX;
		_centerY = centerY;
		_radius = radius;

		this.angle = _angleStart = -angle * flixel.math.FlxAngle.TO_RAD;
		_angleFinish = twoPI * (clockwise ? 1 : -1);

		duration = useDuration ? durationOrSpeed : (circumference / durationOrSpeed);

		start();
		return this;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		angle = _angleStart + _angleFinish * scale;

		x = _centerX + FlxMath.fastCos(angle) * _radius;
		y = _centerY + FlxMath.fastSin(angle) * _radius;

		if (finished) postUpdate();
	}

	private function get_circumference():Float {
		return twoPI * _radius;
	}
}
