package flixel.tweens;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxTypes;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.misc.AngleTween;
import flixel.tweens.misc.ColorTween;
import flixel.tweens.misc.FlickerTween;
import flixel.tweens.misc.NumTween;
import flixel.tweens.misc.ShakeTween;
import flixel.tweens.misc.VarTween;
import flixel.tweens.motion.CircularMotion;
import flixel.tweens.motion.CubicMotion;
import flixel.tweens.motion.LinearMotion;
import flixel.tweens.motion.LinearPath;
import flixel.tweens.motion.QuadMotion;
import flixel.tweens.motion.QuadPath;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.typeLimit.OneOfTwo;

/** @since 4.5.0 **/
enum abstract FlxTweenType(ByteUInt) from ByteUInt to ByteUInt {
	/**
	 * Persistent Tween type, will stop when it finishes.
	 */
	final PERSIST = 1;

	/**
	 * Looping Tween type, will restart immediately when it finishes.
	 */
	final LOOPING = 2;

	/**
	 * "To and from" Tween type, will play tween hither and thither
	 */
	final PINGPONG = 4;

	/**
	 * Oneshot Tween type, will stop and remove itself from its core container when it finishes.
	 */
	final ONESHOT = 8;

	/**
	 * Backward Tween type, will play tween in reverse direction
	 */
	final BACKWARD = 16;
}

/**
 * Allows you to create smooth interpolations and animations easily. "Tweening" is short
 * for inbetweening: you only have to specify start and end values and `FlxTween` will
 * generate all values between those two.
 *
 * ## Resources
 * - [Handbook - FlxTween](https://haxeflixel.com/documentation/flxtween/)
 * - [Demo - FlxTween](https://haxeflixel.com/demos/FlxTween/)
 * - [Snippets - FlxTween](https://snippets.haxeflixel.com/tweens/tween/)
 *
 * ## Example
 * If you want to move a `FlxSprite` across the screen:
 * ```haxe
 * sprite.setPosition(200, 200);
 * FlxTween.tween(sprite, {x: 600, y: 800}, 2);
 * ```
 * The first two lines specify the start position of the sprite, because the `tween()` method
 * assumes the current position is the starting position.
 *
 * ## Cancelling a Tween
 * If you start a tween using the code above, it will run until the desired values are reached,
 * then stop. As the `tween()` method returns an object of type `FlxTween`, keeping this object
 * in a variable allows you to access the current tween running if you wish to control it.
 *
 * This code stops the translation of the sprite if the player presses the spacebar of their keyboard:
 * ```haxe
 * var tween:FlxTween;
 *
 * public function new() {
 *     super();
 *     // set up sprite
 *     tween = FlxTween.tween(sprite, {x:600, y:800}, 2);
 * }
 *
 * override public function update(elapsed:Float) {
 *     super.update(elapsed);
 *
 *     if (FlxG.keys.justPressed.SPACE) tween.cancel();
 * }
 * ```
 * ## Tweening Options
 * The `tween()` method takes an optional fourth parameter which is a map of options.
 *
 * Possible values are:
 * - `type`:
 *     - *ONESHOT*: Stops and removes itself from its core container when it finishes
 *     - *PERSIST*: Like *ONESHOT*, but after it finishes you may call `start()` again
 *     - *BACKWARD*: Like *ONESHOT*, but plays in the reverse direction
 *     - *LOOPING*: Restarts immediately when it finishes
 *     - *PINGPONG*: Like *LOOPING*, but every second execution is in reverse direction
 * - `onComplete`: Called once the tween has finished. For looping tweens it is called every execution.
 * - `ease`: The method of interpolating the start and end points. Usually used to make the start and/or
 *           end of the tween smoother. `FlxEase` has various easing methods to choose from.
 * - `startDelay`: Time to wait before starting this tween, in seconds.
 * - `loopDelay`: Time to wait before this tween is repeated, in seconds
 *
 * Example:
 * ```haxe
 * public function new() {
 *     super();
 *     // set up sprite
 *     sprite.setPosition(200, 200);
 *     FlxTween.tween(sprite, {x: 600, y: 800}, 2, {type: PINGPONG, ease: FlxEase.quadInOut, onComplete: changeColor, startDelay: 1, loopDelay: 2});
 * }
 *
 * private function changeColor(tween:FlxTween):Void {
 *     sprite.color = tween.executions % 2 == 0 ? FlxColor.RED : FlxColor.BLUE;
 * }
 * ```
 *
 * This code moves the sprite constantly between the two points (200|200) and (600|800), smoothly
 * accelerating and decelerating. Each time the sprite arrives at one of those two points, its color
 * changes. The animation starts after 1 second and then the sprite pauses at each point for 2 seconds.
 *
 * ## Special Tweens
 * There are many more tweening methods in `FlxTween`, which are used for special cases:
 *
 * ### Color
 * Tweens the rgb components of a color independently, where normal tweening would screw up the colors.
 *
 * ```haxe
 * FlxTween.color(sprite, 3, FlxColor.RED, FlxColor.GREEN, {onComplete: onTweenComplete});
 * ```
 *
 * ### Angle
 * Tweens the angle of a sprite, normal tweening would have trouble going from negative to positive angles.
 *
 * ```haxe
 * FlxTween.angle(sprite, -90, 180, 3, {onComplete: onTweenComplete});
 * ```
 * ### Num
 * Calls a function with the tweened value over time, no parent object involved.
 *
 * ```haxe
 * FlxTween.num(0, totalWinnings, 3, num -> field.text = addCommas(num));
 * ```
 *
 * ### Motion
 * The FlxTween class also contains the methods `linearMotion()`, `quadMotion()`, `cubicMotion()` and `circularMotion()`,
 * which make objects follow straight lines, smooth paths or circles.
 *
 * ### Paths
 * The methods `linearPath()` and `quadPath()` can be used for longer paths defined through an array of points,
 * instead of a fixed number of points.
 */
class FlxTween implements IFlxDestroyable {
	/**
	 * The global tweening manager that handles global tweens
	 * @since 4.2.0
	 */
	public static var globalManager:FlxTweenManager;

	/**
	 * Tweens numeric public properties of an Object. Shorthand for creating a VarTween, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.tween(object, {x: 500, y: 350, "scale.x": 2}, 2, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	object		The object containing the properties to tween.
	 * @param	values		An object containing key/value pairs of properties and target values.
	 * @param	duration	Duration of the tween in seconds.
	 * @param	options		A structure with tween options.
	 * @return	The added VarTween object.
	 */
	public static function tween(object:Dynamic, values:Dynamic, duration = 1., ?options:TweenOptions):VarTween {
		return globalManager.tween(object, values, duration, options);
	}

	/**
	 * Tweens some numeric value. Shorthand for creating a NumTween, starting it and adding it to the TweenManager. Using it in
	 * conjunction with a TweenFunction requires more setup, but is faster than VarTween because it doesn't use Reflection.
	 *
	 * ```haxe
	 * function tweenFunction(s:FlxSprite, v:Float) { s.alpha = v; }
	 * FlxTween.num(1, 0, 2, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT}, tweenFunction.bind(mySprite));
	 * ```
	 *
	 * Trivia: For historical reasons, you can use either onUpdate or TweenFunction to accomplish the same thing, but TweenFunction
	 * gives you the updated Float as a direct argument.
	 *
	 * @param	fromValue	Start value.
	 * @param	toValue		End value.
	 * @param	duration	Duration of the tween.
	 * @param	options		A structure with tween options.
	 * @param	tweenFunction	A function to be called when the tweened value updates.  It is recommended not to use an anonymous
	 *							function if you are maximizing performance, as those will be compiled to Dynamics on cpp.
	 * @return	The added NumTween object.
	 */
	public static function num(fromValue:Float, toValue:Float, duration = 1., ?options:TweenOptions, ?tweenFunction:Float -> Void):NumTween {
		return globalManager.num(fromValue, toValue, duration, options, tweenFunction);
	}

	/**
	 * Flickers the desired object
	 *
	 * @param   basic     The object to flicker
	 * @param   duration  Duration of the tween, in seconds
	 * @param   period    How often, in seconds, the visibility cycles
	 * @param   options   A structure with flicker and tween options
	 * @since 5.7.0
	 */
	public static function flicker(basic:FlxBasic, duration = 1., period = .08, ?options:FlickerTweenOptions) {
		return globalManager.flicker(basic, duration, period, options);
	}

	/**
	 * Whether the object is flickering via the global tween manager
	 * @since 5.7.0
	 */
	public static function isFlickering(basic:FlxBasic) {
		return globalManager.isFlickering(basic);
	}

	/**
	 * Cancels all flicker tweens on the object in the global tween manager
	 * @since 5.7.0
	 */
	public static function stopFlickering(basic:FlxBasic) {
		return globalManager.stopFlickering(basic);
	}

	/**
	 * A simple shake effect for FlxSprite. Shorthand for creating a ShakeTween, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.shake(sprite, 0.1, 2, FlxAxes.XY, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	sprite       Sprite to shake.
	 * @param   intensity    Percentage representing the maximum distance
	 *                       that the sprite can move while shaking.
	 * @param   duration     The length in seconds that the shaking effect should last.
	 * @param   axes         On what axes to shake. Default value is `FlxAxes.XY` / both.
	 * @param	options      A structure with tween options.
	 * @return The added ShakeTween object.
	 */
	public static function shake(sprite:FlxSprite, intensity = .05, duration = 1., ?axes:FlxAxes, ?options:TweenOptions):ShakeTween {
		return globalManager.shake(sprite, intensity, duration, axes, options);
	}

	/**
	 * Tweens numeric value which represents angle. Shorthand for creating a AngleTween object, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.angle(sprite, -90, 90, 2, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	sprite		Optional Sprite whose angle should be tweened.
	 * @param	fromAngle	Start angle.
	 * @param	toAngle		End angle.
	 * @param	duration	Duration of the tween.
	 * @param	options		A structure with tween options.
	 * @return	The added AngleTween object.
	 */
	public static function angle(?sprite:FlxSprite, fromAngle:Float, toAngle:Float, duration = 1., ?options:TweenOptions):AngleTween {
		return globalManager.angle(sprite, fromAngle, toAngle, duration, options);
	}

	/**
	 * Tweens numeric value which represents color. Shorthand for creating a ColorTween object, starting it and adding it to a TweenPlugin.
	 *
	 * ```haxe
	 * FlxTween.color(sprite, 2, 0x000000, 0xffffff, 0, 1, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	sprite		Optional Sprite whose color should be tweened.
	 * @param	duration	Duration of the tween in seconds.
	 * @param	fromColor	Start color.
	 * @param	toColor		End color.
	 * @param	options		A structure with tween options.
	 * @return	The added ColorTween object.
	 */
	public static function color(?sprite:FlxSprite, duration = 1., fromColor:FlxColor, toColor:FlxColor, ?options:TweenOptions):ColorTween {
		return globalManager.color(sprite, duration, fromColor, toColor, options);
	}

	/**
	 * Create a new LinearMotion tween.
	 *
	 * ```haxe
	 * FlxTween.linearMotion(object, 0, 0, 500, 20, 5, false, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	fromX			X start.
	 * @param	fromY			Y start.
	 * @param	toX				X finish.
	 * @param	toY				Y finish.
	 * @param	durationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	useDuration		Whether to use the previous param as duration or speed.
	 * @param	options			A structure with tween options.
	 * @return The LinearMotion object.
	 */
	public static function linearMotion(object:FlxObject, fromX:Float, fromY:Float, toX:Float, toY:Float, durationOrSpeed = 1., useDuration = true, ?options:TweenOptions):LinearMotion {
		return globalManager.linearMotion(object, fromX, fromY, toX, toY, durationOrSpeed, useDuration, options);
	}

	/**
	 * Create a new QuadMotion tween.
	 *
	 * ```haxe
	 * FlxTween.quadMotion(object, 0, 100, 300, 500, 100, 2, 5, false, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	fromX			X start.
	 * @param	fromY			Y start.
	 * @param	controlX		X control, used to determine the curve.
	 * @param	controlY		Y control, used to determine the curve.
	 * @param	toX				X finish.
	 * @param	toY				Y finish.
	 * @param	durationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	useDuration		Whether to use the previous param as duration or speed.
	 * @param	options			A structure with tween options.
	 * @return The QuadMotion object.
	 */
	public static function quadMotion(object:FlxObject, fromX:Float, fromY:Float, controlX:Float, controlY:Float, toX:Float, toY:Float, durationOrSpeed = 1., useDuration = true, ?options:TweenOptions):QuadMotion {
		return globalManager.quadMotion(object, fromX, fromY, controlX, controlY, toX, toY, durationOrSpeed, useDuration, options);
	}

	/**
	 * Create a new CubicMotion tween.
	 *
	 * ```haxe
	 * FlxTween.cubicMotion(_sprite, 0, 0, 500, 100, 400, 200, 100, 100, 2, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	object 		The object to move (FlxObject or FlxSpriteGroup)
	 * @param	fromX		X start.
	 * @param	fromY		Y start.
	 * @param	aX			First control x.
	 * @param	aY			First control y.
	 * @param	bX			Second control x.
	 * @param	bY			Second control y.
	 * @param	toX			X finish.
	 * @param	toY			Y finish.
	 * @param	duration	Duration of the movement in seconds.
	 * @param	options		A structure with tween options.
	 * @return The CubicMotion object.
	 */
	public static function cubicMotion(object:FlxObject, fromX:Float, fromY:Float, aX:Float, aY:Float, bX:Float, bY:Float, toX:Float, toY:Float, duration = 1., ?options:TweenOptions):CubicMotion {
		return globalManager.cubicMotion(object, fromX, fromY, aX, aY, bX, bY, toX, toY, duration, options);
	}

	/**
	 * Create a new CircularMotion tween.
	 *
	 * ```haxe
	 * FlxTween.circularMotion(object, 250, 250, 50, 0, true, 2, true, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	centerX			X position of the circle's center.
	 * @param	centerY			Y position of the circle's center.
	 * @param	radius			Radius of the circle.
	 * @param	angle			Starting position on the circle.
	 * @param	clockwise		If the motion is clockwise.
	 * @param	durationOrSpeed	Duration of the movement in seconds.
	 * @param	useDuration		Duration of the movement.
	 * @param	ease			Optional easer function.
	 * @param	Options			A structure with tween options.
	 * @return The CircularMotion object.
	 */
	public static function circularMotion(object:FlxObject, centerX:Float, centerY:Float, radius:Float, angle:Float, clockwise:Bool, durationOrSpeed = 1., useDuration = true, ?options:TweenOptions):CircularMotion {
		return globalManager.circularMotion(object, centerX, centerY, radius, angle, clockwise, durationOrSpeed, useDuration, options);
	}

	/**
	 * Create a new LinearPath tween.
	 *
	 * ```haxe
	 * FlxTween.linearPath(object, [FlxPoint.get(0, 0), FlxPoint.get(100, 100)], 2, true, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	object 			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	points			An array of at least 2 FlxPoints defining the path
	 * @param	durationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	useDuration		Whether to use the previous param as duration or speed.
	 * @param	options			A structure with tween options.
	 * @return	The LinearPath object.
	 */
	public static function linearPath(object:FlxObject, points:Array<FlxPoint>, durationOrSpeed = 1., useDuration = true, ?options:TweenOptions):LinearPath {
		return globalManager.linearPath(object, points, durationOrSpeed, useDuration, options);
	}

	/**
	 * Create a new QuadPath tween.
	 *
	 * ```haxe
	 * FlxTween.quadPath(object, [FlxPoint.get(0, 0), FlxPoint.get(200, 200), FlxPoint.get(400, 0)], 2, true, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	points			An array of at least 3 FlxPoints defining the path
	 * @param	durationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	useDuration		Whether to use the previous param as duration or speed.
	 * @param	options			A structure with tween options.
	 * @return	The QuadPath object.
	 */
	public static function quadPath(object:FlxObject, points:Array<FlxPoint>, durationOrSpeed = 1., useDuration = true, ?options:TweenOptions):QuadPath {
		return globalManager.quadPath(object, points, durationOrSpeed, useDuration, options);
	}

	/**
	 * Cancels all related tweens on the specified object.
	 *
	 * Note: Any tweens with the specified fields are cancelled, if the tween has other properties they
	 * will also be cancelled.
	 *
	 * @param object The object with tweens to cancel.
	 * @param fieldPaths Optional list of the tween field paths to search for. If null or empty, all tweens on the specified
	 * object are canceled. Allows dot paths to check child properties.
	 *
	 * @since 4.9.0
	 */
	public static function cancelTweensOf(object:Dynamic, ?fieldPaths:Array<String>):Void {
		globalManager.cancelTweensOf(object, fieldPaths);
	}

	/**
	 * Immediately updates all tweens on the specified object with the specified fields that
	 * are not looping (type `FlxTween.LOOPING` or `FlxTween.PINGPONG`) and `active` through
	 * their endings, triggering their `onComplete` callbacks.
	 *
	 * Note: if they haven't yet begun, this will first trigger their `onStart` callback.
	 *
	 * Note: their `onComplete` callbacks are triggered in the next frame.
	 * To trigger them immediately, call `FlxTween.globalManager.update(0);` after this function.
	 *
	 * In no case should it trigger an `onUpdate` callback.
	 *
	 * Note: Any tweens with the specified fields are completed, if the tween has other properties they
	 * will also be completed.
	 *
	 * @param object The object with tweens to complete.
	 * @param fieldPaths Optional list of the tween field paths to search for. If null or empty, all tweens on
	 * the specified object are completed. Allows dot paths to check child properties.
	 *
	 * @since 4.9.0
	 */
	public static function completeTweensOf(object:Dynamic, ?fieldPaths:Array<String>):Void {
		globalManager.completeTweensOf(object, fieldPaths);
	}

	/**
	 * The manager to which this tween belongs
	 * @since 4.2.0
	 */
	public var manager:FlxTweenManager;

	public var active(default, set) = false;
	public var duration = .0;
	public var ease:EaseFunction;
	public var framerate:Float;
	public var onStart:TweenCallback;
	public var onUpdate:TweenCallback;
	public var onComplete:TweenCallback;

	public var type(default, set):FlxTweenType;

	/**
	 * Value between `0` and `1` that indicates how far along this tween is in its completion.
	 * A value of `0.33` means that the tween is `33%` complete.
	 */
	public var percent(get, set):Float;

	public var finished(default, null):Bool;
	public var scale(default, null) = .0;
	public var backward(default, null):Bool;

	/**
	 * The total time passed since start
	 * @since 5.7.0
	 */
	public var time(get, never):Float;

	/**
	 * How many times this tween has been executed / has finished so far - useful to
	 * stop the `LOOPING` and `PINGPONG` types after a certain amount of time
	 */
	public var executions(default, null) = 0;

	/**
	 * Seconds to wait until starting this tween, 0 by default
	 */
	public var startDelay(default, set) = .0;

	/**
	 * Seconds to wait between loops of this tween, 0 by default
	 */
	public var loopDelay(default, set) = .0;

	var _secondsSinceStart = .0;
	var _delayToUse = .0;
	var _running = false;
	var _waitingForRestart = false;
	var _chainedTweens:Array<FlxTween>;
	var _nextTweenInChain:FlxTween;

	/**
	 * This function is called when tween is created, or recycled.
	 */
	private function new(options:TweenOptions, ?manager:FlxTweenManager):Void {
		options = resolveTweenOptions(options);

		type = options.type;
		onStart = options.onStart;
		onUpdate = options.onUpdate;
		onComplete = options.onComplete;
		ease = options.ease;
		framerate = options.framerate != null ? options.framerate : 0;
		setDelays(options.startDelay, options.loopDelay);
		this.manager = manager != null ? manager : globalManager;
	}

	private function resolveTweenOptions(options:TweenOptions):TweenOptions {
		options ??= {type: FlxTweenType.ONESHOT};
		options.type ??= FlxTweenType.ONESHOT;

		return options;
	}

	public function destroy():Void {
		onStart = null;
		onUpdate = null;
		onComplete = null;
		ease = null;
		manager = null;
		_chainedTweens = null;
		_nextTweenInChain = null;
	}

	/**
	 * Specify a tween to be executed when this one has finished
	 * (useful for creating "tween chains").
	 */
	public function then(tween:FlxTween):FlxTween {
		return addChainedTween(tween);
	}

	/**
	 * How many seconds to delay the execution of the next tween in a tween chain.
	 */
	public function wait(delay:Float):FlxTween {
		return addChainedTween(FlxTween.num(0, 0, delay));
	}

	private function addChainedTween(tween:FlxTween):FlxTween {
		tween.setVarsOnEnd();
		tween.manager.remove(tween, false);

		_chainedTweens ??= [];

		_chainedTweens.push(tween);
		return this;
	}

	private function update(elapsed:Float):Void {
		var preTick = _secondsSinceStart;
		_secondsSinceStart += elapsed;
		var postTick = _secondsSinceStart;
		final delay = (executions > 0) ? loopDelay : startDelay;

		if (_secondsSinceStart < delay) return;

		if (framerate > 0) {
			preTick = Math.fround(preTick * framerate) / framerate;
			postTick = Math.fround(postTick * framerate) / framerate;
		}

		scale = Math.max((postTick - delay), 0) / duration;
		if (ease != null) scale = ease(scale);

		if (backward) scale = 1 - scale;

		if (_secondsSinceStart > delay && !_running) {
			_running = true;
			if (onStart != null) onStart(this);
		}

		if (_secondsSinceStart >= duration + delay) {
			scale = (backward) ? 0 : 1;
			finished = true;
		} else {
			if (postTick > preTick && onUpdate != null)
				onUpdate(this);
		}
	}

	/**
	 * Starts the Tween, or restarts it if it's currently running.
	 */
	public function start():FlxTween {
		_waitingForRestart = false;
		_secondsSinceStart = 0;
		_delayToUse = (executions > 0) ? loopDelay : startDelay;

		if (duration == 0) {
			active = false;
			return this;
		}

		active = true;
		_running = finished = false;

		return this;
	}

	/**
	 * Immediately stops the Tween and removes it from its
	 * `manager` without calling the `onComplete` callback.
	 *
	 * Yields control to the next chained Tween if one exists.
	 */
	public function cancel():Void {
		onEnd();

		manager?.remove(this);
	}

	/**
	 * Immediately stops the Tween and removes it from its
	 * `manager` without calling the `onComplete` callback
	 * or yielding control to the next chained Tween if one exists.
	 *
	 * If control has already been passed on, forwards the cancellation
	 * request along the chain to the currently active Tween.
	 *
	 * @since 4.3.0
	 */
	public function cancelChain():Void {
		// Pass along the cancellation request.
		_nextTweenInChain?.cancelChain();

		// Prevent yielding control to any chained tweens.
		if (_chainedTweens != null) _chainedTweens = null;

		cancel();
	}

	private function finish():Void {
		executions++;

		if (onComplete != null) onComplete(this);

		final type = type & ~FlxTweenType.BACKWARD;

		if (type == FlxTweenType.PERSIST || type == FlxTweenType.ONESHOT) {
			onEnd();
			_secondsSinceStart = duration + startDelay;

			if (type == FlxTweenType.ONESHOT && manager != null)
				manager.remove(this);
		}

		if (type == FlxTweenType.LOOPING || type == FlxTweenType.PINGPONG) {
			_secondsSinceStart = (_secondsSinceStart - _delayToUse) % duration + _delayToUse;
			scale = Math.max((_secondsSinceStart - _delayToUse), 0) / duration;

			if (ease != null && scale > 0 && scale < 1) scale = ease(scale);

			if (type == FlxTweenType.PINGPONG) {
				backward = !backward;
				if (backward) scale = 1 - scale;
			}

			restart();
		}
	}

	/**
	 * Called when the tween ends, either via finish() or cancel().
	 */
	private function onEnd():Void {
		setVarsOnEnd();
		processTweenChain();
	}

	private function setVarsOnEnd():Void {
		active = _running = false;
		finished = true;
	}

	private function processTweenChain():Void {
		if (_chainedTweens == null || _chainedTweens.length <= 0) return;

		// Remember next tween to enable cancellation of the chain.
		_nextTweenInChain = _chainedTweens.shift();

		doNextTween(_nextTweenInChain);
		_chainedTweens = null;
	}

	private function doNextTween(tween:FlxTween):Void {
		if (!tween.active) {
			tween.start();
			manager.add(tween);
		}

		tween.setChain(_chainedTweens);
	}

	private function setChain(previousChain:Array<FlxTween>):Void {
		if (previousChain == null) return;

		if (_chainedTweens == null) _chainedTweens = previousChain;
		else _chainedTweens = _chainedTweens.concat(previousChain);
	}

	/**
	 * In case the tween.active was set to false in onComplete(),
	 * the tween should not be restarted yet.
	 */
	private function restart():Void {
		if (active) start();
		else _waitingForRestart = true;
	}

	/**
	 * Returns true if this is tweening the specified field on the specified object.
	 *
	 * @param object The object.
	 * @param field Optional tween field. Ignored if null.
	 *
	 * @since 4.9.0
	 */
	private function isTweenOf(object:Dynamic, ?field:OneOfTwo<String, Int>):Bool {
		return false;
	}

	/**
	 * Set both type of delays for this tween.
	 *
	 * @param	startDelay	Seconds to wait until starting this tween, 0 by default.
	 * @param	loopDelay	Seconds to wait between loops of this tween, 0 by default.
	 */
	private function setDelays(?startDelay:Null<Float>, ?loopDelay:Null<Float>):FlxTween {
		this.startDelay = (startDelay != null) ? startDelay : 0;
		this.loopDelay = (loopDelay != null) ? loopDelay : 0;
		return this;
	}

	/**
	 * Parses a string into an array of OneOfTwo<String, Int>
 	 *
 	 * Example:

	 * "health.shield.amount" -> ["health", "shield", "amount"]
	 * "health[0].shield.amount" -> ["health", 0, "shield", "amount"]
	 * "health.shield[0].amount" -> ["health", "shield", 0, "amount"]
	 * "" -> [""]
	 * "hello..world" -> ["hello", "", "world"]
	 * "hello.[5]" -> ["hello", "", 5]
	 * "hello[5]" -> ["hello", 5]
	 * "hello." -> ["hello", ""]
 	 *
 	 * @param input The string to parse
 	 * @return An array of OneOfTwo<String, Int>
	**/
	public static function parseFieldString(input:String):Array<OneOfTwo<String, Int>> {
		final result:Array<OneOfTwo<String, Int>> = [];
		var start = 0;
		var inBracket = false;
		var lastWasDot = false;
		final len = input.length;

		for (i in 0...len) {
			final c = StringTools.unsafeCodeAt(input, i);

			switch (c) {
				case ".".code:
					if (!inBracket && (i > start || lastWasDot))
						result.push(input.substr(start, i - start));

					start = i + 1;
					lastWasDot = true;
				case '['.code if (!inBracket):
					if (i > start) result.push(input.substr(start, i - start));
					else if (lastWasDot) result.push("");

					start = i + 1;
					inBracket = true;
					lastWasDot = false;
				case ']'.code if (inBracket):
					if (i > start) result.push(Std.parseInt(input.substr(start, i - start)));
					start = i + 1;
					inBracket = false;
			}
		}

		if (start < len || lastWasDot) {
			final current = input.substr(start);
			result.push(inBracket ? Std.parseInt(current) : current);
		}

		if (result.length == 0) result.push("");

		return result;
	}

	private function set_startDelay(value:Float):Float {
		final dly = Math.abs(value);
		if (executions == 0) _delayToUse = dly;

		return startDelay = dly;
	}

	private function set_loopDelay(value:Null<Float>):Float {
		final dly = Math.abs(value);
		if (executions > 0) {
			_secondsSinceStart = duration * percent + Math.max((dly - loopDelay), 0);
			_delayToUse = dly;
		}
		return loopDelay = dly;
	}

	inline function get_time():Float {
		return Math.max(_secondsSinceStart - _delayToUse, 0);
	}

	inline function get_percent():Float {
		return time / duration;
	}

	private function set_percent(value:Float):Float {
		return _secondsSinceStart = duration * value + _delayToUse;
	}

	private function set_type(value:Int):Int {
		if (value == 0)
			value = FlxTweenType.ONESHOT;
		else if (value == FlxTweenType.BACKWARD)
			value = FlxTweenType.PERSIST | FlxTweenType.BACKWARD;

		backward = (value & FlxTweenType.BACKWARD) > 0;
		return type = value;
	}

	private function set_active(active:Bool):Bool {
		this.active = active;

		if (_waitingForRestart) restart();

		return active;
	}
}

typedef TweenCallback = FlxTween -> Void;

typedef TweenOptions = {
	/**
	 * Tween type - bit field of `FlxTween`'s static type constants.
	 */
	var ?type:FlxTweenType;

	/**
	 * Optional easer function (see `FlxEase`).
	 */
	var ?ease:EaseFunction;

	/**
	 * Optional set framerate for this tween to update at.
	 * This also affects how often `onUpdate` is called.
	 */
	var ?framerate:Null<Float>;

	/**
	 * Optional start callback function.
	 */
	var ?onStart:TweenCallback;

	/**
	 * Optional update callback function.
	 */
	var ?onUpdate:TweenCallback;

	/**
	 * Optional complete callback function.
	 */
	var ?onComplete:TweenCallback;

	/**
	 * Seconds to wait until starting this tween, `0` by default.
	 */
	var ?startDelay:Float;

	/**
	 * Seconds to wait between loops of this tween, `0` by default.
	 */
	var ?loopDelay:Float;
}

/**
 * A simple manager for tracking and updating game tween objects.
 * Normally accessed via the static `FlxTween.globalManager` rather than being created separately.
 */
@:access(flixel.tweens)
@:access(flixel.tweens.FlxTween)
class FlxTweenManager extends FlxBasic {
	/**
	 * A list of all FlxTween objects.
	 */
	var _tweens(default, null):Array<FlxTween> = [];

	public function new():Void {
		super();
		visible = false; // No draw-calls needed
		FlxG.signals.preStateSwitch.add(clear);
	}

	/**
	 * Tweens numeric public properties of an Object. Shorthand for creating a VarTween, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.tween(object, {x: 500, y: 350, "scale.x": 2}, 2, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	object		The object containing the properties to tween.
	 * @param	values		An object containing key/value pairs of properties and target values.
	 * @param	duration	Duration of the tween in seconds.
	 * @param	options		A structure with tween options.
	 * @return	The added VarTween object.
	 * @since   4.2.0
	 */
	public function tween(object:Dynamic, values:Dynamic, duration = 1., ?options:TweenOptions):VarTween {
		final tween = new VarTween(options, this);
		tween.tween(object, values, duration);
		return add(tween);
	}

	/**
	 * Flickers the desired object
	 *
	 * @param   basic     The object to flicker
	 * @param   duration  Duration of the tween, in seconds
	 * @param   period    How often, in seconds, the visibility cycles
	 * @param   options   A structure with flicker and tween options
	 * @since 5.7.0
	 */
	public function flicker(basic:FlxBasic, duration = 1., period = .08, ?options:FlickerTweenOptions) {
		final tween = new FlickerTween(options, this);
		tween.tween(basic, duration, period);
		return add(tween);
	}

	/**
	 * Whether the object is flickering via this manager
	 * @since 5.7.0
	 */
	public function isFlickering(basic:FlxBasic) {
		return containsTweensOf(basic, ["flicker"]);
	}

	/**
	 * Cancels all flicker tweens on the object
	 * @since 5.7.0
	 */
	public function stopFlickering(basic:FlxBasic) {
		return cancelTweensOf(basic, ["flicker"]);
	}

	/**
	 * Tweens some numeric value. Shorthand for creating a NumTween, starting it and adding it to the TweenManager. Using it in
	 * conjunction with a TweenFunction requires more setup, but is faster than VarTween because it doesn't use Reflection.
	 *
	 * ```haxe
	 * function tweenFunction(s:FlxSprite, v:Float) { s.alpha = v; }
	 * FlxTween.num(1, 0, 2, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT}, tweenFunction.bind(mySprite));
	 * ```
	 *
	 * Trivia: For historical reasons, you can use either onUpdate or TweenFunction to accomplish the same thing, but TweenFunction
	 * gives you the updated Float as a direct argument.
	 *
	 * @param	fromValue	Start value.
	 * @param	toValue		End value.
	 * @param	duration	Duration of the tween.
	 * @param	options		A structure with tween options.
	 * @param	tweenFunction	A function to be called when the tweened value updates.  It is recommended not to use an anonymous
	 *							function if you are maximizing performance, as those will be compiled to Dynamics on cpp.
	 * @return	The added NumTween object.
	 * @since   4.2.0
	 */
	public function num(fromValue:Float, toValue:Float, duration:Float = 1, ?options:TweenOptions, ?tweenFunction:Float -> Void):NumTween {
		final tween = new NumTween(options, this);
		tween.tween(fromValue, toValue, duration, tweenFunction);
		return add(tween);
	}

	/**
	 * A simple shake effect for FlxSprite. Shorthand for creating a ShakeTween, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.shake(sprite, 0.1, 2, FlxAxes.XY, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	sprite       Sprite to shake.
	 * @param   intensity    Percentage representing the maximum distance
	 *                       that the sprite can move while shaking.
	 * @param   duration     The length in seconds that the shaking effect should last.
	 * @param   axes         On what axes to shake. Default value is `FlxAxes.XY` / both.
	 * @param	options      A structure with tween options.
	 */
	public function shake(sprite:FlxSprite, intensity = .05, duration = 1., ?axes:FlxAxes = XY, ?options:TweenOptions):ShakeTween {
		final tween = new ShakeTween(options, this);
		tween.tween(sprite, intensity, duration, axes);
		return add(tween);
	}

	/**
	 * Tweens numeric value which represents angle. Shorthand for creating a AngleTween object, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.angle(sprite, -90, 90, 2, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	sprite		Optional Sprite whose angle should be tweened.
	 * @param	fromAngle	Start angle.
	 * @param	toAngle		End angle.
	 * @param	duration	Duration of the tween.
	 * @param	options		A structure with tween options.
	 * @return	The added AngleTween object.
	 * @since   4.2.0
	 */
	public function angle(?sprite:FlxSprite, fromAngle:Float, toAngle:Float, duration = 1., ?options:TweenOptions):AngleTween {
		final tween = new AngleTween(options, this);
		tween.tween(fromAngle, toAngle, duration, sprite);
		return add(tween);
	}

	/**
	 * Tweens numeric value which represents color. Shorthand for creating a ColorTween object, starting it and adding it to a TweenPlugin.
	 *
	 * ```haxe
	 * FlxTween.color(sprite, 2, 0x000000, 0xffffff, 0, 1, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	sprite		Optional Sprite whose color should be tweened.
	 * @param	duration	Duration of the tween in seconds.
	 * @param	fromColor	Start color.
	 * @param	toColor		End color.
	 * @param	options		A structure with tween options.
	 * @return	The added ColorTween object.
	 * @since   4.2.0
	 */
	public function color(?sprite:FlxSprite, duration = 1., fromColor:FlxColor, toColor:FlxColor, ?options:TweenOptions):ColorTween {
		final tween = new ColorTween(options, this);
		tween.tween(duration, fromColor, toColor, sprite);
		return add(tween);
	}

	/**
	 * Create a new LinearMotion tween.
	 *
	 * ```haxe
	 * FlxTween.linearMotion(object, 0, 0, 500, 20, 5, false, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	fromX			X start.
	 * @param	fromY			Y start.
	 * @param	toX				X finish.
	 * @param	toY				Y finish.
	 * @param	durationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	useDuration		Whether to use the previous param as duration or speed.
	 * @param	options			A structure with tween options.
	 * @return The LinearMotion object.
	 * @since  4.2.0
	 */
	public function linearMotion(object:FlxObject, fromX:Float, fromY:Float, toX:Float, toY:Float, durationOrSpeed = 1., useDuration = true, ?options:TweenOptions):LinearMotion {
		final tween = new LinearMotion(options, this);
		tween.setObject(object);
		tween.setMotion(fromX, fromY, toX, toY, durationOrSpeed, useDuration);
		return add(tween);
	}

	/**
	 * Create a new QuadMotion tween.
	 *
	 * ```haxe
	 * FlxTween.quadMotion(object, 0, 100, 300, 500, 100, 2, 5, false, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	fromX			X start.
	 * @param	fromY			Y start.
	 * @param	controlX		X control, used to determine the curve.
	 * @param	controlY		Y control, used to determine the curve.
	 * @param	toX				X finish.
	 * @param	toY				Y finish.
	 * @param	durationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	useDuration		Whether to use the previous param as duration or speed.
	 * @param	options			A structure with tween options.
	 * @return The QuadMotion object.
	 * @since  4.2.0
	 */
	public function quadMotion(object:FlxObject, fromX:Float, fromY:Float, controlX:Float, controlY:Float, toX:Float, toY:Float, durationOrSpeed = 1., useDuration = true, ?options:TweenOptions):QuadMotion {
		final tween = new QuadMotion(options, this);
		tween.setObject(object);
		tween.setMotion(fromX, fromY, controlX, controlY, toX, toY, durationOrSpeed, useDuration);
		return add(tween);
	}

	/**
	 * Create a new CubicMotion tween.
	 *
	 * ```haxe
	 * FlxTween.cubicMotion(_sprite, 0, 0, 500, 100, 400, 200, 100, 100, 2, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	object 		The object to move (FlxObject or FlxSpriteGroup)
	 * @param	fromX		X start.
	 * @param	fromY		Y start.
	 * @param	aX			First control x.
	 * @param	aY			First control y.
	 * @param	bX			Second control x.
	 * @param	bY			Second control y.
	 * @param	toX			X finish.
	 * @param	toY			Y finish.
	 * @param	duration	Duration of the movement in seconds.
	 * @param	options		A structure with tween options.
	 * @return The CubicMotion object.
	 * @since  4.2.0
	 */
	public function cubicMotion(object:FlxObject, fromX:Float, fromY:Float, aX:Float, aY:Float, bX:Float, bY:Float, toX:Float, toY:Float, duration = 1., ?options:TweenOptions):CubicMotion {
		final tween = new CubicMotion(options, this);
		tween.setObject(object);
		tween.setMotion(fromX, fromY, aX, aY, bX, bY, toX, toY, duration);
		return add(tween);
	}

	/**
	 * Create a new CircularMotion tween.
	 *
	 * ```haxe
	 * FlxTween.circularMotion(object, 250, 250, 50, 0, true, 2, true, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	centerX			X position of the circle's center.
	 * @param	centerY			Y position of the circle's center.
	 * @param	radius			Radius of the circle.
	 * @param	angle			Starting position on the circle.
	 * @param	clockwise		If the motion is clockwise.
	 * @param	durationOrSpeed	Duration of the movement in seconds.
	 * @param	useDuration		Duration of the movement.
	 * @param	ease			Optional easer function.
	 * @param	options			A structure with tween options.
	 * @return The CircularMotion object.
	 * @since  4.2.0
	 */
	public function circularMotion(object:FlxObject, centerX:Float, centerY:Float, radius:Float, angle:Float, clockwise:Bool, durationOrSpeed:Float = 1, useDuration:Bool = true, ?options:TweenOptions):CircularMotion {
		final tween = new CircularMotion(options, this);
		tween.setObject(object);
		tween.setMotion(centerX, centerY, radius, angle, clockwise, durationOrSpeed, useDuration);
		return add(tween);
	}

	/**
	 * Create a new LinearPath tween.
	 *
	 * ```haxe
	 * FlxTween.linearPath(object, [FlxPoint.get(0, 0), FlxPoint.get(100, 100)], 2, true, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	object 			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	points			An array of at least 2 FlxPoints defining the path
	 * @param	durationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	useDuration		Whether to use the previous param as duration or speed.
	 * @param	options			A structure with tween options.
	 * @return	The LinearPath object.
	 * @since   4.2.0
	 */
	public function linearPath(object:FlxObject, points:Array<FlxPoint>, durationOrSpeed = 1., useDuration = true, ?options:TweenOptions):LinearPath {
		final tween = new LinearPath(options, this);

		if (points != null)
			for (point in points)
				tween.addPoint(point.x, point.y);

		tween.setObject(object);
		tween.setMotion(durationOrSpeed, useDuration);
		return add(tween);
	}

	/**
	 * Create a new QuadPath tween.
	 *
	 * ```haxe
	 * FlxTween.quadPath(object, [FlxPoint.get(0, 0), FlxPoint.get(200, 200), FlxPoint.get(400, 0)], 2, true, {ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT});
	 * ```
	 *
	 * @param	object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	Points			An array of at least 3 FlxPoints defining the path
	 * @param	durationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	useDuration		Whether to use the previous param as duration or speed.
	 * @param	options			A structure with tween options.
	 * @return	The QuadPath object.
	 * @since   4.2.0
	 */
	public function quadPath(object:FlxObject, points:Array<FlxPoint>, durationOrSpeed = 1., useDuration = true, ?options:TweenOptions):QuadPath {
		final tween = new QuadPath(options, this);

		if (points != null)
			for (point in points)
				tween.addPoint(point.x, point.y);

		tween.setObject(object);
		tween.setMotion(durationOrSpeed, useDuration);
		return add(tween);
	}

	override public function destroy():Void {
		super.destroy();
		FlxG.signals.preStateSwitch.remove(clear);
	}

	override public function update(elapsed:Float):Void {
		// process finished tweens after iterating through main list, since finish() can manipulate FlxTween.list
		var finishedTweens:Array<FlxTween> = null;

		for (tween in _tweens) {
			if (!tween.active) continue;

			tween.update(elapsed);
			if (tween.finished) {
				finishedTweens ??= [];
				finishedTweens.push(tween);
			}
		}

		if (finishedTweens != null)
			while (finishedTweens.length > 0)
				finishedTweens.shift().finish();
	}

	/**
	 * Add a FlxTween.
	 *
	 * @param	tween	The FlxTween to add.
	 * @param	start	Whether you want it to start right away.
	 * @return	The added FlxTween object.
	 */
	#if FLX_GENERIC
	@:generic
	#end
	@:allow(flixel.tweens.FlxTween)
	private function add<T:FlxTween>(tween:T, start = false):T {
		// Don't add a null object
		if (tween == null) return null;

		_tweens.push(tween);
		if (start) tween.start();

		return tween;
	}

	/**
	 * Remove a FlxTween.
	 *
	 * @param	tween		The FlxTween to remove.
	 * @param	destroy		Whether you want to destroy the FlxTween
	 * @return	The removed FlxTween object.
	 */
	@:allow(flixel.tweens.FlxTween)
	private function remove(tween:FlxTween, destroy = true):FlxTween {
		if (tween == null) return null;

		tween.active = false;
		if (destroy) tween.destroy();
		FlxArrayUtil.fastSplice(_tweens, tween);

		return tween;
	}

	/**
	 * Removes all FlxTweens.
	 */
	public function clear():Void {
		for (tween in _tweens)
			if (tween != null) {
				tween.active = false;
				tween.destroy();
			}

		_tweens.resize(0);
	}

	/**
	 * Cancels all related tweens on the specified object.
	 *
	 * Note: Any tweens with the specified fields are cancelled, if the tween has other properties they
	 * will also be cancelled.
	 *
	 * @param object The object with tweens to cancel.
	 * @param fieldPaths Optional list of the tween field paths to search for. If null or empty, all tweens on the specified
	 * object are canceled. Allows dot paths to check child properties.
	 *
	 * @since 4.9.0
	 */
	public function cancelTweensOf(object:Dynamic, ?fieldPaths:Array<String>):Void {
		forEachTweensOf(object, fieldPaths, tween -> tween.cancel());
	}

	/**
	 * Immediately updates all tweens on the specified object with the specified fields that
	 * are not looping (type `FlxTween.LOOPING` or `FlxTween.PINGPONG`) and `active` through
	 * their endings, triggering their `onComplete` callbacks.
	 *
	 * Note: if they haven't yet begun, this will first trigger their `onStart` callback.
	 *
	 * Note: their `onComplete` callbacks are triggered in the next frame.
	 * To trigger them immediately, call `FlxTween.globalManager.update(0);` after this function.
	 *
	 * In no case should it trigger an `onUpdate` callback.
	 *
	 * Note: Any tweens with the specified fields are completed, if the tween has other properties they
	 * will also be completed.
	 *
	 * @param object The object with tweens to complete.
	 * @param fieldPaths Optional list of the tween field paths to search for. If null or empty, all tweens on
	 * the specified object are completed. Allows dot paths to check child properties.
	 *
	 * @since 4.9.0
	 */
	public function completeTweensOf(object:Dynamic, ?fieldPaths:Array<String>):Void {
		forEachTweensOf(object, fieldPaths, tween -> if ((tween.type & FlxTweenType.LOOPING) == 0 && (tween.type & FlxTweenType.PINGPONG) == 0 && tween.active) tween.update(FlxMath.MAX_VALUE_FLOAT));
	}

	/**
	 * Internal helper for iterating tweens with specific parameters.
	 *
	 * Note: loops backwards to allow removals.
	 *
	 * @param   object      The object with tweens you are searching for.
 	 * @param   fieldPaths  List of the tween field paths to check. If `null` or empty, any tween of
 	 *                      the specified object will match. Allows dot paths to check child properties.
 	 * @param   func        The function to call on each matching tween.
	 *
	 * @since 4.9.0
	 */
	private function forEachTweensOf(object:Dynamic, ?fieldPaths:Array<String>, func:FlxTween -> Void) {
		if (object == null) FlxG.log.critical("Cannot cancel tween variables of an object that is null.");

		if (fieldPaths == null || fieldPaths.length == 0) {
			var i = _tweens.length;
			while (i-- > 0) {
				final tween = _tweens[i];
				if (tween.isTweenOf(object)) func(tween);
			}
		} else {
			// check for dot paths and convert to object/field pairs
			final propertyInfos = new Array<TweenProperty>();
			for (fieldPath in fieldPaths) {
				var target:Dynamic = object;
				final path = FlxTween.parseFieldString(fieldPath);
				final field = path.pop();
				for (component in path) {
					if (Type.typeof(component) == TInt) {
						if ((target is Array)) {
							final index:Int = cast component;
							final arr:Array<Dynamic> = cast target;
							target = arr[index];
						}
					} else { // TClass(String)
						final field:String = cast component;
						target = Reflect.getProperty(target, field);
					}

					if (!Reflect.isObject(target) && !(target is Array)) break;
				}

				if (Type.typeof(field) == TInt) {
					if ((target is Array))
						propertyInfos.push({object: target, field: field});
				} else { // TClass(String)
					if (Reflect.isObject(target))
						propertyInfos.push({object: target, field: field});
				}
			}

			var i = _tweens.length;
			while (i-- > 0) {
				final tween = _tweens[i];
				for (info in propertyInfos)
					if (tween.isTweenOf(info.object, info.field)) {
						func(tween);
						break;
					}
			}
		}
	}

	/**
	 * Crude helper to search for any tweens with the desired properties
	 *
	 * @since 5.7.0
	 */
	private function containsTweensOf(object:Dynamic, ?fieldPaths:Array<String>):Bool {
		var found = false;
		forEachTweensOf(object, fieldPaths, _ -> found = true);
		return found;
	}

	/**
	 * Immediately updates all tweens that are not looping (type `FlxTween.LOOPING` or `FlxTween.PINGPONG`)
	 * and `active` through their endings, triggering their `onComplete` callbacks.
	 *
	 * Note: if they haven't yet begun, this will first trigger their `onStart` callback.
	 *
	 * Note: their `onComplete` callbacks are triggered in the next frame.
	 * To trigger them immediately, call `FlxTween.globalManager.update(0);` after this function.
	 *
	 * In no case should it trigger an `onUpdate` callback.
	 *
	 * @since 4.2.0
	 */
	public function completeAll():Void {
		for (tween in _tweens)
			if ((tween.type & FlxTweenType.LOOPING) == 0 && (tween.type & FlxTweenType.PINGPONG) == 0 && tween.active)
				tween.update(FlxMath.MAX_VALUE_FLOAT);
	}

	/**
	 * Applies a function to all tweens
	 *
	 * @param   Function   A function that modifies one tween at a time
	 * @since   4.2.0
	 */
	public function forEach(Function:FlxTween -> Void) {
		for (tween in _tweens)
			Function(tween);
	}
}

private typedef TweenProperty = {object:Dynamic, field:OneOfTwo<String, Int>}