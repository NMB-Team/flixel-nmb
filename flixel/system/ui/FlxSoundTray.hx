package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
#if flash
import openfl.text.AntiAliasType;
import openfl.text.GridFitType;
#end

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 */
class FlxSoundTray extends Sprite
{
	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;

	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	var _timer:Float;

	/**
	 * Helps display the volume bars on the sound tray.
	 */
	public var _bars:Array<Bitmap>;

	var _sound:FlxSound = new FlxSound();

	/**
	 * How wide the sound tray background is.
	 */
	var _width:Int = 100;

	var _defaultScale:Float = 2.0;

	public var countOfBars(default, set):Int = 15;
	inline function set_countOfBars(val:Int) {
		if (countOfBars != val) {
			countOfBars = val;
			_reloadBars();
		}
		return val;
	}

	/**The sound used when increasing the volume.**/
	public var volumeUpSound:String = "flixel/sounds/beep";

	/**The sound used when decreasing the volume.**/
	public var volumeDownSound:String = 'flixel/sounds/beep';

	/**Whether or not changing the volume should make noise.**/
	public var silent:Bool = false;

	var _baseBitmapData:BitmapData;

	var bgMain:Bitmap;

	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	@:keep
	public function new()
	{
		super();

		visible = false;
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		bgMain = new Bitmap(new BitmapData(_width, 30, true, 0x7F000000), true);
		screenCenter();
		addChild(bgMain);

		var text = new TextField();
		text.width = bgMain.width;
		text.height = bgMain.height;
		text.multiline = false;
		text.wordWrap = true;
		text.selectable = false;

		#if flash
		text.embedFonts = true;
		text.antiAliasType = AntiAliasType.NORMAL;
		text.gridFitType = GridFitType.PIXEL;
		#else
		#end
		var dtf:TextFormat = new TextFormat(FlxAssets.FONT_DEFAULT, 10, 0xffffff);
		dtf.align = TextFormatAlign.CENTER;
		text.defaultTextFormat = dtf;
		addChild(text);
		text.text = "VOLUME";
		text.y = 16;
		Utils.removeEventListeners(text);

		_baseBitmapData = new BitmapData(1, 1, false, FlxColor.WHITE);
		_reloadBars();

		y = -height;
		visible = false;
	}

	function _reloadBars() {
		if (_bars == null) _bars = new Array();

		while (_bars.length <= countOfBars) {
			final tmp = new Bitmap(_baseBitmapData);
			addChild(tmp);
			_bars.push(tmp);
		}

		for (i in _bars) i.visible = false;
		
		var bx = 10.;
		var by = 14.;
		var maxy = 24.;
		var _totalWidth = _width - bx * 2;
		var _barWidth = FlxMath.roundDecimal(_width * .5 / countOfBars, 1);
		_totalWidth -= _barWidth * .5;
		bx += _barWidth * .5;
		var _deltaX = Math.round(_totalWidth / countOfBars);
		var _deltaHeight = maxy - by;
		var _deltaY = _deltaHeight / countOfBars;
		var bar:Bitmap;

		for (i in 0...countOfBars) {
			bar = _bars[i];
			bar.visible = true;
			bar.scaleX = _barWidth;
			bar.scaleY = FlxMath.roundDecimal(_deltaY * (i + 1), 1);

			bar.x = FlxMath.roundDecimal(bx, 1);
			bar.y = FlxMath.roundDecimal(by, 1);
			bx += _deltaX;
			by -= _deltaY;
		}
		_updateBars();
	}

	function _updateBars() {
		final globalVolume:Int = FlxG.sound.muted ? 0 : Math.round(FlxG.sound.volume * countOfBars);
		final alpha:Float = FlxMath.lerp(.35, 1, Math.pow(FlxG.sound.volume, .5));
		var bar:Bitmap;
		for (i in 0...countOfBars) {
			bar = _bars[i];
			bar.alpha = (i < globalVolume) ? alpha : .3;
		}
	}

	var lerpYPos = .0;
	var alphaTarget = .0;

	/**
	 * This function updates the soundtray object.
	 */
	public function update(MS:Float):Void
	{
		y = Utils.lerpDelta(y, lerpYPos, .15);
		alpha = Utils.lerpDelta(alpha, alphaTarget, .3);

		if (_timer > 0) {
			_timer -= MS * .001;
			alphaTarget = 1;
		} else if (y >= -height) {
			lerpYPos = -height;
			alphaTarget = 0;
		}

		if (y <= -height) visible = active = false;
	}

	/**
	 * Makes the little volume tray slide out.
	 *
	 * @param	up Whether the volume is increasing.
	 */
	public function show(up:Bool = false, ?forceSound:Bool = true):Void
	{
		if (!silent && forceSound)
		{
			var sound = FlxAssets.getSound(up ? volumeUpSound : volumeDownSound);
			if (sound != null) {
				FlxG.sound.list.add(_sound);
				_sound.loadEmbedded(sound);
				_sound.play(true);
				FlxG.sound.list.remove(_sound);
			}
		}

		_timer = 1;
		lerpYPos = 0;
		active = visible = true;
		_updateBars();
		#if FLX_SAVE
		// Save sound preferences
		FlxG.save.data.mute = FlxG.sound.muted;
		FlxG.save.data.volume = FlxG.sound.volume;
		FlxG.save.flush();
		#end
	}

	public function screenCenter():Void
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = ((Lib.current.stage.stageWidth - _width * _defaultScale) * .5 - FlxG.game.x);
	}
}
#end
