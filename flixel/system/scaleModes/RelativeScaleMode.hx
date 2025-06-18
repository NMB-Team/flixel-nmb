package flixel.system.scaleModes;

import flixel.FlxG;

/**
 * `RelativeScaleMode` is a scaling mode which stretches and squashes the game to exactly fit the provided window.
 * It acts similar to the `FillScaleMode`, however there is one major difference.
 * `RelativeScaleMode` takes two parameters, which represent the width scale and height scale.
 *
 * For example, `RelativeScaleMode(1, 0.5)` will cause the game to take up 100% of the window width,
 * but only 50% of the window height, filling in the remaining space with a black margin.
 *
 * To enable it in your project, use `FlxG.scaleMode = new RelativeScaleMode();`.
 */
class RelativeScaleMode extends BaseScaleMode {
	var _widthScale:Float;
	var _heightScale:Float;

	public function new(widthScale:Float, heightScale:Float) {
		super();
		initScale(widthScale, heightScale);
	}

	inline function initScale(widthScale:Float, heightScale:Float):Void {
		_widthScale = widthScale;
		_heightScale = heightScale;
	}

	public function setScale(widthScale:Float, heightScale:Float):Void {
		initScale(widthScale, heightScale);
		onMeasure(FlxG.stage.stageWidth, FlxG.stage.stageHeight);
	}

	override function updateGameSize(width:Int, height:Int):Void {
		gameSize.x = Std.int(width * _widthScale);
		gameSize.y = Std.int(height * _heightScale);
	}
}
