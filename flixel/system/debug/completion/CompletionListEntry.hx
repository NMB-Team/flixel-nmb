package flixel.system.debug.completion;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextField;

class CompletionListEntry extends openfl.display.Sprite {
	public static inline final WIDTH = 150;
	public static inline final HEIGHT = 20;

	static inline final COLOR_NORMAL = 0xFF5F5F5F;
	static inline final COLOR_HIGHLIGHT = 0xFF6D6D6D;
	static inline final GUTTER = 4;

	static var normalBitmapData:BitmapData;
	static var highlightBitmapData:BitmapData;

	public var selected(default, set) = false;

	var background:Bitmap;
	var label:TextField;

	public function new() {
		super();

		initBitmapDatas();

		addChild(background = new Bitmap());
		background.bitmapData = normalBitmapData;

		label = DebuggerUtil.createTextField();
		label.x = GUTTER;
		addChild(label);
	}

	private function initBitmapDatas() {
		normalBitmapData ??= new BitmapData(WIDTH, HEIGHT, true, COLOR_NORMAL);
		highlightBitmapData ??= new BitmapData(WIDTH, HEIGHT, true, COLOR_HIGHLIGHT);
	}

	public function setItem(item:String) {
		label.text = item;
		if (label.width > WIDTH) {
			label.width = WIDTH;
			label.autoSize = openfl.text.TextFieldAutoSize.NONE;
		}
	}

	@:noCompletion inline function set_selected(selected:Bool):Bool {
		if (selected == this.selected) return selected;
		background.bitmapData = selected ? highlightBitmapData : normalBitmapData;
		return this.selected = selected;
	}
}
