package flixel.system.ui;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import flixel.system.debug.DebuggerUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

/**
 * A basic button for the debugger, extends openfl.display.Sprite.
 * Cannot be used in a FlxState.
 */
class FlxSystemButton extends Sprite implements IFlxDestroyable {
	/**
	 * The function to be called when the button is pressed.
	 */
	public var upHandler:Void -> Void;

	/**
	 * Whether or not the downHandler function will be called when
	 * the button is clicked.
	 */
	public var enabled = true;

	/**
	 * Whether this is a toggle button or not. If so, a Boolean representing the current
	 * state will be passed to the callback function, and the alpha value will be lowered when toggled.
	 */
	public var toggleMode = false;

	/**
	 * Whether the button has been toggled in toggleMode.
	 */
	public var toggled(default, set) = false;

	/**
	 * The icon this button uses.
	 */
	var _icon:Bitmap;

	/**
	 * Whether the mouse has been pressed while over this button.
	 */
	var _mouseDown = false;

	/**
	 * Create a new FlxSystemButton
	 *
	 * @param	icon		The icon to use for the button.
	 * @param	upHandler	The function to be called when the button is pressed.
	 * @param	toggleMode	Whether this is a toggle button or not.
	 */
	public function new(icon:BitmapData, ?upHandler:Void -> Void, toggleMode = false) {
		super();

		if (icon != null) changeIcon(icon);

		this.upHandler = upHandler;
		this.toggleMode = toggleMode;

		addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
	}

	/**
	 * Change the icon of the button
	 *
	 * @param	icon	The new icon to use for the button.
	 */
	public function changeIcon(icon:BitmapData):Void {
		if (_icon != null) removeChild(_icon);

		DebuggerUtil.fixSize(icon);
		_icon = new Bitmap(icon);
		addChild(_icon);
	}

	public function destroy():Void {
		removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);

		_icon = null;
		upHandler = null;
	}

	@:noCompletion inline function onMouseUp(_):Void {
		if (!enabled || !_mouseDown) return;

		toggled = !toggled;
		_mouseDown = false;

		if (upHandler != null)
			upHandler();
	}

	@:noCompletion inline function onMouseDown(_):Void {
		_mouseDown = true;
	}

	@:noCompletion final multAlpha = .2;
	@:noCompletion inline function onMouseOver(_):Void {
		if (!enabled) return;
		alpha -= multAlpha;
	}

	@:noCompletion inline function onMouseOut(_):Void {
		if (!enabled) return;
		alpha += multAlpha;
	}

	@:noCompletion inline function set_toggled(value:Bool):Bool {
		if (toggleMode)
			alpha = value ? multAlpha + .1 : 1;
		return toggled = value;
	}
}
