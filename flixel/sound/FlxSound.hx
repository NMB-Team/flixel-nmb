package flixel.sound;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal;
import flixel.util.FlxStringUtil;
import openfl.events.Event;
import openfl.events.IEventDispatcher;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;

/**
 * This is the universal flixel sound object, used for streaming, music, and sound effects.
 */
class FlxSound extends FlxBasic {
	/**
	 * The x position of this sound in world coordinates.
	 * Only really matters if you are doing proximity/panning stuff.
	 */
	public var x:Float;

	/**
	 * The y position of this sound in world coordinates.
	 * Only really matters if you are doing proximity/panning stuff.
	 */
	public var y:Float;

	/**
	 * Whether or not this sound should be automatically destroyed when you switch states.
	 */
	public var persist:Bool;

	/**
	 * The ID3 song name. Defaults to null. Currently only works for streamed sounds.
	 */
	public var name(default, null):String;

	/**
	 * The ID3 artist name. Defaults to null. Currently only works for streamed sounds.
	 */
	public var artist(default, null):String;

	/**
	 * Stores the average wave amplitude of both stereo channels
	 */
	public var amplitude(default, null):Float;

	/**
	 * Just the amplitude of the left stereo channel
	 */
	public var amplitudeLeft(default, null):Float;

	/**
	 * Just the amplitude of the right stereo channel
	 */
	public var amplitudeRight(default, null):Float;

	/**
	 * Whether to call `destroy()` when the sound has finished playing.
	 */
	public var autoDestroy:Bool;

	/**
	 * Tracker for sound complete callback. If assigned, will be called
	 * each time when sound reaches its end.
	 */
	public final onFinish:FlxSignal;

	/**
	 * Pan amount. -1 = full left, 1 = full right. Proximity based panning overrides this.
	 *
	 * Note: On desktop targets this only works with mono sounds, due to limitations of OpenAL.
	 * More info: [OpenFL Forums - SoundTransform.pan does not work](https://community.openfl.org/t/windows-legacy-soundtransform-pan-does-not-work/6616/2?u=geokureli)
	 */
	public var pan(get, set):Float;

	/**
	 * Whether or not the sound is currently playing.
	 */
	public var playing(get, never):Bool;

	/**
	 * Set volume to a value between 0 and 1 to change how this sound is.
	 */
	public var volume(get, set):Float;

	/**
	 * Whether or not the sound is muted.
	 */
	public var muted(get, set):Bool;

	#if FLX_PITCH
	/**
	 * Set pitch, which also alters the playback speed. Default is 1.
	 */
	public var pitch(get, set):Float;
	#end

	/**
	 * The position in runtime of the music playback in milliseconds.
	 * If set while paused, changes only come into effect after a `resume()` call.
	 */
	public var time(get, set):Float;

	/**
	 * The length of the sound in milliseconds.
	 * @since 4.2.0
	 */
	public var length(get, never):Float;

	/**
	 * The latency of the sound in milliseconds.
	 */
	public var latency(get, never):Float;

	/**
	 * The sound group this sound belongs to, can only be in one group.
	 */
	@:allow(flixel.sound.FlxSoundGroup)
	public var group(default, null):FlxSoundGroup;

	/**
	 * Whether or not this sound should loop.
	 */
	public var looped:Bool;

	/**
	 * In case of looping, the point (in milliseconds) from where to restart the sound when it loops back
	 * @since 4.1.0
	 */
	public var loopTime = .0;

	/**
	 * At which point to stop playing the sound, in milliseconds.
	 * If not set / `null`, the sound completes normally.
	 * @since 4.2.0
	 */
	public var endTime:Null<Float>;

	/**
	 * The tween used to fade this sound's volume in and out (set via `fadeIn()` and `fadeOut()`)
	 * @since 4.1.0
	 */
	public var fadeTween:FlxTween;

	/**
	 * Internal tracker for a sound object.
	 */
	@:allow(flixel.system.frontEnds.SoundFrontEnd.load)
	var _sound:Sound;

	/**
	 * Internal tracker for a sound channel object.
	 */
	var _channel:SoundChannel;

	/**
	 * Internal tracker for a sound transform object.
	 */
	var _transform:SoundTransform;

	/**
	 * Internal tracker for whether the sound is paused or not (not the same as stopped).
	 */
	var _paused:Bool;

	/**
	 * Internal tracker for volume.
	 */
	var _volume:Float;

	/**
	 * Internal tracker for whether the sound is muted or not.
	 */
	var _muted:Bool;

	/**
	 * Internal tracker for sound channel position.
	 */
	var _time = .0;

	/**
	 * Internal tracker for sound length, so that length can still be obtained while a sound is paused, because _sound becomes null.
	 */
	var _length = .0;

	#if FLX_PITCH
	/**
	 * Internal tracker for pitch.
	 */
	var _pitch = 1.;
	#end

	/**
	 * Internal tracker for total volume adjustment.
	 */
	var _volumeAdjust = 1.;

	/**
	 * Internal tracker for the sound's "target" (for proximity and panning).
	 */
	var _target:FlxObject;

	/**
	 * Internal tracker for the maximum effective radius of this sound (for proximity and panning).
	 */
	var _radius:Float;

	/**
	 * Internal tracker for whether to pan the sound left and right.  Default is false.
	 */
	var _proximityPan:Bool;

	/**
	 * Helper var to prevent the sound from playing after focus was regained when it was already paused.
	 */
	var _resumeOnFocus = false;

	/**
	 * The FlxSound constructor gets all the variables initialized, but NOT ready to play a sound yet.
	 */
	public function new() {
		super();

		onFinish = new FlxSignal();

		reset();
	}

	/**
	 * An internal function for clearing all the variables used by sounds.
	 */
	private function reset():Void {
		destroy();

		x = y = 0;

		_volume = _volumeAdjust = 1;
		_time = loopTime = endTime = _radius = amplitude = amplitudeLeft = amplitudeRight = 0;
		_paused = _muted = looped = _proximityPan = visible = false;

		_target = null;

		autoDestroy = false;

		_transform ??= new SoundTransform();
		_transform.pan = 0;
	}

	override public function destroy():Void {
		// Prevents double destroy
		group?.remove(this);

		_transform = null;
		exists = active = false;
		_target = null;
		name = null;
		artist = null;

		if (_channel != null) {
			_channel.removeEventListener(Event.SOUND_COMPLETE, stopped);
			_channel.stop();
			_channel = null;
		}

		if (_sound != null) {
			_sound.removeEventListener(Event.ID3, gotID3);
			_sound = null;
		}

		onFinish.removeAll();

		super.destroy();
	}

	/**
	 * Handles fade out, fade in, panning, proximity, and amplitude operations each frame.
	 */
	override public function update(elapsed:Float):Void {
		if (!playing) return;

		_time = _channel.position;

		var radialMultiplier = 1.;

		// Distance-based volume control
		if (_target != null) {
			final targetPosition = _target.getPosition();
			radialMultiplier = targetPosition.distanceTo(FlxPoint.weak(x, y)) / _radius;
			targetPosition.put();
			radialMultiplier = 1 - FlxMath.bound(radialMultiplier, 0, 1);

			if (_proximityPan) {
				final d = (x - _target.x) / _radius;
				_transform.pan = FlxMath.bound(d, -1, 1);
			}
		}

		_volumeAdjust = radialMultiplier;
		updateTransform();

		if (_transform.volume > 0) {
			amplitudeLeft = _channel.leftPeak / _transform.volume;
			amplitudeRight = _channel.rightPeak / _transform.volume;
			amplitude = (amplitudeLeft + amplitudeRight) * .5;
		} else
			amplitudeLeft = amplitudeRight = amplitude = 0;

		if (endTime != null && _time >= endTime) stopped();
	}

	override public function kill():Void {
		super.kill();
		cleanup(false);
	}

	/**
	 * One of the main setup functions for sounds, this function loads a sound from an embedded MP3.
	 *
	 * **Note:** If the `FLX_DEFAULT_SOUND_EXT` flag is enabled, you may omit the file extension
	 *
	 * @param	embeddedSound	An embedded Class object representing an MP3 file.
	 * @param	looped			Whether or not this sound should loop endlessly.
	 * @param	autoDestroy		Whether or not this FlxSound instance should be destroyed when the sound finishes playing.
	 * 							Default value is false, but `FlxG.sound.play()` and `FlxG.sound.stream()` will set it to true by default.
	 * @param	onComplete		Called when the sound finished playing
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadEmbedded(embeddedSound:FlxSoundAsset, looped = false, autoDestroy = false, ?onComplete:Void -> Void):FlxSound {
		if (embeddedSound == null)
			return this;

		cleanup(true);

		if ((embeddedSound is Sound)) _sound = embeddedSound;
		else if ((embeddedSound is Class)) _sound = Type.createInstance(embeddedSound, []);
		else if ((embeddedSound is String)) {
			if (FlxG.assets.exists(embeddedSound, SOUND))
				_sound = FlxG.assets.getSoundUnsafe(embeddedSound);
			else
				FlxG.log.error('Could not find a Sound asset with an ID of \'$embeddedSound\'.');
		}

		// NOTE: can't pull ID3 info from embedded sound currently
		return init(looped, autoDestroy, onComplete);
	}

	/**
	 * One of the main setup functions for sounds, this function loads a sound from a URL.
	 *
	 * @param	soundURL		A string representing the URL of the MP3 file you want to play.
	 * @param	looped			Whether or not this sound should loop endlessly.
	 * @param	autoDestroy		Whether or not this FlxSound instance should be destroyed when the sound finishes playing.
	 * 							Default value is false, but `FlxG.sound.play()` and `FlxG.sound.stream()` will set it to true by default.
	 * @param	onComplete		Called when the sound finished playing
	 * @param	onLoad			Called when the sound finished loading.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadStream(soundURL:String, looped = false, autoDestroy = false, ?onComplete:Void -> Void, ?onLoad:Void -> Void):FlxSound {
		cleanup(true);

		_sound = new Sound();
		_sound.addEventListener(Event.ID3, gotID3);

		var loadCallback:Event -> Void = null;
		loadCallback = (e:Event) -> {
			(e.target:IEventDispatcher).removeEventListener(e.type, loadCallback);

			if (_sound == e.target) { // Check if the sound was destroyed before calling. Weak ref doesn't guarantee GC.
				_length = _sound.length;
				if (onLoad != null) onLoad();
			}
		}

		// Use a weak reference so this can be garbage collected if destroyed before loading.
		_sound.addEventListener(Event.COMPLETE, loadCallback, false, 0, true);
		_sound.load(new URLRequest(soundURL));

		return init(looped, autoDestroy, onComplete);
	}

	/**
	 * One of the main setup functions for sounds, this function loads a sound from a ByteArray.
	 *
	 * @param	bytes 			A ByteArray object.
	 * @param	looped			Whether or not this sound should loop endlessly.
	 * @param	autoDestroy		Whether or not this FlxSound instance should be destroyed when the sound finishes playing.
	 * 							Default value is false, but `FlxG.sound.play()` and `FlxG.sound.stream()` will set it to true by default.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadByteArray(bytes:ByteArray, looped = false, autoDestroy = false, ?onComplete:Void -> Void):FlxSound {
		cleanup(true);

		_sound = new Sound();
		_sound.addEventListener(Event.ID3, gotID3);
		_sound.loadCompressedDataFromByteArray(bytes, bytes.length);

		return init(looped, autoDestroy, onComplete);
	}

	private function init(looped = false, autoDestroy = false, ?onComplete:Void -> Void):FlxSound {
		this.looped = looped;
		this.autoDestroy = autoDestroy;

		updateTransform();
		exists = true;

		onFinish.removeAll();
		onFinish.add(onComplete);

		#if FLX_PITCH
		pitch = 1;
		#end

		_length = (_sound == null) ? 0 : _sound.length;
		endTime = _length;

		return this;
	}

	/**
	 * Call this function if you want this sound's volume to change
	 * based on distance from a particular FlxObject.
	 *
	 * @param	x			The X position of the sound.
	 * @param	y			The Y position of the sound.
	 * @param	targetObject		The object you want to track.
	 * @param	radius			The maximum distance this sound can travel.
	 * @param	pan			Whether panning should be used in addition to the volume changes.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function proximity(x:Float, y:Float, targetObject:FlxObject, radius:Float, pan = true):FlxSound {
		this.x = x;
		this.y = y;
		_target = targetObject;
		_radius = radius;
		_proximityPan = pan;
		return this;
	}

	/**
	 * Call this function to play the sound - also works on paused sounds.
	 *
	 * @param   ForceRestart   Whether to start the sound over or not.
	 *                         Default value is false, meaning if the sound is already playing or was
	 *                         paused when you call play(), it will continue playing from its current
	 *                         position, NOT start again from the beginning.
	 * @param   StartTime      At which point to start playing the sound, in milliseconds.
	 * @param   EndTime        At which point to stop playing the sound, in milliseconds.
	 *                         If not set / `null`, the sound completes normally.
	 */
	public function play(forceRestart = false, startTime = .0, ?endTime:Float):FlxSound {
		if (!exists) return this;

		if (forceRestart) cleanup(false, true);
		else if (playing) return this; // Already playing sound

		if (_paused) resume();
		else startSound(startTime);

		this.endTime = endTime;
		return this;
	}

	/**
	 * Unpause a sound. Only works on sounds that have been paused.
	 */
	public function resume():FlxSound {
		if (_paused) startSound(_time);
		return this;
	}

	/**
	 * Call this function to pause this sound.
	 */
	public function pause():FlxSound {
		if (!playing) return this;

		_time = _channel.position;
		_paused = true;
		cleanup(false, false);
		return this;
	}

	/**
	 * Call this function to stop this sound.
	 */
	public inline function stop():FlxSound {
		cleanup(autoDestroy, true);
		return this;
	}

	/**
	 * Helper function that tweens this sound's volume.
	 *
	 * @param	duration	The amount of time the fade-out operation should take.
	 * @param	to			The volume to tween to, 0 by default.
	 */
	public inline function fadeOut(duration = 1., ?to = .0, ?onComplete:FlxTween -> Void):FlxSound {
		fadeTween?.cancel();
		fadeTween = FlxTween.num(volume, to, duration, {onComplete: onComplete}, volumeTween);

		return this;
	}

	/**
	 * Helper function that tweens this sound's volume.
	 *
	 * @param	duration	The amount of time the fade-in operation should take.
	 * @param	From		The volume to tween from, 0 by default.
	 * @param	To			The volume to tween to, 1 by default.
	 */
	public inline function fadeIn(duration = 1., from = .0, to = 1., ?onComplete:FlxTween -> Void):FlxSound {
		if (!playing) play();

		fadeTween?.cancel();

		fadeTween = FlxTween.num(from, to, duration, {onComplete: onComplete}, volumeTween);
		return this;
	}

	private function volumeTween(f:Float):Void {
		volume = f;
	}

	/**
	 * Returns the currently selected "real" volume of the sound (takes fades and proximity into account).
	 *
	 * @return	The adjusted volume of the sound.
	 */
	public inline function getActualVolume():Float {
		return _volume * _volumeAdjust * (_muted ? 0 : 1);
	}

	/**
	 * Helper function to set the coordinates of this object.
	 * Sound positioning is used in conjunction with proximity/panning.
	 *
	 * @param        x        The new x position
	 * @param        y        The new y position
	 */
	public inline function setPosition(x = .0, y = .0):Void {
		this.x = x;
		this.y = y;
	}

	/**
	 * Call after adjusting the volume to update the sound channel's settings.
	 */
	@:allow(flixel.sound.FlxSoundGroup)
	private function updateTransform():Void {
		if (_transform == null) return;

		_transform.volume = calcTransformVolume();
		if (_channel != null) _channel.soundTransform = _transform;
	}

	private function calcTransformVolume():Float {
		final volume = (group != null ? group.getVolume() : 1) * _volume * _volumeAdjust * (_muted ? 0 : 1);

		#if FLX_SOUND_SYSTEM
		if (FlxG.sound.muted) return 0;

		return FlxG.sound.applySoundCurve(FlxG.sound.volume * volume);
		#else
		return volume;
		#end
	}

	/**
	 * An internal helper function used to attempt to start playing
	 * the sound and populate the _channel variable.
	 */
	private function startSound(startTime:Float):Void {
		if (_sound == null)
			return;

		_time = startTime;
		_paused = false;
		_channel = _sound.play(_time, 0, _transform);

		if (_channel != null) {
			#if FLX_PITCH
			pitch = _pitch;
			#end
			_channel.addEventListener(Event.SOUND_COMPLETE, stopped);
			active = true;
		} else
			exists = active = false;
	}

	/**
	 * An internal helper function used to clean up finished sounds or restart looped sounds.
	 */
	private function stopped(?_):Void {
		onFinish.dispatch();

		if (looped) {
			cleanup(false);
			play(false, loopTime, endTime);
		} else
			cleanup(autoDestroy);
	}

	/**
	 * An internal helper function used to clean up (and potentially re-use) finished sounds.
	 * Will stop the current sound and destroy the associated SoundChannel, plus,
	 * any other commands ordered by the passed in parameters.
	 *
	 * @param  destroySound    Whether or not to destroy the sound. If this is true,
	 *                         the position and fading will be reset as well.
	 * @param  resetPosition   Whether or not to reset the position of the sound.
	 */
	private function cleanup(destroySound:Bool, resetPosition = true):Void {
		if (destroySound) {
			reset();
			return;
		}

		if (_channel != null) {
			_channel.removeEventListener(Event.SOUND_COMPLETE, stopped);
			_channel.stop();
			_channel = null;
		}

		active = false;

		if (resetPosition) {
			_time = 0;
			_paused = false;
		}
	}

	/**
	 * Internal event handler for ID3 info (i.e. fetching the song name).
	 */
	private function gotID3(_):Void {
		name = _sound.id3.songName;
		artist = _sound.id3.artist;
		_sound.removeEventListener(Event.ID3, gotID3);
	}

	#if FLX_SOUND_SYSTEM
	@:allow(flixel.system.frontEnds.SoundFrontEnd)
	private function onFocus():Void {
		if (_resumeOnFocus) {
			_resumeOnFocus = false;
			resume();
		}
	}

	@:allow(flixel.system.frontEnds.SoundFrontEnd)
	private function onFocusLost():Void {
		_resumeOnFocus = !_paused;
		pause();
	}
	#end

	inline function get_playing():Bool {
		return _channel != null;
	}

	inline function get_volume():Float {
		return _volume;
	}

	private function set_volume(volume:Float):Float {
		_volume = FlxMath.bound(volume, 0, 1);
		updateTransform();
		return volume;
	}

	inline function get_muted():Bool {
		return _muted;
	}

	private function set_muted(muted:Bool):Bool {
		_muted = muted;
		updateTransform();
		return muted;
	}

	#if FLX_PITCH
	inline function get_pitch():Float {
		return _pitch;
	}

	private function set_pitch(v:Float):Float {
		if (_channel != null) {
			#if (openfl < "9.3.2")
			@:privateAccess
			if (_channel.__source != null) _channel.__source.pitch = v;
			#else
			@:privateAccess
			if (_channel.__audioSource != null) _channel.__audioSource.pitch = v;
			#end
		}

		return _pitch = v;
	}
	#end

	inline function get_pan():Float {
		return _transform.pan;
	}

	inline function set_pan(pan:Float):Float {
		_transform.pan = pan;
		updateTransform();
		return pan;
	}

	inline function get_time():Float {
		return _time;
	}

	private function set_time(time:Float):Float {
		if (playing) {
			cleanup(false, true);
			startSound(time);
		}

		return _time = time;
	}

	inline function get_length():Float {
		return _length;
	}

	private function get_latency():Float {
		if (_channel != null) {
			#if (openfl < "9.3.2")
			@:privateAccess
			if (_channel.__source != null) return _channel.__source.latency;
			#else
			@:privateAccess
			if (_channel.__audioSource != null) return _channel.__audioSource.latency;
			#end
		}
		return 0;
	}

	override public function toString():String {
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("playing", playing),
			LabelValuePair.weak("time", time),
			LabelValuePair.weak("length", length),
			LabelValuePair.weak("volume", volume)
		]);
	}
}
