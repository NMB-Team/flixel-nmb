package flixel.tweens.misc;

import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.util.typeLimit.OneOfTwo;

/**
 * Shake effect for a FlxSprite
 */
class ShakeTween extends FlxTween {
	/**
	 * Percentage representing the maximum distance that the object can move while shaking.
	 */
	var intensity:Float;

	/**
	 * Defines on what axes to `shake()`. Default value is `XY` / both.
	 */
	var axes:FlxAxes;

	/**
	 * The sprite to shake.
	 */
	var sprite:FlxSprite;

	/**
	 * Defines the initial offset of the sprite at the beginning of the shake effect.
	 */
	var initialOffset:FlxPoint;

	/**
	 * A simple shake effect for FlxSprite.
	 *
	 * @param	sprite       Sprite to shake.
	 * @param	intensity    Percentage representing the maximum distance
	 *                      that the sprite can move while shaking.
	 * @param	duration     The length in seconds that the shaking effect should last.
	 * @param	axes         On what axes to shake. Default value is `FlxAxes.XY` / both.
	 */
	public function tween(sprite:FlxSprite, intensity = .05, duration = 1., axes:FlxAxes = XY):ShakeTween {
		this.intensity = intensity;
		this.sprite = sprite;
		this.duration = duration;
		this.axes = axes;

		initialOffset = new FlxPoint(sprite.offset.x, sprite.offset.y);

		start();
		return this;
	}

	override function destroy():Void {
		super.destroy();
		// Return the sprite to its initial offset.
		if (sprite != null && !sprite.offset.equals(initialOffset))
			sprite.offset.set(initialOffset.x, initialOffset.y);

		sprite = null;
		initialOffset = null;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (axes.x) sprite.offset.x = initialOffset.x + FlxG.random.float(-intensity * sprite.width, intensity * sprite.width);
		if (axes.y) sprite.offset.y = initialOffset.y + FlxG.random.float(-intensity * sprite.height, intensity * sprite.height);
	}

	override function isTweenOf(Object:Dynamic, ?Field:OneOfTwo<String, Int>):Bool {
		return sprite == Object && (Field == null || Field == "shake");
	}
}
