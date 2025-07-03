package flixel.input.actions;

import flixel.input.FlxInput.FlxInputState;
import flixel.input.actions.FlxAction.FlxActionAnalog;
import flixel.input.actions.FlxAction.FlxActionDigital;
import flixel.input.actions.FlxActionInput.FlxInputDevice;
import flixel.input.actions.FlxActionInput.FlxInputType;
import flixel.input.actions.FlxActionInputAnalog.FlxActionInputAnalogSteam;
import flixel.input.actions.FlxActionInputAnalog.FlxAnalogState;
import flixel.input.actions.FlxActionInputAnalog.FlxAnalogAxis;
import flixel.input.actions.FlxActionInputDigital.FlxActionInputDigitalSteam;
import flixel.input.actions.FlxActionManager.ActionSetJson;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import haxe.Json;
#if FLX_STEAMWRAP
import steamwrap.data.ControllerConfig.ControllerActionSet;
#end

using flixel.util.FlxArrayUtil;

/**
 * @since 4.6.0
 */
@:allow(flixel.input.actions.FlxActionManager)
class FlxActionSet implements IFlxDestroyable {
	/**
	 * Name of the action set
	 */
	public var name(default, null) = "";

	#if FLX_STEAMWRAP
	/**
	 * This action set's numeric handle for the Steam API (ignored if not using Steam)
	 */
	public var steamHandle(default, null) = -1;
	#end

	/**
	 * Digital actions in this set
	 */
	public var digitalActions(default, null):Array<FlxActionDigital>;

	/**
	 * Analog actions in this set
	 */
	public var analogActions(default, null):Array<FlxActionAnalog>;

	/**
	 * Whether this action set runs when update() is called
	 */
	public var active = true;

	#if FLX_STEAMWRAP
	/**
	 * Create an action set from a steamwrap configuration file.
	 *
	 * NOTE: no steam inputs will be attached to the created actions; you must call
	 * attachSteamController() which will automatically add or remove steam
	 * inputs for a particular controller.
	 *
	 * This is unique to steam inputs, which cannot be constructed directly.
	 * Non-steam inputs can be constructed and added to the actions normally.
	 *
	 * @param	steamSet	A steamwrap ControllerActionSet file (found in ControllerConfig)
	 * @param	callbackDigital	A function to call when digital actions fire
	 * @param	callbackAnalog	A function to call when analog actions fire
	 * @return	An action set
	 */
	@:access(flixel.input.actions.FlxActionManager)
	static function fromSteam(steamSet:ControllerActionSet, callbackDigital:FlxActionDigital -> Void, callbackAnalog:FlxActionAnalog -> Void):FlxActionSet {
		if (steamSet == null) return null;

		final digitalActions:Array<FlxActionDigital> = [];
		final analogActions:Array<FlxActionAnalog> = [];

		if (steamSet.button != null)
			for (b in steamSet.button) {
				if (b == null) continue;

				final action = new FlxActionDigital(b.name, callbackDigital);
				final aHandle = FlxSteamController.getDigitalActionHandle(b.name);
				action.steamHandle = aHandle;
				digitalActions.push(action);
			}

		if (steamSet.analogTrigger != null)
			for (a in steamSet.analogTrigger) {
				if (a == null) continue;

				final action = new FlxActionAnalog(a.name, callbackAnalog);
				final aHandle = FlxSteamController.getAnalogActionHandle(a.name);
				action.steamHandle = aHandle;
				analogActions.push(action);
			}

		for (s in steamSet.stickPadGyro) {
			if (s == null) continue;

			final action = new FlxActionAnalog(s.name, callbackAnalog);
			final aHandle = FlxSteamController.getAnalogActionHandle(s.name);
			action.steamHandle = aHandle;
			analogActions.push(action);
		}

		final set = new FlxActionSet(steamSet.name, digitalActions, analogActions);
		set.steamHandle = FlxSteamController.getActionSetHandle(steamSet.name);

		return set;
	}
	#end

	/**
	 * Create an action set from a parsed Json object
	 *
	 * @param	data	A parsed Json object
	 * @param	callbackDigital	A function to call when digital actions fire
	 * @param	callbackAnalog	A function to call when analog actions fire
	 * @return	An action set
	 */
	@:access(flixel.input.actions.FlxActionManager)
	static function fromJson(data:ActionSetJson, callbackDigital:FlxActionDigital -> Void, callbackAnalog:FlxActionAnalog -> Void):FlxActionSet {
		final digitalActions:Array<FlxActionDigital> = [];
		final analogActions:Array<FlxActionAnalog> = [];

		if (data == null) return null;

		if (data.digitalActions != null) {
			final arrD:Array<Dynamic> = data.digitalActions;
			for (d in arrD) {
				final dName:String = cast d;
				final action = new FlxActionDigital(dName, callbackDigital);
				digitalActions.push(action);
			}
		}

		if (data.analogActions != null) {
			final arrA:Array<Dynamic> = data.analogActions;
			for (a in arrA) {
				final aName:String = cast a;
				final action = new FlxActionAnalog(aName, callbackAnalog);
				analogActions.push(action);
			}
		}

		if (data.name != null) {
			final name:String = data.name;
			final set = new FlxActionSet(name, digitalActions, analogActions);
			return set;
		}

		return null;
	}

	public function toJson():String {
		final space = "\t";
		return Json.stringify(this, function(key:Dynamic, value:Dynamic):Dynamic {
			if ((value is FlxAction)) {
				final fa:FlxAction = cast value;
				return {
					"type": fa.type,
					"name": fa.name,
					"steamHandle": fa.steamHandle
				}
			}
			return value;
		}, space);
	}

	public function new(name:String, ?digitalActions:Array<FlxActionDigital>, ?analogActions:Array<FlxActionAnalog>) {
		this.name = name;

		digitalActions ??= [];
		analogActions ??= [];
		this.digitalActions = digitalActions;
		this.analogActions = analogActions;
	}

	/**
	 * Automatically adds or removes inputs for a steam controller
	 * to any steam-affiliated actions
	 * @param	handle	steam controller handle from FlxSteam.getConnectedControllers(), or FlxInputDeviceID.FIRST_ACTIVE / ALL
	 * @param	attach	true: adds inputs, false: removes inputs
	 */
	public function attachSteamController(handle:Int, attach = true):Void {
		attachSteamControllerSub(handle, attach, FlxInputType.DIGITAL, digitalActions, null);
		attachSteamControllerSub(handle, attach, FlxInputType.ANALOG, null, analogActions);
	}

	public function add(Action:FlxAction):Bool {
		if (Action.type == DIGITAL) {
			final dAction:FlxActionDigital = cast Action;
			if (digitalActions.contains(dAction)) return false;
			digitalActions.push(dAction);
			return true;
		} else if (Action.type == ANALOG) {
			final aAction:FlxActionAnalog = cast Action;
			if (analogActions.contains(aAction)) return false;
			analogActions.push(aAction);
			return true;
		}
		return false;
	}

	public function destroy():Void {
		digitalActions = FlxDestroyUtil.destroyArray(digitalActions);
		analogActions = FlxDestroyUtil.destroyArray(analogActions);
	}

	/**
	 * Remove an action from this set
	 * @param	action a FlxAction
	 * @param	destroy whether to destroy it as well
	 * @return	whether it was found and removed
	 */
	public function remove(action:FlxAction, destroy = true):Bool {
		var result = false;
		if (action.type == DIGITAL) {
			result = digitalActions.remove(cast action);
			if (result && destroy) action.destroy();
		} else if (action.type == ANALOG) {
			result = analogActions.remove(cast action);
			if (result && destroy) action.destroy();
		}

		return result;
	}

	/**
	 * Update all the actions in this set (each will check inputs & potentially trigger)
	 */
	public function update():Void {
		if (!active) return;

		for (digitalAction in digitalActions)
			digitalAction.update();

		for (analogAction in analogActions)
			analogAction.update();
	}

	private function attachSteamControllerSub(handle:Int, attach:Bool, inputType:FlxInputType, digitalActions:Array<FlxActionDigital>, analogActions:Array<FlxActionAnalog>) {
		final length = inputType == FlxInputType.DIGITAL ? digitalActions.length : analogActions.length;

		for (i in 0...length) {
			final action = inputType == FlxInputType.DIGITAL ? digitalActions[i] : analogActions[i];

			if (action.steamHandle != -1) { // all steam-affiliated actions will have this numeric ID assigned
				var inputExists = false;
				var theInput:FlxActionInput = null;

				// check if any of the steam controller inputs match this handle
				if (action.inputs != null)
					for (input in action.inputs)
						if (input.device == FlxInputDevice.STEAM_CONTROLLER && input.deviceID == handle) {
							inputExists = true;
							theInput = input;
						}

				if (attach) {
					// attaching: add inputs for this controller if they don't exist

					if (!inputExists) {
						if (inputType == FlxInputType.DIGITAL)
							digitalActions[i].add(new FlxActionInputDigitalSteam(action.steamHandle, FlxInputState.JUST_PRESSED, handle));
						else if (inputType == FlxInputType.ANALOG)
							analogActions[i].add(new FlxActionInputAnalogSteam(action.steamHandle, FlxAnalogState.MOVED, FlxAnalogAxis.EITHER, handle));
					}
				} else if (inputExists)
					// detaching: remove inputs for this controller if they exist
					action.remove(theInput);
			}
		}
	}
}
