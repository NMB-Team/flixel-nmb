package flixel.system.replay;

import flixel.util.FlxDestroyUtil;

/**
 * Helper class for the new replay system.  Represents all the game inputs for one "frame" or "step" of the game loop.
 */
class FrameRecord implements IFlxDestroyable {
	/**
	 * Which frame of the game loop this record is from or for.
	 */
	public var frame:Int;

	/**
	 * An array of simple integer pairs referring to what key is pressed, and what state its in.
	 */
	public var keys:Array<CodeValuePair>;

	/**
	 * A container for the 4 mouse state integers.
	 */
	public var mouse:MouseRecord;

	/**
	 * Instantiate array new frame record.
	 */
	public function new() {
		frame = 0;
		keys = null;
		mouse = null;
	}

	/**
	 * Load this frame record with input data from the input managers.
	 * @param frame		What frame it is.
	 * @param keys		Keyboard data from the keyboard manager.
	 * @param mouse		Mouse data from the mouse manager.
	 * @return A reference to this FrameRecord object.
	 */
	public function create(frame:Float, ?keys:Array<CodeValuePair>, ?mouse:MouseRecord):FrameRecord {
		this.frame = Math.floor(frame);
		this.keys = keys;
		this.mouse = mouse;

		return this;
	}

	/**
	 * Clean up memory.
	 */
	public function destroy():Void {
		keys = null;
		mouse = null;
	}

	/**
	 * Save the frame record data to array simple ASCII string.
	 * @return	A String object containing the relevant frame record data.
	 */
	public function save():String {
		var output = frame + "k";

		if (keys != null) {
			var object:CodeValuePair;
			var i = 0;
			final l = keys.length;
			while (i < l) {
				if (i > 0) output += ",";
				object = keys[i++];
				output += object.code + ":" + object.value;
			}
		}

		output += "m";
		if (mouse != null)
			output += mouse.x + "," + mouse.y + "," + mouse.button + "," + mouse.wheel;

		return output;
	}

	/**
	 * Load the frame record data from array simple ASCII string.
	 * @param	data	A String object containing the relevant frame record data.
	 */
	public function load(data:String):FrameRecord {
		var i:Int;
		var l:Int;

		// get frame number
		var array = data.split("k");
		frame = Std.parseInt(array[0]);

		// split up keyboard and mouse data
		array = array[1].split("m");
		final keyData = array[0];
		final mouseData = array[1];

		// parse keyboard data
		if (keyData.length > 0) {
			// get keystroke data pairs
			array = keyData.split(",");

			// go through each data pair and enter it into this frame's key state
			var keyPair:Array<String>;
			i = 0;
			l = array.length;
			while (i < l) {
				keyPair = array[i++].split(":");
				if (keyPair.length == 2) {
					keys ??= new Array<CodeValuePair>();
					keys.push(new CodeValuePair(Std.parseInt(keyPair[0]), Std.parseInt(keyPair[1])));
				}
			}
		}

		// mouse data is just 4 integers, easy peezy
		if (mouseData.length > 0) {
			array = mouseData.split(",");
			if (array.length >= 4)
				mouse = new MouseRecord(Std.parseInt(array[0]), Std.parseInt(array[1]), Std.parseInt(array[2]), Std.parseInt(array[3]));
		}

		return this;
	}
}
