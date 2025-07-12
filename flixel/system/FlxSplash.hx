package flixel.system;

import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import flixel.FlxG;
import flixel.FlxState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.NextState;

class FlxSplash extends FlxState {
	/**
	 * @since 4.8.0
	 */
	public static final MUTED = #if html5 true #else false #end;

	// Colors as constants
	static inline final GREEN = 0xff00b922;
	static inline final YELLOW = 0xffffc132;
	static inline final RED = 0xfff5274e;
	static inline final BLUE = 0xff3641ff;
	static inline final LIGHT_BLUE = 0xff04cdfb;

	var _sprite:Sprite;
	var _gfx:Graphics;
	var _text:TextField;

	var _times:Array<Float>;
	var _colors:Array<Int>;
	var _functions:Array<Void -> Void>;
	var _curPart = 0;
	var _cachedBgColor:FlxColor;
	var _cachedTimestep:Bool;
	var _cachedAutoPause:Bool;

	var nextState:NextState;

	public function new(nextState:NextState) {
		super();
		this.nextState = nextState;
	}

	override public function create():Void {
		_cachedBgColor = FlxG.cameras.bgColor;
		FlxG.cameras.bgColor = FlxColor.BLACK;

		// This is required for sound and animation to synch up properly
		_cachedTimestep = FlxG.fixedTimestep;
		FlxG.fixedTimestep = false;

		_cachedAutoPause = FlxG.autoPause;
		FlxG.autoPause = false;

		#if FLX_KEYBOARD
		FlxG.keys.enabled = false;
		#end

		_times = [.041, .184, .334, .495, .636];
		_colors = [GREEN, YELLOW, RED, BLUE, LIGHT_BLUE];
		_functions = [drawGreen, drawYellow, drawRed, drawBlue, drawLightBlue];

		for (time in _times)
			new FlxTimer().start(time, timerCallback);

		initDisplay();

		#if FLX_SOUND_SYSTEM
		if (!MUTED) FlxG.sound.load(FlxAssets.getSoundAddExtension("flixel/sounds/flixel")).play();
		#end
	}

	private function initDisplay() {
		final stageWidth = Lib.current.stage.stageWidth;
		final stageHeight = Lib.current.stage.stageHeight;

		_sprite = new Sprite();
		FlxG.stage.addChild(_sprite);
		_gfx = _sprite.graphics;

		_text = new TextField();
		_text.selectable = false;
		_text.embedFonts = true;

		final dtf = new TextFormat(FlxAssets.FONT_DEFAULT, 16, 0xffffff);
		dtf.align = TextFormatAlign.CENTER;
		_text.defaultTextFormat = dtf;
		_text.text = "HaxeFlixel";
		FlxG.stage.addChild(_text);

		onResize(stageWidth, stageHeight);
	}

	override public function destroy():Void {
		_sprite = null;
		_gfx = null;
		_text = null;
		_times = null;
		_colors = null;
		_functions = null;

		super.destroy();
	}

	private function complete() {
		FlxG.switchState(nextState);
	}

	override public function onResize(width:Int, height:Int):Void {
		super.onResize(width, height);

		_sprite.x = (width * .5);
		_sprite.y = (height * .5) - 20 * FlxG.game.scaleY;

		_text.width = width / FlxG.game.scaleX;
		_text.x = 0;
		_text.y = _sprite.y + 80 * FlxG.game.scaleY;

		_sprite.scaleX = _text.scaleX = FlxG.game.scaleX;
		_sprite.scaleY = _text.scaleY = FlxG.game.scaleY;
	}

	private function timerCallback(timer:FlxTimer):Void {
		_functions[_curPart]();
		_text.textColor = _colors[_curPart];
		_curPart++;

		if (_curPart == 5) {
			// Make the logo a tad bit longer, so our users fully appreciate our hard work :D
			FlxTween.num(_sprite.alpha, 0, 3, {ease: FlxEase.quadOut, onComplete: Void -> complete()}, a -> _sprite.alpha = a);
			FlxTween.num(_text.alpha, 0, 3, {ease: FlxEase.quadOut}, a -> _sprite.alpha = a);
		}
	}

	private function drawPolygon(color:Int, points:Array<Float>):Void {
		_gfx.beginFill(color);
		_gfx.moveTo(points[0], points[1]);
		for (i in 2...points.length) if (i % 2 == 0) _gfx.lineTo(points[i], points[i + 1]);
		_gfx.lineTo(points[0], points[1]);
		_gfx.endFill();
	}

	private function drawGreen():Void {
		drawPolygon(GREEN, [0, -37, 1, -37, 37, 0, 37, 1, 1, 37, 0, 37, -37, 1, -37, 0]);
	}

	private function drawYellow():Void {
		drawPolygon(YELLOW, [-50, -50, -25, -50, 0, -37, -37, 0, -50, -25, -50, -50]);
	}

	private function drawRed():Void {
		drawPolygon(RED, [50, -50, 25, -50, 1, -37, 37, 0, 50, -25, 50, -50]);
	}

	private function drawBlue():Void {
		drawPolygon(BLUE, [-50, 50, -25, 50, 0, 37, -37, 1, -50, 25, -50, 50]);
	}

	private function drawLightBlue():Void {
		drawPolygon(LIGHT_BLUE, [50, 50, 25, 50, 1, 37, 37, 1, 50, 25, 50, 50]);
	}

	override function startOutro(onOutroComplete:() -> Void) {
		FlxG.cameras.bgColor = _cachedBgColor;
		FlxG.fixedTimestep = _cachedTimestep;
		FlxG.autoPause = _cachedAutoPause;

		#if FLX_KEYBOARD
		FlxG.keys.enabled = true;
		#end

		FlxG.stage.removeChild(_sprite);
		FlxG.stage.removeChild(_text);

		super.startOutro(onOutroComplete);
	}
}