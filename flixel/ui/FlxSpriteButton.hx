package flixel.ui;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxImageFrame;
import flixel.input.IFlxInput;
import flixel.text.FlxText;
import flixel.ui.FlxButton.FlxTypedButton;
import openfl.display.BitmapData;

/**
 * A simple button class that calls a function when clicked by the mouse.
 */
class FlxSpriteButton extends FlxTypedButton<FlxSprite> implements IFlxInput {
	/**
	 * Creates a new FlxButton object with a gray background
	 * and a callback function on the UI thread.
	 *
	 * @param   X         The x position of the button.
	 * @param   Y         The y position of the button.
	 * @param   Text      The text that you want to appear on the button.
	 * @param   OnClick   The function to call whenever the button is clicked.
	 */
	public function new(x = .0, y = .0, ?label:FlxSprite, ?onClick:Void -> Void) {
		super(x, y, onClick);

		for (point in labelOffsets) point.set(point.x - 1, point.y + 4);

		this.label = label;
	}

	/**
	 * Generates text graphic for button's label.
	 *
	 * @param   Text    text for button's label
	 * @param   font    font name for button's label
	 * @param   size    font size for button's label
	 * @param   color   text color for button's label
	 * @param   align   text align for button's label
	 * @return  this button with generated text graphic.
	 */
	public function createTextLabel(textName:String, ?font:String, ?size = 8, ?color = 0x333333, ?align = FlxTextAlign.CENTER):FlxSpriteButton {
		if (textName != null) {
			final text = new FlxText(0, 0, frameWidth, textName);
			text.setFormat(font, size, color, align);
			text.alpha = labelAlphas[status];
			text.drawFrame(true);

			final labelBitmap = text.graphic.bitmap.clone();
			final labelKey = text.graphic.key;
			text.destroy();

			label ??= new FlxSprite();

			final labelGraphic = FlxG.bitmap.add(labelBitmap, false, labelKey);
			label.frames = FlxImageFrame.fromGraphic(labelGraphic);
		}

		return this;
	}
}
