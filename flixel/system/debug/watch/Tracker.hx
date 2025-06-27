package flixel.system.debug.watch;

#if FLX_DEBUG
import openfl.display.DisplayObject;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.effects.particles.FlxEmitter.FlxTypedEmitter;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.mouse.FlxMouse;
import flixel.input.FlxSwipe;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.path.FlxPath;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton.FlxTypedButton;
import flixel.util.FlxTimer;
import flixel.animation.FlxAnimationController;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end
#end
import flixel.util.FlxStringUtil;

class Tracker extends Watch {
	#if FLX_DEBUG
	/**
	 * Order matters here, as the last profile is the most relevant - i.e., if the
	 * FlxSprite profile were added before the one for FlxObject, it would never be selected.
	 */
	public static var profiles:Array<TrackerProfile>;

	/**
	 * Stores a reference to all objects for a which a tracker window exists
	 * to prevent the creation of two windows for the same object.
	 */
	public static final objectsBeingTracked:Array<Dynamic> = [];

	static var _numTrackerWindows = 0;

	public static inline function addProfile(profile:TrackerProfile):Void {
		if (profile == null) return;

		initProfiles();
		profiles.push(profile);
	}

	public static function findProfile(object:Dynamic):TrackerProfile {
		initProfiles();

		var lastMatchingProfile:TrackerProfile = null;
		for (profile in profiles)
			if (Std.isOfType(object, profile.objectClass) || object == profile.objectClass)
				lastMatchingProfile = profile;

		return lastMatchingProfile;
	}

	public static function onStateSwitch():Void {
		_numTrackerWindows = 0;
	}

	static function initProfiles():Void {
		if (profiles != null) return;
		profiles = [];

		addProfile(new TrackerProfile(FlxG, [
			"width", "height", "worldBounds.x", "worldBounds.y", "worldBounds.width", "worldBounds.height", "worldDivisions", "updateFramerate",
			"drawFramerate", "elapsed", "maxElapsed", "autoPause", "fixedTimestep", "timeScale"
		]));

		addProfile(new TrackerProfile(FlxBasePoint, ["x", "y"]));
		addProfile(new TrackerProfile(FlxRect, ["width", "height"], [FlxBasePoint]));

		addProfile(new TrackerProfile(FlxBasic, ["active", "visible", "alive", "exists"]));
		addProfile(new TrackerProfile(FlxObject, ["velocity", "acceleration", "drag", "angle", "immovable"], [FlxRect, FlxBasic]));
		addProfile(new TrackerProfile(FlxTilemap, ["auto", "widthInTiles", "heightInTiles", "totalTiles", "scale"], [FlxObject]));
		addProfile(new TrackerProfile(FlxSprite, ["frameWidth", "frameHeight", "alpha", "origin", "offset", "scale"], [FlxObject]));
		addProfile(new TrackerProfile(FlxTypedButton, ["status", "labelAlphas"], [FlxSprite]));
		addProfile(new TrackerProfile(FlxBar, ["min", "max", "range", "pct", "pxPerPercent", "value"], [FlxSprite]));
		addProfile(new TrackerProfile(FlxText, [
			"text",
			"size",
			"font",
			"embedded",
			"bold",
			"italic",
			"wordWrap",
			"borderSize",
			"borderStyle"
		], [FlxSprite]));

		addProfile(new TrackerProfile(FlxTypedGroup, ["length", "members.length", "maxSize"], [FlxBasic]));
		addProfile(new TrackerProfile(FlxSpriteGroup, null, [FlxSprite, FlxTypedGroup]));
		addProfile(new TrackerProfile(FlxState, ["persistentUpdate", "persistentDraw", "destroySubStates", "bgColor"], [FlxTypedGroup]));

		addProfile(new TrackerProfile(FlxCamera, [
			"style",
			"followLerp",
			"followLead",
			"deadzone",
			"bounds",
			"zoom",
			"alpha",
			"angle"
		], [FlxBasic, FlxRect]));

		addProfile(new TrackerProfile(FlxTween, [
			"active", "duration", "type", "percent", "finished", "scale", "backward", "executions", "startDelay", "loopDelay"
		]));

		addProfile(new TrackerProfile(FlxPath, ["speed", "angle", "autoCenter", "nodeIndex", "active", "finished"]));
		addProfile(new TrackerProfile(FlxTimer, [
			"time",
			"loops",
			"active",
			"finished",
			"timeLeft",
			"elapsedTime",
			"loopsLeft",
			"elapsedLoops",
			"progress"
		]));

		addProfile(new TrackerProfile(FlxAnimationController, ["frameIndex", "frameName", "name", "paused", "finished", "frames"]));

		addProfile(new TrackerProfile(FlxTypedEmitter, ["emitting", "frequency", "bounce"], [FlxTypedGroup, FlxRect]));

		// Inputs
		#if FLX_MOUSE
		addProfile(new TrackerProfile(FlxMouse, [
			"screenX",
			"screenY",
			"wheel",
			"visible",
			"useSystemCursor",
			"pressed",
			"justPressed",
			"justReleased"
			#if FLX_MOUSE_ADVANCED, "pressedMiddle", "justPressedMiddle", "justReleasedMiddle", "pressedRight", "justPressedRight", "justReleasedRight"
			#end
		], [FlxBasePoint]));
		#end
		#if FLX_TOUCH
		addProfile(new TrackerProfile(FlxTouch, [
			"screenX",
			"screenY",
			"touchPointID",
			"pressed",
			"justPressed",
			"justReleased",
			"isActive"
		], [FlxBasePoint]));
		#end
		#if FLX_GAMEPAD
		addProfile(new TrackerProfile(FlxGamepad, ["id", "deadZone", "hat", "ball", "dpadUp", "dpadDown", "dpadLeft", "dpadRight"]));
		#end

		#if FLX_POINTER_INPUT
		addProfile(new TrackerProfile(FlxSwipe, ["ID", "startPosition", "endPosition", "distance", "angle", "duration"]));
		#end

		addProfile(new TrackerProfile(DisplayObject, ["z", "scaleX", "scaleY", "mouseX", "mouseY", "rotationX", "rotationY", "visible"], [FlxRect]));
		addProfile(new TrackerProfile(Point, null, [FlxBasePoint]));
		addProfile(new TrackerProfile(Rectangle, null, [FlxRect]));
		addProfile(new TrackerProfile(Matrix, ["a", "b", "c", "d", "tx", "ty"]));
	}

	var _object:Dynamic;

	public function new(profile:TrackerProfile, objectOrClass:Dynamic, ?windowTitle:String) {
		super(true);

		initProfiles();
		_object = objectOrClass;
		objectsBeingTracked.push(_object);

		initWatchEntries(profile);

		_title.text = (windowTitle == null) ? FlxStringUtil.getClassName(_object, true) : windowTitle;
		visible = true;

		resize(200, entriesContainer.height + 30);

		// Small x and y offset
		x = _numTrackerWindows * 80;
		y = _numTrackerWindows * 25 + 20;
		_numTrackerWindows++;

		FlxG.signals.preStateSwitch.add(close);
	}

	override public function destroy():Void {
		FlxG.signals.preStateSwitch.remove(close);
		_numTrackerWindows--;
		objectsBeingTracked.remove(_object);
		_object = null;
		super.destroy();
	}

	private function findProfileByClass(objectClass:Class<Dynamic>):TrackerProfile {
		for (profile in profiles)
			if (profile.objectClass == objectClass)
				return profile;

		return null;
	}

	private function initWatchEntries(profile:TrackerProfile):Void {
		if (profile == null) return;
		addExtensions(profile);
		addVariables(profile.variables);
	}

	private function addExtensions(profile:TrackerProfile):Void {
		if (profile.extensions == null) return;

		for (extension in profile.extensions) {
			if (extension == null) continue;

			final extensionProfile = findProfileByClass(extension);
			if (extensionProfile != null) {
				addVariables(extensionProfile.variables);
				addExtensions(extensionProfile); // recurse
			}
		}
	}

	private function addVariables(variables:Array<String>):Void {
		if (variables == null) return;

		for (variable in variables)
			add(variable, FIELD(_object, variable));
	}
	#end
}

class TrackerProfile {
	public var objectClass:Class<Dynamic>;
	public var variables:Array<String>;
	public var extensions:Array<Class<Dynamic>>;

	public function new(objectClass:Class<Dynamic>, ?variables:Array<String>, ?extensions:Array<Class<Dynamic>>) {
		this.objectClass = objectClass;
		this.variables = variables;
		this.extensions = extensions;
	}

	public function toString():String {
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("variables", variables),
			LabelValuePair.weak("extensions", extensions)
		]);
	}
}
