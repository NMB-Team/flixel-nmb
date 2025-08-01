package flixel.tile;

import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.path.FlxPathfinder;
import flixel.system.FlxAssets;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxStringUtil;
import openfl.display.BitmapData;

using StringTools;

class FlxBaseTilemap<Tile:FlxObject> extends FlxObject
{
	/**
	 * Set this flag to use one of the 16-tile binary auto-tile algorithms (OFF, AUTO, or ALT).
	 */
	public var auto:FlxTilemapAutoTiling = OFF;

	static var offsetAutoTile:Array<Int> = [
		0,   0, 0, 0,  2,   2, 0,   3, 0, 0, 0, 0,  0,   0, 0,   0,
		11,  11, 0, 0, 13,  13, 0,  14, 0, 0, 0, 0, 18,  18, 0,  19,
		0,   0, 0, 0,  0,   0, 0,   0, 0, 0, 0, 0,  0,   0, 0,   0,
		0,   0, 0, 0,  0,   0, 0,   0, 0, 0, 0, 0,  0,   0, 0,   0,
		51,  51, 0, 0, 53,  53, 0,  54, 0, 0, 0, 0,  0,   0, 0,   0,
		62,  62, 0, 0, 64,  64, 0,  65, 0, 0, 0, 0, 69,  69, 0,  70,
		0,   0, 0, 0,  0,   0, 0,   0, 0, 0, 0, 0,  0,   0, 0,   0,
		86,  86, 0, 0, 88,  88, 0,  89, 0, 0, 0, 0, 93,  93, 0,  94,
		0,   0, 0, 0,  0,   0, 0,   0, 0, 0, 0, 0,  0,   0, 0,   0,
		0,   0, 0, 0,  0,   0, 0,   0, 0, 0, 0, 0,  0,   0, 0,   0,
		0,   0, 0, 0,  0,   0, 0,   0, 0, 0, 0, 0,  0,   0, 0,   0,
		0,   0, 0, 0,  0,   0, 0,   0, 0, 0, 0, 0,  0,   0, 0,   0,
		0, 159, 0, 0,  0, 162, 0, 163, 0, 0, 0, 0,  0,   0, 0,   0,
		0, 172, 0, 0,  0, 175, 0, 176, 0, 0, 0, 0,  0, 181, 0, 182,
		0,   0, 0, 0,  0,   0, 0,   0, 0, 0, 0, 0,  0,   0, 0,   0,
		0, 199, 0, 0,  0, 202, 0, 203, 0, 0, 0, 0,  0, 208, 0, 209
	];

	static var diagonalPathfinder = new FlxDiagonalPathfinder();

	public var widthInTiles(default, null):Int = 0;

	public var heightInTiles(default, null):Int = 0;

	public var totalTiles(default, null):Int = 0;

	/**
	 * Set this to create your own image index remapper, so you can create your own tile layouts.
	 * Mostly useful in combination with the auto-tilers.
	 *
	 * Normally, each tile's value in _data corresponds to the index of a
	 * tile frame in the tilesheet. With this active, each value in _data
	 * is a lookup value to that index in customTileRemap.
	 *
	 * Example:
	 *  customTileRemap = [10,9,8,7,6]
	 *  means: 0=10, 1=9, 2=8, 3=7, 4=6
	 */
	public var customTileRemap:Array<Int>;

	/**
	 * If these next two arrays are not null, you're telling FlxTilemap to
	 * draw random tiles in certain places.
	 *
	 * _randomIndices is a list of tilemap values that should be replaced
	 * by a randomly selected value. The available values are chosen from
	 * the corresponding array in randomize_choices
	 *
	 * So if you have:
	 *   randomIndices = [12,14]
	 *   randomChoices = [[0,1,2],[3,4,5,6,7]]
	 *
	 * Everywhere the tilemap has a value of 12 it will be replaced by 0, 1, or, 2
	 * Everywhere the tilemap has a value of 14 it will be replaced by 3, 4, 5, 6, 7
	 */
	var _randomIndices:Array<Int>;

	var _randomChoices:Array<Array<Int>>;

	/**
	 * Setting this function allows you to control which choice will be selected for each element within _randomIndices array.
	 * Must return a 0-1 value that gets multiplied by _randomChoices[randIndex].length;
	 */
	var _randomLambda:Void->Float;

	/**
	 * Internal collection of tile objects, one for each type of tile in the map (NOT one for every single tile in the whole map).
	 */
	var _tileObjects:Array<Tile> = [];

	/**
	 * Internal, used to sort of insert blank tiles in front of the tiles in the provided graphic.
	 */
	var _startingIndex:Int = 0;

	/**
	 * Internal representation of the actual tile data, as a large 1D array of integers.
	 */
	var _data:Array<Int>;

	var _drawIndex:Int = 0;
	var _collideIndex:Int = 0;

	/**
	 * Virtual methods, must be implemented in each renderers
	 */
	function updateTile(index:Int):Void
	{
		throw "updateTile must be implemented";
	}

	function cacheGraphics(tileWidth:Int, tileHeight:Int, tileGraphic:FlxTilemapGraphicAsset):Void
	{
		throw "cacheGraphics must be implemented";
	}

	function initTileObjects():Void
	{
		throw "initTileObjects must be implemented";
	}

	function updateMap():Void
	{
		throw "updateMap must be implemented";
	}

	function computeDimensions():Void
	{
		throw "computeDimensions must be implemented";
	}

	/**
	 * Finds the column number that overlaps the given X in world space
	 *
	 * @param   worldX  An X coordinate in the world
	 * @param   bind    If true, it will prevent out of range values
	 * @return  A column index, where 0 is the left-most column
	 * @since 5.9.0
	 */
	public function getColumnAt(worldX:Float, bind = false):Int
	{
		throw "getColumnAt must be implemented";
	}

	/**
	 * Finds the row number that overlaps the given Y in world space
	 *
	 * @param   worldY  A Y coordinate in the world
	 * @param   bind    If true, it will prevent out of range values
	 * @return  A row index, where 0 is the top-most row
	 * @since 5.9.0
	 */
	public function getRowAt(worldY:Float, bind = false):Int
	{
		throw "getRowAt must be implemented";
	}

	/**
	 * Get the world position of the specified column
	 *
	 * @param   column    The grid X location, in tiles
	 * @param   midpoint  Whether to use the tile's midpoint, or upper left corner
	 * @since 5.9.0
	 */
	public function getColumnPos(column:Float, midPoint = false):Float
	{
		throw "getColumnPos must be implemented";
	}

	/**
	 * Get the world position of the specified row
	 *
	 * @param   row       The grid Y location, in tiles
	 * @param   midpoint  Whether to use the tile's midpoint, or upper left corner
	 * @since 5.9.0
	 */
	public function getRowPos(row:Int, midPoint = false):Float
	{
		throw "getRowPos must be implemented";
	}

	/**
	 * Shoots a ray from the start point to the end point.
	 * If/when it passes through a tile, it stores that point and returns false.
	 *
	 * **Note:** In flixel 5.0.0, this was redone, the old method is now `rayStep`
	 *
	 * @param   start   The world coordinates of the start of the ray.
	 * @param   end     The world coordinates of the end of the ray.
	 * @param   result  Optional result vector, to avoid creating a new instance to be returned.
	 *                  Only returned if the line enters the rect.
	 * @return  Returns true if the ray made it from Start to End without hitting anything.
	 *          Returns false and fills Result if a tile was hit.
	 */
	public function ray(start:FlxPoint, end:FlxPoint, ?result:FlxPoint):Bool
	{
		throw "ray must be implemented";
		return false;
	}

	/**
	 * Calculates at which point where the given line, from start to end, first enters the tilemap.
	 * If the line starts inside the tilemap, a copy of start is returned.
	 * If the line never enters the tilemap, null is returned.
	 *
	 * **Note:** If a result vector is supplied and the line is outside the tilemap, null is returned
	 * and the supplied result is unchanged
	 * @since 5.0.0
	 *
	 * @param start   The start of the line
	 * @param end     The end of the line
	 * @param result  Optional result vector, to avoid creating a new instance to be returned.
	 *                Only returned if the line enters the tilemap.
	 * @return The point of entry of the line into the tilemap, if possible.
	 */
	public function calcRayEntry(start, end, ?result)
	{
		var bounds = getBounds(FlxRect.weak());
		// subtract 1 from size otherwise `getTileIndexByCoords` will have weird edge cases (literally)
		bounds.width--;
		bounds.height--;

		return FlxCollision.calcRectEntry(bounds, start, end, result);
	}

	/**
	 * Calculates at which point where the given line, from start to end, was last inside the tilemap.
	 * If the line ends inside the tilemap, a copy of end is returned.
	 * If the line is never inside the tilemap, null is returned.
	 *
	 * **Note:** If a result vector is supplied and the line is outside the tilemap, null is returned
	 * and the supplied result is unchanged
	 * @since 5.0.0
	 *
	 * @param start   The start of the line
	 * @param end     The end of the line
	 * @param result  Optional result vector, to avoid creating a new instance to be returned.
	 *                Only returned if the line enters the tilemap.
	 * @return The point of exit of the line from the tilemap, if possible.
	 */
	public inline function calcRayExit(start, end, ?result)
	{
		return calcRayEntry(end, start, result);
	}

	/**
	 * Searches all tiles near the object for any that satisfy the given filter. Stops searching
	 * when the first overlapping tile that satisfies the condition is found
	 *
	 * @param   object    The object
	 * @param   filter    Function that takes a tile and returns whether is satisfies the
	 *                    disired condition, if `null`, any overlapping tile will satisfy
	 * @param   position  Optional, specify a custom position for the tilemap
	 * @return  Whether any overlapping tile satisfied the condition, if there was one
	 * @since 5.9.0
	 */
	public function isOverlappingTile(object:FlxObject, ?filter:(tile:Tile)->Bool, ?position:FlxPoint):Bool
	{
		throw "overlapsWithCallback must be implemented";
	}

	/**
	 * Calls the given function on ever tile that is overlapping the target object
	 *
	 * @param   object    The object
	 * @param   filter    Function that takes a tile and returns whether is satisfies the
	 *                    disired condition
	 * @param   position  Optional, specify a custom position for the tilemap
	 * @return  Whether any overlapping tile was found
	 * @since 5.9.0
	 */
	public function forEachOverlappingTile(object:FlxObject, func:(tile:Tile)->Void, ?position:FlxPoint):Bool
	{
		throw "overlapsWithCallback must be implemented";
	}

	/**
	 * Checks if the Object overlaps any tiles with any collision flags set,
	 * and calls the specified callback function (if there is one).
	 * Also calls the tile's registered callback if the filter matches.
	 *
	 * **Note:** To flip the callback params you can simply swap them in a arrow func, like so:
	 * ```haxe
	 * final result = objectOverlapsTiles(obj, (tile, obj)->myCallback(obj, tile));
	 * ```
	 *
	 * @param   object       The FlxObject you are checking for overlaps against
	 * @param   callback     An optional function that takes the overlapping tile and object
	 *                       where `a` is a `FlxTile`, and `b` is the given `object` paaram
	 * @param   position     Optional, specify a custom position for the tilemap (see `overlapsAt`)
	 * @param   isCollision  If true, tiles where `allowCollisions` is `NONE` are excluded,
	 *                       and the tiles' `onCollide` is dispatched
	 * @return  Whether there were overlaps that resulted in a positive callback, if one was specified
	 * @since 5.9.0
	 */
	public function objectOverlapsTiles<TObj:FlxObject>(object:TObj, ?callback:(Tile, TObj)->Bool, ?position:FlxPoint, isCollision = true):Bool
	{
		throw "objectOverlapsTiles must be implemented";
	}

	public function setDirty(dirty:Bool = true):Void
	{
		throw "setDirty must be implemented";
	}

	function new()
	{
		super();

		flixelType = TILEMAP;
		immovable = true;
		moves = false;
	}

	override function destroy():Void
	{
		_data = null;
		super.destroy();
	}

	/**
	 * Load the tilemap with string data and a tile graphic.
	 *
	 * @param   mapData         A csv-formatted string indicating what order the tiles should go in (or the path to that file)
	 * @param   tileGraphic     All the tiles you want to use, arranged in a strip corresponding to the numbers in MapData.
	 * @param   tileWidth       The width of your tiles (e.g. 8) - defaults to height of the tile graphic if unspecified.
	 * @param   tileHeight      The height of your tiles (e.g. 8) - defaults to width if unspecified.
	 * @param   autoTile        Whether to load the map using an automatic tile placement algorithm (requires 16 tiles!).
	 *                          Setting this to either AUTO or ALT will override any values you put for StartingIndex, DrawIndex, or CollideIndex.
	 * @param   startingIndex   Used to sort of insert empty tiles in front of the provided graphic.
	 *                          Default is 0, usually safest ot leave it at that.  Ignored if AutoTile is set.
	 * @param   drawIndex       Initializes all tile objects equal to and after this index as visible.
	 *                          Default value is 1. Ignored if AutoTile is set.
	 * @param   collideIndex    Initializes all tile objects equal to and after this index as allowCollisions = ANY.
	 *                          Default value is 1.  Ignored if AutoTile is set.
	 *                          Can override and customize per-tile-type collision behavior using setTileProperties().
	 * @return  A reference to this instance of FlxTilemap, for chaining as usual :)
	 */
	public function loadMapFromCSV(mapData:String, tileGraphic:FlxTilemapGraphicAsset, tileWidth = 0, tileHeight = 0, ?autoTile:FlxTilemapAutoTiling,
			startingIndex = 0, drawIndex = 1, collideIndex = 1)
	{
		// path to map data file?
		if (FlxG.assets.exists(mapData))
		{
			mapData = FlxG.assets.getTextUnsafe(mapData);
		}

		// Figure out the map dimensions based on the data string
		_data = [];
		var columns:Array<String>;

		var regex:EReg = new EReg("[ \t]*((\r\n)|\r|\n)[ \t]*", "g");
		var lines:Array<String> = regex.split(mapData);
		var rows:Array<String> = lines.filter(function(line) return line != "");

		heightInTiles = rows.length;
		widthInTiles = 0;

		var row:Int = 0;
		while (row < heightInTiles)
		{
			var rowString = rows[row];
			if (rowString.endsWith(","))
				rowString = rowString.substr(0, rowString.length - 1);
			columns = rowString.split(",");

			if (columns.length == 0)
			{
				heightInTiles--;
				continue;
			}
			if (widthInTiles == 0)
			{
				widthInTiles = columns.length;
			}

			var column = 0;
			while (column < widthInTiles)
			{
				// the current tile to be added:
				var columnString = columns[column];
				var curTile = Std.parseInt(columnString);

				if (curTile == null)
					throw 'String in row $row, column $column is not a valid integer: "$columnString"';

				_data.push(curTile);
				column++;
			}

			row++;
		}

		loadMapHelper(tileGraphic, tileWidth, tileHeight, autoTile, startingIndex, drawIndex, collideIndex);
		return this;
	}

	/**
	 * Load the tilemap with string data and a tile graphic.
	 *
	 * @param   mapData         An array containing the (non-negative) tile indices.
	 * @param   widthInTiles    The width of the tilemap in tiles
	 * @param   heightInTiles   The height of the tilemap in tiles
	 * @param   tileGraphic     All the tiles you want to use, arranged in a strip corresponding to the numbers in MapData.
	 * @param   tileWidth       The width of your tiles (e.g. 8) - defaults to height of the tile graphic if unspecified.
	 * @param   tileHeight      The height of your tiles (e.g. 8) - defaults to width if unspecified.
	 * @param   autoTile        Whether to load the map using an automatic tile placement algorithm (requires 16 tiles!).
	 *                          Setting this to either AUTO or ALT will override any values you put for StartingIndex, DrawIndex, or CollideIndex.
	 * @param   startingIndex   Used to sort of insert empty tiles in front of the provided graphic.
	 *                          Default is 0, usually safest ot leave it at that.  Ignored if AutoTile is set.
	 * @param   drawIndex       Initializes all tile objects equal to and after this index as visible.
	 *                          Default value is 1. Ignored if AutoTile is set.
	 * @param   collideIndex    Initializes all tile objects equal to and after this index as allowCollisions = ANY.
	 *                          Default value is 1.  Ignored if AutoTile is set.
	 *                          Can override and customize per-tile-type collision behavior using setTileProperties().
	 * @return  A reference to this instance of FlxTilemap, for chaining as usual :)
	 */
	public function loadMapFromArray(mapData:Array<Int>, widthInTiles:Int, heightInTiles:Int, tileGraphic:FlxTilemapGraphicAsset, tileWidth = 0, tileHeight = 0,
			?autoTile:FlxTilemapAutoTiling, startingIndex = 0, drawIndex = 1, collideIndex = 1)
	{
		this.widthInTiles = widthInTiles;
		this.heightInTiles = heightInTiles;
		_data = mapData.copy(); // make a copy to make sure we don't mess with the original array, which might be used for something!

		loadMapHelper(tileGraphic, tileWidth, tileHeight, autoTile, startingIndex, drawIndex, collideIndex);
		return this;
	}

	/**
	 * Load the tilemap with string data and a tile graphic.
	 *
	 * @param   mapData         A 2D array containing the (non-negative) tile indices. The length of the inner arrays should be consistent.
	 * @param   tileGraphic     All the tiles you want to use, arranged in a strip corresponding to the numbers in MapData.
	 * @param   tileWidth       The width of your tiles (e.g. 8) - defaults to height of the tile graphic if unspecified.
	 * @param   tileHeight      The height of your tiles (e.g. 8) - defaults to width if unspecified.
	 * @param   autoTile        Whether to load the map using an automatic tile placement algorithm (requires 16 tiles!).
	 *                          Setting this to either AUTO or ALT will override any values you put for StartingIndex, DrawIndex, or CollideIndex.
	 * @param   startingIndex   Used to sort of insert empty tiles in front of the provided graphic.
	 *                          Default is 0, usually safest ot leave it at that.  Ignored if AutoTile is set.
	 * @param   drawIndex       Initializes all tile objects equal to and after this index as visible.
	 *                          Default value is 1. Ignored if AutoTile is set.
	 * @param   collideIndex    Initializes all tile objects equal to and after this index as allowCollisions = ANY.
	 *                          Default value is 1.  Ignored if AutoTile is set.
	 *                          Can override and customize per-tile-type collision behavior using setTileProperties().
	 * @return  A reference to this instance of FlxTilemap, for chaining as usual :)
	 */
	public function loadMapFrom2DArray(mapData:Array<Array<Int>>, tileGraphic:FlxTilemapGraphicAsset, tileWidth = 0, tileHeight = 0,
			?autoTile:FlxTilemapAutoTiling, startingIndex = 0, drawIndex = 1, collideIndex = 1)
	{
		widthInTiles = mapData[0].length;
		heightInTiles = mapData.length;
		_data = FlxArrayUtil.flatten2DArray(mapData);

		loadMapHelper(tileGraphic, tileWidth, tileHeight, autoTile, startingIndex, drawIndex, collideIndex);
		return this;
	}

	/**
	 * Load the tilemap with image data and a tile graphic.
	 * Black pixels are flagged as 'solid' by default, non-black pixels are set as non-colliding. Black pixels must be PURE BLACK.
	 * @param   mapGraphic      The image you want to use as a source of map data, where each pixel is a tile (or more than one tile if you change Scale's default value). Preferably black and white.
	 * @param   invert          Load white pixels as solid instead.
	 * @param   scale           Default is 1. Scale of 2 means each pixel forms a 2x2 block of tiles, and so on.
	 * @param   colorMap        An array of color values (alpha values are ignored) in the order they're intended to be assigned as indices
	 * @param   tileGraphic     All the tiles you want to use, arranged in a strip corresponding to the numbers in MapData.
	 * @param   tileWidth       The width of your tiles (e.g. 8) - defaults to height of the tile graphic if unspecified.
	 * @param   tileHeight      The height of your tiles (e.g. 8) - defaults to width if unspecified.
	 * @param   autoTile        Whether to load the map using an automatic tile placement algorithm (requires 16 tiles!).
	 *                          Setting this to either AUTO or ALT will override any values you put for StartingIndex, DrawIndex, or CollideIndex.
	 * @param   startingIndex   Used to sort of insert empty tiles in front of the provided graphic.
	 *                          Default is 0, usually safest ot leave it at that.  Ignored if AutoTile is set.
	 * @param   drawIndex       Initializes all tile objects equal to and after this index as visible.
	 *                          Default value is 1. Ignored if AutoTile is set.
	 * @param   collideIndex    Initializes all tile objects equal to and after this index as allowCollisions = ANY.
	 *                          Default value is 1.  Ignored if AutoTile is set.
	 *                          Can override and customize per-tile-type collision behavior using setTileProperties().
	 * @return  A reference to this instance of FlxTilemap, for chaining as usual :)
	 * @since   4.1.0
	 */
	public function loadMapFromGraphic(mapGraphic:FlxGraphicSource, invert = false, scale = 1, ?colorMap:Array<FlxColor>,
			tileGraphic:FlxTilemapGraphicAsset, tileWidth = 0, tileHeight = 0, ?autoTile:FlxTilemapAutoTiling,
			startingIndex = 0, drawIndex = 1, collideIndex = 1)
	{
		var mapBitmap:BitmapData = FlxAssets.resolveBitmapData(mapGraphic);
		var mapData:String = FlxStringUtil.bitmapToCSV(mapBitmap, invert, scale, colorMap);
		return loadMapFromCSV(mapData, tileGraphic, tileWidth, tileHeight, autoTile, startingIndex, drawIndex, collideIndex);
	}

	function loadMapHelper(tileGraphic:FlxTilemapGraphicAsset, tileWidth = 0, tileHeight = 0, ?autoTile:FlxTilemapAutoTiling,
			startingIndex = 0, drawIndex = 1, collideIndex = 1)
	{
		// anything < 0 should be treated as 0 for compatibility with certain map formats (ogmo)
		for (i in 0..._data.length)
		{
			if (_data[i] < 0)
				_data[i] = 0;
		}

		totalTiles = _data.length;
		auto = (autoTile == null) ? OFF : autoTile;
		_startingIndex = (startingIndex <= 0) ? 0 : startingIndex;

		if (auto != OFF)
		{
			_startingIndex = 1;
			drawIndex = 1;
			collideIndex = 1;
		}

		_drawIndex = drawIndex;
		_collideIndex = collideIndex;

		applyAutoTile();
		applyCustomRemap();
		randomizeIndices();
		cacheGraphics(tileWidth, tileHeight, tileGraphic);
		postGraphicLoad();
	}

	function postGraphicLoad()
	{
		initTileObjects();
		computeDimensions();
		updateMap();
	}

	function applyAutoTile():Void
	{
		// Pre-process the map data if it's auto-tiled
		if (auto != OFF)
		{
			var i:Int = 0;
			while (i < totalTiles)
			{
				autoTile(i++);
			}
		}
	}

	function applyCustomRemap():Void
	{
		var i:Int = 0;

		if (customTileRemap != null)
		{
			while (i < totalTiles)
			{
				var oldIndex = _data[i];
				var newIndex = oldIndex;
				if (oldIndex < customTileRemap.length)
				{
					newIndex = customTileRemap[oldIndex];
				}
				_data[i] = newIndex;
				i++;
			}
		}
	}

	function randomizeIndices():Void
	{
		var i:Int = 0;

		if (_randomIndices != null)
		{
			var randLambda:Void->Float = _randomLambda != null ? _randomLambda : function()
			{
				return FlxG.random.float();
			};

			while (i < totalTiles)
			{
				var oldIndex = _data[i];
				var j = 0;
				var newIndex = oldIndex;
				for (rand in _randomIndices)
				{
					if (oldIndex == rand)
					{
						var k:Int = Std.int(randLambda() * _randomChoices[j].length);
						newIndex = _randomChoices[j][k];
					}
					j++;
				}
				_data[i] = newIndex;
				i++;
			}
		}
	}

	/**
	 * An internal function used by the binary auto-tilers. (16 tiles)
	 *
	 * @param   index  The index of the tile you want to analyze.
	 */
	function autoTile(index:Int):Void
	{
		if (_data[index] == 0)
		{
			return;
		}

		if (auto == FULL)
		{
			autoTileFull(index);
			return;
		}

		_data[index] = 0;

		// UP
		if ((index - widthInTiles < 0) || (_data[index - widthInTiles] > 0))
		{
			_data[index] += 1;
		}
		// RIGHT
		if ((index % widthInTiles >= widthInTiles - 1) || (_data[index + 1] > 0))
		{
			_data[index] += 2;
		}
		// DOWN
		if ((Std.int(index + widthInTiles) >= totalTiles) || (_data[index + widthInTiles] > 0))
		{
			_data[index] += 4;
		}
		// LEFT
		if ((index % widthInTiles <= 0) || (_data[index - 1] > 0))
		{
			_data[index] += 8;
		}

		// The alternate algo checks for interior corners
		if ((auto == ALT) && (_data[index] == 15))
		{
			// BOTTOM LEFT OPEN
			if ((index % widthInTiles > 0) && (Std.int(index + widthInTiles) < totalTiles) && (_data[index + widthInTiles - 1] <= 0))
			{
				_data[index] = 1;
			}
			// TOP LEFT OPEN
			if ((index % widthInTiles > 0) && (index - widthInTiles >= 0) && (_data[index - widthInTiles - 1] <= 0))
			{
				_data[index] = 2;
			}
			// TOP RIGHT OPEN
			if ((index % widthInTiles < widthInTiles - 1) && (index - widthInTiles >= 0) && (_data[index - widthInTiles + 1] <= 0))
			{
				_data[index] = 4;
			}
			// BOTTOM RIGHT OPEN
			if ((index % widthInTiles < widthInTiles - 1)
				&& (Std.int(index + widthInTiles) < totalTiles)
				&& (_data[index + widthInTiles + 1] <= 0))
			{
				_data[index] = 8;
			}
		}

		_data[index] += 1;
	}

	/**
	 * An internal function used by the binary auto-tilers. (47 tiles)
	 *
	 * @param   index  The index of the tile you want to analyze.
	 */
	function autoTileFull(index:Int):Void
	{
		_data[index] = 0;

		var wallUp:Bool = index - widthInTiles < 0;
		var wallRight:Bool = index % widthInTiles >= widthInTiles - 1;
		var wallDown:Bool = Std.int(index + widthInTiles) >= totalTiles;
		var wallLeft:Bool = index % widthInTiles <= 0;

		var up = wallUp || _data[index - widthInTiles] > 0;
		var upRight = wallUp || wallRight || _data[index - widthInTiles + 1] > 0;
		var right = wallRight || _data[index + 1] > 0;
		var rightDown = wallRight || wallDown || _data[index + widthInTiles + 1] > 0;
		var down = wallDown || _data[index + widthInTiles] > 0;
		var downLeft = wallDown || wallLeft || _data[index + widthInTiles - 1] > 0;
		var left = wallLeft || _data[index - 1] > 0;
		var leftUp = wallLeft || wallUp || _data[index - widthInTiles - 1] > 0;

		if (up)
			_data[index] += 1;
		if (upRight && up && right)
			_data[index] += 2;
		if (right)
			_data[index] += 4;
		if (rightDown && right && down)
			_data[index] += 8;
		if (down)
			_data[index] += 16;
		if (downLeft && down && left)
			_data[index] += 32;
		if (left)
			_data[index] += 64;
		if (leftUp && left && up)
			_data[index] += 128;

		_data[index] -= offsetAutoTile[_data[index]] - 1;
	}

	/**
	 * Set custom tile mapping and/or randomization rules prior to loading. This MUST be called BEFORE loadMap().
	 * WARNING: Using this will cause your maps to take longer to load. Be careful using this in very large tilemaps.
	 *
	 * @param   mappings       Array of ints for remapping tiles. Ex: [7,4,12] means "0-->7, 1-->4, 2-->12"
	 * @param   randomIndices  Array of ints indicating which tile indices should be randomized. Ex: [7,4,12] means "replace tile index of 7, 4, or 12 with a randomized value"
	 * @param   randomChoices  A list of int-arrays that serve as the corresponding choices to randomly choose from. Ex: indices = [7,4], choices = [[1,2],[3,4,5]], 7 will be replaced by either 1 or 2, 4 will be replaced by 3, 4, or 5.
	 * @param   randomLambda   A custom randomizer function, should return value between 0.0 and 1.0. Initialize your random seed before passing this in! If not defined, will default to unseeded Math.random() calls.
	 */
	public function setCustomTileMappings(mappings:Array<Int>, ?randomIndices:Array<Int>, ?randomChoices:Array<Array<Int>>, ?randomLambda:Void->Float):Void
	{
		customTileRemap = mappings;
		_randomIndices = randomIndices;
		_randomChoices = randomChoices;
		_randomLambda = randomLambda;

		// make sure users provide all that data required if they wish to randomize tile mappings.
		if (_randomIndices != null && (_randomChoices == null || _randomChoices.length == 0))
		{
			throw "You must provide valid 'randomChoices' if you wish to randomize tilemap indices, please read documentation of 'setCustomTileMappings' function.";
		}
	}

	/**
	 * Calculates a `mapIndex` via `row * widthInTiles + column`,
	 * if the column or row is not valid, the result is `-1`
	 *
	 * @param   column  The grid X location, in tiles
	 * @param   row     The grid Y location, in tiles
	 * @since 5.9.0
	 */
	public overload extern inline function getMapIndex(column:Int, row:Int):Int
	{
		return tileExists(column, row) ? (row * widthInTiles + column) : -1;
	}

	/**
	 * Calculates a `mapIndex` of the given location, if the coordinate
	 * does not overlap the tilemap, the result is `-1`
	 *
	 * **Note:** A tile's `mapIndex` can be calculated via `row * widthInTiles + column`
	 *
	 * @param   worldPos  A location in the world
	 * @since 5.9.0
	 */
	public overload extern inline function getMapIndex(worldPos:FlxPoint):Int
	{
		return getMapIndexAt(worldPos.x, worldPos.y);
	}

	/**
	 * Calculates a `mapIndex` of the given location, if the coordinate
	 * does not overlap the tilemap, the result is `-1`
	 *
	 * **Note:** A tile's `mapIndex` can be calculated via `row * widthInTiles + column`
	 *
	 * @param   worldX  An X coordinate in the world
	 * @param   worldY  A Y coordinate in the world
	 * @since 5.9.0
	 */
	public inline function getMapIndexAt(worldX:Float, worldY:Float):Int
	{
		return getMapIndex(getColumnAt(worldX), getRowAt(worldY));
	}
	/**
	 * Calculates the column from a map location
	 *
	 * @param   mapIndex  The location in the map where `mapIndex = row * widthInTiles + column`
	 * @since 5.9.0
	 */
	public inline function getColumn(mapIndex:Int):Int
	{
		return mapIndex % widthInTiles;
	}

	/**
	 * Calculates the column from a map location
	 *
	 * @param   mapIndex  The location in the map where `mapIndex = row * widthInTiles + column`
	 * @since 5.9.0
	 */
	public inline function getRow(mapIndex:Int):Int
	{
		return Std.int(mapIndex / widthInTiles);
	}

	/**
	 * Whether a tile exists at the given map location
	 *
	 * @param   column  The grid X location, in tiles
	 * @param   row     The grid Y location, in tiles
	 * @since 5.9.0
	 */
	public overload extern inline function tileExists(column:Int, row:Int):Bool
	{
		return columnExists(column) && rowExists(row);
	}

	/**
	 * Whether a tile exists at the given map location
	 *
	 * **Note:** A tile's `mapIndex` can be calculated via `row * widthInTiles + column`
	 *
	 * @param   mapIndex  The desired location in the map
	 * @since 5.9.0
	 */
	public overload extern inline function tileExists(mapIndex:Int):Bool
	{
		return mapIndex >= 0 && mapIndex < _data.length;
	}

	/**
	 * Whether a tile exists at the given map location
	 *
	 * @param   worldPos  A location in the map
	 * @since 5.9.0
	 */
	public overload extern inline function tileExists(worldPos:FlxPoint):Bool
	{
		return tileExistsAt(worldPos.x, worldPos.y);
	}

	/**
	 * Whether a tile exists at the given map location
	 *
	 * @param   worldX  An X coordinate in the world
	 * @param   worldY  A Y coordinate in the world
	 * @since 5.9.0
	 */
	public inline function tileExistsAt(worldX:Float, worldY:Float):Bool
	{
		return columnExistsAt(worldX) && rowExistsAt(worldY);
	}

	/**
	 * Whether a row exists at the given map location
	 *
	 * @param   column  The grid X location, in tiles
	 * @since 5.9.0
	 */
	public overload extern inline function columnExists(column:Int):Bool
	{
		return column >= 0 && column < widthInTiles;
	}

	/**
	 * Whether a column exists at the given map location
	 *
	 * @param   worldX  An X coordinate in the world
	 * @since 5.9.0
	 */
	public inline function columnExistsAt(worldX:Float):Bool
	{
		return columnExists(getColumnAt(worldX));
	}

	/**
	 * Whether a row exists at the given map location
	 *
	 * @param   row  The grid Y location, in tiles
	 * @since 5.9.0
	 */
	public overload extern inline function rowExists(row:Int):Bool
	{
		return row >= 0 && row < heightInTiles;
	}

	/**
	 * Whether a row exists at the given map location
	 *
	 * @param   worldY  A Y coordinate in the world
	 * @since 5.9.0
	 */
	public inline function rowExistsAt(worldY:Float):Bool
	{
		return rowExists(getRowAt(worldY));
	}

	/**
	 * Finds the tile instance at a particular column and row,
	 * if the column or row is invalid, the result is `null`
	 *
	 * @param   column  The grid X location, in tiles
	 * @param   row     The grid Y location, in tiles
	 * @since 5.9.0
	 */
	public overload extern inline function getTileData(column:Int, row:Int):Null<Tile>
	{
		return getTileData(getMapIndex(column, row));
	}

	/**
	 * Finds the tile instance with the given `mapIndex`,
	 * if the `mapIndex` is invalid, the result is `null`
	 *
	 * **Note:** A tile's `mapIndex` can be calculated via `row * widthInTiles + column`
	 *
	 * **Note:** The reulting tile's `x`, `y`, `width` and `height` will not be accurate.
	 * You can call `tile.orient` or similar methods
	 *
	 * @param   mapIndex  The desired location in the map
	 * @since 5.9.0
	 */
	public overload extern inline function getTileData(mapIndex:Int):Null<Tile>
	{
		return _tileObjects[getTileIndex(mapIndex)];
	}

	/**
	 * Finds the tile instance with the given world location, if the
	 * coordinate does not overlap the tilemap, the result is `null`
	 *
	 * **Note:** The reulting tile's `x`, `y`, `width` and `height` will not be accurate.
	 * You can call `tile.orient` or similar methods
	 *
	 * @param   worldPos  A location in the world
	 * @since 5.9.0
	 */
	public overload extern inline function getTileData(worldPos:FlxPoint):Null<Tile>
	{
		return getTileDataAt(worldPos.x, worldPos.y);
	}

	/**
	 * Finds the tile instance with the given world location, if the
	 * coordinate does not overlap the tilemap, the result is `null`
	 *
	 * **Note:** The reulting tile's `x`, `y`, `width` and `height` will not be accurate.
	 * You can call `tile.orient` or similar methods
	 *
	 * @param   worldX  An X coordinate in the world
	 * @param   worldY  A Y coordinate in the world
	 * @since 5.9.0
	 */
	public overload extern inline function getTileDataAt(worldX:Float, worldY:Float):Null<Tile>
	{
		return _tileObjects[getTileIndexAt(worldX, worldY)];
	}

	/**
	 * Check the value of a particular tile, if the
	 * column or row is invalid, the result is `-1`
	 *
	 * @param   column  The grid X location, in tiles
	 * @param   row     The grid Y location, in tiles
	 * @return  The tile index of the tile at this location
	 * @since 5.9.0
	 */
	public overload extern inline function getTileIndex(column:Int, row:Int):Int
	{
		return getTileIndex(getMapIndex(column, row));
	}

	/**
	 * Get the `tileIndex` at the given map location,
	 * if the `mapIndex` is invalid, the result is `-1`
	 *
	 * **Note:** A tile's `mapIndex` can be calculated via `row * widthInTiles + column`
	 *
	 * @param   mapIndex  The desired location in the map
	 * @return  The tileIndex of the tile with this `mapIndex`
	 * @since 5.9.0
	 */
	public overload extern inline function getTileIndex(mapIndex:Int):Int
	{
		return tileExists(mapIndex) ? _data[mapIndex] : -1;
	}

	/**
	 * Get the `tileIndex` at the given location, if the coordinate
	 * does not overlap the tilemap, the result is `-1`
	 *
	 * @param   worldPos  A location in the world
	 * @return  The tileIndex of the tile at this location
	 * @since 5.9.0
	 */
	public overload extern inline function getTileIndex(worldPos:FlxPoint):Int
	{
		return getTileIndexAt(worldPos.x, worldPos.y);
	}

	/**
	 * Get the `tileIndex` at the given location, if the coordinate
	 * does not overlap the tilemap, the result is `-1`
	 *
	 * @param   worldX  An X coordinate in the world
	 * @param   worldY  A Y coordinate in the world
	 * @return  The tileIndex of the tile at this location
	 * @since 5.9.0
	 */
	public inline function getTileIndexAt(worldX:Float, worldY:Float):Int
	{
		return getTileIndex(getColumnAt(worldX), getRowAt(worldY));
	}

	/**
	 * Get the world position of the specified tile, if the `mapIndex` is invalid,
	 * the result is `null`
	 *
	 * **Note:** A tile's `mapIndex` can be calculated via `row * widthInTiles + column`
	 *
	 * @param   mapIndex  The desired location in the map
	 * @param   midpoint  Whether to use the tile's midpoint, or upper left corner
	 * @return  The world position of the matching tile
	 * @since 5.9.0
	 */
	public overload extern inline function getTilePos(mapIndex:Int, midpoint = false):Null<FlxPoint>
	{
		return tileExists(mapIndex) ? getTilePos(getColumn(mapIndex), getRow(mapIndex), midpoint) : null;
	}

	/**
	 * Get the world position of the specified tile
	 *
	 * **Note:** The column or row does not need to be valid, to ensure a
	 * valid tile, use `if (tileExists(column, row))`, first
	 *
	 * @param   column    The grid X location, in tiles
	 * @param   row       The grid Y location, in tiles
	 * @param   midpoint  Whether to use the tile's midpoint, or upper left corner
	 * @return  The world position of the matching tile
	 * @since 5.9.0
	 */
	public overload extern inline function getTilePos(column:Int, row:Int, midpoint = false):FlxPoint
	{
		return FlxPoint.get(getColumnPos(column, midpoint), getRowPos(row, midpoint));
	}

	/**
	 * Get the world position of the tile overlapping the specified position
	 *
	 * **Note:** The location does not need to overlap the tilemap, to ensure a
	 * valid tile, use `if (tileExists(worldPos))`, first
	 *
	 * @param   worldPos  A location in the world
	 * @param   midpoint  Whether to use the tile's midpoint, or upper left corner
	 * @return  The world position of the overlapping tile
	 * @since 5.9.0
	 */
	public overload extern inline function getTilePos(worldPos:FlxPoint, midpoint = false):FlxPoint
	{
		return getTilePosAt(worldPos.x, worldPos.y, midpoint);
	}

	/**
	 * Get the world position of the tile overlapping the specified position
	 *
	 * **Note:** The location does not need to overlap the tilemap, to ensure a
	 * valid tile, use `if (tileExistsAt(worldX, worldY))`, first
	 *
	 * @param   worldX    An X coordinate in the world
	 * @param   worldY    A Y coordinate in the world
	 * @param   midpoint  Whether to use the tile's midpoint, or upper left corner
	 * @return  The world position of the overlapping tile
	 * @since 5.9.0
	 */
	public inline function getTilePosAt(worldX:Float, worldY:Float, midpoint = false):FlxPoint
	{
		return getTilePos(getColumnAt(worldX), getRowAt(worldY), midpoint);
	}

	/**
	 * Returns a new array full of every coordinate of the requested tile type.
	 *
	 * @param   tileIndex  The requested tile type
	 * @param   midpoint   Whether to use the tiles' midpoints, or upper left corner
	 * @return  An Array with a list of all the coordinates of that tile type
	 * @since 5.9.0
	 */
	public function getAllTilePos(tileIndex:Int, midpoint = false):Array<FlxPoint>
	{
		final result = [];

		final length = _data.length;
		for (mapIndex in 0...length)
		{
			if (getTileIndex(mapIndex) == tileIndex)
			{
				result.push(getTilePos(mapIndex, midpoint));
			}
		}
		return result;
	}

	/**
	 * Gets the collision flags of the tile at the given location
	 *
	 * **Note:** A tile's `mapIndex` can be calculated via `row * widthInTiles + column`
	 *
	 * ##Soft Deprecation
	 * You should use `getTileData(mapIndex).allowCollisions`, instead
	 *
	 * @param   mapIndex  The desired location in the map
	 * @return  The internal collision flag for the requested tile.
	 */
	public function getTileCollisions(mapIndex:Int):FlxDirectionFlags
	{
		return getTileData(mapIndex).allowCollisions;
	}

	/**
	 * Returns a new array full of every map index of the requested tile type.
	 *
	 * **Note:** Unlike `getTileInstances` this will return `[]` if no tiles are found
	 *
	 * @param   index  The requested tile type.
	 * @return  An Array with a list of all map indices of that tile type.
	 * @since 5.9.0
	 */
	public function getAllMapIndices(tileIndex:Int):Array<Int>
	{
		final result:Array<Int> = [];

		final length = _data.length;
		for (mapIndex in 0...length)
		{
			if (getTileIndex(mapIndex) == tileIndex)
			{
				result.push(mapIndex);
			}
		}
		return result;
	}

	/**
	 * Calls the desired function with every `mapIndex` that uses the given `tileIndex`
	 *
	 * @param   tileIndex  The desired tile type
	 * @param   function   The function called with each mapIndex
	 * @since 5.9.0
	 */
	public function forEachMapIndex(tileIndex:Int, f:(mapIndex:Int) -> Void)
	{
		final length = _data.length;
		for (mapIndex in 0...length)
		{
			if (getTileIndex(mapIndex) == tileIndex)
			{
				f(mapIndex);
			}
		}
	}

	/**
	 * Change the data and graphic of a tile in the tilemap.
	 *
	 * @param   mapIndex   The slot in the data array (Y * widthInTiles + X) where this tile is stored.
	 * @param   tileIndex  The new tileIndex to place at the mapIndex
	 * @param   redraw     Whether the graphical representation of this tile should change.
	 * @return  Whether or not the tile was actually changed.
	 * @since 5.9.0
	 */
	public overload extern inline function setTileIndex(mapIndex:Int, tileIndex:Int, redraw = true):Bool
	{
		return setTileHelper(mapIndex, tileIndex, redraw);
	}

	/**
	 * Change the data and graphic of a tile in the tilemap.
	 *
	 * @param   column     The grid X location, in tiles
	 * @param   row        The grid Y location, in tiles
	 * @param   tileIndex  The new integer data you wish to inject.
	 * @param   redraw     Whether the graphical representation of this tile should change.
	 * @return  Whether or not the tile was actually changed.
	 * @since 5.9.0
	 */
	public overload extern inline function setTileIndex(column:Int, row:Int, tileIndex:Int, redraw = true):Bool
	{
		return setTileHelper(getMapIndex(column, row), tileIndex, redraw);
	}

	/**
	 * Change the data and graphic of a tile in the tilemap.
	 *
	 * @param   worldPos   A location in the world
	 * @param   tileIndex  The new integer data you wish to inject.
	 * @param   redraw     Whether the graphical representation of this tile should change.
	 * @return  Whether or not the tile was actually changed.
	 * @since 5.9.0
	 */
	public overload extern inline function setTileIndex(worldPos:FlxPoint, tileIndex:Int, redraw = true):Bool
	{
		return setTileIndexAt(worldPos.x, worldPos.y, tileIndex, redraw);
	}

	/**
	 * Change the data and graphic of a tile in the tilemap.
	 *
	 * @param   worldX     An X coordinate in the world
	 * @param   worldY     A Y coordinate in the world
	 * @param   tileIndex  The new integer data you wish to inject.
	 * @param   redraw     Whether the graphical representation of this tile should change.
	 * @return  Whether or not the tile was actually changed.
	 * @since 5.9.0
	 */
	public inline function setTileIndexAt(worldX:Float, worldY:Float, tileIndex:Int, redraw = true):Bool
	{
		return setTileHelper(getMapIndexAt(worldX, worldY), tileIndex, redraw);
	}

	function setTileHelper(mapIndex:Int, tileIndex:Int, redraw = true):Bool
	{
		if (!tileExists(mapIndex))
			return false;

		_data[mapIndex] = tileIndex;

		if (!redraw)
		{
			return true;
		}

		setDirty();

		switch (auto)
		{
			case OFF:
				updateTile(_data[mapIndex]);
			default:
				updateTileWithAutoTile(mapIndex);
		}

		return true;
	}

	function updateTileWithAutoTile(mapIndex:Int)
	{
		// If this map is auto-tiled and it changes, locally update the arrangement
		var row:Int = getRow(mapIndex) - 1;
		var column:Int = getColumn(mapIndex) - 1;
		final rowLength:Int = row + 3;
		final columnHeight:Int = column + 3;

		while (row < rowLength)
		{
			column = columnHeight - 3;

			while (column < columnHeight)
			{
				if (tileExists(column, row))
				{
					final i = getMapIndex(column, row);
					autoTile(i);
					updateTile(_data[i]);
				}
				column++;
			}
			row++;
		}
	}

	/**
	 * Adjust collision settings and/or bind a callback function to a range of tiles.
	 * This callback function, if present, is triggered by calls to `overlap` or `objectOverlapsTiles`.
	 *
	 * @param   tile             The tile or tiles you want to adjust.
	 * @param   allowCollisions  Modify the tile or tiles to only allow collisions from certain directions, use FlxObject constants NONE, ANY, LEFT, RIGHT, etc. Default is "ANY".
	 * @param   callback         The function to trigger, e.g. lavaCallback(Tile:FlxObject, Object:FlxObject).
	 * @param   callbackFilter   If you only want the callback to go off for certain classes or objects based on a certain class, set that class here.
	 * @param   range            If you want this callback to work for a bunch of different tiles, input the range here. Default value is 1.
	 */
	public function setTileProperties(tile:Int, allowCollisions = ANY, ?callback:FlxObject->FlxObject->Void, ?callbackFilter:Class<FlxObject>, range = 1):Void
	{
		if (range <= 0)
		{
			range = 1;
		}

		final maxIndex = _tileObjects.length;
		final end = tile + range;
		if (maxIndex == 0)
		{
			final rangeDisplay = range == 1 ? 'tile $tile' : 'tiles $tile-${end-1}';
			FlxG.log.error('Cannot setTileProperties of $rangeDisplay when tilemap does not contain any tiles.'
				+ ' This may be due to an invalid graphic.');
			return;
		}

		if (end > maxIndex)
		{
			final rangeDisplay = range == 1 ? 'tile $tile' : 'tiles $tile-${end-1}';
			FlxG.log.error('Cannot setTileProperties of $rangeDisplay when there are only $end tiles.');
			return;
		}

		for (i in tile...end)
		{
			var tileData = _tileObjects[i];
			tileData.allowCollisions = allowCollisions;
			(cast tileData).callbackFunction = callback;
			(cast tileData).filter = callbackFilter;
		}
	}

	/**
	 * Fetches the tilemap data array.
	 *
	 * @param   simple   If true, returns the data as copy, as a series of 1s and 0s (useful for auto-tiling stuff).
	 *                   Default value is false, meaning it will return the actual data array (NOT a copy).
	 * @return  An array the size of the tilemap full of integers indicating tile placement.
	 */
	public function getData(simple:Bool = false):Array<Int>
	{
		if (!simple)
			return _data;

		return
		[
			for (i in 0..._data.length)
				(getTileData(i).solid ? 1 : 0)
		];
	}

	/**
	 * Find a path through the tilemap.  Any tile with any collision flags set is treated as impassable.
	 * If no path is discovered then a null reference is returned.
	 *
	 * @param   start           The start point in world coordinates.
	 * @param   end             The end point in world coordinates.
	 * @param   simplify        Whether to run a basic simplification algorithm over the path data, removing
	 *                          extra points that are on the same line.  Default value is true.
	 * @param   raySimplify     Whether to run an extra raycasting simplification algorithm over the remaining
	 *                          path data.  This can result in some close corners being cut, and should be
	 *                          used with care if at all (yet).  Default value is false.
	 * @param   diagonalPolicy  How to treat diagonal movement. (Default is WIDE, count +1 tile for diagonal movement)
	 * @return  An Array of FlxPoints, containing all waypoints from the start to the end.  If no path could be found,
	 *          then a null reference is returned.
	 */
	public inline function findPath(start:FlxPoint, end:FlxPoint, simplify:FlxPathSimplifier = LINE,
			diagonalPolicy:FlxTilemapDiagonalPolicy = WIDE):Array<FlxPoint>
	{
		return getDiagonalPathfinder(diagonalPolicy).findPath(cast this, start, end, simplify);
	}

	/**
	 * Find a path through the tilemap.  Any tile with any collision flags set is treated as impassable.
	 * If no path is discovered then a null reference is returned.
	 * @since 5.0.0
	 *
	 * @param   pathfinder   Decides how to move and evaluate the paths for comparison.
	 * @param   start        The start point in world coordinates.
	 * @param   end          The end point in world coordinates.
	 * @param   simplify     Whether to run a basic simplification algorithm over the path data, removing
	 *                       extra points that are on the same line.  Default value is true.
	 * @param   raySimplify  Whether to run an extra raycasting simplification algorithm over the remaining
	 *                       path data.  This can result in some close corners being cut, and should be
	 *                       used with care if at all (yet).  Default value is false.
	 * @return  An Array of FlxPoints, containing all waypoints from the start to the end.  If no path could be found,
	 *          then a null reference is returned.
	 */
	public inline function findPathCustom(pathfinder:FlxPathfinder, start:FlxPoint, end:FlxPoint,
		simplify:FlxPathSimplifier = LINE):Array<FlxPoint>
	{
		return pathfinder.findPath(cast this, start, end, simplify);
	}

	/**
	 * Pathfinding helper function, floods a grid with distance information until it finds the end point.
	 * **Note:** Currently this process does NOT use any kind of fancy heuristic! It's pretty brute.
	 *
	 * @param   startIndex      The starting tile's map index.
	 * @param   endIndex        The ending tile's map index.
	 * @param   diagonalPolicy  How to treat diagonal movement.
	 * @param   stopOnEnd       Whether to stop at the end or not (default true)
	 * @return  An array of FlxPoint nodes. If the end tile could not be found, then a null Array is returned instead.
	 */
	public function computePathDistance(startIndex:Int, endIndex:Int, diagonalPolicy:FlxTilemapDiagonalPolicy = WIDE, stopOnEnd:Bool = true):Array<Int>
	{
		var data = computePathData(startIndex, endIndex, diagonalPolicy, stopOnEnd);
		if (data != null)
			return data.distances;

		return null;
	}


	/**
	 * Pathfinding helper function, floods a grid with distance information until it finds the end point.
	 * **Note:** Currently this process does NOT use any kind of fancy heuristic! It's pretty brute.
	 * @since 5.0.0
	 *
	 * @param   startIndex  The starting tile's map index.
	 * @param   endIndex    The ending tile's map index.
	 * @param   policy      Decides how to move and evaluate the paths for comparison.
	 * @param   stopOnEnd   Whether to stop at the end or not (default true)
	 * @return  An array of FlxPoint nodes. If the end tile could not be found, then a null Array is returned instead.
	 */
	public function computePathData(startIndex:Int, endIndex:Int, diagonalPolicy:FlxTilemapDiagonalPolicy = WIDE, stopOnEnd:Bool = true):FlxPathfinderData
	{
		return getDiagonalPathfinder(diagonalPolicy).computePathData(cast this, startIndex, endIndex, stopOnEnd);
	}

	inline function getDiagonalPathfinder(diagonalPolicy:FlxTilemapDiagonalPolicy):FlxPathfinder
	{
		diagonalPathfinder.diagonalPolicy = diagonalPolicy;
		return diagonalPathfinder;
	}

	/**
	 * Checks to see if some FlxObject overlaps this FlxObject object in world space.
	 * If the group has a LOT of things in it, it might be faster to use FlxG.overlaps().
	 * **Warning:** Currently tilemaps do NOT support screen space overlap checks!
	 *
	 * @param   object         The object being tested.
	 * @param   inScreenSpace  Whether to take scroll factors into account when checking for overlap.
	 * @param   camera         Specify which game camera you want. If null, getScreenPosition() will just grab the first global camera.
	 * @return  Whether or not the two objects overlap.
	 */
	@:access(flixel.group.FlxTypedGroup)
	override function overlaps(objectOrGroup:FlxBasic, inScreenSpace = false, ?camera:FlxCamera):Bool
	{
		final group = FlxTypedGroup.resolveGroup(objectOrGroup);
		if (group != null) // if it is a group
			return group.any(tilemapOverlapsCallback.bind(_, 0, 0, inScreenSpace, camera));

		return tilemapOverlapsCallback(objectOrGroup);
	}

	inline function tilemapOverlapsCallback(objectOrGroup:FlxBasic, x = 0.0, y = 0.0, inScreenSpace = false, ?camera:FlxCamera):Bool
	{
		if (objectOrGroup.flixelType == OBJECT || objectOrGroup.flixelType == TILEMAP)
		{
			return objectOverlapsTiles(cast objectOrGroup);
		}
		else
		{
			return overlaps(objectOrGroup, inScreenSpace, camera);
		}
	}

	/**
	 * Checks to see if this FlxObject were located at the given position, would it overlap the FlxObject or FlxGroup?
	 * This is distinct from overlapsPoint(), which just checks that point, rather than taking the object's size into account.
	 * WARNING: Currently tilemaps do NOT support screen space overlap checks!
	 *
	 * @param   x              The X position you want to check.  Pretends this object (the caller, not the parameter) is located here.
	 * @param   y              The Y position you want to check.  Pretends this object (the caller, not the parameter) is located here.
	 * @param   objectOrGroup  The object or group being tested.
	 * @param   inScreenSpace  Whether to take scroll factors into account when checking for overlap.  Default is false, or "only compare in world space."
	 * @param   camera         Specify which game camera you want.  If null getScreenPosition() will just grab the first global camera.
	 * @return  Whether or not the two objects overlap.
	 */
	@:access(flixel.group.FlxTypedGroup)
	override function overlapsAt(x:Float, y:Float, objectOrGroup:FlxBasic, inScreenSpace:Bool = false, ?camera:FlxCamera):Bool
	{
		final group = FlxTypedGroup.resolveGroup(objectOrGroup);
		if (group != null) // if it is a group
			return group.any(tilemapOverlapsAtCallback.bind(_, x, y, inScreenSpace, camera));

		return tilemapOverlapsAtCallback(objectOrGroup, x, y, inScreenSpace, camera);
	}

	inline function tilemapOverlapsAtCallback(objectOrGroup:FlxBasic, x:Float, y:Float, inScreenSpace:Bool, camera:FlxCamera):Bool
	{
		if (objectOrGroup.flixelType == OBJECT || objectOrGroup.flixelType == TILEMAP)
		{
			return objectOverlapsTiles(cast objectOrGroup, null, _point.set(x, y));
		}
		else
		{
			return overlapsAt(x, y, objectOrGroup, inScreenSpace, camera);
		}
	}

	/**
	 * Checks to see if a point in 2D world space overlaps this FlxObject object.
	 *
	 * @param   worldPoint     The point in world space you want to check.
	 * @param   inScreenSpace  Whether to take scroll factors into account when checking for overlap.
	 * @param   camera         The desired "screen" space. If `null`, `getDefaultCamera()` is used
	 * @return  Whether or not the point overlaps this object.
	 */
	override function overlapsPoint(worldPoint:FlxPoint, inScreenSpace = false, ?camera:FlxCamera):Bool
	{
		if (inScreenSpace)
		{
			if (camera == null)
				camera = getDefaultCamera();

			worldPoint.subtract(camera.scroll);
			worldPoint.putWeak();
		}

		return tileAtPointAllowsCollisions(worldPoint);
	}

	function tileAtPointAllowsCollisions(point:FlxPoint):Bool
	{
		final mapIndex = getMapIndex(point);
		return tileExists(mapIndex) && getTileData(mapIndex).solid;
	}

	/**
	 * Get the world coordinates and size of the entire tilemap as a FlxRect.
	 *
	 * @param   bounds  Optional, pass in a pre-existing FlxRect to prevent instantiation of a new object.
	 * @return  A FlxRect containing the world coordinates and size of the entire tilemap.
	 */
	public function getBounds(?bounds:FlxRect):FlxRect
	{
		if (bounds == null)
			bounds = FlxRect.get();

		return bounds.set(x, y, width, height);
	}
}

enum FlxTilemapAutoTiling
{
	OFF;

	/**
	 * Good for levels with thin walls that don't need interior corner art.
	 */
	AUTO;

	/**
	 * Better for levels with thick walls that look better with interior corner art.
	 */
	ALT;

	/**
	 * Better for all, but need 47 tiles.
	 * @since 4.6.0
	 */
	FULL;
}
