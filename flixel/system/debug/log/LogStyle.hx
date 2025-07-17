package flixel.system.debug.log;

import flixel.util.FlxSignal;
import haxe.PosInfos;

using flixel.util.FlxStringUtil;

/**
 * A class that allows you to create a custom style for `FlxG.log.advanced()`.
 * Also used internally for the pre-defined styles.
 */
class LogStyle
{
	/**
	 * A prefix which is always attached to the start of the logged data
	 */
	public var prefix:String;

	public var color:String;
	public var size:Int;
	public var bold:Bool;
	public var italic:Bool;
	public var underlined:Bool;
	public var ignoreInfo:Bool;

	/**
	 * A sound to be played when this LogStyle is used
	 */
	public var errorSound:String;

	/**
	 * Whether the console should be forced to open when this LogStyle is used
	 */
	public var openConsole:Bool;

	/**
	 * A callback function that is called when this LogStyle is used
	 * **Note:** Unlike the deprecated `callbackFunction`, this is called every time,
	 * even when logged with `once = true` and even in release mode.
	 */
	public final onLog = new FlxTypedSignal<(data:Any, ?pos:PosInfos) -> Void>();

	/**
	 * Whether an exception is thrown when this LogStyle is used.
	 * **Note**: Unlike other log style properties, this happens even in release mode.
	 * @since 5.4.0
	 */
	public var throwException = false;

	/**
	 * Create a new LogStyle to be used in conjunction with `FlxG.log.advanced()`
	 *
	 * @param   prefix            A prefix which is always attached to the start of the logged data
	 * @param   color             The text color
	 * @param   size              The text size
	 * @param   bold              Whether the text is bold or not
	 * @param   italic            Whether the text is italic or not
	 * @param   underlined        Whether the text is underlined or not
	 * @param   errorSound        A sound to be played when this LogStyle is used
	 * @param   openConsole       Whether the console should be forced to open when this LogStyle is used
	 * @param   callbackFunction  A callback function that is called when this LogStyle is used
	 * @param   callback          A callback function that is called when this LogStyle is used
	 * @param   throwError        Whether an error is thrown when this LogStyle is used
	 */
	public function new(prefix = "", color = "FFFFFF", size = 12, ignoreInfo = false, bold = false, italic = false, underlined = false,
			?errorSound:String, openConsole = false, ?callbackFunction:()->Void, ?callback:(Any, ?PosInfos)->Void, throwException = false)
	{
		this.prefix = prefix;
		this.color = color;
		this.size = size;
		this.bold = bold;
		this.ignoreInfo = ignoreInfo;
		this.italic = italic;
		this.underlined = underlined;
		this.errorSound = errorSound;
		this.openConsole = openConsole;
		if (callback != null) onLog.add(callback);
		this.throwException = throwException;
	}

	/**
	 * Converts the data into a log message according to this style.
	 *
	 * @param   data  The data being logged
	 */
	public function toLogString(data:Array<Any>) {
		// Format FlxPoints, Arrays, Maps or turn the data entry into a String
		final texts:Array<String> = [];
		for (i in 0...data.length) {
			final text = Std.string(data[i]);
			texts.push(StringTools.htmlEscape(text)); // Make sure you can't insert html tags
		}

		return prefix + texts.join(" ");
	}

	/**
	 * Converts the data into an html log message according to this style.
	 *
	 * @param   data  The data being logged
	 */
	public inline function toHtmlString(data:Array<Any>) {
		return toLogString(data).htmlFormat(size, color, bold, italic, underlined);
	}
}
