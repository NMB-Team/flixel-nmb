package flixel.util;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.system.FlxAssets;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.typeLimit.OneOfTwo;
import openfl.display.BitmapData;

using StringTools;

/**
 * A class primarily containing functions related
 * to formatting different data types to strings.
 */
class FlxStringUtil {
	/**
	 * Takes two "ticks" timestamps and formats them into the number of seconds that passed as a String.
	 * Useful for logging, debugging, the watch window, or whatever else.
	 *
	 * @param	startTicks	The first timestamp from the system.
	 * @param	endTicks	The second timestamp from the system.
	 * @return	A String containing the formatted time elapsed information.
	 */
	public static inline function formatTicks(startTicks:Int, endTicks:Int):String {
		return (Math.abs(endTicks - startTicks) * .001) + "s";
	}

	/**
	 * Format seconds as minutes with a colon, an optionally with milliseconds too.
	 *
	 * @param	seconds		The number of seconds (for example, time remaining, time spent, etc).
	 * @param	showMS		Whether to show milliseconds after a "." as well.  Default value is false.
	 * @return	A nicely formatted String, like "1:03".
	 */
	public static function formatTime(seconds:Float, showMS = false):String {
		var timeString = Std.int(seconds / 60) + ":";
		var timeStringHelper = Std.int(seconds) % 60;
		if (timeStringHelper < 10) timeString += "0";

		timeString += timeStringHelper;

		if (showMS) {
			timeString += ".";

			timeStringHelper = Std.int((seconds - Std.int(seconds)) * 100);
			if (timeStringHelper < 10)
				timeString += "0";

			timeString += timeStringHelper;
		}

		return timeString;
	}

	/**
	 * Add leading zeros to a string until it reaches the specified length.
	 *
	 * @param str The string to add zeros to.
	 * @param num The desired length of the string.
	 */
	public static function addZeros(str:String, num:Int) {
		while (str.length < num) str = '0${str}';
		return str;
	}

	/**
	 * Add trailing zeros to a string until it reaches the specified length.
	 *
	 * @param str The string to add zeros to.
	 * @param num The desired length of the string.
	 */
	public static function addEndZeros(str:String, num:Int) {
		while (str.length < num) str = '${str}0';
		return str;
	}

	/**
	 * Checks if a single-character string is a letter character.
	 * The check is Unicode-aware, so it works with accented letters, etc.
	 */
	public static function isLetter(c:String) {
		final ascii = StringTools.fastCodeAt(c, 0);
		return (ascii >= 65 && ascii <= 90) || (ascii >= 97 && ascii <= 122) || (ascii >= 192 && ascii <= 214) || (ascii >= 216 && ascii <= 246)
			|| (ascii >= 248 && ascii <= 255);
	}

	/**
	 * Generate a comma-separated string from an array.
	 * Especially useful for tracing or other debug output.
	 *
	 * @param	anyArray	Any Array object.
	 * @return	A comma-separated String containing the .toString() output of each element in the array.
	 */
	public static function formatArray(anyArray:Array<Dynamic>):String {
		var string = "";
		if (anyArray != null && anyArray.length > 0) {
			string = Std.string(anyArray[0]);

			var i = 1;
			final l = anyArray.length;
			while (i < l)
				string += ", " + Std.string(anyArray[i++]);
		}
		return string;
	}

	/**
	 * Generate a comma-separated string representation of the keys of a StringMap.
	 *
	 * @param  anyMap    A StringMap object.
	 * @return  A String formatted like this: key1, key2, ..., keyX
	 */
	public static function formatStringMap(anyMap:Map<String, Dynamic>):String {
		var string = "";
		for (key in anyMap.keys()) {
			string += Std.string(key);
			string += ", ";
		}

		return string.substring(0, string.length - 2);
	}

	/**
	 * Automatically commas and decimals in the right places for displaying money amounts.
	 * Does not include a dollar sign or anything, so doesn't really do much
	 * if you call say `FlxString.formatMoney(10, false)`.
	 * However, very handy for displaying large sums or decimal money values.
	 *
	 * @param	amount			How much moneys (in dollars, or the equivalent "main" currency - i.e. not cents).
	 * @param	showDecimal		Whether to show the decimals/cents component.
	 * @param	englishStyle	Major quantities (thousands, millions, etc) separated by commas, and decimal by a period.
	 * @return	A nicely formatted String. Does not include a dollar sign or anything!
	 */
	public static function formatMoney(amount:Float, showDecimal = true, englishStyle = true):String {
		final isNegative = amount < 0;
		amount = Math.abs(amount);

		var string = "";
		var comma = "";
		var amount = Math.ffloor(amount);
		while (amount > 0) {
			if (string.length > 0 && comma.length <= 0)
				comma = (englishStyle ? "," : ".");

			var zeroes = "";
			final helper = amount - Math.ffloor(amount * .001) * 1000;
			amount = Math.ffloor(amount * .001);
			if (amount > 0) {
				if (helper < 100) zeroes += "0";
				if (helper < 10) zeroes += "0";
			}
			string = zeroes + helper + comma + string;
		}

		if (string == "") string = "0";

		if (showDecimal) {
			amount = Math.ffloor(amount * 100) - (Math.ffloor(amount) * 100);
			string += (englishStyle ? "." : ",");
			if (amount < 10) string += "0";
			string += amount;
		}

		if (isNegative) string = "-" + string;

		return string;
	}

	/**
	 * Takes an amount of bytes and finds the fitting unit. Makes sure that the
	 * value is below 1024. Example: formatBytes(123456789); -> 117.74MB
	 */
	public static function formatBytes(bytes:Float, ?precision = 2):String {
		final units = ["Bytes", "KB", "MB", "GB", "TB", "PB"];
		var curUnit = 0;
		while (bytes >= 1024 && curUnit < units.length - 1) {
			bytes /= 1024;
			curUnit++;
		}

		return '${FlxMath.roundDecimal(bytes, precision)} ${units[curUnit]}';
	}

	/**
	 * Converts large numbers to a human-readable format.
	 * Example: 1500 -> "1.5K", 1200000 -> "1.2M"
	 */
	public static function humanizeNumber(n:Float, decimals = 1):String {
		final suffixes = ["", "K", "M", "B", "T"];
		var i = 0;
		while (n >= 1000 && i < suffixes.length - 1) {
			n *= .001;
			i++;
		}

		return FlxMath.roundDecimal(n, decimals) + suffixes[i];
	}

	/**
	 * Takes a string and filters out everything but the digits.
	 *
	 * @param 	Input	The input string
	 * @return 	The output string, digits-only
	 */
	public static function filterDigits(Input:String):String {
		final output = new StringBuf();
		for (i in 0...Input.length) {
			final c = Input.charCodeAt(i);
			if (c >= '0'.code && c <= '9'.code)
				output.addChar(c);
		}

		return output.toString();
	}

	/**
	 * Format a text with html tags - useful for TextField.htmlText.
	 * Used by the log window of the debugger.
	 *
	 * @param	text		The text to format
	 * @param	size		The text size, using the font-size-tag
	 * @param	color		The text color, using font-color-tag
	 * @param	bold		Whether the text should be bold (b-tag)
	 * @param	italic		Whether the text should be italic (i-tag)
	 * @param	underlined 	Whether the text should be underlined (u-tag)
	 * @return	The html-formatted text.
	 */
	public static function htmlFormat(text:String, size = 12, color = "FFFFFF", bold = false, italic = false, underlined = false):String {
		var prefix = "<font size='" + size + "' color='#" + color + "'>";
		var suffix = "</font>";

		if (bold) {
			prefix = "<b>" + prefix;
			suffix = suffix + "</b>";
		}

		if (italic) {
			prefix = "<i>" + prefix;
			suffix = suffix + "</i>";
		}

		if (underlined) {
			prefix = "<u>" + prefix;
			suffix = suffix + "</u>";
		}

		return prefix + text + suffix;
	}

	/**
	 * Converts a string to a URL-safe, lowercase, hyphenated format.
	 * Example: "Hello World!" -> "hello-world"
	 */
	public static function slugify(str:String):String {
		var s = str.toLowerCase().trim();

		s = ~/[^a-z0-9]+/gi.replace(s, "-");
		s = ~/^-+|-+$/g.replace(s, "");

		return s;
	}

	/**
	 * Get the string name of any class or class instance. Wraps `Type.getClassName()`.
	 *
	 * @param	objectOrClass	The class or class instance in question.
	 * @param	simple	Returns only the type name, without package(s).
	 * @return	The name of the class as a string.
	 */
	public static function getClassName(objectOrClass:Dynamic, simple = false):String {
		var cl:Class<Dynamic>;
		if ((objectOrClass is Class)) cl = cast objectOrClass;
		else cl = Type.getClass(objectOrClass);

		return formatPackage(Type.getClassName(cl), simple);
	}

	/**
	 * Get the string name of any enum or enum value. Wraps `Type.getEnumName()`.
	 *
	 * @param	enumValueOrEnum	The enum value or enum in question.
	 * @param	simple	Returns only the type name, without package(s).
	 * @return	The name of the enum as a string.
	 * @since 4.4.0
	 */
	public static function getEnumName(enumValueOrEnum:OneOfTwo<EnumValue, Enum<Dynamic>>, simple = false):String {
		var e:Enum<Dynamic>;
		if ((enumValueOrEnum is Enum)) e = cast enumValueOrEnum;
		else e = Type.getEnum(enumValueOrEnum);

		return formatPackage(Type.getEnumName(e), simple);
	}

	/**
	 * Take a fully qualified class name and simplify it to just the class name,
	 * optionally including the package name.
	 *
	 * @param	s	The fully qualified class name.
	 * @param	simple	Whether to strip the package name or not.
	 * @return	The simplified class name.
	 */
	public static function formatPackage(s:String, simple:Bool):String {
		if (s == null) return null;

		s = s.replace("::", ".");
		if (simple) s = s.substr(s.lastIndexOf(".") + 1);

		return s;
	}

	/**
	 * Returns the host from the specified URL.
	 * The host is one of three parts that comprise the authority.  (User and port are the other two parts.)
	 * For example, the host for "ftp://anonymous@ftp.domain.test:990/" is "ftp.domain.test".
	 *
	 * @return	The host from the URL; or the empty string ("") upon failure.
	 * @since 4.3.0
	 */
	public static function getHost(url:String):String {
		final hostFromURL:EReg = ~/^(?:[a-z][a-z0-9+\-.]*:\/\/)?(?:[a-z0-9\-._~%!$&'()*+,;=]+@)?([a-z0-9\-._~%]{3,}|\[[a-f0-9:.]+\])?(?::[0-9]+)?/i;
		if (hostFromURL.match(url)) {
			final host = hostFromURL.matched(1);
			return (host != null) ? host.urlDecode().toLowerCase() : "";
		}

		return "";
	}

	/**
	 * Returns the domain from the specified URL.
	 * The domain, in this case, refers specifically to the first and second levels only.
	 * For example, the domain for "api.haxe.org" is "haxe.org".
	 *
	 * @return	The domain from the URL; or the empty string ("") upon failure.
	 */
	public static function getDomain(url:String):String {
		final host = getHost(url);

		final isLocalhostOrIpAddress:EReg = ~/^(localhost|[0-9.]+|\[[a-f0-9:.]+\])$/i;
		final domainFromHost:EReg = ~/^(?:[a-z0-9\-]+\.)*([a-z0-9\-]+\.[a-z0-9\-]+)$/i;
		if (!isLocalhostOrIpAddress.match(host) && domainFromHost.match(host)) {
			final domain = domainFromHost.matched(1);
			return (domain != null) ? domain.toLowerCase() : "";
		}

		return "";
	}

	/**
	 * A regex to match valid URLs.
	 */
	public static final URL_REGEX = ~/^https?:\/?\/?(?:www\.)?[-a-zA-Z0-9@:%_\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$/;

	/**
	 * Sanitizes a URL via a regex.
	 *
	 * @param targetUrl The URL to sanitize.
	 * @return The sanitized URL, or an empty string if the URL is invalid.
	 */
	public static function sanitizeURL(targetUrl:String):String {
		targetUrl = (targetUrl ?? '').trim();
		if (isNullOrEmpty(targetUrl)) return '';

		final lowerUrl = targetUrl.toLowerCase();
		if (!lowerUrl.startsWith('http:') && !lowerUrl.startsWith('https:'))
			targetUrl = 'http://' + targetUrl;

		if (URL_REGEX.match(targetUrl))
			return URL_REGEX.matched(0);

		return '';
	}

	/**
	 * Generates a short visual hash of a string, useful for debug tags or identifiers.
	 */
	public static function shortHash(str:String, length = 6):String {
		var hash = 0;
		for (i in 0...str.length) {
			hash = (hash << 5) - hash + str.charCodeAt(i);
			hash = hash & hash; // convert to 32bit int
		}

		final hex = StringTools.hex(hash >>> 0, 8);
		return hex.substr(0, length);
	}

	/**
	 * Helper function that uses getClassName to compare two objects' class names.
	 *
	 * @param	obj1	The first object
	 * @param	obj2	The second object
	 * @param	simple 	Only uses the class name, not the package or packages.
	 * @return	Whether they have the same class name or not
	 */
	public static inline function sameClassName(obj1:Dynamic, obj2:Dynamic, simple = true):Bool {
		return (getClassName(obj1, simple) == getClassName(obj2, simple));
	}

	/**
	 * Split a comma-separated string into an array of ints
	 *
	 * @param	data 	String formatted like this: "1, 2, 5, -10, 120, 27"
	 * @return	An array of ints
	 */
	public static function toIntArray(data:String):Array<Int> {
		if (!isNullOrEmpty(data)) {
			final strArray = data.split(",");
			final iArray:Array<Int> = [];
			for (str in strArray)
				iArray.push(Std.parseInt(str));

			return iArray;
		}
		return null;
	}

	/**
	 * Split a comma-separated string into an array of floats
	 *
	 * @param	data string formatted like this: "1.0,2.1,5.6,1245587.9, -0.00354"
	 * @return	An array of floats
	 */
	public static function toFloatArray(data:String):Array<Float> {
		if (!isNullOrEmpty(data)) {
			final strArray = data.split(",");
			final fArray:Array<Float> = [];
			for (str in strArray)
				fArray.push(Std.parseFloat(str));

			return fArray;
		}
		return null;
	}

	/**
	 * Converts a one-dimensional array of tile data to a comma-separated string.
	 *
	 * @param	data		An array full of integer tile references.
	 * @param	width		The number of tiles in each row.
	 * @param	invert		Recommended only for 1-bit arrays - changes 0s to 1s and vice versa.
	 * @return	A comma-separated string containing the level data in a FlxTilemap-friendly format.
	 */
	public static function arrayToCSV(data:Array<Int>, width:Int, invert = false):String {
		final height = Std.int(data.length / width);
		var row = 0;
		var offset = 0;
		var csv = "";
		var index:Int, column:Int;

		while (row < height) {
			column = 0;

			while (column < width) {
				index = data[offset];

				if (invert) {
					if (index == 0) index = 1;
					else if (index == 1) index = 0;
				}

				if (column == 0) csv += (row != 0) ? "\n" : "" + index;
				else csv += ", " + index;

				column++;
				offset++;
			}

			row++;
		}

		return csv;
	}

	/**
	 * Converts a BitmapData object to a comma-separated string. Black pixels are flagged as 'solid' by default,
	 * non-black pixels are set as non-colliding. Black pixels must be PURE BLACK.
	 *
	 * @param	bitmap		A Flash BitmapData object, preferably black and white.
	 * @param	invert		Load white pixels as solid instead.
	 * @param	scale		Default is 1. Scale of 2 means each pixel forms a 2x2 block of tiles, and so on.
	 * @param	colorMap	An array of color values (alpha values are ignored) in the order they're intended to be assigned as indices
	 * @return	A comma-separated string containing the level data in a FlxTilemap-friendly format.
	 */
	public static function bitmapToCSV(bitmap:BitmapData, invert = false, scale = 1, ?colorMap:Array<FlxColor>):String {
		if (scale < 1) scale = 1;

		// Import and scale image if necessary
		if (scale > 1) {
			final bd = bitmap;
			bitmap = new BitmapData(bd.width * scale, bd.height * scale);

			final bdW = bd.width;
			final bdH = bd.height;
			var pCol = 0;

			for (i in 0...bdW)
				for (j in 0...bdH) {
					pCol = bd.getPixel(i, j);

					for (k in 0...scale)
						for (m in 0...scale)
							bitmap.setPixel(i * scale + k, j * scale + m, pCol);
				}
		}

		if (colorMap != null)
			for (i in 0...colorMap.length)
				colorMap[i] = colorMap[i].rgb;

		// Walk image and export pixel values

		var row = 0;
		var csv = "";
		var pixel:Int, column:Int;

		final bitmapWidth = bitmap.width;
		final bitmapHeight = bitmap.height;

		while (row < bitmapHeight) {
			column = 0;

			while (column < bitmapWidth) {
				// Decide if this pixel/tile is solid (1) or not (0)
				pixel = bitmap.getPixel(column, row);

				if (colorMap != null) pixel = colorMap.indexOf(pixel);
				else if ((invert && (pixel > 0)) || (!invert && (pixel == 0))) pixel = 1;
				else pixel = 0;

				// Write the result to the string

				if (column == 0) csv += (row != 0) ? "\n" : "" + pixel;
				else csv += ", " + pixel;

				column++;
			}

			row++;
		}

		return csv;
	}

	/**
	 * Converts a resource image file to a comma-separated string. Black pixels are flagged as 'solid' by default,
	 * non-black pixels are set as non-colliding. Black pixels must be PURE BLACK.
	 *
	 * @param   imageFile  An embedded graphic, preferably black and white.
 	 * @param   invert     Load white pixels as solid instead.
 	 * @param   scale      Default is 1.  Scale of 2 means each pixel forms a 2x2 block of tiles, and so on.
 	 * @param   colorMap   An array of color values (alpha values are ignored) in the order they're intended to be assigned as indices
 	 * @return  A comma-separated string containing the level data in a FlxTilemap-friendly format.
	 */
	public static function imageToCSV(graphic:FlxGraphicSource, invert = false, scale = 1, ?colorMap:Array<FlxColor>):String {
		return bitmapToCSV(graphic.resolveBitmapData(), invert, scale, colorMap);
	}

	/**
	 * Helper function to create a string for toString() functions. Automatically rounds values according to FlxG.debugger.precision.
	 * Strings are formatted in the format: (x: 50 | y: 60 | visible: false)
	 *
	 * @param	labelValuePairs		Array with the data for the string
	 */
	public static function getDebugString(labelValuePairs:Array<LabelValuePair>):String {
		var output = "(";
		for (pair in labelValuePairs) {
			output += (pair.label + ": ");
			var value:Dynamic = pair.value;
			if ((value is Float))
				value = FlxMath.roundDecimal(cast value, FlxG.debugger.precision);

			output += (value + " | ");
			pair.put(); // free for recycling
		}

		// remove the | of the last item, we don't want that at the end
		output = output.substr(0, output.length - 2).trim();
		return (output + ")");
	}

	public static inline function contains(s:String, str:String):Bool {
		return s.indexOf(str) != -1;
	}

	/**
	 * Removes occurrences of a substring by calling `StringTools.replace(s, sub, "")`.
	 */
	public static inline function remove(s:String, sub:String):String {
		return s.replace(sub, "");
	}

	/**
	 * Inserts `insertion` into `s` at index `pos`.
	 */
	public static inline function insert(s:String, pos:Int, insertion:String):String {
		return s.substring(0, pos) + insertion + s.substr(pos);
	}

	public static function sortAlphabetically(list:Array<String>):Array<String> {
		list.sort((a, b) -> {
			a = a.toLowerCase();
			b = b.toLowerCase();
			if (a < b) return -1;
			if (a > b) return 1;
			return 0;
		});
		return list;
	}

	/**
	 * Repeats a string `count` times.
	 * Example: repeatString("ha", 3) -> "hahaha"
	 */
	public static function repeatString(s:String, count:Int):String {
		final out = new StringBuf();
		for (i in 0...count) out.add(s);
		return out.toString();
	}

	/**
	 * Truncates a long string in the middle and replaces the removed part with an ellipsis.
	 * Useful for displaying file paths, usernames, or any long identifiers.
	 *
	 * Example: "C:/Users/Very/Long/Path/File.txt" -> "C:/Users/.../File.txt"
	 */
	public static function truncateMiddle(str:String, maxLength:Int):String {
		if (str == null || str.length <= maxLength) return str;
		if (maxLength < 5) return str.substr(0, maxLength); // too small for ellipsis

		final half = Std.int((maxLength - 3) * .5);
		return str.substr(0, half) + "..." + str.substr(str.length - half);
	}

	/**
	 * Returns true if `s` equals `null` or is empty.
	 * @since 4.1.0
	 */
	public static inline function isNullOrEmpty(s:String):Bool {
		return s == null || s.length == 0;
	}

	/**
	 * Returns an Underscored, or "slugified" string
	 * Example: `"A Tale of Two Cities, Part II"` becomes `"a_tale_of_two_cities__part_ii"`
	 */
	public static function toUnderscoreCase(str:String):String {
		final regex = ~/[^a-z0-9]+/g;
		return regex.replace(str.toLowerCase(), '_');
	}

	/**
	 * Returns a string formatted to 'Title Case'.
	 * Example: `"a tale of two cities, pt ii" returns `"A Tale of Two Cities, Part II"`
	 */
	public static function toTitleCase(str:String):String {
		final exempt = ["a", "an", "the", "at", "by", "for", "in", "of", "on", "to", "up", "and", "as", "but", "or", "nor"];
		final words = str.toLowerCase().split(" ");

		for (i in 0...words.length) {
			if (isRomanNumeral(words[i]))
				words[i] = words[i].toUpperCase();
			else if (i == 0 || exempt.indexOf(words[i]) == -1)
				words[i] = words[i].charAt(0).toUpperCase() + words[i].substr(1);
		}

		return words.join(" ");
	}

	/**
	 * Capitalizes the first letter of every word, does not change the others to lower
	 */
	static final whitespace = ~/(?<=\r|\s|^)([a-z])/g;
	public static function capitalizeFirstLetters(str:String):String {
		return whitespace.map(str, r -> r.matched(0).toUpperCase());
	}

	/**
	 * Capitalizes the first letter
	 */
	public static function toCapitalizeCase(string:String):String {
		final formattedString = string.substr(0, 1).toUpperCase() + string.substr(1);
		return formattedString;
	}

	static final roman = ~/^(?=[MDCLXVI])M*(C[MD]|D?C*)(X[CL]|L?X*)(I[XV]|V?I*)$/i;

	/**
	 * Wether the string contains a valid roman numeral
	 */
	public static function isRomanNumeral(str:String):Bool {
		return roman.match(str);
	}

	/**
	 * Replaces spaces with dashes in a string, and converts the string to lowercase.
	 * Useful for formatting strings to be used in file names, URLs, etc.
	 * @param string The string to format.
	 */
	public static function toDashesCase(string:String):String {
		return string.toLowerCase().replace(' ', '-');
	}

	/**
	 * Strip a given prefix from a string.
	 * @param value The string to strip.
	 * @param prefix The prefix to strip. If the prefix isn't found, the original string is returned.
	 * @return The stripped string.
	 */
	public static function stripPrefix(value:String, prefix:String):String {
		if (value.startsWith(prefix))
			return value.substr(prefix.length);
		return value;
	}

	/**
	 * Strip a given suffix from a string.
	 * @param value The string to strip.
	 * @param suffix The suffix to strip. If the suffix isn't found, the original string is returned.
	 * @return The stripped string.
	 */
	public static function stripSuffix(value:String, suffix:String):String {
		if (value.endsWith(suffix))
			return value.substr(0, value.length - suffix.length);
		return value;
	}

	/**
	 * Converts a string to lower kebab case. For example, "Hello World" becomes "hello-world".
	 *
	 * @param value The string to convert.
	 * @return The converted string.
	 */
	public static function toLowerKebabCase(value:String):String {
		return value.toLowerCase().replace(' ', '-');
	}

	/**
	 * Converts a string to upper kebab case, aka screaming kebab case. For example, "Hello World" becomes "HELLO-WORLD".
	 *
	 * @param value The string to convert.
	 * @return The converted string.
	 */
	public static function toUpperKebabCase(value:String):String {
		return value.toUpperCase().replace(' ', '-');
	}

	static final SANTIZE_REGEX = ~/[^-a-zA-Z0-9]/g;

	/**
	 * Remove all instances of symbols other than alpha-numeric characters (and dashes)from a string.
	 * @param value The string to sanitize.
	 * @return The sanitized string.
	 */
	public static function sanitize(value:String):String {
		return SANTIZE_REGEX.replace(value, '');
	}

	/**
	 * Like `join` but adds a word before the last element.
	 * @param array The array to join.
	 * @param separator The separator to use between elements.
	 * @param andWord The word to use before the last element.
	 * @return The joined string.
	 */
	public static function joinPlural(array:Array<String>, separator = ', ', andWord = 'and'):String {
		if (array.length == 0) return '';
		if (array.length == 1) return array[0];

		return '${array.slice(0, array.length - 1).join(separator)} $andWord ${array[array.length - 1]}';
	}
}

class LabelValuePair implements IFlxDestroyable {
	static final _pool = new FlxPool(LabelValuePair.new);

	public static inline function weak(label:String, value:Dynamic):LabelValuePair {
		return _pool.get().create(label, value);
	}

	public var label:String;
	public var value:Dynamic;

	public inline function create(label:String, value:Dynamic):LabelValuePair {
		this.label = label;
		this.value = value;
		return this;
	}

	public inline function put():Void {
		_pool.put(this);
	}

	public inline function destroy():Void {
		label = null;
		value = null;
	}

	@:keep function new() {}
}