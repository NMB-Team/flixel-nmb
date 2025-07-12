package flixel.util;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tile.FlxTileblock;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * FlxCollision
 *
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
 */
class FlxCollision
{
	// Optimization: Local static vars to reduce allocations
	static final testMatrix = new FlxMatrix();
	static final flashRect = new Rectangle();
	static final zero = new Point();

	/**
	 * A Pixel Perfect Collision check between two FlxSprites. It will do a bounds check first, and if that passes it will run a
	 * pixel perfect match on the intersecting area. Works with rotated and animated sprites. May be slow, so use it sparingly.
	 *
	 * @param   spriteA         The first FlxSprite to test against
	 * @param   spriteB         The second FlxSprite to test against
	 * @param   alphaTolerance  The tolerance value above which alpha pixels are included.
	 *                          Default to 1 (anything that is not fully invisible).
	 * @param   camera          If the collision is taking place in a camera other than
	 *                          `FlxG.camera` (the default/current) then pass it here
	 * @return  Whether the sprites collide
	 */
	public static function pixelPerfectCheck(spriteA:FlxSprite, spriteB:FlxSprite, alphaTolerance:Int = 1, ?camera:FlxCamera):Bool
	{
		// if either of the angles are non-zero, consider the angles of the sprites in the pixel check
		final advanced = spriteA.angle != 0 || spriteB.angle != 0
			|| spriteA.scale.x != 1 || spriteA.scale.y != 1
			|| spriteB.scale.x != 1 || spriteB.scale.y != 1;

		final boundsA = spriteA.getScreenBounds(camera);
		final boundsB = spriteB.getScreenBounds(camera);

		final intersect = boundsA.intersection(boundsB);
		boundsA.put();
		boundsB.put();

		if (intersect.isEmpty || intersect.width < 1 || intersect.height < 1)
		{
			return false;
		}

		spriteA.drawFrame();
		spriteB.drawFrame();

		var bmpA:BitmapData = spriteA.framePixels;
		var bmpB:BitmapData = spriteB.framePixels;

		final overlapWidth = Std.int(intersect.width);
		final overlapHeight = Std.int(intersect.height);

		// More complicated case, if either of the sprites is rotated
		if (advanced)
		{
			testMatrix.identity();
			spriteA.prepareDrawMatrix(testMatrix, camera);
			testMatrix.translate(-intersect.x, -intersect.y);

			// prepare an empty canvas
			final tempA = FlxBitmapDataPool.get(overlapWidth, overlapHeight, true, FlxColor.TRANSPARENT, false);

			// plot the sprite using the matrix
			tempA.draw(bmpA, testMatrix, null, null, null, false);
			bmpA = tempA;

			// (same as above)
			testMatrix.identity();
			spriteB.prepareDrawMatrix(testMatrix, camera);
			testMatrix.translate(-intersect.x, -intersect.y);

			final tempB = FlxBitmapDataPool.get(overlapWidth, overlapHeight, true, FlxColor.TRANSPARENT, false);
			tempB.draw(bmpB, testMatrix, null, null, null, false);
			bmpB = tempB;
		}

		intersect.put();

		flashRect.setTo(0, 0, overlapWidth, overlapHeight);
		final pixelsA = bmpA.getPixels(flashRect);
		final pixelsB = bmpB.getPixels(flashRect);

		if (advanced)
		{
			FlxBitmapDataPool.put(bmpA);
			FlxBitmapDataPool.put(bmpB);
		}

		// Analyze overlapping area of BitmapDatas to check for a collision (alpha values >= alphaTolerance)
		final overlapPixels = overlapWidth * overlapHeight;
		var alphaIdx:Int = 0;

		// check every pixel's alpha against the tolerance, in an interlaced search pattern
		final pixels = overlapWidth * overlapHeight;
		// check every 4 pixels first, then the ones in between
		final numPasses = 4;
		final bytesPer = 4; // RGBA
		for (pass in 0...numPasses)
		{
			final passLength = Math.ceil((pixels - pass) / numPasses);
			for (i in 0...passLength)
			{
				final alphaIdx = (i * bytesPer * numPasses) + pass * bytesPer;
				pixelsA.position = pixelsB.position = alphaIdx;
				final alphaA = pixelsA.readUnsignedByte();
				final alphaB = pixelsB.readUnsignedByte();

				if (alphaA >= alphaTolerance && alphaB >= alphaTolerance)
					return true;
			}
		}

		return false;
	}

	/**
	 * Creates a new `Bitmap` showing the pixel-perfect overlap of the two sprites. `spriteA`
	 * will show as red for every pixel above the alpha threshold, `spriteB` will show as blue
	 * and any pixels where both sprites pass the threshold will show as white. The image size
	 * is determined by how much the sprites overlap, in the camera's view.
	 *
	 * Note: This is mainly used debug `pixelPerfectCheck` calls.
	 *
	 * @param   spriteA         The first FlxSprite to test against
	 * @param   spriteB         The second FlxSprite to test against
	 * @param   alphaTolerance  The tolerance value above which alpha pixels are included.
	 *                          Default to 1 (anything that is not fully invisible).
	 * @param   camera          If the collision is taking place in a camera other than
	 *                          `FlxG.camera` (the default/current) then pass it here
	 */
	public static function drawPixelPerfectCheck(spriteA:FlxSprite, spriteB:FlxSprite, alphaTolerance = 1, ?camera:FlxCamera):Null<BitmapData>
	{
		// if either of the angles are non-zero, consider the angles of the sprites in the pixel check
		final advanced = spriteA.angle != 0 || spriteB.angle != 0 || spriteA.scale.x != 1 || spriteA.scale.y != 1 || spriteB.scale.x != 1
			|| spriteB.scale.y != 1;

		final boundsA = spriteA.getScreenBounds(camera);
		final boundsB = spriteB.getScreenBounds(camera);
		final intersect = boundsA.intersection(boundsB);
		boundsA.put();
		boundsB.put();

		if (intersect.isEmpty || intersect.width < 1 || intersect.height < 1)
		{
			intersect.put();

			return null;
		}

		spriteA.drawFrame();
		spriteB.drawFrame();

		var bmpA = spriteA.framePixels;
		var bmpB = spriteB.framePixels;

		final overlapWidth = Std.int(intersect.width);
		final overlapHeight = Std.int(intersect.height);

		// More complicated case, if either of the sprites is rotated
		if (advanced)
		{
			final testMatrix = new FlxMatrix();

			spriteA.prepareDrawMatrix(testMatrix, camera);
			testMatrix.translate(-intersect.x, -intersect.y);
			final testA2 = FlxBitmapDataPool.get(overlapWidth, overlapHeight, true, 0x0, true);
			testA2.draw(bmpA, testMatrix, null, null, null, false);
			bmpA = testA2;

			spriteB.prepareDrawMatrix(testMatrix, camera);
			testMatrix.translate(-intersect.x, -intersect.y);
			final testB2 = FlxBitmapDataPool.get(overlapWidth, overlapHeight, true, 0x0, true);
			testB2.draw(bmpB, testMatrix, null, null, null, false);
			bmpB = testB2;
		}

		intersect.put();

		final result = new BitmapData(overlapWidth, overlapHeight, false, 0x0);
		final flashRect = new Rectangle(0, 0, overlapWidth, overlapHeight);
		final temp = FlxBitmapDataPool.get(overlapWidth, overlapHeight, true, 0x0, true);
		temp.threshold(bmpA, flashRect, zero, ">", alphaTolerance << 24, 0xFFff0000, 0xFF000000);
		result.copyChannel(temp, flashRect, zero, RED, RED);
		temp.threshold(bmpB, flashRect, zero, ">", alphaTolerance << 24, 0xFF0000ff, 0xFF000000);
		result.copyChannel(bmpB, flashRect, zero, BLUE, BLUE);
		result.threshold(result, flashRect, zero, "==", 0xFFff00ff, 0xFFffffff, 0xFFff00ff);
		FlxBitmapDataPool.put(temp);

		if (advanced)
		{
			FlxBitmapDataPool.put(bmpA);
			FlxBitmapDataPool.put(bmpB);
		}

		return result;
	}

	/**
	 * Creates a "wall" around the given camera which can be used for FlxSprite collision
	 *
	 * @param   camera             The FlxCamera to use for the wall bounds (can be FlxG.camera for the current one)
	 * @param   placeOutside       Whether to place the camera wall outside or inside
	 * @param   thickness          The thickness of the wall in pixels
	 * @param   adjustWorldBounds  Adjust the FlxG.worldBounds based on the wall (true) or leave alone (false)
	 * @return  FlxGroup The 4 FlxTileblocks that are created are placed into this FlxGroup which should be added to your State
	 */
	public static function createCameraWall(camera:FlxCamera, placeOutside = true, thickness:Int, adjustWorldBounds = false):FlxGroup
	{
		var left:FlxTileblock = null;
		var right:FlxTileblock = null;
		var top:FlxTileblock = null;
		var bottom:FlxTileblock = null;

		if (placeOutside)
		{
			left = new FlxTileblock(Math.floor(camera.x - thickness), Math.floor(camera.y), thickness, camera.height);
			right = new FlxTileblock(Math.floor(camera.x + camera.width), Math.floor(camera.y), thickness, camera.height);
			top = new FlxTileblock(Math.floor(camera.x - thickness), Math.floor(camera.y - thickness), camera.width + thickness * 2, thickness);
			bottom = new FlxTileblock(Math.floor(camera.x - thickness), camera.height, camera.width + thickness * 2, thickness);

			if (adjustWorldBounds)
			{
				FlxG.worldBounds.set(camera.x - thickness, camera.y - thickness, camera.width + thickness * 2, camera.height + thickness * 2);
			}
		}
		else
		{
			left = new FlxTileblock(Math.floor(camera.x), Math.floor(camera.y + thickness), thickness, camera.height - (thickness * 2));
			right = new FlxTileblock(Math.floor(camera.x + camera.width - thickness), Math.floor(camera.y + thickness), thickness,
				camera.height - (thickness * 2));
			top = new FlxTileblock(Math.floor(camera.x), Math.floor(camera.y), camera.width, thickness);
			bottom = new FlxTileblock(Math.floor(camera.x), camera.height - thickness, camera.width, thickness);

			if (adjustWorldBounds)
			{
				FlxG.worldBounds.set(camera.x, camera.y, camera.width, camera.height);
			}
		}

		var result = new FlxGroup();

		result.add(left);
		result.add(right);
		result.add(top);
		result.add(bottom);

		return result;
	}

	/**
	 * Calculates at which point where the given line, from start to end, first enters the rect.
	 * If the line starts inside the rect, a copy of start is returned.
	 * If the line never enters the rect, null is returned.
	 *
	 * Note: If a result vector is supplied and the line is outside the rect, null is returned
	 * and the supplied result is unchanged
	 * @since 5.0.0
	 *
	 * @param rect    The rect being entered
	 * @param start   The start of the line
	 * @param end     The end of the line
	 * @param result  Optional result vector, to avoid creating a new instance to be returned.
	 *                Only returned if the line enters the rect.
	 * @return The point of entry of the line into the rect, if possible.
	 */
	public static function calcRectEntry(rect:FlxRect, start:FlxPoint, end:FlxPoint, ?result:FlxPoint):Null<FlxPoint>
	{
		// We must ensure that weak refs are placed back in the pool
		inline function putWeakRefs()
		{
			start.putWeak();
			end.putWeak();
			rect.putWeak();
		}

		// helper to create a new instance if needed, when needed.
		// this allows us to return a value at any point and still put weak refs.
		// otherwise this would be a fragile mess of if-elses
		function getResult(x:Float, y:Float)
		{
			if (result == null)
				result = FlxPoint.get(x, y);
			else
				result.set(x, y);

			putWeakRefs();
			return result;
		}

		function nullResult()
		{
			putWeakRefs();
			return null;
		}

		// does the ray start inside the bounds
		if (rect.containsPoint(start))
			return getResult(start.x, start.y);

		// are both points above, below, left or right of the bounds
		if ((start.y < rect.top    && end.y < rect.top   )
		||  (start.y > rect.bottom && end.y > rect.bottom)
		||  (start.x > rect.right  && end.x > rect.right )
		||  (start.x < rect.left   && end.x < rect.left) )
		{
			return nullResult();
		}

		// check for purely vertical, i.e. has infinite slope
		if (start.x == end.x)
		{
			// determine if it exits top or bottom
			if (start.y < rect.top)
				return getResult(start.x, rect.top);

			return getResult(start.x, rect.bottom);
		}

		// Use y = mx + b formula to define out line, m = slope, b is y when x = 0
		var m = (start.y - end.y) / (start.x - end.x);
		// y - mx = b
		var b = start.y - m * start.x;
		// y = mx + b
		var leftY = m * rect.left + b;
		var rightY = m * rect.right + b;

		// if left and right intercepts are both above and below, there is no entry
		if ((leftY < rect.top && rightY < rect.top) || (leftY > rect.bottom && rightY > rect.bottom))
			return nullResult();

		// if ray moves right
		else if (start.x < end.x)
		{
			if (leftY < rect.top)
			{
				// ray exits on top
				// x = (y - b)/m
				return getResult((rect.top - b) / m, rect.top);
			}

			if (leftY > rect.bottom)
			{
				// ray exits on bottom
				// x = (y - b)/m
				return getResult((rect.bottom - b) / m, rect.bottom);
			}

			// ray exits to the left
			return getResult(rect.left, leftY);
		}

		// if ray moves left
		if (rightY < rect.top)
		{
			// ray exits on top
			// x = (y - b)/m
			return getResult((rect.top - b) / m, rect.top);
		}

		if (rightY > rect.bottom)
		{
			// ray exits on bottom
			// x = (y - b)/m
			return getResult((rect.bottom - b) / m, rect.bottom);
		}

		// ray exits to the right
		return getResult(rect.right, rightY);
	}

	/**
	 * Calculates at which point where the given line, from start to end, was last inside the rect.
	 * If the line ends inside the rect, a copy of end is returned.
	 * If the line is never inside the rect, null is returned.
	 *
	 * Note: If a result vector is supplied and the line is outside the rect, null is returned
	 * and the supplied result is unchanged
	 * @since 5.0.0
	 *
	 * @param rect    The rect being exited
	 * @param start   The start of the line
	 * @param end     The end of the line
	 * @param result  Optional result vector, to avoid creating a new instance to be returned.
	 *                Only returned if the line enters the rect.
	 * @return The point of exit of the line from the rect, if possible.
	 */
	public static inline function calcRectExit(rect, start, end, ?result)
	{
		return calcRectEntry(rect, end, start, result);
	}
}
