package flixel.graphics.frames;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.graphics.frames.FlxFramesCollection.FlxFrameCollectionType;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxBitmapDataUtil;
import openfl.display.BitmapData;

/**
 * Single-frame collection.
 * Could be useful for non-animated sprites.
 */
class FlxImageFrame extends FlxFramesCollection {
	/**
	 * Single frame of this frame collection.
	 * Added this var for faster access, so you don't need to type something like: `imageFrame.frames[0]`
	 */
	public var frame(get, never):FlxFrame;

	private function new(parent:FlxGraphic, ?border:FlxPoint) {
		super(parent, FlxFrameCollectionType.IMAGE, border);
	}

	/**
	 * Generates a `FlxImageFrame` object with empty frame of specified size.
	 *
	 * @param   graphic     Graphic for the `FlxImageFrame`.
	 * @param   frameRect   The size of the empty frame to generate
	 *                      (only `width` and `height` of the `frameRect` need to be set properly).
	 * @return  Newly created `FlxImageFrame` object with empty frame of specified size.
	 */
	public static function fromEmptyFrame(graphic:FlxGraphic, frameRect:FlxRect):FlxImageFrame {
		if (graphic == null || frameRect == null) return null;

		// find ImageFrame, if there is one already
		var imageFrame = FlxImageFrame.findEmptyFrame(graphic, frameRect);
		if (imageFrame != null) return imageFrame;

		// or create it, if there is no such object
		imageFrame = new FlxImageFrame(graphic);
		imageFrame.addEmptyFrame(frameRect);
		return imageFrame;
	}

	/**
	 * Generates a `FlxImageFrame` object from the specified `FlxFrame`.
	 *
	 * @param   source   `FlxFrame` to generate `FlxImageFrame` from.
	 * @return  Created `FlxImageFrame` object.
	 */
	public static function fromFrame(source:FlxFrame):FlxImageFrame {
		final graphic = source.parent;
		final rect = source.frame;

		var imageFrame = FlxImageFrame.findFrame(graphic, rect);
		if (imageFrame != null) return imageFrame;

		imageFrame = new FlxImageFrame(graphic);
		imageFrame.addSpriteSheetFrame(rect.copyTo(FlxRect.get()));
		return imageFrame;
	}

	/**
	 * Creates a `FlxImageFrame` object for the whole image.
	 *
	 * @param   source   image graphic for the `FlxImageFrame`.
	 * @return  Newly created `FlxImageFrame` object for specified graphic.
	 */
	public static function fromImage(source:FlxGraphicAsset):FlxImageFrame {
		return fromRectangle(source, null);
	}

	/**
	 * Creates `FlxImageFrame` for the specified region of `FlxGraphic`.
	 *
	 * @param   graphic   Graphic for `FlxImageFrame`.
	 * @param   region    Region of image to create the `FlxImageFrame` for.
	 * @return  Newly created `FlxImageFrame` object for the specified region of `FlxGraphic` object.
	 */
	public static function fromGraphic(graphic:FlxGraphic, ?region:FlxRect):FlxImageFrame {
		// TODO: look into this
		if (graphic == null || graphic.isDestroyed) return null;

		// find ImageFrame, if there is one already
		final checkRegion = FlxRect.get(0, 0, graphic.width, graphic.height);
		region?.copyTo(checkRegion);

		final imageFrame = FlxImageFrame.findFrame(graphic, checkRegion);
		checkRegion.put();
		if (imageFrame != null) {
			region?.putWeak();
			return imageFrame;
		}

		// or create it, if there is no such object
		final imageFrame = new FlxImageFrame(graphic);

		if (region != null) {
			if (region.width == 0) region.width = graphic.width - region.x;
			if (region.height == 0) region.height = graphic.height - region.y;
		} else
			region = FlxRect.weak(0, 0, graphic.width, graphic.height);

		imageFrame.addSpriteSheetFrame(region);
		return imageFrame;
	}

	/**
	 * Creates a `FlxImageFrame` object for specified region of the image.
	 *
	 * @param   source   Image graphic for `FlxImageFrame`.
	 * @param   region   Region of the image to create the `FlxImageFrame` for.
	 * @return  Newly created `FlxImageFrame` object for specified region of image.
	 */
	public static function fromRectangle(source:FlxGraphicAsset, ?region:FlxRect):FlxImageFrame {
		final graphic = FlxG.bitmap.add(source, false);
		return fromGraphic(graphic, region);
	}

	/**
	 * Gets source BitmapData, generates new BitmapData (if there is no such BitmapData in the cache already)
	 * and creates FlxImageFrame collection.
	 *
	 * @param   source   The source of graphic for frame collection.
	 * @param   border   Border to add around tiles (helps to avoid "tearing" problem).
	 * @param   region   Region of image to generate image frame from. Default value is `null`, which means that
	 *                   whole image will be used for it.
	 * @return  Newly created image frame collection.
	 */
	public static function fromBitmapAddSpacesAndBorders(source:FlxGraphicAsset, border:FlxPoint, ?region:FlxRect):FlxImageFrame {
		final graphic = FlxG.bitmap.add(source, false);
		if (graphic == null) return null;

		final key = FlxG.bitmap.getKeyWithSpacesAndBorders(graphic.key, null, null, border, region);
		var result = FlxG.bitmap.get(key);
		if (result == null) {
			final bitmap = FlxBitmapDataUtil.addSpacesAndBorders(graphic.bitmap, null, null, border, region);
			result = FlxG.bitmap.add(bitmap, false, key);
		}

		final imageFrame = FlxImageFrame.fromGraphic(graphic);
		return imageFrame.addBorder(border);
	}

	/**
	 * Gets `FlxFrame` object, generates new `BitmapData` with border pixels around
	 * (if there is no such BitmapData in the cache already) and creates image frame collection.
	 *
	 * @param   frame    Frame to generate tiles from.
	 * @param   border   Border to add around frame image (helps to avoid "tearing" problem).
	 * @return  Newly created image frame collection.
	 */
	public static function fromFrameAddSpacesAndBorders(frame:FlxFrame, border:FlxPoint):FlxImageFrame {
		final bitmap = frame.paint();
		return FlxImageFrame.fromBitmapAddSpacesAndBorders(bitmap, border);
	}

	/**
	 * Searches `FlxImageFrame` object for specified `FlxGraphic` object which have the same frame rectangle.
	 *
	 * @param    graphic     `FlxGraphic` object to search the `FlxImageFrame` for.
	 * @param    frameRect   `FlxImageFrame` object should have frame with
	 *                        the same position and dimensions as specified with this argument.
	 * @return   `FlxImageFrame` object which corresponds to specified rectangle.
	 *           Could be `null` if there is no such `FlxImageFrame`.
	 */
	public static function findFrame(graphic:FlxGraphic, frameRect:FlxRect, ?frameBorder:FlxPoint):FlxImageFrame {
		frameBorder ??= FlxPoint.weak();

		final imageFrames:Array<FlxImageFrame> = cast graphic.getFramesCollections(FlxFrameCollectionType.IMAGE);
		for (imageFrame in imageFrames)
			if (imageFrame.equals(frameRect, frameBorder) && imageFrame.frame.type != FlxFrameType.EMPTY)
				return imageFrame;

		frameBorder.putWeak();
		frameRect.putWeak();

		return null;
	}

	/**
	 * `FlxImageFrame` comparison method. For internal use.
	 */
	inline function equals(rect:FlxRect, border:FlxPoint):Bool {
		return rect.equals(frame.frame) && border.equals(this.border);
	}

	/**
	 * Searches `FlxImageFrame` object with the empty frame which have specified size.
	 *
	 * @param   graphic     `FlxGraphic` object to search `FlxImageFrame` for.
	 * @param   frameRect   The size of empty frame to search for.
	 * @return  `FlxImageFrame` with empty frame.
	 */
	public static function findEmptyFrame(graphic:FlxGraphic, frameRect:FlxRect):FlxImageFrame {
		final imageFrames:Array<FlxImageFrame> = cast graphic.getFramesCollections(FlxFrameCollectionType.IMAGE);

		for (imageFrame in imageFrames) {
			final frame = imageFrame.frame;
			if (frame.sourceSize.x == frameRect.width && frame.sourceSize.y == frameRect.height && frame.type == FlxFrameType.EMPTY)
				return imageFrame;
		}

		return null;
	}

	override public function addBorder(border:FlxPoint):FlxImageFrame {
		final resultBorder = FlxPoint.weak().add(this.border).add(border);

		var imageFrame = FlxImageFrame.findFrame(parent, frame.frame, resultBorder);
		if (imageFrame != null) return imageFrame;

		imageFrame = new FlxImageFrame(parent, resultBorder);
		imageFrame.pushFrame(frame.setBorderTo(border));
		return imageFrame;
	}

	private function get_frame():FlxFrame {
		return frames[0];
	}
}
