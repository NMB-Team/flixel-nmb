package flixel.tile;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxImageFrame;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.system.debug.FlxDebugDrawGraphic;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Graphics;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;

using flixel.util.FlxColorTransformUtil;

#if html5
/**
 * BitmapData loaded via @:bitmap is loaded asynchronously, this allows us to apply frame
 * padding to the bitmap once it's loaded rather
 */
private interface IEmbeddedBitmapData
{
	var onLoad:()->Void;
}

@:keep @:bitmap("assets/images/tile/autotiles.png")
private class RawGraphicAuto extends BitmapData {}
class GraphicAuto extends RawGraphicAuto implements IEmbeddedBitmapData
{
	static inline final WIDTH = 128;
	static inline final HEIGHT = 8;

	public var onLoad:()->Void;
	public function new ()
	{
		super(WIDTH, HEIGHT, true, 0xFFffffff, (_)-> if (onLoad != null) onLoad());
		// Set properties because `@:bitmap` constructors ignore width/height
		this.width = WIDTH;
		this.height = HEIGHT;
	}
}

@:keep @:bitmap("assets/images/tile/autotiles_alt.png")
private class RawGraphicAutoAlt extends BitmapData {}
class GraphicAutoAlt extends RawGraphicAutoAlt implements IEmbeddedBitmapData
{
	static inline final WIDTH = 128;
	static inline final HEIGHT = 8;

	public var onLoad:()->Void;
	public function new ()
	{
		super(WIDTH, HEIGHT, true, 0xFFffffff, (_)-> if (onLoad != null) onLoad());
		// Set properties because `@:bitmap` constructors ignore width/height
		this.width = WIDTH;
		this.height = HEIGHT;
	}
}

@:keep @:bitmap("assets/images/tile/autotiles_full.png")
private class RawGraphicAutoFull extends BitmapData {}
class GraphicAutoFull extends RawGraphicAutoFull implements IEmbeddedBitmapData
{
	static inline final WIDTH = 256;
	static inline final HEIGHT = 48;

	public var onLoad:()->Void;
	public function new ()
	{
		super(WIDTH, HEIGHT, true, 0xFFffffff, (_)-> if (onLoad != null) onLoad());
		// Set properties because `@:bitmap` constructors ignore width/height
		this.width = WIDTH;
		this.height = HEIGHT;
	}
}
#else
@:keep @:bitmap("assets/images/tile/autotiles.png")
class GraphicAuto extends BitmapData {}

@:keep @:bitmap("assets/images/tile/autotiles_alt.png")
class GraphicAutoAlt extends BitmapData {}

@:keep @:bitmap("assets/images/tile/autotiles_full.png")
class GraphicAutoFull extends BitmapData {}
#end

/**
 * This is a traditional tilemap display and collision class. It takes a string of comma-separated
 * numbers and then associates those values with tiles from the sheet you pass in. It also includes
 * some handy static parsers that can convert arrays or images into strings that can be loaded.
 */
class FlxTilemap extends FlxTypedTilemap<FlxTile>
{
	/**
	 * The default frame padding tilemaps will use when their own `framePadding` is not set
	 *
	 * @see FlxTypedTilemap.framePadding
	 * @since 5.0.0
	 */
	public static var defaultFramePadding(get, set):Int;

	static inline function get_defaultFramePadding()
	{
		return FlxTypedTilemap.defaultFramePadding;
	}

	static inline function set_defaultFramePadding(value:Int)
	{
		return FlxTypedTilemap.defaultFramePadding = value;
	}

	public function new ()
	{
		super();
	}

	override function createTile(index:Int, width, height):FlxTile
	{
		final visible = index >= _drawIndex;
		final allowCollisions = index >= _collideIndex ? this.allowCollisions : NONE;
		return new FlxTile(this, index, width, height, visible, allowCollisions);
	}
}

/**
 * This is a traditional tilemap display and collision class. It takes a string of comma-separated
 * numbers and then associates those values with tiles from the sheet you pass in. It also includes
 * some handy static parsers that can convert arrays or images into strings that can be loaded.
 */
class FlxTypedTilemap<Tile:FlxTile> extends FlxBaseTilemap<Tile>
{
	/**
	 * The default frame padding tilemaps will use when their own `framePadding` is not set
	 *
	 * @see FlxTypedTilemap.framePadding
	 * @since 5.0.0
	 */
	public static var defaultFramePadding = 2;

	/**
	 * Eliminates tearing on tilemaps by extruding each tile frame's edge out by the specified
	 * number of pixels. Ignored if <= 0. If `null`, `defaultFramePadding` is used
	 *
	 * Note: Changing this only affects future loadMap calls.
	 * @see FlxTypedTilemap.defaultFramePadding
	 * @since 5.4.0
	 */
	public var framePadding:Null<Int> = null;

	/**
	 * Changes the size of this tilemap. Default is (1, 1).
	 * Anything other than the default is very slow with blitting!
	 */
	public var scale(default, null):FlxPoint;

	/**
	 * Controls whether the object is smoothed when rotated, affects performance.
	 * @since 4.1.0
	 *
	 * @see FlxSprite.defaultAntialiasing
	 */
	public var antialiasing(default, set):Bool = FlxSprite.defaultAntialiasing;

	/**
	 * Use to offset the drawing position of the tilemap,
	 * just like FlxSprite.
	 */
	public var offset(default, null):FlxPoint = FlxPoint.get();

	/**
	 * Rendering variables.
	 */
	public var frames(default, set):FlxFramesCollection;

	public var graphic(default, set):FlxGraphic;

	/**
	 * Tints the whole sprite to a color (0xRRGGBB format) - similar to OpenGL vertex colors. You can use
	 * 0xAARRGGBB colors, but the alpha value will simply be ignored. To change the opacity use alpha.
	 */
	public var color(default, set):FlxColor = 0xffffff;

	/**
	 * Set alpha to a number between 0 and 1 to change the opacity of the sprite.
	 */
	public var alpha(default, set):Float = 1.0;

	public var colorTransform(default, null):ColorTransform = new ColorTransform();

	/**
	 * Blending modes, just like Photoshop or whatever, e.g. "multiply", "screen", etc.
	 */
	public var blend(default, set):BlendMode = null;

	/**
	 * The unscaled width of a single tile.
	 */
	public var tileWidth(default, null):Int = 0;

	/**
	 * The unscaled height of a single tile.
	 */
	public var tileHeight(default, null):Int = 0;

	/**
	 * The scaled width of a single tile.
	 */
	public var scaledTileWidth(default, null):Float = 0;

	/**
	 * The scaled height of a single tile.
	 */
	public var scaledTileHeight(default, null):Float = 0;

	/**
	 * The scaled width of the entire map.
	 */
	public var scaledWidth(get, never):Float;

	/**
	 * The scaled height of the entire map.
	 */
	public var scaledHeight(get, never):Float;

	/**
	 * GLSL shader for this tilemap. Only works with OpenFL Next or WebGL.
	 * Avoid changing it frequently as this is a costly operation.
	 * @since 4.1.0
	 */
	public var shader:FlxShader;

	/**
	 * Rendering helper, minimize new object instantiation on repetitive methods.
	 */
	var _flashPoint:Point = new Point();

	/**
	 * Rendering helper, minimize new object instantiation on repetitive methods.
	 */
	var _flashRect:Rectangle = new Rectangle();

	/**
	 * Internal list of buffers, one for each camera, used for drawing the tilemaps.
	 */
	var _buffers:Array<FlxTilemapBuffer> = [];

	#if FLX_DEBUG
	var _debugTileNotSolid:BitmapData;
	var _debugTilePartial:BitmapData;
	var _debugTileSolid:BitmapData;
	var _debugRect:Rectangle;
	#end

	/**
	 * Rendering helper, minimize new object instantiation on repetitive methods. Used only in tile rendering mode
	 */
	var _helperPoint:Point;

	/**
	 * Rendering helper, used for tile's frame transformations (only in tile rendering mode).
	 */
	var _matrix:FlxMatrix;

	/**
	 * Whether buffers need to be checked again next draw().
	 */
	var _checkBufferChanges:Bool = false;

	function new()
	{
		super();

		if (FlxG.render.tile)
		{
			_helperPoint = new Point();
			_matrix = new FlxMatrix();
		}

		scale = new FlxCallbackPoint(setScaleXCallback, setScaleYCallback, setScaleXYCallback);
		scale.set(1, 1);

		FlxG.signals.gameResized.add(onGameResized);
		FlxG.cameras.cameraAdded.add(onCameraChanged);
		FlxG.cameras.cameraRemoved.add(onCameraChanged);
		FlxG.cameras.cameraResized.add(onCameraChanged);

		#if FLX_DEBUG
		debugBoundingBoxColorSolid = FlxColor.GREEN;
		debugBoundingBoxColorPartial = FlxColor.PINK;
		debugBoundingBoxColorNotSolid = FlxColor.TRANSPARENT;

		if (FlxG.render.blit)
			FlxG.debugger.drawDebugChanged.add(onDrawDebugChanged);
		#end
	}

	/**
	 * Clean up memory.
	 */
	override function destroy():Void
	{
		_flashPoint = null;
		_flashRect = null;

		_tileObjects = FlxDestroyUtil.destroyArray(_tileObjects);
		_buffers = FlxDestroyUtil.destroyArray(_buffers);

		if (FlxG.render.blit)
		{
			#if FLX_DEBUG
			_debugRect = null;
			_debugTileNotSolid = FlxDestroyUtil.dispose(_debugTileNotSolid);
			_debugTilePartial = FlxDestroyUtil.dispose(_debugTilePartial);
			_debugTileSolid = FlxDestroyUtil.dispose(_debugTileSolid);
			#end
		}
		else
		{
			_helperPoint = null;
			_matrix = null;
		}

		frames = null;
		graphic = null;

		// need to destroy FlxCallbackPoints
		scale = FlxDestroyUtil.destroy(scale);
		offset = FlxDestroyUtil.put(offset);

		colorTransform = null;

		FlxG.signals.gameResized.remove(onGameResized);
		FlxG.cameras.cameraAdded.remove(onCameraChanged);
		FlxG.cameras.cameraRemoved.remove(onCameraChanged);
		FlxG.cameras.cameraResized.remove(onCameraChanged);

		#if FLX_DEBUG
		if (FlxG.render.blit)
			FlxG.debugger.drawDebugChanged.remove(onDrawDebugChanged);
		#end

		shader = null;

		super.destroy();
	}

	override function initTileObjects():Void
	{
		if (frames == null)
			return;

		_tileObjects = FlxDestroyUtil.destroyArray(_tileObjects);
		// Create some tile objects that we'll use for overlap checks (one for each tile)
		_tileObjects = [];

		var length:Int = frames.numFrames;
		length += _startingIndex;

		for (i in 0...length)
			_tileObjects[i] = createTile(i, tileWidth, tileHeight);

		// Create debug tiles for rendering bounding boxes on demand
		#if FLX_DEBUG
		updateDebugTileBoundingBoxSolid();
		updateDebugTileBoundingBoxNotSolid();
		updateDebugTileBoundingBoxPartial();
		#end
	}

	function createTile(index, width, height):Tile
	{
		throw "createTile not implemented";
	}

	function set_frames(value:FlxFramesCollection):FlxFramesCollection
	{
		frames = value;

		if (value != null)
		{
			tileWidth = Std.int(value.frames[0].sourceSize.x);
			tileHeight = Std.int(value.frames[0].sourceSize.y);
			_flashRect.setTo(0, 0, tileWidth, tileHeight);
			graphic = value.parent;
			postGraphicLoad();
		}

		return value;
	}

	function onGameResized(w:Int, h:Int):Void
	{
		_checkBufferChanges = true;
	}

	function onCameraChanged(cam:FlxCamera):Void
	{
		_checkBufferChanges = true;
	}

	override function loadMapHelper(tileGraphic, tileWidth = 0, tileHeight = 0, ?autoTile, startingIndex = 0, drawIndex = 1, collideIndex = 1)
	{
		// redraw buffers, fixes https://github.com/HaxeFlixel/flixel/issues/2882
		_checkBufferChanges = true;

		super.loadMapHelper(tileGraphic, tileWidth, tileHeight, autoTile, startingIndex, drawIndex, collideIndex);
	}

	override function cacheGraphics(tileWidth:Int, tileHeight:Int, tileGraphic:FlxTilemapGraphicAsset):Void
	{
		if ((tileGraphic is FlxFramesCollection))
		{
			frames = cast tileGraphic;
			return;
		}

		var graph:FlxGraphic = FlxG.bitmap.add(cast tileGraphic);
		if (graph == null)
			return;

		// Figure out the size of the tiles
		if (tileWidth <= 0)
			tileWidth = graph.height;

		if (tileHeight <= 0)
			tileHeight = tileWidth;

		this.tileWidth = tileWidth;
		this.tileHeight = tileHeight;

		final actualFramePadding = framePadding == null ? defaultFramePadding : framePadding;
		if (actualFramePadding > 0 && graph.isLoaded)
			frames = padTileFrames(tileWidth, tileHeight, graph, actualFramePadding);
		else
		{
			#if html5
			/* if Using tile graphics like GraphicAuto or others defined above, they will not
			 * load immediately. Track their loading and apply frame padding after.
			**/
			if (!graph.isLoaded && Std.isOfType(graph.bitmap, IEmbeddedBitmapData))
			{
				var futureBitmap:IEmbeddedBitmapData = cast graph.bitmap;
				futureBitmap.onLoad = function()
				{
					frames = padTileFrames(tileWidth, tileHeight, graph, actualFramePadding);
				}
			}
			else if (actualFramePadding > 0 && !graph.isLoaded)
			{
				FlxG.log.warn('Frame padding not applied to "${graph.key}" because it is loading asynchronously.'
					+ "Using `@:bitmap` assets on html5 is not recommended");
			}
			#end
			frames = FlxTileFrames.fromGraphic(graph, FlxPoint.get(tileWidth, tileHeight));
		}
	}

	function padTileFrames(tileWidth:Int, tileHeight:Int, graphic:FlxGraphic, padding:Int)
	{
		return FlxTileFrames.fromBitmapAddSpacesAndBorders(
			graphic,
			FlxPoint.get(tileWidth, tileHeight),
			null,
			FlxPoint.get(padding, padding)
		);
	}

	#if FLX_DEBUG
	function updateDebugTileBoundingBoxSolid():Void
	{
		_debugTileSolid = updateDebugTile(_debugTileSolid, debugBoundingBoxColorSolid);
	}

	function updateDebugTileBoundingBoxNotSolid():Void
	{
		_debugTileNotSolid = updateDebugTile(_debugTileNotSolid, debugBoundingBoxColorNotSolid);
	}

	function updateDebugTileBoundingBoxPartial():Void
	{
		_debugTilePartial = updateDebugTile(_debugTilePartial, debugBoundingBoxColorPartial);
	}

	function updateDebugTile(tileBitmap:BitmapData, color:FlxColor):BitmapData
	{
		if (FlxG.render.tile)
			return null;

		if (tileWidth <= 0 || tileHeight <= 0)
			return tileBitmap;

		if (tileBitmap != null && (tileBitmap.width != tileWidth || tileBitmap.height != tileHeight))
			tileBitmap = FlxDestroyUtil.dispose(tileBitmap);

		if (tileBitmap == null)
			tileBitmap = makeDebugTile(color);
		else
		{
			tileBitmap.fillRect(tileBitmap.rect, FlxColor.TRANSPARENT);
			drawDebugTile(tileBitmap, color);
		}

		setDirty();
		return tileBitmap;
	}
	#end

	override function computeDimensions():Void
	{
		scaledTileWidth = tileWidth * scale.x;
		scaledTileHeight = tileHeight * scale.y;

		width = scaledWidth;
		height = scaledHeight;
	}

	override function updateMap():Void
	{
		#if FLX_DEBUG
		if (FlxG.render.blit)
			_debugRect = new Rectangle(0, 0, tileWidth, tileHeight);
		#end

		var numTiles:Int = _tileObjects.length;
		for (i in 0...numTiles)
			updateTile(i);
	}

	#if FLX_DEBUG
	override function drawDebugOnCamera(camera:FlxCamera):Void
	{
		if (!FlxG.render.tile)
			return;

		var buffer:FlxTilemapBuffer = null;
		var l:Int = FlxG.cameras.list.length;

		for (i in 0...l)
		{
			if (FlxG.cameras.list[i] == camera)
			{
				buffer = _buffers[i];
				break;
			}
		}

		if (buffer == null)
			return;

		// Copied from getScreenPosition()
		_helperPoint.x = x - camera.scroll.x * scrollFactor.x;
		_helperPoint.y = y - camera.scroll.y * scrollFactor.y;

		final rect = FlxRect.get(0, 0, scaledTileWidth, scaledTileHeight);

		// Copy tile images into the tile buffer
		// Modified from getScreenPosition()
		_point.x = (camera.scroll.x * scrollFactor.x) - x;
		_point.y = (camera.scroll.y * scrollFactor.y) - y;
		var screenXInTiles:Int = Math.floor(_point.x / scaledTileWidth);
		var screenYInTiles:Int = Math.floor(_point.y / scaledTileHeight);
		var screenRows:Int = buffer.rows;
		var screenColumns:Int = buffer.columns;

		// Bound the upper left corner
		screenXInTiles = Std.int(FlxMath.bound(screenXInTiles, 0, widthInTiles - screenColumns));
		screenYInTiles = Std.int(FlxMath.bound(screenYInTiles, 0, heightInTiles - screenRows));

		var rowIndex:Int = screenYInTiles * widthInTiles + screenXInTiles;

		for (row in 0...screenRows)
		{
			var columnIndex = rowIndex;

			for (column in 0...screenColumns)
			{
				final tile = getTileData(columnIndex);

				if (tile != null && tile.visible && !tile.ignoreDrawDebug)
				{
					rect.x = _helperPoint.x + (columnIndex % widthInTiles) * rect.width;
					rect.y = _helperPoint.y + Math.floor(columnIndex / widthInTiles) * rect.height;

						final color = tile.debugBoundingBoxColor != null
							? tile.debugBoundingBoxColor
							: getDebugBoundingBoxColor(tile.allowCollisions);

						if (color != null)
						{
							final colStr = color.toHexString();
							drawDebugBoundingBoxColor(camera.debugLayer.graphics, rect, color);
						}
				}

				columnIndex++;
			}

			rowIndex += widthInTiles;
		}

		rect.put();
	}
	#end

	/**
	 * Check and see if this object is currently on screen. Differs from `FlxObject`'s implementation
	 * in that it takes the actual graphic into account, not just the hitbox or bounding box or whatever.
	 *
	 * @param   camera  Specify which game camera you want. If `null`, it will just grab the first global camera.
	 * @return  Whether the object is on screen or not.
	 */
	override function isOnScreen(?camera:FlxCamera):Bool
	{
		if (camera == null)
			camera = getDefaultCamera();

		var minX:Float = x - offset.x - camera.scroll.x * scrollFactor.x;
		var minY:Float = y - offset.y - camera.scroll.y * scrollFactor.y;

		_point.set(minX, minY);
		return camera.containsPoint(_point, scaledTileWidth * widthInTiles, scaledTileHeight * heightInTiles);
	}

	/**
	 * Draws the tilemap buffers to the cameras.
	 */
	override function draw():Void
	{
		// don't try to render a tilemap that isn't loaded yet
		if (graphic == null)
			return;

		if (_checkBufferChanges)
		{
			refreshBuffers();
			_checkBufferChanges = false;
		}

		final cameras = getCamerasLegacy();
		var buffer:FlxTilemapBuffer;
		var l:Int = cameras.length;

		for (i in 0...l)
		{
			final camera = cameras[i];

			if (!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;

			if (_buffers[i] == null)
				_buffers[i] = createBuffer(camera);

			buffer = _buffers[i];

			if (FlxG.render.blit)
			{
				if (buffer.isDirty(this, camera))
					drawTilemap(buffer, camera);

				getScreenPosition(_point, camera).subtract(offset).add(buffer.x, buffer.y).copyTo(_flashPoint);
				buffer.draw(camera, _flashPoint, scale.x, scale.y);
			}
			else
			{
				drawTilemap(buffer, camera);
			}

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}

	function refreshBuffers():Void
	{
		final cameras = getCamerasLegacy();
		for (i in 0...cameras.length)
		{
			var camera = cameras[i];
			var buffer = _buffers[i];

			// Create a new buffer if the number of columns and rows differs
			if (buffer == null)
				_buffers[i] = createBuffer(camera);
			else
				buffer.resize(tileWidth, tileHeight, widthInTiles, heightInTiles, camera, scale.x, scale.y);
		}
	}

	/**
	 * Set the dirty flag on all the tilemap buffers.
	 * Basically forces a reset of the drawn tilemaps, even if it wasn't necessary.
	 *
	 * @param   dirty  Whether to flag the tilemap buffers as dirty or not.
	 */
	override function setDirty(dirty:Bool = true):Void
	{
		if (FlxG.render.tile)
			return;

		for (buffer in _buffers)
			if (buffer != null)
				buffer.dirty = dirty;
	}

	override function isOverlappingTile(object:FlxObject, ?filter:(tile:Tile)->Bool, ?position:FlxPoint)
	{
		return forEachOverlappingTileHelper(object, filter, position, true);
	}

	override function forEachOverlappingTile(object:FlxObject, func:(tile:Tile)->Void, ?position:FlxPoint):Bool
	{
		function filter(tile)
		{
			// call func on every overlapping tile
			func(tile);

			// return true, since an overlapping tile was found
			return true;
		}

		return forEachOverlappingTileHelper(object, filter, position, false);
	}

	function forEachOverlappingTileHelper(object:FlxObject, ?filter:(tile:Tile)->Bool, ?position:FlxPoint, stopAtFirst:Bool):Bool
	{
		var xPos = x;
		var yPos = y;

		if (position != null)
		{
			xPos = position.x;
			yPos = position.y;
			position.putWeak();
		}

		inline function bindInt(value:Int, min:Int, max:Int)
		{
			return Std.int(FlxMath.bound(value, min, max));
		}

		// Figure out what tiles we need to check against, and bind them by the map edges
		final minTileX:Int = bindInt(Math.floor((object.x - xPos) / scaledTileWidth), 0, widthInTiles);
		final minTileY:Int = bindInt(Math.floor((object.y - yPos) / scaledTileHeight), 0, heightInTiles);
		final maxTileX:Int = bindInt(Math.ceil((object.x + object.width - xPos) / scaledTileWidth), 0, widthInTiles);
		final maxTileY:Int = bindInt(Math.ceil((object.y + object.height - yPos) / scaledTileHeight), 0, heightInTiles);

		var result = false;
		for (row in minTileY...maxTileY)
		{
			for (column in minTileX...maxTileX)
			{
				final tile = getTileData(column, row);
				if (tile == null)
					continue;
				tile.orientAt(xPos, yPos, column, row);
				if (tile.overlapsObject(object) && (filter == null || filter(tile)))
				{
					if (stopAtFirst)
						return true;

					result = true;
				}
			}
		}

		return result;
	}

	override function objectOverlapsTiles<TObj:FlxObject>(object:TObj, ?callback:(Tile, TObj)->Bool, ?position:FlxPoint, isCollision = true):Bool
	{
		var results = false;

		function each(tile:Tile)
		{
			var overlapFound = tile.solid || !isCollision;
			if (overlapFound && callback != null)
			{
				overlapFound = callback(tile, object);
			}

			if (overlapFound)
			{
				if (tile.callbackFunction != null)
				{
					tile.callbackFunction(tile, object);
				}

				// check again in case callback changed it (for backwards compatibility)
				if (tile.solid || !isCollision)
				{
					tile.onCollide.dispatch(tile, object);
					results = true;
				}
			}
		}

		forEachOverlappingTile(object, each, position);

		return results;
	}

	override function getColumnAt(worldX:Float, bind = false):Int
	{
		final result = Math.floor((worldX - x) / scaledTileWidth);

		if (bind)
			return result < 0 ? 0 : (result >= widthInTiles ? widthInTiles - 1 : result);

		return result;
	}

	override function getRowAt(worldY:Float, bind = false):Int
	{
		final result = Math.floor((worldY - y) / scaledTileHeight);

		if (bind)
			return result < 0 ? 0 : (result >= heightInTiles ? heightInTiles - 1 : result);

		return result;
	}

	override function getColumnPos(column:Float, midpoint = false):Float
	{
		return x + column * scaledTileWidth + (midpoint ? scaledTileWidth * 0.5 : 0);
	}

	override function getRowPos(row:Int, midpoint = false):Float
	{
		return y + row * scaledTileHeight + (midpoint ? scaledTileHeight * 0.5 : 0);
	}

	/**
	 * Call this function to lock the automatic camera to the map's edges.
	 *
	 * @param   camera       The desired camera.  If `null`, `getDefaultCamera()` is used.
	 * @param   border       Adjusts the camera follow boundary by whatever number of tiles you
	 *                       specify here. Handy for blocking off deadends that are offscreen, etc.
	 *                       Use a negative number to add padding instead of hiding the edges.
	 * @param   updateWorld  Whether to update the collision system's world size, default value is true.
	 */
	public function follow(?camera:FlxCamera, border = 0, updateWorld = true):Void
	{
		if (camera == null)
			camera = getDefaultCamera();

		camera.setScrollBoundsRect(
			x + border * scaledTileWidth,
			y + border * scaledTileHeight,
			scaledWidth - border * scaledTileWidth * 2,
			scaledHeight - border * scaledTileHeight * 2,
			updateWorld
		);
	}

	/**
	 * Shoots a ray from the start point to the end point.
	 * If/when it passes through a tile, it stores that point and returns false.
	 *
	 * @param   start   The world coordinates of the start of the ray.
	 * @param   end     The world coordinates of the end of the ray.
	 * @param   result  Optional result vector, to avoid creating a new instance to be returned.
	 *                  Only returned if the line enters the rect.
	 * @return  Returns true if the ray made it from Start to End without hitting anything.
	 *          Returns false and fills Result if a tile was hit.
	 */
	override function ray(start:FlxPoint, end:FlxPoint, ?result:FlxPoint):Bool
	{
		// trim the line to the parts inside the map
		final trimmedStart = calcRayEntry(start, end);
		final trimmedEnd = calcRayExit(start, end);

		start.putWeak();
		end.putWeak();

		if (trimmedStart == null || trimmedEnd == null)
		{
			FlxDestroyUtil.put(trimmedStart);
			FlxDestroyUtil.put(trimmedEnd);
			return true;
		}

		start = trimmedStart;
		end = trimmedEnd;

		inline function clearRefs()
		{
			trimmedStart.put();
			trimmedEnd.put();
		}

		final startIndex = getMapIndex(start);
		final endIndex = getMapIndex(end);

		// If the starting tile is solid, return the starting position
		final tile = getTileData(startIndex);
		if (tile != null && tile.solid)
		{
			if (result != null)
				result.copyFrom(start);

			clearRefs();
			return false;
		}

		final startTileX = getColumn(startIndex);
		final startTileY = getRow(startIndex);
		final endTileX = getColumn(endIndex);
		final endTileY = getRow(endIndex);
		var hitIndex = -1;

		if (start.x == end.x)
		{
			hitIndex = checkColumn(startTileX, startTileY, endTileY);
			if (hitIndex != -1 && result != null)
			{
				// check the bottom
				result.copyFrom(getTilePos(hitIndex));
				result.x = start.x;
				if (start.y > end.y)
					result.y += scaledTileHeight;
			}
		}
		else
		{
			// Use y = mx + b formula
			final m = (start.y - end.y) / (start.x - end.x);
			// y - mx = b
			final b = start.y - m * start.x;

			final movesRight = start.x < end.x;
			final inc = movesRight ? 1 : -1;
			final offset = movesRight ? 1 : 0;
			var tileX = startTileX;
			var lastTileY = startTileY;

			while (tileX != endTileX)
			{
				final xPos = getColumnPos(tileX + offset);
				final yPos = m * getColumnPos(tileX + offset) + b;
				final tileY = getRowAt(yPos);
				hitIndex = checkColumn(tileX, lastTileY, tileY);
				if (hitIndex != -1)
					break;
				lastTileY = tileY;
				tileX += inc;
			}

			if (hitIndex == -1)
				hitIndex = checkColumn(endTileX, lastTileY, endTileY);

			if (hitIndex != -1 && result != null)
			{
				result.copyFrom(getTilePos(hitIndex));
				if (Std.int(hitIndex / widthInTiles) == lastTileY)
				{
					if (start.x > end.x)
						result.x += scaledTileWidth;

					// set result to left side
					result.y = m * result.x + b; //mx + b
				}
				else
				{
					// if ascending
					if (start.y > end.y)
					{
						// change result to bottom
						result.y += scaledTileHeight;
					}
					// otherwise result is top

					// x = (y - b)/m
					result.x = (result.y - b) / m;
				}
			}
		}

		clearRefs();
		return hitIndex == -1;
	}

	function checkColumn(x:Int, startY:Int, endY:Int):Int
	{
		if (startY < 0)
			startY = 0;

		if (endY < 0)
			endY = 0;

		if (startY > heightInTiles - 1)
			startY = heightInTiles - 1;

		if (endY > heightInTiles - 1)
			endY = heightInTiles - 1;

		var y = startY;
		final step = startY <= endY ? 1 : -1;
		while (true)
		{
			final index = getMapIndex(x, y);
			final tile = getTileData(index);
			if (tile != null && tile.solid)
				return index;

			if (y == endY)
				break;

			y += step;
		}

		return -1;
	}

	/**
	 * Change a particular tile to FlxSprite. Or just copy the graphic if you dont want any changes to map data itself.
	 *
	 * @param   tileX          The X coordinate of the tile (in tiles, not pixels).
	 * @param   tileY          The Y coordinate of the tile (in tiles, not pixels).
	 * @param   newTile        New tile for the map data. Use -1 if you dont want any changes. Default = 0 (empty)
	 * @param   spriteFactory  Method for converting FlxTile to FlxSprite. If null then will be used defaultTileToSprite() method.
	 * @return FlxSprite.
	 */
	public function tileToSprite(tileX:Int, tileY:Int, newTile = 0, ?spriteFactory:FlxTileProperties->FlxSprite):FlxSprite
	{
		if (spriteFactory == null)
			spriteFactory = defaultTileToSprite;

		final tile:FlxTile = getTileData(tileX, tileY);
		var image:FlxImageFrame = null;

		if (tile != null && tile.visible)
			image = FlxImageFrame.fromFrame(tile.frame);
		else
			image = FlxImageFrame.fromEmptyFrame(graphic, FlxRect.get(0, 0, tileWidth, tileHeight));

		final worldX:Float = tileX * tileWidth * scale.x + x;
		final worldY:Float = tileY * tileHeight * scale.y + y;
		final tileSprite:FlxSprite = spriteFactory({
			graphic: image,
			x: worldX,
			y: worldY,
			scale: FlxPoint.get().copyFrom(scale),
			alpha: alpha,
			blend: blend
		});

		if (newTile >= 0)
			setTileIndex(tileX, tileY, newTile);

		return tileSprite;
	}

	/**
	 * Use this method so the tilemap buffers are updated, e.g. when resizing your game
	 */
	public function updateBuffers():Void
	{
		FlxDestroyUtil.destroyArray(_buffers);
		_buffers = [];
	}

	/**
	 * Internal function that actually renders the tilemap to the tilemap buffer. Called by draw().
	 *
	 * @param   buffer  The FlxTilemapBuffer you are rendering to.
	 * @param   camera  The related FlxCamera, mainly for scroll values.
	 */
	@:access(flixel.FlxCamera)
	function drawTilemap(buffer:FlxTilemapBuffer, camera:FlxCamera):Void
	{
		var isColored:Bool = (alpha != 1) || (color != 0xffffff);

		// only used for render.tile
		var drawX:Float = 0;
		var drawY:Float = 0;
		var scaledWidth:Float = 0;
		var scaledHeight:Float = 0;
		var drawItem = null;

		if (FlxG.render.blit)
		{
			buffer.fill();
		}
		else
		{
			getScreenPosition(_point, camera).subtractPoint(offset).copyTo(_helperPoint);

			_helperPoint.x = isPixelPerfectRender(camera) ? Math.floor(_helperPoint.x) : _helperPoint.x;
			_helperPoint.y = isPixelPerfectRender(camera) ? Math.floor(_helperPoint.y) : _helperPoint.y;

			scaledWidth = scaledTileWidth;
			scaledHeight = scaledTileHeight;

			var hasColorOffsets:Bool = (colorTransform != null && colorTransform.hasRGBAOffsets());
			drawItem = camera.startQuadBatch(graphic, isColored, hasColorOffsets, blend, antialiasing, shader);
		}

		// Copy tile images into the tile buffer
		_point.x = (camera.scroll.x * scrollFactor.x) - x - offset.x + camera.viewMarginX; // modified from getScreenPosition()
		_point.y = (camera.scroll.y * scrollFactor.y) - y - offset.y + camera.viewMarginY;

		var screenXInTiles:Int = Math.floor(_point.x / scaledTileWidth);
		var screenYInTiles:Int = Math.floor(_point.y / scaledTileHeight);
		var screenRows:Int = buffer.rows;
		var screenColumns:Int = buffer.columns;

		// Bound the upper left corner
		screenXInTiles = Std.int(FlxMath.bound(screenXInTiles, 0, widthInTiles - screenColumns));
		screenYInTiles = Std.int(FlxMath.bound(screenYInTiles, 0, heightInTiles - screenRows));

		var rowIndex:Int = screenYInTiles * widthInTiles + screenXInTiles;
		_flashPoint.y = 0;
		var columnIndex:Int;
		var tile:FlxTile;
		var frame:FlxFrame;

		#if FLX_DEBUG
		var debugTile:BitmapData;
		#end

		for (row in 0...screenRows)
		{
			columnIndex = rowIndex;
			_flashPoint.x = 0;

			for (column in 0...screenColumns)
			{
				tile = getTileData(columnIndex);

				if (tile != null && tile.visible && tile.frame.type != FlxFrameType.EMPTY)
				{
					frame = tile.frame;

					if (FlxG.render.blit)
					{
						frame.paint(buffer.pixels, _flashPoint, true);

						#if FLX_DEBUG
						if (FlxG.debugger.drawDebug && !ignoreDrawDebug)
						{
							if (tile.allowCollisions == NONE)
							{
								debugTile = _debugTileNotSolid;
							}
							else if (tile.allowCollisions != ANY)
							{
								debugTile = _debugTilePartial;
							}
							else
							{
								debugTile = _debugTileSolid;
							}

							offset.addToFlash(_flashPoint);
							buffer.pixels.copyPixels(debugTile, _debugRect, _flashPoint, null, null, true);
							offset.subtractFromFlash(_flashPoint);
						}
						#end
					}
					else
					{
						drawX = _helperPoint.x + (columnIndex % widthInTiles) * scaledWidth;
						drawY = _helperPoint.y + Math.floor(columnIndex / widthInTiles) * scaledHeight;

						_matrix.identity();

						if (frame.angle != FlxFrameAngle.ANGLE_0)
						{
							frame.prepareMatrix(_matrix);
						}

						var scaleX:Float = scale.x;
						var scaleY:Float = scale.y;

						_matrix.scale(scaleX, scaleY);
						_matrix.translate(drawX, drawY);

						drawItem.addQuad(frame, _matrix, colorTransform);
					}
				}

				if (FlxG.render.blit)
					_flashPoint.x += tileWidth;

				columnIndex++;
			}

			if (FlxG.render.blit)
				_flashPoint.y += tileHeight;
			rowIndex += widthInTiles;
		}

		buffer.x = screenXInTiles * scaledTileWidth;
		buffer.y = screenYInTiles * scaledTileHeight;

		if (FlxG.render.blit)
		{
			if (isColored)
				buffer.colorTransform(colorTransform);
			buffer.blend = blend;
		}

		buffer.dirty = false;
	}

	/**
	 * Internal function to clean up the map loading code.
	 * Just generates a wireframe box the size of a tile with the specified color.
	 */
	#if FLX_DEBUG
	function makeDebugTile(color:FlxColor):BitmapData
	{
		if (FlxG.render.tile)
			return null;

		var debugTile = new BitmapData(tileWidth, tileHeight, true, 0);
		drawDebugTile(debugTile, color);
		return debugTile;
	}

	function drawDebugTile(debugTile:BitmapData, color:FlxColor):Void
	{
		if (color != FlxColor.TRANSPARENT)
		{
			var gfx:Graphics = FlxSpriteUtil.flashGfx;
			gfx.clear();
			gfx.moveTo(0, 0);
			gfx.lineStyle(1, color, 0.5);
			gfx.lineTo(tileWidth - 1, 0);
			gfx.lineTo(tileWidth - 1, tileHeight - 1);
			gfx.lineTo(0, tileHeight - 1);
			gfx.lineTo(0, 0);

			debugTile.draw(FlxSpriteUtil.flashGfxSprite);
		}
	}

	function onDrawDebugChanged():Void
	{
		setDirty();
	}
	#end

	/**
	 * Internal function used in setTileIndex() and the constructor to update the map.
	 *
	 * @param   index  The index of the tile object in _tileObjects internal array you want to update.
	 */
	override function updateTile(index:Int):Void
	{
		var tile:FlxTile = _tileObjects[index];
		if (tile == null || !tile.visible)
			return;

		tile.frame = frames.frames[index - _startingIndex];
	}

	inline function createBuffer(camera:FlxCamera):FlxTilemapBuffer
	{
		var buffer = new FlxTilemapBuffer(tileWidth, tileHeight, widthInTiles, heightInTiles, camera, scale.x, scale.y);
		buffer.pixelPerfectRender = pixelPerfectRender;
		buffer.antialiasing = antialiasing;
		return buffer;
	}

	function set_antialiasing(value:Bool):Bool
	{
		for (buffer in _buffers)
			buffer.antialiasing = value;
		return antialiasing = value;
	}

	/**
	 * Internal function for setting graphic property for this object.
	 * Changes the graphic's `useCount` for better memory tracking.
	 */
	@:noCompletion
	function set_graphic(value:FlxGraphic):FlxGraphic
	{
		if (graphic != value)
		{
			// If new graphic is not null, increase its use count
			if (value != null)
				value.incrementUseCount();

			// If old graphic is not null, decrease its use count
			if (graphic != null)
				graphic.decrementUseCount();

			graphic = value;
		}

		return value;
	}

	override function set_pixelPerfectRender(value:Bool):Bool
	{
		if (_buffers != null)
			for (buffer in _buffers)
				buffer.pixelPerfectRender = value;

		return pixelPerfectRender = value;
	}

	function set_alpha(value:Float):Float
	{
		alpha = FlxMath.bound(value, 0, 1);
		updateColorTransform();
		return alpha;
	}

	function set_color(value:FlxColor):Int
	{
		if (color == value)
			return value;

		color = value;
		updateColorTransform();
		return color;
	}

	function updateColorTransform():Void
	{
		if (colorTransform == null)
			colorTransform = new ColorTransform();

		if (alpha != 1 || color != 0xffffff)
			colorTransform.setMultipliers(color.redFloat, color.greenFloat, color.blueFloat, alpha);
		else
			colorTransform.setMultipliers(1, 1, 1, 1);

		setDirty();
	}

	function set_blend(value:BlendMode):BlendMode
	{
		setDirty();
		return blend = value;
	}

	function setScaleXYCallback(scale:FlxPoint):Void
	{
		setScaleXCallback(scale);
		setScaleYCallback(scale);
	}

	function setScaleXCallback(scale:FlxPoint):Void
	{
		scaledTileWidth = tileWidth * scale.x;
		width = scaledWidth;

		final cameras = getCameras();
		if (cameras == null)
			return;

		for (i in 0...cameras.length)
			if (_buffers[i] != null)
				_buffers[i].updateColumns(tileWidth, widthInTiles, scale.x, cameras[i]);
	}

	function setScaleYCallback(scale:FlxPoint):Void
	{
		scaledTileHeight = tileHeight * scale.y;
		height = scaledHeight;

		final cameras = getCameras();
		if (cameras == null)
			return;

		for (i in 0...cameras.length)
			if (_buffers[i] != null)
				_buffers[i].updateRows(tileHeight, heightInTiles, scale.y, cameras[i]);
	}

	/**
	 * Default method for generating FlxSprite from FlxTile
	 *
	 * @param   tileProperties  properties for new sprite
	 * @return  New FlxSprite with specified graphic
	 */
	function defaultTileToSprite(tileProperties:FlxTileProperties):FlxSprite
	{
		var tileSprite = new FlxSprite(tileProperties.x, tileProperties.y);
		tileSprite.frames = tileProperties.graphic;
		tileSprite.scale.copyFrom(tileProperties.scale);
		tileProperties.scale = FlxDestroyUtil.put(tileProperties.scale);
		tileSprite.alpha = tileProperties.alpha;
		tileSprite.blend = tileProperties.blend;
		return tileSprite;
	}

	override function set_allowCollisions(value:FlxDirectionFlags):FlxDirectionFlags
	{
		for (tile in _tileObjects)
			if (tile.index >= _collideIndex)
				tile.allowCollisions = value;

		return super.set_allowCollisions(value);
	}

	inline function get_scaledWidth():Float
	{
		return widthInTiles * scaledTileWidth;
	}

	inline function get_scaledHeight():Float
	{
		return heightInTiles * scaledTileHeight;
	}

	/**
	 * Get the world coordinates and size of the entire tilemap as a FlxRect.
	 *
	 * @param   bounds  Optional, pass in a pre-existing FlxRect to prevent instantiation of a new object.
	 * @return  A FlxRect containing the world coordinates and size of the entire tilemap.
	 */
	override function getBounds(?bounds:FlxRect):FlxRect
	{
		if (bounds == null)
			bounds = FlxRect.get();

		return bounds.set(x, y, scaledWidth, scaledHeight);
	}

	#if FLX_DEBUG
	override function set_debugBoundingBoxColorSolid(color:FlxColor)
	{
		super.set_debugBoundingBoxColorSolid(color);
		updateDebugTileBoundingBoxSolid();
		return color;
	}

	override function set_debugBoundingBoxColorNotSolid(color:FlxColor)
	{
		super.set_debugBoundingBoxColorNotSolid(color);
		updateDebugTileBoundingBoxNotSolid();
		return color;
	}

	override function set_debugBoundingBoxColorPartial(color:FlxColor)
	{
		super.set_debugBoundingBoxColorPartial(color);
		updateDebugTileBoundingBoxPartial();
		return color;
	}
	#end
}

typedef FlxTileProperties =
{
	graphic:FlxImageFrame,
	x:Float,
	y:Float,
	scale:FlxPoint,
	alpha:Float,
	blend:BlendMode
}
