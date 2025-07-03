package flixel.input.gamepad;

import flixel.input.FlxInput;

class FlxGamepadButton extends FlxInput<Int> {
	/**
	 * Optional analog value, so we can check when the value has changed from the last frame
	 */
	public var value = .0;
}
