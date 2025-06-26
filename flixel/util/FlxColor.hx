package flixel.util;

import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.system.macros.FlxMacroUtil;

/**
 * Class representing a color, based on Int. Provides a variety of methods for creating and converting colors.
 *
 * FlxColors can be written as Ints. This means you can pass a hex value such as
 * 0xff123456 to a function expecting a FlxColor, and it will automatically become a FlxColor "object".
 * Similarly, FlxColors may be treated as Ints.
 *
 * Note that when using properties of a FlxColor other than ARGB, the values are ultimately stored as
 * ARGB values, so repeatedly manipulating HSB/HSL/CMYK values may result in a gradual loss of precision.
 *
 * @author Joe Williamson (JoeCreates)
 */
abstract FlxColor(Int) from Int from UInt to Int to UInt {
	public static inline final TRANSPARENT:FlxColor = 0x00000000;
	public static inline final WHITE:FlxColor = 0xFFFFFFFF;
	public static inline final GRAY:FlxColor = 0xFF808080;
	public static inline final BLACK:FlxColor = 0xFF000000;

	public static inline final GREEN:FlxColor = 0xFF008000;
	public static inline final LIME:FlxColor = 0xFF00FF00;
	public static inline final YELLOW:FlxColor = 0xFFFFFF00;
	public static inline final ORANGE:FlxColor = 0xFFFFA500;
	public static inline final RED:FlxColor = 0xFFFF0000;
	public static inline final PURPLE:FlxColor = 0xFF800080;
	public static inline final BLUE:FlxColor = 0xFF0000FF;
	public static inline final BROWN:FlxColor = 0xFF8B4513;
	public static inline final PINK:FlxColor = 0xFFFFC0CB;
	public static inline final MAGENTA:FlxColor = 0xFFFF00FF;
	public static inline final CYAN:FlxColor = 0xFF00FFFF;

	/**
	 * A `Map<String, Int>` whose values are the static colors of `FlxColor`.
	 * You can add more colors for `FlxColor.fromString(String)` if you need.
	 */
	public static var colorLookup(default, null):Map<String, Int> = FlxMacroUtil.buildMap("flixel.util.FlxColor");

	public var red(get, set):Int;
	public var blue(get, set):Int;
	public var green(get, set):Int;
	public var alpha(get, set):Int;

	public var redFast(get, set):Int;
	public var blueFast(get, set):Int;
	public var greenFast(get, set):Int;
	public var alphaFast(get, set):Int;

	public var redFloat(get, set):Float;
	public var blueFloat(get, set):Float;
	public var greenFloat(get, set):Float;
	public var alphaFloat(get, set):Float;

	public var cyan(get, set):Float;
	public var magenta(get, set):Float;
	public var yellow(get, set):Float;
	public var black(get, set):Float;

	/**
	 * The red, green and blue channels of this color as a 24 bit integer (from 0 to 0xFFFFFF)
	 */
	public var rgb(get, set):FlxColor;

	/**
	 * The hue of the color in degrees (from 0 to 359)
	 */
	public var hue(get, set):Float;

	/**
	 * The saturation of the color (from 0 to 1)
	 */
	public var saturation(get, set):Float;

	/**
	 * The brightness (aka value) of the color (from 0 to 1)
	 */
	public var brightness(get, set):Float;

	/**
	 * The lightness of the color (from 0 to 1)
	 */
	public var lightness(get, set):Float;

	/**
	 * The luminance, or "percieved brightness" of a color (from 0 to 1)
	 * RGB -> Luma calculation from https://www.w3.org/TR/AERT/#color-contrast
	 */
	public var luminance(get, never):Float;

	static final COLOR_REGEX = ~/^(0x|#)(([A-F0-9]{2}){3,4})$/i;

	/**
	 * Create a color from the least significant four bytes of an Int
	 *
	 * @param	value And Int with bytes in the format 0xAARRGGBB
	 * @return	The color as a FlxColor
	 */
	public static inline function fromInt(value:Int):FlxColor {
		return new FlxColor(value);
	}

	/**
	 * Generate a color from integer RGB values (0 to 255)
	 *
	 * @param red	The red value of the color from 0 to 255
	 * @param green	The green value of the color from 0 to 255
	 * @param blue	The green value of the color from 0 to 255
	 * @param alpha	How opaque the color should be, from 0 to 255
	 * @return The color as a FlxColor
	 */
	public static inline function fromRGB(red:Int, green:Int, blue:Int, alpha = 255):FlxColor {
		var color = new FlxColor();
		return color.setRGB(red, green, blue, alpha);
	}

	public static inline function fromRGBFast(red:Int, green:Int, blue:Int, alpha = 255):FlxColor {
		var color = new FlxColor();
		return color.setRGBFast(red, green, blue, alpha);
	}

	public static inline function fromRGBUnsafe(red:Int, green:Int, blue:Int, alpha = 255):FlxColor {
		var color = new FlxColor();
		return color.setRGBUnsafe(red, green, blue, alpha);
	}

	/**
	 * Generate a color from float RGB values (0 to 1)
	 *
	 * @param red	The red value of the color from 0 to 1
	 * @param green	The green value of the color from 0 to 1
	 * @param blue	The green value of the color from 0 to 1
	 * @param alpha	How opaque the color should be, from 0 to 1
	 * @return The color as a FlxColor
	 */
	public static inline function fromRGBFloat(red:Float, green:Float, blue:Float, alpha = 1.):FlxColor {
		var color = new FlxColor();
		return color.setRGBFloat(red, green, blue, alpha);
	}

	/**
	 * Generate a color from CMYK values (0 to 1)
	 *
	 * @param cyan		The cyan value of the color from 0 to 1
	 * @param magenta	The magenta value of the color from 0 to 1
	 * @param yellow	The yellow value of the color from 0 to 1
	 * @param black		The black value of the color from 0 to 1
	 * @param alpha		How opaque the color should be, from 0 to 1
	 * @return The color as a FlxColor
	 */
	public static inline function fromCMYK(cyan:Float, magenta:Float, yellow:Float, black:Float, alpha = 1.):FlxColor {
		var color = new FlxColor();
		return color.setCMYK(cyan, magenta, yellow, black, alpha);
	}

	/**
	 * Generate a color from HSB (aka HSV) components.
	 *
	 * @param	hue			A number between 0 and 360, indicating position on a color strip or wheel.
	 * @param	saturation	A number between 0 and 1, indicating how colorful or gray the color should be.  0 is gray, 1 is vibrant.
	 * @param	brightness	(aka Value) A number between 0 and 1, indicating how bright the color should be.  0 is black, 1 is full bright.
	 * @param	alpha		How opaque the color should be, either between 0 and 1 or 0 and 255.
	 * @return	The color as a FlxColor
	 */
	public static function fromHSB(hue:Float, saturation:Float, brightness:Float, alpha = 1.):FlxColor {
		var color = new FlxColor();
		return color.setHSB(hue, saturation, brightness, alpha);
	}

	/**
	 * Generate a color from HSL components.
	 *
	 * @param	hue			A number between 0 and 360, indicating position on a color strip or wheel.
	 * @param	saturation	A number between 0 and 1, indicating how colorful or gray the color should be.  0 is gray, 1 is vibrant.
	 * @param	lightness	A number between 0 and 1, indicating the lightness of the color
	 * @param	alpha		How opaque the color should be, either between 0 and 1 or 0 and 255.
	 * @return	The color as a FlxColor
	 */
	public static inline function fromHSL(hue:Float, saturation:Float, lightness:Float, alpha = 1.):FlxColor {
		var color = new FlxColor();
		return color.setHSL(hue, saturation, lightness, alpha);
	}

	/**
	 * Parses a `String` and returns a `FlxColor` or `null` if the `String` couldn't be parsed.
	 *
	 * Examples (input -> output in hex):
	 *
	 * - `0x00FF00`    -> `0xFF00FF00`
	 * - `0xAA4578C2`  -> `0xAA4578C2`
	 * - `#0000FF`     -> `0xFF0000FF`
	 * - `#3F000011`   -> `0x3F000011`
	 * - `GRAY`        -> `0xFF808080`
	 * - `blue`        -> `0xFF0000FF`
	 *
	 * @param	str 	The string to be parsed
	 * @return	A `FlxColor` or `null` if the `String` couldn't be parsed
	 */
	public static function fromString(str:String):Null<FlxColor> {
		var result:Null<FlxColor> = null;
		str = StringTools.trim(str);

		if (COLOR_REGEX.match(str)) {
			final hexColor:String = "0x" + COLOR_REGEX.matched(2);
			result = new FlxColor(Std.parseInt(hexColor));
			if (hexColor.length == 8)
				result.alphaFloat = 1;
		} else {
			str = str.toUpperCase();
			if (colorLookup.exists(str)) result = new FlxColor(colorLookup.get(str)); // for better result checking

			for (key in colorLookup.keys())
				if (key.toUpperCase() == str) {
					result = new FlxColor(colorLookup.get(key));
					break;
				}
		}

		return result;
	}

	/**
	 * Get HSB color wheel values in an array which will be 360 elements in size
	 *
	 * @param	alpha Alpha value for each color of the color wheel, between 0 (transparent) and 255 (opaque)
	 * @return	HSB color wheel as Array of FlxColors
	 */
	public static function getHSBColorWheel(alpha = 255):Array<FlxColor> {
		return [for (c in 0...360) fromHSB(c, 1.0, 1.0, alpha)];
	}

	/**
	 * Get an interpolated color based on two different colors.
	 *
	 * @param 	color1 The first color
	 * @param 	color2 The second color
	 * @param 	factor Value from 0 to 1 representing how much to shift color1 toward color2
	 * @return	The interpolated color
	 */
	public static inline function interpolate(color1:FlxColor, color2:FlxColor, factor = .5):FlxColor {
		final r = Std.int((color2.red - color1.red) * factor + color1.red);
		final g = Std.int((color2.green - color1.green) * factor + color1.green);
		final b = Std.int((color2.blue - color1.blue) * factor + color1.blue);
		final a = Std.int((color2.alpha - color1.alpha) * factor + color1.alpha);

		return fromRGB(r, g, b, a);
	}

	/**
	 * Create a gradient from one color to another
	 *
	 * @param color1 The color to shift from
	 * @param color2 The color to shift to
	 * @param steps How many colors the gradient should have
	 * @param ease An optional easing function, such as those provided in FlxEase
	 * @return An array of colors of length steps, shifting from color1 to color2
	 */
	public static function gradient(color1:FlxColor, color2:FlxColor, steps:Int, ?ease:EaseFunction):Array<FlxColor> {
		final output = new Array<FlxColor>();

		ease ??= FlxEase.linear;

		for (step in 0...steps)
			output[step] = interpolate(color1, color2, ease(step / (steps - 1)));

		return output;
	}

	/**
	 * Divide the RGB channels of two FlxColors
	 */
	@:op(A / B)
	public static inline function divide(lhs:FlxColor, rhs:FlxColor):FlxColor {
		return FlxColor.fromRGBFloat(lhs.redFloat / rhs.redFloat, lhs.greenFloat / rhs.greenFloat, lhs.blueFloat / rhs.blueFloat);
	}

	/**
	 * Multiply the RGB channels of two FlxColors
	 */
	@:op(A * B)
	public static inline function multiply(lhs:FlxColor, rhs:FlxColor):FlxColor {
		return FlxColor.fromRGBFloat(lhs.redFloat * rhs.redFloat, lhs.greenFloat * rhs.greenFloat, lhs.blueFloat * rhs.blueFloat);
	}

	/**
	 * Add the RGB channels of two FlxColors
	 */
	@:op(A + B)
	public static inline function add(lhs:FlxColor, rhs:FlxColor):FlxColor {
		return FlxColor.fromRGB(lhs.red + rhs.red, lhs.green + rhs.green, lhs.blue + rhs.blue);
	}

	/**
	 * Subtract the RGB channels of one FlxColor from another
	 */
	@:op(A - B)
	public static inline function subtract(lhs:FlxColor, rhs:FlxColor):FlxColor {
		return FlxColor.fromRGB(lhs.red - rhs.red, lhs.green - rhs.green, lhs.blue - rhs.blue);
	}

	/**
	 * Returns a Complementary Color Harmony of this color.
	 * A complementary hue is one directly opposite the color given on the color wheel
	 *
	 * @return	The complimentary color
	 */
	public inline function getComplementHarmony():FlxColor {
		return fromHSB(FlxMath.wrapMax(Std.int(hue) + 180, 350), brightness, saturation, alphaFloat);
	}

	/**
	 * Returns an Analogous Color Harmony for the given color.
	 * An Analogous harmony are hues adjacent to each other on the color wheel
	 *
	 * @param	threshold Control how adjacent the colors will be (default +- 30 degrees)
	 * @return 	Object containing 3 properties: original (the original color), warmer (the warmer analogous color) and colder (the colder analogous color)
	 */
	public inline function getAnalogousHarmony(threshold = 30):Harmony {
		final warmer = fromHSB(FlxMath.wrapMax(Std.int(hue) - threshold, 350), saturation, brightness, alphaFloat);
		final colder = fromHSB(FlxMath.wrapMax(Std.int(hue) + threshold, 350), saturation, brightness, alphaFloat);

		return {original: this, warmer: warmer, colder: colder};
	}

	/**
	 * Returns an Split Complement Color Harmony for this color.
	 * A Split Complement harmony are the two hues on either side of the color's Complement
	 *
	 * @param	threshold Control how adjacent the colors will be to the Complement (default +- 30 degrees)
	 * @return 	Object containing 3 properties: original (the original color), warmer (the warmer analogous color) and colder (the colder analogous color)
	 */
	public inline function getSplitComplementHarmony(threshold = 30):Harmony {
		final oppositeHue = FlxMath.wrapMax(Std.int(hue) + 180, 350);
		final warmer:FlxColor = fromHSB(FlxMath.wrapMax(oppositeHue - threshold, 350), saturation, brightness, alphaFloat);
		final colder:FlxColor = fromHSB(FlxMath.wrapMax(oppositeHue + threshold, 350), saturation, brightness, alphaFloat);

		return {original: this, warmer: warmer, colder: colder};
	}

	/**
	 * Returns a Triadic Color Harmony for this color. A Triadic harmony are 3 hues equidistant
	 * from each other on the color wheel.
	 *
	 * @return 	Object containing 3 properties: color1 (the original color), color2 and color3 (the equidistant colors)
	 */
	public inline function getTriadicHarmony():TriadicHarmony {
		final triadic1:FlxColor = fromHSB(FlxMath.wrapMax(Std.int(hue) + 120, 359), saturation, brightness, alphaFloat);
		final triadic2:FlxColor = fromHSB(FlxMath.wrapMax(Std.int(triadic1.hue) + 120, 359), saturation, brightness, alphaFloat);

		return {color1: this, color2: triadic1, color3: triadic2};
	}

	/**
	 * Return a String representation of the color in the format
	 *
	 * @param alpha Whether to include the alpha value in the hex string
	 * @param prefix Whether to include "0x" prefix at start of string
	 * @return	A string of length 10 in the format 0xAARRGGBB
	 */
	public inline function toHexString(alpha = true, prefix = true):String {
		return (prefix ? "0x" : "") + (alpha ? StringTools.hex(alpha, 2) : "") + StringTools.hex(red, 2) + StringTools.hex(green, 2) + StringTools.hex(blue, 2);
	}

	/**
	 * Return a String representation of the color in the format #RRGGBB
	 *
	 * @return	A string of length 7 in the format #RRGGBB
	 */
	public inline function toWebString():String {
		return "#" + toHexString(false, false);
	}

	/**
	 * Get a string of color information about this color
	 *
	 * @return A string containing information about this color
	 */
	public function getColorInfo():String {
		// Hex format
		var result = toHexString() + "\n";
		// RGB format
		result += "Alpha: " + alpha + " Red: " + red + " Green: " + green + " Blue: " + blue + "\n";
		// HSB/HSL info
		result += "Hue: " + FlxMath.roundDecimal(hue, 2) + " Saturation: " + FlxMath.roundDecimal(saturation, 2) + " Brightness: "
			+ FlxMath.roundDecimal(brightness, 2) + " Lightness: " + FlxMath.roundDecimal(lightness, 2);

		return result;
	}

	/**
	 * Get a darkened version of this color
	 *
	 * @param	factor Value from 0 to 1 of how much to progress toward black.
	 * @return 	A darkened version of this color
	 */
	public function getDarkened(factor = .2):FlxColor {
		factor = FlxMath.bound(factor, 0, 1);

		var output:FlxColor = this;
		output.lightness = output.lightness * (1 - factor);
		return output;
	}

	/**
	 * Get a lightened version of this color
	 *
	 * @param	factor Value from 0 to 1 of how much to progress toward white.
	 * @return 	A lightened version of this color
	 */
	public inline function getLightened(factor = .2):FlxColor {
		factor = FlxMath.bound(factor, 0, 1);

		var output:FlxColor = this;
		output.lightness = output.lightness + (1 - lightness) * factor;
		return output;
	}

	/**
	 * Get the inversion of this color
	 *
	 * @return The inversion of this color
	 */
	public inline function getInverted():FlxColor {
		final oldAlpha = alpha;
		var output:FlxColor = FlxColor.WHITE - this;
		output.alpha = oldAlpha;
		return output;
	}

	/**
	 * Set RGB values as integers (0 to 255)
	 *
	 * @param red	The red value of the color from 0 to 255
	 * @param green	The green value of the color from 0 to 255
	 * @param blue	The blue value of the color from 0 to 255
	 * @param alpha	How opaque the color should be, from 0 to 255
	 * @return This color
	 */
	public inline function setRGB(red:Int, green:Int, blue:Int, alpha = 255):FlxColor {
		this = (boundChannel(red) & 0xFF) << 16 | (boundChannel(green) & 0xFF) << 8 | (boundChannel(blue) & 0xFF) | (boundChannel(alpha) & 0xFF) << 24;
		return this;
	}

	public inline function setRGBFast(red:Int, green:Int, blue:Int, alpha = 255):FlxColor {
		this = (red & 0xFF) << 16 | (green & 0xFF) << 8 | (blue & 0xFF) | (alpha & 0xFF) << 24;
		return this;
	}

	public inline function setRGBUnsafe(red:Int, green:Int, blue:Int, alpha = 255):FlxColor {
		this = (red) << 16 | (green) << 8 | (blue) | (alpha) << 24;
		return this;
	}

	/**
	 * Set RGB values as floats (0 to 1)
	 *
	 * @param red	The red value of the color from 0 to 1
	 * @param green	The green value of the color from 0 to 1
	 * @param blue	The blue value of the color from 0 to 1
	 * @param alpha	How opaque the color should be, from 0 to 1
	 * @return This color
	 */
	public inline function setRGBFloat(red:Float, green:Float, blue:Float, alpha = 1.):FlxColor {
		this = setRGB(Std.int(red * 255), Std.int(green * 255), Std.int(blue * 255), Std.int(alpha * 255));
		return this;
	}

	/**
	 * Set CMYK values as floats (0 to 1)
	 *
	 * @param cyan		The cyan value of the color from 0 to 1
	 * @param magenta	The magenta value of the color from 0 to 1
	 * @param yellow	The yellow value of the color from 0 to 1
	 * @param black		The black value of the color from 0 to 1
	 * @param alpha		How opaque the color should be, from 0 to 1
	 * @return This color
	 */
	public inline function setCMYK(cyan:Float, magenta:Float, yellow:Float, black:Float, alpha:Float = 1):FlxColor {
		redFloat = (1 - cyan) * (1 - black);
		greenFloat = (1 - magenta) * (1 - black);
		blueFloat = (1 - yellow) * (1 - black);
		alphaFloat = alpha;
		return this;
	}

	/**
	 * Set HSB (aka HSV) components
	 *
	 * @param	hue			A number between 0 and 360, indicating position on a color strip or wheel.
	 * @param	saturation	A number between 0 and 1, indicating how colorful or gray the color should be.  0 is gray, 1 is vibrant.
	 * @param	brightness	(aka Value) A number between 0 and 1, indicating how bright the color should be.  0 is black, 1 is full bright.
	 * @param	alpha		How opaque the color should be, either between 0 and 1 or 0 and 255.
	 * @return	This color
	 */
	public inline function setHSB(hue:Float, saturation:Float, brightness:Float, alpha = 1.):FlxColor {
		final chroma = brightness * saturation;
		final match = brightness - chroma;
		return setHueChromaMatch(hue, chroma, match, alpha);
	}

	/**
	 * Set HSL components.
	 *
	 * @param	hue			A number between 0 and 360, indicating position on a color strip or wheel.
	 * @param	saturation	A number between 0 and 1, indicating how colorful or gray the color should be.  0 is gray, 1 is vibrant.
	 * @param	lightness	A number between 0 and 1, indicating the lightness of the color
	 * @param	alpha		How opaque the color should be, either between 0 and 1 or 0 and 255
	 * @return	This color
	 */
	public inline function setHSL(hue:Float, saturation:Float, lightness:Float, alpha = 1.):FlxColor {
		final chroma = (1 - Math.abs(2 * lightness - 1)) * saturation;
		final match = lightness - chroma * .5;
		return setHueChromaMatch(hue, chroma, match, alpha);
	}

	/**
	 * Private utility function to perform common operations between setHSB and setHSL
	 */
	inline function setHueChromaMatch(hue:Float, chroma:Float, match:Float, alpha:Float):FlxColor {
		hue %= 360;
		final hueD = hue / 60;
		final mid = chroma * (1 - Math.abs(hueD % 2 - 1)) + match;
		chroma += match;

		switch (Std.int(hueD)) {
			case 0: setRGBFloat(chroma, mid, match, alpha);
			case 1: setRGBFloat(mid, chroma, match, alpha);
			case 2: setRGBFloat(match, chroma, mid, alpha);
			case 3: setRGBFloat(match, mid, chroma, alpha);
			case 4: setRGBFloat(mid, match, chroma, alpha);
			case 5: setRGBFloat(chroma, match, mid, alpha);
		}

		return this;
	}

	public function new(value = 0) {
		this = value;
	}

	inline function getThis():Int {
		return this;
	}

	inline function get_red():Int {
		return (getThis() >> 16) & 0xff;
	}

	inline function get_redFast():Int {
		return (getThis() >> 16) & 0xFF;
	}

	inline function get_green():Int {
		return (getThis() >> 8) & 0xff;
	}

	inline function get_greenFast():Int {
		return (getThis() >> 8) & 0xFF;
	}

	inline function get_blue():Int {
		return getThis() & 0xff;
	}

	inline function get_blueFast():Int {
		return getThis() & 0xFF;
	}

	inline function get_alpha():Int {
		return (getThis() >> 24) & 0xff;
	}

	inline function get_alphaFast():Int {
		return (getThis() >> 24) & 0xFF;
	}

	inline function get_redFloat():Float {
		return red / 255;
	}

	inline function get_greenFloat():Float {
		return green / 255;
	}

	inline function get_blueFloat():Float {
		return blue / 255;
	}

	inline function get_alphaFloat():Float {
		return alpha / 255;
	}

	inline function set_red(value:Int):Int {
		this = (this & 0xFF00FFFF) | (boundChannel(value)) << 16;
		return value;
	}

	inline function set_green(value:Int):Int {
		this = (this & 0xFFFF00FF) | (boundChannel(value)) << 8;
		return value;
	}

	inline function set_blue(value:Int):Int {
		this = (this & 0xFFFFFF00) | (boundChannel(value));
		return value;
	}

	inline function set_alpha(value:Int):Int {
		this = (this & 0x00FFFFFF) | (boundChannel(value)) << 24;
		return value;
	}

	inline function set_redFast(value:Int):Int {
		this = (this & 0xFF00FFFF) | ((value & 0xFF)) << 16;
		return value;
	}

	inline function set_greenFast(value:Int):Int {
		this = (this & 0xFFFF00FF) | ((value & 0xFF) << 8);
		return value;
	}

	inline function set_blueFast(value:Int):Int {
		this = (this & 0xFFFFFF00) | ((value & 0xFF));
		return value;
	}

	inline function set_alphaFast(value:Int):Int {
		this = (this & 0xFF000000) | ((value & 0xFF) << 24);
		return value;
	}

	inline function set_redFloat(value:Float):Float {
		red = Math.round(value * 255);
		return value;
	}

	inline function set_greenFloat(value:Float):Float {
		green = Math.round(value * 255);
		return value;
	}

	inline function set_blueFloat(value:Float):Float {
		blue = Math.round(value * 255);
		return value;
	}

	inline function set_alphaFloat(value:Float):Float {
		alpha = Math.round(value * 255);
		return value;
	}

	inline function get_cyan():Float {
		final r = redFloat;
		final g = greenFloat;
		final b = blueFloat;
		final bri = Math.max(r, Math.max(g, b));
		final blck = 1 - bri;
		return (1 - r - blck) / bri;
	}

	inline function get_magenta():Float {
		final r = redFloat;
		final g = greenFloat;
		final b = blueFloat;
		final bri = Math.max(r, Math.max(g, b));
		final blck = 1 - bri;
		return (1 - g - blck) / bri;
	}

	inline function get_yellow():Float {
		final r = redFloat;
		final g = greenFloat;
		final b = blueFloat;
		final bri = Math.max(r, Math.max(g, b));
		final blck = 1 - bri;
		return (1 - b - blck) / bri;
	}

	inline function get_black():Float {
		return 1 - brightness;
	}

	inline function set_cyan(value:Float):Float {
		setCMYK(value, magenta, yellow, black, alphaFloat);
		return value;
	}

	inline function set_magenta(value:Float):Float {
		setCMYK(cyan, value, yellow, black, alphaFloat);
		return value;
	}

	inline function set_yellow(value:Float):Float {
		setCMYK(cyan, magenta, value, black, alphaFloat);
		return value;
	}

	inline function set_black(value:Float):Float {
		setCMYK(cyan, magenta, yellow, value, alphaFloat);
		return value;
	}

	function get_hue():Float {
		final r = redFloat;
		final g = greenFloat;
		final b = blueFloat;

		final max = Math.max(r, Math.max(g, b));
		final min = Math.min(r, Math.min(g, b));

		var h = .0;

		if (max != min) {
			final d = max - min;
			if (max == r) h = (g - b) / d + (g < b ? 6 : 0);
			else if (max == g) h = (b - r) / d + 2;
			else if (max == b) h = (r - g) / d + 4;
			h /= 6;
		}

		return h * 360;
	}

	// old version of get_hue(), inaccurate and slow
	function get_hueOld():Float {
 		// 1.7320508075688772 = Math.sqrt(3)
 		final hueRad = Math.atan2(1.7320508075688772 * (greenFloat - blueFloat), 2 * redFloat - greenFloat - blueFloat);
		final hue = (hueRad != 0) ? flixel.math.FlxAngle.TO_DEG * hueRad : 0;
		return hue < 0 ? hue + 360 : hue;
	}

	inline function get_brightness():Float {
		return maxColor();
	}

	inline function get_luminance():Float {
		return (redFloat * 299 + greenFloat * 587 + blueFloat * 114) * .001;
	}

	inline function get_saturation():Float {
		final r = redFloat;
		final g = greenFloat;
		final b = blueFloat;
		final max = Math.max(r, Math.max(g, b));
		final min = Math.min(r, Math.min(g, b));
		return (max - min) / max;
	}

	inline function get_lightness():Float {
		final r = redFloat;
		final g = greenFloat;
		final b = blueFloat;
		final max = Math.max(r, Math.max(g, b));
		final min = Math.min(r, Math.min(g, b));
		return (max + min) * .5;
	}

	inline function set_hue(value:Float):Float {
		setHSB(value, saturation, brightness, alphaFloat);
		return value;
	}

	inline function set_saturation(value:Float):Float {
		setHSB(hue, value, brightness, alphaFloat);
		return value;
	}

	inline function set_brightness(value:Float):Float {
		setHSB(hue, saturation, value, alphaFloat);
		return value;
	}

	inline function set_lightness(value:Float):Float {
		setHSL(hue, saturation, value, alphaFloat);
		return value;
	}

	inline function set_rgb(value:FlxColor):FlxColor {
		this = (this & 0xff000000) | (value & 0x00ffffff);
		return value;
	}

	inline function get_rgb():FlxColor {
		return this & 0x00ffffff;
	}

	inline function maxColor():Float {
		return Math.max(redFloat, Math.max(greenFloat, blueFloat));
	}

	inline function minColor():Float {
		return Math.min(redFloat, Math.min(greenFloat, blueFloat));
	}

	inline function boundChannel(value:Int):Int {
		#if cpp
		final v = value;
		return untyped __cpp__("((({0}) > 0xff) ? 0xff : (({0}) < 0) ? 0 : ({0}))", v);
		#else
		return value > 0xff ? 0xff : value < 0 ? 0 : value;
		#end
	}
}

typedef Harmony = {original:FlxColor, warmer:FlxColor, colder:FlxColor}
typedef TriadicHarmony = {color1:FlxColor, color2:FlxColor, color3:FlxColor}
