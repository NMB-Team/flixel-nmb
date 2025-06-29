package flixel.input.touch;

#if FLX_TOUCH
import flixel.util.FlxDestroyUtil;
import openfl.Lib;
import openfl.events.TouchEvent;
import openfl.ui.Multitouch;
import openfl.ui.MultitouchInputMode;

/**
 * @author Zaphod
 */
@:nullSafety(Strict)
class FlxTouchManager implements IFlxInputManager {
	/**
	 * The maximum number of concurrent touch points supported by the current device.
	 */
	public static var maxTouchPoints(default, null) = 0;

	/**
	 * All active touches including just created, moving and just released.
	 */
	public final list:Array<FlxTouch> = [];

	/**
	 * Storage for inactive touches (some sort of cache for them).
	 */
	final _inactiveTouches:Array<FlxTouch> = [];

	/**
	 * Helper storage for active touches (for faster access)
	 */
	final _touchesCache:Map<Int, FlxTouch> = [];

	/**
	 * WARNING: can be null if no active touch with the provided ID could be found
	 */
	public inline function getByID(touchPointID:Int):Null<FlxTouch> {
		return _touchesCache.get(touchPointID);
	}

	/**
	 * Return the first touch if there is one, beware of null
	 */
	public inline function getFirst():Null<FlxTouch> {
		return list[0];
	}

	/**
	 * Clean up memory. Internal use only.
	 */
	@:noCompletion public function destroy():Void {
		_touchesCache.clear();
		FlxDestroyUtil.destroyArray(list);
		FlxDestroyUtil.destroyArray(_inactiveTouches);
	}

	/**
	 * Gets all touches which were just started
	 *
	 * @param	TouchArray	Optional array to fill with touch objects
	 * @return	Array with touches
	 */
	public function justStarted(?touchArray:Array<FlxTouch>):Array<FlxTouch> {
		touchArray ??= new Array<FlxTouch>();

		final touchLen = touchArray.length;
		if (touchLen > 0)
			touchArray.resize(0);

		for (touch in list)
			if (touch.justPressed)
				touchArray.push(touch);

		return touchArray;
	}

	/**
	 * Gets all touches which were just ended
	 *
	 * @param	TouchArray	Optional array to fill with touch objects
	 * @return	Array with touches
	 */
	public function justReleased(?touchArray:Array<FlxTouch>):Array<FlxTouch> {
		touchArray ??= new Array<FlxTouch>();

		final touchLen = touchArray.length;
		if (touchLen > 0)
			touchArray.resize(0);

		for (touch in list)
			if (touch.justReleased)
				touchArray.push(touch);

		return touchArray;
	}

	/**
	 * Resets all touches to inactive state.
	 */
	public function reset():Void {
		_touchesCache.clear();

		for (touch in list) {
			touch.input.reset();
			_inactiveTouches.push(touch);
		}

		list.resize(0);
	}

	@:allow(flixel.FlxG)
	private function new() {
		maxTouchPoints = Multitouch.maxTouchPoints;
		Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;

		Lib.current.stage.addEventListener(TouchEvent.TOUCH_BEGIN, handleTouchBegin);
		Lib.current.stage.addEventListener(TouchEvent.TOUCH_END, handleTouchEnd);
		Lib.current.stage.addEventListener(TouchEvent.TOUCH_MOVE, handleTouchMove);
	}

	/**
	 * Event handler so FlxGame can update touches.
	 */
	private function handleTouchBegin(flashEvent:TouchEvent):Void {
		var touch:Null<FlxTouch> = _touchesCache.get(flashEvent.touchPointID);
		if (touch != null) {
			touch.setXY(Std.int(flashEvent.stageX), Std.int(flashEvent.stageY));
			touch.pressure = flashEvent.pressure;
		} else
			touch = recycle(Std.int(flashEvent.stageX), Std.int(flashEvent.stageY), flashEvent.touchPointID, flashEvent.pressure);

		touch.input.press();
	}

	/**
	 * Event handler so FlxGame can update touches.
	 */
	private function handleTouchEnd(flashEvent:TouchEvent):Void {
		final touch:Null<FlxTouch> = _touchesCache.get(flashEvent.touchPointID);
		touch?.input.release();
	}

	/**
	 * Event handler so FlxGame can update touches.
	 */
	private function handleTouchMove(flashEvent:TouchEvent):Void {
		final touch:Null<FlxTouch> = _touchesCache.get(flashEvent.touchPointID);

		if (touch != null) {
			touch.setXY(Std.int(flashEvent.stageX), Std.int(flashEvent.stageY));
			touch.pressure = flashEvent.pressure;
		}
	}

	/**
	 * Internal function for adding new touches to the manager
	 *
	 * @param	touch	A new FlxTouch object
	 * @return	The added FlxTouch object
	 */
	private function add(touch:FlxTouch):FlxTouch {
		list.push(touch);
		_touchesCache.set(touch.touchPointID, touch);
		return touch;
	}

	/**
	 * Internal function for touch reuse
	 *
	 * @param	X			stageX touch coordinate
	 * @param	Y			stageY touch coordinate
	 * @param	PointID		id of the touch
	 * @return	A recycled touch object
	 */
	private function recycle(x:Int, y:Int, pointID:Int, pressure:Float):FlxTouch {
		if (_inactiveTouches.length > 0) {
			@:nullSafety(Off)
			final touch:FlxTouch = _inactiveTouches.pop();
			touch.recycle(x, y, pointID, pressure);
			return add(touch);
		}
		return add(new FlxTouch(x, y, pointID, pressure));
	}

	/**
	 * Called by the internal game loop to update the touch position in the game world.
	 * Also updates the just pressed/just released flags.
	 */
	private function update():Void {
		var i:Int = list.length - 1;
		var touch:FlxTouch;

		while (i >= 0) {
			touch = list[i];

			// Touch ended at previous frame
			if (touch.released && !touch.justReleased) {
				touch.input.reset();
				_touchesCache.remove(touch.touchPointID);
				list.splice(i, 1);
				_inactiveTouches.push(touch);
			} else // Touch is active currently
				touch.update();

			i--;
		}
	}

	private function onFocus():Void {}

	private function onFocusLost():Void {
		reset();
	}
}
#end
