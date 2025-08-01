package flixel.system.scaleModes;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxAlign;

/**
 * The base class from which all other scale modes extend from.
 * You can implement your own scale mode by extending this class and overriding the appropriate methods.
 *
 * The default behavior of `BaseScaleMode` matches that of `FillScaleMode`.
 */
class BaseScaleMode {
	public var deviceSize(default, null):FlxPoint;
	public var gameSize(default, null):FlxPoint;
	public var scale(default, null):FlxPoint;
	public var offset(default, null):FlxPoint;

	public var horizontalAlign(default, set):FlxHorizontalAlign = CENTER;
	public var verticalAlign(default, set):FlxVerticalAlign = CENTER;

	public function new() {
		deviceSize = FlxPoint.get();
		gameSize = FlxPoint.get();
		scale = FlxPoint.get();
		offset = FlxPoint.get();
	}

	public function onMeasure(width:Int, height:Int):Void {
		FlxG.width = FlxG.initialWidth;
		FlxG.height = FlxG.initialHeight;

		updateGameSize(width, height);
		updateDeviceSize(width, height);
		updateScaleOffset();
		updateGamePosition();
	}

	function updateGameSize(width:Int, height:Int):Void {
		gameSize.set(width, height);
	}

	function updateDeviceSize(width:Int, height:Int):Void {
		deviceSize.set(width, height);
	}

	function updateScaleOffset():Void {
		scale.x = gameSize.x / FlxG.width;
		scale.y = gameSize.y / FlxG.height;
		updateOffsetX();
		updateOffsetY();
	}

	function updateOffsetX():Void {
		offset.x = switch (horizontalAlign) {
			case FlxHorizontalAlign.LEFT: 0;
			case FlxHorizontalAlign.CENTER: Math.ceil((deviceSize.x - gameSize.x) * .5);
			case FlxHorizontalAlign.RIGHT: deviceSize.x - gameSize.x;
		}
	}

	function updateOffsetY():Void {
		offset.y = switch (verticalAlign) {
			case FlxVerticalAlign.TOP: 0;
			case FlxVerticalAlign.CENTER: Math.ceil((deviceSize.y - gameSize.y) * .5);
			case FlxVerticalAlign.BOTTOM: deviceSize.y - gameSize.y;
		}
	}

	function updateGamePosition():Void {
		if (FlxG.game == null) return;

		FlxG.game.x = offset.x;
		FlxG.game.y = offset.y;
	}

	function set_horizontalAlign(value:FlxHorizontalAlign):FlxHorizontalAlign {
		horizontalAlign = value;
		if (offset != null) {
			updateOffsetX();
			updateGamePosition();
		}
		return value;
	}

	function set_verticalAlign(value:FlxVerticalAlign):FlxVerticalAlign {
		verticalAlign = value;
		if (offset != null) {
			updateOffsetY();
			updateGamePosition();
		}
		return value;
	}
}
