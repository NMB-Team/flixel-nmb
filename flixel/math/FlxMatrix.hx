package flixel.math;

import openfl.geom.Matrix;

/**
 * Helper class for making fast matrix calculations for rendering.
 * It mostly copies Matrix class, but with some additions for
 * faster rotation by 90 degrees.
 */
class FlxMatrix extends Matrix
{
	/**
	 * Whether this matrix is the identity matrix.
	 * @return	Whether this matrix is the identity matrix.
	 */
	public inline function isIdentity():Bool
	{
		return a == 1 && b == 0 && c == 0 && d == 1 && tx == 0 && ty == 0;
	}

	/**
	 * Skews `this` matrix, in radians.
	 * @param	skewX	Horizontal skew in radians.
	 * @param	skewY	Vertical skew in radians.
	 * @return	`this` skewed matrix.
	 */
	public inline function skewRadians(skewX:Float, skewY:Float):FlxMatrix
	{
		b = Math.tan(skewY);

		c = Math.tan(skewX);

		return this;
	}

	/**
	 * Skews `this` matrix, in degrees.
	 * @param	skewY	Horizontal skew in degrees.
	 * @param	skewX	Vertical skew in degrees.
	 * @return	`this` skewed matrix.
	 */
	public inline function skewDegrees(skewX:Float, skewY:Float):FlxMatrix
	{
		return skewRadians(skewY * FlxAngle.TO_RAD, skewX * FlxAngle.TO_RAD);
	}

	/**
	 * Rotates this matrix, but takes the values of sine and cosine,
	 * so it might be useful when you rotate multiple matrices by the same angle
	 * @param	cos	The cosine value for rotation angle
	 * @param	sin	The sine value for rotation angle
	 * @return	this transformed matrix
	 */
	public inline function rotateWithTrig(cos:Float, sin:Float):FlxMatrix
	{
		final a1 = a * cos - b * sin;
		b = a * sin + b * cos;
		a = a1;

		final c1 = c * cos - d * sin;
		d = c * sin + d * cos;
		c = c1;

		final tx1 = tx * cos - ty * sin;
		ty = tx * sin + ty * cos;
		tx = tx1;

		return this;
	}

	/**
	 * Adds 180 degrees to rotation of this matrix
	 * @return	rotated matrix
	 */
	public inline function rotateBy180():FlxMatrix
	{
		this.setTo(-a, -b, -c, -d, -tx, -ty);
		return this;
	}

	/**
	 * Adds 90 degrees to rotation of this matrix
	 * @return	rotated matrix
	 */
	public inline function rotateByPositive90():FlxMatrix
	{
		this.setTo(-b, a, -d, c, -ty, tx);
		return this;
	}

	/**
	 * Subtract 90 degrees from rotation of this matrix
	 * @return	rotated matrix
	 */
	public inline function rotateByNegative90():FlxMatrix
	{
		this.setTo(b, -a, d, -c, ty, -tx);
		return this;
	}

	/**
	 * Transforms x coordinate of the point.
	 * Took original code from openfl.geom.Matrix.
	 *
	 * @param	px	x coordinate of the point
	 * @param	py	y coordinate of the point
	 * @return	transformed x coordinate of the point
	 *
	 * @since 4.3.0
	 */
	public inline function transformX(px:Float, py:Float):Float
	{
		return px * a + py * c + tx;
	}

	/**
	 * Transforms y coordinate of the point.
	 * Took original code from openfl.geom.Matrix.
	 *
	 * @param	px	x coordinate of the point
	 * @param	py	y coordinate of the point
	 * @return	transformed y coordinate of the point
	 *
	 * @since 4.3.0
	 */
	public inline function transformY(px:Float, py:Float):Float
	{
		return px * b + py * d + ty;
	}
}
