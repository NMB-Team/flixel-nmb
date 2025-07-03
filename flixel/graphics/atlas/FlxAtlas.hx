package flixel.graphics.atlas;

import openfl.display.BitmapData;
import openfl.geom.Point;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.util.FlxBitmapDataUtil;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.geom.Matrix;

// TODO: rewrite this class again, since it's a total mess again.
// It needs better resize handling.

/**
 * Class for packing multiple images in big one and generating frame data for each of them
 * so you can easily load regions of atlas in sprites and tilemaps as a source of graphic
 */
class FlxAtlas implements IFlxDestroyable {
	static var point = new Point();
	static var matrix = new Matrix();

	/**
	 * Default minimum size for atlases.
	 */
	public static final defaultMinSize = new FlxPoint(128, 128);

	/**
	 * Default maximum size for atlases.
	 */
	public static final defaultMaxSize = new FlxPoint(1024, 1024);

	/**
	 * Root node of the atlas.
	 */
	public var root(default, null):FlxNode;

	/**
	 * Name of this atlas, used as a key in the bitmap cache.
	 */
	public var name(default, null):String;

	public var nodes(default, null):Map<String, FlxNode>;

	/**
	 * `BitmapData` of this atlas, combines all images into a big one.
	 */
	public var bitmapData(default, set):BitmapData;

	/**
	 * Graphic for this atlas.
	 */
	public var graphic(get, never):FlxGraphic;

	/**
	 * Whether this atlas should stay in memory after state switch.
	 * Default value if `false`.
	 */
	public var persist(default, set) = false;

	/**
	 * Offsets between nodes.
	 */
	public var border(default, null) = 1;

	/**
	 * Total width of the atlas.
	 */
	@:isVar public var width(get, set):Int;

	/**
	 * Total height of the atlas.
	 */
	@:isVar public var height(get, set):Int;

	/**
	 * Minimum width for this atlas.
	 */
	public var minWidth(default, set) = 128;

	/**
	 * Minimum height for this atlas
	 */
	public var minHeight(default, set) = 128;

	/**
	 * Maximum width for this atlas.
	 */
	public var maxWidth(default, set) = 1024;

	/**
	 * Maximum height for this atlas.
	 */
	public var maxHeight(default, set) = 1024;

	/**
	 * Whether to allow image rotation for packing in atlas.
	 */
	public var allowRotation(default, null) = false;

	/**
	 * Whether the size of this atlas should be the power of 2 or not.
	 */
	public var powerOfTwo(default, set) = false;

	var _graphic:FlxGraphic;

	/**
	 * Internal storage for building atlas from queue
	 */
	var _tempStorage:Array<TempAtlasObj>;

	/**
	 * Atlas constructor
	 *
	 * @param   name         The name of this atlas. It will be used for caching `BitmapData` of this atlas.
	 * @param   powerOfTwo   Whether the size of this atlas should be the power of 2 or not.
	 * @param   border       Gap between nodes to insert.
	 * @param   rotate       Whether to rotate added images for less atlas size.
	 * @param   minSize      Min size of atlas.
	 * @param   maxSize      Max size of atlas.
	 */
	public function new(name:String, powerOfTwo = false, border = 1, rotate = false, ?minSize:FlxPoint, ?maxSize:FlxPoint) {
		nodes = new Map<String, FlxNode>();

		this.name = name;
		this.powerOfTwo = powerOfTwo;
		this.border = border;

		minSize = (minSize != null) ? minSize : defaultMinSize;
		maxSize = (maxSize != null) ? maxSize : defaultMaxSize;

		this.minWidth = Std.int(minSize.x);
		this.minHeight = Std.int(minSize.y);
		this.maxWidth = (maxSize.x > minSize.x) ? Std.int(maxSize.x) : minWidth;
		this.maxHeight = (maxSize.y > minSize.x) ? Std.int(maxSize.y) : minHeight;
		this.allowRotation = rotate;

		initRoot();

		FlxG.signals.preStateCreate.add(onClear);
	}

	private function initRoot():Void {
		var rootWidth = minWidth;
		var rootHeight = minHeight;

		if (powerOfTwo) {
			rootWidth = getNextPowerOfTwo(rootWidth);
			rootHeight = getNextPowerOfTwo(rootHeight);
		}

		root = new FlxNode(FlxRect.get(0, 0, rootWidth, rootHeight), this);
	}

	/**
	 * Adds a new node to the atlas.
	 *
	 * @param   Graphic   Image to store. Could be a `BitmapData`, `String`
	 *                    (key from OpenFL's asset cache) or a `Class<Dynamic>`.
	 * @param   Key       Image name, optional.
	 *                    You can omit it if you pass `String` or `Class<Dynamic>` as a `Graphic` source.
	 * @return  Newly created and added node, or `null` if there is no space for it.
	 */
	public function addNode(graphic:FlxGraphicSource, ?key:String):FlxNode {
		final keyTemp = FlxAssets.resolveKey(graphic, key);

		if (keyTemp == null) {
			#if FLX_DEBUG
			FlxG.log.critical("addNode can't find the key for specified BitmapData. Please provide not null value as a Key argument.");
			#end
			return null;
		}

		if (hasNodeWithName(keyTemp)) return nodes.get(keyTemp);

		final data = FlxAssets.resolveBitmapData(graphic);

		if (data == null) {
			#if FLX_DEBUG
			FlxG.log.critical("addNode can't find BitmapData with specified key: " + graphic + ". Please provide valid value.");
			#end
			return null;
		}

		// check if we can add nodes right into root
		if (root.left == null) return insertFirstNodeInRoot(data, keyTemp);
		if (root.right == null) return expand(data, key);

		// try to find enough empty space in atlas
		final inserted = tryInsert(data, key);
		if (inserted != null) return inserted;

		// if there is no empty space we need to wrap existing nodes and add new one on the right...
		wrapRoot();
		return expand(data, key);
	}

	private function wrapRoot():Void {
		final temp:FlxNode = root;
		root = new FlxNode(FlxRect.get(0, 0, temp.width, temp.height), this);
		root.left = temp;
	}

	private function tryInsert(data:BitmapData, key:String):FlxNode {
		var insertWidth = data.width + border;
		var insertHeight = data.height + border;

		var rotateNode = false;
		var nodeToInsert = findNodeToInsert(insertWidth, insertHeight);

		if (allowRotation) {
			final nodeToInsertWithRotation = findNodeToInsert(insertHeight, insertWidth);

			if (nodeToInsertWithRotation != null) {
				final nodeWithRotationArea = nodeToInsertWithRotation.width * nodeToInsertWithRotation.height;

				if (nodeToInsert == null || (nodeToInsert != null && nodeToInsert.width * nodeToInsert.height > nodeWithRotationArea)) {
					nodeToInsert = nodeToInsertWithRotation;
					rotateNode = true;
					final temp = insertWidth;
					insertWidth = insertHeight;
					insertHeight = temp;
				}
			}
		}

		if (nodeToInsert != null) {
			final horizontally = needToDivideHorizontally(nodeToInsert, insertWidth, insertHeight);
			return divideNode(nodeToInsert, insertWidth, insertHeight, horizontally, data, key, rotateNode);
		}

		return null;
	}

	private function needToDivideHorizontally(nodeToDivide:FlxNode, insertWidth:Int, insertHeight:Int):Bool {
		final dw = nodeToDivide.width - insertWidth;
		final dh = nodeToDivide.height - insertHeight;

		return dw > dh; // divide horizontally if true, vertically if false
	}

	private function divideNode(nodeToDivide:FlxNode, insertWidth:Int, insertHeight:Int, divideHorizontally:Bool, ?firstGrandChildData:BitmapData, ?firstGrandChildKey:String, firstGrandChildRotated = false):FlxNode {
		if (nodeToDivide != null) {
			var firstChild:FlxNode = null;
			var secondChild:FlxNode = null;
			var firstGrandChild:FlxNode = null;
			var secondGrandChild:FlxNode = null;
			final firstGrandChildFilled = (firstGrandChildKey != null);

			if (divideHorizontally) { // divide horizontally
				firstChild = new FlxNode(FlxRect.get(nodeToDivide.x, nodeToDivide.y, insertWidth, nodeToDivide.height), this);

				if (nodeToDivide.width - insertWidth > 0)
					secondChild = new FlxNode(FlxRect.get(nodeToDivide.x + insertWidth, nodeToDivide.y, nodeToDivide.width - insertWidth, nodeToDivide.height), this);

				firstGrandChild = new FlxNode(FlxRect.get(firstChild.x, firstChild.y, insertWidth, insertHeight), this, firstGrandChildFilled, firstGrandChildKey, firstGrandChildRotated);

				if (firstChild.height - insertHeight > 0) secondGrandChild = new FlxNode(FlxRect.get(firstChild.x, firstChild.y + insertHeight, insertWidth, firstChild.height - insertHeight), this);
			} else { // divide vertically
				firstChild = new FlxNode(FlxRect.get(nodeToDivide.x, nodeToDivide.y, nodeToDivide.width, insertHeight), this);

				if (nodeToDivide.height - insertHeight > 0)
					secondChild = new FlxNode(FlxRect.get(nodeToDivide.x, nodeToDivide.y + insertHeight, nodeToDivide.width, nodeToDivide.height - insertHeight), this);

				firstGrandChild = new FlxNode(FlxRect.get(firstChild.x, firstChild.y, insertWidth, insertHeight), this, firstGrandChildFilled, firstGrandChildKey, firstGrandChildRotated);

				if (firstChild.width - insertWidth > 0)
					secondGrandChild = new FlxNode(FlxRect.get(firstChild.x + insertWidth, firstChild.y, firstChild.width - insertWidth, insertHeight), this);
			}

			firstChild.left = firstGrandChild;
			firstChild.right = secondGrandChild;

			nodeToDivide.left = firstChild;
			nodeToDivide.right = secondChild;

			// bake data in atlas
			if (firstGrandChildKey != null && firstGrandChildData != null) {
				expandBitmapData();

				if (firstGrandChildRotated) {
					matrix.identity();
					matrix.rotate(Math.PI * .5);
					matrix.translate(firstGrandChildData.height + firstGrandChild.x, firstGrandChild.y);
					bitmapData.draw(firstGrandChildData, matrix);
				} else {
					point.setTo(firstGrandChild.x, firstGrandChild.y);
					bitmapData.copyPixels(firstGrandChildData, firstGrandChildData.rect, point);
				}

				addNodeToAtlasFrames(firstGrandChild);
				nodes.set(firstGrandChildKey, firstGrandChild);
			}

			return firstGrandChild;
		}

		return null;
	}

	private function insertFirstNodeInRoot(data:BitmapData, key:String):FlxNode {
		if (root.left == null) {
			final insertWidth = data.width + border;
			final insertHeight = data.height + border;

			var rootWidth = insertWidth;
			var rootHeight = insertHeight;

			if (powerOfTwo) {
				rootWidth = getNextPowerOfTwo(rootWidth);
				rootHeight = getNextPowerOfTwo(rootHeight);
			}

			rootWidth = (minWidth > rootWidth) ? minWidth : rootWidth;
			rootHeight = (minHeight > rootHeight) ? minHeight : rootHeight;

			if (powerOfTwo) {
				rootWidth = getNextPowerOfTwo(rootWidth);
				rootHeight = getNextPowerOfTwo(rootHeight);
			}

			if ((maxWidth > 0 && rootWidth > maxWidth) || (maxHeight > 0 && rootHeight > maxHeight)) {
				#if FLX_DEBUG
				FlxG.log.critical("Can't insert node " + key + " with the size of (" + data.width + "; " + data.height + ") in atlas " + name + " with the max size of (" + maxWidth + "; " + maxHeight + ") and powerOfTwo: " + powerOfTwo);
				#end
				return null;
			}

			root.width = rootWidth;
			root.height = rootHeight;

			final horizontally = needToDivideHorizontally(root, insertWidth, insertHeight);
			return divideNode(root, insertWidth, insertHeight, horizontally, data, key);
		}

		return null;
	}

	private function expand(data:BitmapData, key:String):FlxNode {
		if (root.right == null) {
			final insertWidth = data.width + border;
			final insertHeight = data.height + border;

			// helpers for making decision on how to insert new node
			var addRightWidth = root.width + insertWidth;
			var addRightHeight = Std.int(Math.max(root.height, insertHeight));

			var addBottomWidth = Std.int(Math.max(root.width, insertWidth));
			var addBottomHeight = root.height + insertHeight;

			var addRightWidthRotate = addRightWidth;
			var addRightHeightRotate = addRightHeight;

			var addBottomWidthRotate = addBottomWidth;
			var addBottomHeightRotate = addBottomHeight;

			if (allowRotation) {
				addRightWidthRotate = root.width + insertHeight;
				addRightHeightRotate = Std.int(Math.max(root.height, insertWidth));

				addBottomWidthRotate = Std.int(Math.max(root.width, insertHeight));
				addBottomHeightRotate = root.height + insertWidth;
			}

			if (powerOfTwo) {
				addRightWidthRotate = addRightWidth = getNextPowerOfTwo(addRightWidth);
				addRightHeightRotate = addRightHeight = getNextPowerOfTwo(addRightHeight);
				addBottomWidthRotate = addBottomWidth = getNextPowerOfTwo(addBottomWidth);
				addBottomHeightRotate = addBottomHeight = getNextPowerOfTwo(addBottomHeight);

				if (allowRotation) {
					addRightWidthRotate = getNextPowerOfTwo(addRightWidthRotate);
					addRightHeightRotate = getNextPowerOfTwo(addRightHeightRotate);
					addBottomWidthRotate = getNextPowerOfTwo(addBottomWidthRotate);
					addBottomHeightRotate = getNextPowerOfTwo(addBottomHeightRotate);
				}
			}

			// checks for the max size
			var canExpandRight = true;
			var canExpandBottom = true;

			var canExpandRightRotate = allowRotation;
			var canExpandBottomRotate = allowRotation;

			if ((maxWidth > 0 && addRightWidth > maxWidth) || (maxHeight > 0 && addRightHeight > maxHeight))
				canExpandRight = false;

			if ((maxWidth > 0 && addBottomWidth > maxWidth) || (maxHeight > 0 && addBottomHeight > maxHeight))
				canExpandBottom = false;

			if ((maxWidth > 0 && addRightWidthRotate > maxWidth) || (maxHeight > 0 && addRightHeightRotate > maxHeight))
				canExpandRightRotate = false;

			if ((maxWidth > 0 && addBottomWidthRotate > maxWidth) || (maxHeight > 0 && addBottomHeightRotate > maxHeight))
				canExpandBottomRotate = false;

			if (!canExpandRight && !canExpandBottom && !canExpandRightRotate && !canExpandBottomRotate) {
				#if FLX_DEBUG
				FlxG.log.critical("Can't insert node " + key + " with the size of (" + data.width + "; " + data.height + ") in atlas " + name
					+ " with the max size of (" + maxWidth + "; " + maxHeight + ") and powerOfTwo: " + powerOfTwo);
				#end
				return null; // can't expand in any direction
			}

			// calculate area of result atlas for various cases
			// the case with less area will be chosen
			var addRightArea = addRightWidth * addRightHeight;
			var addBottomArea = addBottomWidth * addBottomHeight;

			final addRightAreaRotate = addRightWidthRotate * addRightHeightRotate;
			final addBottomAreaRotate = addBottomWidthRotate * addBottomHeightRotate;

			var rotateRight = false;
			var rotateBottom = false;
			var rotateNode = false;

			if ((canExpandRight && canExpandRightRotate && addRightArea > addRightAreaRotate) || (!canExpandRight && canExpandRightRotate)) {
				addRightArea = addBottomAreaRotate;
				addRightWidth = addRightWidthRotate;
				addRightHeight = addRightHeightRotate;
				canExpandRight = rotateRight = true;
			}

			if ((canExpandBottom && canExpandBottomRotate && addBottomArea > addBottomAreaRotate) || (!canExpandBottom && canExpandBottomRotate)) {
				addBottomArea = addBottomAreaRotate;
				addBottomWidth = addBottomWidthRotate;
				addBottomHeight = addBottomHeightRotate;
				canExpandBottom = rotateBottom = true;
			}

			if (!canExpandRight && canExpandBottom) {
				addRightArea = addBottomArea + 1; // can't expand to the right
				rotateNode = rotateRight;
			} else if (canExpandRight && !canExpandBottom) {
				addBottomArea = addRightArea + 1; // can't expand to the bottom
				rotateNode = rotateBottom;
			}

			var dataNode:FlxNode = null;
			final temp:FlxNode = root;
			var insertNodeWidth = insertWidth;
			var insertNodeHeight = insertHeight;

			// decide how to insert new node
			if (addBottomArea >= addRightArea) { // add node to the right
				if (rotateRight) {
					insertNodeWidth = insertHeight;
					insertNodeHeight = insertWidth;
				}

				expandRoot(temp.width + insertNodeWidth, Math.max(temp.height, insertNodeHeight), true);
				dataNode = divideNode(root.right, insertNodeWidth, insertNodeHeight, true, data, key, rotateRight);
				expandRoot(addRightWidth, addRightHeight, false, true);
			} else { // add node at the bottom
				if (rotateBottom) {
					insertNodeWidth = insertHeight;
					insertNodeHeight = insertWidth;
				}

				expandRoot(Math.max(temp.width, insertNodeWidth), temp.height + insertNodeHeight, false);
				dataNode = divideNode(root.right, insertNodeWidth, insertNodeHeight, true, data, key, rotateBottom);
				expandRoot(addBottomWidth, addBottomHeight, false, true);
			}

			return dataNode;
		}

		return null;
	}

	private function expandRoot(newWidth:Float, newHeight:Float, divideHorizontally:Bool, decideHowToDivide = false):Void {
		if (newWidth > root.width || newHeight > root.height) {
			final temp:FlxNode = root;
			root = new FlxNode(FlxRect.get(0, 0, newWidth, newHeight), this);

			divideHorizontally = decideHowToDivide ? needToDivideHorizontally(root, temp.width, temp.height) : divideHorizontally;

			divideNode(root, temp.width, temp.height, divideHorizontally);
			root.left.left = temp;
		}
	}

	private function expandBitmapData():Void {
		if (bitmapData != null && bitmapData.width == root.width && bitmapData.height == root.height) return;

		final newBitmapData = new BitmapData(root.width, root.height, true, FlxColor.TRANSPARENT);
		if (bitmapData != null) {
			point.setTo(0, 0);
			newBitmapData.copyPixels(bitmapData, bitmapData.rect, point);
		}

		bitmapData = FlxDestroyUtil.dispose(bitmapData);
		bitmapData = newBitmapData;
	}

	private function getNextPowerOfTwo(number:Float):Int {
		final n = Std.int(number);
		if (n > 0 && (n & (n - 1)) == 0) return n; // see: https://goo.gl/D9kPj

		var result = 1;
		while (result < n) result <<= 1;
		return result;
	}

	/**
	 * Generates a new `BitmapData` with spaces between tiles, adds this `BitmapData` to this atlas,
	 * generates a `FlxTileFrames` object for the added node and returns it. Can be useful for tilemaps.
	 *
	 * @param   graphic        Source image for node, where spaces will be inserted
	 *                        (could be a `BitmapData`, `String` or `Class<Dynamic>`).
	 * @param   key           Optional key for image
	 * @param   tileSize      The size of tile in spritesheet
	 * @param   tileSpacing   Offsets to add in spritesheet between tiles
	 * @param   tileBorder    Border to add around tiles (helps to avoid "tearing" problem)
	 * @param   region        Region of source image to use as a source graphic
	 * @return  Generated `FlxTileFrames` for the added node
	 */
	public function addNodeWithSpacesAndBorders(graphic:FlxGraphicSource, ?key:String, tileSize:FlxPoint, tileSpacing:FlxPoint, ?tileBorder:FlxPoint, ?region:FlxRect):FlxTileFrames {
		var keyTemp = FlxAssets.resolveKey(graphic, key);

		if (keyTemp == null) {
			#if FLX_DEBUG
			FlxG.log.critical("addNodeWithSpacings can't find the key for specified BitmapData." + " Please provide not null value as a Key argument.");
			#end
			return null;
		}

		keyTemp = FlxG.bitmap.getKeyWithSpacesAndBorders(keyTemp, tileSize, tileSpacing, tileBorder, region);

		if (hasNodeWithName(keyTemp)) return nodes.get(keyTemp).getTileFrames(tileSize, tileSpacing, tileBorder);

		final data = FlxAssets.resolveBitmapData(graphic);
		if (data == null) {
			#if FLX_DEBUG
			FlxG.log.critical("addNodeWithSpacings can't find BitmapData with specified key: " + graphic + ". Please provide valid value.");
			#end
			return null;
		}

		final nodeData = FlxBitmapDataUtil.addSpacesAndBorders(data, tileSize, tileSpacing, tileBorder, region);
		final node = addNode(nodeData, keyTemp);

		if (node == null) {
			#if FLX_DEBUG
			FlxG.log.critical("addNodeWithSpacings can't insert provided image: " + graphic + ") in atlas. It's probably too big.");
			#end
			return null;
		}

		if (tileBorder != null) tileSize.add(2 * tileBorder.x, 2 * tileBorder.y);

		return node.getTileFrames(tileSize, tileSpacing, tileBorder);
	}

	/**
	 * Gets the `FlxAtlasFrames` object for this atlas.
	 * It caches graphic of this atlas and generates `FlxAtlasFrames` if it doesn't exist yet.
	 *
	 * @return `FlxAtlasFrames` for this atlas
	 */
	public function getAtlasFrames():FlxAtlasFrames {
		final graph:FlxGraphic = this.graphic;

		var atlasFrames:FlxAtlasFrames = graph.atlasFrames;
		atlasFrames ??= new FlxAtlasFrames(graph);

		for (node in nodes) addNodeToAtlasFrames(node);

		return atlasFrames;
	}

	private function addNodeToAtlasFrames(node:FlxNode):Void {
		if (_graphic == null || _graphic.atlasFrames == null || node == null) return;

		final atlasFrames:FlxAtlasFrames = _graphic.atlasFrames;

		if (node.filled && !atlasFrames.exists(node.key)) {
			final frame = FlxRect.get(node.x, node.y, node.width - border, node.height - border);
			final sourceSize = node.rotated ? FlxPoint.get(node.height - border, node.width - border) : FlxPoint.get(node.width - border, node.height - border);
			final offset = FlxPoint.get(0, 0);
			final angle:FlxFrameAngle = node.rotated ? FlxFrameAngle.ANGLE_NEG_90 : FlxFrameAngle.ANGLE_0;
			atlasFrames.addAtlasFrame(frame, sourceSize, offset, node.key, angle);
		}
	}

	/**
	 * Checks if the atlas already contains node with the same name.
	 *
	 * @param   nodeName   Node name to check.
	 * @return  `true` if atlas already contains node with the name.
	 */
	public function hasNodeWithName(nodeName:String):Bool {
		return nodes.exists(nodeName);
	}

	/**
	 * Gets a node by it's name.
	 *
	 * @param   key   Node name to search for.
	 * @return  node with searched name. `null` if atlas doesn't contain any node with that name.
	 */
	public function getNode(key:String):FlxNode {
		return nodes.get(key);
	}

	/**
	 * Optimized version of method for adding multiple nodes to atlas.
	 * Uses less of the atlas' area (it sorts images by the size before adding them to atlas).
	 *
	 * @param   bitmaps   `BitmapData`'s to insert
	 * @param   keys      Names of these `BitmapData` objects.
	 * @return  `this` `FlxAtlas`
	 */
	public function addNodes(bitmaps:Array<BitmapData>, keys:Array<String>):FlxAtlas {
		final numKeys = keys.length;
		final numBitmaps = bitmaps.length;

		if (numBitmaps != numKeys) {
			#if FLX_DEBUG
			FlxG.log.critical("The number of bitmaps (" + numBitmaps + ") should be equal to number of keys (" + numKeys + ")");
			#end
			return null;
		}

		_tempStorage = new Array<TempAtlasObj>();
		for (i in 0...numBitmaps) _tempStorage.push({bmd: bitmaps[i], keyStr: keys[i]});

		addFromAtlasObjects(_tempStorage);
		return this;
	}

	private function addFromAtlasObjects(objects:Array<TempAtlasObj>):Void {
		objects.sort(bitmapSorter);

		final numBitmaps = objects.length;
		for (i in 0...numBitmaps) addNode(objects[i].bmd, objects[i].keyStr);

		_tempStorage = null;
	}

	/**
	 * Internal method for sorting bitmaps
	 */
	private function bitmapSorter(obj1:TempAtlasObj, obj2:TempAtlasObj):Int {
		if (allowRotation) {
			final area1 = obj1.bmd.width * obj1.bmd.height;
			final area2 = obj2.bmd.width * obj2.bmd.height;
			return area2 - area1;
		}

		if (obj2.bmd.width == obj1.bmd.width) return obj2.bmd.height - obj1.bmd.height;

		return obj2.bmd.width - obj1.bmd.width;
	}

	/**
	 * Creates a new "queue" for adding new nodes.
	 * This method should be used with the `addToQueue()` and `generateFromQueue()` methods:
	 * - first, you create queue, like `atlas.createQueue()`;
	 * - second, you add several bitmaps to the queue: `atlas.addToQueue(bmd1, "key1").addToQueue(bmd2, "key2");`
	 * - third, you actually bake those bitmaps onto the atlas: `atlas.generateFromQueue();`
	 */
	public function createQueue():FlxAtlas {
		_tempStorage = new Array<TempAtlasObj>();
		return this;
	}

	/**
	 * Adds new object to queue for later creation of new node
	 *
	 * @param   data   `BitmapData` to bake on atlas
	 * @param   key    "name" of the `BitmapData`. You'll use it as a key for accessing the created node.
	 */
	public function addToQueue(data:BitmapData, key:String):FlxAtlas { 
		_tempStorage ??= new Array<TempAtlasObj>();
		_tempStorage.push({bmd: data, keyStr: key});
		return this;
	}

	/**
	 * Adds all objects in "queue" to existing atlas. Doesn't remove any nodes.
	 */
	public function generateFromQueue():FlxAtlas {
		if (_tempStorage != null) addFromAtlasObjects(_tempStorage);

		return this;
	}

	private function onClear(_):Void {
		if (!persist && _graphic != null && _graphic.useCount <= 0) destroy();
	}

	/**
	 * Destroys the atlas. Use only if you want to clear memory and don't need this atlas anymore,
	 * since it disposes the `BitmapData` and removes it from the cache.
	 */
	public function destroy():Void {
		_tempStorage = null;
		deleteSubtree(root);
		root = null;
		FlxG.bitmap.removeByKey(name);
		bitmapData = null;
		nodes = null;
		_graphic = null;

		FlxG.signals.preStateCreate.remove(onClear);
	}

	/**
	 * Clears all data in atlas. Use it when you want reuse this atlas.
	 * WARNING: it will destroy the graphic of this image, so you can get
	 * null pointer exceptions if you're still using it for your sprites.
	 */
	public function clear():Void {
		deleteSubtree(root);
		initRoot();
		FlxG.bitmap.removeByKey(name);
		bitmapData = null;
		nodes = new Map<String, FlxNode>();
		_graphic = null;
	}

	/**
	 * Returns atlas data in LibGdx packer format.
	 */
	public function getLibGdxData():String {
		var data = "\n";
		data += name + "\n";
		data += "format: RGBA8888\n";
		data += "filter: Linear,Linear\n";
		data += "repeat: none\n";

		for (node in nodes) {
			data += node.key + "\n";
			data += "  rotate: " + node.rotated + "\n";
			data += "  xy: " + node.x + ", " + node.y + "\n";

			if (allowRotation) {
				data += "size: " + node.height + ", " + node.width + "\n";
				data += "orig: " + node.height + ", " + node.width + "\n";
			} else {
				data += "size: " + node.width + ", " + node.height + "\n";
				data += "orig: " + node.width + ", " + node.height + "\n";
			}

			data += "  offset: 0, 0\n";
			data += "  index: -1\n";
		}

		return data;
	}

	private function deleteSubtree(node:FlxNode):Void {
		if (node != null) {
			if (node.left != null) deleteSubtree(node.left);
			if (node.right != null) deleteSubtree(node.right);
			node.destroy();
		}
	}

	// Internal iteration method
	private function findNodeToInsert(insertWidth:Int, insertHeight:Int):FlxNode {
		// Node stack
		final stack = new Array<FlxNode>();
		// Current node
		var current:FlxNode = root;

		var emptyNodes = new Array<FlxNode>();

		var canPlaceRight = false;
		var canPlaceLeft = false;

		var looping = true;

		var result:FlxNode = null;
		var minArea = maxWidth * maxHeight + 1;
		var nodeArea:Int;

		// Main loop
		while (looping) {
			// Look into current node
			if (current.isEmpty && current.canPlace(insertWidth, insertHeight)) {
				nodeArea = current.width * current.height;

				if (nodeArea < minArea) {
					minArea = nodeArea;
					result = current;
				}
			}
			// Move to next node
			canPlaceRight = (current.right != null && current.right.canPlace(insertWidth, insertHeight));
			canPlaceLeft = (current.left != null && current.left.canPlace(insertWidth, insertHeight));
			if (canPlaceRight && canPlaceLeft) {
				stack.push(current.right);
				current = current.left;
			} else if (canPlaceLeft) current = current.left;
			else if (canPlaceRight) current = current.right;
			else {
				if (stack.length > 0) current = stack.pop(); // Trying to get next node from the stack
				else looping = false; // Stack is empty. End of loop
			}
		}

		return result;
	}

	private function set_bitmapData(value:BitmapData):BitmapData {
		// update graphic bitmapData
		if (value != null && _graphic != null) _graphic.bitmap = value;
		return bitmapData = value;
	}

	private function get_graphic():FlxGraphic {
		if (_graphic != null) return _graphic;

		_graphic = FlxG.bitmap.add(bitmapData, false, name);
		_graphic.persist = persist;

		return _graphic;
	}

	private function set_persist(value:Bool):Bool {
		if (_graphic != null) _graphic.persist = value;
		return persist = value;
	}

	private function set_minWidth(value:Int):Int {
		if (value <= maxWidth) {
			minWidth = value;
			if (value > width) width = value;
		}

		return minWidth;
	}

	private function set_minHeight(value:Int):Int {
		if (value <= maxHeight) {
			minHeight = value;
			if (value > height) height = value;
		}

		return minHeight;
	}

	private function get_width():Int {
		if (root != null) return root.width;
		return 0;
	}

	private function set_width(value:Int):Int {
		if (value > get_width()) {
			if (powerOfTwo) value = getNextPowerOfTwo(value);

			if (value <= maxWidth && root != null && root.width < value)
				expandRoot(value, root.height, needToDivideHorizontally(root, root.width, root.height));
		}

		return value;
	}

	private function get_height():Int {
		if (root != null) return root.height;
		return 0;
	}

	private function set_height(value:Int):Int {
		if (value > get_height()) {
			if (powerOfTwo) value = getNextPowerOfTwo(value);

			if (value <= maxHeight && (root != null && root.height < value))
				expandRoot(root.width, value, needToDivideHorizontally(root, root.width, root.height));
		}

		return value;
	}

	private function set_maxWidth(value:Int):Int {
		if (value >= minWidth && (root == null || value >= width)) maxWidth = value;
		return maxWidth;
	}

	private function set_maxHeight(value:Int):Int {
		if (value >= minHeight && (root == null || value >= height)) maxHeight = value;
		return maxHeight;
	}

	private function set_powerOfTwo(value:Bool):Bool {
		if (value != powerOfTwo && value && root != null) {
			final nextWidth = getNextPowerOfTwo(root.width);
			final nextHeight = getNextPowerOfTwo(root.height);

			if (nextWidth != root.width || nextHeight != root.height) { // need to resize atlas
				if ((maxWidth > 0 && nextWidth > maxWidth) || (maxHeight > 0 && nextHeight > maxHeight)) {
					#if FLX_DEBUG
					FlxG.log.critical("Can't set powerOfTwo property to true," + " since it requires to increase atlas size which is bigger that max size");
					#end
					return false;
				}

				final temp:FlxNode = root;
				root = new FlxNode(FlxRect.get(0, 0, nextWidth, nextHeight), this);

				if (temp.left != null) { // this means that atlas isn't empty and we need to resize it's BitmapData
					divideNode(root, temp.width, temp.height, needToDivideHorizontally(root, temp.width, temp.height));
					root.left.left = temp;
				}
			}
		}

		return powerOfTwo = value;
	}
}

private typedef TempAtlasObj = {
	public var bmd:BitmapData;
	public var keyStr:String;
}
