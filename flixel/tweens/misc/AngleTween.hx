package flixel.tweens.misc;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.typeLimit.OneOfTwo;

/**
 * Tweens from one angle to another.
 */
class AngleTween extends FlxTween {
	public var angle(default, null):Float;

	/**
	 * Optional sprite object whose angle to tween
	 */
	public var sprite(default, null):FlxSprite;

	var _start:Float;
	var _range:Float;

	/**
	 * Clean up references
	 */
	override public function destroy() {
		super.destroy();
		sprite = null;
	}

	/**
	 * Tweens the value from one angle to another.
	 *
	 * @param	fromAngle		Start angle.
	 * @param	toAngle			End angle.
	 * @param	duration		Duration of the tween.
	 */
	public function tween(fromAngle:Float, toAngle:Float, duration:Float, ?sprite:FlxSprite):AngleTween {
		_start = angle = fromAngle;
		_range = toAngle - angle;
		this.duration = duration;
		this.sprite = sprite;

		if (sprite != null) sprite.angle = angle % 360;

		start();
		return this;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		angle = _start + _range * scale;

		if (sprite != null) {
			final spriteAngle = angle % 360;
			sprite.angle = spriteAngle;
		}
	}

	override function isTweenOf(object:Dynamic, ?field:OneOfTwo<String, Int>):Bool {
		return sprite == object && (field == null || field == "angle");
	}
}
