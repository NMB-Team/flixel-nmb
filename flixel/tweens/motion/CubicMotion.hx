package flixel.tweens.motion;

/**
 * Determines motion along a cubic curve.
 */
class CubicMotion extends Motion {
	// Curve information.
	var _fromX = .0;
	var _fromY = .0;
	var _toX = .0;
	var _toY = .0;
	var _aX = .0;
	var _aY = .0;
	var _bX = .0;
	var _bY = .0;
	var _ttt = .0;
	var _tt = .0;

	/**
	 * Starts moving along the curve.
	 *
	 * @param	fromX		X start.
	 * @param	fromY		Y start.
	 * @param	aX			First control x.
	 * @param	aY			First control y.
	 * @param	bX			Second control x.
	 * @param	bY			Second control y.
	 * @param	toX			X finish.
	 * @param	toY			Y finish.
	 * @param	duration	Duration of the movement.
	 */
	public function setMotion(fromX:Float, fromY:Float, aX:Float, aY:Float, bX:Float, bY:Float, toX:Float, toY:Float, duration:Float):CubicMotion {
		x = _fromX = fromX;
		y = _fromY = fromY;
		_aX = aX;
		_aY = aY;
		_bX = bX;
		_bY = bY;
		_toX = toX;
		_toY = toY;

		this.duration = duration;

		start();
		return this;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		final t = scale;
		final u = 1 - t;
		final tt = t * t;
		final uu = u * u;
		
		x = uu * u * _fromX + 3 * uu * t * _aX + 3 * u * tt * _bX + tt * t * _toX;
		y = uu * u * _fromY + 3 * uu * t * _aY + 3 * u * tt * _bY + tt * t * _toY;

		if (finished) postUpdate();
	}
}
