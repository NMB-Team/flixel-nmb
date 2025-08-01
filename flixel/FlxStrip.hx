package flixel;

import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.util.FlxArrayUtil;

/**
 * A very basic rendering component which uses `drawTriangles()`.
 * You have access to `vertices`, `indices` and `uvtData` vectors which are used as data storages for rendering.
 * The whole `FlxGraphic` object is used as a texture for this sprite.
 * Use these links for more info about `drawTriangles()`:
 * @see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/display/Graphics.html#drawTriangles%28%29
 * @see http://help.adobe.com/en_US/as3/dev/WS84753F1C-5ABE-40b1-A2E4-07D7349976C4.html
 * @see https://web.archive.org/web/20170620062159/http://www.flashandmath.com/advanced/p10triangles/index.html
 */
class FlxStrip extends FlxSprite {
	/**
	 * A `Vector` of floats where each pair of numbers is treated as a coordinate location (an x, y pair).
	 */
	public var vertices = new DrawData<Float>();

	/**
	 * A `Vector` of integers or indexes, where every three indexes define a triangle.
	 */
	public var indices = new DrawData<Int>();

	/**
	 * A `Vector` of normalized coordinates used to apply texture mapping.
	 */
	public var uvtData = new DrawData<Float>();

	public var colors = new DrawData<Int>();

	public var repeat = false;

	override public function destroy():Void {
		vertices = null;
		indices = null;
		uvtData = null;
		colors = null;

		super.destroy();
	}

	override public function draw():Void {
		if (alpha == 0 || graphic == null || (vertices == null || vertices.length == 0)) return;

		final cameras = getCamerasLegacy();
		for (camera in cameras) {
			if (!camera.visible || !camera.exists) continue;

			getScreenPosition(_point, camera).subtractPoint(offset);
			camera.drawTrianglesAdvanced(graphic, vertices, indices, uvtData, colors, _point, angle, scale, origin, blend, repeat, antialiasing, colorTransform, shader);
		}
	}
}
