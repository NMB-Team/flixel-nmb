package flixel.system;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;

/**
 * A fairly generic quad tree structure for rapid overlap checks.
 * FlxQuadTree is also configured for single or dual list operation.
 * You can add items either to its A list or its B list.
 * When you do an overlap check, you can compare the A list to itself,
 * or the A list against the B list.  Handy for different things!
 */
class FlxQuadTree extends FlxRect {
	/**
	 * Flag for specifying that you want to add an object to the A list.
	 */
	public static inline final A_LIST = 0;

	/**
	 * Flag for specifying that you want to add an object to the B list.
	 */
	public static inline final B_LIST = 1;

	/**
	 * Controls the granularity of the quad tree.  Default is 6 (decent performance on large and small worlds).
	 */
	public static var divisions:Int;

	public var exists:Bool;

	/**
	 * Whether this branch of the tree can be subdivided or not.
	 */
	var _canSubdivide:Bool;

	/**
	 * Refers to the internal A and B linked lists,
	 * which are used to store objects in the leaves.
	 */
	var _headA:FlxLinkedList;

	/**
	 * Refers to the internal A and B linked lists,
	 * which are used to store objects in the leaves.
	 */
	var _tailA:FlxLinkedList;

	/**
	 * Refers to the internal A and B linked lists,
	 * which are used to store objects in the leaves.
	 */
	var _headB:FlxLinkedList;

	/**
	 * Refers to the internal A and B linked lists,
	 * which are used to store objects in the leaves.
	 */
	var _tailB:FlxLinkedList;

	/**
	 * Internal, governs and assists with the formation of the tree.
	 */
	static var _min:Int;

	/**
	 * Internal, governs and assists with the formation of the tree.
	 */
	var _northWestTree:FlxQuadTree;

	/**
	 * Internal, governs and assists with the formation of the tree.
	 */
	var _northEastTree:FlxQuadTree;

	/**
	 * Internal, governs and assists with the formation of the tree.
	 */
	var _southEastTree:FlxQuadTree;

	/**
	 * Internal, governs and assists with the formation of the tree.
	 */
	var _southWestTree:FlxQuadTree;

	/**
	 * Internal, governs and assists with the formation of the tree.
	 */
	var _leftEdge:Float;

	/**
	 * Internal, governs and assists with the formation of the tree.
	 */
	var _rightEdge:Float;

	/**
	 * Internal, governs and assists with the formation of the tree.
	 */
	var _topEdge:Float;

	/**
	 * Internal, governs and assists with the formation of the tree.
	 */
	var _bottomEdge:Float;

	/**
	 * Internal, governs and assists with the formation of the tree.
	 */
	var _halfWidth:Float;

	/**
	 * Internal, governs and assists with the formation of the tree.
	 */
	var _halfHeight:Float;

	/**
	 * Internal, governs and assists with the formation of the tree.
	 */
	var _midpointX:Float;

	/**
	 * Internal, governs and assists with the formation of the tree.
	 */
	var _midpointY:Float;

	/**
	 * Internal, used to reduce recursive method parameters during object placement and tree formation.
	 */
	static var _object:FlxObject;

	/**
	 * Internal, used to reduce recursive method parameters during object placement and tree formation.
	 */
	static var _objectLeftEdge:Float;

	/**
	 * Internal, used to reduce recursive method parameters during object placement and tree formation.
	 */
	static var _objectTopEdge:Float;

	/**
	 * Internal, used to reduce recursive method parameters during object placement and tree formation.
	 */
	static var _objectRightEdge:Float;

	/**
	 * Internal, used to reduce recursive method parameters during object placement and tree formation.
	 */
	static var _objectBottomEdge:Float;

	/**
	 * Internal, used during tree processing and overlap checks.
	 */
	static var _list:Int;

	/**
	 * Internal, used during tree processing and overlap checks.
	 */
	static var _useBothLists:Bool;

	/**
	 * Internal, used during tree processing and overlap checks.
	 */
	static var _processingCallback:FlxObject -> FlxObject -> Bool;

	/**
	 * Internal, used during tree processing and overlap checks.
	 */
	static var _notifyCallback:FlxObject -> FlxObject -> Void;

	/**
	 * Internal, used during tree processing and overlap checks.
	 */
	static var _iterator:FlxLinkedList;

	/**
	 * Internal, helpers for comparing actual object-to-object overlap - see overlapNode().
	 */
	static var _objectHullX:Float;

	/**
	 * Internal, helpers for comparing actual object-to-object overlap - see overlapNode().
	 */
	static var _objectHullY:Float;

	/**
	 * Internal, helpers for comparing actual object-to-object overlap - see overlapNode().
	 */
	static var _objectHullWidth:Float;

	/**
	 * Internal, helpers for comparing actual object-to-object overlap - see overlapNode().
	 */
	static var _objectHullHeight:Float;

	/**
	 * Internal, helpers for comparing actual object-to-object overlap - see overlapNode().
	 */
	static var _checkObjectHullX:Float;

	/**
	 * Internal, helpers for comparing actual object-to-object overlap - see overlapNode().
	 */
	static var _checkObjectHullY:Float;

	/**
	 * Internal, helpers for comparing actual object-to-object overlap - see overlapNode().
	 */
	static var _checkObjectHullWidth:Float;

	/**
	 * Internal, helpers for comparing actual object-to-object overlap - see overlapNode().
	 */
	static var _checkObjectHullHeight:Float;

	/**
	 * Pooling mechanism, turn FlxQuadTree into a linked list, when FlxQuadTrees are destroyed, they get added to the list, and when they get recycled they get removed.
	 */
	public static var _NUM_CACHED_QUAD_TREES = 0;

	static var _cachedTreesHead:FlxQuadTree;

	var next:FlxQuadTree;

	/**
	 * Private, use recycle instead.
	 */
	private function new(x:Float, y:Float, width:Float, height:Float, ?parent:FlxQuadTree) {
		super();
		set(x, y, width, height);
		reset(x, y, width, height, parent);
	}

	/**
	 * Recycle a cached Quad Tree node, or creates a new one if needed.
	 * @param	x			The X-coordinate of the point in space.
	 * @param	y			The Y-coordinate of the point in space.
	 * @param	width		Desired width of this node.
	 * @param	height		Desired height of this node.
	 * @param	parent		The parent branch or node.  Pass null to create a root.
	 */
	public static function recycle(x:Float, y:Float, width:Float, height:Float, ?parent:FlxQuadTree):FlxQuadTree {
		if (_cachedTreesHead != null) {
			final cachedTree = _cachedTreesHead;
			_cachedTreesHead = _cachedTreesHead.next;
			_NUM_CACHED_QUAD_TREES--;

			cachedTree.reset(x, y, width, height, parent);
			return cachedTree;
		} else
			return new FlxQuadTree(x, y, width, height, parent);
	}

	/**
	 * Clear cached Quad Tree nodes. You might want to do this when loading new levels (probably not though, no need to clear cache unless you run into memory problems).
	 */
	public static function clearCache():Void {
		// null out next pointers to help out garbage collector
		while (_cachedTreesHead != null) {
			final node = _cachedTreesHead;
			_cachedTreesHead = _cachedTreesHead.next;
			node.next = null;
		}

		_NUM_CACHED_QUAD_TREES = 0;
	}

	public function reset(x:Float, y:Float, width:Float, height:Float, ?parent:FlxQuadTree):Void {
		exists = true;

		set(x, y, width, height);

		_headA = _tailA = FlxLinkedList.recycle();
		_headB = _tailB = FlxLinkedList.recycle();

		// Copy the parent's children (if there are any)
		if (parent != null) {
			var iterator:FlxLinkedList;
			var ot:FlxLinkedList;
			if (parent._headA.object != null) {
				iterator = parent._headA;
				while (iterator != null) {
					if (_tailA.object != null) {
						ot = _tailA;
						_tailA = FlxLinkedList.recycle();
						ot.next = _tailA;
					}

					_tailA.object = iterator.object;
					iterator = iterator.next;
				}
			}

			if (parent._headB.object != null) {
				iterator = parent._headB;
				while (iterator != null) {
					if (_tailB.object != null) {
						ot = _tailB;
						_tailB = FlxLinkedList.recycle();
						ot.next = _tailB;
					}

					_tailB.object = iterator.object;
					iterator = iterator.next;
				}
			}
		} else
			_min = Math.floor((this.width + this.height) / (2 * divisions));

		_canSubdivide = (this.width > _min) || (this.height > _min);

		// Set up comparison/sort helpers
		_northWestTree = null;
		_northEastTree = null;
		_southEastTree = null;
		_southWestTree = null;
		_leftEdge = this.x;
		_rightEdge = this.x + this.width;
		_halfWidth = this.width * .5;
		_midpointX = _leftEdge + _halfWidth;
		_topEdge = this.y;
		_bottomEdge = this.y + this.height;
		_halfHeight = this.height * .5;
		_midpointY = _topEdge + _halfHeight;
	}

	/**
	 * Clean up memory.
	 */
	override public function destroy():Void {
		_headA = FlxDestroyUtil.destroy(_headA);
		_headB = FlxDestroyUtil.destroy(_headB);

		_tailA = FlxDestroyUtil.destroy(_tailA);
		_tailB = FlxDestroyUtil.destroy(_tailB);

		_northWestTree = FlxDestroyUtil.destroy(_northWestTree);
		_northEastTree = FlxDestroyUtil.destroy(_northEastTree);

		_southWestTree = FlxDestroyUtil.destroy(_southWestTree);
		_southEastTree = FlxDestroyUtil.destroy(_southEastTree);

		_object = null;
		_processingCallback = null;
		_notifyCallback = null;

		exists = false;

		// Deposit this tree into the linked list for reusal.
		next = _cachedTreesHead;
		_cachedTreesHead = this;
		_NUM_CACHED_QUAD_TREES++;

		super.destroy();
	}

	/**
	 * Load objects and/or groups into the quad tree, and register notify and processing callbacks.
	 * @param ObjectOrGroup1	Any object that is or extends FlxObject or FlxGroup.
	 * @param ObjectOrGroup2	Any object that is or extends FlxObject or FlxGroup.  If null, the first parameter will be checked against itself.
	 * @param NotifyCallback	A function with the form myFunction(Object1:FlxObject,Object2:FlxObject):void that is called whenever two objects are found to overlap in world space, and either no ProcessCallback is specified, or the ProcessCallback returns true.
	 * @param ProcessCallback	A function with the form myFunction(Object1:FlxObject,Object2:FlxObject):Boolean that is called whenever two objects are found to overlap in world space.  The NotifyCallback is only called if this function returns true.  See FlxObject.separate().
	 */
	public function load(objectOrGroup1:FlxBasic, ?objectOrGroup2:FlxBasic, ?notifyCallback:FlxObject -> FlxObject -> Void, ?processCallback:FlxObject -> FlxObject -> Bool):Void {
		add(objectOrGroup1, A_LIST);
		if (objectOrGroup2 != null) {
			add(objectOrGroup2, B_LIST);
			_useBothLists = true;
		} else
			_useBothLists = false;

		_notifyCallback = notifyCallback;
		_processingCallback = processCallback;
	}

	/**
	 * Call this function to add an object to the root of the tree.
	 * This function will recursively add all group members, but
	 * not the groups themselves.
	 * @param	ObjectOrGroup	FlxObjects are just added, FlxGroups are recursed and their applicable members added accordingly.
	 * @param	List			A int flag indicating the list to which you want to add the objects.  Options are A_LIST and B_LIST.
	 */
	@:access(flixel.group.FlxTypedGroup.resolveGroup)
	public function add(objectOrGroup:FlxBasic, list:Int):Void {
		_list = list;

		var group = FlxTypedGroup.resolveGroup(objectOrGroup);
		if (group != null) {
			var i = 0;
			var basic:FlxBasic;
			final members:Array<FlxBasic> = group.members;
			final l = group.length;
			while (i < l) {
				basic = members[i++];
				if (basic != null && basic.exists) {
					group = FlxTypedGroup.resolveGroup(basic);
					if (group != null) {
						_object = cast basic;
						if (_object.exists && _object.allowCollisions != NONE) {
							_objectLeftEdge = _object.x;
							_objectTopEdge = _object.y;
							_objectRightEdge = _object.x + _object.width;
							_objectBottomEdge = _object.y + _object.height;
							addObject();
						}
					} else
						add(group, list);
				}
			}
		} else {
			_object = cast objectOrGroup;

			if (_object.exists && _object.allowCollisions != NONE) {
				_objectLeftEdge = _object.x;
				_objectTopEdge = _object.y;
				_objectRightEdge = _object.x + _object.width;
				_objectBottomEdge = _object.y + _object.height;
				addObject();
			}
		}
	}

	/**
	 * Internal function for recursively navigating and creating the tree
	 * while adding objects to the appropriate nodes.
	 */
	private function addObject():Void {
		// If this quad (not its children) lies entirely inside this object, add it here
		if (!_canSubdivide || (_leftEdge >= _objectLeftEdge && _rightEdge <= _objectRightEdge && _topEdge >= _objectTopEdge && _bottomEdge <= _objectBottomEdge)) {
			addToList();
			return;
		}

		// See if the selected object fits completely inside any of the quadrants
		if ((_objectLeftEdge > _leftEdge) && (_objectRightEdge < _midpointX)) {
			if ((_objectTopEdge > _topEdge) && (_objectBottomEdge < _midpointY)) {
				_northWestTree ??= FlxQuadTree.recycle(_leftEdge, _topEdge, _halfWidth, _halfHeight, this);
				_northWestTree.addObject();
				return;
			}

			if ((_objectTopEdge > _midpointY) && (_objectBottomEdge < _bottomEdge)) {
				_southWestTree ??= FlxQuadTree.recycle(_leftEdge, _midpointY, _halfWidth, _halfHeight, this);
				_southWestTree.addObject();
				return;
			}
		}

		if ((_objectLeftEdge > _midpointX) && (_objectRightEdge < _rightEdge)) {
			if ((_objectTopEdge > _topEdge) && (_objectBottomEdge < _midpointY)) {
				_northEastTree ??= FlxQuadTree.recycle(_midpointX, _topEdge, _halfWidth, _halfHeight, this);
				_northEastTree.addObject();
				return;
			}

			if ((_objectTopEdge > _midpointY) && (_objectBottomEdge < _bottomEdge)) {
				_southEastTree ??= FlxQuadTree.recycle(_midpointX, _midpointY, _halfWidth, _halfHeight, this);
				_southEastTree.addObject();
				return;
			}
		}

		// If it wasn't completely contained we have to check out the partial overlaps
		final trees = [
			{condition: _objectRightEdge > _leftEdge && _objectLeftEdge < _midpointX && _objectBottomEdge > _topEdge && _objectTopEdge < _midpointY, tree: _northWestTree, x: _leftEdge, y: _topEdge},
			{condition: _objectRightEdge > _midpointX && _objectLeftEdge < _rightEdge && _objectBottomEdge > _topEdge && _objectTopEdge < _midpointY, tree: _northEastTree, x: _midpointX, y: _topEdge},
			{condition: _objectRightEdge > _midpointX && _objectLeftEdge < _rightEdge && _objectBottomEdge > _midpointY && _objectTopEdge < _bottomEdge, tree: _southEastTree, x: _midpointX, y: _midpointY},
			{condition: _objectRightEdge > _leftEdge && _objectLeftEdge < _midpointX && _objectBottomEdge > _midpointY && _objectTopEdge < _bottomEdge, tree: _southWestTree, x: _leftEdge, y: _midpointY}
		];
		
		for (treeData in trees)
			if (treeData.condition) {
				treeData.tree ??= FlxQuadTree.recycle(treeData.x, treeData.y, _halfWidth, _halfHeight, this);
				treeData.tree.addObject();
			}
	}

	/**
	 * Internal function for recursively adding objects to leaf lists.
	 */
	private function addToList():Void {
		var ot:FlxLinkedList;
		if (_list == A_LIST) {
			if (_tailA.object != null) {
				ot = _tailA;
				_tailA = FlxLinkedList.recycle();
				ot.next = _tailA;
			}

			_tailA.object = _object;
		} else {
			if (_tailB.object != null) {
				ot = _tailB;
				_tailB = FlxLinkedList.recycle();
				ot.next = _tailB;
			}

			_tailB.object = _object;
		}

		if (!_canSubdivide) return;

		for (tree in [_northWestTree, _northEastTree, _southEastTree, _southWestTree]) tree?.addToList();
	}

	/**
	 * FlxQuadTree's other main function.  Call this after adding objects
	 * using FlxQuadTree.load() to compare the objects that you loaded.
	 * @return	Whether or not any overlaps were found.
	 */
	public function execute():Bool {
		var overlapProcessed = false;

		if (_headA.object != null) {
			var iterator = _headA;
			while (iterator != null) {
				_object = iterator.object;
				if (_useBothLists)
					_iterator = _headB;
				else
					_iterator = iterator.next;

				if (_object != null && _object.exists && _object.allowCollisions != NONE && _iterator != null && _iterator.object != null && overlapNode()) overlapProcessed = true;
				
				iterator = iterator.next;
			}
		}

		// Advance through the tree by calling overlap on each child
		for (tree in [_northWestTree, _northEastTree, _southEastTree, _southWestTree])
			if (tree != null && tree.execute())
				overlapProcessed = true;

		return overlapProcessed;
	}

	/**
	 * An internal function for comparing an object against the contents of a node.
	 * @return	Whether or not any overlaps were found.
	 */
	private function overlapNode():Bool {
		// Calculate bulk hull for _object
		_objectHullX = (_object.x < _object.last.x) ? _object.x : _object.last.x;
		_objectHullY = (_object.y < _object.last.y) ? _object.y : _object.last.y;
		_objectHullWidth = _object.x - _object.last.x;
		_objectHullWidth = _object.width + ((_objectHullWidth > 0) ? _objectHullWidth : -_objectHullWidth);
		_objectHullHeight = _object.y - _object.last.y;
		_objectHullHeight = _object.height + ((_objectHullHeight > 0) ? _objectHullHeight : -_objectHullHeight);

		// Walk the list and check for overlaps
		var overlapProcessed = false;
		var checkObject:FlxObject;

		while (_iterator != null) {
			checkObject = _iterator.object;
			if (_object == checkObject || !checkObject.exists || checkObject.allowCollisions == NONE) {
				_iterator = _iterator.next;
				continue;
			}

			// Calculate bulk hull for checkObject
			_checkObjectHullX = (checkObject.x < checkObject.last.x) ? checkObject.x : checkObject.last.x;
			_checkObjectHullY = (checkObject.y < checkObject.last.y) ? checkObject.y : checkObject.last.y;
			_checkObjectHullWidth = checkObject.x - checkObject.last.x;
			_checkObjectHullWidth = checkObject.width + ((_checkObjectHullWidth > 0) ? _checkObjectHullWidth : -_checkObjectHullWidth);
			_checkObjectHullHeight = checkObject.y - checkObject.last.y;
			_checkObjectHullHeight = checkObject.height + ((_checkObjectHullHeight > 0) ? _checkObjectHullHeight : -_checkObjectHullHeight);

			// Check for intersection of the two hulls
			if ((_objectHullX + _objectHullWidth > _checkObjectHullX)
				&& (_objectHullX < _checkObjectHullX + _checkObjectHullWidth)
				&& (_objectHullY + _objectHullHeight > _checkObjectHullY)
				&& (_objectHullY < _checkObjectHullY + _checkObjectHullHeight))
			{
				// Execute callback functions if they exist
				if (_processingCallback == null || _processingCallback(_object, checkObject)) {
					overlapProcessed = true;
					if (_notifyCallback != null) _notifyCallback(_object, checkObject); 
				}
			}

			if (_iterator != null) _iterator = _iterator.next;
		}

		return overlapProcessed;
	}
}
