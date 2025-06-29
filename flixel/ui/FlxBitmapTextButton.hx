package flixel.ui;

import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.ui.FlxButton.FlxTypedButton;

/**
 * A button with `FlxBitmapText` field as a `label`.
 */
class FlxBitmapTextButton extends FlxTypedButton<FlxBitmapText> {
	public function new(x = .0, y = .0, ?label:String, ?onClick:Void -> Void) {
		super(x, y, onClick);

		if (label != null) {
			this.label = new FlxBitmapText();
			this.label.width = 80;
			this.label.text = label;
			this.label.color = 0xFF333333;
			this.label.useTextColor = true;
			this.label.alignment = FlxTextAlign.CENTER;

			for (offset in labelOffsets) offset.set(0, 5);

			this.label.set(x + labelOffsets[status].x, y + labelOffsets[status].y);
		}
	}

	/**
	 * Updates the size of the text field to match the button.
	 */
	override function resetHelpers() {
		super.resetHelpers();

		label?.width = width;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		label?.update(elapsed);
	}
}
