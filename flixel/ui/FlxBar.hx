package flixel.ui;

import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxImageFrame;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxGradient;
import flixel.util.FlxStringUtil;

// TODO: better handling bars with borders (don't take border into account while drawing its front).

/**
 * FlxBar is a quick and easy way to create a graphical bar which can
 * be used as part of your UI/HUD, or positioned next to a sprite.
 * It could represent a loader, progress or health bar.
 *
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
 */
class FlxBar extends FlxSprite
{
	/**
	 * If false, the bar is tracking its parent
	 * (the position is synchronized with the parent's position).
	 */
	public var fixedPosition:Bool = true;

	/**
	 * How many pixels = 1% of the bar (barWidth (or barHeight) / 100)
	 */
	public var pxPerPercent(default, null):Float;

	/**
	 * The positionOffset controls how far offset the FlxBar is from the parent sprite (if at all)
	 */
	public var positionOffset(default, null):FlxPoint;

	/**
	 * If this FlxBar should be killed when its empty
	 */
	public var killOnEmpty:Bool = false;

	/**
	 * The percentage of how full the bar is (a value between 0 and 100)
	 */
	public var percent(get, set):Float;

	/**
	 * The percentage of how full the bar is (a value between 0 and 100)
	 */
	public var floorPercent(get, never):Int;

	/**
	 * The current value - must always be between min and max
	 */
	@:isVar
	public var value(default, set):Float;

	/**
	 * The minimum value the bar can be (can never be >= max)
	 */
	public var min(default, null):Float;

	/**
	 * The maximum value the bar can be (can never be <= min)
	 */
	public var max(default, null):Float;

	/**
	 * How wide is the range of this bar? (max - min)
	 */
	public var range(default, null):Float;

	/**
	 * What 1% of the bar is equal to in terms of value (range / 100)
	 */
	public var pct(default, null):Float;

	/**
	 * Number of frames FlxBar will have. Default value is 100.
	 * The bigger value you set then visual will change smoother.
	 *
	 * If the value is set to 0, the bar will smoothly change
	 * to any value given, instead of looking blocky.
	 *
	 * @since 4.1.0
	 */
	public var numDivisions(default, set):Int = 100;

	/**
	 * Determines whenever numDivisions will make stuff blocky
	 */
	public var continuous:Bool = false;

	/**
	 * This function will be called when value will hit it's minimum
	 */
	public var emptyCallback:Void->Void;

	/**
	 * This function will be called when value will hit it's maximum
	 */
	public var filledCallback:Void->Void;

	/**
	 * Object to track value from
	 */
	public var parent:Dynamic;

	/**
	 * Property of parent object to track.
	 */
	public var parentVariable:String;

	public var barWidth(default, null):Int;
	public var barHeight(default, null):Int;

	/**
	 * BarFrames which will be used for filled bar rendering.
	 * It is recommended to use this property in tile render mode
	 * (although it will work in blit render mode also).
	 */
	@:isVar
	public var frontFrames(get, set):FlxImageFrame;

	public var backFrames(get, set):FlxImageFrame;

	/**
	 * The direction from which the health bar will fill-up. Default is from left to right. Change takes effect immediately.
	 */
	public var fillDirection(default, set):FlxBarFillDirection;

	var _fillHorizontal:Bool;

	/**
	 * FlxFrame which is used for rendering front graphics of bar (showing value) in tile render mode.
	 */
	var _frontFrame:FlxFrame;

	var _filledFlxRect:FlxRect;

	var _emptyBar:BitmapData;
	var _emptyBarRect:Rectangle;

	var _filledBar:BitmapData;

	var _zeroOffset:Point;

	var _filledBarRect:Rectangle;
	var _filledBarPoint:Point;

	var _maxPercent:Int = 100;

	/**
	 * Create a new FlxBar Object
	 *
	 * @param	x			The x coordinate location of the resulting bar (in world pixels)
	 * @param	y			The y coordinate location of the resulting bar (in world pixels)
	 * @param	direction 	The fill direction, LEFT_TO_RIGHT by default
	 * @param	width		The width of the bar in pixels
	 * @param	height		The height of the bar in pixels
	 * @param	parentRef	A reference to an object in your game that you wish the bar to track
	 * @param	variable	The variable of the object that is used to determine the bar position. For example if the parent was an FlxSprite this could be "health" to track the health value
	 * @param	min			The minimum value. I.e. for a progress bar this would be zero (nothing loaded yet)
	 * @param	max			The maximum value the bar can reach. I.e. for a progress bar this would typically be 100.
	 * @param	showBorder	Should the bar be outlined with a solid border?
	 */
	public function new(x:Float = 0, y:Float = 0, ?direction:FlxBarFillDirection, width:Int = 100, height:Int = 10, ?parentRef:Dynamic, variable:String = "",
			min:Float = 0, max:Float = 100, showBorder:Bool = false)
	{
		super(x, y);

		direction = (direction == null) ? FlxBarFillDirection.LEFT_TO_RIGHT : direction;

		barWidth = width;
		barHeight = height;

		_filledBarPoint = new Point();
		_filledBarRect = new Rectangle();
		if (FlxG.render.blit)
		{
			_zeroOffset = new Point();
			_emptyBarRect = new Rectangle();
			makeGraphic(width, height, FlxColor.TRANSPARENT, true);
		}
		else
		{
			_filledFlxRect = FlxRect.get();
		}

		if (parentRef != null)
		{
			parent = parentRef;
			parentVariable = variable;
		}

		fillDirection = direction;
		createFilledBar(0xff005100, 0xff00F400, showBorder);
		setRange(min, max);
	}

	override public function destroy():Void
	{
		positionOffset = FlxDestroyUtil.put(positionOffset);

		if (FlxG.render.tile)
		{
			frontFrames = null;
			_filledFlxRect = FlxDestroyUtil.put(_filledFlxRect);
		}
		else
		{
			_emptyBarRect = null;
			_zeroOffset = null;
			_emptyBar = FlxDestroyUtil.dispose(_emptyBar);
			_filledBar = FlxDestroyUtil.dispose(_filledBar);
		}
		_filledBarRect = null;
		_filledBarPoint = null;

		parent = null;
		emptyCallback = null;
		filledCallback = null;

		super.destroy();
	}

	/**
	 * Track the parent FlxSprites x/y coordinates. For example if you wanted your sprite to have a floating health-bar above their head.
	 * If your health bar is 10px tall and you wanted it to appear above your sprite, then set offsetY to be -10
	 * If you wanted it to appear below your sprite, and your sprite was 32px tall, then set offsetY to be 32. Same applies to offsetX.
	 *
	 * @param	offsetX		The offset on X in relation to the origin x/y of the parent
	 * @param	offsetY		The offset on Y in relation to the origin x/y of the parent
	 * @see		stopTrackingParent
	 */
	public function trackParent(offsetX:Int, offsetY:Int):Void
	{
		fixedPosition = false;
		positionOffset = FlxPoint.get(offsetX, offsetY);

		if (Reflect.hasField(parent, "scrollFactor"))
		{
			scrollFactor.x = parent.scrollFactor.x;
			scrollFactor.y = parent.scrollFactor.y;
		}
	}

	/**
	 * Sets a parent for this FlxBar. Instantly replaces any previously set parent and refreshes the bar.
	 *
	 * @param	parentRef	A reference to an object in your game that you wish the bar to track
	 * @param	variable	The variable of the object that is used to determine the bar position. For example if the parent was an FlxSprite this could be "health" to track the health value
	 * @param	track		If you wish the FlxBar to track the x/y coordinates of parent set to true (default false)
	 * @param	offsetX		The offset on X in relation to the origin x/y of the parent
	 * @param	offsetY		The offset on Y in relation to the origin x/y of the parent
	 */
	public function setParent(parentRef:Dynamic, variable:String, track:Bool = false, offsetX:Int = 0, offsetY:Int = 0):Void
	{
		parent = parentRef;
		parentVariable = variable;

		if (track)
		{
			trackParent(offsetX, offsetY);
		}

		updateValueFromParent();
	}

	/**
	 * Tells the health bar to stop following the parent sprite. The given posX and posY values are where it will remain on-screen.
	 *
	 * @param	posX	X coordinate of the health bar now it's no longer tracking the parent sprite
	 * @param	posY	Y coordinate of the health bar now it's no longer tracking the parent sprite
	 */
	public function stopTrackingParent(posX:Int, posY:Int):Void
	{
		fixedPosition = true;
		x = posX;
		y = posY;
	}

	/**
	 * Sets callbacks which will be triggered when the value of this FlxBar reaches min or max.
	 * Functions will only be called once and not again until the value changes.
	 * Optionally the FlxBar can be killed if it reaches min, but if will fire the empty callback first (if set)
	 *
	 * @param	onEmpty			The function that is called if the value of this FlxBar reaches min
	 * @param	onFilled		The function that is called if the value of this FlxBar reaches max
	 * @param	killOnEmpty		If set it will call FlxBar.kill() if the value reaches min
	 */
	public function setCallbacks(onEmpty:Void->Void, onFilled:Void->Void, killOnEmpty:Bool = false):Void
	{
		emptyCallback = (onEmpty != null) ? onEmpty : emptyCallback;
		filledCallback = (onFilled != null) ? onFilled : filledCallback;
		this.killOnEmpty = killOnEmpty;
	}

	/**
	 * Set the minimum and maximum allowed values for the FlxBar
	 *
	 * @param	min			The minimum value. I.e. for a progress bar this would be zero (nothing loaded yet)
	 * @param	max			The maximum value the bar can reach. I.e. for a progress bar this would typically be 100.
	 */
	public function setRange(min:Float, max:Float):Void
	{
		if (max <= min)
		{
			throw "FlxBar: max cannot be less than or equal to min";
			return;
		}

		this.min = min;
		this.max = max;
		this.range = max - min;
		this.pct = range / _maxPercent;

		pxPerPercent = (_fillHorizontal) ? (barWidth / _maxPercent) : (barHeight / _maxPercent);

		if (!Math.isNaN(value))
		{
			value = Math.max(min, Math.min(value, max));
		}
		else
		{
			value = min;
		}
	}

	/**
	 * Creates a solid-colour filled health bar in the given colours, with optional border.
	 * All colour values are in 0xAARRGGBB format, so if you want a slightly transparent health bar give it lower AA values.
	 *
	 * @param	empty		The color of the bar when empty in 0xAARRGGBB format (the background colour)
	 * @param	fill		The color of the bar when full in 0xAARRGGBB format (the foreground colour)
	 * @param	showBorder	Should the bar be outlined with a solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 * @param   borderSize  The size of the border, in pixels.
	 * @return	This FlxBar object with generated images for front and background.
	 */
	public function createFilledBar(empty:FlxColor, fill:FlxColor, showBorder:Bool = false, border:FlxColor = FlxColor.WHITE, borderSize:Int = 1):FlxBar
	{
		createColoredEmptyBar(empty, showBorder, border, borderSize);
		createColoredFilledBar(fill, showBorder, border, borderSize);
		return this;
	}

	/**
	 * Creates a solid-colour filled background for health bar in the given colour, with optional border.
	 *
	 * @param	empty			The color of the bar when empty in 0xAARRGGBB format (the background colour)
	 * @param	showBorder		Should the bar be outlined with a solid border?
	 * @param	border			The border colour in 0xAARRGGBB format
	 * @param   borderSize  The size of the border, in pixels.
	 * @return	This FlxBar object with generated image for rendering health bar background.
	 */
	public function createColoredEmptyBar(empty:FlxColor, showBorder:Bool = false, border:FlxColor = FlxColor.WHITE, borderSize:Int = 1):FlxBar
	{
		if (FlxG.render.tile)
		{
			var emptyKey:String = "empty: " + barWidth + "x" + barHeight + ":" + empty.toHexString();
			if (showBorder)
				emptyKey += ",border: " + border.toHexString() + "borderSize: " + borderSize;

			if (!FlxG.bitmap.checkCache(emptyKey))
			{
				var emptyBar:BitmapData = null;

				if (showBorder)
				{
					emptyBar = new BitmapData(barWidth, barHeight, true, border);
					emptyBar.fillRect(new Rectangle(borderSize, borderSize, barWidth - borderSize * 2, barHeight - borderSize * 2), empty);
				}
				else
				{
					emptyBar = new BitmapData(barWidth, barHeight, true, empty);
				}

				FlxG.bitmap.add(emptyBar, false, emptyKey);
			}

			frames = FlxG.bitmap.get(emptyKey).imageFrame;
		}
		else
		{
			if (showBorder)
			{
				_emptyBar = new BitmapData(barWidth, barHeight, true, border);
				_emptyBar.fillRect(new Rectangle(borderSize, borderSize, barWidth - borderSize * 2, barHeight - borderSize * 2), empty);
			}
			else
			{
				_emptyBar = new BitmapData(barWidth, barHeight, true, empty);
			}

			_emptyBarRect.setTo(0, 0, barWidth, barHeight);
			updateEmptyBar();
		}

		return this;
	}

	/**
	 * Creates a solid-colour filled foreground for health bar in the given colour, with optional border.
	 * @param	fill		The color of the bar when full in 0xAARRGGBB format (the foreground colour)
	 * @param	showBorder	Should the bar be outlined with a solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 * @param   borderSize  The size of the border, in pixels.
	 * @return	This FlxBar object with generated image for rendering actual values.
	 */
	public function createColoredFilledBar(fill:FlxColor, showBorder:Bool = false, border:FlxColor = FlxColor.WHITE, borderSize:Int = 1):FlxBar
	{
		if (FlxG.render.tile)
		{
			var filledKey:String = "filled: " + barWidth + "x" + barHeight + ":" + fill.toHexString();
			if (showBorder)
				filledKey += ",border: " + border.toHexString() + "borderSize: " + borderSize;

			if (!FlxG.bitmap.checkCache(filledKey))
			{
				var filledBar:BitmapData = null;

				if (showBorder)
				{
					filledBar = new BitmapData(barWidth, barHeight, true, border);
					filledBar.fillRect(new Rectangle(borderSize, borderSize, barWidth - borderSize * 2, barHeight - borderSize * 2), fill);
				}
				else
				{
					filledBar = new BitmapData(barWidth, barHeight, true, fill);
				}

				FlxG.bitmap.add(filledBar, false, filledKey);
			}

			frontFrames = FlxG.bitmap.get(filledKey).imageFrame;
		}
		else
		{
			if (showBorder)
			{
				_filledBar = new BitmapData(barWidth, barHeight, true, border);
				_filledBar.fillRect(new Rectangle(borderSize, borderSize, barWidth - borderSize * 2, barHeight - borderSize * 2), fill);
			}
			else
			{
				_filledBar = new BitmapData(barWidth, barHeight, true, fill);
			}

			_filledBarRect.setTo(0, 0, barWidth, barHeight);
			updateFilledBar();
		}
		return this;
	}

	/**
	 * Creates a gradient filled health bar using the given colour ranges, with optional border.
	 * All colour values are in 0xAARRGGBB format, so if you want a slightly transparent health bar give it lower AA values.
	 *
	 * @param	empty		Array of colour values used to create the gradient of the health bar when empty, each colour must be in 0xAARRGGBB format (the background colour)
	 * @param	fill		Array of colour values used to create the gradient of the health bar when full, each colour must be in 0xAARRGGBB format (the foreground colour)
	 * @param	chunkSize	If you want a more old-skool looking chunky gradient, increase this value!
	 * @param	rotation	Angle of the gradient in degrees. 90 = top to bottom, 180 = left to right. Any angle is valid
	 * @param	showBorder	Should the bar be outlined with a solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 * @param   borderSize  The size of the border, in pixels.
	 * @return 	This FlxBar object with generated images for front and background.
	 */
	public function createGradientBar(empty:Array<FlxColor>, fill:Array<FlxColor>, chunkSize:Int = 1, rotation:Int = 180, showBorder:Bool = false,
			border:FlxColor = FlxColor.WHITE, borderSize:Int = 1):FlxBar
	{
		createGradientEmptyBar(empty, chunkSize, rotation, showBorder, border, borderSize);
		createGradientFilledBar(fill, chunkSize, rotation, showBorder, border, borderSize);
		return this;
	}

	/**
	 * Creates a gradient filled background for health bar using the given colour range, with optional border.
	 *
	 * @param	empty			Array of colour values used to create the gradient of the health bar when empty, each colour must be in 0xAARRGGBB format (the background colour)
	 * @param	chunkSize		If you want a more old-skool looking chunky gradient, increase this value!
	 * @param	rotation		Angle of the gradient in degrees. 90 = top to bottom, 180 = left to right. Any angle is valid
	 * @param	showBorder		Should the bar be outlined with a solid border?
	 * @param	border			The border colour in 0xAARRGGBB format
	 * @param   borderSize  The size of the border, in pixels.
	 * @return 	This FlxBar object with generated image for background rendering.
	 */
	public function createGradientEmptyBar(empty:Array<FlxColor>, chunkSize:Int = 1, rotation:Int = 180, showBorder:Bool = false,
			border:FlxColor = FlxColor.WHITE, borderSize:Int = 1):FlxBar
	{
		if (FlxG.render.tile)
		{
			var emptyKey:String = "Gradient:" + barWidth + "x" + barHeight + ",colors:[";
			for (col in empty)
			{
				emptyKey += col.toHexString() + ",";
			}
			emptyKey += "],chunkSize: " + chunkSize + ",rotation: " + rotation;

			if (showBorder)
			{
				emptyKey += ",border: " + border.toHexString() + "borderSize: " + borderSize;
			}

			if (!FlxG.bitmap.checkCache(emptyKey))
			{
				var emptyBar:BitmapData = null;

				if (showBorder)
				{
					emptyBar = new BitmapData(barWidth, barHeight, true, border);
					FlxGradient.overlayGradientOnBitmapData(emptyBar, barWidth - borderSize * 2, barHeight - borderSize * 2, empty, borderSize, borderSize,
						chunkSize, rotation);
				}
				else
				{
					emptyBar = FlxGradient.createGradientBitmapData(barWidth, barHeight, empty, chunkSize, rotation);
				}

				FlxG.bitmap.add(emptyBar, false, emptyKey);
			}

			frames = FlxG.bitmap.get(emptyKey).imageFrame;
		}
		else
		{
			if (showBorder)
			{
				_emptyBar = new BitmapData(barWidth, barHeight, true, border);
				FlxGradient.overlayGradientOnBitmapData(_emptyBar, barWidth - borderSize * 2, barHeight - borderSize * 2, empty, borderSize, borderSize,
					chunkSize, rotation);
			}
			else
			{
				_emptyBar = FlxGradient.createGradientBitmapData(barWidth, barHeight, empty, chunkSize, rotation);
			}

			_emptyBarRect.setTo(0, 0, barWidth, barHeight);
			updateEmptyBar();
		}

		return this;
	}

	/**
	 * Creates a gradient filled foreground for health bar using the given colour range, with optional border.
	 *
	 * @param	fill		Array of colour values used to create the gradient of the health bar when full, each colour must be in 0xAARRGGBB format (the foreground colour)
	 * @param	chunkSize	If you want a more old-skool looking chunky gradient, increase this value!
	 * @param	rotation	Angle of the gradient in degrees. 90 = top to bottom, 180 = left to right. Any angle is valid
	 * @param	showBorder	Should the bar be outlined with a solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 * @param   borderSize  The size of the border, in pixels.
	 * @return 	This FlxBar object with generated image for rendering actual values.
	 */
	public function createGradientFilledBar(fill:Array<FlxColor>, chunkSize:Int = 1, rotation:Int = 180, showBorder:Bool = false,
			border:FlxColor = FlxColor.WHITE, borderSize:Int = 1):FlxBar
	{
		if (FlxG.render.tile)
		{
			var filledKey:String = "Gradient:" + barWidth + "x" + barHeight + ",colors:[";
			for (col in fill)
			{
				filledKey += col.toHexString() + ",";
			}
			filledKey += "],chunkSize: " + chunkSize + ",rotation: " + rotation;

			if (showBorder)
			{
				filledKey += ",border: " + border.toHexString() + "borderSize: " + borderSize;
			}

			if (!FlxG.bitmap.checkCache(filledKey))
			{
				var filledBar:BitmapData = null;

				if (showBorder)
				{
					filledBar = new BitmapData(barWidth, barHeight, true, border);
					FlxGradient.overlayGradientOnBitmapData(filledBar, barWidth - borderSize * 2, barHeight - borderSize * 2, fill, borderSize, borderSize,
						chunkSize, rotation);
				}
				else
				{
					filledBar = FlxGradient.createGradientBitmapData(barWidth, barHeight, fill, chunkSize, rotation);
				}

				FlxG.bitmap.add(filledBar, false, filledKey);
			}

			frontFrames = FlxG.bitmap.get(filledKey).imageFrame;
		}
		else
		{
			if (showBorder)
			{
				_filledBar = new BitmapData(barWidth, barHeight, true, border);
				FlxGradient.overlayGradientOnBitmapData(_filledBar, barWidth - borderSize * 2, barHeight - borderSize * 2, fill, borderSize, borderSize,
					chunkSize, rotation);
			}
			else
			{
				_filledBar = FlxGradient.createGradientBitmapData(barWidth, barHeight, fill, chunkSize, rotation);
			}

			_filledBarRect.setTo(0, 0, barWidth, barHeight);
			updateFilledBar();
		}

		return this;
	}

	/**
	 * Creates a health bar filled using the given bitmap images.
	 * You can provide "empty" (background) and "fill" (foreground) images. either one or both images (empty / fill), and use the optional empty/fill colour values
	 * All colour values are in 0xAARRGGBB format, so if you want a slightly transparent health bar give it lower AA values.
	 * NOTE: This method doesn't check if the empty image doesn't have the same size as fill image.
	 *
	 * @param	empty				Bitmap image used as the background (empty part) of the health bar, if null the emptyBackground colour is used
	 * @param	fill				Bitmap image used as the foreground (filled part) of the health bar, if null the fillBackground colour is used
	 * @param	emptyBackground		If no background (empty) image is given, use this colour value instead. 0xAARRGGBB format
	 * @param	fillBackground		If no foreground (fill) image is given, use this colour value instead. 0xAARRGGBB format
	 * @return	This FlxBar object with generated images for front and background.
	 */
	public function createImageBar(?empty:FlxGraphicAsset, ?fill:FlxGraphicAsset, emptyBackground:FlxColor = FlxColor.BLACK,
			fillBackground:FlxColor = FlxColor.LIME):FlxBar
	{
		createImageEmptyBar(empty, emptyBackground);
		createImageFilledBar(fill, fillBackground);
		return this;
	}

	/**
	 * Loads given bitmap image for health bar background.
	 *
	 * @param	empty				Bitmap image used as the background (empty part) of the health bar, if null the emptyBackground colour is used
	 * @param	emptyBackground		If no background (empty) image is given, use this colour value instead. 0xAARRGGBB format
	 * @return	This FlxBar object with generated image for background rendering.
	 */
	public function createImageEmptyBar(?empty:FlxGraphicAsset, emptyBackground:FlxColor = FlxColor.BLACK):FlxBar
	{
		if (empty != null)
		{
			var emptyGraphic:FlxGraphic = FlxG.bitmap.add(empty);

			if (FlxG.render.tile)
			{
				frames = emptyGraphic.imageFrame;
			}
			else
			{
				_emptyBar = emptyGraphic.bitmap.clone();

				barWidth = _emptyBar.width;
				barHeight = _emptyBar.height;

				_emptyBarRect.setTo(0, 0, barWidth, barHeight);

				if (graphic == null || (frame.sourceSize.x != barWidth || frame.sourceSize.y != barHeight))
				{
					makeGraphic(barWidth, barHeight, FlxColor.TRANSPARENT, true);
				}

				updateEmptyBar();
			}
		}
		else
		{
			createColoredEmptyBar(emptyBackground);
		}

		return this;
	}

	/**
	 * Loads given bitmap image for health bar foreground.
	 *
	 * @param	fill				Bitmap image used as the foreground (filled part) of the health bar, if null the fillBackground colour is used
	 * @param	fillBackground		If no foreground (fill) image is given, use this colour value instead. 0xAARRGGBB format
	 * @return	This FlxBar object with generated image for rendering actual values.
	 */
	public function createImageFilledBar(?fill:FlxGraphicAsset, fillBackground:FlxColor = FlxColor.LIME):FlxBar
	{
		if (fill != null)
		{
			var filledGraphic:FlxGraphic = FlxG.bitmap.add(fill);

			if (FlxG.render.tile)
			{
				frontFrames = filledGraphic.imageFrame;
			}
			else
			{
				_filledBar = filledGraphic.bitmap.clone();

				_filledBarRect.setTo(0, 0, barWidth, barHeight);

				if (graphic == null || (frame.sourceSize.x != barWidth || frame.sourceSize.y != barHeight))
				{
					makeGraphic(barWidth, barHeight, FlxColor.TRANSPARENT, true);
				}

				pxPerPercent = (_fillHorizontal) ? (barWidth / _maxPercent) : (barHeight / _maxPercent);
				updateFilledBar();
			}
		}
		else
		{
			createColoredFilledBar(fillBackground);
		}

		return this;
	}

	function set_fillDirection(direction:FlxBarFillDirection):FlxBarFillDirection
	{
		fillDirection = direction;

		switch (direction)
		{
			case LEFT_TO_RIGHT, RIGHT_TO_LEFT, HORIZONTAL_INSIDE_OUT, HORIZONTAL_OUTSIDE_IN:
				_fillHorizontal = true;

			case TOP_TO_BOTTOM, BOTTOM_TO_TOP, VERTICAL_INSIDE_OUT, VERTICAL_OUTSIDE_IN:
				_fillHorizontal = false;
		}

		return fillDirection;
	}

	function updateValueFromParent():Void
	{
		value = Reflect.getProperty(parent, parentVariable);
	}

	/**
	 * Updates health bar view according its current value.
	 * Called when the health bar detects a change in the health of the parent.
	 */
	public function updateBar():Void
	{
		updateEmptyBar();
		updateFilledBar();
	}

	/**
	 * Stamps health bar background on its pixels
	 */
	public function updateEmptyBar():Void
	{
		if (FlxG.render.blit)
		{
			pixels.copyPixels(_emptyBar, _emptyBarRect, _zeroOffset);
			dirty = true;
		}
	}

	/**
	 * Stamps health bar foreground on its pixels
	 */
	public function updateFilledBar():Void
	{
		_filledBarRect.width = barWidth;
		_filledBarRect.height = barHeight;

		var fraction:Float = (value - min) / range;
		var percent:Float = fraction * _maxPercent;
		var maxScale:Float = (_fillHorizontal) ? barWidth : barHeight;
		var interval:Float = continuous ? {
			fraction * maxScale;
		} : {
			var scaleInterval:Float = maxScale / numDivisions;
			Math.round(Std.int(fraction * maxScale / scaleInterval) * scaleInterval);
		}

		if (_fillHorizontal)
		{
			_filledBarRect.width = floorFunc(interval);
		}
		else
		{
			_filledBarRect.height = floorFunc(interval);
		}

		if (percent > 0)
		{
			switch (fillDirection)
			{
				case LEFT_TO_RIGHT, TOP_TO_BOTTOM:
				//	Already handled above

				case BOTTOM_TO_TOP:
					_filledBarRect.y = barHeight - _filledBarRect.height;
					_filledBarPoint.y = barHeight - _filledBarRect.height;

				case RIGHT_TO_LEFT:
					_filledBarRect.x = barWidth - _filledBarRect.width;
					_filledBarPoint.x = barWidth - _filledBarRect.width;

				case HORIZONTAL_INSIDE_OUT:
					_filledBarRect.x = floorFunc((barWidth * .5) - (_filledBarRect.width * .5));
					_filledBarPoint.x = floorFunc((barWidth * .5) - (_filledBarRect.width * .5));

				case HORIZONTAL_OUTSIDE_IN:
					_filledBarRect.width = floorFunc(maxScale - interval);
					_filledBarPoint.x = floorFunc((barWidth - _filledBarRect.width) * .5);

				case VERTICAL_INSIDE_OUT:
					_filledBarRect.y = floorFunc((barHeight * .5) - (_filledBarRect.height * .5));
					_filledBarPoint.y = floorFunc((barHeight * .5) - (_filledBarRect.height * .5));

				case VERTICAL_OUTSIDE_IN:
					_filledBarRect.height = floorFunc(maxScale - interval);
					_filledBarPoint.y = floorFunc((barHeight - _filledBarRect.height) * .5);
			}

			if (FlxG.render.blit)
			{
				pixels.copyPixels(_filledBar, _filledBarRect, _filledBarPoint, null, null, true);
			}
			else
			{
				if (frontFrames != null)
				{
					_filledFlxRect.copyFromFlash(_filledBarRect).round();
					_frontFrame = frontFrames.frame.clipTo(_filledFlxRect, _frontFrame);
				}
			}
		}

		if (FlxG.render.blit)
		{
			dirty = true;
		}
	}

	override public function update(elapsed:Float):Void
	{
		if (parent != null)
		{
			if (Reflect.getProperty(parent, parentVariable) != value)
			{
				updateValueFromParent();
			}

			if (!fixedPosition)
			{
				x = parent.x + positionOffset.x;
				y = parent.y + positionOffset.y;
			}
		}

		super.update(elapsed);
	}

	override public function draw():Void
	{
		super.draw();

		if (!FlxG.render.tile)
			return;

		if (alpha == 0)
			return;

		if (percent > 0 && _frontFrame.type != FlxFrameType.EMPTY)
		{
			for (camera in getCamerasLegacy())
			{
				if (!camera.visible || !camera.exists || !isOnScreen(camera))
				{
					continue;
				}

				_frontFrame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
				_matrix.translate(-origin.x, -origin.y);
				_matrix.scale(scale.x, scale.y);

				// rotate matrix if sprite's graphic isn't prerotated
				if (bakedRotationAngle <= 0)
				{
					updateTrig();

					if (angle != 0)
						_matrix.rotateWithTrig(_cosAngle, _sinAngle);
				}
				_matrix.concat(transform);

				getScreenPosition(_point, camera).subtract(offset);
				_point.add(origin.x, origin.y);
				_matrix.translate(_point.x, _point.y);

				if (isPixelPerfectRender(camera))
				{
					_matrix.tx = Math.floor(_matrix.tx);
					_matrix.ty = Math.floor(_matrix.ty);
				}

				camera.drawPixels(_frontFrame, _matrix, colorTransform, blend, antialiasing, shaderEnabled ? shader : null);
			}
		}
	}

	override function set_pixels(pixels:BitmapData):BitmapData
	{
		if (FlxG.render.tile)
		{
			return pixels; // hack
		}
		else
		{
			return super.set_pixels(pixels);
		}
	}

	override public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("min", min),
			LabelValuePair.weak("max", max),
			LabelValuePair.weak("range", range),
			LabelValuePair.weak("%", pct),
			LabelValuePair.weak("px/%", pxPerPercent),
			LabelValuePair.weak("value", value)
		]);
	}

	function get_percent():Float
	{
		if (value > max)
		{
			return _maxPercent;
		}

		return ((value - min) / range) * _maxPercent;
	}

	function get_floorPercent():Int
	{
		if (value > max)
		{
			return _maxPercent;
		}

		return Math.floor(((value - min) / range) * _maxPercent);
	}

	function set_percent(newPct:Float):Float
	{
		if (newPct >= 0 && newPct <= _maxPercent)
		{
			value = pct * newPct;
		}
		return newPct;
	}

	function set_value(newValue:Float):Float
	{
		value = Math.max(min, Math.min(newValue, max));

		if (value == min && emptyCallback != null)
		{
			emptyCallback();
		}

		if (value == max && filledCallback != null)
		{
			filledCallback();
		}

		if (value == min && killOnEmpty)
		{
			kill();
		}

		updateBar();
		return newValue;
	}

	function set_numDivisions(newValue:Int):Int
	{
		numDivisions = (newValue > 0) ? newValue : 100;
		updateFilledBar();
		return newValue;
	}

	function get_frontFrames():FlxImageFrame
	{
		if (FlxG.render.tile)
		{
			return frontFrames;
		}
		return null;
	}

	function set_frontFrames(value:FlxImageFrame):FlxImageFrame
	{
		if (FlxG.render.tile)
		{
			/*if (value != null)
				value.parent.incrementUseCount();

			if (frontFrames != null)
				frontFrames.parent.decrementUseCount();*/

			frontFrames = value;
			_frontFrame = (value != null) ? value.frame.copyTo(_frontFrame) : FlxDestroyUtil.destroy(_frontFrame);
		}
		else
		{
			createImageFilledBar(value.frame.paint());
		}
		return value;
	}

	function get_backFrames():FlxImageFrame
	{
		if (FlxG.render.tile)
		{
			return cast frames;
		}
		return null;
	}

	function set_backFrames(value:FlxImageFrame):FlxImageFrame
	{
		if (FlxG.render.tile)
		{
			frames = value;
		}
		else
		{
			createImageEmptyBar(value.frame.paint());
		}
		return value;
	}

	inline function floorFunc(x:Float):Float
	{
		return continuous ? x : Std.int(x);
	}

	@:noCompletion public var unbounded(get, set):Bool;

	@:noCompletion inline function get_unbounded()
		return continuous;

	@:noCompletion inline function set_unbounded(value:Bool):Bool
		return continuous = value;
}

enum FlxBarFillDirection
{
	LEFT_TO_RIGHT;
	RIGHT_TO_LEFT;
	TOP_TO_BOTTOM;
	BOTTOM_TO_TOP;
	HORIZONTAL_INSIDE_OUT;
	HORIZONTAL_OUTSIDE_IN;
	VERTICAL_INSIDE_OUT;
	VERTICAL_OUTSIDE_IN;
}
