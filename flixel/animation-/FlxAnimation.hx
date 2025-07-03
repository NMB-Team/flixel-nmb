package flixel.animation;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;

/**
 * Just a helper structure for the `FlxSprite` animation system.
 */
class FlxAnimation extends FlxBaseAnimation {
	/**
	 * Animation frameRate - the speed in frames per second that the animation should play at.
	 */
	public var frameRate(default, set):Float;

	/**
	 * Keeps track of the current frame of animation.
	 * This is NOT an index into the tile sheet, but the frame number in the animation object.
	 */
	public var curFrame(default, set) = 0;

	/**
	 * Accessor for `frames.length`
	 */
	public var numFrames(get, never):Int;

	/**
	 * Seconds between frames (inverse of the framerate)
	 *
	 * Note: `FlxFrameCollections` and `FlxAtlasFrames` may have their own duration set per-frame,
	 * those values will override this value.
	 */
	public var frameDuration(default, null) = .0;

	/**
	 * Whether the current animation has finished.
	 */
	public var finished(default, null) = true;

	/**
	 * Whether the current animation is at the end aka the last frame.
	 * Works both when looping and reversed.
	**/
	public var isAtEnd(get, never):Bool;

	/**
	 * Whether the current animation gets updated or not.
	 */
	public var paused = true;

	/**
	 * Whether or not the animation is looped.
	 */
	public var looped = true;

	/**
	 * The custom loop point for this animation.
	 * This allows you to skip the first few frames of an animation when looping.
	 */
	public var loopPoint = 0;

	/**
	 * Whether or not this animation is being played backwards.
	 */
	public var reversed(default, null) = false;

	/**
	 * Whether or not the frames of this animation are horizontally flipped
	 */
	public var flipX = false;

	/**
	 * Whether or not the frames of this animation are vertically flipped
	 */
	public var flipY = false;

	/**
	 * A list of frames stored as int indices
	 * @since 4.2.0
	 */
	public var frames:Array<Int>;

	/**
	 * How fast or slow time should pass for this animation.
	 *
	 * Similar to `FlxAnimationController`'s `timeScale`, but won't effect other animations.
	 * @since 5.4.1
	 */
	public var timeScale = 1.;

	public var onFinish:FlxTypedSignal<Void -> Void> = new FlxTypedSignal();
	public var onFinishEnd:FlxTypedSignal<Void -> Void> = new FlxTypedSignal();
	public var onPlay:FlxTypedSignal<String -> Bool -> Bool -> Int -> Void> = new FlxTypedSignal();
	public var onLoop:FlxTypedSignal<Void -> Void> = new FlxTypedSignal();

	/**
	 * Optional offset of the animation's frames from the sprite's position.
	 * This can be useful for creating animations that are not centered around the sprite.
	 */
	public var offset(default, null) = FlxPoint.get();

	public var usesIndices = false;

	@:noCompletion public var usesIndicies(get, set):Bool;

	inline function get_usesIndicies():Bool {
		return usesIndices;
	}

	inline function set_usesIndicies(value:Bool):Bool {
		return usesIndices = value;
	}

	/**
	 * Internal, used to time each frame of animation.
	 */
	var _frameTimer = .0;

	/**
	 * Internal, used to wait the frameDuration at the end of the animation.
	 */
	var _frameFinishedEndTimer = .0;

	/**
	 * @param   name        What this animation should be called (e.g. `"run"`).
	 * @param   frames      An array of numbers indicating what frames to play in what order (e.g. `[1, 2, 3]`).
	 * @param   frameRate   The speed in frames per second that the animation should play at (e.g. `40`).
	 * @param   looped      Whether or not the animation is looped or just plays once.
	 * @param   flipX       Whether or not the frames of this animation are horizontally flipped.
	 * @param   flipY       Whether or not the frames of this animation are vertically flipped.
	 */
	public function new(parent:FlxAnimationController, name:String, frames:Array<Int>, frameRate = .0, looped = true, flipX = false, flipY = false) {
		super(parent, name);

		this.frameRate = frameRate;
		this.frames = frames;
		this.looped = looped;
		this.flipX = flipX;
		this.flipY = flipY;
	}

	/**
	 * Clean up memory.
	 */
	override public function destroy():Void {
		FlxDestroyUtil.destroy(onFinish);
		FlxDestroyUtil.destroy(onFinishEnd);
		onPlay?.destroy();
		onLoop?.destroy();

		offset = FlxDestroyUtil.put(offset);
		frames = null;
		name = null;
		super.destroy();
	}

	/**
	 * Starts this animation playback.
	 *
	 * @param   force      Whether to force this animation to restart.
	 * @param   reversed   Whether to play animation backwards or not.
	 * @param   frame      The frame number in this animation you want to start from (`0` by default).
	 *                     If you pass a negative value then it will start from a random frame.
	 *                     If you `Reversed` is `true`, the frame value will be "reversed"
	 *                     (`Frame = numFrames - 1 - Frame`), so `Frame` value will mean frame index
	 *                     from the animation's end in this case.
	 */
	public function play(force = false, reversed = false, frame = 0):Void {
		if (!force && !finished && this.reversed == reversed) {
			paused = false;
			return;
		}

		this.reversed = reversed;
		paused = false;
		_frameTimer = 0;
		finished = frameDuration == 0;

		final maxFrameIndex = numFrames - 1;
		if (frame >= 0) {
			if (frame > maxFrameIndex) frame = maxFrameIndex;
			if (this.reversed) frame = (maxFrameIndex - frame);
			curFrame = frame;
		} else
			curFrame = FlxG.random.int(0, maxFrameIndex);

		if (finished) {
			_frameFinishedEndTimer = frameDuration;
			onFinish.dispatch();
			parent?.fireFinishCallback(name);
		} else
			_frameFinishedEndTimer = 0;

		parent?.firePlayCallback(name, force, reversed, curFrame);
		onPlay.dispatch(name, force, reversed, curFrame);
	}

	public inline function restart():Void {
		play(true, reversed);
	}

	public inline function stop():Void {
		finished = paused = true;
	}

	public inline function reset():Void {
		stop();
		curFrame = reversed ? (numFrames - 1) : 0;
	}

	public inline function finish():Void {
		stop();
		curFrame = reversed ? 0 : (numFrames - 1);
	}

	public inline function pause():Void {
		paused = true;
	}

	public inline function resume():Void {
		paused = false;
	}

	public inline function reverse():Void {
		reversed = !reversed;
		if (finished) play(false, reversed);
	}

	inline function _doFinishedEndCallback():Void {
		parent.onFinishEnd.dispatch(name);
		onFinishEnd.dispatch();
	}

	override public function update(elapsed:Float):Void {
		if (paused) return;

		if (_frameFinishedEndTimer > 0) {
			_frameFinishedEndTimer -= elapsed * timeScale;
			if (_frameFinishedEndTimer <= 0) {
				_frameFinishedEndTimer = 0;
				_doFinishedEndCallback();
			}
		}

		if (finished) return;

		var curFrameDuration = getCurrentFrameDuration();
		if (curFrameDuration == 0) return;

		_frameTimer += elapsed * timeScale;
		while (_frameTimer > curFrameDuration && !finished) {
			_frameTimer -= curFrameDuration;
			if (reversed) {
				if (looped && curFrame == loopPoint) {
					curFrame = numFrames - 1;
					parent.fireLoopCallback(name);
					onLoop.dispatch();
				} else
					curFrame--;
			} else {
				if (looped && curFrame == numFrames - 1) {
					curFrame = loopPoint;
					parent.fireLoopCallback(name);
					onLoop.dispatch();
				} else
					curFrame++;
			}

			// prevents null ref when the sprite is destroyed on finishCallback (#2782)
			if (finished) break;

			curFrameDuration = getCurrentFrameDuration();
		}
	}

	inline function getCurrentFrameDuration() {
		final curframeDuration = parent.getFrameDuration(frames[curFrame]);
		return curframeDuration > 0 ? curframeDuration : frameDuration;
	}

	override public function clone(newParent:FlxAnimationController):FlxAnimation {
		return new FlxAnimation(newParent, name, frames, frameRate, looped, flipX, flipY);
	}

	inline function set_frameRate(value:Float):Float {
		frameRate = value;
		frameDuration = (value > 0 ? 1 / value : 0);
		return value;
	}

	private function set_curFrame(frame:Int):Int {
		final maxFrameIndex = numFrames - 1;
		final tempFrame = (reversed) ? (maxFrameIndex - frame) : frame;

		if (tempFrame >= 0) {
			if (!looped && tempFrame > maxFrameIndex) {
				finished = true;
				curFrame = reversed ? 0 : maxFrameIndex;
			} else
				curFrame = frame;
		} else
			curFrame = FlxG.random.int(0, maxFrameIndex);

		curIndex = frames[curFrame];

		if (finished) {
			_frameFinishedEndTimer = frameDuration;
			onFinish.dispatch();
			parent?.fireFinishCallback(name);
		}

		return frame;
	}

	inline function get_numFrames():Int {
		return frames.length;
	}

	inline function get_isAtEnd() {
		return reversed ? curFrame == 0 : curFrame == numFrames - 1;
	}
}
