package flixel.input.actions;

import flixel.input.FlxInput.FlxInputState;
import flixel.input.IFlxInput;
import flixel.input.actions.FlxActionInput.FlxInputDeviceID;
import flixel.input.actions.FlxActionInput.FlxInputType;
import flixel.input.actions.FlxActionInputAnalog.FlxAnalogAxis;
import flixel.input.actions.FlxActionInputAnalog.FlxAnalogState;
import flixel.input.actions.FlxActionInputAnalog.FlxActionInputAnalogClickAndDragMouseMotion;
import flixel.input.actions.FlxActionInputAnalog.FlxActionInputAnalogGamepad;
import flixel.input.actions.FlxActionInputAnalog.FlxActionInputAnalogMouseMotion;
import flixel.input.actions.FlxActionInputAnalog.FlxActionInputAnalogMousePosition;
import flixel.input.actions.FlxActionInputDigital.FlxActionInputDigitalIFlxInput;
import flixel.input.actions.FlxActionInputDigital.FlxActionInputDigitalGamepad;
import flixel.input.actions.FlxActionInputDigital.FlxActionInputDigitalKeyboard;
import flixel.input.actions.FlxActionInputDigital.FlxActionInputDigitalMouse;
import flixel.input.actions.FlxActionInputDigital.FlxActionInputDigitalMouseWheel;
#if android
import flixel.input.actions.FlxActionInputDigital.FlxActionInputDigitalAndroid;
#end
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseButton.FlxMouseButtonID;
import flixel.input.android.FlxAndroidKey;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
#if FLX_STEAMWRAP
import steamwrap.api.Controller.EControllerActionOrigin;
#end

using flixel.util.FlxArrayUtil;

/**
 * A digital action is a binary on/off event like "jump" or "fire".
 * FlxActions let you attach multiple inputs to a single in-game action,
 * so "jump" could be performed by a keyboard press, a mouse click,
 * or a gamepad button press.
 *
 * @since 4.6.0
 */
class FlxActionDigital extends FlxAction {
	/**
	 * Function to call when this action occurs
	 */
	public var callback:FlxActionDigital -> Void;

	/**
	 * Create a new digital action
	 * @param	name	name of the action
	 * @param	callback	function to call when this action occurs
	 */
	public function new(?name = "", ?callback:FlxActionDigital -> Void) {
		super(FlxInputType.DIGITAL, name);
		this.callback = callback;
	}

	/**
	 * Add a digital input (any kind) that will trigger this action
	 * @param	input
	 * @return	This action
	 */
	public function add(input:FlxActionInputDigital):FlxActionDigital {
		addGenericInput(input);
		return this;
	}

	/**
	 * Add a generic IFlxInput action input
	 *
	 * WARNING: IFlxInput objects are often member variables of some other
	 * object that is often destructed at the end of a state. If you don't
	 * destroy() this input (or the action you assign it to), the IFlxInput
	 * reference will persist forever even after its parent object has been
	 * destroyed!
	 *
	 * @param	input	A generic IFlxInput object (ex: FlxButton.input)
	 * @param	trigger	trigger What state triggers this action (PRESSED, JUST_PRESSED, RELEASED, JUST_RELEASED)
	 * @return	This action
	 */
	public function addInput(input:IFlxInput, trigger:FlxInputState):FlxActionDigital {
		return add(new FlxActionInputDigitalIFlxInput(input, trigger));
	}

	/**
	 * Add a gamepad action input for digital (button-like) events
	 * @param	inputID "universal" gamepad input ID (A, X, DPAD_LEFT, etc)
	 * @param	trigger What state triggers this action (PRESSED, JUST_PRESSED, RELEASED, JUST_RELEASED)
	 * @param	gamepadID specific gamepad ID, or FlxInputDeviceID.ALL / FIRST_ACTIVE
	 * @return	This action
	 */
	public function addGamepad(inputID:FlxGamepadInputID, trigger:FlxInputState, gamepadID:Int = FlxInputDeviceID.FIRST_ACTIVE):FlxActionDigital {
		return add(new FlxActionInputDigitalGamepad(inputID, trigger, gamepadID));
	}

	/**
	 * Add a keyboard action input
	 * @param	key key identifier (FlxKey.SPACE, FlxKey.Z, etc)
	 * @param	trigger What state triggers this action (PRESSED, JUST_PRESSED, RELEASED, JUST_RELEASED)
	 * @return	This action
	 */
	public function addKey(key:FlxKey, trigger:FlxInputState):FlxActionDigital {
		return add(new FlxActionInputDigitalKeyboard(key, trigger));
	}

	/**
	 * Mouse button action input
	 * @param	buttonID Button identifier (FlxMouseButtonID.LEFT / MIDDLE / RIGHT)
	 * @param	trigger What state triggers this action (PRESSED, JUST_PRESSED, RELEASED, JUST_RELEASED)
	 * @return	This action
	 */
	public function addMouse(buttonID:FlxMouseButtonID, trigger:FlxInputState):FlxActionDigital {
		return add(new FlxActionInputDigitalMouse(buttonID, trigger));
	}

	/**
	 * Action for mouse wheel events
	 * @param	positive	True: respond to mouse wheel values > 0; False: respond to mouse wheel values < 0
	 * @param	trigger		What state triggers this action (PRESSED, JUST_PRESSED, RELEASED, JUST_RELEASED)
	 * @return	This action
	 */
	public function addMouseWheel(positive:Bool, trigger:FlxInputState):FlxActionDigital {
		return add(new FlxActionInputDigitalMouseWheel(positive, trigger));
	}

	#if android
	/**
	 * Android buttons action inputs
	 * @param	key	Android button key, BACK, or MENU probably (might need to set FlxG.android.preventDefaultKeys to disable the default behaviour and allow proper use!)
	 * @param	trigger		What state triggers this action (PRESSED, JUST_PRESSED, RELEASED, JUST_RELEASED)
	 * @return	This action
	 *
	 * @since 4.10.0
	 */
	public function addAndroidKey(key:FlxAndroidKey, trigger:FlxInputState):FlxActionDigital {
		return add(new FlxActionInputDigitalAndroid(key, trigger));
	}
	#end

	override public function destroy():Void {
		callback = null;
		super.destroy();
	}

	override public function check():Bool {
		final val = super.check();
		if (val && callback != null) callback(this);

		return val;
	}
}

/**
 * Analog actions are events with continuous (floating-point) values, and up
 * to two axes (x,y). This is for events like "move" and "accelerate" where the
 * event is not simply on or off.
 *
 * FlxActions let you attach multiple inputs to a single in-game action,
 * so "move" could be performed by a gamepad joystick, a mouse movement, etc.
 *
 * @since 4.6.0
 */
class FlxActionAnalog extends FlxAction {
	/**
	 * Function to call when this action occurs
	 */
	public var callback:FlxActionAnalog -> Void;

	/**
	 * X axis value, or the value of a single-axis analog input.
	 */
	public var x(get, never):Float;

	/**
	 * Y axis value. (If action only has single-axis input this is always == 0)
	 */
	public var y(get, never):Float;

	/**
	 * Create a new analog action
	 * @param	name	name of the action
	 * @param	callback	function to call when this action occurs
	 */
	public function new(?name = "", ?callback:FlxActionAnalog -> Void) {
		super(FlxInputType.ANALOG, name);
		this.callback = callback;
	}

	/**
	 * Add an analog input that will trigger this action
	 */
	public function add(input:FlxActionInputAnalog):FlxActionAnalog {
		addGenericInput(input);
		return this;
	}

	/**
	 * Add mouse input -- same as mouse motion, but requires a particular mouse button to be PRESSED
	 * Very useful for e.g. panning a map or canvas around
	 * @param	buttonID	Button identifier (FlxMouseButtonID.LEFT / MIDDLE / RIGHT)
	 * @param	trigger	What state triggers this action (MOVED, JUST_MOVED, STOPPED, JUST_STOPPED)
	 * @param	axis	which axes to monitor for triggering: X, Y, EITHER, or BOTH
	 * @param	pixelsPerUnit	How many pixels of movement = 1.0 in analog motion (lower: more sensitive, higher: less sensitive)
	 * @param	deadZone	Minimum analog value before motion will be reported
	 * @param	invertY	Invert the Y axis
	 * @param	invertX	Invert the X axis
	 * @return	This action
	 */
	public function addMouseClickAndDragMotion(buttonID:FlxMouseButtonID, trigger:FlxAnalogState, axis = FlxAnalogAxis.EITHER, pixelsPerUnit = 10, deadZone = .1, invertY = false, invertX = false):FlxActionAnalog {
		return add(new FlxActionInputAnalogClickAndDragMouseMotion(buttonID, trigger, axis, pixelsPerUnit, deadZone, invertY, invertX));
	}

	/**
	 * Add mouse input -- X/Y is the RELATIVE motion of the mouse since the last frame
	 * @param	trigger	What state triggers this action (MOVED, JUST_MOVED, STOPPED, JUST_STOPPED)
	 * @param	axis	which axes to monitor for triggering: X, Y, EITHER, or BOTH
	 * @param	pixelsPerUnit	How many pixels of movement = 1.0 in analog motion (lower: more sensitive, higher: less sensitive)
	 * @param	deadZone	Minimum analog value before motion will be reported
	 * @param	invertY	Invert the Y axis
	 * @param	invertX	Invert the X axis
	 * @return	This action
	 */
	public function addMouseMotion(trigger:FlxAnalogState, axis:FlxAnalogAxis = EITHER, pixelsPerUnit = 10, deadZone = .1, invertY = false, invertX = false):FlxActionAnalog {
		return add(new FlxActionInputAnalogMouseMotion(trigger, axis, pixelsPerUnit, deadZone, invertY, invertX));
	}

	/**
	 * Add mouse input -- X/Y is the mouse's absolute screen position
	 * @param	trigger What state triggers this action (MOVED, JUST_MOVED, STOPPED, JUST_STOPPED)
	 * @param	axis which axes to monitor for triggering: X, Y, EITHER, or BOTH
	 * @return	This action
	 */
	public function addMousePosition(trigger:FlxAnalogState, axis:FlxAnalogAxis = EITHER):FlxActionAnalog {
		return add(new FlxActionInputAnalogMousePosition(trigger, axis));
	}

	/**
	 * Add gamepad action input for analog (trigger, joystick, touchpad, etc) events
	 * @param	inputID "universal" gamepad input ID (LEFT_TRIGGER, RIGHT_ANALOG_STICK, TILT_PITCH, etc)
	 * @param	trigger What state triggers this action (MOVED, JUST_MOVED, STOPPED, JUST_STOPPED)
	 * @param	axis which axes to monitor for triggering: X, Y, EITHER, or BOTH
	 * @param	gamepadID specific gamepad ID, or FlxInputDeviceID.FIRST_ACTIVE / ALL
	 * @return	This action
	 */
	public function addGamepad(inputID:FlxGamepadInputID, trigger:FlxAnalogState, axis:FlxAnalogAxis = EITHER, gamepadID:Int = FlxInputDeviceID.FIRST_ACTIVE):FlxActionAnalog {
		return add(new FlxActionInputAnalogGamepad(inputID, trigger, axis, gamepadID));
	}

	override public function update():Void {
		_x = null;
		_y = null;
		super.update();
	}

	override public function destroy():Void {
		callback = null;
		super.destroy();
	}

	override public function toString():String {
		return "FlxAction(" + type + ") name:" + name + " x/y:" + _x + "," + _y;
	}

	override public function check():Bool {
		final val = super.check();
		if (val && callback != null) callback(this);

		return val;
	}

	private function get_x():Float {
		return (_x != null) ? _x : 0;
	}

	private function get_y():Float {
		return (_y != null) ? _y : 0;
	}
}

/**
 * @since 4.6.0
 */
@:allow(flixel.input.actions.FlxActionDigital, flixel.input.actions.FlxActionAnalog, flixel.input.actions.FlxActionSet)
class FlxAction implements IFlxDestroyable
{
	/**
	 * Digital or Analog
	 */
	public var type(default, null):FlxInputType;

	/**
	 * The name of the action, "jump", "fire", "move", etc.
	 */
	public var name(default, null):String;

	/**
	 * This action's numeric handle for the Steam API (ignored if not using Steam)
	 */
	var steamHandle(default, null) = -1;

	/**
	 * If true, this action has just been triggered
	 */
	public var triggered(default, null) = false;

	/**
	 * The inputs attached to this action
	 */
	public var inputs:Array<FlxActionInput>;

	var _x:Null<Float> = null;
	var _y:Null<Float> = null;

	var _timestamp = .0;

	/**
	 * Whether the steam controller inputs for this action have changed since the last time origins were polled. Always false if steam isn't active
	 */
	public var steamOriginsChanged(default, null) = false;

	#if FLX_STEAMWRAP
	var _steamOriginsChecksum = 0;
	var _steamOrigins:Array<EControllerActionOrigin>;
	#end

	private function new(inputType:FlxInputType, name:String) {
		type = inputType;
		this.name = name;
		inputs = [];

		#if FLX_STEAMWRAP
		_steamOrigins = [];
		for (i in 0...FlxSteamController.MAX_ORIGINS) _steamOrigins.push(cast 0);
		#end
	}

	public function getFirstSteamOrigin():Int {
		#if FLX_STEAMWRAP
		if (_steamOrigins == null) return 0;

		for (i in 0..._steamOrigins.length)
			if (_steamOrigins[i] != EControllerActionOrigin.NONE)
				return cast _steamOrigins[i];
		#end
		return 0;
	}

	public function getSteamOrigins(?origins:Array<Int>):Array<Int> {
		#if FLX_STEAMWRAP
		origins ??= [];

		if (_steamOrigins != null)
			for (i in 0..._steamOrigins.length)
				origins[i] = cast _steamOrigins[i];
		#end
		return origins;
	}

	public function removeAll(destroy = true):Void {
		final len = inputs.length;
		for (i in 0...len) {
			final input = inputs[j];
			remove(input, destroy);
		}
		inputs.resize(0);
	}

	public function remove(input:FlxActionInput, destroy = false):Void {
		if (input == null) return;

		inputs.remove(input);
		if (destroy) input.destroy();
	}

	public function toString():String {
		return "FlxAction(" + type + ") name:" + name;
	}

	/**
	 * See if this action has just been triggered
	 */
	public function check():Bool {
		if (_timestamp == FlxG.game.ticks) return triggered; // run no more than once per frame

		_x = null;
		_y = null;

		_timestamp = FlxG.game.ticks;
		triggered = false;

		var i = inputs != null ? inputs.length : 0;
		while (i-- > 0)  { // Iterate backwards, since we may remove items
			final input = inputs[i];

			if (input.destroyed) {
				inputs.remove(input);
				continue;
			}

			input.update();

			if (input.check(this)) triggered = true;
		}

		return triggered;
	}

	/**
	 * Check input states & fire callbacks if anything is triggered
	 */
	public function update():Void {
		check();
	}

	public function destroy():Void {
		FlxDestroyUtil.destroyArray(inputs);
		inputs = null;
		#if FLX_STEAMWRAP
		FlxArrayUtil.clearArray(_steamOrigins);
		_steamOrigins = null;
		#end
	}

	public function match(other:FlxAction):Bool {
		return name == other.name && steamHandle == other.steamHandle;
	}

	private function addGenericInput(input:FlxActionInput):FlxAction {
		inputs ??= [];

		if (!checkExists(input)) inputs.push(input);

		return this;
	}

	private function checkExists(input:FlxActionInput):Bool {
		if (inputs == null) return false;
		return inputs.contains(input);
	}
}
