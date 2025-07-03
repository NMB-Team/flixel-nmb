package flixel.graphics.frames;

import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection.FlxFrameCollectionType;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import openfl.filters.BitmapFilter;

/**
 * Frames collection which you can apply bitmap filters to.
 * WARNING: this frame collection doesn't use caching, so be careful or you will "leak" out memory very fast.
 * You should destroy frames collections of this type manually.
 */
class FlxFilterFrames extends FlxFramesCollection {
	static var point = new Point();
	static var rect = new Rectangle();

	/**
	 * Generates new frames collection from specified frames.
	 *
	 * @param   frames      Frames collection to generate filters for.
	 * @param   widthInc    How much frames should expand horizontally.
	 * @param   heightInc   How much frames should expend vertically.
	 * @param   filters     Optional filters array to apply.
	 * @return  New frames collection which you can apply filters to.
	 */
	public static inline function fromFrames(frames:FlxFramesCollection, widthInc = 0, heightInc = 0, ?filters:Array<BitmapFilter>):FlxFilterFrames {
		return new FlxFilterFrames(frames, widthInc, heightInc, filters);
	}

	/**
	 * Original frames collection
	 */
	public var sourceFrames(default, null):FlxFramesCollection;

	/**
	 * How much frames should expand horizontally
	 */
	public var widthInc(default, null) = 0;

	/**
	 * How much frames should expand vertically
	 */
	public var heightInc(default, null) = 0;

	/**
	 * Filters applied to these frames
	 */
	public var filters(default, set):Array<BitmapFilter>;

	private function new(sourceFrames:FlxFramesCollection, widthInc = 0, heightInc = 0, ?filters:Array<BitmapFilter>) {
		super(null, FlxFrameCollectionType.FILTER);

		this.sourceFrames = sourceFrames;

		widthInc = (widthInc >= 0) ? widthInc : 0;
		heightInc = (heightInc >= 0) ? heightInc : 0;

		widthInc = 2 * Math.ceil(.5 * widthInc);
		heightInc = 2 * Math.ceil(.5 * heightInc);

		this.widthInc = widthInc;
		this.heightInc = heightInc;

		this.filters = (filters == null) ? [] : filters;

		genFrames();
		applyFilters();
	}

	/**
	 * Just helper method which "centers" sprite offsets
	 *
	 * @param   spr              Sprite to apply this frame collection.
	 * @param   saveAnimations   Whether to save sprite's animations or not.
	 * @param   updateFrames     Whether to regenerate frame `BitmapData`s or not.
	 */
	public function applyToSprite(spr:FlxSprite, saveAnimations = false, updateFrames = false):Void {
		if (updateFrames) set_filters(filters);

		final w = spr.width;
		final h = spr.height;
		spr.setFrames(this, saveAnimations);
		spr.offset.add(.5 * widthInc, .5 * heightInc);
		spr.setSize(w, h);
	}

	private function genFrames():Void {
		var canvas:BitmapData;
		var graph:FlxGraphic;
		var filterFrame:FlxFrame;

		for (frame in sourceFrames.frames) {
			canvas = new BitmapData(Std.int(frame.sourceSize.x + widthInc), Std.int(frame.sourceSize.y + heightInc), true, FlxColor.TRANSPARENT);
			graph = FlxGraphic.fromBitmapData(canvas, false, null, false);

			filterFrame = graph.imageFrame.frame;

			frames.push(filterFrame);
			if (frame.name != null) {
				filterFrame.name = frame.name;
				framesByName.set(frame.name, filterFrame);
			}
		}

		regenBitmaps(false);
	}

	/**
	 * Adds a filter to this frames collection.
	 *
	 * @param   filter   The filter to be added.
	 */
	public inline function addFilter(filter:BitmapFilter):Void {
		if (filter != null) {
			filters.push(filter);
			applyFilter(filter);
		}
	}

	/**
	 * Removes a filter from this frames collection.
	 *
	 * @param   filter   The filter to be removed.
	 */
	public function removeFilter(filter:BitmapFilter):Void {
		if (FlxStringUtil.isNullOrEmpty(filters)) return;
		if (filters.remove(filter)) regenAndApplyFilters();
	}

	/**
	 * Removes all filters from the frames.
	 */
	public function clearFilters():Void {
		if (filters.length == 0) return;

		filters.resize(0);
		regenBitmaps();
	}

	private function regenAndApplyFilters():Void {
		regenBitmaps();
		applyFilters();
	}

	private function regenBitmaps(fill = true):Void {
		final numFrames = frames.length;
		var frame:FlxFrame;
		var sourceFrame:FlxFrame;
		final frameOffset = point;

		for (i in 0...numFrames) {
			sourceFrame = sourceFrames.frames[i];
			frame = frames[i];

			if (fill) frame.parent.bitmap.fillRect(frame.parent.bitmap.rect, FlxColor.TRANSPARENT);

			frameOffset.setTo(widthInc * .5, heightInc * .5);
			sourceFrame.paint(frame.parent.bitmap, frameOffset, true);
		}
	}

	private function applyFilter(filter:BitmapFilter) {
		var bitmap:BitmapData;

		for (frame in frames) {
			point.setTo(0, 0);
			rect.setTo(0, 0, frame.sourceSize.x, frame.sourceSize.y);
			bitmap = frame.parent.bitmap;
			bitmap.applyFilter(bitmap, rect, point, filter);
		}
	}

	private function applyFilters():Void {
		for (filter in filters) applyFilter(filter);
	}

	override public function destroy():Void {
		sourceFrames = null;
		filters = null;

		for (frame in frames) frame.parent.destroy();

		super.destroy();
	}

	private function set_filters(value:Array<BitmapFilter>):Array<BitmapFilter> {
		filters = value;
		if (value != null) regenAndApplyFilters();
		return filters;
	}
}
