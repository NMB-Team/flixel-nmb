package flixel.util;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.display.BitmapData;
import openfl.display.BitmapDataChannel;
import openfl.display.BlendMode;
import openfl.display.CapsStyle;
import openfl.display.Graphics;
import openfl.display.JointStyle;
import openfl.display.LineScaleMode;
import openfl.display.Sprite;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * Some handy functions for FlxSprite (FlxObject) manipulation, mostly drawing-related.
 * Note that stage quality impacts the results of the draw() functions -
 * use FlxG.stage.quality = openfl.display.StageQuality.BEST; for best results.
 */
class FlxSpriteUtil {
	/**
	 * Useful helper objects for doing Flash-specific rendering.
	 * Primarily used for "debug visuals" like drawing bounding boxes directly to the screen buffer.
	 */
	public static var flashGfxSprite(default, null) = new Sprite();

	public static var flashGfx(default, null) = flashGfxSprite.graphics;

	/**
	 * Pads a sprite with transparent pixels on each side.
	 *
	 * @param	sprite	The FlxSprite to pad.
	 * @param	left	How many pixels to add to the left.
	 * @param	right	How many pixels to add to the right.
	 * @param	top		How many pixels to add to the top.
	 * @param	bottom	How many pixels to add to the bottom.
	 * @return 	The padded FlxSprite for chaining.
	 */
	public static function pad(sprite:FlxSprite, left = 0, right = 0, top = 0, bottom = 0):FlxSprite {
		final oldPixels = sprite.pixels;
		final newWidth = Std.int(oldPixels.width + left + right);
		final newHeight = Std.int(oldPixels.height + top + bottom);

		final newPixels = new BitmapData(newWidth, newHeight, true, 0x00000000);
		newPixels.copyPixels(oldPixels, oldPixels.rect, new Point(left, top));

		sprite.pixels = newPixels;
		return sprite;
	}

	/**
	 * Rotates the sprite's pixels 90 degrees clockwise.
	 *
	 * @param	sprite	The FlxSprite to rotate.
	 * @return 	The rotated FlxSprite for chaining.
	 */
	public static function rotateClockwise(sprite:FlxSprite):FlxSprite {
		final oldPixels = sprite.pixels;
		final newPixels = new BitmapData(oldPixels.height, oldPixels.width, true, 0x00000000);

		final matrix = new Matrix();
		matrix.translate(-oldPixels.width * .5, -oldPixels.height * .5);
		matrix.rotate(Math.PI * .5);
		matrix.translate(oldPixels.height * .5, oldPixels.width * .5);

		newPixels.draw(oldPixels, matrix, null, null, null, true);

		sprite.pixels = newPixels;
		return sprite;
	}

	/**
	 * Takes two source images (typically from Embedded bitmaps) and puts the resulting image into the output FlxSprite.
	 * Note: It assumes the source and mask are the same size. Different sizes may result in undesired results.
	 * It works by copying the source image (your picture) into the output sprite. Then it removes all areas of it that do not
	 * have an alpha color value in the mask image. So if you draw a big black circle in your mask with a transparent edge, you'll
	 * get a circular image to appear.
	 * May lead to unexpected results if `source` does not have an alpha channel.
	 *
	 * @param	output		The FlxSprite you wish the resulting image to be placed in (will adjust width/height of image)
	 * @param	source		The source image. Typically the one with the image / picture / texture in it.
	 * @param	mask		The mask to apply. Remember the non-alpha zero areas are the parts that will display.
	 * @return 	The FlxSprite for chaining
	 */
	public static function alphaMask(output:FlxSprite, source:FlxGraphicSource, mask:FlxGraphicSource):FlxSprite {
		var data = FlxAssets.resolveBitmapData(source);
		final maskData = FlxAssets.resolveBitmapData(mask);

		if (data == null || maskData == null) return null;

		data = data.clone();
		data.copyChannel(maskData, new Rectangle(0, 0, data.width, data.height), new Point(), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
		output.pixels = data;
		return output;
	}

	/**
	 * Takes the image data from two FlxSprites and puts the resulting image into the output FlxSprite.
	 * Note: It assumes the source and mask are the same size. Different sizes may result in undesired results.
	 * It works by copying the source image (your picture) into the output sprite. Then it removes all areas of it that do not
	 * have an alpha color value in the mask image. So if you draw a big black circle in your mask with a transparent edge, you'll
	 * get a circular image appear.
	 * May lead to unexpected results if `sprite`'s graphic does not have an alpha channel.
	 *
	 * @param	sprite		The source FlxSprite. Typically the one with the image / picture / texture in it.
	 * @param	mask		The FlxSprite containing the mask to apply. Remember the non-alpha zero areas are the parts that will display.
	 * @param	output		The FlxSprite you wish the resulting image to be placed in (will adjust width/height of image)
	 * @return 	The output FlxSprite for chaining
	 */
	public static function alphaMaskFlxSprite(sprite:FlxSprite, mask:FlxSprite, output:FlxSprite):FlxSprite {
		sprite.drawFrame();

		final data = sprite.pixels.clone();
		data.copyChannel(mask.pixels, new Rectangle(0, 0, sprite.width, sprite.height), new Point(), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
		output.pixels = data;
		return output;
	}

	/**
	 * Checks the x/y coordinates of the FlxSprite and keeps them within the
	 * area of 0, 0, FlxG.width, FlxG.height (i.e. wraps it around the screen)
	 *
	 * @param	sprite		The FlxSprite to keep within the screen
	 * @param	left		Whether to activate screen wrapping on the left side of the screen
	 * @param	right		Whether to activate screen wrapping on the right side of the screen
	 * @param	top			Whether to activate screen wrapping on the top of the screen
	 * @param	bottom		Whether to activate screen wrapping on the bottom of the screen
	 * @return	The FlxSprite for chaining
	 */
	public static function screenWrap(sprite:FlxSprite, left = true, right = true, top = true, bottom = true):FlxSprite {
		if (left && ((sprite.x + sprite.frameWidth * .5) <= 0))
			sprite.x = FlxG.width;
		else if (right && (sprite.x >= FlxG.width))
			sprite.x = 0;

		if (top && ((sprite.y + sprite.frameHeight * .5) <= 0))
			sprite.y = FlxG.height;
		else if (bottom && (sprite.y >= FlxG.height))
			sprite.y = 0;

		return sprite;
	}

	/**
	 * Makes sure a FlxSprite doesn't leave the specified area - most common use case is to call this every frame in update().
	 * If you call this without specifying an area, the game area (FlxG.width / height as max) will be used. Takes the graphic size into account.
	 *
	 * @param	sprite	The FlxSprite to bound to an area
	 * @param	minX	The minimum x position allowed
	 * @param	maxX	The maximum x position allowed
	 * @param	minY	The minimum y position allowed
	 * @param	maxY	The minimum y position allowed
	 * @return	The FlxSprite for chaining
	 */
	public static function bound(sprite:FlxSprite, minX = .0, maxX = .0, minY = .0, maxY = .0):FlxSprite {
		if (maxX <= 0) maxX = FlxG.width;
		if (maxY <= 0) maxY = FlxG.height;

		maxX -= sprite.frameWidth;
		maxY -= sprite.frameHeight;

		sprite.setPosition(FlxMath.bound(sprite.x, minX, maxX), FlxMath.bound(sprite.y, minX, maxX));

		return sprite;
	}

	/**
	 * Checks the sprite's screen bounds of the FlxSprite and keeps them within the camera by wrapping it around.
	 *
	 * @param   sprite  The FlxSprite to wrap.
	 * @param   camera  The camera to wrap around. If `null`, `sprite.getDefaultCamera()` is used.
	 * @param   edges   The edges FROM which to wrap. Use constants like `LEFT`, `RIGHT`, `UP|DOWN` or `ANY`.
	 * @return  The FlxSprite for chaining
	 * @since 4.11.0
	 */
	public static function cameraWrap(sprite:FlxSprite, ?camera:FlxCamera, edges:FlxDirectionFlags = ANY):FlxSprite {
		camera ??= sprite.getDefaultCamera();

		final spriteBounds = sprite.getScreenBounds(camera);
		final offset = FlxPoint.get(
			sprite.x - spriteBounds.x - camera.scroll.x,
			sprite.y - spriteBounds.y - camera.scroll.y
		);

		if (edges.has(LEFT) && spriteBounds.right < camera.viewMarginLeft)
			sprite.x = camera.viewRight + offset.x;
		else if (edges.has(RIGHT) && spriteBounds.left > camera.viewMarginRight)
			sprite.x = camera.viewLeft + offset.x - spriteBounds.width;

		if (edges.has(UP) && spriteBounds.bottom < camera.viewMarginTop)
			sprite.y = camera.viewBottom + offset.y;
		else if (edges.has(DOWN) && spriteBounds.top > camera.viewMarginBottom)
			sprite.y = camera.viewTop + offset.y - spriteBounds.height;

		spriteBounds.put();
		offset.put();

		return sprite;
	}

	/**
	 * Checks the sprite's screen bounds and keeps it entirely within the camera.
	 *
	 * @param   sprite  The FlxSprite to restrict.
	 * @param   camera  The camera resitricting the sprite. If left null, `sprite.getDefaultCamera()` is used.
	 * @param   edges   The edges to restrict. Use constants like `LEFT`, `RIGHT`, `UP|DOWN` or `ANY`.
	 * @return  The FlxSprite for chaining
	 * @since 4.11.0
	 */
	public static function cameraBound(sprite:FlxSprite, ?camera:FlxCamera, edges:FlxDirectionFlags = ANY):FlxSprite {
		camera ??= sprite.getDefaultCamera();

		final spriteBounds = sprite.getScreenBounds(camera);
		final offset = FlxPoint.get(
			sprite.x - spriteBounds.x - camera.scroll.x,
			sprite.y - spriteBounds.y - camera.scroll.y
		);

		if (edges.has(LEFT) && spriteBounds.left < camera.viewMarginLeft)
			sprite.x = camera.viewLeft + offset.x;
		else if (edges.has(RIGHT) && spriteBounds.right > camera.viewMarginRight)
			sprite.x = camera.viewRight + offset.x - spriteBounds.width;

		if (edges.has(UP) && spriteBounds.top < camera.viewMarginTop)
			sprite.y = camera.viewTop + offset.y;
		else if (edges.has(DOWN) && spriteBounds.bottom > camera.viewMarginBottom)
			sprite.y = camera.viewBottom + offset.y - spriteBounds.height;

		spriteBounds.put();
		offset.put();

		return sprite;
	}

	/**
	 * Aligns a set of FlxObjects so there is equal spacing between them
	 *
	 * @param	objects				An Array of FlxObjects
	 * @param	startX				The base X coordinate to start the spacing from
	 * @param	startY				The base Y coordinate to start the spacing from
	 * @param	horizontalSpacing	The amount of pixels between each sprite horizontally. Set to `null` to just keep the current X position of each object.
	 * @param	verticalSpacing		The amount of pixels between each sprite vertically. Set to `null` to just keep the current Y position of each object.
	 * @param	spaceFromBounds		If set to true the h/v spacing values will be added to the width/height of the sprite, if false it will ignore this
	 * @param	position			A function with the signature `(target:FlxObject, x:Float, y:Float):Void`. You can use this to tween objects into their spaced position, etc.
	 */
	public static function space(objects:Array<FlxObject>, startX:Float, startY:Float, ?horizontalSpacing:Float, ?verticalSpacing:Float, spaceFromBounds = false, ?position:FlxObject -> Float -> Float -> Void):Void {
		var prevWidth = .0;
		var runningX = .0;

		if (horizontalSpacing != null) {
			if (spaceFromBounds)
				prevWidth = objects[0].width;
			runningX = startX;
		} else
			runningX = objects[0].x;

		var prevHeight = .0;
		var runningY = .0;

		if (verticalSpacing != null) {
			if (spaceFromBounds)
				prevHeight = objects[0].height;
			runningY = startY;
		} else
			runningY = objects[0].y;

		if (position != null)
			position(objects[0], runningX, runningY);
		else
			objects[0].setPosition(runningX, runningY);

		var curX = .0;
		var curY = .0;

		for (i in 1...objects.length) {
			final object = objects[i];

			if (horizontalSpacing != null) {
				curX = runningX + prevWidth + horizontalSpacing;
				runningX = curX;
			} else
				curX = object.x;

			if (verticalSpacing != null) {
				curY = runningY + prevHeight + verticalSpacing;
				runningY = curY;
			} else
				curY = object.y;

			if (position != null)
				position(object, curX, curY);
			else
				object.setPosition(curX, curY);

			if (spaceFromBounds) {
				prevWidth = object.width;
				prevHeight = object.height;
			}
		}
	}

	/**
	 * This function draws a line on a FlxSprite from position X1,Y1
	 * to position X2,Y2 with the specified color.
	 *
	 * @param	sprite		The FlxSprite to manipulate
	 * @param	startX		X coordinate of the line's start point.
	 * @param	startY		Y coordinate of the line's start point.
	 * @param	endX		X coordinate of the line's end point.
	 * @param	endY		Y coordinate of the line's end point.
	 * @param	lineStyle	A LineStyle typedef containing the params of Graphics.lineStyle()
	 * @param	drawStyle	A DrawStyle typedef containing the params of BitmapData.draw()
	 * @return 	The FlxSprite for chaining
	 */
	public static function drawLine(sprite:FlxSprite, startX:Float, startY:Float, endX:Float, endY:Float, ?lineStyle:LineStyle, ?drawStyle:DrawStyle):FlxSprite {
		lineStyle = getDefaultLineStyle(lineStyle);
		beginDraw(0x0, lineStyle);
		flashGfx.moveTo(startX, startY);
		flashGfx.lineTo(endX, endY);
		endDraw(sprite, drawStyle);
		return sprite;
	}

	/**
	 * This function draws a curve on a FlxSprite from position X1,Y1
	 * to anchor position X2,Y2 using control points X3,Y3 with the specified color.
	 *
	 * @param	sprite		The FlxSprite to manipulate
	 * @param	startX		X coordinate of the curve's start point.
	 * @param	startY		Y coordinate of the curve's start point.
	 * @param	endX		X coordinate of the curve's end/anchor point.
	 * @param	endY		Y coordinate of the curve's end/anchor point.
	 * @param	controlX	X coordinate of the curve's control point.
	 * @param	controlY	Y coordinate of the curve's control point.
	 * @param	fillColor		The ARGB color to fill this curve with. FlxColor.TRANSPARENT (0x0) means no fill. Filling a curve draws a line from End to Start to complete the figure.
	 * @param	lineStyle	A LineStyle typedef containing the params of Graphics.lineStyle()
	 * @param	drawStyle	A DrawStyle typedef containing the params of BitmapData.draw()
	 * @return 	The FlxSprite for chaining
	 */
	public static function drawCurve(sprite:FlxSprite, startX:Float, startY:Float, endX:Float, endY:Float, controlX:Float, controlY:Float, fillColor = FlxColor.TRANSPARENT, ?lineStyle:LineStyle, ?drawStyle:DrawStyle):FlxSprite {
		lineStyle = getDefaultLineStyle(lineStyle);
		beginDraw(fillColor, lineStyle);
		flashGfx.moveTo(startX, startY);
		flashGfx.curveTo(endX, endY, controlX, controlY);
		endDraw(sprite, drawStyle);
		return sprite;
	}

	/**
	 * This function draws a rectangle on a FlxSprite.
	 *
	 * @param	sprite		The FlxSprite to manipulate
	 * @param	x			X coordinate of the rectangle's start point.
	 * @param	y			Y coordinate of the rectangle's start point.
	 * @param	width		Width of the rectangle
	 * @param	height		Height of the rectangle
	 * @param	fillColor		The ARGB color to fill this rectangle with. FlxColor.TRANSPARENT (0x0) means no fill.
	 * @param	lineStyle	A LineStyle typedef containing the params of Graphics.lineStyle()
	 * @param	drawStyle	A DrawStyle typedef containing the params of BitmapData.draw()
	 * @return 	The FlxSprite for chaining
	 */
	public static function drawRect(sprite:FlxSprite, x:Float, y:Float, width:Float, height:Float, fillColor = FlxColor.WHITE, ?lineStyle:LineStyle, ?drawStyle:DrawStyle):FlxSprite {
		beginDraw(fillColor, lineStyle);
		flashGfx.drawRect(x, y, width, height);
		endDraw(sprite, drawStyle);
		return sprite;
	}

	/**
	 * This function draws a rounded rectangle on a FlxSprite.
	 *
	 * @param	sprite			The FlxSprite to manipulate
	 * @param	x				X coordinate of the rectangle's start point.
	 * @param	y				Y coordinate of the rectangle's start point.
	 * @param	width			Width of the rectangle
	 * @param	height			Height of the rectangle
	 * @param	ellipseWidth	The width of the ellipse used to draw the rounded corners
	 * @param	ellipseHeight	The height of the ellipse used to draw the rounded corners
	 * @param	fillColor			The ARGB color to fill this rectangle with. FlxColor.TRANSPARENT (0x0) means no fill.
	 * @param	lineStyle		A LineStyle typedef containing the params of Graphics.lineStyle()
	 * @param	drawStyle		A DrawStyle typedef containing the params of BitmapData.draw()
	 * @return 	The FlxSprite for chaining
	 */
	public static function drawRoundRect(sprite:FlxSprite, x:Float, y:Float, width:Float, height:Float, ellipseWidth:Float, ellipseHeight:Float, fillColor = FlxColor.WHITE, ?lineStyle:LineStyle, ?drawStyle:DrawStyle):FlxSprite {
		beginDraw(fillColor, lineStyle);
		flashGfx.drawRoundRect(x, y, width, height, ellipseWidth, ellipseHeight);
		endDraw(sprite, drawStyle);
		return sprite;
	}

	/**
	 * This function draws a rounded rectangle on a FlxSprite. Same as drawRoundRect,
	 * except it allows you to determine the radius of each corner individually.
	 *
	 * @param	sprite				The FlxSprite to manipulate
	 * @param	x					X coordinate of the rectangle's start point.
	 * @param	y					Y coordinate of the rectangle's start point.
	 * @param	sidth				Width of the rectangle
	 * @param	height				Height of the rectangle
	 * @param	topLeftRadius		The radius of the top left corner of the rectangle
	 * @param	topRightRadius		The radius of the top right corner of the rectangle
	 * @param	bottomLeftRadius	The radius of the bottom left corner of the rectangle
	 * @param	bottomRightRadius	The radius of the bottom right corner of the rectangle
	 * @param	fillColor				The ARGB color to fill this rectangle with. FlxColor.TRANSPARENT (0x0) means no fill.
	 * @param	lineStyle			A LineStyle typedef containing the params of Graphics.lineStyle()
	 * @param	drawStyle			A DrawStyle typedef containing the params of BitmapData.draw()
	 * @return 	The FlxSprite for chaining
	 */
	public static function drawRoundRectComplex(sprite:FlxSprite, x:Float, y:Float, width:Float, height:Float, topLeftRadius:Float, topRightRadius:Float, bottomLeftRadius:Float, bottomRightRadius:Float, fillColor = FlxColor.WHITE, ?lineStyle:LineStyle, ?drawStyle:DrawStyle):FlxSprite {
		beginDraw(fillColor, lineStyle);
		flashGfx.drawRoundRectComplex(x, y, width, height, topLeftRadius, topRightRadius, bottomLeftRadius, bottomRightRadius);
		endDraw(sprite, drawStyle);
		return sprite;
	}

	/**
	 * This function draws a circle on a FlxSprite at position X,Y with the specified color.
	 *
	 * @param	sprite		The FlxSprite to manipulate
	 * @param	x 			X coordinate of the circle's center (automatically centered on the bitmap if -1)
	 * @param	y 			Y coordinate of the circle's center (automatically centered on the bitmap if -1)
	 * @param	radius 		Radius of the circle (makes sure the circle fully fits on the sprite's graphic if < 1, assuming and and y are centered)
	 * @param	fillColor 		The ARGB color to fill this circle with. FlxColor.TRANSPARENT (0x0) means no fill.
	 * @param	lineStyle	A LineStyle typedef containing the params of Graphics.lineStyle()
	 * @param	drawStyle	A DrawStyle typedef containing the params of BitmapData.draw()
	 * @return 	The FlxSprite for chaining
	 */
	public static function drawCircle(sprite:FlxSprite, x = -1., y = -1., radius = -1., fillColor = FlxColor.WHITE, ?lineStyle:LineStyle, ?drawStyle:DrawStyle):FlxSprite {
		if (x == -1 || y == -1) {
			if (x == -1)
				x = sprite.frameWidth * .5;
			if (y == -1)
				y = sprite.frameHeight * .5;
		}

		if (radius < 1) {
			final minVal = Math.min(sprite.frameWidth, sprite.frameHeight);
			radius = (minVal * .5);
		}

		beginDraw(fillColor, lineStyle);
		flashGfx.drawCircle(x, y, radius);
		endDraw(sprite, drawStyle);
		return sprite;
	}

	/**
	 * This function draws an ellipse on a FlxSprite.
	 *
	 * @param	sprite		The FlxSprite to manipulate
	 * @param	x			X coordinate of the ellipse's start point.
	 * @param	y			Y coordinate of the ellipse's start point.
	 * @param	width		Width of the ellipse
	 * @param	height		Height of the ellipse
	 * @param	fillColor		The ARGB color to fill this ellipse with. FlxColor.TRANSPARENT (0x0) means no fill.
	 * @param	lineStyle	A LineStyle typedef containing the params of Graphics.lineStyle()
	 * @param	drawStyle	A DrawStyle typedef containing the params of BitmapData.draw()
	 * @return 	The FlxSprite for chaining
	 */
	public static function drawEllipse(sprite:FlxSprite, x:Float, y:Float, width:Float, height:Float, fillColor = FlxColor.WHITE, ?lineStyle:LineStyle, ?drawStyle:DrawStyle):FlxSprite {
		beginDraw(fillColor, lineStyle);
		flashGfx.drawEllipse(x, y, width, height);
		endDraw(sprite, drawStyle);
		return sprite;
	}

	/**
	 * This function draws a simple, equilateral triangle on a FlxSprite.
	 *
	 * @param	sprite		The FlxSprite to manipulate
	 * @param	x			X position of the triangle
	 * @param	y			Y position of the triangle
	 * @param	height		Height of the triangle
	 * @param	fillColor		The ARGB color to fill this triangle with. FlxColor.TRANSPARENT (0x0) means no fill.
	 * @param	lineStyle	A LineStyle typedef containing the params of Graphics.lineStyle()
	 * @param	drawStyle	A DrawStyle typedef containing the params of BitmapData.draw()
	 * @return 	The FlxSprite for chaining
	 */
	public static function drawTriangle(sprite:FlxSprite, x:Float, y:Float, height:Float, fillColor = FlxColor.WHITE, ?lineStyle:LineStyle, ?drawStyle:DrawStyle):FlxSprite {
		beginDraw(fillColor, lineStyle);
		flashGfx.moveTo(x + height * .5, y);
		flashGfx.lineTo(x + height, height + y);
		flashGfx.lineTo(x, height + y);
		flashGfx.lineTo(x + height * .5, y);
		endDraw(sprite, drawStyle);
		return sprite;
	}

	/**
	 * This function draws a polygon on a FlxSprite.
	 *
	 * @param	sprite		The FlxSprite to manipulate
	 * @param	vertices	Array of Vertices to use for drawing the polygon
	 * @param	fillColor		The ARGB color to fill this polygon with. FlxColor.TRANSPARENT (0x0) means no fill.
	 * @param	lineStyle	A LineStyle typedef containing the params of Graphics.lineStyle()
	 * @param	drawStyle	A DrawStyle typedef containing the params of BitmapData.draw()
	 * @return 	The FlxSprite for chaining
	 */
	public static function drawPolygon(sprite:FlxSprite, vertices:Array<FlxPoint>, fillColor:FlxColor = FlxColor.WHITE, ?lineStyle:LineStyle,
			?drawStyle:DrawStyle):FlxSprite
	{
		beginDraw(fillColor, lineStyle);

		final p = vertices.shift();
		flashGfx.moveTo(p.x, p.y);
		for (p in vertices)
			flashGfx.lineTo(p.x, p.y);

		endDraw(sprite, drawStyle);
		vertices.unshift(p);
		return sprite;
	}

	/**
	 * Helper function that the drawing functions use at the start to set the color and lineStyle.
	 *
	 * @param	fillColor		The ARGB color to use for drawing
	 * @param	lineStyle	A LineStyle typedef containing the params of Graphics.lineStyle()
	 */
	@:noUsing public static inline function beginDraw(fillColor:FlxColor, ?lineStyle:LineStyle):Void {
		flashGfx.clear();
		setLineStyle(lineStyle);

		if (fillColor != FlxColor.TRANSPARENT)
			flashGfx.beginFill(fillColor.rgb, fillColor.alphaFloat);
	}

	/**
	 * Helper function that the drawing functions use at the end.
	 *
	 * @param	sprite		The FlxSprite to draw to
	 * @param	drawStyle	A DrawStyle typedef containing the params of BitmapData.draw()
	 * @return 	The FlxSprite for chaining
	 */
	public static inline function endDraw(sprite:FlxSprite, ?drawStyle:DrawStyle):FlxSprite {
		flashGfx.endFill();
		updateSpriteGraphic(sprite, drawStyle);
		return sprite;
	}

	/**
	 * Just a helper function that is called at the end of the draw functions
	 * to handle a few things related to updating a sprite's graphic.
	 *
	 * @param	Sprite		The FlxSprite to manipulate
	 * @param	drawStyle	A DrawStyle typedef containing the params of BitmapData.draw()
	 * @return 	The FlxSprite for chaining
	 */
	public static function updateSpriteGraphic(sprite:FlxSprite, ?drawStyle:DrawStyle):FlxSprite {
		if (drawStyle == null)
			drawStyle = {smoothing: false};
		else if (drawStyle.smoothing == null)
			drawStyle.smoothing = false;

		sprite.pixels.draw(flashGfxSprite, drawStyle.matrix, drawStyle.colorTransform, drawStyle.blendMode, drawStyle.clipRect, drawStyle.smoothing);
		sprite.dirty = true;
		return sprite;
	}

	/**
	 * Just a helper function that is called in the draw functions
	 * to set the lineStyle via Graphics.lineStyle()
	 *
	 * @param	lineStyle	The lineStyle typedef
	 */
	@:noUsing public static inline function setLineStyle(lineStyle:LineStyle):Void {
		if (lineStyle == null) return;

		final color = (lineStyle.color == null) ? FlxColor.BLACK : lineStyle.color;

		lineStyle.thickness ??= 1;
		lineStyle.pixelHinting ??= false;
		lineStyle.miterLimit ??= 3;

		flashGfx.lineStyle(lineStyle.thickness, color.rgb, color.alphaFloat, lineStyle.pixelHinting, lineStyle.scaleMode, lineStyle.capsStyle,
			lineStyle.jointStyle, lineStyle.miterLimit);
	}

	/**
	 * Helper function for the default line styles of drawLine() and drawCurve()
	 *
	 * @param   lineStyle   The lineStyle typedef
	 */
	public static inline function getDefaultLineStyle(?lineStyle:LineStyle):LineStyle {
		lineStyle ??= {thickness: 1, color: FlxColor.WHITE};
		lineStyle.thickness ??= 1;
		lineStyle.color ??= FlxColor.WHITE;

		return lineStyle;
	}

	/**
	 * Fills this sprite's graphic with a specific color.
	 *
	 * @param	Sprite	The FlxSprite to manipulate
	 * @param	FillColor	The color with which to fill the graphic, format 0xAARRGGBB.
	 * @return 	The FlxSprite for chaining
	 */
	public static function fill(sprite:FlxSprite, fillColor:FlxColor):FlxSprite {
		sprite.pixels.fillRect(sprite.pixels.rect, fillColor);

		if (sprite.pixels != sprite.framePixels)
			sprite.dirty = true;

		return sprite;
	}

	/**
	 * A simple flicker effect for sprites achieved by toggling visibility.
	 *
	 * @param	object				The sprite.
	 * @param	duration			How long to flicker for (in seconds). `0` means "forever".
	 * @param	interval			In what interval to toggle visibility. Set to `FlxG.elapsed` if `<= 0`!
	 * @param	endVisibility		Force the visible value when the flicker completes, useful with fast repetitive use.
	 * @param	forceRestart		Force the flicker to restart from beginning, discarding the flickering effect already in progress if there is one.
	 * @param	completionCallback	An optional callback that will be triggered when a flickering has finished.
	 * @param	progressCallback	An optional callback that will be triggered when visibility is toggled.
	 * @return The FlxFlicker object. FlxFlickers are pooled internally, so beware of storing references.
	 */
	public static inline function flicker(object:FlxObject, duration = 1., interval = .04, endVisibility = true, forceRestart = true, ?completionCallback:FlxFlicker -> Void, ?progressCallback:FlxFlicker -> Void):FlxFlicker {
		return FlxFlicker.flicker(object, duration, interval, endVisibility, forceRestart, completionCallback, progressCallback);
	}

	/**
	 * Returns whether an object is flickering or not.
	 *
	 * @param  object 	The object to check against.
	 */
	public static inline function isFlickering(object:FlxObject):Bool {
		return FlxFlicker.isFlickering(object);
	}

	/**
	 * Stops flickering of the object. Also it will make the object visible.
	 *
	 * @param  object 	The object to stop flickering.
	 * @return The FlxObject for chaining
	 */
	public static inline function stopFlickering(object:FlxObject):FlxObject {
		FlxFlicker.stopFlickering(object);
		return object;
	}

	/**
	 * Fade in a sprite, tweening alpha to 1.
	 *
	 * @param  sprite 	The object to fade.
	 * @param  duration How long the fade will take (in seconds).
	 * @return The FlxSprite for chaining
	 */
	public static inline function fadeIn(sprite:FlxSprite, duration = 1., ?resetAlpha:Bool, ?onComplete:TweenCallback):FlxSprite {
		if (resetAlpha) sprite.alpha = 0;
		FlxTween.num(sprite.alpha, 1, duration, {onComplete: onComplete}, alphaTween.bind(sprite));
		return sprite;
	}

	/**
	 * Fade out a sprite, tweening alpha to 0.
	 *
	 * @param  sprite 	The object to fade.
	 * @param  duration How long the fade will take (in seconds).
	 * @return The FlxSprite for chaining
	 */
	public static inline function fadeOut(sprite:FlxSprite, duration = 1., ?onComplete:TweenCallback):FlxSprite {
		FlxTween.num(sprite.alpha, 0, duration, {onComplete: onComplete}, alphaTween.bind(sprite));
		return sprite;
	}

	static function alphaTween(sprite:FlxSprite, f:Float):Void {
		sprite.alpha = f;
	}

	/**
	 * Change's this sprite's color transform to apply a tint effect.
	 * Mimics Adobe Animate's "Tint" color effect
	 *
	 * @param   tint  The color to tint the sprite, where alpha determines the strength
	 *
	 * @since 5.4.0
	 */
	public static inline function setTint(sprite:FlxSprite, tint:FlxColor) {
		final strength = tint.alphaFloat;
		inline function scaleInt(i:Int):Int {
			return Math.round(i * strength);
		}

		final mult = 1 - strength;
		sprite.setColorTransform(mult, mult, mult, 1, scaleInt(tint.red), scaleInt(tint.green), scaleInt(tint.blue));
	}

	/**
	 * Uses `FlxTween.num` to call `setTint` on the target sprite
	 *
	 * @param   tint        The color to tint the sprite, where alpha determines the max strength
	 * @param   duration    How long the flash lasts
	 * @param   func        Controls the amount of tint over time. The input float goes from 0 to
	 *                      1.0, an output of 1.0 means the tint is fully applied. If omitted,
	 *                      `(n)->1-n` is used, meaning it starts at full tint and fades away
	 * @param   onComplete  Called when the flash is complete
	 *
	 * @since 5.4.0
	 */
	public static inline function flashTint(sprite:FlxSprite, tint = FlxColor.WHITE, duration = .5, ?func:(Float) -> Float, ?onComplete:() -> Void) {
		final options:TweenOptions = onComplete != null ? { onComplete: (_)->onComplete} : null;

		func ??= n -> 1 - FlxEase.circIn(n); // start at full, fade out

		var color = tint.rgb;
		var strength = tint.alphaFloat;
		FlxTween.num(0, 1, duration, options, n -> {
			color.alphaFloat = strength * func(n);
			setTint(sprite, color);
		});

		return sprite;
	}

	/**
	 * Centers a sprite on another sprite based on the specified axes.
	 *
	 * @param sprite The sprite to be centered.
	 * @param spr The target sprite on which to center.
	 * @param axes The axes on which to center the sprite.
	 */
	public static function centerOnSprite(sprite:FlxSprite, spr:FlxSprite, axes:FlxAxes) {
		final x = axes.x ? spr.x + (spr.width - sprite.width) * .5 : sprite.x;
		final y = axes.y ? spr.y + (spr.height - sprite.height) * .5 : sprite.y;
		return (axes.x && axes.y) ? ((x + y) * .5) : (axes.x ? x : y);
	}

	/**
	 * Change's this sprite's color transform to brighten or darken it.
	 * Mimics Adobe Animate's "Brightness" color effect
	 *
	 * @param   brightness  Use 1.0 to fully brighten, -1.0 to fully darken, or anything inbetween
	 *
	 * @since 5.4.0
	 */
	public static inline function setBrightness(sprite:FlxSprite, brightness:Float) {
		final mult = 1 - Math.abs(brightness);
		final offset = Math.round(Math.max(0, 0xFF * brightness));
		sprite.setColorTransform(mult, mult, mult, 1, offset, offset, offset);
	}
}

typedef LineStyle = {
	?thickness:Float,
	?color:FlxColor,
	?pixelHinting:Bool,
	?scaleMode:LineScaleMode,
	?capsStyle:CapsStyle,
	?jointStyle:JointStyle,
	?miterLimit:Float
}

typedef DrawStyle = {
	?matrix:Matrix,
	?colorTransform:ColorTransform,
	?blendMode:BlendMode,
	?clipRect:Rectangle,
	?smoothing:Bool
}