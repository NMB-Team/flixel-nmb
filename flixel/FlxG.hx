package flixel;

#if !macro
import openfl.Lib;
import openfl.display.DisplayObject;
import openfl.display.Stage;
import openfl.display.StageDisplayState;
import openfl.net.URLRequest;
#end
import flixel.math.FlxMath;
import flixel.math.FlxRandom;
import flixel.math.FlxRect;
import flixel.system.FlxQuadTree;
import flixel.system.FlxVersion;
import flixel.system.frontEnds.AssetFrontEnd;
import flixel.system.frontEnds.BitmapFrontEnd;
import flixel.system.frontEnds.BitmapLogFrontEnd;
import flixel.system.frontEnds.CameraFrontEnd;
import flixel.system.frontEnds.ConsoleFrontEnd;
import flixel.system.frontEnds.DebuggerFrontEnd;
import flixel.system.frontEnds.RenderFrontEnd;
import flixel.system.frontEnds.InputFrontEnd;
import flixel.system.frontEnds.LogFrontEnd;
import flixel.system.frontEnds.PluginFrontEnd;
import flixel.system.frontEnds.SignalFrontEnd;
import flixel.system.frontEnds.SoundFrontEnd;
import flixel.system.frontEnds.VCRFrontEnd;
import flixel.system.frontEnds.WatchFrontEnd;
import flixel.system.scaleModes.BaseScaleMode;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.util.FlxAxes;
import flixel.util.FlxCollision;
import flixel.util.FlxSave;
import flixel.util.FlxStringUtil;
import flixel.util.typeLimit.NextState;
#if FLX_TOUCH
import flixel.input.touch.FlxTouchManager;
#end
#if FLX_KEYBOARD
import flixel.input.keyboard.FlxKeyboard;
#end
#if FLX_MOUSE
import flixel.input.mouse.FlxMouse;
#end
#if FLX_GAMEPAD
import flixel.input.gamepad.FlxGamepadManager;
#end
#if android
import flixel.input.android.FlxAndroidKeys;
#end
#if FLX_ACCELEROMETER
import flixel.input.FlxAccelerometer;
#end
#if FLX_GYROSCOPE
import flixel.input.FlxGyroscope;
#end
#if FLX_POINTER_INPUT
import flixel.input.FlxSwipe;
#end
#if html5
import flixel.system.frontEnds.HTML5FrontEnd;
#end

/**
 * Global helper class for audio, input, the camera system, the debugger and other global properties.
 */
class FlxG
{
	/**
	 * Whether the game should be paused when focus is lost or not. Use `-D FLX_NO_FOCUS_LOST_SCREEN`
	 * if you only want to get rid of the default pause screen.
	 * Override `onFocus()` and `onFocusLost()` for your own behaviour in your state.
	 */
	public static var autoPause:Bool = true;

	/**
	 * WARNING: Changing this can lead to issues with physics and the recording system. Setting this to
	 * `false` might lead to smoother animations (even at lower fps) at the cost of physics accuracy.
	 */
	public static var fixedTimestep:Bool = true;

	/**
	 * How fast or slow time should pass in the game; default is `1.0`.
	 */
	public static var timeScale:Float = 1.0;

	/**
	 * How fast or slow animations should pass in the game; default is `1.0`.
	 * @since 5.5.0
	 */
	public static var animationTimeScale:Float = 1.0;

	/**
	 * How many times the quad tree should divide the world on each axis.
	 * Generally, sparse collisions can have fewer divisons,
	 * while denser collision activity usually profits from more. Default value is `6`.
	 */
	public static var worldDivisions:Int = 6;

	/**
	 * By default this just refers to the first entry in the `FlxG.cameras.list`
	 * array but you can do what you like with it.
	 */
	public static var camera:FlxCamera;

	/**
	 * The HaxeFlixel version, in semantic versioning syntax. Use `Std.string()`
	 * on it to get a `String` formatted like this: `"HaxeFlixel MAJOR.MINOR.PATCH-COMMIT_SHA"`.
	 */
	public static var VERSION(default, null):FlxVersion = new FlxVersion(6, 5, 1);

	/**
	 * Internal tracker for game object.
	 */
	public static var game(default, null):FlxGame;

	/**
	 * The stage object (required for event listeners).
	 * Will be `null` if it's not safe/useful yet.
	 */
	public static var stage(get, never):Stage;

	/**
	 * Access the current game state from anywhere. Consider using `addChildBelowMouse()`
	 * if you want to add a `DisplayObject` to the stage instead of directly adding it here!
	 */
	public static var state(get, never):FlxState;

	/**
	 * How many times you want your game to update each second.
	 * More updates usually means better collisions and smoother motion.
	 * NOTE: This is NOT the same thing as the draw framerate!
	 */
	public static var updateFramerate(default, set):Int;

	/**
	 * How many times you want your game to step each second. More steps usually means greater responsiveness,
	 * but it can also slowdown your game if the stage can't keep up with the update routine.
	 * NOTE: This is NOT the same thing as the update framerate!
	 */
	public static var drawFramerate(default, set):Int;

	public static var fixedDelta(default, null) = .0;

	/**
	 * Whether the game is running on a mobile device.
	 * If on HTML5, it returns `FlxG.html5.onMobile`.
	 * Otherwise, it checks whether the `mobile` haxedef is defined.
	 * @since 4.2.0
	 */
	public static var onMobile(get, never):Bool;

	/**
	 * Whether or not antialiasing is allowed.
	 *
	 * If this is disabled, sprites or cameras will not have
	 * any antialiasing, regardless of their individual antialiasing values.
	 *
	 * This could come in handy for an antialiasing option in your game!
	 */
	public static var allowAntialiasing:Bool = true;

	/**
	 * Represents the amount of time in seconds that passed since last frame.
	 */
	@:allow(flixel.FlxGame.updateElapsed)
	public static var elapsed(default, null):Float = 0;

	/**
	 * Represents the amount of time in seconds that passed since last frame. (Ignoring timescale)
	 */
	@:allow(flixel.FlxGame.updateElapsed)
	public static var rawElapsed(default, null):Float = 0;

	/**
	 * Useful when the timestep is NOT fixed (i.e. variable),
	 * to prevent jerky movement or erratic behavior at very low fps.
	 * Essentially locks the framerate to a minimum value - any slower and you'll get
	 * slowdown instead of frameskip; default is 1/10th of a second.
	 */
	public static var maxElapsed:Float = 0.1;

	/**
	 * The width of the screen in game pixels. Read-only, use `resizeGame()` to change.
	 */
	@:allow(flixel.system.scaleModes)
	public static var width(default, null):Int;

	/**
	 * The height of the screen in game pixels. Read-only, use `resizeGame()` to change.
	 */
	@:allow(flixel.system.scaleModes)
	public static var height(default, null):Int;

	/**
	 * The scale mode the game should use.
	 * HaxeFlixel includes several available scale modes, which are located in `flixel.system.scaleModes`.
	 * However, you may also create a class which extends `BaseScaleMode`, and override its behavior according to your needs.
	 */
	public static var scaleMode(default, set):BaseScaleMode = new RatioScaleMode();

	/**
	 * Use this to toggle between fullscreen and normal mode. Works on CPP.
	 * You can easily toggle fullscreen with e.g.: `FlxG.fullscreen = !FlxG.fullscreen;`
	 */
	public static var fullscreen(get, set):Bool;

	/**
	 * The dimensions of the game world, used by the quad tree for collisions and overlap checks.
	 * Use `.set()` instead of creating a new object!
	 */
	public static var worldBounds(default, null):FlxRect = new FlxRect();

	#if FLX_SAVE
	/**
	 * A `FlxSave` used internally by flixel to save sound preferences and
	 * the history of the console window, but no reason you can't use it for your own stuff too!
	 */
	public static var save(default, null):FlxSave = new FlxSave();
	#end

	/**
	 * A `FlxRandom` object which can be used to generate random numbers.
	 * Also used by Flixel internally.
	 */
	public static var random(default, null):FlxRandom = new FlxRandom();

	#if FLX_MOUSE
	/**
	 * Used for mouse input. e.g.: check if the left mouse button
	 * is pressed with `if (FlxG.mouse.pressed) { })` in `update()`.
	 */
	public static var mouse(default, set):FlxMouse;
	#end

	#if FLX_TOUCH
	/**
	 * Useful for devices with multitouch support.
	 */
	public static var touches(default, null):FlxTouchManager;
	#end

	#if FLX_POINTER_INPUT
	/**
	 * Contains all "swipes" from both mouse and touch input that have just ended.
	 */
	public static var swipes(default, null):Array<FlxSwipe> = [];
	#end

	#if FLX_KEYBOARD
	/**
	 * Used for keyboard input e.g.: check if the left arrow key is
	 * pressed with `if (FlxG.keys.pressed.LEFT) { }` in `update()`.
	 */
	public static var keys(default, null):FlxKeyboard;
	#end

	#if FLX_GAMEPAD
	/**
	 * Allows accessing the available gamepads.
	 */
	public static var gamepads(default, null):FlxGamepadManager;
	#end

	#if android
	/**
	 * Useful for tracking Back, Home buttons etc on Android devices.
	 */
	public static var android(default, null):FlxAndroidKeys;
	#end

	#if FLX_ACCELEROMETER
	/**
	 * Provides access to the accelerometer data of mobile devices as `x`/`y`/`z` values.
	 */
	public static var accelerometer(default, null):FlxAccelerometer;
	#end

	#if FLX_GYROSCOPE
	/**
	 * Provides access to the accelerometer data of mobile devices as `pitch`/`roll`/`yaw` values.
	 */
	public static var gyroscope(default, null):FlxGyroscope;
	#end

	#if js
	/**
	 * Has some HTML5-specific things like browser detection, browser dimensions etc...
	 */
	public static var html5(default, null):HTML5FrontEnd = new HTML5FrontEnd();
	#end

	/**
	 * Mostly used internally, but you can use it too to reset inputs and create input classes of your own.
	 */
	public static var inputs(default, null):InputFrontEnd = new InputFrontEnd();

	/**
	 * Used to register functions and objects or add new commands to the console window.
	 */
	public static var console(default, null):ConsoleFrontEnd = new ConsoleFrontEnd();

	/**
	 * Used to add messages to the log window or enable `trace()` redirection.
	 */
	public static var log(default, null):LogFrontEnd = new LogFrontEnd();

	/**
	 * Used to add images to the bitmap log window.
	 */
	public static var bitmapLog(default, null):BitmapLogFrontEnd = new BitmapLogFrontEnd();

	/**
	 * Used to add or remove things to / from the watch window.
	 */
	public static var watch(default, null):WatchFrontEnd = new WatchFrontEnd();

	/**
	 * Used to change the render mode (tile/blit), set the render pixel mode and more.
	 */
	public static var render(default, null) = new RenderFrontEnd();

	/**
	 * Used it to show / hide the debugger, change its layout,
	 * activate debug drawing or change the key used to toggle it.
	 */
	public static var debugger(default, null):DebuggerFrontEnd = new DebuggerFrontEnd();

	/**
	 * Contains all the functions needed for recording and replaying.
	 */
	public static var vcr(default, null):VCRFrontEnd;

	/**
	 * Contains things related to bitmaps, for example regarding the `BitmapData` cache and the cache itself.
	 */
	public static var bitmap(default, null):BitmapFrontEnd = new BitmapFrontEnd();

	/**
	 * Contains things related to cameras, a list of all cameras and several effects like `flash()` or `fade()`.
	 */
	public static var cameras(default, null):CameraFrontEnd = new CameraFrontEnd();

	/**
	 * Contains a list of all plugins and the functions required to `add()`, `remove()` them etc.
	 */
	public static var plugins(default, null):PluginFrontEnd;

	/**
	 * Whenever rendering with antialiasing should be enabled. If `false`, no sprite will render with antialiasing.
	 */
	public static var enableAntialiasing:Bool = true;

	public static var initialWidth(default, null):Int = 0;
	public static var initialHeight(default, null):Int = 0;

	#if FLX_SOUND_SYSTEM
	/**
	 * Contains a list of all sounds and other things to manage or `play()` sounds.
	 */
	public static var sound(default, null):SoundFrontEnd;
	#end

	/**
	 * Contains system-wide signals like `gameResized` or `preStateSwitch`.
	 */
	public static var signals(default, null):SignalFrontEnd = new SignalFrontEnd();

	/**
	 * Contains helper functions relating to retrieving assets
	 * @since 5.9.0
	 */
	public static var assets(default, null):AssetFrontEnd = new AssetFrontEnd();

	/**
	 * Resizes the game within the window by reapplying the current scale mode.
	 */
	public static inline function resizeGame(width:Int, height:Int):Void
	{
		scaleMode.onMeasure(width, height);
	}

	/**
	 * Resizes the window. Only works on desktop targets (Windows, Linux, Mac).
	 */
	public static function resizeWindow(width:Int, height:Int):Void
	{
		#if desktop
		Lib.application.window.resize(width, height);
		#end
	}

	/**
	 * Like hitting the reset button on a game console, this will re-launch the game as if it just started.
	 */
	public static inline function resetGame():Void
	{
		game._resetGame = true;
	}

	/**
	 * Attempts to switch from the current game state to `nextState`.
	 * The state switch is successful if `switchTo()` of the current `state` returns `true`.
	 * @param   nextState  A constructor for the initial state, ex: `PlayState.new` or `()->new PlayState()`.
	 *                     Note: Before Flixel 5.6.0, this took a `FlxState` instance,
	 *                     this is still available, for backwards compatibility.
	 */
	public static inline function switchState(nextState:NextState):Void
	{
		final stateOnCall = FlxG.state;
		state.startOutro(function()
		{
			if (FlxG.state == stateOnCall)
				game._nextState = nextState;
			else
				FlxG.log.warn("`onOutroComplete` was called after the state was switched. This will be ignored");
		});
	}

	/**
	 * Request a reset of the current game state.
	 * Calls `switchState()` with a new instance of the current `state`.
	 */
	public static inline function resetState():Void
	{
		switchState(state._constructor);
	}

	/**
	 * Call this function to see if one `FlxObject` overlaps another within `FlxG.worldBounds`.
	 * Can be called with one object and one group, or two groups, or two objects,
	 * whatever floats your boat! For maximum performance try bundling a lot of objects
	 * together using a `FlxGroup` (or even bundling groups together!).
	 *
	 * NOTE: does NOT take objects' `scrollFactor` into account, all overlaps are checked in world space.
	 *
	 * NOTE: this takes the entire area of `FlxTilemap`s into account (including "empty" tiles).
	 * Use `FlxTilemap#overlaps()` if you don't want that.
	 *
	 * @param   objectOrGroup1   The first object or group you want to check.
	 * @param   objectOrGroup2   The second object or group you want to check. If it is the same as the first,
	 *                           Flixel knows to just do a comparison within that group.
	 * @param   notifyCallback   A function with two `FlxObject` parameters -
	 *                           e.g. `onOverlap(object1:FlxObject, object2:FlxObject)` -
	 *                           that is called if those two objects overlap.
	 * @param   processCallback  A function with two `FlxObject` parameters -
	 *                           e.g. `onOverlap(object1:FlxObject, object2:FlxObject)` -
	 *                           that is called if those two objects overlap.
	 *                           If a `ProcessCallback` is provided, then `NotifyCallback`
	 *                           will only be called if `ProcessCallback` returns true for those objects!
	 * @return  Whether any overlaps were detected.
	 */
	public static function overlap(?objectOrGroup1:FlxBasic, ?objectOrGroup2:FlxBasic, ?notifyCallback:Dynamic->Dynamic->Void,
			?processCallback:Dynamic->Dynamic->Bool):Bool
	{
		if (objectOrGroup1 == null)
			objectOrGroup1 = state;
		if (objectOrGroup2 == objectOrGroup1)
			objectOrGroup2 = null;

		FlxQuadTree.divisions = worldDivisions;
		final quadTree = FlxQuadTree.recycle(worldBounds.x, worldBounds.y, worldBounds.width, worldBounds.height);
		quadTree.load(objectOrGroup1, objectOrGroup2, notifyCallback, processCallback);
		final result:Bool = quadTree.execute();
		quadTree.destroy();
		return result;
	}

	/**
	 * A pixel perfect collision check between two `FlxSprite` objects.
	 * It will do a bounds check first, and if that passes it will run a
	 * pixel perfect match on the intersecting area. Works with rotated and animated sprites.
	 * May be slow, so use it sparingly.
	 *
	 * @param   sprite1         The first `FlxSprite` to test against.
	 * @param   sprite2         The second `FlxSprite` to test again, sprite order is irrelevant.
	 * @param   alphaTolerance  The tolerance value above which alpha pixels are included.
	 *                          Default to `255` (must be fully opaque for collision).
	 * @param   camera          If the collision is taking place in a camera other than
	 *                          `FlxG.camera` (the default/current) then pass it here.
	 * @return  Whether the sprites collide
	 */
	public static inline function pixelPerfectOverlap(sprite1:FlxSprite, sprite2:FlxSprite, alphaTolerance = 255, ?camera:FlxCamera):Bool
	{
		return FlxCollision.pixelPerfectCheck(sprite1, sprite2, alphaTolerance, camera);
	}

	/**
	 * Call this function to see if one `FlxObject` collides with another within `FlxG.worldBounds`.
	 * Can be called with one object and one group, or two groups, or two objects,
	 * whatever floats your boat! For maximum performance try bundling a lot of objects
	 * together using a FlxGroup (or even bundling groups together!).
	 *
	 * This function just calls `FlxG.overlap` and presets the `ProcessCallback` parameter to `FlxObject.separate`.
	 * To create your own collision logic, write your own `ProcessCallback` and use `FlxG.overlap` to set it up.
	 * NOTE: does NOT take objects' `scrollFactor` into account, all overlaps are checked in world space.
	 *
	 * @param   objectOrGroup1  The first object or group you want to check.
	 * @param   objectOrGroup2  The second object or group you want to check. If it is the same as the first,
	 *                          Flixel knows to just do a comparison within that group.
	 * @param   notifyCallback  A function with two `FlxObject` parameters -
	 *                          e.g. `onOverlap(object1:FlxObject, object2:FlxObject)` -
	 *                          that is called if those two objects overlap.
	 * @return  Whether any objects were successfully collided/separated.
	 */
	public static inline function collide(?objectOrGroup1:FlxBasic, ?objectOrGroup2:FlxBasic, ?notifyCallback:Dynamic->Dynamic->Void):Bool
	{
		return overlap(objectOrGroup1, objectOrGroup2, notifyCallback, FlxObject.separate);
	}

	/**
 	 * Centers `FlxSprite` by graphic size in game space, either by the x axis, y axis, or both.
 	 *
 	 * @param   sprite       The sprite to center.
 	 * @param   axes         On what axes to center the sprite (e.g. `X`, `Y`, `XY`) - default is both.
 	 * @return  Centered sprite for chaining.
 	 * @since 6.2.0
 	 */
	public static function centerGraphic<T:FlxSprite>(sprite:T, axes:FlxAxes = XY):T
	{
		final graphicBounds = sprite.getAccurateScreenBounds();

		if (axes.x)
		{
			final offset = sprite.x - graphicBounds.x;
			sprite.x = (FlxG.width - graphicBounds.width) * .5 + offset;
		}

		if (axes.y)
		{
			final offset = sprite.y - graphicBounds.y;
			sprite.y = (FlxG.height - graphicBounds.height) * .5 + offset;
		}

		graphicBounds.put();
		return sprite;
	}

	/**
	 * Centers `FlxObject` by hitbox size in game space, either by the x axis, y axis, or both.
	 *
	 * @param   sprite  The object to center.
	 * @param   axes    On what axes to center the object (e.g. `X`, `Y`, `XY`) - default is both.
	 * @return  Centered object for chaining.
	 * @since 6.2.0
	 */
	public static function centerHitbox<T:FlxObject>(object:T, axes:FlxAxes = XY):T
	{
		if (axes.x)
			object.x = (FlxG.width - object.width) * .5;

		if (axes.y)
			object.y = (FlxG.height - object.height) * .5;

		return object;
	}

	/**
	 * Regular `DisplayObject`s are normally displayed over the Flixel cursor and the Flixel debugger if simply
	 * added to `stage`. This function simplifies things by adding a `DisplayObject` directly below mouse level.
	 *
	 * @param   child          The `DisplayObject` to add
	 * @param   indexModifier  Amount to add to the index - makes sure the index stays within bounds.
	 * @return  The added `DisplayObject`
	 */
	public static function addChildBelowMouse<T:DisplayObject>(child:T, indexModifier = 0):T
	{
		var index = game.getChildIndex(game._inputContainer);
		var max = game.numChildren;

		index = FlxMath.maxAdd(index, indexModifier, max);
		game.addChildAt(child, index);
		return child;
	}

	/**
	 * Removes a child from the Flixel display list, if it is part of it.
	 *
	 * @param   child   The `DisplayObject` to add
	 * @return  The removed `DisplayObject`
	 */
	public static inline function removeChild<T:DisplayObject>(child:T):T
	{
		if (game.contains(child))
			game.removeChild(child);
		return child;
	}

	/**
	 * Runs platform-specific code to open a URL in a web browser.
	 * @param url The URL to open.
	 */
	public static function openURL(url:String, target = "_blank"):Void {
		// Ensure you can't open protocols such as steam://, file://, etc
		final protocol = url.split("://");
		if (protocol.length == 1)
			url = 'https://${url}';
		else if (protocol[0] != 'http' && protocol[0] != 'https')
			throw "openURL can only open http and https links.";

		url = FlxStringUtil.sanitizeURL(url);
		if (FlxStringUtil.isNullOrEmpty(url)) throw 'Invalid URL: "$url"';

		// This should work on Windows and HTML5.
		openURLBase(url, target);
	}

	/**
	 * Opens a web page, by default a new tab or window. If the URL does not
	 * already start with `"http://"` or `"https://"`, it gets added automatically.
	 *
	 * @param   url     The address of the web page.
	 * @param   target  `"_blank"`, `"_self"`, `"_parent"` or `"_top"`
	 */
	public static inline function openURLBase(url:String, target = "_blank"):Void
	{
		// Ensure you can't open protocols such as steam://, file://, etc
		final protocol = url.split("://");
		if (protocol.length == 1)
			url = 'https://${url}';
		else if (protocol[0] != 'http' && protocol[0] != 'https')
			throw "openURL can only open http and https links.";

		Lib.getURL(new URLRequest(url), target);
	}

	/**
	 * Called by `FlxGame` to set up `FlxG` during `FlxGame`'s constructor.
	 */
	@:allow(flixel.FlxGame.new)
	@:haxe.warning("-WDeprecated")
	static function init(game:FlxGame, width:Int, height:Int):Void
	{
		if (width < 0)
			width = -width;
		if (height < 0)
			height = -height;

		FlxG.game = game;
		FlxG.width = width;
		FlxG.height = height;

		render.init();

		FlxG.initialWidth = width;
		FlxG.initialHeight = height;

		resizeGame(stage.stageWidth, stage.stageHeight);

		// Instantiate inputs
		#if FLX_KEYBOARD
		keys = inputs.addInput(new FlxKeyboard());
		#end

		#if FLX_MOUSE
		mouse = inputs.addInput(new FlxMouse(game._inputContainer));
		#end

		#if FLX_TOUCH
		touches = inputs.addInput(new FlxTouchManager());
		#end

		#if FLX_GAMEPAD
		gamepads = inputs.addInput(new FlxGamepadManager());
		#end

		#if android
		android = inputs.addInput(new FlxAndroidKeys());
		#end

		#if FLX_ACCELEROMETER
		accelerometer = new FlxAccelerometer();
		#end

		#if FLX_GYROSCOPE
		gyroscope = new FlxGyroscope();
		#end

		#if FLX_SAVE
		initSave();
		#end

		plugins = new PluginFrontEnd();
		vcr = new VCRFrontEnd();

		#if FLX_SOUND_SYSTEM
		sound = new SoundFrontEnd();
		#end
	}

	#if FLX_SAVE
	static function initSave()
	{
		// Don't init if the FlxG.save.bind was manually called before the FlxGame was created
		if (save.isBound)
			return;

		// Use Project.xml data to determine save id (since 5.0.0).
		final name = stage.application.meta["file"];
		save.bind(FlxSave.validate(name));
		// look for the pre 5.0 save and convert it if it exists.
		if (save.isEmpty())
			save.mergeDataFrom("flixel", null, false, false);
	}
	#end

	/**
	 * Called whenever the game is reset, doesn't have to do quite as much work as the basic initialization stuff.
	 */
	@:allow(flixel.FlxGame)
	static function reset():Void
	{
		random.resetInitialSeed();

		bitmap.reset();
		inputs.reset();
		#if FLX_SOUND_SYSTEM
		sound.destroy(true);
		#end
		autoPause = true;
		fixedTimestep = true;
		timeScale = 1.0;
		animationTimeScale = 1.0;
		elapsed = 0;
		maxElapsed = 0.1;
		worldBounds.set(-10, -10, width + 20, height + 20);
		worldDivisions = 6;
	}

	static function set_scaleMode(value:BaseScaleMode):BaseScaleMode
	{
		scaleMode = value;
		game.onResize(null);
		return value;
	}

	#if FLX_MOUSE
	static function set_mouse(newMouse:FlxMouse):FlxMouse
	{
		if (mouse == null) // if no mouse, just add it
		{
			mouse = inputs.addUniqueType(newMouse);
			return mouse;
		}

		// replace existing mouse
		final oldMouse:FlxMouse = mouse;
		final result:FlxMouse = inputs.replace(oldMouse, newMouse, true);
		if (result != null)
		{
			mouse = result;
			return newMouse;
		}

		return oldMouse;
	}
	#end

	static function set_updateFramerate(value:Int):Int
	{
		if (value < drawFramerate)
			log.warn("FlxG.framerate: the game's framerate shouldn't be smaller than the framerate," + " since it can stop your game from updating.");

		updateFramerate = value;

		game._stepMS = Math.abs(1000 / value);
		game._stepSeconds = game._stepMS * .001;

		if (game._maxAccumulation < game._stepMS)
			game._maxAccumulation = game._stepMS;

		return value;
	}

	static function set_drawFramerate(value:Int):Int
	{
		if (value > updateFramerate)
			log.warn("FlxG.drawFramerate: the update framerate shouldn't be smaller than the draw framerate," + " since it can stop your game from updating.");

		drawFramerate = Std.int(Math.abs(value));

		fixedDelta = FlxMath.roundDecimal(1 / drawFramerate, 6);

		if (game.stage != null)
			game.stage.frameRate = drawFramerate;

		game._maxAccumulation = 2000 / drawFramerate - 1;

		if (game._maxAccumulation < game._stepMS)
			game._maxAccumulation = game._stepMS;

		return value;
	}

	static function get_fullscreen():Bool
	{
		return stage.displayState == StageDisplayState.FULL_SCREEN || stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE;
	}

	static function set_fullscreen(value:Bool):Bool
	{
		stage.displayState = value ? StageDisplayState.FULL_SCREEN : StageDisplayState.NORMAL;
		return value;
	}

	static inline function get_stage():Stage
	{
		return Lib.current.stage;
	}

	static inline function get_state():FlxState
	{
		return game._state;
	}

	static inline function get_onMobile():Bool
	{
		return #if js
			html5.onMobile
		#elseif mobile
			true
		#else
			false
		#end;
	}
}