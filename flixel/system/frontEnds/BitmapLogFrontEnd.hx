package flixel.system.frontEnds;

import flixel.FlxG;
import flixel.util.FlxStringUtil;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;

/**
 * Accessed via `FlxG.bitmapLog`.
 */
class BitmapLogFrontEnd {
	#if FLX_DEBUG
	public var window(get, never):flixel.system.debug.log.BitmapLog;
	inline function get_window() return FlxG.game.debugger.bitmapLog;
	#end

	public overload inline extern function add(data:BitmapData, name = ""):Void {
		#if FLX_DEBUG
		window.add(data, name);
		#end
	}

	public overload inline extern function add(graphic:FlxGraphic, ?name:String):Void {
		addGraphic(graphic, name);
	}

	private function addGraphic(graphic:FlxGraphic, ?name:String):Void {
		#if FLX_DEBUG
		if (graphic != null && graphic.bitmap != null) {
			if (FlxStringUtil.isNullOrEmpty(name)) name = getGraphicName(graphic);
			add(graphic.bitmap, name);
		}
		#end
	}

	private function getGraphicName(graphic:FlxGraphic) {
		if (graphic.key != null) return graphic.key;
		if (graphic.assetsKey != null) return graphic.assetsKey;
		if (graphic.assetsClass != null) return Type.getClassName(graphic.assetsClass);
		#if FLX_TRACK_GRAPHICS
		if (graphic.trackingInfo != null) return graphic.trackingInfo;
		#end

		return null;
	}

	/**
	 * Clears all bitmaps
	 */
	public inline function clear():Void {
		#if FLX_DEBUG
		window.clear();
		#end
	}

	/**
	 * Clear one bitmap object from the log -- the last one, by default
	 * @param	index
	 */
	public inline function clearAt(index = -1):Void {
		#if FLX_DEBUG
		window.clearAt(index);
		#end
	}

	/**
	 * Clears the bitmapLog window and adds the entire cache to it.
	 */
	public function viewCache():Void {
		#if FLX_DEBUG
		clear();
		for (cachedGraphic in FlxG.bitmap._cache)
			add(cachedGraphic.bitmap, cachedGraphic.key);
		#end
	}

	@:allow(flixel.FlxG)
	private function new() {}
}
