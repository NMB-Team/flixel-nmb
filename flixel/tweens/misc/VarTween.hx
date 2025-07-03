package flixel.tweens.misc;

import flixel.tweens.FlxTween;
import flixel.util.typeLimit.OneOfTwo;

using StringTools;

/**
 * Tweens multiple numeric properties of an object simultaneously.
 */
class VarTween extends FlxTween {
	var _object:Dynamic;
	var _properties:Dynamic;
	var _propertyInfos:Array<VarTweenProperty>;

	private function new(options:TweenOptions, ?manager:FlxTweenManager) {
		super(options, manager);
	}

	/**
	 * Tweens multiple numeric public properties.
	 *
	 * @param	object		The object containing the properties.
	 * @param	properties	An object containing key/value pairs of properties and target values.
	 * @param	duration	Duration of the tween.
	 */
	public function tween(object:Dynamic, properties:Dynamic, duration:Float):VarTween {
		#if FLX_DEBUG
		if (object == null)
			FlxG.log.critical("Cannot tween variables of an object that is null.");
		else if (properties == null)
			FlxG.log.critical("Cannot tween null properties.");
		#end

		_object = object;
		_properties = properties;
		_propertyInfos = [];

		this.duration = duration;

		start();
		initializeVars();
		return this;
	}

	override function update(elapsed:Float):Void {
		final delay = (executions > 0) ? loopDelay : startDelay;

		if (_secondsSinceStart >= delay) {
			// Wait until the delay is done to set the starting values of tweens
			if (Math.isNaN(_propertyInfos[0].startValue)) setStartValues();

			super.update(elapsed);

			if (active)
				for (info in _propertyInfos)
					info.setField(info.startValue + info.range * scale);
		} else // Leave properties alone until delay is over
			super.update(elapsed);
	}

	private function initializeVars():Void {
		var fieldPaths:Array<String>;
		if (Reflect.isObject(_properties))
			fieldPaths = Reflect.fields(_properties);
		else
			throw "Unsupported properties container - use an object containing key/value pairs.";

		for (fieldPath in fieldPaths) {
			var target:Dynamic = _object;
			final path = FlxTween.parseFieldString(fieldPath);
			final field = path.pop();
			for (component in path) {
				if (Type.typeof(component) == TInt) {
					if ((target is Array)) {
						final index:Int = cast component;
						final arr:Array<Dynamic> = cast target;
						target = arr[index];
					}
				} else
					target = Reflect.getProperty(target, component);

				if (!Reflect.isObject(target) && !(target is Array))
					FlxG.log.critical('The object does not have the property "$component" in "$fieldPath"');
			}

			_propertyInfos.push({
				object: target,
				field: field,
				startValue: Math.NaN, // gets set after delay
				range: Reflect.getProperty(_properties, fieldPath)
			});
		}
	}

	private function setStartValues() {
		for (info in _propertyInfos) {
			final value:Dynamic = info.getField();

			if (value == null) FlxG.log.critical('The object does not have the property "${info.field}"');
			if (Math.isNaN(value)) FlxG.log.critical('The property "${info.field}" is not numeric.');

			info.startValue = value;
			info.range = info.range - value;
		}
	}

	override public function destroy():Void {
		super.destroy();
		_object = null;
		_properties = null;
		_propertyInfos = null;
	}

	override function isTweenOf(object:Dynamic, ?field:OneOfTwo<String, Int>):Bool {
		if (object == _object && field == null) return true;

		for (property in _propertyInfos)
			if (object == property.object && (field == null || field == property.field))
				return true;

		return false;
	}
}

@:structInit class VarTweenProperty {
	public var object:Dynamic;
	public var field:OneOfTwo<String, Int>;
	public var startValue:Float;
	public var range:Float;

	public function getField():Dynamic {
		if (Type.typeof(field) == TInt) {
			final index:Int = cast field;
			final arr:Array<Dynamic> = cast object;
			return arr[index];
		} else
			return Reflect.getProperty(object, field);
	}

	public function setField(value:Dynamic):Void {
		if (Type.typeof(field) == TInt) {
			final index:Int = cast field;
			final arr:Array<Dynamic> = cast object;
			arr[index] = value;
		} else
			Reflect.setProperty(object, field, value);
	}
}
