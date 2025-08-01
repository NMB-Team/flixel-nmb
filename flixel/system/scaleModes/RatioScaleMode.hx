package flixel.system.scaleModes;

import flixel.FlxG;

/**
 * `RatioScaleMode` is a scaling mode which maintains the game's aspect ratio.
 * When you shrink or grow the window, the width and height of the game will adjust,
 * either scaling the game or adding black bars as needed.
 *
 * This is the default scaling mode used by HaxeFlixel.
 */
class RatioScaleMode extends BaseScaleMode {
	var fillScreen:Bool;

	/**
	 * @param fillScreen Whether to cut the excess side to fill the
	 * screen or always display everything.
	 */
	public function new(fillScreen = false) {
		super();
		this.fillScreen = fillScreen;
	}

	override function updateGameSize(width:Int, height:Int):Void {
		final ratio = FlxG.width / FlxG.height;
		final realRatio = width / height;

		var scaleY = realRatio < ratio;
		if (fillScreen)
			scaleY = !scaleY;

		if (scaleY) {
			gameSize.x = width;
			gameSize.y = Math.floor(gameSize.x / ratio);
		} else {
			gameSize.y = height;
			gameSize.x = Math.floor(gameSize.y * ratio);
		}
	}
}
