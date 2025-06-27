package flixel.system.debug.completion;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;

class CompletionListScrollBar extends Sprite {
	static inline final BG_COLOR = 0xFF444444;
	static inline final HANDLE_COLOR = 0xFF222222;

	private var handle:Bitmap;

	public function new(x:Int, y:Int, width:Int, height:Int) {
		super();

		this.x = x;
		this.y = y;

		addChild(new Bitmap(new BitmapData(width, height, true, BG_COLOR)));
		addChild(handle = new Bitmap(new BitmapData(width, 1, true, HANDLE_COLOR)));
	}

	public inline function updateHandle(lower:Int, items:Int, entries:Int) {
		handle.scaleY = Math.min((height / items) * entries, height);
		handle.y = (height / items) * lower;
		handle.y = flixel.math.FlxMath.bound(handle.y, 0, height - handle.scaleY);
	}
}
