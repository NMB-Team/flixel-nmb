package flixel.system.frontEnds;

#if FLX_RECORD
import flixel.FlxG;
import flixel.util.typeLimit.NextState;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxRandom;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.utils.ByteArray;
import openfl.ui.Mouse;
#end

/**
 * Accessed via `FlxG.vcr`.
 */
class VCRFrontEnd {
	#if FLX_RECORD
	/**
	 * This function, if set, is triggered when the callback stops playing.
	 */
	public var replayCallback:Void -> Void;

	/**
	 * The keys used to toggle the debugger. "MOUSE" to cancel with the mouse.
	 * Handy for skipping cutscenes or getting out of attract modes!
	 */
	public var cancelKeys:Array<FlxKey>;

	/**
	 * Helps time out a replay if necessary.
	 */
	public var timeout = .0;
	#end

	/**
	 * Whether the debugger has been paused.
	 */
	public var paused = false;

	/**
	 * Whether a "1 frame step forward" was requested.
	 */
	public var stepRequested = false;

	/**
	 * Pause the main game loop
	**/
	public function pause():Void {
		if (paused) return;

		#if FLX_MOUSE
		if (!FlxG.mouse.useSystemCursor)
			Mouse.show();
		#end

		paused = true;

		#if FLX_DEBUG
		FlxG.game.debugger.vcr.onPause();
		#end
	}

	/**
	 * Resume the main game loop from FlxG.vcr.pause();
	**/
	public function resume():Void {
		if (!paused) return;

		#if FLX_MOUSE
		if (!FlxG.mouse.useSystemCursor)
			Mouse.hide();
		#end

		paused = false;

		#if FLX_DEBUG
		FlxG.game.debugger.vcr.onResume();
		#end
	}

	#if FLX_RECORD
	/**
	 * Called when the user presses the Rewind-looking button. If Alt is pressed, the entire game is reset.
	 * If Alt is NOT pressed, only the current state is reset. The GUI is updated accordingly.
	 *
	 * @param	standardMode	Whether to reset the current game (== true), or just the current state.  Just resetting the current state can be very handy for debugging.
	 */
	public function restartReplay(standardMode = false):Void {
		stopReplay();
		FlxG.vcr.reloadReplay(standardMode);
	}

	/**
	 * Load replay data from a string and play it back.
	 *
	 * @param   data        The replay that you want to load.
	 * @param   state       If you recorded a state-specific demo or cutscene, pass a state
	 *                      constructor here, just as you would to to `FlxG.switchState`.
	 * @param   cancelKeys  An array of string names of keys (see `FlxKeyboard`) that can be pressed
	 *                      to cancel the playback, e.g. `[ESCAPE,ENTER]`.  Also accepts 2 custom
	 *                      key names: `ANY` and `MOUSE`.
	 * @param   timeout     Set a time limit for the replay. `cancelKeys` will override this, if pressed.
	 * @param   callback    If set, called when the replay finishes, any cancel key is pressed, or
	 *                      if a timeout is triggered. Note: `cancelKeys` and `timeout` will NOT
	 *                      call `FlxG.stopReplay()` if `callback` is set!
	 */
	public function loadReplay(data:String, ?state:NextState, ?cancelKeys:Array<FlxKey>, ?timeout = .0, ?callback:Void -> Void):Void {
		FlxG.game._replay.load(data);

		if (state == null)
			FlxG.resetGame();
		else
			FlxG.switchState(state);

		this.cancelKeys = cancelKeys;
		this.timeout = Std.int(timeout * 1000);
		replayCallback = callback;
		FlxG.game._replayRequested = true;

		#if FLX_KEYBOARD
		FlxG.keys.enabled = false;
		#end

		#if FLX_MOUSE
		FlxG.mouse.enabled = false;
		#end

		#if FLX_DEBUG
		FlxG.game.debugger.vcr.runtime = 0;
		FlxG.game.debugger.vcr.playingReplay();
		#end
	}

	/**
	 * Resets the game or state and replay requested flag.
	 *
	 * @param	standardMode	If true, reload entire game, else just reload current game state.
	 */
	public function reloadReplay(standardMode = true):Void {
		if (standardMode) FlxG.resetGame();
		else FlxG.resetState();

		if (FlxG.game._replay.frameCount > 0)
			FlxG.game._replayRequested = true;
	}

	/**
	 * Stops the current replay.
	 */
	public inline function stopReplay():Void {
		FlxG.game.replaying = false;
		FlxG.inputs.reset();

		#if FLX_DEBUG
		FlxG.game.debugger.vcr.stoppedReplay();
		#end

		#if FLX_KEYBOARD
		FlxG.keys.enabled = true;
		#end

		#if FLX_MOUSE
		FlxG.mouse.enabled = true;
		#end
	}

	public function cancelReplay():Void  {
		if (replayCallback != null) {
			replayCallback();
			replayCallback = null;
		} else 
			stopReplay();
	}

	/**
	 * Resets the game or state and requests a new recording.
	 *
	 * @param	standardMode	If true, reset the entire game, else just reset the current state.
	 */
	public function startRecording(standardMode = true):Void {
		FlxRandom.updateRecordingSeed(standardMode);

		if (standardMode) FlxG.resetGame();
		else FlxG.resetState();

		FlxG.game._recordingRequested = true;
		#if FLX_DEBUG
		FlxG.game.debugger.vcr.recording();
		#end
	}

	/**
	 * Stop recording the current replay and return the replay data.
	 *
	 * @param	openSaveDialog	If true, open an OS-native save dialog for the user to choose where to save the data, and save it there.
	 *
	 * @return	The replay data in simple ASCII format (see FlxReplay.save()).
	 */
	public inline function stopRecording(openSaveDialog = true):String {
		FlxG.game.recording = false;

		#if FLX_DEBUG
		FlxG.game.debugger.vcr.stoppedRecording();
		FlxG.game.debugger.vcr.stoppedReplay();
		#end

		final data = FlxG.game._replay.save();

		if (openSaveDialog && data != null && data.length > 0) {}
		return data;
	}

	/**
	 * Called when the "open file" button is pressed.
	 * Opens the file dialog and registers event handlers for the file dialog.
	 */
	public function onOpen():Void {}

	/**
	 * Clean up memory.
	 */
	inline function destroy():Void {
		#if FLX_RECORD
		cancelKeys = null;
		#end
	}

	/**
	 * Called when a file is picked from the file dialog.
	 * Attempts to load the file and registers file loading event handlers.
	 */
	inline function onOpenSelect(_):Void {}

	/**
	 * Called when a file is opened successfully.
	 * If there's stuff inside, then the contents are loaded into a new replay.
	 */
	inline function onOpenComplete(_):Void {}

	/**
	 * Called if the open file dialog is canceled.
	 */
	inline function onOpenCancel(_):Void {}

	/**
	 * Called if there is a file open error.
	 */
	inline function onOpenError(_):Void {}

	/**
	 * Called when the file is saved successfully.
	 */
	inline function onSaveComplete(_):Void {}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	inline function onSaveCancel(_):Void {}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	inline function onSaveError(_):Void {}
	#end

	@:allow(flixel.FlxG)
	private function new() {}
}