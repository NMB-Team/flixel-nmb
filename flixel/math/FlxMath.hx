package flixel.math;

import openfl.geom.Rectangle;
import flixel.util.FlxColor;
#if !macro
import flixel.FlxG;
import flixel.FlxSprite;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end
#end

/**
 * A class containing a set of math-related functions.
 */
class FlxMath
{
	/**
	 * Minimum value of a floating point number.
	 */
	public static inline final MIN_VALUE_FLOAT:Float = #if (js || ios || blackberry) 0.0000000000000001 #else 5e-324 #end;

	/**
	 * Maximum value of a floating point number.
	 */
	public static inline final MAX_VALUE_FLOAT:Float = 1.79e+308;

	/**
	 * Minimum value of an integer.
	 */
	public static inline final MIN_VALUE_INT:Int = -MAX_VALUE_INT;

	/**
	 * Maximum value of an integer.
	 */
	public static inline final MAX_VALUE_INT:Int = 0x7FFFFFFF;

	/**
	 * Approximation of `Math.sqrt(2)`.
	 */
	public static inline final SQUARE_ROOT_OF_TWO:Float = 1.41421356237;

	/**
	 * Used to account for floating-point inaccuracies.
	 */
	public static inline final EPSILON:Float = 0.0000001;

	/**
	 * Euler's constant and the base of the natural logarithm.
	 * Math.E is not a constant in Haxe, so we'll just define it ourselves.
	 */
	public static inline final E = 2.71828182845904523536;

	/**
	 * Quantizes a float value to the nearest multiple of the given snap value.
	 *
	 * @param f The float value to quantize.
	 * @param snap The snap value to quantize to.
	 */
	public static inline function quantize(f:Float, snap:Float)
	{
		return ((Math.fround(f * snap)) / snap);
	}

	/**
	 * Snap a value to another if it's within a certain distance (inclusive).
	 *
	 * Helpful when using functions like `smoothLerpPrecision` to ensure the value actually reaches the target.
	 *
	 * @param base The base value to conditionally snap.
	 * @param target The target value to snap to.
	 * @param threshold Maximum distance between the two for snapping to occur.
	 *
	 * @return `target` if `base` is within `threshold` of it, otherwise `base`.
	 */
	public static function snap(base:Float, target:Float, threshold:Float):Float
	{
		return Math.abs(base - target) <= threshold ? target : base;
	}

	/**
	 * Get the logarithm of a value with a given base.
	 * @param base The base of the logarithm.
	 * @param value The value to get the logarithm of.
	 * @return `log_base(value)`
	 */
	public static function logBase(base:Float, value:Float):Float
	{
		return Math.log(value) / Math.log(base);
	}

	/**
	 * Round a decimal number to have reduced precision (less decimal numbers).
	 *
	 * ```haxe
	 * roundDecimal(1.2485, 2) = 1.25
	 * ```
	 *
	 * @param	value		Any number.
	 * @param	precision	Number of decimals the result should have.
	 * @return	The rounded value of that number.
	 */
	public static function roundDecimal(value:Float, precision:Int):Float
	{
		final mult = (precision > 0) ? Math.pow(10, precision) : 1.;
		return Math.fround(value * mult) / mult;
	}

	/**
	 * Floor a decimal number to a fixed number of decimal places.
	 *
	 * ```haxe
	 * floorDecimal(3.14159, 2) = 3.14
	 * floorDecimal(5.987, 0) = 5
	 * ```
	 *
	 * @param	value		The number to be floored.
	 * @param	decimals	Number of decimal places to keep.
	 * @return	The floored value with specified precision.
	 */
	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1) return Math.floor(value);
		return Math.floor(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
	}

	/**
	 * Get the base-2 exponent of a value.
	 * @param x value
	 * @return `2^x`
	 */
	public static function exp2(x:Float):Float
	{
		return Math.pow(2, x);
	}

	/**
	 * Bound a number by a minimum and maximum. Ensures that this number is
	 * no smaller than the minimum, and no larger than the maximum.
	 * Leaving a bound `null` means that side is unbounded.
	 *
	 * @param	value	Any number.
	 * @param	min		Any number.
	 * @param	max		Any number.
	 * @return	The bounded value of the number.
	 */
	public static inline function bound(value:Float, ?min:Float, ?max:Float):Float
	{
		final lowerBound:Float = (min != null && value < min) ? min : value;
		return (max != null && lowerBound > max) ? max : lowerBound;
	}

	/**
	 * Bound a integer by a minimum and maximum. Ensures that this integer is
	 * no smaller than the minimum, and no larger than the maximum.
	 * Leaving a bound `null` means that side is unbounded.
	 *
	 * @param	value	Any integer.
	 * @param	min		Any integer.
	 * @param	max		Any integer.
	 * @return	The bounded value of the integer.
	 */
	public static inline function boundInt(value:Int, ?min:Int, ?max:Int):Int
	{
		final lowerBound:Int = (min != null && value < min) ? min : value;
		return (max != null && lowerBound > max) ? max : lowerBound;
	}

	/**
	 * Truncates a float value to the specified number of decimal places.
	 *
	 * @param x The float value to be truncated.
	 * @param precision The number of decimal places to truncate to (default is 2).
	 * @param round If true, the value will be rounded to the nearest whole number at the specified precision before being truncated.
	 */
	public static inline function truncateFloat(x:Float, precision = 2, round = false):Float
	{
		final p = Math.pow(10, precision);
		return (round ? Math.round : Math.floor)(precision > 0 ? p * x : x) / (precision > 0 ? p : 1);
	}

	/**
	 * Helper function to get the fractional part of a value.
	 * @param x value
	 * @return `x mod 1`.
	 */
	public static function fract(x:Float):Float
	{
		return x - Math.floor(x);
	}

	/**
	 * Returns the linear interpolation of two numbers if `ratio`
	 * is between 0 and 1, and the linear extrapolation otherwise.
	 *
	 * Examples:
	 *
	 * ```haxe
	 * lerp(a, b, 0) = a
	 * lerp(a, b, 1) = b
	 * lerp(5, 15, 0.5) = 10
	 * lerp(5, 15, -1) = -5
	 * ```
	 */
	public static inline function lerp(a:Float, b:Float, ratio:Float):Float
	{
		return a + ratio * (b - a);
	}

	/**
	 * Calculates frame rate-independent lerp ratio based on time delta.
	 *
	 * @param lerp The interpolation ratio (usually between 0 and 1).
	 * @param elapsed Time elapsed since last frame; defaults to FlxG.elapsed.
	 * @return Adjusted interpolation ratio based on elapsed time.
	 * @since 6.0.0
	 */
	public static function getElapsedLerp(lerp:Float, ?elapsed:Float):Float
	{
		elapsed ??= FlxG.elapsed;
		return (lerp >= 1) ? 1 : (lerp > 0 && elapsed > 0) ? 1 - Math.pow(1 - lerp, elapsed * 60) : 0;
	}

	/**
	 * Calculates the linear interpolation ratio based on the elapsed time.
	 */
	public static function getLerpRatio(factor:Float, ?elapsed:Float):Float
	{
		elapsed ??= FlxG.elapsed;
		// scale the time factor by elapsed time and frame rate, then bound the result between 0 and 1
		return bound(factor * 60 * elapsed, 0, 1);
	}

	/**
	 * Converts a per-frame linear interpolation factor to an exponential decay factor
	 * based on the actual elapsed time.
	 *
	 * Use this to apply consistent smoothing regardless of frame rate.
	 *
	 * @param   lerp     The "strength" of the interpolation (larger = faster convergence)
	 * @param   elapsed  The actual time that has passed, in seconds
	 * @since 6.2.0
	 */
	public static function getExponentialDecayLerp(lerp:Float, elapsed:Float):Float
	{
		return Math.exp(-elapsed * lerp * 60);
	}

		/**
	 * Returns the linear interpolation/extrapolation of two points.
	 * Works the same way as this expression:
	 *
	 * ```haxe
	 * var result = FlxPoint.get(lerp(a.x, b.x, ratio), lerp(a.y, b.y, ratio))
	 * ```
	 *
	 * @see				FlxMath.lerp()
	 * @param result	Optional arg for the returning point
	 */
	public static inline function lerpPoint(a:FlxPoint, b:FlxPoint, ratio:Float, ?result:FlxPoint):FlxPoint
	{
		result ??= FlxPoint.get();

		result.set(lerp(a.x, b.x, ratio), lerp(a.y, b.y, ratio));
		a.putWeak();
		b.putWeak();

		return result;
	}

	/**
	 * Interpolates between two float values using a weighted average.
	 * This is a simple linear interpolation function.
	 *
	 * @param from The starting value.
	 * @param to The target value.
	 * @param weight The weight of the target value, clamped to the range [0, 1].
	 */
	public static inline function ilerp(from:Float, to:Float, weight:Float, ?elapsed:Float):Float
	{
		elapsed ??= FlxG.elapsed;
		return from + bound(weight * 60 * elapsed, 0, 1) * (to - from);
	}

	/**
	 * Returns the linear interpolation of two colors.
	 * Works the same way as `FlxColor.interpolate` method.
	 *
	 * @see FlxMath.lerp
	 * @see FlxColor.interpolate
	 */
	public static inline function lerpColor(a:FlxColor, b:FlxColor, ratio:Float):FlxColor
	{
		final TO_PERCENT = 1 / 255;
		return FlxColor.fromRGBFloat(
			lerp(a.red,   b.red,   ratio) * TO_PERCENT,
			lerp(a.green, b.green, ratio) * TO_PERCENT,
			lerp(a.blue,  b.blue,  ratio) * TO_PERCENT,
			lerp(a.alpha, b.alpha, ratio) * TO_PERCENT
		);
	}

	#if !macro
	/**
	 * Linearly interpolates between two values over time.
	 * The rate of interpolation is frame rate independent.
	 * @param a The starting value.
	 * @param b The ending value.
	 * @param ratio The ratio to interpolate towards the end value.
	 * @param elapsed The time that has elapsed since the last frame.
	 * @return The interpolated value.
	 */
	public static inline function lerpElapsed(a:Float, b:Float, ratio:Float, ?elapsed:Float):Float
	{
		if (equal(a, b))
			return b;

		return lerp(a, b, getElapsedLerp(ratio, elapsed));
	}

	/**
	 * Performs exponential interpolation between two values (a and b) over time.
	 *
	 * @param a The starting value.
	 * @param b The target value.
	 * @param t The interpolation factor (usually in the range [0, 1]).
	 * @param e The elapsed time.
	 */
	public static inline function lerpExpoElapsed(a:Float, b:Float, t:Float, e:Float):Float {
		if (equal(a, b)) return b;

		final decayFactor = getExponentialDecayLerp(t, e);
		return lerp(b, a, decayFactor);
	}

	/**
	 * Exponential decay interpolation.
	 *
	 * Framerate-independent because the rate-of-change is proportional to the difference, so you can
	 * use the time elapsed since the last frame as `deltaTime` and the function will be consistent.
	 *
	 * Equivalent to `smoothLerpPrecision(base, target, deltaTime, halfLife, 0.5)`.
	 *
	 * @param base The starting or current value.
	 * @param target The value this function approaches.
	 * @param deltaTime The change in time along the function in seconds.
	 * @param halfLife Time in seconds to reach halfway to `target`.
	 *
	 * @see https://twitter.com/FreyaHolmer/status/1757918211679650262
	 *
	 * @return The interpolated value.
	 */
	public static function smoothLerpDecay(base:Float, target:Float, deltaTime:Float, halfLife:Float):Float
	{
		if (deltaTime == 0) return base;
		if (base == target) return target;

		return lerp(target, base, exp2(-deltaTime / halfLife));
	}

	/**
	 * Exponential decay interpolation.
	 *
	 * Framerate-independent because the rate-of-change is proportional to the difference, so you can
	 * use the time elapsed since the last frame as `deltaTime` and the function will be consistent.
	 *
	 * Equivalent to `smoothLerpDecay(base, target, deltaTime, -duration / logBase(2, precision))`.
	 *
	 * @param base The starting or current value.
	 * @param target The value this function approaches.
	 * @param deltaTime The change in time along the function in seconds.
	 * @param duration Time in seconds to reach `target` within `precision`, relative to the original distance.
	 * @param precision Relative target precision of the interpolation. Defaults to 1% distance remaining.
	 *
	 * @see https://twitter.com/FreyaHolmer/status/1757918211679650262
	 *
	 * @return The interpolated value.
	 */
	public static function smoothLerpPrecision(base:Float, target:Float, deltaTime:Float, duration:Float, precision = 0.01):Float
	{
		if (deltaTime == 0) return base;
		if (base == target) return target;

		return lerp(target, base, Math.pow(precision, deltaTime / duration));
	}


	/**
	 * Linearly interpolates between two `FlxPoint` values over time.
	 * The rate of interpolation is frame rate independent.
	 * @param a The starting point.
	 * @param b The ending point.
	 * @param ratio The ratio to interpolate towards the end value.
	 * @param result The `FlxPoint` to store the interpolated result. If null, a new `FlxPoint` is created.
	 * @param elapsed The time that has elapsed since the last frame.
	 * @return The interpolated point.
	 */
	public static inline function lerpPointElapsed(a:FlxPoint, b:FlxPoint, ratio:Float, ?result:FlxPoint, ?elapsed:Float):FlxPoint
	{
		if (result == null)
			result = FlxPoint.get();

		if (equal(a.x, b.x) && equal(a.y, b.y))
		{
			result.copyFrom(b);
		}
		else
		{
			ratio = getElapsedLerp(ratio, elapsed);
			result.set(lerp(a.x, b.x, ratio), lerp(a.y, b.y, ratio));
		}
		a.putWeak();
		b.putWeak();
		return result;
	}

	/**
	 * Linearly interpolates between two `FlxColor` values over time.
	 * The rate of interpolation is frame rate independent.
	 * @param a The starting color.
	 * @param b The ending color.
	 * @param ratio The ratio to interpolate towards the end value.
	 * @param elapsed The time that has elapsed since the last frame.
	 * @return The interpolated color.
	 */
	public static inline function lerpColorElapsed(a:FlxColor, b:FlxColor, ratio:Float, ?elapsed:Float):FlxColor
	{
		if (a == b) return b;

		return lerpColor(a, b, getLerpRatio(ratio, elapsed));
	}
	#end

	/**
	 * Checks if number is in defined range. A null bound means that side is unbounded.
	 *
	 * @param Value		Number to check.
	 * @param Min		Lower bound of range.
	 * @param Max 		Higher bound of range.
	 * @return Returns true if Value is in range.
	 */
	public static inline function inBounds(Value:Float, ?Min:Float, ?Max:Float):Bool
	{
		return (Min == null || Value >= Min) && (Max == null || Value <= Max);
	}

	/**
	 * Returns `true` if the given number is odd.
	 */
	public static inline function isOdd(n:Float):Bool
	{
		return (Std.int(n) & 1) != 0;
	}

	/**
	 * Returns `true` if the given number is even.
	 */
	public static inline function isEven(n:Float):Bool
	{
		return (Std.int(n) & 1) == 0;
	}

	/**
	 * Checks if the given integer is a power of two.
	 *
	 * @param n The number to check.
	 * @return True if the number is a power of two, false otherwise.
	 */
	public static inline function isPowerOfTwo(n:Int)
	{
		return n > 0 && (n & (n - 1)) == 0;
	}

	/**
	 * Returns `-1` if `a` is smaller, `1` if `b` is bigger and `0` if both numbers are equal.
	 */
	public static inline function numericComparison(a:Float, b:Float):Int
	{
		return (b > a ? -1 : (a > b ? 1 : 0));
	}

	/**
	 * Converts a normalized percent (0–1) to a value in a given range.
	 */
	public static inline function percentToRange(percent:Float, min:Float, max:Float):Float
	{
		return min + percent * (max - min);
	}

	/**
	 * Calculates the mean of an array of float values.
	 *
	 * The mean is the average value of the array, calculated by summing all the values and dividing by the number of elements.
	 *
	 * @param values The array of float values to calculate the mean of.
	 * @return The mean of the array.
	 */
	public static inline function mean(values:Array<Float>):Float
	{
		final amount = values.length;

		var result = .0;
		var value = .0;

		for (i in 0...amount) {
			value = values[i];
			if (value == 0) continue;
			result += value;
		}

		return result / amount;
	}

	/**
	 * Returns true if the given x/y coordinate is within the given rectangular block
	 *
	 * @param	pointX		The X value to test
	 * @param	pointY		The Y value to test
	 * @param	rectX		The X value of the region to test within
	 * @param	rectY		The Y value of the region to test within
	 * @param	rectWidth	The width of the region to test within
	 * @param	rectHeight	The height of the region to test within
	 *
	 * @return	true if pointX/pointY is within the region, otherwise false
	 */
	public static inline function pointInCoordinates(pointX:Float, pointY:Float, rectX:Float, rectY:Float, rectWidth:Float, rectHeight:Float):Bool
	{
		return pointX >= rectX && pointX <= (rectX + rectWidth) && pointY >= rectY && pointY <= (rectY + rectHeight);
	}

	/**
	 * Returns true if the given x/y coordinate is within the given rectangular block
	 *
	 * @param	pointX		The X value to test
	 * @param	pointY		The Y value to test
	 * @param	rect		The FlxRect to test within
	 * @return	true if pointX/pointY is within the FlxRect, otherwise false
	 */
	public static inline function pointInFlxRect(pointX:Float, pointY:Float, rect:FlxRect):Bool
	{
		return return rect.containsXY(pointX, pointY);
	}

	#if (FLX_MOUSE && !macro)
	/**
	 * Returns true if the mouse world x/y coordinate are within the given rectangular block
	 *
	 * @param	useWorldCoords	If true the world x/y coordinates of the mouse will be used, otherwise screen x/y
	 * @param	rect			The FlxRect to test within. If this is null for any reason this function always returns true.
	 *
	 * @return	true if mouse is within the FlxRect, otherwise false
	 */
	public static inline function mouseInFlxRect(useWorldCoords:Bool, rect:FlxRect):Bool
	{
		if (rect == null)
			return true;

		if (useWorldCoords)
			return pointInFlxRect(Math.floor(FlxG.mouse.x), Math.floor(FlxG.mouse.y), rect);
		else
			return pointInFlxRect(FlxG.mouse.viewX, FlxG.mouse.viewY, rect);
	}
	#end

	/**
	 * Returns true if the given x/y coordinate is within the Rectangle
	 *
	 * @param	pointX		The X value to test
	 * @param	pointY		The Y value to test
	 * @param	rect		The Rectangle to test within
	 * @return	true if pointX/pointY is within the Rectangle, otherwise false
	 */
	public static inline function pointInRectangle(pointX:Float, pointY:Float, rect:Rectangle):Bool
	{
		return pointX >= rect.x && pointX <= rect.right && pointY >= rect.y && pointY <= rect.bottom;
	}

	/**
	 * Adds the given amount to the value, but never lets the value
	 * go over the specified maximum or under the specified minimum.
	 *
	 * @param 	value 	The value to add the amount to
	 * @param 	amount 	The amount to add to the value
	 * @param 	max 	The maximum the value is allowed to be
	 * @param 	min 	The minimum the value is allowed to be
	 * @return The new value
	 */
	public static inline function maxAdd(value:Int, amount:Int, max:Int, min:Int = 0):Int
	{
		value += amount;

		if (value > max)
			value = max;
		else if (value < min)
			value = min;

		return value;
	}

	/**
	 * Calculates the greatest common divisor of two numbers using the Euclidean algorithm.
	 * The Euclidean algorithm is an efficient method for computing the greatest common divisor of two numbers.
	 * It works by repeatedly dividing the larger number by the smaller number until the remainder is 0.
	 * The GCD is then the last non-zero remainder.
	 *
	 * @param a The first number to compute the GCD for.
	 * @param b The second number to compute the GCD for.
	 */
	public static inline function gcd(a, b)
	{
		return b == 0 ? absInt(a) : gcd(b, a % b);
	}

	/**
	 * Makes sure that value always stays between 0 and max,
	 * by wrapping the value around.
	 *
	 * @param 	value 	The value to wrap around
	 * @param 	min		The minimum the value is allowed to be
	 * @param 	max 	The maximum the value is allowed to be
	 * @return The wrapped value
	 */
	public static function wrap(value:Int, min:Int, max:Int):Int
	{
		if (max < min)
			FlxG.log.error('FlxMath.wrap() error: max ($max) must be >= min ($min)');

		final range = max - min + 1;

		if (value < min)
			value += range * Std.int((min - value) / range + 1);

		return min + (value - min) % range;
	}

	/**
	 * Wraps an integer value between a minimum and maximum range.
	 */
	public static inline function wrapInt(value:Int, min:Int, max:Int):Int
	{
		if (max < min)
			FlxG.log.error('FlxMath.wrap() error: max ($max) must be >= min ($min)');

		final range = max - min + 1;
		return min + ((value - min) % range + range) % range;
	}

	/**
	 * Wraps a float value between two values.
	 * If the value is larger than the maximum, it subtracts the range from the value.
	 * If the value is smaller than the minimum, it adds the range to the value.
	 * @param value The value to wrap.
	 * @param min The minimum of the range.
	 * @param max The maximum of the range.
	 */
	public static inline function fwrap(value:Float, min:Float, max:Float):Float
	{
		if (max < min)
			FlxG.log.error('FlxMath.wrap() error: max ($max) must be >= min ($min)');

		final range = max - min;
		return min + ((value < min ? value + range : value) - min) % (range + FlxPoint.EPSILON_SQUARED);
	}

	public static inline function wrapMax(value:Int, max:Int):Int
	{
		final range = max + 1;
		value = value % range;

		if (value < 0)
			value += range;

		return value;
	}

	/**
	 * Remaps a number from one range to another.
	 *
	 * @param 	value	The incoming value to be converted
	 * @param 	start1 	Lower bound of the value's current range
	 * @param 	stop1 	Upper bound of the value's current range
	 * @param 	start2  Lower bound of the value's target range
	 * @param 	stop2 	Upper bound of the value's target range
	 * @return The remapped value
	 */
	public static function remapToRange(value:Float, start1:Float, stop1:Float, start2:Float, stop2:Float):Float
	{
		return start2 + (value - start1) * ((stop2 - start2) / (stop1 - start1));
	}

	/**
	 * Finds the dot product value of two vectors
	 *
	 * @param	ax		Vector X
	 * @param	ay		Vector Y
	 * @param	bx		Vector X
	 * @param	by		Vector Y
	 *
	 * @return	Result of the dot product
	 */
	public static inline function dotProduct(ax:Float, ay:Float, bx:Float, by:Float):Float
	{
		return ax * bx + ay * by;
	}

	/**
	 * Returns the length of the given vector.
	 */
	public static inline function vectorLength(dx:Float, dy:Float):Float
	{
		return Math.sqrt(dx * dx + dy * dy);
	}

	#if !macro
	/**
	 * Find the distance (in pixels, rounded) between two FlxSprites, taking their origin into account
	 *
	 * @param	SpriteA		The first FlxSprite
	 * @param	SpriteB		The second FlxSprite
	 * @return	Distance between the sprites in pixels
	 */
	public static inline function distanceBetween(SpriteA:FlxSprite, SpriteB:FlxSprite):Int
	{
		final dx = (SpriteA.x + SpriteA.origin.x) - (SpriteB.x + SpriteB.origin.x);
		final dy = (SpriteA.y + SpriteA.origin.y) - (SpriteB.y + SpriteB.origin.y);
		return Std.int(vectorLength(dx, dy));
	}

	/**
	 * Check if the distance between two FlxSprites is within a specified number.
	 * A faster algorithm than distanceBetween because the Math.sqrt() is avoided.
	 *
	 * @param	SpriteA		The first FlxSprite
	 * @param	SpriteB		The second FlxSprite
	 * @param	Distance	The distance to check
	 * @param	IncludeEqual	If set to true, the function will return true if the calculated distance is equal to the given Distance
	 * @return	True if the distance between the sprites is less than the given Distance
	 */
	public static inline function isDistanceWithin(SpriteA:FlxSprite, SpriteB:FlxSprite, Distance:Float, IncludeEqual:Bool = false):Bool
	{
		final dx = (SpriteA.x + SpriteA.origin.x) - (SpriteB.x + SpriteB.origin.x);
		final dy = (SpriteA.y + SpriteA.origin.y) - (SpriteB.y + SpriteB.origin.y);

		if (IncludeEqual)
			return dx * dx + dy * dy <= Distance * Distance;
		else
			return dx * dx + dy * dy < Distance * Distance;
	}

	/**
	 * Find the distance (in pixels, rounded) from an FlxSprite
	 * to the given FlxPoint, taking the source origin into account.
	 *
	 * @param	Sprite	The FlxSprite
	 * @param	Target	The FlxPoint
	 * @return	Distance in pixels
	 */
	public static inline function distanceToPoint(Sprite:FlxSprite, Target:FlxPoint):Int
	{
		final dx = (Sprite.x + Sprite.origin.x) - Target.x;
		final dy = (Sprite.y + Sprite.origin.y) - Target.y;
		Target.putWeak();
		return Std.int(vectorLength(dx, dy));
	}

	/**
	 * Check if the distance from an FlxSprite to the given
	 * FlxPoint is within a specified number.
	 * A faster algorithm than distanceToPoint because the Math.sqrt() is avoided.
	 *
	 * @param	Sprite	The FlxSprite
	 * @param	Target	The FlxPoint
	 * @param	Distance	The distance to check
	 * @param	IncludeEqual	If set to true, the function will return true if the calculated distance is equal to the given Distance
	 * @return	True if the distance between the sprites is less than the given Distance
	 */
	public static inline function isDistanceToPointWithin(Sprite:FlxSprite, Target:FlxPoint, Distance:Float, IncludeEqual:Bool = false):Bool
	{
		final dx = (Sprite.x + Sprite.origin.x) - (Target.x);
		final dy = (Sprite.y + Sprite.origin.y) - (Target.y);

		Target.putWeak();

		if (IncludeEqual)
			return dx * dx + dy * dy <= Distance * Distance;
		else
			return dx * dx + dy * dy < Distance * Distance;
	}

	#if FLX_MOUSE
	/**
	 * Find the distance (in pixels, rounded) from the object x/y and the mouse x/y
	 *
	 * @param	Sprite	The FlxSprite to test against
	 * @return	The distance between the given sprite and the mouse coordinates
	 */
	public static inline function distanceToMouse(Sprite:FlxSprite):Int
	{
		final dx = (Sprite.x + Sprite.origin.x) - FlxG.mouse.viewX;
		final dy = (Sprite.y + Sprite.origin.y) - FlxG.mouse.viewY;
		return Std.int(vectorLength(dx, dy));
	}

	/**
	 * Check if the distance from the object x/y and the mouse x/y is within a specified number.
	 * A faster algorithm than distanceToMouse because the Math.sqrt() is avoided.
	 *
	 * @param	Sprite		The FlxSprite to test against
	 * @param	Distance	The distance to check
	 * @param	IncludeEqual	If set to true, the function will return true if the calculated distance is equal to the given Distance
	 * @return	True if the distance between the sprites is less than the given Distance
	 */
	public static inline function isDistanceToMouseWithin(Sprite:FlxSprite, Distance:Float, IncludeEqual:Bool = false):Bool
	{
		final dx = (Sprite.x + Sprite.origin.x) - FlxG.mouse.viewX;
		final dy = (Sprite.y + Sprite.origin.y) - FlxG.mouse.viewY;

		if (IncludeEqual)
			return dx * dx + dy * dy <= Distance * Distance;
		else
			return dx * dx + dy * dy < Distance * Distance;
	}
	#end

	#if FLX_TOUCH
	/**
	 * Find the distance (in pixels, rounded) from the object x/y and the FlxPoint screen x/y
	 *
	 * @param	Sprite	The FlxSprite to test against
	 * @param	Touch	The FlxTouch to test against
	 * @return	The distance between the given sprite and the mouse coordinates
	 */
	public static inline function distanceToTouch(Sprite:FlxSprite, Touch:FlxTouch):Int
	{
		final dx = (Sprite.x + Sprite.origin.x) - Touch.viewX;
		final dy = (Sprite.y + Sprite.origin.y) - Touch.viewY;
		return Std.int(vectorLength(dx, dy));
	}

	/**
	 * Check if the distance from the object x/y and the FlxPoint screen x/y is within a specified number.
	 * A faster algorithm than distanceToTouch because the Math.sqrt() is avoided.
	 *
	 * @param	Sprite	The FlxSprite to test against
	 * @param	Distance	The distance to check
	 * @param	IncludeEqual	If set to true, the function will return true if the calculated distance is equal to the given Distance
	 * @return	True if the distance between the sprites is less than the given Distance
	 */
	public static inline function isDistanceToTouchWithin(Sprite:FlxSprite, Touch:FlxTouch, Distance:Float, IncludeEqual:Bool = false):Bool
	{
		final dx = (Sprite.x + Sprite.origin.x) - Touch.viewX;
		final dy = (Sprite.y + Sprite.origin.y) - Touch.viewY;

		if (IncludeEqual)
			return dx * dx + dy * dy <= Distance * Distance;
		else
			return dx * dx + dy * dy < Distance * Distance;
	}
	#end
	#end

	/**
	 * Returns the amount of decimals a `Float` has.
	 */
	public static inline function getDecimals(n:Float):Int
	{
		final numString = Std.string(n);
		final dotIndex = numString.indexOf(".");
		return dotIndex == -1 ? 0 : numString.length - dotIndex - 1;
	}

	public static inline function equal(aValueA:Float, aValueB:Float, aDiff:Float = EPSILON):Bool
	{
		return Math.abs(aValueA - aValueB) <= aDiff;
	}

	/**
	 * Returns `-1` if the number is smaller than `0` and `1` otherwise
	 */
	public static inline function signOf(n:Float):Int
	{
		return (n < 0) ? -1 : 1;
	}

	/**
	 * Checks if two numbers have the same sign (using `FlxMath.signOf()`).
	 */
	public static inline function sameSign(a:Float, b:Float):Bool
	{
		return signOf(a) == signOf(b);
	}

	/**
	 * A faster but slightly less accurate version of `Math.sin()`.
	 * About 2-6 times faster with < 0.05% average error.
	 *
	 * @param	n	The angle in radians.
	 * @return	An approximated sine of `n`.
	 */
	public static inline function fastSin(n:Float):Float
	{
		n *= 0.3183098862; // divide by pi to normalize

		// bound between -1 and 1
		if (n > 1)
			n -= (Math.ceil(n) >> 1) << 1;
		else if (n < -1)
			n += (Math.ceil(-n) >> 1) << 1;

		// this approx only works for -pi <= rads <= pi, but it's quite accurate in this region
		if (n > 0)
			return n * (3.1 + n * (0.5 + n * (-7.2 + n * 3.6)));
		else
			return n * (3.1 - n * (0.5 + n * (7.2 + n * 3.6)));
	}

	/**
	 * A faster, but less accurate version of `Math.cos()`.
	 * About 2-6 times faster with < 0.05% average error.
	 *
	 * @param	n	The angle in radians.
	 * @return	An approximated cosine of `n`.
	 */
	public static inline function fastCos(n:Float):Float
	{
		return fastSin(n + 1.570796327); // sin and cos are the same, offset by pi/2
	}

	/**
	 * A faster, but less accurate version of `Math.tan()`.
	 * About 2-6 times faster with < 0.05% average error.
	 *
	 * @param	n	The angle in radians.
	 * @return	An approximated tangent of `n`.
	 */
	public static inline function fastTan(n:Float):Float
	{
		return fastSin(n) / fastCos(n);
	}

	/**
	 * A faster, but less accurate version of `Math.cos() / Math.sin()` (cotangent).
	 * About 2-6 times faster with < 0.05% average error.
	 *
	 * Be aware: division by zero is possible near `n = 0, π, 2π...`
	 *
	 * @param	n	The angle in radians.
	 * @return	An approximated cotangent of `n`.
	 */
	public static inline function fastCot(n:Float):Float
	{
		return fastCos(n) / fastSin(n);
	}

	/**
	 * A faster, but less accurate version of `1 / Math.cos()`, also known as secant.
	 * About 2–6 times faster than standard math functions, with < 0.05% average error.
	 *
	 * Be cautious near points where `cos(n)` is zero (e.g., `π/2`, `3π/2`, …),
	 * which can cause division by zero or large inaccuracies.
	 *
	 * @param	n	The angle in radians.
	 * @return	An approximated secant of `n`.
	 */
	public static inline function fastSec(n:Float):Float
	{
		return 1 / fastCos(n);
	}

	/**
	 * A faster, but less accurate version of `1 / Math.sin()`, also known as cosecant.
	 * About 2–6 times faster than standard math functions, with < 0.05% average error.
	 *
	 * Be cautious near points where `sin(n)` is zero (e.g., `0`, `π`, `2π`, …),
	 * which can cause division by zero or large inaccuracies.
	 *
	 * @param	n	The angle in radians.
	 * @return	An approximated cosecant of `n`.
	 */
	public static inline function fastCsc(n:Float):Float
	{
		return 1 / fastSin(n);
	}

	/**
	 * Hyperbolic sine.
	 */
	public static inline function sinh(n:Float):Float
	{
		return (Math.exp(n) - Math.exp(-n)) * .5;
	}

	/**
	 * Exponential interpolation
	 * @see https://twitter.com/FreyaHolmer/status/1813629237187817600
	 *
	 * @param a Minimum value of the range
	 * @param b Maximum value of the range
	 * @param t A value from 0.0 to 1.0, optional, by default will be a random value.
	 */
	public static inline function eerp(a:Float, b:Float, ?t:Null<Float>):Float
	{
		t ??= FlxG.random.float();
		return a * Math.exp(t * Math.log(b / a));
	}

	/**
	 * Returns the bigger argument.
	 */
	public static inline function maxInt(a:Int, b:Int):Int
	{
		return (a > b) ? a : b;
	}

	/**
	 * Returns the smaller argument.
	 */
	public static inline function minInt(a:Int, b:Int):Int
	{
		return (a > b) ? b : a;
	}

	/**
	 * Returns the absolute integer value.
	 */
	public static inline function absInt(n:Int):Int
	{
		return (n > 0) ? n : -n;
	}

	/**
	 * Clamps an integer value to ensure it stays within the specified minimum and maximum bounds.
	 */
	public static inline function clamp(v:Int, min:Int, max:Int):Int
	{
		return v < min ? min : (v > max ? max : v);
	}

	/**
	 * Clamps a value between a minimum and maximum value.
	 *
	 * @param val The value to clamp.
	 * @param min The minimum value.
	 * @param max The maximum value.
	 * @return The clamped value.
	 */
	public static inline function fclamp(val:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, val));
	}

	/**
	 * Clamps a float value between 0 and 1.
	 */
	public static inline function clamp01(value:Float):Float
	{
		return value < 0 ? 0 : (value > 1 ? 1 : value);
	}

	/**
	 * Gets the number of digits in a number.
	 */
	public static inline function getDigits(n:Float):Int
	{
		return Std.string(Std.int(Math.abs(n))).length;
	}

	/**
	 * Converts a time in the format `h:m:s` to seconds.
	 * @param h The hours component.
	 * @param m The minutes component.
	 * @param s The seconds component.
	 */
	public static inline function timeToSeconds(h:Float, m:Float, s:Float):Float
	{
		return h * 3600 + m * 60 + s;
	}

	/**
	 * Converts a time in the format `h:m:s` to milliseconds.
	 *
	 * @param h The hours component.
	 * @param m The minutes component.
	 * @param s The seconds component.
	 */
	public static inline function timeToMiliseconds(h:Float, m:Float, s:Float):Float
	{
		return timeToSeconds(h, m, s) * 1000;
	}

	public static inline function normalize(value:Float, min:Float, max:Float)
	{
		final val = (value - min) / (max - min);
		return bound(val, 0, 1);
	}

	/**
	 * Returns null if the given number is NaN, otherwise returns the number itself.
	 * Useful for avoiding NaN values in calculations.
	 */
	public static inline function nullifyNaN(num:Null<Float>):Null<Float>
	{
		return Math.isNaN(num) ? null : num;
	}

	/**
	 * Performs a modulo operation to calculate the remainder of `a` divided by `b`.
	 *
	 * The definition of "remainder" varies by implementation;
	 * this one is similar to GLSL or Python in that it uses Euclidean division, which always returns positive,
	 * while Haxe's `%` operator uses signed truncated division.
	 *
	 * For example, `-5 % 3` returns `-2` while `FlxMath.mod(-5, 3)` returns `1`.
	 *
	 * @param a The dividend.
	 * @param b The divisor.
	 * @return `a mod b`.
	 */
	public static inline function mod(a:Float, b:Float):Float
	{
		b = Math.abs(b);
		return a - b * Math.ffloor(a / b);
	}
}
