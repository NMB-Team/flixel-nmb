package flixel.system.debug;

import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;

class DebuggerUtil {
	public static function createTextField(x = .0, y = .0, color = FlxColor.WHITE, size = 12):TextField {
		return initTextField(new TextField(), x, y, color, size);
	}

	public static function initTextField<T:TextField>(tf:T, x = .0, y = .0, color = FlxColor.WHITE, size = 12):T {
		tf.x = x;
		tf.y = y;
		tf.multiline = tf.wordWrap = tf.selectable = false;
		tf.embedFonts = true;
		tf.defaultTextFormat = new TextFormat(FlxAssets.FONT_DEBUGGER, size, color.rgb);
		tf.alpha = color.alphaFloat;
		tf.autoSize = TextFieldAutoSize.LEFT;
		return tf;
	}

	@:allow(flixel.system)
	static function fixSize(bitmapData:BitmapData):BitmapData {
		#if html5 // dirty hack for openfl/openfl#682
		Reflect.setProperty(bitmapData, "width", 11);
		Reflect.setProperty(bitmapData, "height", 11);
		#end

		return bitmapData;
	}
}
