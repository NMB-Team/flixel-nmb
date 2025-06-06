package flixel.tweens;

/**
 * Static class with useful easer functions that can be used by tweens.
 *
 * Operation of in/out easers:
 *
 * - **in(t)**:
 *
 *       return t;
 *
 * - **out(t)**
 *
 *       return 1 - in(1 - t);
 *
 * - **inOut(t)**
 *
 *       return (t <= .5) ? in(t * 2) * 0.5 : out(t * 2 - 1) * 0.5 + .5;
 */
class FlxEase
{
	/** Easing constants */
	static var PI2:Float = Math.PI * .5;

	static var EL:Float = 2 * Math.PI / .45;
	static var B1:Float = 1 / 2.75;
	static var B2:Float = 2 / 2.75;
	static var B3:Float = 1.5 / 2.75;
	static var B4:Float = 2.5 / 2.75;
	static var B5:Float = 2.25 / 2.75;
	static var B6:Float = 2.625 / 2.75;
	static var ELASTIC_AMPLITUDE:Float = 1;
	static var ELASTIC_PERIOD:Float = 0.4;

	/** @since 4.3.0 */
	public static inline function linear(t:Float):Float
	{
		return t;
	}

	public static inline function step(t:Float):Float
	{
		return t < 1 ? 0 : 1;
	}

	public static inline function quadIn(t:Float):Float
	{
		return t * t;
	}

	public static inline function quadOut(t:Float):Float
	{
		return -t * (t - 2);
	}

	public static inline function quadInOut(t:Float):Float
	{
		return t <= .5 ? t * t * 2 : 1 - (--t) * t * 2;
	}

	public static inline function cubeIn(t:Float):Float
	{
		return t * t * t;
	}

	public static inline function cubeOut(t:Float):Float
	{
		return 1 + (--t) * t * t;
	}

	public static inline function cubeInOut(t:Float):Float
	{
		return t <= .5 ? t * t * t * 4 : 1 + (--t) * t * t * 4;
	}

	public static inline function quartIn(t:Float):Float
	{
		return t * t * t * t;
	}

	public static inline function quartOut(t:Float):Float
	{
		return 1 - (t -= 1) * t * t * t;
	}

	public static inline function quartInOut(t:Float):Float
	{
		return t <= .5 ? t * t * t * t * 8 : (1 - (t = t * 2 - 2) * t * t * t) * .5 + .5;
	}

	public static inline function quintIn(t:Float):Float
	{
		return t * t * t * t * t;
	}

	public static inline function quintOut(t:Float):Float
	{
		return (t = t - 1) * t * t * t * t + 1;
	}

	public static inline function quintInOut(t:Float):Float
	{
		return ((t *= 2) < 1) ? (t * t * t * t * t) * .5 : ((t -= 2) * t * t * t * t + 2) * .5;
	}

	/** @since 4.3.0 */
	public static inline function smoothStepIn(t:Float):Float
	{
		return 2 * smoothStepInOut(t * .5);
	}

	/** @since 4.3.0 */
	public static inline function smoothStepOut(t:Float):Float
	{
		return 2 * smoothStepInOut(t * .5 + 0.5) - 1;
	}

	/** @since 4.3.0 */
	public static inline function smoothStepInOut(t:Float):Float
	{
		return t * t * (t * -2 + 3);
	}

	/** @since 4.3.0 */
	public static inline function smootherStepIn(t:Float):Float
	{
		return 2 * smootherStepInOut(t * .5);
	}

	/** @since 4.3.0 */
	public static inline function smootherStepOut(t:Float):Float
	{
		return 2 * smootherStepInOut(t * .5 + 0.5) - 1;
	}

	/** @since 4.3.0 */
	public static inline function smootherStepInOut(t:Float):Float
	{
		return t * t * t * (t * (t * 6 - 15) + 10);
	}

	public static inline function sineIn(t:Float):Float
	{
		return -Math.cos(PI2 * t) + 1;
	}

	public static inline function sineOut(t:Float):Float
	{
		return Math.sin(PI2 * t);
	}

	public static inline function sineInOut(t:Float):Float
	{
		return -Math.cos(Math.PI * t) * .5 + .5;
	}

	public static function bounceIn(t:Float):Float
	{
		return 1 - bounceOut(1 - t);
	}

	public static function bounceOut(t:Float):Float
	{
		if (t < B1)
			return 7.5625 * t * t;
		if (t < B2)
			return 7.5625 * (t - B3) * (t - B3) + .75;
		if (t < B4)
			return 7.5625 * (t - B5) * (t - B5) + .9375;
		return 7.5625 * (t - B6) * (t - B6) + .984375;
	}

	public static function bounceInOut(t:Float):Float
	{
		return t < 0.5
			? (1 - bounceOut(1 - 2 * t)) * .5
			: (1 + bounceOut(2 * t - 1)) * .5;
	}

	public static function bounceHardOut(t:Float):Float
	{
		t = 1 - t;
		if (t < B1)
			return 1 - (7.5625 * t * t);
		if (t < B2)
			return 1 - (7.5625 * (t -= B3) * t + 0.75);
		if (t < B4)
			return 1 - (7.5625 * (t -= B5) * t + 0.9375);
		return 1 - (7.5625 * (t -= B6) * t + 0.984375);
	}

	public static inline function circIn(t:Float):Float
	{
		return -(Math.sqrt(1 - t * t) - 1);
	}

	public static inline function circOut(t:Float):Float
	{
		return Math.sqrt(1 - (t - 1) * (t - 1));
	}

	public static function circInOut(t:Float):Float
	{
		return t <= .5 ? (Math.sqrt(1 - t * t * 4) - 1) * -.5 : (Math.sqrt(1 - (t * 2 - 2) * (t * 2 - 2)) + 1) * .5;
	}

	public static function cubicBezierEase(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float
	{
		final u = 1 - t;
		return u * u * u * p0 + 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t * p3;
	}

	public static inline function expoIn(t:Float):Float
	{
		return Math.pow(2, 10 * (t - 1));
	}

	public static inline function expoOut(t:Float):Float
	{
		return -Math.pow(2, -10 * t) + 1;
	}

	public static function expoInOut(t:Float):Float
	{
		return t < .5 ? Math.pow(2, 10 * (t * 2 - 1)) * .5 : (-Math.pow(2, -10 * (t * 2 - 1)) + 2) * .5;
	}

	public static inline function backIn(t:Float):Float
	{
		return t * t * (2.70158 * t - 1.70158);
	}

	public static inline function backOut(t:Float):Float
	{
		return 1 - (--t) * (t) * (-2.70158 * t - 1.70158);
	}

	public static function backInOut(t:Float):Float
	{
		t *= 2;
		if (t < 1)
			return t * t * (2.70158 * t - 1.70158) * .5;
		t--;
		return (1 - (--t) * (t) * (-2.70158 * t - 1.70158)) * .5 + .5;
	}

	public static inline function elasticIn(t:Float):Float
	{
		return -(ELASTIC_AMPLITUDE * Math.pow(2,
			10 * (t -= 1)) * Math.sin((t - (ELASTIC_PERIOD / (2 * Math.PI) * Math.asin(1 / ELASTIC_AMPLITUDE))) * (2 * Math.PI) / ELASTIC_PERIOD));
	}

	public static inline function elasticOut(t:Float):Float
	{
		return (ELASTIC_AMPLITUDE * Math.pow(2,
			-10 * t) * Math.sin((t - (ELASTIC_PERIOD / (2 * Math.PI) * Math.asin(1 / ELASTIC_AMPLITUDE))) * (2 * Math.PI) / ELASTIC_PERIOD)
			+ 1);
	}

	public static function elasticInOut(t:Float):Float
	{
		if (t < 0.5)
		{
			return -0.5 * (Math.pow(2, 10 * (t -= 0.5)) * Math.sin((t - (ELASTIC_PERIOD * .25)) * (2 * Math.PI) / ELASTIC_PERIOD));
		}
		return Math.pow(2, -10 * (t -= 0.5)) * Math.sin((t - (ELASTIC_PERIOD * .25)) * (2 * Math.PI) / ELASTIC_PERIOD) * 0.5 + 1;
	}

	public static inline function powIn(t:Float):Float
	{
		return Math.pow(t, 3);
	}

	public static inline function powOut(t:Float):Float
	{
		return 1 - Math.pow(1 - t, 3);
	}

	public static inline function powInOut(t:Float):Float
	{
		t *= 2;
		if (t < 1)
			return 0.5 * Math.pow(t, 3);
		return 1 - 0.5 * Math.abs(Math.pow(2 - t, 3));
	}
}

typedef EaseFunction = Float->Float;
