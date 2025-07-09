package flixel.util;

import flixel.util.FlxPool.IFlxPooled;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;

@:access(openfl.display.BitmapData)
class FlxDestroyUtil {
	/**
	 * Checks if an object is not null before calling destroy(), always returns null.
	 *
	 * @param	object	An IFlxDestroyable object that will be destroyed if it's not null.
	 * @return	null
	 */
	public static inline function destroy<T:IFlxDestroyable>(object:Null<IFlxDestroyable>):T {
		object?.destroy();
		return null;
	}

	/**
	 * Destroy every element of an array of IFlxDestroyables
	 *
	 * @param	array	An Array of IFlxDestroyable objects
	 * @return	null
	 */
	public static function destroyArray<T:IFlxDestroyable>(array:Array<T>):Array<T> {
		if (array == null) return null;

		for (e in array) destroy(e);

		array.resize(0);
		return null;
	}

	/**
	 * Checks if an object is not null before putting it back into the pool, always returns null.
	 *
	 * @param	object	An IFlxPooled object that will be put back into the pool if it's not null
	 * @return	null
	 */
	public static inline function put<T:IFlxPooled>(object:IFlxPooled):T {
		object?.put();
		return null;
	}

	/**
	 * Checks if an object is not null before calling `putWeak`, always returns `null`
	 *
	 * @param   object  An `IFlxPooled` object that will be put back into the pool if it's not `null`
	 * @return  `null`
	 * @since 6.2.0
	 */
	public static function putWeak<T:IFlxPooled>(object:IFlxPooled):T {
		object?.putWeak();
		return null;
	}

	/**
	 * Puts all objects in an Array of IFlxPooled objects back into
	 * the pool by calling FlxDestroyUtil.put() on them
	 *
	 * @param	array	An Array of IFlxPooled objects
	 * @return	null
	 */
	public static function putArray<T:IFlxPooled>(array:Array<T>):Array<T> {
		if (array == null) return null;

		for (e in array) put(e);

		array.resize(0);
		return null;
	}

	#if !macro
	/**
	 * Checks if a BitmapData object is not null before calling dispose() on it, always returns null.
	 *
	 * @param	Bitmap	A BitmapData to be disposed if not null
	 * @return 	null
	 */
	public static function dispose(bitmapData:BitmapData, ?ignoreTextureDispose = false):BitmapData {
		if (bitmapData != null) {
			if (!ignoreTextureDispose) bitmapData.__texture?.dispose();
			bitmapData.dispose();
		}
		return null;
	}

	/**
	 * Checks if a BitmapData object is not null and it's size isn't equal to specified one before calling dispose() on it.
	 */
	public static function disposeIfNotEqual(bitmapData:BitmapData, width:Float, height:Float, ?ignoreTextureDispose = false):BitmapData {
		if (bitmapData != null && (bitmapData.width != width || bitmapData.height != height)) {
			if (!ignoreTextureDispose) bitmapData.__texture?.dispose();
			bitmapData.dispose();
			return null;
		}
		return bitmapData;
	}

	public static function removeChild<T:DisplayObject>(parent:DisplayObjectContainer, child:T):T {
		if (parent != null && child != null && parent.contains(child))
			parent.removeChild(child);
		return null;
	}

	@:access(openfl.text.TextField)
	public static inline function removeEventListeners(textField:openfl.text.TextField) {
		textField.removeEventListener(FocusEvent.FOCUS_IN, textField.this_onFocusIn);
		textField.removeEventListener(FocusEvent.FOCUS_OUT, textField.this_onFocusOut);
		textField.removeEventListener(KeyboardEvent.KEY_DOWN, textField.this_onKeyDown);
		textField.removeEventListener(MouseEvent.MOUSE_DOWN, textField.this_onMouseDown);
		textField.removeEventListener(MouseEvent.MOUSE_WHEEL, textField.this_onMouseWheel);
	}
	#end
}

interface IFlxDestroyable {
	function destroy():Void;
}