package flixel.graphics.atlas;

import flixel.graphics.atlas.AtlasBase;

typedef AseAtlasBase<T> = AtlasBase<T> & {
	var meta:AseAtlasMeta;
}

/**
 * Metadata attached to aseprite's atlas json, containing info about how the .aseprite file was
 * set up.
 */
typedef AseAtlasMeta = {
	/** The app used to save the file, often https://www.aseprite.org/ */
	var app:String;

	/** The version of Aseprite used to export the json */
	var version:String;

	/** Usually "I8" */
	var format:String;

	/** The dimensions of the image file */
	var size:AtlasSize;

	/** Usually "1" */
	var scale:String;

	/**
	 * The png file exported with this json, if one was
	 *
	 * Note: Does not contain the relative filepath of that image (as of Aseprite 1.3-rc4)
	 */
	var ?image:String;

	/** A list of animation tags */
	var ?frameTags:Array<AseAtlasTag>;

	/** A list of rects, 9-slices and pivots used in the Aseprite file, to be used however you desire */
	var ?slices:Array<AseAtlasSlice>;

	/** A list of the layers used in the Aseprite file, to be used however you desire */
	var ?layers:Array<AseAtlasLayer>;
}

typedef AseAtlasArray = AseAtlasBase<Array<AseAtlasFrame>>;

typedef AseAtlasFrame = AtlasBase.AtlasFrame & {duration:Int}

typedef AseAtlas = AseAtlasBase<HashOrArray<AseAtlasFrame>>;

typedef AseObject = {
	/** The color used to display this object */
	var ?color:AseAtlasColor;

	/** A message attached to this object */
	var ?data:String;
}

/**
 * Aseprite atlases use strings for colors (for some reason). This allows you to easily
 * convert to a more usable format.
 */
abstract AseAtlasColor(String) to String {
	/** Converts the underlying string to an actual color usable by flixel tools */
	public function toFlxColor() {
		// Note: FlxColor.fromString has imports that don't work with macros (see https://github.com/HaxeFlixel/flixel/issues/2893)
		return this == null ? null : Std.parseInt("0x" + this.substr(1));
	}

	public function toString() {
		return this;
	}
}

/**
 * Tags are Aseprite's animation labels. They define a range of frames that all pertain to a
 * certain animation.
 */
typedef AseAtlasTag = AseObject & {
	/** The name of this tag */
	var name:String;

	/** The tag's starting frame */
	var from:Int;

	/** The tag's ending frame */
	var to:Int;

	/** The tag's ending frame */
	var direction:AseAtlasTagDirection;

	/**
	 * The number of times to repeat this animation before aseprite's timeline switched to the next one.
	 *
	 * Note: Used by `FlxAseAtlasUtils` to determine whether an animation loops. Loops if `> 0`.
	 */
	var ?repeat:AseAtlasTagRepeat;
}

/**
 * A string expected to always be a string with a valid int value (or null)
 */
abstract AseAtlasTagRepeat(Null<String>) from Null<String> to Null<String> {
	/**
	 * Whether the underlying value indicates whether to loop this animation
	 */
	public var loops(get, never):Bool;

	inline function get_loops() {
		return this == null || toInt() > 1;
	}

	@:to public inline function toInt() {
		return Std.parseInt(this);
	}

}

enum abstract AseAtlasTagDirection(String) to String {
	final FORWARD = "forward";
	final REVERSE = "reverse";
	final PINGPONG = "pingpong";
	final PINGPONG_REVERSE = "pingpong_reverse";

	/** Whether this plays forward */
	public inline function isForward() {
		return this == FORWARD || this == PINGPONG;
	}

	/** Whether this plays in reverse */
	public inline function isReverse() {
		return !isForward();
	}

	/** Whether this animation plays back and forth */
	public inline function isPingPong() {
		return this == PINGPONG || this == PINGPONG_REVERSE;
	}
}

/**
 * Aseprite atlases allow for the definition of rectangles that can change on various
 * frames of an animation.
 *
 * Note: These values are not implemented, or understood by any of Flixel's tools, yet.
 */
typedef AseAtlasSlice = AseObject & {
	/** The name of this slice */
	var name:String;

	/** The "keyframes" where the slice changes properties */
	var keys:Array<AseAtlasSliceKey>;
}

/**
 * The "keyframes" of a slice.
 */
typedef AseAtlasSliceKey = AseObject & {
	/** The frame that the slice changes properties */
	var frame:Int;

	/** The size and postion of the slice at this frame */
	var bounds:AtlasRect;

	/** The center rect of the 9-slice of this slice, if 9-slice is enabled */
	var ?center:AtlasRect;

	/** The pivot point of this slice */
	var ?pivot:AtlasPos;
}

typedef AseAtlasLayer = AseObject & {
	/** The name of the layer */
	var name:String;

	/** The name of the parent layer */
	var ?group:String;

	/** Ranges from 0 to 0xFF (255) */
	var ?opacity:Int;

	/** The effect added to this layer to change how the colors blend with colors on lower layers */
	var ?blendMode:AseBlendMode;

	/**
	 * Any info that was left on cels of this layer.
	 *
	 * Note: While `data`, `color` and `zIndex` are optional, a cel should always have
	 * at least one of them with a non-null value.
	 */
	var ?cels:Array<AseAtlasCel>;
}

/**
 * Any data attached to this frame cel.
 *
 * Note: These values are not implemented, or understood by any of Flixel's tools, yet.
 */
typedef AseAtlasCel = AseObject & {
	/** The frame number associated with this data */
	var frame:Int;

	/** The intended display z-index of this frame */
	var ?zIndex:Int;
}

/**
 * The different types of blend modes offered by Aseprite's atlases.
 *
 * Note: These values are not implemented, or understood by any of Flixel's tools, yet.
 */
enum abstract AseBlendMode(String) {
	final NORMAL = "normal";
	final DARKEN = "darken";
	final MULTIPLY = "multiply";
	final COLOR_BURN = "color_burn";
	final LIGHTEN = "lighten";
	final SCREEN = "screen";
	final COLOR_DODGE = "color_dodge";
	final ADDITION = "addition";
	final OVERLAY = "overlay";
	final SOFT_LIGHT = "soft_light";
	final HARD_LIGHT = "hard_light";
	final DIFFERENCE = "difference";
	final EXCLUSION = "exclusion";
	final SUBTRACT = "subtract";
	final DIVIDE = "divide";
	final HSL_HUE = "hsl_hue";
	final HSL_SATURATION = "hsl_saturation";
	final HSL_COLOR = "hsl_color";
	final HSL_LUMINOSITY = "hsl_luminosity";
}
