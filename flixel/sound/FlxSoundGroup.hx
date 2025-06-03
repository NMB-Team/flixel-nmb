package flixel.sound;

/**
 * A way of grouping sounds for things such as collective volume control
 */
class FlxSoundGroup {
	/**
	 * The sounds in this group
	 */
	public var members = new Array<FlxSound>();

	/**
	 * The maximum number of sounds that can be in this group at once.
	 */
	public var limit:Int = 0;

	/**
	 * The volume of this group
	 */
	public var volume(default, set):Float;

	/**
 	 * Whether or not this group is muted
 	 */
	public var muted(default, set):Bool;

	/**
	 * The pitch of this sound group.
	 */
	public var pitch(default, set):Float;

	/**
	 * The position in milliseconds of this sound group.
	 */
	public var time(default, set):Float;

	/**
	 * The pan of this sound group.
	 */
	public var pan(default, set):Float;

	/**
	 * Create a new sound group
	 * @param	volume  The initial volume of this group
	 */
	public function new(volume = 1., _limit = 0)
	{
		if (_limit > 0) limit = _limit;
		this.volume = volume;
	}

	/**
	 * Add a sound to this group, will remove the sound from any group it is currently in
	 * @param	sound The sound to add to this group
	 * @return True if sound was successfully added, false otherwise
	 */
	public function add(sound:FlxSound):FlxSound {
		if (members.contains(sound) || members.length >= limit) return sound;
		if (sound.group != null) sound.group.members.remove(sound);

		@:bypassAccessor sound.group = this;
		members.push(sound);
		@:privateAccess sound.updateTransform();
		FlxG.sound.list.add(sound);

		return sound;
	}

	/**
	 * Remove a sound from this group
	 * @param	sound The sound to remove
	 * @return True if sound was successfully removed, false otherwise
	 */
	public function remove(sound:FlxSound):FlxSound {
		if (!members.contains(sound)) return sound;
		if (sound == null) return sound;

		@:bypassAccessor sound.group = null;
		members.remove(sound);
		@:privateAccess sound.updateTransform();
		FlxG.sound.list.remove(sound);

		return sound;
	}

	/**
	 * Destroys all sounds in this group and removes them from the group.
	 */
	public function destroy():Void {
		while (members.length > 0) {
			var sound:FlxSound = members[0];
			if (sound == null) {
				members.remove(sound);
				continue;
			}

			remove(sound);
			sound.destroy();
			sound = null;
		}
	}

	/**
	 * Play all sounds in this group.
	 * If a sound is null, it will be skipped.
	 */
	public function play():Void {
		for (sound in members) {
			if (sound == null) continue;
			sound.play();
		}
	}

	/**
	 * Stops all sounds in this group.
	 * If a sound is null, it will be skipped.
	 */
	public function stop():Void {
		for (sound in members) {
			if (sound == null) continue;
			sound.stop();
		}
	}

	/**
	 * Pause all sounds in this group.
	 * If the group is muted, nothing will happen.
	 */
	public function pause():Void {
		for (sound in members) {
			if (sound == null) continue;
			sound.pause();
		}
	}

	/**
	 * Resume all sounds in this group.
	 * If the group is muted, nothing will happen.
	 */
	public function resume():Void {
		for (sound in members) {
			if (sound == null) continue;
			sound.resume();
		}
	}

	/**
	 * Returns the volume of this group, taking `muted` in account.
	 * @return The volume of the group or 0 if the group is muted.
	 */
	public function getVolume():Float {
		return muted ? .0 : volume;
	}

	@:noCompletion function set_volume(value:Float):Float {
		for (sound in members) {
			if (sound == null) continue;
			sound.volume = value;
		}

		return volume;
	}

	@:noCompletion function set_pitch(value:Float):Float {
		for (sound in members) {
			if (sound == null) continue;
			sound.pitch = value;
		}

		return pitch = value;
	}

	@:noCompletion function set_time(value:Float):Float {
		for (sound in members) {
			if (sound == null) continue;
			sound.time = value;
		}

		return time = value;
	}

	@:noCompletion function set_pan(value:Float):Float {
		for (sound in members) {
			if (sound == null) continue;
			sound.pan = value;
		}

		return pan = value;
	}

	@:noCompletion function set_muted(value:Bool):Bool {
		muted = value;
		for (sound in members) {
			if (sound == null) continue;
			sound.updateTransform();
		}

		return muted;
	}
}
