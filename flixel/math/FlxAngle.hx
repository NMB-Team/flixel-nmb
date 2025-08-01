package flixel.math;

import haxe.macro.Context;
import haxe.macro.Expr;
#if !macro
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxDirectionFlags;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end
#end

/**
 * A set of functions related to angle calculations.
 * In degrees: (down = 90, right = 0, up = -90)
 *
 * Note: in Flixel 5.0.0 all angle-related tools were changed so that 0 degrees points right, instead of up
 * @see [Flixel 5.0.0 Migration guide](https://github.com/HaxeFlixel/flixel/wiki/Flixel-5.0.0-Migration-guide)
 */
class FlxAngle
{
	/**
	 * Convert radians to degrees by multiplying it with this value.
	 */
	public static inline final TO_DEG = 57.295779513082320876798154814105; // 180 / Math.PI;

	/**
	 * Convert degrees to radians by multiplying it with this value.
	 */
	public static inline final TO_RAD = .017453292519943295769236907684886; // Math.PI / 180;

	/**
	 * Generate a sine and cosine table during compilation
	 *
	 * The parameters allow you to specify the length, amplitude and frequency of the wave.
	 * You have to call this function with constant parameters and either use it on your own or assign it to FlxAngle.sincos
	 *
	 * @param length 		The length of the wave
	 * @param sinAmplitude 	The amplitude to apply to the sine table (default 1.0) if you need values between say -+ 125 then give 125 as the value
	 * @param cosAmplitude 	The amplitude to apply to the cosine table (default 1.0) if you need values between say -+ 125 then give 125 as the value
	 * @param frequency 	The frequency of the sine and cosine table data
	 * @return	Returns the cosine/sine table in a FlxSinCos
	 */
	public static macro function sinCosGenerator(length:Int = 360, sinAmplitude:Float = 1.0, cosAmplitude:Float = 1.0, frequency:Float = 1.0):Expr
	{
		final table = {cos: [], sin: []};

		for (c in 0...length)
		{
			final radian = c * frequency * TO_RAD;
			table.cos.push(Math.cos(radian) * cosAmplitude);
			table.sin.push(Math.sin(radian) * sinAmplitude);
		}

		return Context.makeExpr(table, Context.currentPos());
	}

	#if !macro
	/**
	 * Calculates the angle from (0, 0) to (x, y), in radians
	 * @param x The x distance from the origin
	 * @param y The y distance from the origin
	 * @return The angle in radians between -PI to PI
	 */
	public static inline function radiansFromOrigin(x:Float, y:Float)
	{
		return angleFromOrigin(x, y, false);
	}

	/**
	 * Calculates the angle from (0, 0) to (x, y), in degrees
	 * @param x The x distance from the origin
	 * @param y The y distance from the origin
	 * @return The angle in degrees between -180 to 180
	 */
	public static inline function degreesFromOrigin(x:Float, y:Float)
	{
		return angleFromOrigin(x, y, true);
	}

	/**
	 * Calculates the angle from (0, 0) to (x, y)
	 * @param x         The x distance from the origin
	 * @param y         The y distance from the origin
	 * @param asDegrees If true, it gives the value in degrees
	 * @return The angle, either in degrees, between -180 and 180 or in radians, between -PI and PI
	 */
	public static inline function angleFromOrigin(x:Float, y:Float, asDegrees:Bool = false)
	{
		return if (asDegrees) Math.atan2(y, x) * TO_DEG; else Math.atan2(y, x);
	}

	/**
	 * Keeps an angle value between -180 and +180 by wrapping it
	 * e.g an angle of +270 will be converted to -90
	 * Should be called whenever the angle is updated on a FlxSprite to stop it from going insane.
	 *
	 * @param	angle	The angle value to check
	 *
	 * @return	The new angle value, returns the same as the input angle if it was within bounds
	 */
	public static function wrapAngle(angle:Float):Float
	{
		if (angle > 180)
			angle = wrapAngle(angle - 360);
		else if (angle < -180)
			angle = wrapAngle(angle + 360);

		return angle;
	}

	/**
	 * Clamps an angle to the range [0, 360).
	 * Useful for wrapping rotations.
	 */
	public static inline function clampAngle(angle:Float)
	{
		return (angle % 360 + 360) % 360;
	}

	/**
	 * Performs exponential interpolation between two angles (a and b) over time.
	 * This is similar to `lerpElapsed`, but takes into account the circular nature of angles.
	 *
	 * @param a The starting angle.
	 * @param b The target angle.
	 * @param t The interpolation factor (usually in the range [0, 1]).
	 * @param e The elapsed time.
	 */
	public static inline function lerpAngle(a:Float, b:Float, t:Float, e:Float):Float
	{
		final delta = clampAngle((b - a + 180)) - 180;
		final factor = Math.exp(-e * t);
		return a + delta * (1 - factor);
	}

	/**
	 * Calculates the shortest angular difference (in degrees) between two angles.
	 */
	public static inline function angleDifference(a:Float, b:Float):Float
	{
		final diff = (b - a + 180) % 360 - 180;
		return diff < -180 ? diff + 360 : diff;
	}

	/**
	 * Converts a Radian value into a Degree
	 * Converts the radians value into degrees and returns
	 *
	 * @param 	radians 	The value in radians
	 * @return	Degrees
	 */
	public static inline function asDegrees(radians:Float):Float
	{
		return radians * TO_DEG;
	}

	/**
	 * Converts a Degrees value into a Radian
	 * Converts the degrees value into radians and returns
	 *
	 * @param 	degrees The value in degrees
	 * @return	Radians
	 */
	public static inline function asRadians(degrees:Float):Float
	{
		return degrees * TO_RAD;
	}

	/**
	 * Find the angle between the two FlxSprite, taking their x/y and origin into account.
	 *
	 * @param	SpriteA		The FlxSprite to test from
	 * @param	SpriteB		The FlxSprite to test to
	 * @param	AsDegrees	If you need the value in degrees instead of radians, set to true
	 * @return	The angle (in radians unless asDegrees is true)
	 */
	public static function angleBetween(SpriteA:FlxSprite, SpriteB:FlxSprite, AsDegrees:Bool = false):Float
	{
		final dx = (SpriteB.x + SpriteB.origin.x) - (SpriteA.x + SpriteA.origin.x);
		final dy = (SpriteB.y + SpriteB.origin.y) - (SpriteA.y + SpriteA.origin.y);

		return angleFromOrigin(dx, dy, AsDegrees);
	}

	/**
	 * Find the angle (in degrees) between the two FlxSprite, taking their x/y and origin into account.
	 * @since 5.0.0
	 *
	 * @param	SpriteA		The FlxSprite to test from
	 * @param	SpriteB		The FlxSprite to test to
	 * @return	The angle in degrees
	 */
	public static inline function degreesBetween(SpriteA:FlxSprite, SpriteB:FlxSprite):Float
	{
		return angleBetween(SpriteA, SpriteB, true);
	}

	/**
	 * Find the angle (in radians) between the two FlxSprite, taking their x/y and origin into account.
	 * @since 5.0.0
	 *
	 * @param	SpriteA		The FlxSprite to test from
	 * @param	SpriteB		The FlxSprite to test to
	 * @return	The angle in radians
	 */
	public static inline function radiansBetween(SpriteA:FlxSprite, SpriteB:FlxSprite):Float
	{
		return angleBetween(SpriteA, SpriteB, false);
	}

	/**
	 * Find the angle between an FlxSprite and an FlxPoint.
	 * The source sprite takes its x/y and origin into account.
	 *
	 * @param	Sprite		The FlxSprite to test from
	 * @param	Target		The FlxPoint to angle the FlxSprite towards
	 * @param	AsDegrees	If you need the value in degrees instead of radians, set to true
	 * @return	The angle (in radians unless AsDegrees is true)
	 */
	public static function angleBetweenPoint(Sprite:FlxSprite, Target:FlxPoint, AsDegrees:Bool = false):Float
	{
		final dx = (Target.x) - (Sprite.x + Sprite.origin.x);
		final dy = (Target.y) - (Sprite.y + Sprite.origin.y);

		Target.putWeak();

		return angleFromOrigin(dx, dy, AsDegrees);
	}

	/**
	 * Find the angle (in degrees) between an FlxSprite and an FlxPoint.
	 * The source sprite takes its x/y and origin into account.
	 * @since 5.0.0
	 *
	 * @param	Sprite		The FlxSprite to test from
	 * @param	Target		The FlxPoint to angle the FlxSprite towards
	 * @return	The angle in degrees
	 */
	public static inline function degreesBetweenPoint(Sprite:FlxSprite, Target:FlxPoint):Float
	{
		return angleBetweenPoint(Sprite, Target, true);
	}

	/**
	 * Find the angle (in radians) between an FlxSprite and an FlxPoint.
	 * The source sprite takes its x/y and origin into account.
	 * @since 5.0.0
	 *
	 * @param	Sprite		The FlxSprite to test from
	 * @param	Target		The FlxPoint to angle the FlxSprite towards
	 * @return	The angle in radians
	 */
	public static inline function radiansBetweenPoint(Sprite:FlxSprite, Target:FlxPoint):Float
	{
		return angleBetweenPoint(Sprite, Target, false);
	}

	#if FLX_MOUSE
	/**
	 * Find the angle between an FlxSprite and the mouse,
	 * taking their **screen** x/y and origin into account.
	 *
	 * @param	Object		The FlxObject to test from
	 * @param	AsDegrees	If you need the value in degrees instead of radians, set to true
	 * @return	The angle (in radians unless AsDegrees is true)
	 */
	public static function angleBetweenMouse(Object:FlxObject, AsDegrees:Bool = false):Float
	{
		if (Object == null)
			return 0;

		final p = Object.getScreenPosition();

		final dx = FlxG.mouse.viewX - p.x;
		final dy = FlxG.mouse.viewY - p.y;

		p.put();

		return angleFromOrigin(dx, dy, AsDegrees);
	}

	/**
	 * Find the angle (in degrees) between an FlxSprite and the mouse,
	 * taking their **screen** x/y and origin into account.
	 * @since 5.0.0
	 *
	 * @param	Object		The FlxObject to test from
	 * @return	The angle in degrees
	 */
	public static inline function degreesBetweenMouse(Object:FlxObject):Float
	{
		return angleBetweenMouse(Object, true);
	}

	/**
	 * Find the angle (in radians) between an FlxSprite and the mouse,
	 * taking their **screen** x/y and origin into account.
	 * @since 5.0.0
	 *
	 * @param	Object		The FlxObject to test from
	 * @return	The angle in radians
	 */
	public static inline function radiansBetweenMouse(Object:FlxObject):Float
	{
		return angleBetweenMouse(Object, false);
	}
	#end

	#if FLX_TOUCH
	/**
	 * Find the angle between an FlxSprite and a FlxTouch,
	 * taking their **screen** x/y and origin into account.
	 *
	 * @param	Object		The FlxObject to test from
	 * @param	Touch		The FlxTouch to test to
	 * @param	AsDegrees	If you need the value in degrees instead of radians, set to true
	 * @return	The angle (in radians unless AsDegrees is true)
	 */
	public static function angleBetweenTouch(Object:FlxObject, Touch:FlxTouch, AsDegrees:Bool = false):Float
	{
		// In order to get the angle between the object and mouse, we need the objects screen coordinates (rather than world coordinates)
		final p = Object.getScreenPosition();

		final dx = Touch.viewX - p.x;
		final dy = Touch.viewY - p.y;

		p.put();

		return angleFromOrigin(dx, dy, AsDegrees);
	}

	/**
	 * Find the angle (in degrees) between an FlxSprite and a FlxTouch,
	 * taking their **screen** x/y and origin into account.
	 * @since 5.0.0
	 *
	 * @param	Object		The FlxObject to test from
	 * @param	Touch		The FlxTouch to test to
	 * @return	The angle in degrees
	 */
	public static inline function degreesBetweenTouch(Object:FlxObject, Touch:FlxTouch):Float
	{
		return angleBetweenTouch(Object, Touch, true);
	}

	/**
	 * Find the angle (in radians) between an FlxSprite and a FlxTouch,
	 * taking their **screen** x/y and origin into account.
	 * @since 5.0.0
	 *
	 * @param	Object		The FlxObject to test from
	 * @param	Touch		The FlxTouch to test to
	 * @return	The angle in radians
	 */
	public static inline function radiansBetweenTouch(Object:FlxObject, Touch:FlxTouch):Float
	{
		return angleBetweenTouch(Object, Touch, false);
	}
	#end
	#end
}

typedef FlxSinCos =
{
	final cos:Array<Float>;
	final sin:Array<Float>;
};
