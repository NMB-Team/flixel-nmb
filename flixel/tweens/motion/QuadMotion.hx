package flixel.tweens.motion;

import flixel.math.FlxPoint;

/**
 * Determines motion along p1 quadratic curve.
 */
class QuadMotion extends Motion {
	/**
	 * The distance of the entire curve.
	 */
	public var distance(get, never):Float;

	// Curve information.
	var _distance = -1.;
	var _fromX = .0;
	var _fromY = .0;
	var _toX = .0;
	var _toY = .0;
	var _controlX = .0;
	var _controlY = .0;

	/**
	 * Starts moving along the curve.
	 *
	 * @param	fromX			X start.
	 * @param	fromY			Y start.
	 * @param	controlX		X control, used to determine the curve.
	 * @param	controlY		Y control, used to determine the curve.
	 * @param	toX				X finish.
	 * @param	toY				Y finish.
	 * @param	durationOrSpeed	Duration or speed of the movement.
	 * @param	useDuration		Duration of the movement.
	 */
	public function setMotion(fromX:Float, fromY:Float, controlX:Float, controlY:Float, toX:Float, toY:Float, durationOrSpeed:Float, useDuration = true):QuadMotion {
		_distance = -1;

		x = _fromX = fromX;
		y = _fromY = fromY;
		_controlX = controlX;
		_controlY = controlY;
		_toX = toX;
		_toY = toY;

		duration = useDuration ? durationOrSpeed : (distance / durationOrSpeed);

		start();

		return this;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		
		x = _fromX * (1 - scale) * (1 - scale) + _controlX * 2 * (1 - scale) * scale + _toX * scale * scale;
		y = _fromY * (1 - scale) * (1 - scale) + _controlY * 2 * (1 - scale) * scale + _toY * scale * scale;

		if (finished) postUpdate();
	}

	private function get_distance():Float {
		if (_distance >= 0)
			return _distance;

		final p1 = FlxPoint.get();
		final p2 = FlxPoint.get();
		p1.x = x - 2 * _controlX + _toX;
		p1.y = y - 2 * _controlY + _toY;
		p2.x = 2 * _controlX - 2 * x;
		p2.y = 2 * _controlY - 2 * y;
		final a:Float = 4 * (p1.x * p1.x + p1.y * p1.y),
			b:Float = 4 * (p1.x * p2.x + p1.y * p2.y),
			c:Float = p2.x * p2.x + p2.y * p2.y,
			abc:Float = 2 * Math.sqrt(a + b + c),
			a2:Float = Math.sqrt(a),
			a32:Float = 2 * a * a2,
			c2:Float = 2 * Math.sqrt(c),
			ba:Float = b / a2;

		p1.put();
		p2.put();

		return (a32 * abc + a2 * b * (abc - c2) + (4 * c * a - b * b) * Math.log((2 * a2 + ba + abc) / (ba + c2))) / (4 * a32);
	}
}
