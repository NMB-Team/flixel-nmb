package flixel.system.scaleModes;

import flixel.FlxG;

/**
 * `FixedScaleAdjustSizeScaleMode` is a scaling mode which maintains the game's scene at a fixed size.
 * This will clip off the edges of the scene for dimensions which are too small.
 * However, unlike `FixedScaleMode`, this mode will extend the width of the current scene to match the window scale.
 * The result is that objects that would be offscreen on smaller window sizes will be visible in larger ones.
 *
 * Note that compared with `StageSizeScaleMode`, this scale mode aligns with the center of the game's screen,
 * so the coordinates 0,0 may not be located at the top left of your game window.
 *
 * To enable it in your project, use `FlxG.scaleMode = new FixedScaleAdjustSizeScaleMode();`.
 */
class FixedScaleAdjustSizeScaleMode extends BaseScaleMode {
	var fixedWidth = false;
	var fixedHeight = false;

	public function new(fixedWidth = false, fixedHeight = false) {
		super();
		this.fixedWidth = fixedWidth;
		this.fixedHeight = fixedHeight;

		gameSize.set(FlxG.width, FlxG.height);
	}

	override public function onMeasure(width:Int, height:Int):Void {
		FlxG.width = fixedWidth ? FlxG.initialWidth : Math.ceil(width);
		FlxG.height = fixedHeight ? FlxG.initialHeight : Math.ceil(height);

		updateGameSize(width, height);
		updateDeviceSize(width, height);
		updateScaleOffset();
		updateGamePosition();
	}

	override function updateGameSize(width:Int, height:Int):Void {
		gameSize.x = FlxG.width;
		gameSize.y = FlxG.height;

		if (FlxG.camera == null) return;

		final oldWidth:Float = FlxG.camera.width;
		final oldHeight:Float = FlxG.camera.height;

		FlxG.camera.setSize(FlxG.width, FlxG.height);
		FlxG.camera.scroll.x += .5 * (oldWidth - FlxG.width);
		FlxG.camera.scroll.y += .5 * (oldHeight - FlxG.height);
	}
}
