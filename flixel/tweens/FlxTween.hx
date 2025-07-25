package flixel.tweens;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxTypes;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.misc.AngleTween;
import flixel.tweens.misc.BezierPathTween;
import flixel.tweens.misc.BezierPathNumTween;
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
enum abstract FlxTweenType(ByteUInt) from ByteUInt to ByteUInt
{
	/**
	 * Persistent Tween type, will stop when it finishes.
	 */
	var PERSIST = 1;

	/**
	 * Looping Tween type, will restart immediately when it finishes.
	 */
	var LOOPING = 2;

	/**
	 * "To and from" Tween type, will play tween hither and thither
	 */
	var PINGPONG = 4;

	/**
	 * Oneshot Tween type, will stop and remove itself from its core container when it finishes.
	 */
	var ONESHOT = 8;

	/**
	 * Backward Tween type, will play tween in reverse direction
	 */
	var BACKWARD = 16;
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
 * sprite.x = 200;
 * sprite.y = 200;
 *
 * FlxTween.tween(sprite, { x: 600, y: 800 }, 2.0);
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
 * public function new()
 * {
 *     super();
 *     // set up sprite
 *     tween = FlxTween.tween(sprite, { x:600, y:800 }, 2);
 * }
 *
 * override public function update(elapsed:Float)
 * {
 *     super.update(elapsed);
 *
 *     if (FlxG.keys.justPressed.SPACE)
 *         tween.cancel();
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
 * public function new()
 * {
 *     super();
 *     // set up sprite
 *     sprite.x = 200;
 *     sprite.y = 200;
 *     FlxTween.tween(sprite, { x: 600, y: 800 }, 2,
 *         {
 *             type:       PINGPONG,
 *             ease:       FlxEase.quadInOut,
 *             onComplete: changeColor,
 *             startDelay: 1,
 *             loopDelay:  2
 *         }
 *     );
 * }
 *
 * function changeColor(tween:FlxTween):Void
 * {
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
 * FlxTween.color(sprite, 3.0, FlxColor.RED, FlxColor.GREEN, { onComplete:onTweenComplete } );
 * ```
 *
 * ### Angle
 * Tweens the angle of a sprite, normal tweening would have trouble going from negative to positive angles.
 *
 * ```haxe
 * FlxTween.angle(sprite, -90, 180, 3.0, { onComplete:onTweenComplete } );
 * ```
 * ### Num
 * Calls a function with the tweened value over time, no parent object involved.
 *
 * ```haxe
 * FlxTween.num(0, totalWinnings, 3.0, function(num) { field.text = addCommas(num); });
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
class FlxTween implements IFlxDestroyable
{
	/**
	 * The global tweening manager that handles global tweens
	 * @since 4.2.0
	 */
	public static var globalManager:FlxTweenManager;

	/**
	 * Tweens numeric public properties of an Object and values of that object Array<Float>.
	 *
	 * @param	Object		The object containing the properties to tween.
	 * @param	Values		An object containing key/value pairs of properties and target values Array<Float>.
	 * @param	Duration	Duration of the tween in seconds.
	 * @param	Options		A structure with tween options.
	 * @return	The added VarTween object.
	 */
	public static function berizePathTween(Object:Dynamic, Values:Dynamic, Duration:Float = 1, ?Options:TweenOptions):BezierPathTween
	{
		return globalManager.bezierPathTween(Object, Values, Duration, Options);
	}

	/**
	 * Tweens numeric points of that object Array<Float>.
	 *
	 * @param	Points		The object containing the properties to tween.
	 * @param	Duration		Duration of the twene in seconds.
	 * @param	Options	A structure with tween options.
	 * @param	TweenFunction		A function called when tween ends. Float->Void
	 * @return	The added VarTween object.
	 */
	public function createBezierPathNumTween(Points:Array<Float>, Duration:Float, ?Options:TweenOptions, ?TweenFunction:Float->Void):BezierPathNumTween
	{
		return globalManager.bezierPathNumTween(Points, Duration, Options, TweenFunction);
	}

	/**
	 * Tweens numeric public properties of an Object. Shorthand for creating a VarTween, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.tween(Object, { x: 500, y: 350, "scale.x": 2 }, 2.0, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object		The object containing the properties to tween.
	 * @param	Values		An object containing key/value pairs of properties and target values.
	 * @param	Duration	Duration of the tween in seconds.
	 * @param	Options		A structure with tween options.
	 * @return	The added VarTween object.
	 */
	public static function tween(Object:Dynamic, Values:Dynamic, Duration:Float = 1, ?Options:TweenOptions):VarTween
	{
		return globalManager.tween(Object, Values, Duration, Options);
	}

	/**
	 * Tweens some numeric value. Shorthand for creating a NumTween, starting it and adding it to the TweenManager. Using it in
	 * conjunction with a TweenFunction requires more setup, but is faster than VarTween because it doesn't use Reflection.
	 *
	 * ```haxe
	 * function tweenFunction(s:FlxSprite, v:Float) { s.alpha = v; }
	 * FlxTween.num(1, 0, 2.0, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT }, tweenFunction.bind(mySprite));
	 * ```
	 *
	 * Trivia: For historical reasons, you can use either onUpdate or TweenFunction to accomplish the same thing, but TweenFunction
	 * gives you the updated Float as a direct argument.
	 *
	 * @param	FromValue	Start value.
	 * @param	ToValue		End value.
	 * @param	Duration	Duration of the tween.
	 * @param	Options		A structure with tween options.
	 * @param	TweenFunction	A function to be called when the tweened value updates.  It is recommended not to use an anonymous
	 *							function if you are maximizing performance, as those will be compiled to Dynamics on cpp.
	 * @return	The added NumTween object.
	 */
	public static function num(FromValue:Float, ToValue:Float, Duration:Float = 1, ?Options:TweenOptions, ?TweenFunction:Float->Void):NumTween
	{
		return globalManager.num(FromValue, ToValue, Duration, Options, TweenFunction);
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
	public static function flicker(basic:FlxBasic, duration = 1.0, period = 0.08, ?options:FlickerTweenOptions)
	{
		return globalManager.flicker(basic, duration, period, options);
	}

	/**
	 * Whether the object is flickering via the global tween manager
	 * @since 5.7.0
	 */
	public static function isFlickering(basic:FlxBasic)
	{
		return globalManager.isFlickering(basic);
	}

	/**
	 * Cancels all flicker tweens on the object in the global tween manager
	 * @since 5.7.0
	 */
	public static function stopFlickering(basic:FlxBasic)
	{
		return globalManager.stopFlickering(basic);
	}

	/**
	 * A simple shake effect for FlxSprite. Shorthand for creating a ShakeTween, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.shake(Sprite, 0.1, 2, FlxAxes.XY, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Sprite       Sprite to shake.
	 * @param   Intensity    Percentage representing the maximum distance
	 *                       that the sprite can move while shaking.
	 * @param   Duration     The length in seconds that the shaking effect should last.
	 * @param   Axes         On what axes to shake. Default value is `FlxAxes.XY` / both.
	 * @param	Options      A structure with tween options.
	 * @return The added ShakeTween object.
	 */
	public static function shake(Sprite:FlxSprite, Intensity:Float = 0.05, Duration:Float = 1, ?Axes:FlxAxes, ?Options:TweenOptions):ShakeTween
	{
		return globalManager.shake(Sprite, Intensity, Duration, Axes, Options);
	}

	/**
	 * Tweens numeric value which represents angle. Shorthand for creating a AngleTween object, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.angle(Sprite, -90, 90, 2.0, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Sprite		Optional Sprite whose angle should be tweened.
	 * @param	FromAngle	Start angle.
	 * @param	ToAngle		End angle.
	 * @param	Duration	Duration of the tween.
	 * @param	Options		A structure with tween options.
	 * @return	The added AngleTween object.
	 */
	public static function angle(?Sprite:FlxSprite, FromAngle:Float, ToAngle:Float, Duration:Float = 1, ?Options:TweenOptions):AngleTween
	{
		return globalManager.angle(Sprite, FromAngle, ToAngle, Duration, Options);
	}

	/**
	 * Tweens numeric value which represents color. Shorthand for creating a ColorTween object, starting it and adding it to a TweenPlugin.
	 *
	 * ```haxe
	 * FlxTween.color(Sprite, 2.0, 0x000000, 0xffffff, 0.0, 1.0, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Sprite		Optional Sprite whose color should be tweened.
	 * @param	Duration	Duration of the tween in seconds.
	 * @param	FromColor	Start color.
	 * @param	ToColor		End color.
	 * @param	Options		A structure with tween options.
	 * @return	The added ColorTween object.
	 */
	public static function color(?Sprite:FlxSprite, Duration:Float = 1, FromColor:FlxColor, ToColor:FlxColor, ?Options:TweenOptions):ColorTween
	{
		return globalManager.color(Sprite, Duration, FromColor, ToColor, Options);
	}

	/**
	 * Create a new LinearMotion tween.
	 *
	 * ```haxe
	 * FlxTween.linearMotion(Object, 0, 0, 500, 20, 5, false, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	FromX			X start.
	 * @param	FromY			Y start.
	 * @param	ToX				X finish.
	 * @param	ToY				Y finish.
	 * @param	DurationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	UseDuration		Whether to use the previous param as duration or speed.
	 * @param	Options			A structure with tween options.
	 * @return The LinearMotion object.
	 */
	public static function linearMotion(Object:FlxObject, FromX:Float, FromY:Float, ToX:Float, ToY:Float, DurationOrSpeed:Float = 1, UseDuration:Bool = true,
			?Options:TweenOptions):LinearMotion
	{
		return globalManager.linearMotion(Object, FromX, FromY, ToX, ToY, DurationOrSpeed, UseDuration, Options);
	}

	/**
	 * Create a new QuadMotion tween.
	 *
	 * ```haxe
	 * FlxTween.quadMotion(Object, 0, 100, 300, 500, 100, 2, 5, false, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	FromX			X start.
	 * @param	FromY			Y start.
	 * @param	ControlX		X control, used to determine the curve.
	 * @param	ControlY		Y control, used to determine the curve.
	 * @param	ToX				X finish.
	 * @param	ToY				Y finish.
	 * @param	DurationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	UseDuration		Whether to use the previous param as duration or speed.
	 * @param	Options			A structure with tween options.
	 * @return The QuadMotion object.
	 */
	public static function quadMotion(Object:FlxObject, FromX:Float, FromY:Float, ControlX:Float, ControlY:Float, ToX:Float, ToY:Float,
			DurationOrSpeed:Float = 1, UseDuration:Bool = true, ?Options:TweenOptions):QuadMotion
	{
		return globalManager.quadMotion(Object, FromX, FromY, ControlX, ControlY, ToX, ToY, DurationOrSpeed, UseDuration, Options);
	}

	/**
	 * Create a new CubicMotion tween.
	 *
	 * ```haxe
	 * FlxTween.cubicMotion(_sprite, 0, 0, 500, 100, 400, 200, 100, 100, 2, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object 		The object to move (FlxObject or FlxSpriteGroup)
	 * @param	FromX		X start.
	 * @param	FromY		Y start.
	 * @param	aX			First control x.
	 * @param	aY			First control y.
	 * @param	bX			Second control x.
	 * @param	bY			Second control y.
	 * @param	ToX			X finish.
	 * @param	ToY			Y finish.
	 * @param	Duration	Duration of the movement in seconds.
	 * @param	Options		A structure with tween options.
	 * @return The CubicMotion object.
	 */
	public static function cubicMotion(Object:FlxObject, FromX:Float, FromY:Float, aX:Float, aY:Float, bX:Float, bY:Float, ToX:Float, ToY:Float,
			Duration:Float = 1, ?Options:TweenOptions):CubicMotion
	{
		return globalManager.cubicMotion(Object, FromX, FromY, aX, aY, bX, bY, ToX, ToY, Duration, Options);
	}

	/**
	 * Create a new CircularMotion tween.
	 *
	 * ```haxe
	 * FlxTween.circularMotion(Object, 250, 250, 50, 0, true, 2, true, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	CenterX			X position of the circle's center.
	 * @param	CenterY			Y position of the circle's center.
	 * @param	Radius			Radius of the circle.
	 * @param	Angle			Starting position on the circle.
	 * @param	Clockwise		If the motion is clockwise.
	 * @param	DurationOrSpeed	Duration of the movement in seconds.
	 * @param	UseDuration		Duration of the movement.
	 * @param	Ease			Optional easer function.
	 * @param	Options			A structure with tween options.
	 * @return The CircularMotion object.
	 */
	public static function circularMotion(Object:FlxObject, CenterX:Float, CenterY:Float, Radius:Float, Angle:Float, Clockwise:Bool,
			DurationOrSpeed:Float = 1, UseDuration:Bool = true, ?Options:TweenOptions):CircularMotion
	{
		return globalManager.circularMotion(Object, CenterX, CenterY, Radius, Angle, Clockwise, DurationOrSpeed, UseDuration, Options);
	}

	/**
	 * Create a new LinearPath tween.
	 *
	 * ```haxe
	 * FlxTween.linearPath(Object, [FlxPoint.get(0, 0), FlxPoint.get(100, 100)], 2, true, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object 			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	Points			An array of at least 2 FlxPoints defining the path
	 * @param	DurationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	UseDuration		Whether to use the previous param as duration or speed.
	 * @param	Options			A structure with tween options.
	 * @return	The LinearPath object.
	 */
	public static function linearPath(Object:FlxObject, Points:Array<FlxPoint>, DurationOrSpeed:Float = 1, UseDuration:Bool = true,
			?Options:TweenOptions):LinearPath
	{
		return globalManager.linearPath(Object, Points, DurationOrSpeed, UseDuration, Options);
	}

	/**
	 * Create a new QuadPath tween.
	 *
	 * ```haxe
	 * FlxTween.quadPath(Object, [FlxPoint.get(0, 0), FlxPoint.get(200, 200), FlxPoint.get(400, 0)], 2, true, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	Points			An array of at least 3 FlxPoints defining the path
	 * @param	DurationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	UseDuration		Whether to use the previous param as duration or speed.
	 * @param	Options			A structure with tween options.
	 * @return	The QuadPath object.
	 */
	public static function quadPath(Object:FlxObject, Points:Array<FlxPoint>, DurationOrSpeed:Float = 1, UseDuration:Bool = true,
			?Options:TweenOptions):QuadPath
	{
		return globalManager.quadPath(Object, Points, DurationOrSpeed, UseDuration, Options);
	}

	/**
	 * Cancels all related tweens on the specified object.
	 *
	 * Note: Any tweens with the specified fields are cancelled, if the tween has other properties they
	 * will also be cancelled.
	 *
	 * @param Object The object with tweens to cancel.
	 * @param FieldPaths Optional list of the tween field paths to search for. If null or empty, all tweens on the specified
	 * object are canceled. Allows dot paths to check child properties.
	 *
	 * @since 4.9.0
	 */
	public static function cancelTweensOf(Object:Dynamic, ?FieldPaths:Array<String>):Void
	{
		globalManager.cancelTweensOf(Object, FieldPaths);
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
	 * @param Object The object with tweens to complete.
	 * @param FieldPaths Optional list of the tween field paths to search for. If null or empty, all tweens on
	 * the specified object are completed. Allows dot paths to check child properties.
	 *
	 * @since 4.9.0
	 */
	public static function completeTweensOf(Object:Dynamic, ?FieldPaths:Array<String>):Void
	{
		globalManager.completeTweensOf(Object, FieldPaths);
	}

	/**
	 * The manager to which this tween belongs
	 * @since 4.2.0
	 */
	public var manager:FlxTweenManager;

	public var active(default, set):Bool = false;
	public var duration:Float = 0;
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
	public var scale(default, null):Float = 0;
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
	public var executions(default, null):Int = 0;

	/**
	 * Seconds to wait until starting this tween, 0 by default
	 */
	public var startDelay(default, set):Float = 0;

	/**
	 * Seconds to wait between loops of this tween, 0 by default
	 */
	public var loopDelay(default, set):Float = 0;

	var _secondsSinceStart:Float = 0;
	var _delayToUse:Float = 0;
	var _running:Bool = false;
	var _waitingForRestart:Bool = false;
	var _chainedTweens:Array<FlxTween>;
	var _nextTweenInChain:FlxTween;

	/**
	 * This function is called when tween is created, or recycled.
	 */
	function new(Options:TweenOptions, ?manager:FlxTweenManager):Void
	{
		Options = resolveTweenOptions(Options);

		type = Options.type;
		onStart = Options.onStart;
		onUpdate = Options.onUpdate;
		onComplete = Options.onComplete;
		ease = Options.ease;
		framerate = Options.framerate != null ? Options.framerate : 0;
		setDelays(Options.startDelay, Options.loopDelay);
		this.manager = manager != null ? manager : globalManager;
	}

	function resolveTweenOptions(Options:TweenOptions):TweenOptions
	{
		if (Options == null)
			Options = {type: FlxTweenType.ONESHOT};

		if (Options.type == null)
			Options.type = FlxTweenType.ONESHOT;

		return Options;
	}

	public function destroy():Void
	{
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
	public function then(tween:FlxTween):FlxTween
	{
		return addChainedTween(tween);
	}

	/**
	 * How many seconds to delay the execution of the next tween in a tween chain.
	 */
	public function wait(delay:Float):FlxTween
	{
		return addChainedTween(FlxTween.num(0, 0, delay));
	}

	function addChainedTween(tween:FlxTween):FlxTween
	{
		tween.setVarsOnEnd();
		tween.manager.remove(tween, false);

		if (_chainedTweens == null)
			_chainedTweens = [];

		_chainedTweens.push(tween);
		return this;
	}

	function update(elapsed:Float):Void
	{
		var preTick:Float = _secondsSinceStart;
		_secondsSinceStart += elapsed;
		var postTick:Float = _secondsSinceStart;
		var delay:Float = (executions > 0) ? loopDelay : startDelay;
		if (_secondsSinceStart < delay)
		{
			return;
		}

		if (framerate > 0)
		{
			preTick = Math.fround(preTick * framerate) / framerate;
			postTick = Math.fround(postTick * framerate) / framerate;
		}

		scale = Math.max((postTick - delay), 0) / duration;
		if (ease != null)
		{
			scale = ease(scale);
		}
		if (backward)
		{
			scale = 1 - scale;
		}
		if (_secondsSinceStart > delay && !_running)
		{
			_running = true;
			if (onStart != null)
				onStart(this);
		}
		if (_secondsSinceStart >= duration + delay)
		{
			scale = (backward) ? 0 : 1;
			finished = true;
		}
		else
		{
			if (postTick > preTick && onUpdate != null)
				onUpdate(this);
		}
	}

	/**
	 * Starts the Tween, or restarts it if it's currently running.
	 */
	public function start():FlxTween
	{
		_waitingForRestart = false;
		_secondsSinceStart = 0;
		_delayToUse = (executions > 0) ? loopDelay : startDelay;
		if (duration == 0)
		{
			active = false;
			return this;
		}
		active = true;
		_running = false;
		finished = false;
		return this;
	}

	/**
	 * Immediately stops the Tween and removes it from its
	 * `manager` without calling the `onComplete` callback.
	 *
	 * Yields control to the next chained Tween if one exists.
	 */
	public function cancel():Void
	{
		onEnd();

		if (manager != null)
			manager.remove(this);
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
	public function cancelChain():Void
	{
		// Pass along the cancellation request.
		if (_nextTweenInChain != null)
			_nextTweenInChain.cancelChain();

		// Prevent yielding control to any chained tweens.
		if (_chainedTweens != null)
			_chainedTweens = null;

		cancel();
	}

	function finish():Void
	{
		executions++;

		if (onComplete != null)
			onComplete(this);

		var type = type & ~FlxTweenType.BACKWARD;

		if (type == FlxTweenType.PERSIST || type == FlxTweenType.ONESHOT)
		{
			onEnd();
			_secondsSinceStart = duration + startDelay;

			if (type == FlxTweenType.ONESHOT && manager != null)
			{
				manager.remove(this);
			}
		}

		if (type == FlxTweenType.LOOPING || type == FlxTweenType.PINGPONG)
		{
			_secondsSinceStart = (_secondsSinceStart - _delayToUse) % duration + _delayToUse;
			scale = Math.max((_secondsSinceStart - _delayToUse), 0) / duration;

			if (ease != null && scale > 0 && scale < 1)
			{
				scale = ease(scale);
			}

			if (type == FlxTweenType.PINGPONG)
			{
				backward = !backward;
				if (backward)
				{
					scale = 1 - scale;
				}
			}

			restart();
		}
	}

	/**
	 * Called when the tween ends, either via finish() or cancel().
	 */
	function onEnd():Void
	{
		setVarsOnEnd();
		processTweenChain();
	}

	function setVarsOnEnd():Void
	{
		active = false;
		_running = false;
		finished = true;
	}

	function processTweenChain():Void
	{
		if (_chainedTweens == null || _chainedTweens.length <= 0)
			return;

		// Remember next tween to enable cancellation of the chain.
		_nextTweenInChain = _chainedTweens.shift();

		doNextTween(_nextTweenInChain);
		_chainedTweens = null;
	}

	function doNextTween(tween:FlxTween):Void
	{
		if (!tween.active)
		{
			tween.start();
			manager.add(tween);
		}

		tween.setChain(_chainedTweens);
	}

	function setChain(previousChain:Array<FlxTween>):Void
	{
		if (previousChain == null)
			return;

		if (_chainedTweens == null)
			_chainedTweens = previousChain;
		else
			_chainedTweens = _chainedTweens.concat(previousChain);
	}

	/**
	 * In case the tween.active was set to false in onComplete(),
	 * the tween should not be restarted yet.
	 */
	function restart():Void
	{
		if (active)
		{
			start();
		}
		else
		{
			_waitingForRestart = true;
		}
	}

	/**
	 * Returns true if this is tweening the specified field on the specified object.
	 *
	 * @param Object The object.
	 * @param Field Optional tween field. Ignored if null.
	 *
	 * @since 4.9.0
	 */
	function isTweenOf(Object:Dynamic, ?Field:OneOfTwo<String, Int>):Bool
	{
		return false;
	}

	/**
	 * Set both type of delays for this tween.
	 *
	 * @param	startDelay	Seconds to wait until starting this tween, 0 by default.
	 * @param	loopDelay	Seconds to wait between loops of this tween, 0 by default.
	 */
	function setDelays(?StartDelay:Null<Float>, ?LoopDelay:Null<Float>):FlxTween
	{
		startDelay = (StartDelay != null) ? StartDelay : 0;
		loopDelay = (LoopDelay != null) ? LoopDelay : 0;
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
	public static function parseFieldString(input:String):Array<OneOfTwo<String, Int>>
	{
		var result:Array<OneOfTwo<String, Int>> = [];
		var start = 0;
		var inBracket = false;
		var lastWasDot = false;
		var len = input.length;

		for (i in 0...len)
		{
			var c = StringTools.unsafeCodeAt(input, i);

			switch (c)
			{
				case ".".code:
					if (!inBracket && (i > start || lastWasDot))
					{
						result.push(input.substr(start, i - start));
					}
					start = i + 1;
					lastWasDot = true;
				case '['.code if (!inBracket):
					if (i > start)
					{
						result.push(input.substr(start, i - start));
					}
					else if (lastWasDot)
						result.push("");
					start = i + 1;
					inBracket = true;
					lastWasDot = false;
				case ']'.code if (inBracket):
					if (i > start)
					{
						result.push(Std.parseInt(input.substr(start, i - start)));
					}
					start = i + 1;
					inBracket = false;
			}
		}

		if (start < len || lastWasDot)
		{
			var current = input.substr(start);
			result.push(inBracket ? Std.parseInt(current) : current);
		}

		if (result.length == 0)
			result.push("");

		return result;
	}

	function set_startDelay(value:Float):Float
	{
		var dly:Float = Math.abs(value);
		if (executions == 0)
		{
			_delayToUse = dly;
		}
		return startDelay = dly;
	}

	function set_loopDelay(value:Null<Float>):Float
	{
		var dly:Float = Math.abs(value);
		if (executions > 0)
		{
			_secondsSinceStart = duration * percent + Math.max((dly - loopDelay), 0);
			_delayToUse = dly;
		}
		return loopDelay = dly;
	}

	inline function get_time():Float
	{
		return Math.max(_secondsSinceStart - _delayToUse, 0);
	}

	inline function get_percent():Float
	{
		return time / duration;
	}

	function set_percent(value:Float):Float
	{
		return _secondsSinceStart = duration * value + _delayToUse;
	}

	function set_type(value:Int):Int
	{
		if (value == 0)
		{
			value = FlxTweenType.ONESHOT;
		}
		else if (value == FlxTweenType.BACKWARD)
		{
			value = FlxTweenType.PERSIST | FlxTweenType.BACKWARD;
		}

		backward = (value & FlxTweenType.BACKWARD) > 0;
		return type = value;
	}

	function set_active(active:Bool):Bool
	{
		this.active = active;

		if (_waitingForRestart)
			restart();

		return active;
	}
}

typedef TweenCallback = FlxTween->Void;

typedef TweenOptions =
{
	/**
	 * Tween type - bit field of `FlxTween`'s static type constants.
	 */
	@:optional var type:FlxTweenType;

	/**
	 * Optional easer function (see `FlxEase`).
	 */
	@:optional var ease:EaseFunction;

	/**
	 * Optional set framerate for this tween to update at.
	 * This also affects how often `onUpdate` is called.
	 */
	@:optional var framerate:Null<Float>;

	/**
	 * Optional start callback function.
	 */
	@:optional var onStart:TweenCallback;

	/**
	 * Optional update callback function.
	 */
	@:optional var onUpdate:TweenCallback;

	/**
	 * Optional complete callback function.
	 */
	@:optional var onComplete:TweenCallback;

	/**
	 * Seconds to wait until starting this tween, `0` by default.
	 */
	@:optional var startDelay:Float;

	/**
	 * Seconds to wait between loops of this tween, `0` by default.
	 */
	@:optional var loopDelay:Float;
}

/**
 * A simple manager for tracking and updating game tween objects.
 * Normally accessed via the static `FlxTween.globalManager` rather than being created separately.
 */
@:access(flixel.tweens)
@:access(flixel.tweens.FlxTween)
class FlxTweenManager extends FlxBasic
{
	/**
	 * A list of all FlxTween objects.
	 */
	var _tweens(default, null):Array<FlxTween> = [];

	public function new():Void
	{
		super();
		visible = false; // No draw-calls needed
		FlxG.signals.preStateSwitch.add(clear);
	}

	/**
	 * Tweens numeric public properties of an Object and it's numeric array values.
	 *
	 * @param	Object		The object containing the properties to tween.
	 * @param	Values		An object containing key/value pairs of properties and target values. Dynamic<Array<Float>>
	 * @param	Duration	Duration of the tween in seconds.
	 * @param	Options		A structure with tween options.
	 * @return	The added BezierPathTween.
	 */
	public function bezierPathTween(Object:Dynamic, Values:Dynamic<Array<Float>>, Duration:Float = 1, ?Options:TweenOptions):BezierPathTween
	{
		var tween = new BezierPathTween(Options, this);
		tween.tween(Object, Values, Duration);
		return add(tween);
	}

	/**
	 * Tween numeric public properties of points.
	 *
	 * @param Points The point the tween creates. Array<Float>
	 * @param Duration Duration of the tween in seconds.
	 * @param Options A structure with tween options.
	 * @param TweenFunction A function called at the end. Float->Void
	 */
	public function bezierPathNumTween(Points:Array<Float>, Duration:Float = 1, ?Options:TweenOptions, ?TweenFunction:Float->Void):BezierPathNumTween
	{
		var tween = new BezierPathNumTween(Options, this);
		tween.tween(Points, Duration, TweenFunction);
		return add(tween);
	}

	/**
	 * Tweens numeric public properties of an Object. Shorthand for creating a VarTween, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.tween(Object, { x: 500, y: 350, "scale.x": 2 }, 2.0, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object		The object containing the properties to tween.
	 * @param	Values		An object containing key/value pairs of properties and target values.
	 * @param	Duration	Duration of the tween in seconds.
	 * @param	Options		A structure with tween options.
	 * @return	The added VarTween object.
	 * @since   4.2.0
	 */
	public function tween(Object:Dynamic, Values:Dynamic, Duration:Float = 1, ?Options:TweenOptions):VarTween
	{
		var tween = new VarTween(Options, this);
		tween.tween(Object, Values, Duration);
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
	public function flicker(basic:FlxBasic, duration = 1.0, period = 0.08, ?options:FlickerTweenOptions)
	{
		final tween = new FlickerTween(options, this);
		tween.tween(basic, duration, period);
		return add(tween);
	}

	/**
	 * Whether the object is flickering via this manager
	 * @since 5.7.0
	 */
	public function isFlickering(basic:FlxBasic)
	{
		return containsTweensOf(basic, ["flicker"]);
	}

	/**
	 * Cancels all flicker tweens on the object
	 * @since 5.7.0
	 */
	public function stopFlickering(basic:FlxBasic)
	{
		return cancelTweensOf(basic, ["flicker"]);
	}

	/**
	 * Tweens some numeric value. Shorthand for creating a NumTween, starting it and adding it to the TweenManager. Using it in
	 * conjunction with a TweenFunction requires more setup, but is faster than VarTween because it doesn't use Reflection.
	 *
	 * ```haxe
	 * function tweenFunction(s:FlxSprite, v:Float) { s.alpha = v; }
	 * FlxTween.num(1, 0, 2.0, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT }, tweenFunction.bind(mySprite));
	 * ```
	 *
	 * Trivia: For historical reasons, you can use either onUpdate or TweenFunction to accomplish the same thing, but TweenFunction
	 * gives you the updated Float as a direct argument.
	 *
	 * @param	FromValue	Start value.
	 * @param	ToValue		End value.
	 * @param	Duration	Duration of the tween.
	 * @param	Options		A structure with tween options.
	 * @param	TweenFunction	A function to be called when the tweened value updates.  It is recommended not to use an anonymous
	 *							function if you are maximizing performance, as those will be compiled to Dynamics on cpp.
	 * @return	The added NumTween object.
	 * @since   4.2.0
	 */
	public function num(FromValue:Float, ToValue:Float, Duration:Float = 1, ?Options:TweenOptions, ?TweenFunction:Float->Void):NumTween
	{
		var tween = new NumTween(Options, this);
		tween.tween(FromValue, ToValue, Duration, TweenFunction);
		return add(tween);
	}

	/**
	 * A simple shake effect for FlxSprite. Shorthand for creating a ShakeTween, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.shake(Sprite, 0.1, 2, FlxAxes.XY, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Sprite       Sprite to shake.
	 * @param   Intensity    Percentage representing the maximum distance
	 *                       that the sprite can move while shaking.
	 * @param   Duration     The length in seconds that the shaking effect should last.
	 * @param   Axes         On what axes to shake. Default value is `FlxAxes.XY` / both.
	 * @param	Options      A structure with tween options.
	 */
	public function shake(Sprite:FlxSprite, Intensity:Float = 0.05, Duration:Float = 1, ?Axes:FlxAxes = XY, ?Options:TweenOptions):ShakeTween
	{
		var tween = new ShakeTween(Options, this);
		tween.tween(Sprite, Intensity, Duration, Axes);
		return add(tween);
	}

	/**
	 * Tweens numeric value which represents angle. Shorthand for creating a AngleTween object, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.angle(Sprite, -90, 90, 2.0, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Sprite		Optional Sprite whose angle should be tweened.
	 * @param	FromAngle	Start angle.
	 * @param	ToAngle		End angle.
	 * @param	Duration	Duration of the tween.
	 * @param	Options		A structure with tween options.
	 * @return	The added AngleTween object.
	 * @since   4.2.0
	 */
	public function angle(?Sprite:FlxSprite, FromAngle:Float, ToAngle:Float, Duration:Float = 1, ?Options:TweenOptions):AngleTween
	{
		var tween = new AngleTween(Options, this);
		tween.tween(FromAngle, ToAngle, Duration, Sprite);
		return add(tween);
	}

	/**
	 * Tweens numeric value which represents color. Shorthand for creating a ColorTween object, starting it and adding it to a TweenPlugin.
	 *
	 * ```haxe
	 * FlxTween.color(Sprite, 2.0, 0x000000, 0xffffff, 0.0, 1.0, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Sprite		Optional Sprite whose color should be tweened.
	 * @param	Duration	Duration of the tween in seconds.
	 * @param	FromColor	Start color.
	 * @param	ToColor		End color.
	 * @param	Options		A structure with tween options.
	 * @return	The added ColorTween object.
	 * @since   4.2.0
	 */
	public function color(?Sprite:FlxSprite, Duration:Float = 1, FromColor:FlxColor, ToColor:FlxColor, ?Options:TweenOptions):ColorTween
	{
		var tween = new ColorTween(Options, this);
		tween.tween(Duration, FromColor, ToColor, Sprite);
		return add(tween);
	}

	/**
	 * Create a new LinearMotion tween.
	 *
	 * ```haxe
	 * FlxTween.linearMotion(Object, 0, 0, 500, 20, 5, false, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	FromX			X start.
	 * @param	FromY			Y start.
	 * @param	ToX				X finish.
	 * @param	ToY				Y finish.
	 * @param	DurationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	UseDuration		Whether to use the previous param as duration or speed.
	 * @param	Options			A structure with tween options.
	 * @return The LinearMotion object.
	 * @since  4.2.0
	 */
	public function linearMotion(Object:FlxObject, FromX:Float, FromY:Float, ToX:Float, ToY:Float, DurationOrSpeed:Float = 1, UseDuration:Bool = true,
			?Options:TweenOptions):LinearMotion
	{
		var tween = new LinearMotion(Options, this);
		tween.setObject(Object);
		tween.setMotion(FromX, FromY, ToX, ToY, DurationOrSpeed, UseDuration);
		return add(tween);
	}

	/**
	 * Create a new QuadMotion tween.
	 *
	 * ```haxe
	 * FlxTween.quadMotion(Object, 0, 100, 300, 500, 100, 2, 5, false, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	FromX			X start.
	 * @param	FromY			Y start.
	 * @param	ControlX		X control, used to determine the curve.
	 * @param	ControlY		Y control, used to determine the curve.
	 * @param	ToX				X finish.
	 * @param	ToY				Y finish.
	 * @param	DurationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	UseDuration		Whether to use the previous param as duration or speed.
	 * @param	Options			A structure with tween options.
	 * @return The QuadMotion object.
	 * @since  4.2.0
	 */
	public function quadMotion(Object:FlxObject, FromX:Float, FromY:Float, ControlX:Float, ControlY:Float, ToX:Float, ToY:Float, DurationOrSpeed:Float = 1,
			UseDuration:Bool = true, ?Options:TweenOptions):QuadMotion
	{
		var tween = new QuadMotion(Options, this);
		tween.setObject(Object);
		tween.setMotion(FromX, FromY, ControlX, ControlY, ToX, ToY, DurationOrSpeed, UseDuration);
		return add(tween);
	}

	/**
	 * Create a new CubicMotion tween.
	 *
	 * ```haxe
	 * FlxTween.cubicMotion(_sprite, 0, 0, 500, 100, 400, 200, 100, 100, 2, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object 		The object to move (FlxObject or FlxSpriteGroup)
	 * @param	FromX		X start.
	 * @param	FromY		Y start.
	 * @param	aX			First control x.
	 * @param	aY			First control y.
	 * @param	bX			Second control x.
	 * @param	bY			Second control y.
	 * @param	ToX			X finish.
	 * @param	ToY			Y finish.
	 * @param	Duration	Duration of the movement in seconds.
	 * @param	Options		A structure with tween options.
	 * @return The CubicMotion object.
	 * @since  4.2.0
	 */
	public function cubicMotion(Object:FlxObject, FromX:Float, FromY:Float, aX:Float, aY:Float, bX:Float, bY:Float, ToX:Float, ToY:Float, Duration:Float = 1,
			?Options:TweenOptions):CubicMotion
	{
		var tween = new CubicMotion(Options, this);
		tween.setObject(Object);
		tween.setMotion(FromX, FromY, aX, aY, bX, bY, ToX, ToY, Duration);
		return add(tween);
	}

	/**
	 * Create a new CircularMotion tween.
	 *
	 * ```haxe
	 * FlxTween.circularMotion(Object, 250, 250, 50, 0, true, 2, true, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	CenterX			X position of the circle's center.
	 * @param	CenterY			Y position of the circle's center.
	 * @param	Radius			Radius of the circle.
	 * @param	Angle			Starting position on the circle.
	 * @param	Clockwise		If the motion is clockwise.
	 * @param	DurationOrSpeed	Duration of the movement in seconds.
	 * @param	UseDuration		Duration of the movement.
	 * @param	Ease			Optional easer function.
	 * @param	Options			A structure with tween options.
	 * @return The CircularMotion object.
	 * @since  4.2.0
	 */
	public function circularMotion(Object:FlxObject, CenterX:Float, CenterY:Float, Radius:Float, Angle:Float, Clockwise:Bool, DurationOrSpeed:Float = 1,
			UseDuration:Bool = true, ?Options:TweenOptions):CircularMotion
	{
		var tween = new CircularMotion(Options, this);
		tween.setObject(Object);
		tween.setMotion(CenterX, CenterY, Radius, Angle, Clockwise, DurationOrSpeed, UseDuration);
		return add(tween);
	}

	/**
	 * Create a new LinearPath tween.
	 *
	 * ```haxe
	 * FlxTween.linearPath(Object, [FlxPoint.get(0, 0), FlxPoint.get(100, 100)], 2, true, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object 			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	Points			An array of at least 2 FlxPoints defining the path
	 * @param	DurationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	UseDuration		Whether to use the previous param as duration or speed.
	 * @param	Options			A structure with tween options.
	 * @return	The LinearPath object.
	 * @since   4.2.0
	 */
	public function linearPath(Object:FlxObject, Points:Array<FlxPoint>, DurationOrSpeed:Float = 1, UseDuration:Bool = true, ?Options:TweenOptions):LinearPath
	{
		var tween = new LinearPath(Options, this);

		if (Points != null)
		{
			for (point in Points)
			{
				tween.addPoint(point.x, point.y);
			}
		}

		tween.setObject(Object);
		tween.setMotion(DurationOrSpeed, UseDuration);
		return add(tween);
	}

	/**
	 * Create a new QuadPath tween.
	 *
	 * ```haxe
	 * FlxTween.quadPath(Object, [FlxPoint.get(0, 0), FlxPoint.get(200, 200), FlxPoint.get(400, 0)], 2, true, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	Points			An array of at least 3 FlxPoints defining the path
	 * @param	DurationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	UseDuration		Whether to use the previous param as duration or speed.
	 * @param	Options			A structure with tween options.
	 * @return	The QuadPath object.
	 * @since   4.2.0
	 */
	public function quadPath(Object:FlxObject, Points:Array<FlxPoint>, DurationOrSpeed:Float = 1, UseDuration:Bool = true, ?Options:TweenOptions):QuadPath
	{
		var tween = new QuadPath(Options, this);

		if (Points != null)
		{
			for (point in Points)
			{
				tween.addPoint(point.x, point.y);
			}
		}

		tween.setObject(Object);
		tween.setMotion(DurationOrSpeed, UseDuration);
		return add(tween);
	}

	override public function destroy():Void
	{
		super.destroy();
		FlxG.signals.preStateSwitch.remove(clear);
	}

	override public function update(elapsed:Float):Void
	{
		// process finished tweens after iterating through main list, since finish() can manipulate FlxTween.list
		var finishedTweens:Array<FlxTween> = null;

		for (tween in _tweens)
		{
			if (!tween.active)
				continue;

			tween.update(elapsed);
			if (tween.finished)
			{
				if (finishedTweens == null)
					finishedTweens = [];
				finishedTweens.push(tween);
			}
		}

		if (finishedTweens != null)
		{
			while (finishedTweens.length > 0)
			{
				finishedTweens.shift().finish();
			}
		}
	}

	/**
	 * Add a FlxTween.
	 *
	 * @param	Tween	The FlxTween to add.
	 * @param	Start	Whether you want it to start right away.
	 * @return	The added FlxTween object.
	 */
	#if FLX_GENERIC
	@:generic
	#end
	@:allow(flixel.tweens.FlxTween)
	function add<T:FlxTween>(Tween:T, Start:Bool = false):T
	{
		// Don't add a null object
		if (Tween == null)
			return null;

		_tweens.push(Tween);

		if (Start)
			Tween.start();
		return Tween;
	}

	/**
	 * Remove a FlxTween.
	 *
	 * @param	Tween		The FlxTween to remove.
	 * @param	Destroy		Whether you want to destroy the FlxTween
	 * @return	The removed FlxTween object.
	 */
	@:allow(flixel.tweens.FlxTween)
	function remove(Tween:FlxTween, Destroy:Bool = true):FlxTween
	{
		if (Tween == null)
			return null;

		Tween.active = false;

		if (Destroy)
			Tween.destroy();

		FlxArrayUtil.fastSplice(_tweens, Tween);

		return Tween;
	}

	/**
	 * Removes all FlxTweens.
	 */
	public function clear():Void
	{
		for (tween in _tweens)
		{
			if (tween != null)
			{
				tween.active = false;
				tween.destroy();
			}
		}

		_tweens.resize(0);
	}

	/**
	 * Cancels all related tweens on the specified object.
	 *
	 * Note: Any tweens with the specified fields are cancelled, if the tween has other properties they
	 * will also be cancelled.
	 *
	 * @param Object The object with tweens to cancel.
	 * @param FieldPaths Optional list of the tween field paths to search for. If null or empty, all tweens on the specified
	 * object are canceled. Allows dot paths to check child properties.
	 *
	 * @since 4.9.0
	 */
	public function cancelTweensOf(Object:Dynamic, ?FieldPaths:Array<String>):Void
	{
		forEachTweensOf(Object, FieldPaths, function (tween) tween.cancel());
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
	 * @param Object The object with tweens to complete.
	 * @param FieldPaths Optional list of the tween field paths to search for. If null or empty, all tweens on
	 * the specified object are completed. Allows dot paths to check child properties.
	 *
	 * @since 4.9.0
	 */
	public function completeTweensOf(Object:Dynamic, ?FieldPaths:Array<String>):Void
	{
		forEachTweensOf(Object, FieldPaths,
			function (tween)
			{
				if ((tween.type & FlxTweenType.LOOPING) == 0 && (tween.type & FlxTweenType.PINGPONG) == 0 && tween.active)
					tween.update(FlxMath.MAX_VALUE_FLOAT);
			}
		);
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
	function forEachTweensOf(object:Dynamic, ?fieldPaths:Array<String>, func:FlxTween->Void)
	{
		if (object == null)
			throw "Cannot cancel tween variables of an object that is null.";

		if (fieldPaths == null || fieldPaths.length == 0)
		{
			var i = _tweens.length;
			while (i-- > 0)
			{
				var tween = _tweens[i];
				if (tween.isTweenOf(object))
					func(tween);
			}
		}
		else
		{
			// check for dot paths and convert to object/field pairs
			var propertyInfos:Array<TweenProperty> = [];
			for (fieldPath in fieldPaths)
			{
				var target:Dynamic = object;
				var path = FlxTween.parseFieldString(fieldPath);
				var field = path.pop();
				for (component in path)
				{
					if (Type.typeof(component) == TInt)
					{
						if ((target is Array))
						{
							var index:Int = cast component;
							var arr:Array<Dynamic> = cast target;
							target = arr[index];
						}
					}
					else
					{ // TClass(String)
						var field:String = cast component;
						target = Reflect.getProperty(target, field);
					}
					if (!Reflect.isObject(target) && !(target is Array))
						break;
				}

				if (Type.typeof(field) == TInt)
				{
					if ((target is Array))
						propertyInfos.push({object: target, field: field});
				}
				else
				{ // TClass(String)
					if (Reflect.isObject(target))
						propertyInfos.push({object: target, field: field});
				}
			}

			var i = _tweens.length;
			while (i-- > 0)
			{
				final tween = _tweens[i];
				for (info in propertyInfos)
				{
					if (tween.isTweenOf(info.object, info.field))
					{
						func(tween);
						break;
					}
				}
			}
		}
	}

	/**
	 * Crude helper to search for any tweens with the desired properties
	 *
	 * @since 5.7.0
	 */
	function containsTweensOf(object:Dynamic, ?fieldPaths:Array<String>):Bool
	{
		var found = false;
		forEachTweensOf(object, fieldPaths, (_) -> found = true);
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
	public function completeAll():Void
	{
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
	public function forEach(Function:FlxTween->Void)
	{
		for (tween in _tweens)
			Function(tween);
	}
}

private typedef TweenProperty =
{
	object:Dynamic,
	field:OneOfTwo<String, Int>
}