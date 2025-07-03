package flixel.system;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Sprite;
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.FlxG;
import flixel.util.FlxDestroyUtil;

@:keep @:bitmap("assets/images/preloader/light.png")
private class GraphicLogoLight extends BitmapData {}

@:keep @:bitmap("assets/images/preloader/corners.png")
private class GraphicLogoCorners extends BitmapData {}

/**
 * This is the Default HaxeFlixel Themed Preloader
 * You can make your own style of Preloader by overriding `FlxPreloaderBase` and using this class as an example.
 * To use your Preloader, simply change `Project.xml` to say: `<app preloader="class.path.MyPreloader" />`
 */
class FlxPreloader extends FlxBasePreloader {
	var _buffer:Sprite;
	var _bmpBar:Bitmap;
	var _text:TextField;
	var _logo:Sprite;
	var _logoGlow:Sprite;

	static inline final BAR_HEIGHT = 7;
	static inline final BAR_OFFSET = 11;

	/**
	 * Initialize your preloader here.
	 *
	 * ```haxe
	 * super(0, ["test.com", FlxPreloaderBase.LOCAL]); // example of site-locking
	 * super(10); // example of long delay (10 seconds)
	 * ```
	 */
	override public function new(minDisplayTime = .0, ?allowedURLs:Array<String>):Void {
		super(minDisplayTime, allowedURLs);
	}

	/**
	 * This class is called as soon as the FlxPreloaderBase has finished initializing.
	 * Override it to draw all your graphics and things - make sure you also override update
	 * Make sure you call super.create()
	 */
	override function create():Void {
		_buffer = new Sprite();
		_buffer.scaleX = _buffer.scaleY = 2;
		addChild(_buffer);

		final stageWidth = Lib.current.stage.stageWidth;
		final stageHeight = Lib.current.stage.stageHeight;

		_width = Std.int(stageWidth / _buffer.scaleX);
		_height = Std.int(stageHeight / _buffer.scaleY);

		_buffer.addChild(new Bitmap(new BitmapData(_width, _height, false, 0x00345e)));

		final logoLight = createBitmap(GraphicLogoLight, (logoLight:Bitmap) -> {
			logoLight.width = logoLight.height = _height;
			logoLight.x = (_width - logoLight.width) * .5;
		});
		logoLight.smoothing = true;
		_buffer.addChild(logoLight);
		_bmpBar = new Bitmap(new BitmapData(1, 7, false, 0x5f6aff));
		_bmpBar.x = 4;
		_bmpBar.y = _height - 11;
		_buffer.addChild(_bmpBar);

		_text = new TextField();
		_text.defaultTextFormat = new TextFormat(FlxAssets.FONT_DEFAULT, 8, 0x5f6aff);
		_text.embedFonts = true;
		_text.selectable = _text.multiline = false;
		_text.x = 2;
		_text.y = _bmpBar.y - 11;
		_text.width = 200;
		_buffer.addChild(_text);

		_logo = new Sprite();
		FlxAssets.drawLogo(_logo.graphics);
		_logo.scaleX = _logo.scaleY = _height * .125 * .04;
		_logo.x = (_width - _logo.width) * .5;
		_logo.y = (_height - _logo.height) * .5;
		_buffer.addChild(_logo);

		_logoGlow = new Sprite();
		FlxAssets.drawLogo(_logoGlow.graphics);
		_logoGlow.blendMode = BlendMode.SCREEN;
		_logoGlow.scaleX = _logoGlow.scaleY = _height * .125 * .04;
		_logoGlow.x = (_width - _logoGlow.width) * .5;
		_logoGlow.y = (_height - _logoGlow.height) * .5;
		_buffer.addChild(_logoGlow);

		final corners = createBitmap(GraphicLogoCorners, corners -> {
			corners.width = _width;
			corners.height = height;
		});
		corners.smoothing = true;
		_buffer.addChild(corners);

		final bitmap = new Bitmap(new BitmapData(_width, _height, false, 0xffffff));
		var i = 0;
		var j = 0;
		while (i < _height) {
			j = 0;
			while (j < _width) bitmap.bitmapData.setPixel(j++, i, 0);
			i += 2;
		}
		bitmap.blendMode = BlendMode.OVERLAY;
		bitmap.alpha = .25;
		_buffer.addChild(bitmap);

		super.create();
	}

	/**
	 * Update is called every frame, passing the current percent loaded. Use this to change your loading bar or whatever.
	 * @param	Percent	The percentage that the project is loaded
	 */
	override public function update(percent:Float):Void {
		_bmpBar.scaleX = percent * (_width - 8);
		_text.text = '${FlxG.VERSION} ${Std.int(percent * 100)}%';

		if (percent < .1) {
			_logoGlow.alpha = _logo.alpha = 0;
		} else if (percent < .15) {
			_logoGlow.alpha = FlxG.random.float(0, 1);
			_logo.alpha = 0;
		} else if (percent < .2) {
			_logoGlow.alpha = _logo.alpha = 0;
		} else if (percent < .25) {
			_logoGlow.alpha = 0;
			_logo.alpha = FlxG.random.float(0, 1);
		} else if (percent < .7) {
			_logoGlow.alpha = (percent - .45) / .45;
			_logo.alpha = 1;
		} else if (percent > .8 && percent < .9) {
			_logoGlow.alpha = 1 - (percent - 0.8) * 10;
			_logo.alpha = 0;
		} else if (percent > .9) {
			_buffer.alpha = 1 - (percent - .9) * 10;
		}
	}

	/**
	 * Cleanup your objects!
	 * Make sure you call super.destroy()!
	 */
	override function destroy():Void {
		_buffer = FlxDestroyUtil.removeChild(this, _buffer);
		_bmpBar = null;
		_text = null;
		_logo = null;
		_logoGlow = null;

		super.destroy();
	}
}