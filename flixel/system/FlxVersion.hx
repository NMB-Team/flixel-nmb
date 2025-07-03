package flixel.system;

import flixel.util.FlxStringUtil;

/**
 * Helper object for semantic versioning.
 * @see   http://semver.org/
 */
@:build(flixel.system.macros.FlxGitSHA.buildGitSHA("flixel"))
final class FlxVersion {
	public var major(default, null):Int;
	public var minor(default, null):Int;
	public var patch(default, null):Int;

	@:noCompletion var s:String;

	public function new(major:Int, minor:Int, patch:Int) {
		this.major = major;
		this.minor = minor;
		this.patch = patch;

		// build string representation of this version
		var sha = FlxVersion.sha;
		if (!FlxStringUtil.isNullOrEmpty(sha)) sha = "@" + sha.substring(0, 7);
		s = 'HaxeFlixel $major.$minor.$patch$sha [dtwotwo]';
	}

	/**
	 * Formats the version in the format "HaxeFlixel MAJOR.MINOR.PATCH-COMMIT_SHA",
	 * e.g. HaxeFlixel 6.0.0.
	 * If this is a dev version, the git sha is included.
	 */
	public function toString():String {
		return s;
	}
}
