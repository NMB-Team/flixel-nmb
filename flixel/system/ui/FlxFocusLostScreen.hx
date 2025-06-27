package flixel.system.ui;

import openfl.display.Graphics;
import openfl.display.Sprite;
import flixel.FlxG;
import flixel.system.FlxAssets;

class FlxFocusLostScreen extends Sprite {
	@:keep public function new() {
		super();
		draw();

		final logo = new Sprite();
		FlxAssets.drawLogo(logo.graphics);
		logo.scaleX = logo.scaleY = .2;
		logo.x = logo.y = 5;
		logo.alpha = .35;
		addChild(logo);

		visible = false;
	}

	/**
	 * Redraws the big arrow on the focus lost screen.
	 */
	public function draw():Void {
		final gfx = graphics;

		final screenWidth = Std.int(FlxG.stage.stageWidth);
		final screenHeight = Std.int(FlxG.stage.stageHeight);

		// Draw transparent black backdrop
		gfx.clear();
		gfx.moveTo(0, 0);
		gfx.beginFill(0, .5);
		gfx.drawRect(0, 0, screenWidth, screenHeight);
		gfx.endFill();

		// Draw white arrow
		final halfWidth = Std.int(screenWidth * .5);
		final halfHeight = Std.int(screenHeight * .5);
		final helper = Std.int(Math.min(halfWidth, halfHeight) / 3);
		gfx.moveTo(halfWidth - helper, halfHeight - helper);
		gfx.beginFill(0xffffff, .65);
		gfx.lineTo(halfWidth + helper, halfHeight);
		gfx.lineTo(halfWidth - helper, halfHeight + helper);
		gfx.lineTo(halfWidth - helper, halfHeight - helper);
		gfx.endFill();

		this.x = -FlxG.scaleMode.offset.x;
		this.y = -FlxG.scaleMode.offset.y;
	}
}
