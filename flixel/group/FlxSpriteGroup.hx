package flixel.group;

import openfl.display.BitmapData;
import openfl.display.BlendMode;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxSort;

/**
 * `FlxSpriteGroup` is a special `FlxSprite` that can be treated like a single sprite even if it's
 * made up of several member sprites. It shares the `FlxGroup` API, but it doesn't inherit from it.
 * Note that `FlxSpriteContainer` also exists.
 *
 * ## When to use a group or container
 * `FlxGroups` are better for organising arbitrary groups for things like iterating or collision.
 * `FlxContainers` are recommended when you are adding them to the current `FlxState`, or a
 * child (or grandchild, and so on) of the state.
 * Since `FlxSpriteGroups` and `FlxSpriteContainers` are usually meant to draw groups of sprites
 * rather than organizing them for collision or iterating, it's recommended to always use
 * `FlxSpriteContainer` instead of `FlxSpriteGroup`.
 */
typedef FlxSpriteGroup = FlxTypedSpriteGroup<FlxSprite>;

/**
 * A `FlxSpriteGroup` that only allows specific members to be a specific type of `FlxSprite`.
 * To use any kind of `FlxSprite` use `FlxSpriteGroup`, which is an alias for
 * `FlxTypedSpriteGroup<FlxSprite>`.
 */
class FlxTypedSpriteGroup<T:FlxSprite> extends FlxSprite {
	/**
	 * The actual group which holds all sprites.
	 */
	public var group(default, set):FlxTypedGroup<T>;

	/**
	 * The link to a group's `members` array.
	 */
	public var members(get, never):Array<T>;

	/**
	 * The number of entries in the members array. For performance and safety you should check this
	 * variable instead of `members.length` unless you really know what you're doing!
	 */
	public var length(get, never):Int;

	/**
	 * Whether to attempt to preserve the ratio of alpha values of group members, or set them directly through
	 * the alpha property. Defaults to `false` (preservation).
	 * @since 4.5.0
	 */
	public var directAlpha = false;

	/**
	 * Whether getters like findMinX, width and height will only count sprites with exist = true.
	 * Defaults to false for backwards compatibility.
	 *
	 * @since 6.4.0
	 */
	public var checkExistsInBounds = false;

	/**
	 * Whether getters like findMinX, width and height will only count visible sprites.
	 *
	 * @since 6.4.0
	 */
	public var checkVisibleInBounds = false;

	/**
	 * The maximum capacity of this group. Default is `0`, meaning no max capacity, and the group can just grow.
	 */
	public var maxSize(get, set):Int;

	/**
	 * Optimization to allow setting position of group without transforming children twice.
	 */
	var _skipTransformChildren = false;

	/**
	 * @param   x         The initial x position of the group.
	 * @param   y         The initial y position of the group.
	 * @param   MaxSize   Maximum amount of members allowed.
	 */
	public function new(x = .0, y = .0, maxSize = 0) {
		initGroup(maxSize);
		super(x, y);
	}

	private function initGroup(maxSize:Int):Void {
		group = new FlxTypedGroup<T>(maxSize);
	}

	/**
	 * This method is used for initialization of variables of complex types.
	 * Don't forget to call `super.initVars()` if you'll override this method,
	 * or you'll get `null` object error and app will crash.
	 */
	override function initVars():Void {
		flixelType = SPRITEGROUP;

		offset = new FlxCallbackPoint(offsetCallback);
		origin = new FlxCallbackPoint(originCallback);
		scale = new FlxCallbackPoint(scaleCallback);
		scrollFactor = new FlxCallbackPoint(scrollFactorCallback);

		scale.set(1, 1);
		scrollFactor.set(1, 1);

		initMotionVars();
	}

	/**
	 * **WARNING:** A destroyed `FlxBasic` can't be used anymore.
	 * It may even cause crashes if it is still part of a group or state.
	 * You may want to use `kill()` instead if you want to disable the object temporarily only and `revive()` it later.
	 *
	 * This function is usually not called manually (Flixel calls it automatically during state switches for all `add()`ed objects).
	 *
	 * Override this function to `null` out variables manually or call `destroy()` on class members if necessary.
	 * Don't forget to call `super.destroy()`!
	 */
	override public function destroy():Void {
		// normally don't have to destroy FlxPoints, but these are FlxCallbackPoints!
		offset = FlxDestroyUtil.destroy(offset);
		origin = FlxDestroyUtil.destroy(origin);
		scale = FlxDestroyUtil.destroy(scale);
		scrollFactor = FlxDestroyUtil.destroy(scrollFactor);

		@:bypassAccessor
		group = FlxDestroyUtil.destroy(group);

		super.destroy();
	}

	/**
	 * Recursive cloning method: it will create a copy of this group which will hold copies of all sprites
	 *
	 * @return  copy of this sprite group
	 */
	override public function clone():FlxTypedSpriteGroup<T> {
		final newGroup = new FlxTypedSpriteGroup<T>(x, y, maxSize);
		for (sprite in group.members)
			if (sprite != null)
				newGroup.add(cast sprite.clone());

		return newGroup;
	}

	/**
	 * Check and see if any sprite in this group is currently on screen.
	 *
	 * @param   camera   Specify which game camera you want. If `null`, it will just grab the first global camera.
	 * @return  Whether the object is on screen or not.
	 */
	override public function isOnScreen(?camera:FlxCamera):Bool {
		if (forceIsOnScreen) return true;

		for (sprite in group.members)
			if (sprite != null && sprite.exists && sprite.visible && sprite.isOnScreen(camera))
				return true;

		return false;
	}

	/**
	 * Checks to see if a point in 2D world space overlaps any `FlxSprite` object from this group.
	 *
	 * @param   Point           The point in world space you want to check.
	 * @param   inScreenSpace   Whether to take scroll factors into account when checking for overlap.
	 * @param   camera          Specify which game camera you want. If `null`, it will just grab the first global camera.
	 * @return  Whether or not the point overlaps this group.
	 */
	override public function overlapsPoint(point:FlxPoint, inScreenSpace = false, ?camera:FlxCamera):Bool {
		var result = false;
		for (sprite in group.members)
			if (sprite != null && sprite.exists && sprite.visible)
				result = result || sprite.overlapsPoint(point, inScreenSpace, camera);

		return result;
	}

	/**
	 * Checks to see if a point in 2D world space overlaps any of FlxSprite object's current displayed pixels.
	 * This check is ALWAYS made in screen space, and always takes scroll factors into account.
	 *
	 * @param   Point    The point in world space you want to check.
	 * @param   mask     Used in the pixel hit test to determine what counts as solid.
	 * @param   camera   Specify which game camera you want.  If `null`, it will just grab the first global camera.
	 * @return  Whether or not the point overlaps this object.
	 */
	override public function pixelsOverlapPoint(point:FlxPoint, mask:Int = 0xFF, ?camera:FlxCamera):Bool {
		var result = false;
		for (sprite in group.members)
			if (sprite != null && sprite.exists && sprite.visible)
				result = result || sprite.pixelsOverlapPoint(point, mask, camera);

		return result;
	}

	override public function update(elapsed:Float):Void {
		group.update(elapsed);

		if (path != null && path.active) path.update(elapsed);

		if (moves) updateMotion(elapsed);
	}

	override public function draw():Void {
		group.draw();

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug) drawDebug();
		#end
	}

	/**
	 * Replaces all pixels with specified `color` with `newColor` pixels.
	 * WARNING: very expensive (especially on big graphics) as it iterates over every single pixel.
	 *
	 * @param   color            color to replace
	 * @param   newColor         New color
	 * @param   fetchPositions   Whether we need to store positions of pixels which colors were replaced.
	 * @return  `Array` with replaced pixels positions
	 */
	override public function replaceColor(color:Int, newColor:Int, fetchPositions = false):Array<FlxPoint> {
		var positions:Array<FlxPoint> = null;
		if (fetchPositions) positions = new Array<FlxPoint>();

		var spritePositions:Array<FlxPoint>;
		for (sprite in group.members)
			if (sprite != null) {
				spritePositions = sprite.replaceColor(color, newColor, fetchPositions);
				if (fetchPositions) positions = positions.concat(spritePositions);
			}

		return positions;
	}

	/**
	 * Adds a new `FlxSprite` subclass to the group.
	 *
	 * @param   sprite   The sprite or sprite group you want to add to the group.
	 * @return  The same object that was passed in.
	 */
	public function add(sprite:T):T {
		preAdd(sprite);
		return group.add(sprite);
	}

	/**
	 * Inserts a new `FlxSprite` subclass to the group at the specified position.
	 *
	 * @param   position The position that the new sprite or sprite group should be inserted at.
	 * @param   sprite   The sprite or sprite group you want to insert into the group.
	 * @return  The same object that was passed in.
	 *
	 * @since 4.3.0
	 */
	public function insert(position:Int, sprite:T):T {
		preAdd(sprite);
		return group.insert(position, sprite);
	}

	/**
	 * Adjusts the position and other properties of the soon-to-be child of this sprite group.
	 * Private helper to avoid duplicate code in `add()` and `insert()`.
	 *
	 * @param	sprite	The sprite or sprite group that is about to be added or inserted into the group.
	 */
	private function preAdd(sprite:T):Void {
		sprite.x += x;
		sprite.y += y;
		sprite.alpha *= alpha;
		sprite.scrollFactor.copyFrom(scrollFactor);
		sprite.cameras = _cameras; // _cameras instead of cameras because get_cameras() will not return null

		if (clipRect != null)
			clipRectTransform(sprite, clipRect);
	}

	/**
	 * Recycling is designed to help you reuse game objects without always re-allocating or "newing" them.
	 * It behaves differently depending on whether `maxSize` equals `0` or is bigger than `0`.
	 *
	 * `maxSize > 0` / "rotating-recycling" (used by `FlxEmitter`):
	 *   - at capacity:  returns the next object in line, no matter its properties like `alive`, `exists` etc.
	 *   - otherwise:    returns a new object.
	 *
	 * `maxSize == 0` / "grow-style-recycling"
	 *   - tries to find the first object with `exists == false`
	 *   - otherwise: adds a new object to the `members` array
	 *
	 * WARNING: If this function needs to create a new object, and no object class was provided,
	 * it will return `null` instead of a valid object!
	 *
	 * @param   objectClass     The class type you want to recycle (e.g. `FlxSprite`, `EvilRobot`, etc).
	 * @param   objectFactory   Optional factory function to create a new object
	 *                          if there aren't any dead members to recycle.
	 *                          If `null`, `Type.createInstance()` is used,
	 *                          which requires the class to have no constructor parameters.
	 * @param   force           force the object to be an `objectClass` and not a super class of `objectClass`.
	 * @param   revive          Whether recycled members should automatically be revived
	 *                          (by calling `revive()` on them).
	 * @return  A reference to the object that was created.
	 */
	public inline function recycle(?objectClass:Class<T>, ?objectFactory:Void -> T, force = false, revive = true):T {
		return group.recycle(objectClass, objectFactory, force, revive);
	}

	/**
	 * Removes the specified sprite from the group.
	 *
	 * @param   sprite  The `FlxSprite` you want to remove.
	 * @param   splice  Whether the object should be cut from the array entirely or not.
	 * @return  The removed sprite.
	 */
	public function remove(sprite:T, splice = false):T {
		sprite.x -= x;
		sprite.y -= y;
		// alpha
		sprite.cameras = null;
		return group.remove(sprite, splice);
	}

	/**
	 * Replaces an existing `FlxSprite` with a new one.
	 *
	 * @param   oldObject  The sprite you want to replace.
	 * @param   newObject  The new object you want to use instead.
	 * @return  The new sprite.
	 */
	public inline function replace(oldObject:T, newObject:T):T {
		preAdd(newObject);
		return group.replace(oldObject, newObject);
	}

	/**
	 * Call this function to sort the group according to a particular value and order.
	 * For example, to sort game objects for Zelda-style overlaps you might call
	 * `group.sort(FlxSort.byY, FlxSort.ASCENDING)` at the bottom of your `FlxState#update()` override.
	 *
	 * @param   func   The sorting function to use - you can use one of the premade ones in
	 *                     `FlxSort` or write your own using `FlxSort.byValues()` as a "backend".
	 * @param   order      A constant that defines the sort order.
	 *                     Possible values are `FlxSort.ASCENDING` (default) and `FlxSort.DESCENDING`.
	 */
	public inline function sort(func:Int -> T -> T -> Int, order = FlxSort.ASCENDING):Void {
		group.sort(func, order);
	}

	/**
	 * Call this function to retrieve the first object with `exists == false` in the group.
	 * This is handy for recycling in general, e.g. respawning enemies.
	 *
	 * @param   objectClass   An optional parameter that lets you narrow the
	 *                        results to instances of this particular class.
	 * @param   force         force the object to be an `objectClass` and not a super class of `objectClass`.
	 * @return  A `FlxSprite` currently flagged as not existing.
	 */
	public inline function getFirstAvailable(?objectClass:Class<T>, force = false):T {
		return group.getFirstAvailable(objectClass, force);
	}

	/**
	 * Call this function to retrieve the first index set to `null`.
	 * Returns `-1` if no index stores a `null` object.
	 *
	 * @return  An `Int` indicating the first `null` slot in the group.
	 */
	public inline function getFirstNull():Int {
		return group.getFirstNull();
	}

	/**
	 * Call this function to retrieve the first object with `exists == true` in the group.
	 * This is handy for checking if everything's wiped out, or choosing a squad leader, etc.
	 *
	 * @return  A `FlxSprite` currently flagged as existing.
	 */
	public inline function getFirstExisting():T {
		return group.getFirstExisting();
	}

	/**
	 * Call this function to retrieve the first object with `dead == false` in the group.
	 * This is handy for checking if everything's wiped out, or choosing a squad leader, etc.
	 *
	 * @return  A `FlxSprite` currently flagged as not dead.
	 */
	public inline function getFirstAlive():T {
		return group.getFirstAlive();
	}

	/**
	 * Call this function to retrieve the first object with `dead == true` in the group.
	 * This is handy for checking if everything's wiped out, or choosing a squad leader, etc.
	 *
	 * @return  A `FlxSprite` currently flagged as dead.
	 */
	public inline function getFirstDead():T {
		return group.getFirstDead();
	}

	/**
	 * Call this function to find out how many members of the group are not dead.
	 *
	 * @return  The number of `FlxSprite`s flagged as not dead. Returns `-1` if group is empty.
	 */
	public inline function countLiving():Int {
		return group.countLiving();
	}

	/**
	 * Call this function to find out how many members of the group are dead.
	 *
	 * @return  The number of `FlxSprite`s flagged as dead. Returns `-1` if group is empty.
	 */
	public inline function countDead():Int {
		return group.countDead();
	}

	/**
	 * Returns a member at random from the group.
	 *
	 * @param   startIndex  Optional offset off the front of the array.
	 *                      Default value is `0`, or the beginning of the array.
	 * @param   length      Optional restriction on the number of values you want to randomly select from.
	 * @return  A `FlxSprite` from the `members` list.
	 */
	public inline function getRandom(startIndex = 0, length = 0):T {
		return group.getRandom(startIndex, length);
	}

	/**
	 * Iterate through every member
	 *
	 * @return An iterator
	 */
	public inline function iterator(?filter:T -> Bool):FlxTypedGroupIterator<T> {
		return new FlxTypedGroupIterator<T>(members, filter);
	}

	/**
	 * Applies a function to all members.
	 *
	 * @param   func   A function that modifies one element at a time.
	 * @param   recurse    Whether or not to apply the function to members of subgroups as well.
	 */
	public inline function forEach(func:T -> Void, recurse = false):Void {
		group.forEach(func, recurse);
	}

	/**
	 * Applies a function to all `alive` members.
	 *
	 * @param   func   A function that modifies one element at a time.
	 * @param   recurse    Whether or not to apply the function to members of subgroups as well.
	 */
	public inline function forEachAlive(func:T -> Void, recurse = false):Void {
		group.forEachAlive(func, recurse);
	}

	/**
	 * Applies a function to all dead members.
	 *
	 * @param   func   A function that modifies one element at a time.
	 * @param   recurse    Whether or not to apply the function to members of subgroups as well.
	 */
	public inline function forEachDead(func:T -> Void, recurse = false):Void {
		group.forEachDead(func, recurse);
	}

	/**
	 * Applies a function to all existing members.
	 *
	 * @param   func   A function that modifies one element at a time.
	 * @param   recurse    Whether or not to apply the function to members of subgroups as well.
	 */
	public inline function forEachExists(func:T -> Void, recurse = false):Void {
		group.forEachExists(func, recurse);
	}

	/**
	 * Applies a function to all members of type `Class<K>`.
	 *
	 * @param   objectClass   A class that objects will be checked against before func is applied, ex: `FlxSprite`.
	 * @param   func      A function that modifies one element at a time.
	 * @param   recurse       Whether or not to apply the function to members of subgroups as well.
	 */
	public inline function forEachOfType<K>(objectClass:Class<K>, func:K -> Void, recurse = false) {
		group.forEachOfType(objectClass, func, recurse);
	}

	/**
	 * Remove all instances of `FlxSprite` from the list.
	 * WARNING: does not `destroy()` or `kill()` any of these objects!
	 */
	public inline function clear():Void {
		group.clear();
	}

	/**
	 * Calls `kill()` on the group's members and then on the group itself.
	 * You can revive this group later via `revive()` after this.
	 */
	override public function kill():Void {
		_skipTransformChildren = true;
		super.kill();
		_skipTransformChildren = false;
		group.kill();
	}

	/**
	 * Revives the group.
	 */
	override public function revive():Void {
		_skipTransformChildren = true;
		super.revive(); // calls set_exists and set_alive
		_skipTransformChildren = false;
		group.revive();
	}

	override public function reset(x:Float, y:Float):Void {
		for (sprite in group.members)
			sprite?.reset(sprite.x + x - this.x, sprite.y + y - this.y);

		// prevent any transformations on children, mainly from setter overrides
		_skipTransformChildren = true;

		// recreate super.reset() but call super.revive instead of revive
		touching = wasTouching = NONE;

		this.x = x;
		this.y = y;
		// last.set(x, y); // null on sprite groups
		velocity.set();
		super.revive();

		_skipTransformChildren = false;
	}

	/**
	 * Helper function to set the coordinates of this object.
	 * Handy since it only requires one line of code.
	 *
	 * @param   x   The new x position
	 * @param   y   The new y position
	 */
	override public function setPosition(x = .0, y = .0):Void {
		// Transform children by the movement delta
		final dx = x - this.x;
		final dy = y - this.y;
		multiTransformChildren([xTransform, yTransform], [dx, dy]);

		// don't transform children twice
		_skipTransformChildren = true;
		this.x = x; // this calls set_x
		this.y = y; // this calls set_y
		_skipTransformChildren = false;
	}

	/**
	 * Handy function that allows you to quickly transform one property of sprites in this group at a time.
	 *
	 * @param   func   func to transform the sprites. Example:
	 *                     `function(sprite, v:Dynamic) { s.acceleration.x = v; s.makeGraphic(10,10,0xFF000000); }`
	 * @param   value      value which will passed to lambda function.
	 */
	#if FLX_GENERIC
	@:generic
	#end
	public function transformChildren<V>(func:T -> V -> Void, value:V):Void {
		if (_skipTransformChildren || group == null) return;

		for (sprite in group.members)
			if (sprite != null)
				func(cast sprite, value);
	}

	/**
	 * Handy function that allows you to quickly transform multiple properties of sprites in this group at a time.
	 *
	 * @param   funcArr   `Array` of functions to transform sprites in this group.
	 * @param   valueArray      `Array` of values which will be passed to lambda functions
	 */
	#if FLX_GENERIC
	@:generic
	#end
	public function multiTransformChildren<V>(funcArr:Array<T -> V -> Void>, valueArray:Array<V>):Void {
		if (_skipTransformChildren || group == null) return;

		final numProps = funcArr.length;
		if (numProps > valueArray.length) return;

		var lambda:T->V->Void;
		for (sprite in group.members)
			if (sprite != null && sprite.exists)
				for (i in 0...numProps) {
					lambda = funcArr[i];
					lambda(cast sprite, valueArray[i]);
				}

	}

	// PROPERTIES GETTERS/SETTERS

	override function set_camera(value:FlxCamera):FlxCamera {
		if (camera != value) transformChildren(cameraTransform, value);
		return super.set_camera(value);
	}

	override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera> {
		if (_cameras != value) transformChildren(camerasTransform, value);
		return super.set_cameras(value);
	}

	override function set_exists(value:Bool):Bool {
		if (exists != value) transformChildren(existsTransform, value);
		return super.set_exists(value);
	}

	override function set_visible(value:Bool):Bool {
		if (exists && visible != value) transformChildren(visibleTransform, value);
		return super.set_visible(value);
	}

	override function set_active(value:Bool):Bool {
		if (exists && active != value) transformChildren(activeTransform, value);
		return super.set_active(value);
	}

	override function set_alive(value:Bool):Bool {
		if (alive != value) transformChildren(aliveTransform, value);
		return super.set_alive(value);
	}

	override function set_x(value:Float):Float {
		if (exists && x != value) transformChildren(xTransform, value - x); // offset
		return x = value;
	}

	override function set_y(value:Float):Float {
		if (exists && y != value) transformChildren(yTransform, value - y); // offset
		return y = value;
	}

	override function set_angle(value:Float):Float {
		if (exists && angle != value) transformChildren(angleTransform, value - angle); // offset
		return angle = value;
	}

	override function set_alpha(value:Float):Float {
		value = FlxMath.bound(value, 0, 1);

		if (exists && alpha != value) {
			final factor = (alpha > 0) ? value / alpha : 0;
			if (!directAlpha && alpha != 0)
				transformChildren(alphaTransform, factor);
			else
				transformChildren(directAlphaTransform, value);
		}
		return alpha = value;
	}

	override function set_facing(value:FlxDirectionFlags):FlxDirectionFlags {
		if (exists && facing != value) transformChildren(facingTransform, value);
		return facing = value;
	}

	override function set_flipX(value:Bool):Bool {
		if (exists && flipX != value) transformChildren(flipXTransform, value);
		return flipX = value;
	}

	override function set_flipY(value:Bool):Bool {
		if (exists && flipY != value) transformChildren(flipYTransform, value);
		return flipY = value;
	}

	override function set_moves(value:Bool):Bool {
		if (exists && moves != value) transformChildren(movesTransform, value);
		return moves = value;
	}

	override function set_immovable(value:Bool):Bool {
		if (exists && immovable != value) transformChildren(immovableTransform, value);
		return immovable = value;
	}

	override function set_solid(value:Bool):Bool {
		if (exists && solid != value) transformChildren(solidTransform, value);
		return super.set_solid(value);
	}

	override function set_color(value:Int):Int {
		if (exists && color != value) transformChildren(gColorTransform, value);
		return color = value;
	}

	override function set_blend(value:BlendMode):BlendMode {
		if (exists && blend != value) transformChildren(blendTransform, value);
		return blend = value;
	}

	override function set_clipRect(rect:FlxRect):FlxRect {
		if (exists) transformChildren(clipRectTransform, rect);
		return super.set_clipRect(rect);
	}

	override function set_pixelPerfectRender(value:Bool):Bool {
		if (exists && pixelPerfectRender != value) transformChildren(pixelPerfectTransform, value);
		return super.set_pixelPerfectRender(value);
	}

	/**
	 * This functionality isn't supported in SpriteGroup
	 */
	override function set_width(value:Float):Float {
		return value;
	}

	override function get_width():Float  {
		if (length == 0) return 0;

		return findMaxXHelper() - findMinXHelper();
	}

	inline function ignoreBounds(sprite:Null<FlxSprite>) {
		return sprite == null || (checkExistsInBounds && !sprite.exists) || (checkVisibleInBounds && !sprite.visible);
	}

	/**
	 * Returns the left-most position of the left-most member.
	 * If there are no members, x is returned.
	 *
	 * @since 5.0.0
	 */
	public function findMinX() {
		return length == 0 ? x : findMinXHelper();
	}

	private function findMinXHelper() {
		var value = Math.POSITIVE_INFINITY;
		for (member in group.members) {
			if (ignoreBounds(member)) continue;

			var minX:Float;
			if (member.flixelType == SPRITEGROUP) minX = (cast member:FlxSpriteGroup).findMinX();
			else minX = member.x;

			if (minX < value) value = minX;
		}
		return value;
	}

	/**
	 * Returns the right-most position of the right-most member.
	 * If there are no members, x is returned.
	 *
	 * @since 5.0.0
	 */
	public function findMaxX() {
		return length == 0 ? x : findMaxXHelper();
	}

	private function findMaxXHelper() {
		var value = Math.NEGATIVE_INFINITY;
		for (member in group.members) {
			if (ignoreBounds(member)) continue;

			var maxX:Float;
			if (member.flixelType == SPRITEGROUP) maxX = (cast member:FlxSpriteGroup).findMaxX();
			else maxX = member.x + member.width;

			if (maxX > value) value = maxX;
		}
		return value;
	}

	/**
	 * This functionality isn't supported in SpriteGroup
	 */
	override function set_height(value:Float):Float {
		return value;
	}

	override function get_height():Float {
		if (length == 0) return 0;

		return findMaxYHelper() - findMinYHelper();
	}

	/**
	 * Returns the top-most position of the top-most member.
	 * If there are no members, y is returned.
	 *
	 * @since 5.0.0
	 */
	public function findMinY() {
		return length == 0 ? y : findMinYHelper();
	}

	private function findMinYHelper() {
		var value = Math.POSITIVE_INFINITY;
		for (member in group.members) {
			if (ignoreBounds(member)) continue;

			var minY:Float;
			if (member.flixelType == SPRITEGROUP) minY = (cast member:FlxSpriteGroup).findMinY();
			else minY = member.y;

			if (minY < value) value = minY;
		}
		return value;
	}

	/**
	 * Returns the top-most position of the top-most member.
	 * If there are no members, y is returned.
	 *
	 * @since 5.0.0
	 */
	public function findMaxY()
	{
		return length == 0 ? y : findMaxYHelper();
	}

	private function findMaxYHelper() {
		var value = Math.NEGATIVE_INFINITY;
		for (member in group.members) {
			if (ignoreBounds(member)) continue;

			var maxY:Float;
			if (member.flixelType == SPRITEGROUP) maxY = (cast member:FlxSpriteGroup).findMaxY();
			else maxY = member.y + member.height;

			if (maxY > value) value = maxY;
		}
		return value;
	}

	// GROUP FUNCTIONS

	inline function get_length():Int {
		return group.length;
	}

	inline function get_maxSize():Int {
		return group.maxSize;
	}

	inline function set_maxSize(size:Int):Int {
		return group.maxSize = size;
	}

	inline function get_members():Array<T> {
		return group.members;
	}

	// TRANSFORM FUNCTIONS - STATIC TYPING

	inline function xTransform(sprite:FlxSprite, x:Float) {
		sprite.x += x; // addition
	}

	inline function yTransform(sprite:FlxSprite, y:Float) {
		sprite.y += y; // addition
	}

	inline function angleTransform(sprite:FlxSprite, angle:Float) {
		sprite.angle += angle; // addition
	}

	inline function alphaTransform(sprite:FlxSprite, alpha:Float) {
		if (sprite.alpha != 0 || alpha == 0)
			sprite.alpha *= alpha; // multiplication
		else
			sprite.alpha = 1 / alpha; // direct set to avoid stuck sprites
	}

	inline function directAlphaTransform(sprite:FlxSprite, alpha:Float){
		sprite.alpha = alpha; // direct set
	}

	inline function facingTransform(sprite:FlxSprite, facing:FlxDirectionFlags) {
		sprite.facing = facing;
	}

	inline function flipXTransform(sprite:FlxSprite, flipX:Bool) {
		sprite.flipX = flipX;
	}

	inline function flipYTransform(sprite:FlxSprite, flipY:Bool) {
		sprite.flipY = flipY;
	}

	inline function movesTransform(sprite:FlxSprite, moves:Bool) {
		sprite.moves = moves;
	}

	inline function pixelPerfectTransform(sprite:FlxSprite, pixelPerfect:Bool) {
		sprite.pixelPerfectRender = pixelPerfect;
	}

	inline function gColorTransform(sprite:FlxSprite, color:Int) {
		sprite.color = color;
	}

	inline function blendTransform(sprite:FlxSprite, blend:BlendMode) {
		sprite.blend = blend;
	}

	inline function immovableTransform(sprite:FlxSprite, immovable:Bool) {
		sprite.immovable = immovable;
	}

	inline function visibleTransform(sprite:FlxSprite, visible:Bool) {
		sprite.visible = visible;
	}

	inline function activeTransform(sprite:FlxSprite, active:Bool) {
		sprite.active = active;
	}

	inline function solidTransform(sprite:FlxSprite, solid:Bool) {
		sprite.solid = solid;
	}

	inline function aliveTransform(sprite:FlxSprite, alive:Bool) {
		sprite.alive = alive;
	}

	inline function existsTransform(sprite:FlxSprite, exists:Bool) {
		sprite.exists = exists;
	}

	inline function cameraTransform(sprite:FlxSprite, camera:FlxCamera) {
		sprite.camera = camera;
	}

	inline function camerasTransform(sprite:FlxSprite, cameras:Array<FlxCamera>) {
		sprite.cameras = cameras;
	}

	inline function offsetTransform(sprite:FlxSprite, offset:FlxPoint) {
		sprite.offset.copyFrom(offset);
	}

	inline function originTransform(sprite:FlxSprite, origin:FlxPoint) {
		sprite.origin.set(x + origin.x - sprite.x, y + origin.y - sprite.y);
	}

	inline function scaleTransform(sprite:FlxSprite, scale:FlxPoint) {
		sprite.scale.copyFrom(scale);
	}

	inline function scrollFactorTransform(sprite:FlxSprite, scrollFactor:FlxPoint) {
		sprite.scrollFactor.copyFrom(scrollFactor);
	}

	private function clipRectTransform(sprite:FlxSprite, clipRect:FlxRect) {
		if (clipRect == null)
			sprite.clipRect = null;
		else
			sprite.clipRect = FlxRect.get(clipRect.x - sprite.x + x, clipRect.y - sprite.y + y, clipRect.width, clipRect.height);
	}

	// Functions for the FlxCallbackPoint
	inline function offsetCallback(offset:FlxPoint) {
		transformChildren(offsetTransform, offset);
	}

	inline function originCallback(origin:FlxPoint) {
		transformChildren(originTransform, origin);
	}

	inline function scaleCallback(scale:FlxPoint) {
		transformChildren(scaleTransform, scale);
	}

	inline function scrollFactorCallback(scrollFactor:FlxPoint) {
		transformChildren(scrollFactorTransform, scrollFactor);
	}

	// NON-SUPPORTED FUNCTIONALITY
	// THESE METHODS ARE OVERRIDDEN FOR SAFETY PURPOSES

	/**
	 * This functionality isn't supported in SpriteGroup
	 * @return this sprite group
	 */
	override public function loadGraphicFromSprite(sprite:FlxSprite):FlxSprite {
		#if FLX_DEBUG
		FlxG.log.critical("This function is not supported in FlxSpriteGroup");
		#end
		return this;
	}

	/**
	 * This functionality isn't supported in SpriteGroup
	 * @return this sprite group
	 */
	override public function loadGraphic(graphic:FlxGraphicAsset, animated = false, width = 0, height = 0, unique = false, ?key:String):FlxSprite {
		return this;
	}

	/**
	 * This functionality isn't supported in SpriteGroup
	 * @return this sprite group
	 */
	override public function loadRotatedGraphic(graphic:FlxGraphicAsset, rotations = 16, frame = -1, antiAliasing = false, autoBuffer = false, ?key:String):FlxSprite {
		#if FLX_DEBUG
		FlxG.log.critical("This function is not supported in FlxSpriteGroup");
		#end
		return this;
	}

	/**
	 * This functionality isn't supported in SpriteGroup
	 * @return this sprite group
	 */
	override public function makeGraphic(width:Int, height:Int, color:Int = FlxColor.WHITE, unique = false, ?key:String):FlxSprite {
		#if FLX_DEBUG
		FlxG.log.critical("This function is not supported in FlxSpriteGroup");
		#end
		return this;
	}

	override function set_pixels(value:BitmapData):BitmapData {
		return value;
	}

	override function set_frame(value:FlxFrame):FlxFrame {
		return value;
	}

	override function get_pixels():BitmapData {
		return null;
	}

	private function set_group(value:FlxTypedGroup<T>):FlxTypedGroup<T> {
		return this.group = value;
	}

	/**
	 * Internal function to update the current animation frame.
	 *
	 * @param	runOnCpp	Whether the frame should also be recalculated
	 */
	override inline function calcFrame(runOnCpp = false):Void {} // Nothing to do here

	/**
	 * This functionality isn't supported in SpriteGroup
	 */
	override inline function resetHelpers():Void {}

	/**
	 * This functionality isn't supported in SpriteGroup
	 */
	override public inline function stamp(brush:FlxSprite, x = 0, y = 0):Void {}

	override function set_frames(frames:FlxFramesCollection):FlxFramesCollection {
		return frames;
	}

	/**
	 * This functionality isn't supported in SpriteGroup
	 */
	override inline function updateColorTransform():Void {}
}
