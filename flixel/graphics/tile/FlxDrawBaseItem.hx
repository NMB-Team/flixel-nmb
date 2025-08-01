package flixel.graphics.tile;

import flixel.FlxTypes;
import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

/**
 * @author Zaphod
 */
abstract class FlxDrawBaseItem<T:FlxDrawBaseItem<T>>
{
	/**
	 * Tracks the total number of draw calls made each frame.
	 */
	public static var drawCalls:Int = 0;

	public var nextTyped:T;

	public var next:FlxDrawBaseItem<T>;

	public var graphics:FlxGraphic;
	public var antialiasing:Bool = false;
	public var colored:Bool = false;
	public var hasColorOffsets:Bool = false;
	public var blend:BlendMode;

	public var type:FlxDrawItemType = NONE;

	public var numVertices(get, never):Int;

	public var numTriangles(get, never):Int;

	public function new() {}

	public function reset():Void
	{
		graphics = null;
		antialiasing = false;
		nextTyped = null;
		next = null;
	}

	public function dispose():Void
	{
		graphics = null;
		next = null;
		type = NONE;
		nextTyped = null;
	}

	public function render(camera:FlxCamera):Void
	{
		drawCalls++;
	}

	public abstract function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform):Void;

	function get_numVertices():Int
	{
		return 0;
	}

	function get_numTriangles():Int
	{
		return 0;
	}
}

enum abstract FlxDrawItemType(ByteUInt)
{
	var NONE;
	var TILES;
	var TRIANGLES;
}
