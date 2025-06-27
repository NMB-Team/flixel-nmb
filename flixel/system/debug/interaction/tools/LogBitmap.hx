package flixel.system.debug.interaction.tools;

import flixel.FlxG;
import flixel.FlxG;
import openfl.display.Graphics;
import openfl.display.BitmapData;
import flixel.system.debug.interaction.Interaction;
// import flixel.system.debug.Tooltip;

using flixel.util.FlxArrayUtil;


/**
 * A tool to add selected sprites to the BitmapLog window
 *
 * @author George
 */
class LogBitmap extends Tool {
	override function init(brain:Interaction):Tool {
		super.init(brain);

		_name = "Log selected bitmaps";
		setButton(Icon.bitmapLog);
		button.toggleMode = false;

		return this;
	}

	override function update():Void {
		button.enabled = _brain.selectedItems.countLiving() > 0;
		button.mouseEnabled = button.enabled;
		button.alpha = button.enabled ? .3 : .1;
	}

	override function onButtonClicked() {
		#if FLX_DEBUG // needed for coverage tests
		if (_brain.selectedItems.length == 0) return;

		for (member in _brain.selectedItems)
			if (member != null && member is FlxSprite) {
				final sprite:FlxSprite = cast member;
				FlxG.bitmapLog.add(sprite.graphic);
			}
		#end
	}
}
