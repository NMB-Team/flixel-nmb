package flixel.system.frontEnds;

import flixel.util.FlxSignal;

/**
 * Accessed via `FlxG.signals`.
 */
class SignalFrontEnd {
	/**
	 * Gets dispatched when a state change occurs.
	 * @since 4.6.0
	 */
	public var preStateSwitch(default, null) = new FlxSignal();

	/**
	 * @since 4.6.0
	 */
	public var postStateSwitch(default, null) = new FlxSignal();

	/** Dispatched just before state.create() is called */
	public var preStateCreate(default, null) = new FlxTypedSignal<FlxState -> Void>();

	/**
	 * Gets dispatched when the game is resized.
	 * Passes the new window width and height to callback functions.
	 */
	public var gameResized(default, null) = new FlxTypedSignal<Int -> Int -> Void>();

	public var preGameReset(default, null) = new FlxSignal();
	public var postGameReset(default, null) = new FlxSignal();

	/**
	 * Gets dispatched just before the game is started (before the first state after the splash screen is created)
	 * @since 4.6.0
	 */
	public var preGameStart(default, null) = new FlxSignal();

	/**
	 * Gets dispatched when the game is started (first state after the splash screen).
	 * @since 4.6.0
	 */
	public var postGameStart(default, null) = new FlxSignal();

	public var preUpdate(default, null) = new FlxSignal();
	public var postUpdate(default, null) = new FlxSignal();
	public var preDraw(default, null) = new FlxSignal();
	public var postDraw(default, null) = new FlxSignal();
	public var focusGained(default, null) = new FlxSignal();
	public var focusLost(default, null) = new FlxSignal();

	@:allow(flixel.FlxG)
	private function new() {}
}
