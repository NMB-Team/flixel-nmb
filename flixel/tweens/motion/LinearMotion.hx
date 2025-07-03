package flixel.tweens.motion;

/**
 * Determines motion along a line, from one point to another.
 */
class LinearMotion extends Motion {
	/**
	 * Length of the current line of movement.
	 */
	public var distance(get, never):Float;

	// Line information.
	var _fromX = .0;
	var _fromY = .0;
	var _moveX = .0;
	var _moveY = .0;
	var _distance = -1.;

	/**
	 * Starts moving along a line.
	 *
	 * @param	fromX			X start.
	 * @param	fromY			Y start.
	 * @param	toX				X finish.
	 * @param	toY				Y finish.
	 * @param	durationOrSpeed	Duration or speed of the movement.
	 * @param	useDuration		Whether to use the previous param as duration or speed.
	 */
	public function setMotion(fromX:Float, fromY:Float, toX:Float, toY:Float, durationOrSpeed:Float, useDuration = true):LinearMotion {
		_distance = -1;

		x = _fromX = fromX;
		y = _fromY = fromY;

		_moveX = toX - fromX;
		_moveY = toY - fromY;

		duration = useDuration ? durationOrSpeed : (distance / durationOrSpeed);

		start();

		return this;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		x = _fromX + _moveX * scale;
		y = _fromY + _moveY * scale;

		if ((x == (_fromX + _moveX)) && (y == (_fromY + _moveY)) && active && (_secondsSinceStart >= duration)) finished = true;

		if (finished) postUpdate();
	}

	private function get_distance():Float {
		if (_distance >= 0) return _distance;
		return _distance = Math.sqrt(_moveX * _moveX + _moveY * _moveY);
	}
}
