package flixel.system.frontEnds;

import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.system.debug.log.LogStyle;
import haxe.PosInfos;

/**
 * Accessed via `FlxG.log`.
 */
class LogFrontEnd {
	/**
	 * Whether everything you trace() is being redirected into the log window.
	 */
	public var redirectTraces(default, set) = false;

	public final styles = new LogFrontEndStyles();

	var _standardTraceFunction:(Dynamic, ?PosInfos)->Void;

	public inline function add(data:Dynamic, ?pos:PosInfos):Void {
		advanced(data, styles.NORMAL, false, pos);
	}

	public inline function warn(data:Dynamic, ?pos:PosInfos):Void {
		advanced(data, styles.WARNING, true, pos);
	}

	public inline function error(data:Dynamic, ?pos:PosInfos):Void {
		advanced(data, styles.ERROR, true, pos);
	}

	public inline function critical(data:Dynamic, ?pos:PosInfos):Void {
		advanced(data, styles.CRITICAL, true, pos);
	}

	public inline function notice(data:Dynamic, ?pos:PosInfos):Void {
		advanced(data, styles.NOTICE, false, pos);
	}

	/**
	 * Add an advanced log message to the debugger by also specifying a LogStyle. Backend to FlxG.log.add(), FlxG.log.warn(), FlxG.log.error() and FlxG.log.notice().
	 *
	 * @param   data      Any Data to log.
	 * @param   style     The LogStyle to use, for example FlxG.log.styles.WARNING. You can also create your own by importing the LogStyle class.
	 * @param   fireOnce  Whether you only want to log the Data in case it hasn't been added already
	 */
	public function advanced(data:Any, ?style:LogStyle, fireOnce = false, ?pos:PosInfos):Void {
		if (style == null) style = styles.NORMAL;

		final arrayData = (!(data is Array) ? [data] : cast data);

		#if FLX_DEBUG
		// Check null game since `FlxG.save.bind` may be called before `new FlxGame`
		if (FlxG.game == null || FlxG.game.debugger == null)
			_standardTraceFunction(arrayData);
		else if (FlxG.game.debugger.log.add(arrayData, style, fireOnce)) {
			#if (FLX_SOUND_SYSTEM && !FLX_UNIT_TEST)
			if (style.errorSound != null) {
				final sound = FlxAssets.getSoundAddExtension(style.errorSound);
				if (sound != null)
					FlxG.sound.load(sound).play();
			}
			#end

			if (style.openConsole) FlxG.debugger.visible = true;
		}
		#end

		style.onLog.dispatch(data, pos);

		if (style.throwException)
			throw style.toLogString(arrayData);
	}

	/**
	 * Clears the log output.
	 */
	public inline function clear():Void {
		#if FLX_DEBUG
		FlxG.game.debugger.log.clear();
		#end
	}

	@:allow(flixel.FlxG) function new() {
		_standardTraceFunction = haxe.Log.trace;
	}

	inline function set_redirectTraces(redirect:Bool):Bool {
		haxe.Log.trace = (redirect) ? processTraceData : _standardTraceFunction;
		return redirectTraces = redirect;
	}

	/**
	 * Internal function used as a interface between trace() and add().
	 *
	 * @param   data  The data that has been traced
	 * @param   info  Information about the position at which trace() was called
	 */
	inline function processTraceData(data:Any, ?info:PosInfos):Void {
		final paramArray = [data];

		if (info.customParams != null)
			for (i in info.customParams)
				paramArray.push(i);

		advanced(paramArray, FlxG.log.styles.NORMAL);
	}
}

/**
 * Helper for LogStyle static
 */
@:publicFields class LogFrontEndStyles {
	/** The lowest severity message style. By default, doesn't open the console or beep */
	final NORMAL = new LogStyle();

	/** A low severity message style. By default, doesn't open the console or beep */
	final NOTICE = new LogStyle("[NOTICE] ", "5CF878", 12, false);

	/** Logged when something unexpected but safe happens. By default, opens the console and beeps */
	final WARNING = new LogStyle("[WARNING] ", "D9F85C", 12, false, false, false, false, "flixel/sounds/beep", true);

	/** Logged when something unsafe happens. By default, opens the console and beeps */
	final ERROR = new LogStyle("[ERROR] ", "FF8888", 12, false, false, false, false, "flixel/sounds/beep", true);

	/** A high severity message style. By default, opens the console, beeps, and throws an exception. */
	final CRITICAL = new LogStyle("[CRITICAL] ", "FF0033", 12, false, false, false, false, "flixel/sounds/beep", true, true);

	/** Used internally by Flixel's console debugging tool */
	final CONSOLE = new LogStyle("[CONSOLE] ", "5A96FA", 12, false);

	/** A style used for trace messages. */
	final TRACE = new LogStyle("[TRACE] ", "FC763D", 12, false);

	/** A style used to format messages with a bracket prefix. */
	final BRACKET = new LogStyle("> ", "7982DB", 12, false);

	/** A style used for FlxSave logs. */
	final SAVE = new LogStyle("[SAVE] ", "54FFEE", 12, true);

	function new() {
		// TODO: check FLX_LOG_SEVERITY_THROW, FLX_LOG_SEVERITY_BEEP and FLX_LOG_SEVERITY_OPEN
	}
}
