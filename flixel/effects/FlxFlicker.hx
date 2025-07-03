package flixel.effects;

import flixel.FlxObject;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxPool;
import flixel.util.FlxTimer;

/**
 * The retro flickering effect with callbacks.
 * You can use this as a mixin in any FlxObject subclass or by calling the static functions.
 * @author pixelomatic
 */
class FlxFlicker implements IFlxDestroyable {
	static var _pool = new FlxPool<FlxFlicker>(FlxFlicker.new);

	/**
	 * Internal map for looking up which objects are currently flickering and getting their flicker data.
	 */
	static var _boundObjects = new Map<FlxObject, FlxFlicker>();

	/**
	 * A simple flicker effect for sprites using a `FlxTimer` to toggle visibility.
	 *
	 * @param   object               The object.
	 * @param   duration             How long to flicker for (in seconds). `0` means "forever".
	 * @param   interval             In what interval to toggle visibility. Set to `FlxG.elapsed` if `<= 0`!
	 * @param   endVisibility        Force the visible value when the flicker completes,
	 *                               useful with fast repetitive use.
	 * @param   forceRestart         Force the flicker to restart from beginning,
	 *                               discarding the flickering effect already in progress if there is one.
	 * @param   completionCallback   An optional callback that will be triggered when a flickering has finished.
	 * @param   progressCallback     An optional callback that will be triggered when visibility is toggled.
	 * @return The `FlxFlicker` object. `FlxFlicker`s are pooled internally, so beware of storing references.
	 */
	public static function flicker(object:FlxObject, duration = 1., interval = .04, endVisibility = true, forceRestart = true, ?completionCallback:FlxFlicker -> Void, ?progressCallback:FlxFlicker -> Void):FlxFlicker {
		if (isFlickering(object)) {
			if (forceRestart)
				stopFlickering(object);
			else
				return _boundObjects[object]; // Ignore this call if object is already flickering.
		}

		if (interval <= 0) interval = FlxG.elapsed;

		final flicker = _pool.get();
		flicker.start(object, duration, interval, endVisibility, completionCallback, progressCallback);
		return _boundObjects[object] = flicker;
	}

	/**
	 * Returns whether the object is flickering or not.
	 *
	 * @param   object The object to test.
	 */
	public static function isFlickering(object:FlxObject):Bool {
		return _boundObjects.exists(object);
	}

	/**
	 * Stops flickering of the object. Also it will make the object visible.
	 *
	 * @param   object The object to stop flickering.
	 */
	public static function stopFlickering(object:FlxObject):Void {
		final boundFlicker = _boundObjects[object];
		boundFlicker?.stop();
	}

	/**
	 * The flickering object.
	 */
	public var object(default, null):FlxObject;

	/**
	 * The final visibility of the object after flicker is complete.
	 */
	public var endVisibility(default, null):Bool;

	/**
	 * The flicker timer. You can check how many seconds has passed since flickering started etc.
	 */
	public var timer(default, null):FlxTimer;

	/**
	 * The callback that will be triggered after flicker has completed.
	 */
	public var completionCallback(default, null):FlxFlicker -> Void;

	/**
	 * The callback that will be triggered every time object visiblity is changed.
	 */
	public var progressCallback(default, null):FlxFlicker -> Void;

	/**
	 * The duration of the flicker (in seconds). `0` means "forever".
	 */
	public var duration(default, null):Float;

	/**
	 * The interval of the flicker.
	 */
	public var interval(default, null):Float;

	/**
	 * Nullifies the references to prepare object for reuse and avoid memory leaks.
	 */
	public function destroy():Void {
		object = null;
		timer = null;
		completionCallback = null;
		progressCallback = null;
	}

	/**
	 * Starts flickering behavior.
	 */
	private function start(object:FlxObject, duration:Float, interval:Float, endVisibility:Bool, ?completionCallback:FlxFlicker -> Void, ?progressCallback:FlxFlicker -> Void):Void {
		this.object = object;
		this.duration = duration;
		this.interval = interval;
		this.completionCallback = completionCallback;
		this.progressCallback = progressCallback;
		this.endVisibility = endVisibility;
		timer = new FlxTimer().start(this.interval, flickerProgress, Std.int(this.duration / this.interval));
	}

	/**
	 * Temporarily pause the flickering, so it can be resumed later.
	 */
	public inline function pause():Void {
		if (timer != null) timer.active = false;
	}

	/**
	 * Resume the flickering after it has been temporarily paused.
	 */
	public inline function resume():Void {
		if (timer != null) timer.active = true;
	}

	/**
	 * Prematurely ends flickering.
	 */
	public inline function stop():Void {
		timer?.cancel();
		object.visible = true;
		release();
	}

	/**
	 * Unbinds the object from flicker and releases it into pool for reuse.
	 */
	inline function release():Void {
		_boundObjects.remove(object);
		_pool.put(this);
	}

	/**
	 * Just a helper function for flicker() to update object's visibility.
	 */
	private function flickerProgress(timer:FlxTimer):Void {
		object.visible = !object.visible;

		if (progressCallback != null) progressCallback(this);

		if (timer.loops > 0 && timer.loopsLeft == 0) {
			object.visible = endVisibility;
			if (completionCallback != null) completionCallback(this);
			if (this.timer == timer) release();
		}
	}

	/**
	 * Internal constructor. Use static methods.
	 */
	@:keep function new() {}
}
