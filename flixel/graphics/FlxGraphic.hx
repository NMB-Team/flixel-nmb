package flixel.graphics;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxImageFrame;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;

/**
 * `BitmapData` wrapper which is used for rendering.
 * It stores info about all frames, generated for specific `BitmapData` object.
 */
class FlxGraphic implements IFlxDestroyable {
	@:allow(flixel.system.frontEnds.BitmapFrontEnd)
	private var mustDestroy = false;

	/**
	 * The default value for the `persist` variable at creation if none is specified in the constructor.
	 * @see [FlxGraphic.persist](https://api.haxeflixel.com/flixel/graphics/FlxGraphic.html#persist)
	 */
	public static var defaultPersist = false;

	/**
	 * Creates and caches FlxGraphic object from openfl.Assets key string.
	 *
	 * @param   source   `openfl.Assets` key string. For example: `"assets/image.png"`.
	 * @param   unique   Ensures that the `BitmapData` uses a new slot in the cache.
	 *                   If `true`, then `BitmapData` for this `FlxGraphic` will be cloned, which means extra memory.
	 * @param   key      Force the cache to use a specific key to index the bitmap.
	 * @param   cache    Whether to use graphic caching or not. Default value is `true`, which means automatic caching.
	 * @return  Cached `FlxGraphic` object we just created.
	 */
	public static function fromAssetKey(source:String, unique = false, ?key:String, cache = true):FlxGraphic {
		var bitmap:BitmapData = null;

		if (!cache) {
			bitmap = FlxG.assets.getBitmapData(source);
			if (bitmap == null) return null;

			return createGraphic(bitmap, key, unique, cache);
		}

		final keyTemp = FlxG.bitmap.generateKey(source, key, unique);
		var graphic = FlxG.bitmap.get(keyTemp);
		if (graphic != null) return graphic;

		bitmap = FlxG.assets.getBitmapData(source);
		if (bitmap == null)	return null;

		graphic = createGraphic(bitmap, keyTemp, unique);
		graphic.assetsKey = source;
		return graphic;
	}

	/**
	 * Creates and caches `FlxGraphic` object from a specified `Class<BitmapData>`.
	 *
	 * @param   source   `Class<BitmapData>` to create `BitmapData` for `FlxGraphic` from.
	 * @param   unique   Ensures that the `BitmapData` uses a new slot in the cache.
	 *                   If `true`, then `BitmapData` for this `FlxGraphic` will be cloned, which means extra memory.
	 * @param   key      Force the cache to use a specific key to index the bitmap.
	 * @param   cache    Whether to use graphic caching or not. Default value is `true`, which means automatic caching.
	 * @return  `FlxGraphic` object we just created.
	 */
	public static function fromClass(source:Class<BitmapData>, unique = false, ?key:String, cache = true):FlxGraphic {
		var bitmap:BitmapData = null;
		if (!cache) {
			bitmap = FlxAssets.getBitmapFromClass(source);
			return createGraphic(bitmap, key, unique, cache);
		}

		var keyTemp = FlxG.bitmap.getKeyForClass(source);
		keyTemp = FlxG.bitmap.generateKey(keyTemp, key, unique);

		var graphic = FlxG.bitmap.get(keyTemp);
		if (graphic != null) return graphic;

		bitmap = FlxAssets.getBitmapFromClass(source);
		graphic = createGraphic(bitmap, keyTemp, unique);
		graphic.assetsClass = source;

		return graphic;
	}

	/**
	 * Creates and caches `FlxGraphic` object from specified `BitmapData` object.
	 *
	 * @param   source   `BitmapData` for `FlxGraphic` to use.
	 * @param   unique   Ensures that the `BitmapData` uses a new slot in the cache.
	 *                   If `true`, then `BitmapData` for this `FlxGraphic` will be cloned, which means extra memory.
	 * @param   key      Force the cache to use a specific key to index the bitmap.
	 * @param   cache    Whether to use graphic caching or not. Default value is `true`, which means automatic caching.
	 * @return  `FlxGraphic` object we just created.
	 */
	public static function fromBitmapData(source:BitmapData, unique = false, ?key:String, cache = true):FlxGraphic {
		if (!cache) return createGraphic(source, key, unique, cache);

		var keyTemp = FlxG.bitmap.findKeyForBitmap(source);

		var assetKey:String = null;
		var assetClass:Class<BitmapData> = null;
		var graphic:FlxGraphic = null;
		if (keyTemp != null) {
			graphic = FlxG.bitmap.get(keyTemp);
			assetKey = graphic.assetsKey;
			assetClass = graphic.assetsClass;
		}

		keyTemp = FlxG.bitmap.generateKey(keyTemp, key, unique);
		graphic = FlxG.bitmap.get(keyTemp);
		if (graphic != null) return graphic;

		graphic = createGraphic(source, keyTemp, unique);
		graphic.assetsKey = assetKey;
		graphic.assetsClass = assetClass;

		return graphic;
	}

	/**
	 * Creates and (optionally) caches a `FlxGraphic` object from the specified `FlxFrame`.
	 * It uses frame's `BitmapData`, not the `frame.parent.bitmap`.
	 *
	 * @param   source   `FlxFrame` to get the `BitmapData` from.
	 * @param   unique   Ensures that the bitmap data uses a new slot in the cache.
	 *                   If `true`, then `BitmapData` for this `FlxGraphic` will be cloned, which means extra memory.
	 * @param   key      Force the cache to use a specific key to index the bitmap.
	 * @param   cache    Whether to use graphic caching or not. Default value is `true`, which means automatic caching.
	 * @return  `FlxGraphic` object we just created.
	 */
	public static function fromFrame(source:FlxFrame, unique:Bool = false, ?key:String, cache:Bool = true):FlxGraphic {
		var keyTemp = source.name;
		keyTemp ??= source.frame.toString();

		keyTemp = source.parent.key + ":" + keyTemp;
		keyTemp = FlxG.bitmap.generateKey(keyTemp, key, unique);

		var graphic = FlxG.bitmap.get(keyTemp);
		if (graphic != null) return graphic;

		final bitmap = source.paint();
		graphic = createGraphic(bitmap, keyTemp, unique, cache);

		final image = FlxImageFrame.fromGraphic(graphic);
		image.getByIndex(0).name = source.name;

		return graphic;
	}

	/**
	 * Creates and caches a FlxGraphic object from the specified `FlxFramesCollection`.
	 * It uses `frames.parent.bitmap` as a source for the `FlxGraphic`'s `BitmapData`.
	 * It also copies all the frames collections onto the newly created `FlxGraphic`.
	 *
	 * @param   source   `FlxFramesCollection` to get the `BitmapData` from.
	 * @param   unique   Ensures that the `BitmapData` uses a new slot in the cache.
	 *                   If `true`, then `BitmapData` for this `FlxGraphic` will be cloned, which means extra memory.
	 * @param   key      Force the cache to use a specific key to index the bitmap.
	 * @return  Cached `FlxGraphic` object we just created.
	 */
	public static inline function fromFrames(source:FlxFramesCollection, unique = false, ?key:String):FlxGraphic {
		return fromGraphic(source.parent, unique, key);
	}

	/**
	 * Creates and caches a `FlxGraphic` object from the specified `FlxGraphic` object.
	 * It copies all the frame collections onto the newly created `FlxGraphic`.
	 *
	 * @param   source   `FlxGraphic` to get the `BitmapData` from.
	 * @param   unique   Ensures that the `BitmapData` uses a new slot in the cache.
	 *                   If `true`, then `BitmapData` for this `FlxGraphic` will be cloned, which means extra memory.
	 * @param   key      Force the cache to use a specific key to index the bitmap.
	 * @return  Cached `FlxGraphic` object we just created.
	 */
	public static function fromGraphic(source:FlxGraphic, unique = false, ?key:String):FlxGraphic {
		if (!unique) return source;

		final keyTemp = FlxG.bitmap.generateKey(source.key, key, unique);
		final graphic = createGraphic(source.bitmap, keyTemp, unique);
		graphic.unique = unique;
		graphic.assetsClass = source.assetsClass;
		graphic.assetsKey = source.assetsKey;

		return FlxG.bitmap.addGraphic(graphic);
	}

	/**
	 * Generates and caches new `FlxGraphic` object with a colored rectangle.
	 *
	 * @param   width    How wide the rectangle should be.
	 * @param   height   How high the rectangle should be.
	 * @param   color    What color the rectangle should have (`0xAARRGGBB`).
	 * @param   unique   Ensures that the `BitmapData` uses a new slot in the cache.
	 * @param   key      Force the cache to use a specific key to index the bitmap.
	 * @return  The `FlxGraphic` object we just created.
	 */
	public static function fromRectangle(width:Int, height:Int, color:FlxColor, unique = false, ?key:String):FlxGraphic {
		final systemKey = width + "x" + height + ":" + color;
		final keyTemp = FlxG.bitmap.generateKey(systemKey, key, unique);

		final graphic = FlxG.bitmap.get(keyTemp);
		if (graphic != null) return graphic;

		final bitmap = new BitmapData(width, height, true, color);
		return createGraphic(bitmap, keyTemp);
	}

	/**
	 * Helper method for cloning specified `BitmapData` if necessary.
	 *
	 * @param   bitmap   `BitmapData` to process
	 * @param   unique   Whether we need to clone specified `BitmapData` object or not
	 * @return  Processed `BitmapData`
	 */
	static inline function getBitmap(bitmap:BitmapData, unique = false):BitmapData {
		return unique ? bitmap.clone() : bitmap;
	}

	/**
	 * Creates and caches the specified `BitmapData` object.
	 *
	 * @param   bitmap   `BitmapData` to use as a graphic source for the new `FlxGraphic`.
	 * @param   key      Key to use as a cache key for the created `FlxGraphic`.
	 * @param   unique   Whether the new `FlxGraphic` object uses a unique `BitmapData` or not.
	 *                   If `true`, the specified `BitmapData` will be cloned.
	 * @param   cache    Whether to use graphic caching or not. Default value is `true`, which means automatic caching.
	 * @return  Created `FlxGraphic` object.
	 */
	static function createGraphic(bitmap:BitmapData, key:String, unique = false, cache = true):FlxGraphic {
		bitmap = FlxGraphic.getBitmap(bitmap, unique);
		var graphic:FlxGraphic = null;

		if (cache) {
			graphic = new FlxGraphic(key, bitmap);
			graphic.unique = unique;
			FlxG.bitmap.addGraphic(graphic);
		} else
			graphic = new FlxGraphic(null, bitmap);

		return graphic;
	}

	/**
	 * Key used in the `BitmapFrontEnd` cache.
	 */
	public var key(default, null):String;

	/**
	 * The cached `BitmapData` object.
	 */
	public var bitmap(default, set):BitmapData;

	/**
	 * Width of the cached `BitmapData`.
	 */
	public var width(default, null) = 0;

	/**
	 * Height of the cached `BitmapData`.
	 */
	public var height(default, null) = 0;

	/**
	 * Asset name from `openfl.Assets`.
	 */
	public var assetsKey(default, null):String;

	/**
	 * Class name for the `BitmapData`.
	 */
	public var assetsClass(default, null):Class<BitmapData>;

	/**
	 * Whether this graphic object should stay in the cache after state changes or not.
	 * `destroyOnNoUse` has no effect when this is set to `true`.
	 */
	public var persist = false;

	/**
	 * Whether this `FlxGraphic` should be destroyed when `useCount` becomes zero (defaults to `true`).
	 * Has no effect when `persist` is `true`.
	 */
	public var destroyOnNoUse(default, set) = true;

	/**
	 * Whether the `BitmapData` of this graphic object has been loaded or not.
	 */
	public var isLoaded(get, never):Bool;

	/**
	 * Whether `destroy` was called on this graphic
	 * @since 5.6.0
	 */
	public var isDestroyed(get, never):Bool;

	/**
	 * Whether the `BitmapData` of this graphic object can be refreshed.
 	 * This is only the case for graphics with an `assetsKey` or `assetsClass`.
 	 */
	public var canBeRefreshed(get, never):Bool;

	/**
	 * GLSL shader for this graphic. Only used if utilizing sprites do not define a shader
	 * Avoid changing it frequently as this is a costly operation.
	 */
	public var shader(default, null):FlxShader;

	/**
	 * Usage counter for this `FlxGraphic` object.
	 */
	public var useCount(default, null) = 0;

	/**
	 * `FlxImageFrame` object for the whole bitmap.
	 */
	public var imageFrame(get, null):FlxImageFrame;

	/**
	 * Atlas frames for this graphic.
	 * You should fill it yourself with one of `FlxAtlasFrames`'s static methods
	 * (like `fromTexturePackerJson()`, `fromTexturePackerXml()`, etc).
	 */
	public var atlasFrames(get, never):FlxAtlasFrames;

	/**
	 * Storage for all available frame collection of all types for this graphic object.
	 */
	var frameCollections:Map<FlxFrameCollectionType, Array<Dynamic>>;

	/**
	 * All types of frames collection which had been added to this graphic object.
	 * It helps to avoid map iteration, which produces a lot of garbage.
	 */
	var frameCollectionTypes:Array<FlxFrameCollectionType>;

	/**
	 * Shows whether this object unique in cache or not.
	 *
	 * Whether undumped `BitmapData` should be cloned or not.
	 * It is `false` by default, since it significantly increases memory consumption.
	 */
	public var unique = false;

	#if FLX_TRACK_GRAPHICS
	/**
	 * **Debug only**
	 * Any info about the creation or intended usage of this graphic, for debugging purposes
	 * @since 5.9.0
	 */
	public var trackingInfo = "";
	#end

	/**
	 * `FlxGraphic` constructor
	 *
	 * @param   Key       Key string for this graphic object, with which you can get it from bitmap cache.
	 * @param   Bitmap    `BitmapData` for this graphic object.
	 * @param   Persist   Whether or not this graphic stay in the cache after resetting it.
	 *                    Default value is `false`, which means that this graphic will be destroyed at the cache reset.
	 */
	private function new(key:String, bitmap:BitmapData, ?persist:Bool) {
		this.key = key;
		this.persist = (persist != null) ? persist : defaultPersist;

		frameCollections = new Map<FlxFrameCollectionType, Array<Dynamic>>();
		frameCollectionTypes = new Array<FlxFrameCollectionType>();
		this.bitmap = bitmap;

		shader = new FlxShader();
	}

	/**
	 * Refreshes the `BitmapData` of this graphic.
	 */
	public function refresh():Void {
		final newBitmap = getBitmapFromSystem();
		if (newBitmap != null) bitmap = newBitmap;
	}

	/**
	 * If possible, frees the software image buffer for this graphic's `BitmapData`.
	 * This can significantly reduce RAM usage at the cost of not being able to draw on the graphic.
	 * Call `FlxGraphic.refresh()` to refresh this graphic's `BitmapData` and restore drawing functionality.
	 *
	 * Note that the buffer may not be cleaned up immediately.
	 *
	 * @see `openfl.display.BitmapData.disposeImage()`
	 */
	public function freeImageBuffer():Void {
		bitmap?.disposeImage();
	}

	/**
	 * Asset reload callback for this graphic object.
	 * It regenerates its bitmap data.
	 */
	public function onAssetsReload():Void {
		if (!canBeRefreshed) return;

		refresh();
	}

	/**
	 * Trying to free the memory as much as possible
	 */
	public function destroy():Void {
		@:privateAccess
		if (bitmap != null) {
			bitmap.__texture?.dispose();
			bitmap.disposeImage();
		}
		bitmap = FlxDestroyUtil.dispose(bitmap);

		shader = null;

		assetsClass = null;
		imageFrame = FlxDestroyUtil.destroy(imageFrame); // no need to dispose _imageFrame since it exists in imageFrames

		if (frameCollections == null) return; // no need to destroy frame collections if it's already null

		var collections:Array<FlxFramesCollection>;
		for (collectionType in frameCollectionTypes) {
			collections = cast frameCollections.get(collectionType);
			FlxDestroyUtil.destroyArray(collections);
		}

		frameCollections = null;
		frameCollectionTypes = null;
	}

	/**
	 * Stores specified `FlxFrame` collection in internal map (this helps reduce object creation).
	 *
	 * @param   collection   frame collection to store.
	 */
	public function addFrameCollection(collection:FlxFramesCollection):Void {
		if (collection.type != null) {
			final collections = getFramesCollections(collection.type);
			if (collections.contains(collection))
				FlxG.log.warn('Attempting to add already added collection');
			else
				collections.push(collection);

			if (!frameCollectionTypes.contains(collection.type))
				frameCollectionTypes.push(collection.type);
		}
	}

	/**
	 * Searches frame collections of specified type for this `FlxGraphic` object.
	 *
	 * @param   type   The type of frames collections to search for.
	 * @return  Array of available frames collections of specified type for this object.
	 */
	public inline function getFramesCollections(type:FlxFrameCollectionType):Array<Dynamic> {
		if (this.isDestroyed) {
			FlxG.log.warn('Invalid call to getFramesCollections on a destroyed graphic');
			return [];
		}

		var collections:Array<Dynamic> = frameCollections.get(type);
		if (collections == null) {
			collections = new Array<FlxFramesCollection>();
			frameCollections.set(type, collections);

			#if EXPERIMENTAL_FLXGRAPHIC_DESTROY_FIX
			if (!frameCollectionTypes.contains(type))
				frameCollectionTypes.push(type);
			#end
		}
		return collections;
	}

	/**
	 * Creates empty frame for this graphic with specified size.
	 * This method could be useful for tile frames, in case when you'll need empty tile.
	 *
	 * @param   size   dimensions of the frame to add.
	 * @return  Empty frame with specified size which belongs to this `FlxGraphic` object.
	 */
	public inline function getEmptyFrame(size:FlxPoint):FlxFrame {
		final frame = new FlxFrame(this);
		frame.type = FlxFrameType.EMPTY;
		frame.frame = FlxRect.get();
		frame.sourceSize.copyFrom(size);
		return frame;
	}

	/**
	 * Gets the `BitmapData` for this graphic object from OpenFL.
	 * This method is used for refreshing bitmaps.
	 */
	private function getBitmapFromSystem():BitmapData {
		var newBitmap:BitmapData = null;
		if (assetsClass != null) newBitmap = FlxAssets.getBitmapFromClass(assetsClass);
		else if (assetsKey != null) newBitmap = FlxG.assets.getBitmapData(assetsKey);

		if (newBitmap != null) return FlxGraphic.getBitmap(newBitmap, unique);

		return null;
	}

	inline function get_isLoaded() {
		return bitmap != null && !bitmap.rect.isEmpty();
	}

	inline function get_isDestroyed() {
		return shader == null;
	}

	inline function get_canBeRefreshed():Bool {
		return assetsClass != null || assetsKey != null;
	}

	public function incrementUseCount() {
		useCount++;
	}

	public function addToUseCount(count:Int) {
		useCount += count;
	}

	public function decreasseToUseCount(count:Int) {
		useCount -= count;
		checkUseCount();
	}

	public function decrementUseCount() {
		useCount--;

		checkUseCount();
	}

	private function checkUseCount() {
		if (FlxG.bitmap.autoClearCache && !FlxG.bitmap.doNotDelete && useCount <= 0 && destroyOnNoUse && !persist)
			FlxG.bitmap.remove(this);
	}

	private function set_destroyOnNoUse(value:Bool):Bool {
		this.destroyOnNoUse = value;

		checkUseCount();

		return value;
	}

	private function get_imageFrame():FlxImageFrame {
		imageFrame ??= FlxImageFrame.fromRectangle(this);

		return imageFrame;
	}

	private function get_atlasFrames():FlxAtlasFrames {
		return FlxAtlasFrames.findFrame(this, null);
	}

	private function set_bitmap(value:BitmapData):BitmapData {
		if (value != null) {
			bitmap = value;
			width = bitmap.width;
			height = bitmap.height;
		}

		#if FLX_OPENGL_AVAILABLE
		final max = FlxG.bitmap.maxTextureSize;
		if (max > 0 && (width > max || height > max))
			FlxG.log.warn('Graphic dimensions (${width}x${height}) exceed the maximum allowed size (${max}x${max}), which may cause rendering issues.');
		#end

		return value;
	}
}
