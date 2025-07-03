package flixel.math;

import flixel.FlxSprite;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end

class FlxVelocity {
	/**
	 * Sets the source FlxSprite x/y velocity so it will move directly towards the destination FlxSprite at the speed given (in pixels per second)
	 * If you specify a maxTime then it will adjust the speed (over-writing what you set) so it arrives at the destination in that number of seconds.
	 * Timings are approximate due to the way Flash timers work, and irrespective of SWF frame rate. Allow for a variance of +- 50ms.
	 * The source object doesn't stop moving automatically should it ever reach the destination coordinates.
	 * If you need the object to accelerate, see accelerateTowardsObject() instead
	 * Note: Doesn't take into account acceleration, maxVelocity or drag (if you set drag or acceleration too high this object may not move at all)
	 *
	 * @param	source		The FlxSprite on which the velocity will be set
	 * @param	dest		The FlxSprite where the source object will move to
	 * @param	speed		The speed it will move, in pixels per second (default is 60 pixels/sec)
	 * @param	maxTime		Time given in milliseconds (1000 = 1 sec). If set the speed is adjusted so the source will arrive at destination in the given number of ms
	 */
	public static function moveTowardsObject(source:FlxSprite, dest:FlxSprite, speed = 60., maxTime = 0):Void {
		final a = FlxAngle.angleBetween(source, dest);

		if (maxTime > 0) {
			final d = FlxMath.distanceBetween(source, dest);
			speed = Std.int(d / (maxTime * .001)); // We know how many pixels we need to move, but how fast?
		}

		source.velocity.set(Math.cos(a) * speed, Math.sin(a) * speed);
	}

	/**
	 * Sets the x/y acceleration on the source FlxSprite so it will move towards the destination FlxSprite at the speed given (in pixels per second)
	 * You must give a maximum speed value, beyond which the FlxSprite won't go any faster.
	 * If you don't need acceleration look at moveTowardsObject() instead.
	 *
	 * @param	source			The FlxSprite on which the acceleration will be set
	 * @param	dest			The FlxSprite where the source object will move towards
	 * @param	acceleration	The speed it will accelerate in pixels per second
	 * @param	maxSpeed		The maximum speed in pixels per second in which the sprite can move
	 */
	public static function accelerateTowardsObject(source:FlxSprite, dest:FlxSprite, acceleration:Float, maxSpeed:Float):Void {
		final a:Float = FlxAngle.angleBetween(source, dest);
		accelerateFromAngle(source, a, acceleration, maxSpeed);
	}

	#if FLX_MOUSE
	/**
	 * Move the given FlxSprite towards the mouse pointer coordinates at a steady velocity
	 * If you specify a maxTime then it will adjust the speed (over-writing what you set) so it arrives at the destination in that number of seconds.
	 * Timings are approximate due to the way Flash timers work, and irrespective of SWF frame rate. Allow for a variance of +- 50ms.
	 * The source object doesn't stop moving automatically should it ever reach the destination coordinates.
	 *
	 * @param	source		The FlxSprite to move
	 * @param	speed		The speed it will move, in pixels per second (default is 60 pixels/sec)
	 * @param	maxTime		Time given in milliseconds (1000 = 1 sec). If set the speed is adjusted so the source will arrive at destination in the given number of ms
	 */
	public static function moveTowardsMouse(source:FlxSprite, speed = 60., maxTime = 0):Void {
		final a = FlxAngle.angleBetweenMouse(source);

		if (maxTime > 0) {
			final d = FlxMath.distanceToMouse(source);
			speed = Std.int(d / (maxTime * .001)); // We know how many pixels we need to move, but how fast?
		}

		source.velocity.set(Math.cos(a) * speed, Math.sin(a) * speed);
	}
	#end

	#if FLX_TOUCH
	/**
	 * Move the given FlxSprite towards a FlxTouch point at a steady velocity
	 * If you specify a maxTime then it will adjust the speed (over-writing what you set) so it arrives at the destination in that number of seconds.
	 * Timings are approximate due to the way Flash timers work, and irrespective of SWF frame rate. Allow for a variance of +- 50ms.
	 * The source object doesn't stop moving automatically should it ever reach the destination coordinates.
	 *
	 * @param	source		The FlxSprite to move
	 * @param	speed		The speed it will move, in pixels per second (default is 60 pixels/sec)
	 * @param	maxTime		Time given in milliseconds (1000 = 1 sec). If set the speed is adjusted so the source will arrive at destination in the given number of ms
	 */
	public static function moveTowardsTouch(source:FlxSprite, touch:FlxTouch, speed = 60., maxTime = 0):Void {
		final a = FlxAngle.angleBetweenTouch(source, touch);

		if (maxTime > 0) {
			final d = FlxMath.distanceToTouch(source, touch);
			speed = Std.int(d / (maxTime * .001)); // We know how many pixels we need to move, but how fast?
		}

		source.velocity.set(Math.cos(a) * speed, Math.sin(a) * speed);
	}
	#end

	#if FLX_MOUSE
	/**
	 * Sets the x/y acceleration on the source FlxSprite so it will move towards the mouse coordinates at the speed given (in pixels per second)
	 * You must give a maximum speed value, beyond which the FlxSprite won't go any faster.
	 * If you don't need acceleration look at moveTowardsMouse() instead.
	 *
	 * @param	source			The FlxSprite on which the acceleration will be set
	 * @param	acceleration	The speed it will accelerate in pixels per second
	 * @param	maxSpeed		The maximum speed in pixels per second in which the sprite can move
	 */
	public static function accelerateTowardsMouse(source:FlxSprite, acceleration:Float, maxSpeed:Float):Void {
		final a = FlxAngle.angleBetweenMouse(source);
		accelerateFromAngle(source, a, acceleration, maxSpeed);
	}
	#end

	#if FLX_TOUCH
	/**
	 * Sets the x/y acceleration on the source FlxSprite so it will move towards a FlxTouch at the speed given (in pixels per second)
	 * You must give a maximum speed value, beyond which the FlxSprite won't go any faster.
	 * If you don't need acceleration look at moveTowardsMouse() instead.
	 *
	 * @param	source			The FlxSprite on which the acceleration will be set
	 * @param	touch			The FlxTouch on which to accelerate towards
	 * @param	acceleration	The speed it will accelerate in pixels per second
	 * @param	maxSpeed		The maximum speed in pixels per second in which the sprite can move
	 */
	public static function accelerateTowardsTouch(source:FlxSprite, touch:FlxTouch, acceleration:Float, maxSpeed:Float):Void {
		final a = FlxAngle.angleBetweenTouch(source, touch);
		accelerateFromAngle(source, a, acceleration, maxSpeed);
	}
	#end

	/**
	 * Sets the x/y velocity on the source FlxSprite so it will move towards the target coordinates at the speed given (in pixels per second)
	 * If you specify a maxTime then it will adjust the speed (over-writing what you set) so it arrives at the destination in that number of seconds.
	 * Timings are approximate due to the way Flash timers work, and irrespective of SWF frame rate. Allow for a variance of +- 50ms.
	 * The source object doesn't stop moving automatically should it ever reach the destination coordinates.
	 *
	 * @param	source		The FlxSprite to move
	 * @param	target		The FlxPoint coordinates to move the source FlxSprite towards
	 * @param	speed		The speed it will move, in pixels per second (default is 60 pixels/sec)
	 * @param	maxTime		Time given in milliseconds (1000 = 1 sec). If set the speed is adjusted so the source will arrive at destination in the given number of ms
	 */
	public static function moveTowardsPoint(source:FlxSprite, target:FlxPoint, speed = 60., maxTime = 0):Void {
		final a = FlxAngle.angleBetweenPoint(source, target);

		if (maxTime > 0) {
			final d = FlxMath.distanceToPoint(source, target);
			speed = Std.int(d / (maxTime * .001)); // We know how many pixels we need to move, but how fast?
		}

		source.velocity.set(Math.cos(a) * speed, Math.sin(a) * speed);

		target.putWeak();
	}

	/**
	 * Sets the x/y acceleration on the source FlxSprite so it will move towards the target coordinates at the speed given (in pixels per second)
	 * You must give a maximum speed value, beyond which the FlxSprite won't go any faster.
	 * If you don't need acceleration look at moveTowardsPoint() instead.
	 *
	 * @param	source			The FlxSprite on which the acceleration will be set
	 * @param	target			The FlxPoint coordinates to move the source FlxSprite towards
	 * @param	acceleration	The speed it will accelerate in pixels per second
	 * @param	maxSpeed		The maximum speed in pixels per second in which the sprite can move
	 */
	public static function accelerateTowardsPoint(source:FlxSprite, target:FlxPoint, acceleration:Float, maxSpeed:Float):Void {
		final a = FlxAngle.angleBetweenPoint(source, target);
		accelerateFromAngle(source, a, acceleration, maxSpeed);
		target.putWeak();
	}

	/**
	 * Given the angle and speed calculate the velocity and return it as an FlxPoint
	 *
	 * @param	angle	The angle (in degrees) calculated in clockwise positive direction (down = 90 degrees positive, right = 0 degrees positive, up = 90 degrees negative)
	 * @param	speed	The speed it will move, in pixels per second sq
	 * @return	A FlxPoint where FlxPoint.x contains the velocity x value and FlxPoint.y contains the velocity y value
	 */
	public static inline function velocityFromAngle(angle:Float, speed:Float):FlxPoint {
		final a = FlxAngle.asRadians(angle);
		return FlxPoint.get(Math.cos(a) * speed, Math.sin(a) * speed);
	}

	/**
	 * Given the FlxSprite and speed calculate the velocity and return it as an FlxPoint based on the direction the sprite is facing
	 *
	 * @param	parent	The FlxSprite to get the facing value from
	 * @param	speed	The speed it will move, in pixels per second
	 * @return	An FlxPoint where FlxPoint.x contains the velocity x value and FlxPoint.y contains the velocity y value
	 */
	public static function velocityFromFacing(parent:FlxSprite, speed:Float):FlxPoint {
		return FlxPoint.get().setPolarDegrees(speed, parent.facing.degrees);
	}

	/**
	 * A tween-like function that takes a starting velocity and some other factors and returns an altered velocity.
	 *
	 * @param	velocity		Any component of velocity (e.g. 20).
	 * @param	acceleration	Rate at which the velocity is changing.
	 * @param	drag			Really kind of a deceleration, this is how much the velocity changes if acceleration is not set.
	 * @param	max				An absolute value cap for the velocity (0 for no cap).
	 * @param	elapsed			The amount of time passed in to the latest update cycle
	 * @return	The altered velocity value.
	 */
	public static function computeVelocity(velocity:Float, acceleration:Float, drag:Float, max:Float, elapsed:Float):Float {
		if (acceleration != 0)
			velocity += acceleration * elapsed;
		else if (drag != 0) {
			final drag = drag * elapsed;
			if (velocity - drag > 0) velocity -= drag;
			else if (velocity + drag < 0) velocity += drag;
			else velocity = 0;
		}

		if ((velocity != 0) && (max != 0)) {
			if (velocity > max) velocity = max;
			else if (velocity < -max) velocity = -max;
		}

		return velocity;
	}

	/**
	 * Sets the x/y acceleration on the source FlxSprite so it will accelerate in the direction of the specified angle.
	 * You must give a maximum speed value (in pixels per second), beyond which the FlxSprite won't go any faster.
	 *
	 * @param	source			The FlxSprite on which the acceleration will be set
	 * @param	radians			The angle in which the FlxPoint will be set to accelerate
	 * @param	acceleration	The speed it will accelerate in pixels per second
	 * @param	maxSpeed		The maximum speed in pixels per second in which the sprite can move
	 * @param	resetVelocity	Whether to reset the FlxSprite velocity to 0 each time
	 */
	public static inline function accelerateFromAngle(source:FlxSprite, radians:Float, acceleration:Float, maxSpeed:Float, resetVelocity = true):Void {
		final sinA = Math.sin(radians);
		final cosA = Math.cos(radians);

		if (resetVelocity) source.velocity.set(0, 0);

		source.acceleration.set(cosA * acceleration, sinA * acceleration);
		source.maxVelocity.set(Math.abs(cosA * maxSpeed), Math.abs(sinA * maxSpeed));
	}
}
