package flixel;

import flixel.FlxBasic.IFlxBasic;
import flixel.FlxTypes;
import flixel.animation.FlxAnimationController;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.util.FlxBitmapDataUtil;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDirectionFlags;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;

using flixel.util.FlxColorTransformUtil;

/**
 * The core building blocks of all Flixel games. With helpful tools for animation, movement and
 * features for the needs of most games.
 *
 * It is pretty common place to extend `FlxSprite` for your own game's needs; for example a `SpaceShip`
 * class may extend `FlxSprite` but could have additional variables for the game like `shieldStrength`
 * or `shieldPower`.
 *
 * - [Handbook - FlxSprite](https://haxeflixel.com/documentation/flxsprite/)
 *
 * ## Collision and Motion
 * Flixel handles many aspects of collision and physics motions for you. This is all defined in the
 * base class: [FlxObject](https://api.haxeflixel.com/flixel/FlxObject.html), check there for things
 * like: `x`, `y`, `width`, `height`, `velocity`, `acceleration`, `maxVelocity`, `drag`, `angle`,
 * and `angularVelocity`. All of these affect the movement and orientation of the sprite as well
 * as [FlxG.collide](https://api.haxeflixel.com/flixel/FlxG.html#collide) and
 * [FlxG.overlap](https://api.haxeflixel.com/flixel/FlxG.html#overlap)
 *
 * ## Graphics
 * `FlxSprites` are just `FlxObjects` with the ability to show graphics. There are various ways to do this.
 * ### `loadGraphic()`
 * [Snippets - Loading Sprites](https://snippets.haxeflixel.com/sprites/loading-sprites/)
 * The easiest way to use a single image for your FlxSprite. Using the OpenFL asset system defined
 * in the project xml file you simply have to define a path to your image and the compiler will do
 * the rest.
 * ```haxe
 * var player = new FlxSprite();
 * player.loadGraphic("assets/player.png");
 * add(player);
 * ```
 *
 * ####Animations
 * [Snippets - Animations](https://snippets.haxeflixel.com/sprites/animation/)
 * When loading a graphic for a `FlxSprite`, you can specify is as an animated graphic. Then, using
 * animation, you can setup animations and play them.
 * ```haxe
 *  // sprite's graphic will be loaded from 'path/to/image.png' and is set to allow animations.
 * sprite.loadGraphic('path/to/image/png', true);
 *
 * // add an animation named 'run' to sprite, using the specified frames
 * sprite.animation.add('run', [0, 1, 2, 1]);
 *
 * // play the 'run' animation
 * sprite.animation.play('run');
 * ```
 *
 * ### `makeGraphic()`
 * [Snippets - Loading Sprites](https://snippets.haxeflixel.com/sprites/making-sprites/)
 * This method is a handy way to make a simple color fill to quickly test a feature or have the basic shape.
 * ```haxe
 * var whiteSquare = new FlxSprite();
 * whiteSquare.makeGraphic(200, 200, FlxColor.WHITE);
 * add(whiteSquare);
 * ```
 * ## Properties
 * ### Position: x, y
 * ```haxe
 * whiteSquare.x = 100;
 * whiteSquare.y = 300;
 * ```
 *
 * ### Size: width, height
 * Automatically set in loadGraphic() or makeGraphic(), changing this will only affect the hitbox
 * of this sprite, use scale to change the graphic's size.
 * ```haxe
 * // get
 * var getWidth = whiteSquare.width;
 *
 * // set
 * whiteSquare.width = 100;
 * whiteSquare.height = 100;
 * ```
 *
 * ### Scale
 * [Snippets - Scale](https://snippets.haxeflixel.com/sprites/scale/)
 * (FlxPoint) Change the size of your sprite's graphic. NOTE: The hitbox is not automatically
 * adjusted, use updateHitbox() for that.
 * ```haxe
 * // twice as big
 * whiteSquare.scale.set(2, 2);
 *
 * // 50%
 * whiteSquare.scale.set(0.5, 0.5);
 * ```
 *
 * ### Offset
 * (FlxPoint) Controls the position of the sprite's hitbox. Likely needs to be adjusted after changing a sprite's width, height or scale.
 * ```haxe
 * whiteSquare.offset.set(50, 50);
 * ```
 *
 * ### Origin
 * (FlxPoint) Rotation axis. Default: center.
 *
 * WARNING: If you change this, the visuals and the collisions will likely be pretty out-of-sync if you do any rotation.
 * ```haxe
 * // rotate from top-left corner instead of center
 * whiteSquare.origin.set(0, 0);
 * ```
 *
 */
class FlxSprite extends FlxObject {
	/**
	 * The default value for `antialiasing` across all `FlxSprites`,
	 * defaults to `false`.
	 * @since 5.0.0
	 */
	public static var defaultAntialiasing = false;

	public static var defaultHaxeFlixelLogo:FlxGraphicAsset = "flixel/images/logo/default.png";

	/**
	 * Class that handles adding and playing animations on this sprite.
	 * @see https://snippets.haxeflixel.com/sprites/animation/
	 */
	public var animation:FlxAnimationController;

	// TODO: maybe convert this var to property...

	/**
	 * The current display state of the sprite including current animation frame,
	 * tint, flip etc... may be `null` unless `useFramePixels` is `true`.
	 */
	public var framePixels:BitmapData;

	/**
	 * Always `true` on `FlxG.render.blit`. On `FlxG.render.tile` it determines whether
	 * `framePixels` is used and defaults to `false` for performance reasons.
	 */
	public var useFramePixels(default, set) = true;

	/**
	 * Controls whether the object is smoothed when rotated, affects performance.
	 */
	public var antialiasing(default, set) = defaultAntialiasing;

	/**
	 * Set this flag to true to force the sprite to update during the `draw()` call.
	 * NOTE: Rarely if ever necessary, most sprite operations will flip this flag automatically.
	 */
	public var dirty = true;

	/**
	 * This sprite's graphic / `BitmapData` object.
	 * Automatically adjusts graphic size and render helpers if changed.
	 */
	public var pixels(get, set):BitmapData;

	/**
	 * Link to current `FlxFrame` from loaded atlas
	 */
	public var frame(default, set):FlxFrame;

	/**
	 * The width of the actual graphic or image being displayed (not necessarily the game object/bounding box).
	 */
	public var frameWidth(default, null) = 0;

	/**
	 * The height of the actual graphic or image being displayed (not necessarily the game object/bounding box).
	 */
	public var frameHeight(default, null) = 0;

	/**
	 * The total number of frames in this image.
	 * WARNING: assumes each row in the sprite sheet is full!
	 */
	public var numFrames(get, never):Int;

	/**
	 * Rendering variables.
	 */
	public var frames(default, set):FlxFramesCollection;

	public var graphic(default, set):FlxGraphic;

	/**
	 * The minimum angle (out of 360°) for which a new baked rotation exists. Example: `90` means there
	 * are 4 baked rotations in the spritesheet. `0` if this sprite does not have any baked rotations.
	 * @see https://snippets.haxeflixel.com/sprites/baked-rotations/
	 */
	public var bakedRotationAngle(default, null) = .0;

	/**
	 * Set alpha to a number between `0` and `1` to change the opacity of the sprite.
	 * @see https://snippets.haxeflixel.com/sprites/alpha/
	 */
	public var alpha(default, set) = 1.;

	/**
	 * Can be set to `LEFT`, `RIGHT`, `UP`, and `DOWN` to take advantage
	 * of flipped sprites and/or just track player orientation more easily.
	 * @see https://snippets.haxeflixel.com/sprites/facing/
	 */
	public var facing(default, set):FlxDirectionFlags = RIGHT;

	/**
	 * Whether this sprite is flipped on the X axis.
	 */
	public var flipX(default, set) = false;

	/**
	 * Whether this sprite is flipped on the Y axis.
	 */
	public var flipY(default, set) = false;

	/**
	 * WARNING: The `origin` of the sprite will default to its center. If you change this,
	 * the visuals and the collisions will likely be pretty out-of-sync if you do any rotation.
	 */
	public var origin(default, null):FlxPoint;

	/**
	 * The position of the sprite's graphic relative to its hitbox. For example, `offset.x = 10;` will
	 * show the graphic 10 pixels left of the hitbox. Likely needs to be adjusted after changing a sprite's
	 * `width`, `height` or `scale`.
	 */
	public var offset(default, null):FlxPoint;

	/**
	 * The position of the sprite's graphic relative to the frame, scaling and angles. For example, `offset.x = 10;` with
	 * a scale of 2 will move the sprite 20 pixels to the left.
	 */
	public var frameOffset(default, null):FlxPoint;

	/**
	 * (Nullable) Custom angle to be applied to `frameOffset`
	 */
	public var frameOffsetAngle:Null<Float> = null;

	/**
	 * Change the size of your sprite's graphic.
	 * NOTE: The hitbox is not automatically adjusted, use `updateHitbox()` for that.
	 * WARNING: With `FlxG.render.blit`, scaling sprites decreases rendering performance by a factor of about x10!
	 * @see https://snippets.haxeflixel.com/sprites/scale/
	 */
	public var scale(default, null):FlxPoint;

	/**
	 * Blending modes, just like Photoshop or whatever, e.g. "multiply", "screen", etc.
	 */
	public var blend(default, set):BlendMode;

	/**
	 * Tints the whole sprite to a color (`0xRRGGBB` format) - similar to OpenGL vertex colors. You can use
	 * `0xAARRGGBB` colors, but the alpha value will simply be ignored. To change the opacity use `alpha`.
	 * @see https://snippets.haxeflixel.com/sprites/color/
	 */
	public var color(default, set):FlxColor = FlxColor.WHITE;

	/**
	 * The color effects of this sprite, changes to `color` or `alpha` will be reflected here
	 */
	public var colorTransform(default, null) = new ColorTransform();

	public var onDraw(default, set):FlxSprite -> Void;

	public function set_onDraw(drawFunc:FlxSprite -> Void):FlxSprite->Void {
		__drawOverrided = drawFunc != null;
		return onDraw = drawFunc;
	}

	@:noCompletion public var __drawOverrided = false; // Avoid null checks

	/**
	 * Clipping rectangle for this sprite's frame. When `null`, the entire
 	 * frame is shown, otherwise `x`, `y`, `width` and `height` determine which portion
 	 * of the frame is shown. Expected values are within (`0`,`0`) and (`frameWidth`,`frameHeight`),
 	 * extending the rect beyond the frame will not extend the graphic.
 	 *
 	 * Fields like position `scale`, `offset`, `angle`, `flipX` and `flipY` have no effect and are
 	 * applied after the frame is clipped. Use `clipToWorldBounds` or `clipToViewBounds` to convert
	 */
	public var clipRect(default, set):FlxRect;
	var _lastClipRect = FlxRect.get(Math.NaN);

	/**
	 * Clipping rectangle for this sprite.
	 * Changing the rect's properties directly doesn't have any effect,
	 * reassign the property to update it (`sprite.rawClipRect = sprite.rawClipRect;`).
	 * Set to `null` to discard graphic frame clipping.
	 * Differences between `clipRect` and `rawClipRect`:
	 * - `clipRect` is rounded to the nearest pixel.
	 * - `rawClipRect` is not rounded at all.
	 */
	public var rawClipRect(get, set):FlxRect;

	/**
	 * GLSL shader for this sprite. Avoid changing it frequently as this is a costly operation.
	 * @since 4.1.0
	 */
	public var shader(default, set):FlxShader;

	/**
	 * Whether the shader should be enabled.
	 */
	public var shaderEnabled = true;

	/**
 	 * Layer to draw on
 	 */
	public var layer:FlxLayer;

	/**
	 * The actual frame used for sprite rendering
	 */
	@:noCompletion
	var _frame:FlxFrame;

	/**
	 * Graphic of `_frame`. Used in tile render mode, when `useFramePixels` is `true`.
	 */
	@:noCompletion var _frameGraphic:FlxGraphic;

	@:noCompletion var _facingHorizontalMult:ByteInt = 1;
	@:noCompletion var _facingVerticalMult:ByteInt = 1;

	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	@:noCompletion var _flashPoint:Point;

	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	@:noCompletion var _flashRect:Rectangle;

	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	@:noCompletion var _flashRect2:Rectangle;

	/**
	 * Internal, reused frequently during drawing and animating. Always contains `(0,0)`.
	 */
	@:noCompletion static var __flashPointZero = new Point();

	@:noCompletion var _flashPointZero(get, never):Point;

	inline function get__flashPointZero() return __flashPointZero;

	/**
	 * Internal, helps with animation, caching and drawing.
	 */
	@:noCompletion var _matrix:FlxMatrix;

	/**
	 *  Helper variable
	 */
	@:noCompletion var _scaledOrigin:FlxPoint;

	/**
	 *  Helper variable
	 */
	@:noCompletion var _scaledFrameOffset:FlxPoint;

	/**
	 * These vars are being used for rendering in some of `FlxSprite` subclasses (`FlxTileblock`, `FlxBar`,
	 * and `FlxBitmapText`) and for checks if the sprite is in camera's view.
	 */
	@:noCompletion var _sinAngle = .0;

	@:noCompletion var _cosAngle = 1.;

	@:noCompletion var _angleChanged = true;

	/**
	 * Maps `FlxDirectionFlags` values to axis flips
	 */
	@:noCompletion var _facingFlip = new Map<FlxDirectionFlags, FlxSpriteFacingFlip>();

	/**
	 * Creates a `FlxSprite` at a specified position with a specified one-frame graphic.
	 * If none is provided, a 16x16 image of the HaxeFlixel logo is used.
	 *
	 * @param   x               The initial X position of the sprite.
	 * @param   y               The initial Y position of the sprite.
	 * @param   simpleGraphic   The graphic you want to display
	 *                          (OPTIONAL - for simple stuff only, do NOT use for animated images!).
	 */
	public function new(?x = .0, ?y = .0, ?simpleGraphic:FlxGraphicAsset) {
		super(x, y);

		useFramePixels = FlxG.render.blit;
		if (simpleGraphic != null) loadGraphic(simpleGraphic);
	}

	@:noCompletion override function initVars():Void {
		super.initVars();

		animation = new FlxAnimationController(this);

		_flashPoint = new Point();
		_flashRect = new Rectangle();
		_flashRect2 = new Rectangle();
		offset = FlxPoint.get();
		frameOffset = FlxPoint.get();
		origin = FlxPoint.get();
		scale = FlxPoint.get(1, 1);
		_matrix = new FlxMatrix();
		_scaledOrigin = new FlxPoint();
		_scaledFrameOffset = new FlxPoint();
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
		super.destroy();

		animation = FlxDestroyUtil.destroy(animation);

		offset = FlxDestroyUtil.put(offset);
		frameOffset = FlxDestroyUtil.put(frameOffset);
		origin = FlxDestroyUtil.put(origin);
		scale = FlxDestroyUtil.put(scale);
		_scaledOrigin = FlxDestroyUtil.put(_scaledOrigin);
		_lastClipRect = FlxDestroyUtil.put(_lastClipRect);
		_scaledFrameOffset = FlxDestroyUtil.put(_scaledFrameOffset);

		framePixels = FlxDestroyUtil.dispose(framePixels);

		_flashPoint = null;
		_flashRect = null;
		_flashRect2 = null;
		_matrix = null;
		blend = null;

		frames = null;
		graphic = null;
		_frame = FlxDestroyUtil.destroy(_frame);
		isFrameNull = true;
		_frameGraphic = FlxDestroyUtil.destroy(_frameGraphic);

		@:bypassAccessor clipRect = FlxDestroyUtil.put(clipRect);
		shader = null;
	}

	public function clone():FlxSprite {
		return (new FlxSprite()).loadGraphicFromSprite(this);
	}

	/**
	 * Load graphic from another `FlxSprite` and copy its tile sheet data.
	 *
	 * @param   sprite   The `FlxSprite` from which you want to load graphic data.
	 * @return  This `FlxSprite` instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadGraphicFromSprite(sprite:FlxSprite):FlxSprite {
		frames = sprite.frames;
		bakedRotationAngle = sprite.bakedRotationAngle;
		if (bakedRotationAngle > 0) {
			width = sprite.width;
			height = sprite.height;
			centerOffsets();
		}
		antialiasing = sprite.antialiasing;
		animation.copyFrom(sprite.animation);
		graphicLoaded();
		clipRect = sprite.clipRect;
		return this;
	}

	/**
	 * Load an image from an embedded graphic file.
	 *
	 * HaxeFlixel's graphic caching system keeps track of loaded image data.
	 * When you load an identical copy of a previously used image, by default
	 * HaxeFlixel copies the previous reference onto the `pixels` field instead
	 * of creating another copy of the image data, to save memory.
	 *
	 * NOTE: This method updates hitbox size and frame size.
	 *
	 * @param   graphic      The image you want to use.
	 * @param   animated     Whether the `Graphic` parameter is a single sprite or a row / grid of sprites.
	 * @param   frameWidth   Specify the width of your sprite
	 *                       (helps figure out what to do with non-square sprites or sprite sheets).
	 * @param   frameHeight  Specify the height of your sprite
	 *                       (helps figure out what to do with non-square sprites or sprite sheets).
	 * @param   unique       Whether the graphic should be a unique instance in the graphics cache.
	 *                       Set this to `true` if you want to modify the `pixels` field without changing
	 *                       the `pixels` of other sprites with the same `BitmapData`.
	 * @param   key          Set this parameter if you're loading `BitmapData`.
	 * @return  This `FlxSprite` instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):FlxSprite {
		final graph = FlxG.bitmap.add(graphic, unique, key);
		if (graph == null) return this;

		if (frameWidth == 0) {
			frameWidth = animated ? graph.height : graph.width;
			frameWidth = (frameWidth > graph.width) ? graph.width : frameWidth;
		} else if (frameWidth > graph.width)
			FlxG.log.warn('frameWidth:$frameWidth is larger than the graphic\'s width:${graph.width}');

		if (frameHeight == 0) {
			frameHeight = animated ? frameWidth : graph.height;
			frameHeight = (frameHeight > graph.height) ? graph.height : frameHeight;
		} else if (frameHeight > graph.height)
			FlxG.log.warn('frameHeight:$frameHeight is larger than the graphic\'s height:${graph.height}');

		frames = animated ? FlxTileFrames.fromGraphic(graph, FlxPoint.get(frameWidth, frameHeight)) : graph.imageFrame;

		return this;
	}

	/**
	 * Create a pre-rotated sprite sheet from a simple sprite.
	 * This can make a huge difference in graphical performance on blitting targets!
	 *
	 * @param   graphic        The image you want to rotate and stamp.
	 * @param   rotations      The number of rotation frames the final sprite should have.
	 *                         For small sprites this can be quite a large number (`360` even) without any problems.
	 * @param   frame          If the `Graphic` has a single row of square animation frames on it,
	 *                         you can specify which of the frames you want to use here.
	 *                         Default is `-1`, or "use whole graphic."
	 * @param   antiAliasing   Whether to use high quality rotations when creating the graphic. Default is `false`.
	 * @param   autoBuffer     Whether to automatically increase the image size to accommodate rotated corners.
	 *                         Will create frames that are 150% larger on each axis than the original frame or graphic.
	 * @param   key            Optional, set this parameter if you're loading `BitmapData`.
	 * @return  This `FlxSprite` instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadRotatedGraphic(graphic:FlxGraphicAsset, rotations = 16, frame = -1, antiAliasing = false, autoBuffer = false, ?Key:String):FlxSprite {
		final brushGraphic = FlxG.bitmap.add(graphic, false, Key);
		if (brushGraphic == null) return this;

		var brush = brushGraphic.bitmap;
		var key = brushGraphic.key;

		if (frame >= 0) {
			// we assume that source graphic has one row frame animation with equal width and height
			final brushSize:Int = brush.height;
			final framesNum = Std.int(brush.width / brushSize);
			frame = (framesNum > frame || framesNum == 0) ? frame : (frame % framesNum);
			key += ":" + frame;

			final full = brush;
			brush = new BitmapData(brushSize, brushSize, true, FlxColor.TRANSPARENT);
			_flashRect.setTo(frame * brushSize, 0, brushSize, brushSize);
			brush.copyPixels(full, _flashRect, _flashPointZero);
		}

		key += ":" + rotations + ":" + autoBuffer;

		// Generate a new sheet if necessary, then fix up the width and height
		var tempGraph = FlxG.bitmap.get(key);
		if (tempGraph == null) {
			final bitmap = FlxBitmapDataUtil.generateRotations(brush, rotations, antiAliasing, autoBuffer);
			tempGraph = FlxGraphic.fromBitmapData(bitmap, false, key);
		}

		#if FLX_TRACK_GRAPHICS
		tempGraph.trackingInfo = '$ID.loadRotatedGraphic(${brushGraphic.trackingInfo}, $Rotations, $frame, $antiAliasing, $autoBuffer)';
		#end

		var max:Int = (brush.height > brush.width) ? brush.height : brush.width;
		max = autoBuffer ? Std.int(max * 1.5) : max;

		frames = FlxTileFrames.fromGraphic(tempGraph, FlxPoint.get(max, max));

		if (autoBuffer) {
			width = brush.width;
			height = brush.height;
			centerOffsets();
		}

		bakedRotationAngle = 360 / rotations;
		animation.createPrerotated();
		return this;
	}

	/**
	 * Helper method which allows using `FlxFrame` as graphic source for sprite's `loadRotatedGraphic()` method.
	 *
	 * @param   frame          Frame to load into this sprite.
	 * @param   rotations      The number of rotation frames the final sprite should have.
	 *                         For small sprites this can be quite a large number (`360` even) without any problems.
	 * @param   antiAliasing   Whether to use high quality rotations when creating the graphic. Default is `false`.
	 * @param   autoBuffer     Whether to automatically increase the image size to accommodate rotated corners.
	 *                         Will create frames that are 150% larger on each axis than the original frame or graphic.
	 * @return  this FlxSprite with loaded rotated graphic in it.
	 */
	public function loadRotatedFrame(frame:FlxFrame, rotations = 16, antiAliasing = false, autoBuffer = false):FlxSprite {
		var key = frame.parent.key;
		if (frame.name != null) key += ":" + frame.name;
		else key += ":" + frame.frame.toString();

		var graphic = FlxG.bitmap.get(key);
		graphic ??= FlxGraphic.fromBitmapData(frame.paint(), false, key);

		#if FLX_TRACK_GRAPHICS
		graphic.trackingInfo = '$ID.loadRotatedFrame($key, $rotations, $antiAliasing, $autoBuffer)';
		#end

		return loadRotatedGraphic(graphic, rotations, -1, antiAliasing, autoBuffer);
	}

	/**
	 * This function creates a flat colored rectangular image dynamically.
	 *
	 * HaxeFlixel's graphic caching system keeps track of loaded image data.
	 * When you make an identical copy of a previously used image, by default
	 * HaxeFlixel copies the previous reference onto the pixels field instead
	 * of creating another copy of the image data, to save memory.
	 *
	 * NOTE: This method updates hitbox size and frame size.
	 *
	 * @param   Width    The width of the sprite you want to generate.
	 * @param   Height   The height of the sprite you want to generate.
	 * @param   Color    Specifies the color of the generated block (ARGB format).
	 * @param   Unique   Whether the graphic should be a unique instance in the graphics cache. Default is `false`.
	 *                   Set this to `true` if you want to modify the `pixels` field without changing the
	 *                   `pixels` of other sprites with the same `BitmapData`.
	 * @param   Key      An optional `String` key to identify this graphic in the cache.
	 *                   If `null`, the key is determined by `Width`, `Height` and `Color`.
	 *                   If `Unique` is `true` and a graphic with this `Key` already exists,
	 *                   it is used as a prefix to find a new unique name like `"Key3"`.
	 * @return  This `FlxSprite` instance (nice for chaining stuff together, if you're into that).
	 */
	public function makeGraphic(width:Int, height:Int, color = FlxColor.WHITE, unique = false, ?key:String):FlxSprite {
		final graph = FlxG.bitmap.create(width, height, color, unique, key);
		frames = graph.imageFrame;

		#if FLX_TRACK_GRAPHICS
		graph.trackingInfo = '$ID.makeGraphic($width, $height, ${color.toHexString()}, $unique, $key)';
		#end

		return this;
	}

	/**
 	 * This function creates a solid colored rectangular image dynamically.
 	 *
 	 * HaxeFlixel's graphic caching system keeps track of loaded image data.
 	 * When you make an identical copy of a previously used image, by default
 	 * HaxeFlixel copies the previous reference onto the pixels field instead
 	 * of creating another copy of the image data, to save memory.
 	 *
 	 * @param   Width    The width of the sprite you want to generate.
 	 * @param   Height   The height of the sprite you want to generate.
 	 * @param   Color    Specifies the color of the generated block (ARGB format).
 	 * @param   Unique   Whether the graphic should be a unique instance in the graphics cache. Default is `false`.
 	 *                   Set this to `true` if you want to modify the `pixels` field without changing the
 	 *                   `pixels` of other sprites with the same `BitmapData`.
 	 * @param   Key      An optional `String` key to identify this graphic in the cache.
 	 *                   If `null`, the key is determined by `Width`, `Height` and `Color`.
 	 *                   If `Unique` is `true` and a graphic with this `Key` already exists,
 	 *                   it is used as a prefix to find a new unique name like `"Key3"`.
 	 * @return  This `FlxSprite` instance (nice for chaining stuff together, if you're into that).
 	 */
	public function makeSolid(width:Float, height:Float, color = FlxColor.WHITE, unique = false, ?key:String):FlxSprite {
		final graph = FlxG.bitmap.create(1, 1, color, unique, key);
		frames = graph.imageFrame;
		antialiasing = false;

		#if FLX_TRACK_GRAPHICS
		graph.trackingInfo = '$ID.makeSolid($width, $height, ${color.toHexString()}, $unique, $key)';
		#end

		scale.set(width, height);
		updateHitbox();

		return this;
	}

	/**
	 * Called whenever a new graphic is loaded for this sprite (after `loadGraphic()`, `makeGraphic()` etc).
	 */
	public function graphicLoaded():Void {}

	/**
	 * Resets some internal variables used for frame `BitmapData` calculation.
	 */
	public inline function resetSize():Void {
		_flashRect.x = _flashRect.y = 0;
		_flashRect.width = frameWidth;
		_flashRect.height = frameHeight;
	}

	/**
	 * Resets frame size to frame dimensions.
	 */
	public inline function resetFrameSize():Void {
		if (frame != null) {
			frameWidth = Std.int(frame.sourceSize.x);
			frameHeight = Std.int(frame.sourceSize.y);
		}
		resetSize();
	}

	/**
	 * Resets sprite's size back to frame size.
	 */
	public inline function resetSizeFromFrame():Void {
		width = frameWidth;
		height = frameHeight;
	}

	/**
	 * Helper method just for convenience, so you don't need to type
	 * `sprite.frame = sprite.frame;`
	 * You may need this method in tile render mode,
	 * when you want sprite to use its original graphic, not the graphic generated from its `framePixels`.
	 */
	public inline function resetFrame():Void {
		frame = this.frame;
	}

	/**
	 * Helper function to set the graphic's dimensions by using `scale`, allowing you to keep the current aspect ratio
	 * should one of the numbers be `<= 0`. It might make sense to call `updateHitbox()` afterwards!
	 *
	 * @param   width    How wide the graphic should be. If `<= 0`, and `height` is set, the aspect ratio will be kept.
	 * @param   height   How high the graphic should be. If `<= 0`, and `width` is set, the aspect ratio will be kept.
	 */
	public function setGraphicSize(width = .0, ?height = .0):Void {
		if (width <= 0 && height <= 0) return;

		final newScaleX = width / frameWidth;
		final newScaleY = height / frameHeight;
		scale.set(newScaleX, newScaleY);

		if (width <= 0) scale.x = newScaleY;
		else if (height <= 0) scale.y = newScaleX;
	}

	/**
	 * Sets this sprite's `clipRect` so that, when rendered,
	 * will be clipped to the given world coordinates.
	 *
	 * **NOTE:** Does not work with most angles
	 * @since 6.2.0
	 */
	overload public inline extern function clipToWorldRect(x:Float, y:Float, width:Float, height:Float) {
		clipToWorldBounds(x, y, x + width, y + height);
	}

	/**
	 * Sets this sprite's `clipRect` so that, when rendered,
	 * will be clipped to the given screen rectangle.
	 *
	 * **NOTE:** Does not work with most angles
	 * @since 6.2.0
	 */
	overload public inline extern function clipToWorldRect(rect:FlxRect) {
		clipToWorldBounds(rect.x, rect.y, rect.x + rect.width, rect.y + rect.height);
	}

	/**
	 * Sets this sprite's `clipRect` so that, when rendered,
	 * will be clipped to the given world coordinates.
	 *
	 * **NOTE:** Does not work with most angles
	 * @since 6.2.0
	 */
	public function clipToWorldBounds(left:Float, top:Float, right:Float, bottom:Float) {
		clipRect ??= new FlxRect();

		final p1 = worldToFramePosition(left, top);
		final p2 = worldToFramePosition(right, bottom);

		clipRect.setBoundsAbs(p1.x, p1.y, p2.x, p2.y);
		p1.put();
		p2.put();
	}

	/**
	 * Sets this sprite's `clipRect` so that, when rendered, will be clipped to the given
	 * world coordinates. Same as `clipToWorldBounds` but never uses a camera, therefore
	 * `scrollFactor` is ignored
	 *
	 * **NOTE:** Does not work with most angles
	 * @since 6.2.0
	 */
	overload public inline extern function clipToWorldRectSimple(x:Float, y:Float, width:Float, height:Float) {
		clipToWorldBoundsSimple(x, y, x + width, y + height);
	}

	/**
	 * Sets this sprite's `clipRect` so that, when rendered, will be clipped to the given
	 * world coordinates. Same as `clipToWorldBounds` but never uses a camera, therefore
	 * `scrollFactor` is ignored
	 *
	 * **NOTE:** Does not work with most angles
	 * @since 6.2.0
	 */
	overload public inline extern function clipToWorldRectSimple(rect:FlxRect) {
		clipToWorldBoundsSimple(rect.x, rect.y, rect.x + rect.width, rect.y + rect.height);
	}

	/**
	 * Sets this sprite's `clipRect` so that, when rendered, will be clipped to the given
	 * world coordinates. Same as `clipToWorldBounds` but never uses a camera, therefore
	 * `scrollFactor` is ignored
	 *
	 * **NOTE:** Does not work with most angles
	 * @since 6.2.0
	 */
	public function clipToWorldBoundsSimple(left:Float, top:Float, right:Float, bottom:Float) {
		clipRect ??= new FlxRect();

		final p1 = worldToFrameSimpleHelper(left, top);
		final p2 = worldToFrameSimpleHelper(right, bottom);

		clipRect.setBoundsAbs(p1.x, p1.y, p2.x, p2.y);
		p1.put();
		p2.put();
	}

	/**
	 * Sets this sprite's `clipRect` so that, when rendered,
	 * will be clipped to the given screen coordinates.
	 *
	 * **NOTE:** Does not work with most angles
	 * @since 6.2.0
	 */
	overload public inline extern function clipToViewRect(x:Float, y:Float, width:Float, height:Float, ?camera:FlxCamera) {
		clipToViewBounds(x, y, x + width, y + height, camera);
	}

	/**
	 * Sets this sprite's `clipRect` so that, when rendered, will be clipped to the given
	 * screen rectangle. If `clipRect` is `null` a new instance is created
	 *
	 * **NOTE:** `clipRect` is not set to the passed in rect instance
	 *
	 * **NOTE:** Does not work with most angles
	 * @since 6.2.0
	 */
	overload public inline extern function clipToViewRect(rect:FlxRect, ?camera:FlxCamera) {
		clipToViewBounds(rect.left, rect.top, rect.right, rect.bottom, camera);
		rect.putWeak();
	}

	/**
	 * Sets this sprite's `clipRect` so that, when rendered,
	 * will be clipped to the given screen coordinates.
	 *
	 * **NOTE:** Does not work with most angles
	 * @since 6.2.0
	 */
	public function clipToViewBounds(left:Float, top:Float, right:Float, bottom:Float, ?camera:FlxCamera) {
		clipRect ??= new FlxRect();
		if (camera != null) camera = getDefaultCamera();

		final p1 = viewToFramePosition(left, top, camera);
		final p2 = viewToFramePosition(right, bottom, camera);

		clipRect.setBoundsAbs(p1.x, p1.y, p2.x, p2.y);
		p1.put();
		p2.put();
	}

	/**
	 * Updates the sprite's hitbox (`width`, `height`, `offset`) according to the current `scale`.
	 * Also calls `centerOrigin()`.
	 */
	public function updateHitbox():Void {
		width = Math.abs(scale.x) * frameWidth;
		height = Math.abs(scale.y) * frameHeight;
		offset.set(-.5 * (width - frameWidth), -.5 * (height - frameHeight));
		centerOrigin();
	}

	/**
	 * Resets some important variables for sprite optimization and rendering.
	 */
	@:noCompletion function resetHelpers():Void {
		resetFrameSize();
		resetSizeFromFrame();
		_flashRect2.x = _flashRect2.y = 0;

		if (graphic != null) {
			_flashRect2.width = graphic.width;
			_flashRect2.height = graphic.height;
		}

		centerOrigin();

		if (FlxG.render.blit) {
			dirty = true;
			updateFramePixels();
		}
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		updateAnimation(elapsed);
	}

	/**
	 * This is separated out so it can be easily overridden.
	 */
	function updateAnimation(elapsed:Float):Void {
		if (animation.curAnim == null || animation.curAnim.numFrames <= 1) return;
		animation.update(elapsed);
	}

	@:noCompletion function checkEmptyFrame() {
		if (_frame == null) loadGraphic(defaultHaxeFlixelLogo);
		else if (graphic != null && graphic.isDestroyed) {
			// switch graphic but log and preserve size
			final width = this.width;
			final height = this.height;

			FlxG.log.error('Cannot render a destroyed graphic, the placeholder image will be used instead');
			loadGraphic(defaultHaxeFlixelLogo);

			this.width = width;
			this.height = height;
		}
	}

	var isFrameNull(default, null) = true;

	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen.
	 */
	override public function draw():Void {
		if (__drawOverrided) {
			__drawOverrided = false;
			onDraw(this);
			__drawOverrided = true;
			return;
		}

		checkClipRect();

		if (isFrameNull) checkEmptyFrame();

		if (alpha == 0 || _frame.type == FlxFrameType.EMPTY) return;

		if (dirty) calcFrame(useFramePixels); // rarely

		for (camera in cameras) {
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;

			if (isSimpleRender(camera)) drawSimple(camera);
			else drawComplex(camera);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}

	/**
	 * Checks the previous frame's clipRect compared to the current. If there's changes, apply them
	 */
	function checkClipRect() {
		if (frames == null
		|| (clipRect == null && Math.isNaN(_lastClipRect.x))
		|| (clipRect != null && clipRect.equals(_lastClipRect)))
			return;

		// redraw frame
		frame = frames.frames[animation.frameIndex];

		if (clipRect == null)
			_lastClipRect.set(Math.NaN);
		else
			_lastClipRect.copyFrom(clipRect);
	}

	@:noCompletion function drawSimple(camera:FlxCamera):Void {
		getScreenPosition(_point, camera).subtract(offset);

		if (animation.curAnim != null) _point.subtractPoint(animation.curAnim.offset);
		if (isPixelPerfectRender(camera)) _point.floor();

		_point.copyTo(_flashPoint);
		camera.copyPixels(_frame, framePixels, _flashRect, _flashPoint, colorTransform, blend, antialiasing);
	}

	@:noCompletion function drawComplex(camera:FlxCamera):Void {
		drawFrameComplex(_frame, camera);
	}

	function drawFrameComplex(frame:FlxFrame, camera:FlxCamera):Void {
		final matrix = this._matrix; // TODO: Just use local?
		frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, checkFlipX() != camera.flipX, checkFlipY() != camera.flipY);
		matrix.translate(-origin.x, -origin.y);

		if (frameOffsetAngle != null && frameOffsetAngle != angle) {
			final angleOff = (frameOffsetAngle - angle) * FlxAngle.TO_RAD;
			final cos = FlxMath.fastCos(angleOff);
			final sin = FlxMath.fastSin(angleOff);
			// cos doesnt need to be negated
			_matrix.rotateWithTrig(cos, -sin);
			_matrix.translate(-frameOffset.x, -frameOffset.y);
			_matrix.rotateWithTrig(cos, sin);
		} else
			_matrix.translate(-frameOffset.x, -frameOffset.y);

		matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0) {
			updateTrig();
			if (angle != 0) matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		getScreenPosition(_point, camera).subtract(offset);
		if (animation.curAnim != null) _point.subtractPoint(animation.curAnim.offset);
		_point.add(origin.x, origin.y);
		matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera)) {
			matrix.tx = Math.floor(matrix.tx);
			matrix.ty = Math.floor(matrix.ty);
		}

		doAdditionalMatrixStuff(_matrix, camera);

		if (layer != null)
			layer.drawPixels(this, camera, frame, framePixels, matrix, colorTransform, blend, antialiasing, shaderEnabled ? shader : null);
		else
			camera.drawPixels(frame, framePixels, matrix, colorTransform, blend, antialiasing, shaderEnabled ? shader : null);
	}

	/**
 	 * Made in case developer wanna finalize stuff with the matrix.
 	 */
	public function doAdditionalMatrixStuff(matrix:FlxMatrix, camera:FlxCamera) {}

	/**
	 * Stamps / draws another `FlxSprite` onto this `FlxSprite`.
	 * This function is NOT intended to replace `draw()`!
	 *
	 * @param   brush   The sprite you want to use as a brush or stamp or pen or whatever.
	 * @param   x       The X coordinate of the brush's top left corner on this sprite.
	 * @param   y       They Y coordinate of the brush's top left corner on this sprite.
	 */
	public function stamp(brush:FlxSprite, x = 0, y = 0):Void {
		brush.drawFrame();

		if (graphic == null || brush.graphic == null)
			FlxG.log.critical("Cannot stamp to or from a FlxSprite with no graphics.");

		final bitmapData:BitmapData = brush.framePixels;

		if (isSimpleRender()) { // simple render
			_flashPoint.x = x + frame.frame.x;
			_flashPoint.y = y + frame.frame.y;
			_flashRect2.width = bitmapData.width;
			_flashRect2.height = bitmapData.height;
			graphic.bitmap.copyPixels(bitmapData, _flashRect2, _flashPoint, null, null, true);
			_flashRect2.width = graphic.bitmap.width;
			_flashRect2.height = graphic.bitmap.height;
		} else { // complex render
			_matrix.identity();
			_matrix.translate(-brush.origin.x, -brush.origin.y);
			_matrix.scale(brush.scale.x, brush.scale.y);
			if (brush.angle != 0) _matrix.rotate(brush.angle * FlxAngle.TO_RAD);
			_matrix.translate(x + frame.frame.x + brush.origin.x, y + frame.frame.y + brush.origin.y);
			final brushBlend:BlendMode = brush.blend;
			graphic.bitmap.draw(bitmapData, _matrix, null, brushBlend, null, brush.antialiasing);
		}

		if (FlxG.render.blit) {
			dirty = true;
			calcFrame();
		}
	}

	/**
	 * Request (or force) that the sprite update the frame before rendering.
	 * Useful if you are doing procedural generation or other weirdness!
	 *
	 * @param   force   Force the frame to redraw, even if its not flagged as necessary.
	 */
	public function drawFrame(force = false):Void {
		if (FlxG.render.blit) {
			if (force || dirty) {
				dirty = true;
				calcFrame();
			}
		} else {
			dirty = true;
			calcFrame(true);
		}
	}

	/**
	 * Helper function that adjusts the offset automatically to center the bounding box within the graphic.
	 *
	 * @param   adjustPosition   Adjusts the actual X and Y position just once to match the offset change.
	 */
	public function centerOffsets(adjustPosition = false):Void {
		offset.x = (frameWidth - width) * .5;
		offset.y = (frameHeight - height) * .5;
		if (adjustPosition) {
			x += offset.x;
			y += offset.y;
		}
	}

	/**
	 * Sets the sprite's origin to its center - useful after adjusting
	 * `scale` to make sure rotations work as expected.
	 */
	public inline function centerOrigin():Void {
		origin.set(frameWidth * .5, frameHeight * .5);
	}

	/**
	 * Replaces all pixels with specified `Color` with `NewColor` pixels.
	 * WARNING: very expensive (especially on big graphics) as it iterates over every single pixel.
	 *
	 * @param   color            Color to replace
	 * @param   NewColor         New color
	 * @param   fetchPositions   Whether we need to store positions of pixels which colors were replaced.
	 * @return  `Array` with replaced pixels positions
	 */
	public function replaceColor(color:FlxColor, newColor:FlxColor, fetchPositions = false):Array<FlxPoint> {
		final positions = FlxBitmapDataUtil.replaceColor(graphic.bitmap, color, newColor, fetchPositions);
		if (positions != null) dirty = true;
		return positions;
	}

	/**
	 * Sets the sprite's color transformation with control over color offsets.
	 * With `FlxG.render.tile`, offsets are only supported on OpenFL Next version 3.6.0 or higher.
	 *
	 * @param   redMultiplier     The value for the red multiplier, in the range from `0` to `1`.
	 * @param   greenMultiplier   The value for the green multiplier, in the range from `0` to `1`.
	 * @param   blueMultiplier    The value for the blue multiplier, in the range from `0` to `1`.
	 * @param   alphaMultiplier   The value for the alpha transparency multiplier, in the range from `0` to `1`.
	 * @param   redOffset         The offset value for the red color channel, in the range from `-255` to `255`.
	 * @param   greenOffset       The offset value for the green color channel, in the range from `-255` to `255`.
	 * @param   blueOffset        The offset for the blue color channel value, in the range from `-255` to `255`.
	 * @param   alphaOffset       The offset for alpha transparency channel value, in the range from `-255` to `255`.
	 */
	public function setColorTransform(redMultiplier = 1., greenMultiplier = 1., blueMultiplier = 1., alphaMultiplier = 1., redOffset = .0, greenOffset = .0, blueOffset = .0, alphaOffset = .0):Void {
		colorTransform ??= new ColorTransform();

		@:bypassAccessor color = FlxColor.fromRGBFloat(redMultiplier, greenMultiplier, blueMultiplier, 1.0);
		@:bypassAccessor alpha = alphaMultiplier;

		colorTransform.setMultipliers(redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);
		colorTransform.setOffsets(redOffset, greenOffset, blueOffset, alphaOffset);

		dirty = true;
	}

	function updateColorTransform():Void {
		colorTransform ??= new ColorTransform();

		colorTransform.setMultipliers(color.redFloat, color.greenFloat, color.blueFloat, alpha);
		dirty = true;
	}

	/**
	 * Whether this sprite has a color transform, menaing any of the following: less than full
	 * `alpha`, a `color` tint, or a `colorTransform` whos values are not the default.
	 */
	function hasColorTransform() {
		return alpha != 1 || color.rgb != 0xffffff || colorTransform.hasRGBAOffsets();
	}

	/**
	 * Checks to see if a point in 2D world space overlaps this `FlxSprite` object's
	 * current displayed pixels. This check is ALWAYS made in screen space, and
	 * factors in `scale`, `angle`, `offset`, `origin`, and `scrollFactor`.
	 *
	 * @param   worldPoint      point in world space you want to check.
	 * @param   alphaTolerance  Used to determine what counts as solid.
	 * @param   camera          The desired "screen" coordinate space. If `null`, `getDefaultCamera()` is used.
	 * @return  Whether or not the point overlaps this object.
	 */
	public function pixelsOverlapPoint(worldPoint:FlxPoint, alphaTolerance = 0xFF, ?camera:FlxCamera):Bool {
		final pixelColor = getPixelAt(worldPoint, camera);

		if (pixelColor != null) return pixelColor.alpha * alpha >= alphaTolerance;

		// point is outside of the graphic
		return false;
	}

	/**
	 * Helper to apply the sprite's color or colorTransform to the specified color
	 */
	function transformColor(colorIn:FlxColor):FlxColor {
		final colorStr = color.toHexString();
		if (hasColorTransform()) {
			final ct = colorTransform;
			return FlxColor.fromRGB(Math.round(colorIn.red * ct.redMultiplier + ct.redOffset),
				Math.round(colorIn.green * ct.greenMultiplier + ct.greenOffset), Math.round(colorIn.blue * ct.blueMultiplier + ct.blueOffset),
				Math.round(colorIn.alpha * alpha));
		}

		final WHITE_COLOR = 0xffffff;
		if (color.rgb != WHITE_COLOR) {
			final result = FlxColor.fromRGBFloat(colorIn.redFloat * color.redFloat, colorIn.greenFloat * color.greenFloat,
				colorIn.blueFloat * color.blueFloat, colorIn.alphaFloat * alpha);
			return result;
		}

		return colorIn;
	}

	/**
	 * Determines which of this sprite's pixels are at the specified world coordinate, if any.
	 * Factors in `scale`, `angle`, `offset`, `origin`, `scrollFactor`, `flipX` and `flipY`.
	 *
	 * @param  worldPoint  The point in world space
	 * @param  camera      The camera, used for `scrollFactor`. If `null`, `getDefaultCamera()` is used.
	 * @return a `FlxColor`, if the point is in the sprite's graphic, otherwise `null` is returned.
	 * @since 5.0.0
	 */
	public function getPixelAt(worldPoint:FlxPoint, ?camera:FlxCamera):Null<FlxColor> {
		final point = worldToFramePosition(worldPoint, camera, FlxPoint.weak());
		final overlaps = point.x >= 0 && point.x <= frameWidth && point.y >= 0 && point.y <= frameHeight;
		if (!overlaps) {
			point.put();
			return null;
		}

		return transformColor(frame.getPixelAt(point));
	}

	/**
	 * Determines which of this sprite's pixels are at the specified screen coordinate, if any.
	 * Factors in `scale`, `angle`, `offset`, `origin`, and `scrollFactor`.
	 *
	 * @param  screenPoint  The point in screen space
	 * @param  camera       The desired "screen" coordinate space. If `null`, `getDefaultCamera()` is used.
	 * @return a `FlxColor`, if the point is in the sprite's graphic, otherwise `null` is returned.
	 * @since 5.0.0
	 */
	public function getPixelAtScreen(screenPoint:FlxPoint, ?camera:FlxCamera):Null<FlxColor> {
		final point = viewToFramePosition(screenPoint, camera);

		final overlaps = point.x >= 0 && point.x <= frameWidth && point.y >= 0 && point.y <= frameHeight;
		final result = overlaps ? frame.getPixelAt(point) : null;

		point.put();
		return result;
	}

	/**
	 * Converts the point from world coordinates to this sprite's frame coordinates where (0,0)
	 * is the top left of the frame. Factors in `scale`, `angle`, `offset`, `origin`,
	 * `scrollFactor`, `flipX` and `flipY`.
	 *
	 * @param   worldPos  The world coordinates
	 * @param   camera    The camera, used for `scrollFactor`. If `null`, `getDefaultCamera()` is used
	 * @param   result    Optional arg for the returning point
	 * @since 6.2.0
	 */
	overload public inline extern function worldToFramePosition(worldPos:FlxPoint, ?camera:FlxCamera, ?result:FlxPoint):FlxPoint {
		result = worldToFrameHelper(worldPos.x, worldPos.y, camera, result);
		worldPos.putWeak();
		return result;
	}

	/**
	 * Converts the point from world coordinates to this sprite's frame coordinates where (0,0)
	 * is the top left of the frame. Factors in `scale`, `angle`, `offset`, `origin`,
	 * `scrollFactor`, `flipX` and `flipY`.
	 *
	 * @param   worldX    The world coordinates
	 * @param   worldY    The world coordinates
	 * @param   camera    The camera, used for `scrollFactor`. If `null`, `getDefaultCamera()` is used
	 * @param   result    Optional arg for the returning point
	 * @since 6.2.0
	 */
	overload public inline extern function worldToFramePosition(worldX:Float, worldY:Float, ?camera:FlxCamera, ?result:FlxPoint):FlxPoint {
		return worldToFrameHelper(worldX, worldY, camera, result);
	}

	function worldToFrameHelper(worldX:Float, worldY:Float, ?camera:FlxCamera, ?result:FlxPoint):FlxPoint {
		camera ??= getDefaultCamera();

		// get the screen pos without scrollFactor, then get the world, WITH scrollFactor
		return viewToFrameHelper(camera.worldToViewX(worldX), camera.worldToViewY(worldY), camera, result);
	}

	/**
	 * Converts the point from world coordinates to this sprite's frame coordinates where (0,0)
	 * is the top left of the frame. Same as `worldToFrameCoord` but never uses a camera,
	 * therefore `scrollFactor` is ignored
	 *
	 * @param   worldPos  The world coordinates.
	 * @param   result    Optional arg for the returning point
	 * @since 6.2.0
	 */
	overload public inline extern function worldToFramePositionSimple(worldPos:FlxPoint, ?result:FlxPoint):FlxPoint {
		result = worldToFrameSimpleHelper(worldPos.x, worldPos.y, result);
		worldPos.putWeak();
		return result;
	}

	/**
	 * Converts the point from world coordinates to this sprite's frame coordinates where (0,0)
	 * is the top left of the frame. Same as `worldToFrameCoord` but never uses a camera,
	 * therefore `scrollFactor` is ignored
	 *
	 * @param   worldX    The world coordinates.
	 * @param   worldY    The world coordinates.
	 * @param   result    Optional arg for the returning point
	 * @since 6.2.0
	 */
	overload public inline extern function worldToFramePositionSimple(worldX:Float, worldY:Float, ?result:FlxPoint):FlxPoint {
		return worldToFrameSimpleHelper(worldX, worldY, result);
	}

	function worldToFrameSimpleHelper(worldX:Float, worldY:Float, ?result:FlxPoint):FlxPoint {
		result ??= FlxPoint.get();

		result.set(worldX - x, worldY - y);
		result.add(offset);
		result.subtract(origin);
		result.scale(1 / scale.x, 1 / scale.y);
		result.degrees -= angle;
		result.add(origin);

		final animFlipX = animation.curAnim != null && animation.curAnim.flipX;
		if (flipX != animFlipX) result.x = frameWidth - result.x;

		final animFlipY = animation.curAnim != null && animation.curAnim.flipY;
		if (flipY != animFlipY) result.y = frameHeight - result.y;

		return result;
	}

	/**
	 * Converts the point from camera coordinates to this sprite's frame coordinates where (0,0)
	 * is the top left of the camera's frame. Factors in `scale`, `angle`, `offset`, `origin`,
	 * `scrollFactor`, `flipX` and `flipY`.
	 *
	 * @param   viewPoint  The coordinates in the camera's view
	 * @param   camera     The desired "screen" space. If `null`, `getDefaultCamera()` is used
	 * @param   result     Optional arg for the returning point
	 * @since 6.2.0
	 */
	overload public inline extern function viewToFramePosition(viewPoint:FlxPoint, ?camera:FlxCamera, ?result:FlxPoint):FlxPoint {
		result = viewToFrameHelper(viewPoint.x, viewPoint.y, camera, result);
		viewPoint.putWeak();
		return result;
	}

	/**
	 * Converts the point from camera coordinates to this sprite's frame coordinates where (0,0)
	 * is the top left of the camera's frame. Factors in `scale`, `angle`, `offset`, `origin`,
	 * `scrollFactor`, `flipX` and `flipY`.
	 *
	 * @param   viewX   The coordinates in the camera's view
	 * @param   viewY   The coordinates in the camera's view
	 * @param   camera  The desired "screen" space. If `null`, `getDefaultCamera()` is used
	 * @param   result  Optional arg for the returning point
	 * @since 6.2.0
	 */
	overload public inline extern function viewToFramePosition(viewX:Float, viewY:Float, ?camera:FlxCamera, ?result:FlxPoint):FlxPoint {
		return viewToFrameHelper(viewX, viewY, camera, result);
	}

	function viewToFrameHelper(viewX:Float, viewY:Float, ?camera:FlxCamera, ?result:FlxPoint):FlxPoint {
		camera ??= this.getDefaultCamera();

		result = camera.viewToWorldPosition(viewX, viewY, scrollFactor, result);
		result.subtract(x, y);

		result.add(offset);
		result.subtract(origin);
		result.scale(1 / scale.x, 1 / scale.y);
		result.degrees -= angle;
		result.add(origin);

		final animFlipX = animation.curAnim != null && animation.curAnim.flipX;
		if (flipX != animFlipX) result.x = frameWidth - result.x;

		final animFlipY = animation.curAnim != null && animation.curAnim.flipY;
		if (flipY != animFlipY) result.y = frameHeight - result.y;

		return result;
	}

	/**
	 * Internal function to update the current animation frame.
	 *
	 * @param   force   Whether the frame should also be recalculated
	 */
	@:noCompletion function calcFrame(force = false):Void {
		checkEmptyFrame();

		if (FlxG.render.tile && !force) return;

		updateFramePixels();
	}

	/**
	 * Retrieves the `BitmapData` of the current `FlxFrame`. Updates `framePixels`.
	 */
	public function updateFramePixels():BitmapData {
		if (_frame == null || !dirty) return framePixels;

		// don't try to regenerate frame pixels if _frame already uses it as source of graphics
		// if you'll try then it will clear framePixels and you won't see anything
		if (FlxG.render.tile && _frameGraphic != null) {
			dirty = false;
			return framePixels;
		}

		final doFlipX = checkFlipX();
		final doFlipY = checkFlipY();

		if (!doFlipX && !doFlipY && _frame.type == FlxFrameType.REGULAR)
			framePixels = _frame.paint(framePixels, _flashPointZero, false, true);
		else
			framePixels = _frame.paintRotatedAndFlipped(framePixels, _flashPointZero, FlxFrameAngle.ANGLE_0, doFlipX, doFlipY, false, true);

		if (FlxG.render.blit && hasColorTransform())
			framePixels.colorTransform(_flashRect, colorTransform);

		if (FlxG.render.tile && useFramePixels) {
			// recreate _frame for native target, so it will use modified framePixels
			_frameGraphic = FlxGraphic.fromBitmapData(framePixels, false, null, false);
			_frame = _frameGraphic.imageFrame.frame.copyTo(_frame);
			isFrameNull = false;
		}

		dirty = false;
		return framePixels;
	}

	/**
	 * Retrieve the midpoint of this sprite's graphic in world coordinates.
	 *
	 * @param   point  The resulting point, if `null` a new one is created
	 */
	public function getGraphicMidpoint(?point:FlxPoint):FlxPoint {
		final rect = getGraphicBounds();
		point = rect.getMidpoint(point);
		rect.put();
		return point;
	}

	/**
	 * Retrieves the world bounds of this sprite's graphic
	 * **Note:** Ignores `scrollFactor`, to get the screen position of the graphic use
	 * `getScreenBounds`
	 *
	 * @param   rect  The resulting rect, if `null` a new one is created
	 * @since 5.9.0
	 */
	public function getGraphicBounds(?rect:FlxRect):FlxRect {
		rect ??= FlxRect.get();

		rect.set(x, y);
		if (pixelPerfectPosition) rect.floor();

		_scaledOrigin.set(origin.x * scale.x, origin.y * scale.y);
		rect.x += origin.x - offset.x - _scaledOrigin.x;
		rect.y += origin.y - offset.y - _scaledOrigin.y;
		rect.setSize(frameWidth * scale.x, frameHeight * scale.y);

		if (angle % 360 != 0)
			rect.getRotatedBounds(angle, _scaledOrigin, rect);

		return rect;
	}

	/**
	 * Check and see if this object is currently on screen. Differs from `FlxObject`'s implementation
	 * in that it takes the actual graphic into account, not just the hitbox or bounding box or whatever.
	 *
	 * @param   camera  Specify which game camera you want. If `null`, `getDefaultCamera()` is used.
	 * @return  Whether the object is on screen or not.
	 */
	override public function isOnScreen(?camera:FlxCamera):Bool {
		if (forceIsOnScreen) return true;

		camera ??= getDefaultCamera();

		return camera.containsRect(getScreenBounds(_rect, camera));
	}

	/**
	 * Returns the result of `isSimpleRenderBlit()` if `FlxG.render.blit` is
	 * `true`, or `false` if `FlxG.render.tile` is `true`.
	 */
	public function isSimpleRender(?camera:FlxCamera):Bool {
		if (FlxG.render.tile) return false;

		return isSimpleRenderBlit(camera);
	}

	/**
	 * Determines the function used for rendering in blitting:
	 * `copyPixels()` for simple sprites, `draw()` for complex ones.
	 * Sprites are considered simple when they have an `angle` of `0`, a `scale` of `1`,
	 * don't use `blend` and `pixelPerfectRender` is `true`.
	 *
	 * @param   camera   If a camera is passed its `pixelPerfectRender` flag is taken into account
	 */
	public function isSimpleRenderBlit(?camera:FlxCamera):Bool {
		var result = (angle == 0 || bakedRotationAngle > 0) && scale.x == 1 && scale.y == 1 && blend == null;
		result = result && (camera != null ? isPixelPerfectRender(camera) : pixelPerfectRender);
		return result;
	}

	/**
	 * Calculates the smallest globally aligned bounding box that encompasses this
	 * sprite's width and height, at its current rotation.
	 * Note, if called on a `FlxSprite`, the origin is used, but scale and offset are ignored.
	 * Use `getScreenBounds` to use these properties.
	 * @param newRect The optional output `FlxRect` to be returned, if `null`, a new one is created.
	 * @return A globally aligned `FlxRect` that fully contains the input object's width and height.
	 * @since 4.11.0
	 */
	override function getRotatedBounds(?newRect:FlxRect) {
		newRect ??= FlxRect.get();

		newRect.set(x, y, width, height);
		return newRect.getRotatedBounds(angle, origin, newRect);
	}

	/**
	 * Calculates the smallest globally aligned bounding box that encompasses this sprite's graphic as it
	 * would be displayed. Honors scrollFactor, rotation, scale, offset and origin.
	 * @param newRect Optional output `FlxRect`, if `null`, a new one is created.
	 * @param camera  Optional camera used for scrollFactor, if null `getDefaultCamera()` is used.
	 * @return A globally aligned `FlxRect` that fully contains the input sprite.
	 * @since 4.11.0
	 */
	public function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect {
		newRect ??= FlxRect.get();
		camera ??= getDefaultCamera();

		newRect.setPosition(x, y);

		if (pixelPerfectPosition) newRect.floor();

		_scaledOrigin.set(origin.x * Math.abs(scale.x), origin.y * Math.abs(scale.y));
		_scaledFrameOffset.set(frameOffset.x * scale.x, frameOffset.y * scale.y);

		newRect.x += -Std.int(camera.scroll.x * scrollFactor.x) - offset.x + origin.x - _scaledOrigin.x;
		newRect.y += -Std.int(camera.scroll.y * scrollFactor.y) - offset.y + origin.y - _scaledOrigin.y;

		if (animation.curAnim != null) {
			newRect.x -= animation.curAnim.offset.x;
			newRect.y -= animation.curAnim.offset.y;
		}

		if (isPixelPerfectRender(camera)) newRect.floor();
		newRect.setSize(frameWidth * Math.abs(scale.x), frameHeight * Math.abs(scale.y));
		return newRect.getRotatedBounds(angle, _scaledOrigin, newRect, _scaledFrameOffset);
	}

	/**
	 * Set how a sprite flips when facing in a particular direction.
	 *
	 * @param   direction   Use constants `LEFT`, `RIGHT`, `UP`, and `DOWN`.
	 *                      These may be combined with the bitwise OR operator.
	 *                      E.g. To make a sprite flip horizontally when it is facing both `UP` and `LEFT`,
	 *                      use `setFacingFlip(LEFT | UP, true, false);`
	 * @param   flipX       Whether to flip the sprite on the X axis.
	 * @param   flipY       Whether to flip the sprite on the Y axis.
	 */
	public inline function setFacingFlip(direction:FlxDirectionFlags, flipX:Bool, flipY:Bool):Void {
		_facingFlip.set(direction, {x: flipX, y: flipY});
	}

	/**
	 * Sets frames and allows you to save animations in sprite's animation controller
	 *
	 * @param   frames           Frames collection to set for this sprite.
	 * @param   saveAnimations   Whether to save animations in animation controller or not.
	 * @return  This sprite with loaded frames
	 */
	@:access(flixel.animation.FlxAnimationController)
	public function setFrames(frames:FlxFramesCollection, saveAnimations = true):FlxSprite {
		if (saveAnimations) {
			final animations = animation._animations;
			var reverse = false;
			var index = 0;
			final frameIndex = animation.frameIndex;
			var currName:String = null;

			if (animation.curAnim != null) {
				reverse = animation.curAnim.reversed;
				index = animation.curAnim.curFrame;
				currName = animation.curAnim.name;
			}

			animation._animations = null;
			this.frames = frames;
			frame = this.frames.frames[frameIndex];
			animation._animations = animations;

			if (currName != null)
				animation.play(currName, false, reverse, index);
		} else
			this.frames = frames;

		return this;
	}

	@:noCompletion function get_pixels():BitmapData {
		return (graphic == null) ? null : graphic.bitmap;
	}

	@:noCompletion function set_pixels(pixels:BitmapData):BitmapData {
		var key:String = FlxG.bitmap.findKeyForBitmap(pixels);

		if (key == null) {
			key = FlxG.bitmap.getUniqueKey();
			graphic = FlxG.bitmap.add(pixels, false, key);
		} else
			graphic = FlxG.bitmap.get(key);

		frames = graphic.imageFrame;
		return pixels;
	}

	@:noCompletion function set_frame(value:FlxFrame):FlxFrame {
		frame = value;
		if (frame != null) {
			resetFrameSize();
			dirty = true;
		} else if (frames != null && frames.frames != null && numFrames > 0) {
			frame = frames.frames[0];
			dirty = true;
		} else
			return null;

		if (FlxG.render.tile)
			_frameGraphic = FlxDestroyUtil.destroy(_frameGraphic);

		_frame = frame.copyTo(_frame);
		if (clipRect != null)
			_frame.clip(clipRect);

		isFrameNull = false;

		return frame;
	}

	@:noCompletion function set_facing(direction:FlxDirectionFlags):FlxDirectionFlags {
		final flip = _facingFlip.get(direction);
		if (flip != null) {
			flipX = flip.x;
			flipY = flip.y;
		}

		return facing = direction;
	}

	@:noCompletion function set_alpha(alpha:Float):Float {
		alpha = FlxMath.bound(alpha, 0, 1);
		if (this.alpha == alpha) return alpha;
		this.alpha = alpha;
		updateColorTransform();
		return this.alpha;
	}

	@:noCompletion function set_color(Color:FlxColor):Int {
		if (this.color == color) return color;
		this.color = color;
		updateColorTransform();
		return this.color;
	}

	@:noCompletion override function set_angle(value:Float):Float {
		final newAngle = (angle != value);
		final ret = super.set_angle(value);
		if (newAngle) {
			_angleChanged = true;
			animation.update(0);
		}
		return ret;
	}

	@:noCompletion inline function updateTrig():Void {
		if (_angleChanged) {
			final radians = angle * FlxAngle.TO_RAD;
			_sinAngle = FlxMath.fastSin(radians);
			_cosAngle = FlxMath.fastCos(radians);
			_angleChanged = false;
		}
	}

	@:noCompletion function set_blend(value:BlendMode):BlendMode {
		return blend = value;
	}

	@:noCompletion function set_shader(value:FlxShader):FlxShader {
		return shader = value;
	}

	/**
	 * Internal function for setting graphic property for this object.
	 * Changes the graphic's `useCount` for better memory tracking.
	 */
	@:noCompletion function set_graphic(value:FlxGraphic):FlxGraphic {
		if (graphic != value) {
			// If new graphic is not null, increase its use count
			value?.incrementUseCount();

			// If old graphic is not null, decrease its use count
			graphic?.decrementUseCount();

			graphic = value;
		}

		return value;
	}

	@:noCompletion function set_clipRect(rect:FlxRect):FlxRect {
		clipRect = rect;

		return rect;
	}

	@:noCompletion function set_rawClipRect(rect:FlxRect):FlxRect {
		@:bypassAccessor clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}

	@:noCompletion inline function get_rawClipRect():FlxRect {
		return clipRect;
	}

	/**
	 * Frames setter. Used by `loadGraphic` methods, but you can load generated frames yourself
	 * (this should be even faster since engine doesn't need to do bunch of additional stuff).
	 *
	 * @param   Frames   frames to load into this sprite.
	 * @return  loaded frames.
	 */
	@:noCompletion function set_frames(frames:FlxFramesCollection):FlxFramesCollection {
		animation?.destroyAnimations();

		if (frames != null) {
			graphic = frames.parent;
			this.frames = frames;
			frame = frames.getByIndex(0);
			resetHelpers();
			bakedRotationAngle = 0;
			animation.frameIndex = 0;
			graphicLoaded();
		} else {
			this.frames = null;
			frame = null;
			graphic = null;
		}

		return frames;
	}

	function get_numFrames() {
		if (frames != null)
			return frames.numFrames;

		return 0;
	}

	@:noCompletion function set_flipX(value:Bool):Bool {
		if (FlxG.render.tile)
			_facingHorizontalMult = value ? -1 : 1;

		dirty = (flipX != value) || dirty;
		return flipX = value;
	}

	@:noCompletion function set_flipY(value:Bool):Bool {
		if (FlxG.render.tile)
			_facingVerticalMult = value ? -1 : 1;

		dirty = (flipY != value) || dirty;
		return flipY = value;
	}

	@:noCompletion function set_antialiasing(value:Bool):Bool {
		return antialiasing = value;
	}

	@:noCompletion function set_useFramePixels(value:Bool):Bool {
		if (FlxG.render.tile) {
			if (value != useFramePixels) {
				useFramePixels = value;
				resetFrame();

				if (value) updateFramePixels();
			}

			return value;
		} else {
			useFramePixels = true;
			return true;
		}
	}

	@:noCompletion inline function checkFlipX():Bool {
		final doFlipX = (flipX != _frame.flipX);
		if (animation.curAnim != null)
			return doFlipX != animation.curAnim.flipX;
		return doFlipX;
	}

	@:noCompletion inline function checkFlipY():Bool {
		final doFlipY = (flipY != _frame.flipY);
		if (animation.curAnim != null)
			return doFlipY != animation.curAnim.flipY;
		return doFlipY;
	}
}

interface IFlxSprite extends IFlxBasic {
	var x(default, set):Float;
	var y(default, set):Float;
	var alpha(default, set):Float;
	var angle(default, set):Float;
	var facing(default, set):FlxDirectionFlags;
	var moves(default, set):Bool;
	var immovable(default, set):Bool;

	var offset(default, null):FlxPoint;
	var origin(default, null):FlxPoint;
	var scale(default, null):FlxPoint;
	var velocity(default, null):FlxPoint;
	var maxVelocity(default, null):FlxPoint;
	var acceleration(default, null):FlxPoint;
	var drag(default, null):FlxPoint;
	var scrollFactor(default, null):FlxPoint;

	function reset(X:Float, Y:Float):Void;
	function setPosition(X = .0, Y = 0.):Void;
}

typedef FlxSpriteFacingFlipDynamic = {x:Bool, y:Bool}

abstract FlxSpriteFacingFlip(#if macro Int #else ByteUInt #end) #if !macro from ByteUInt to ByteUInt #end from Int to Int {
	public var x(get, set):Bool;
	public var y(get, set):Bool;

	public function new(x = false, y = false) {
		this = 0;
		set_x(x);
		set_y(y);
	}

	@:noCompletion inline function get_x():Bool {
		return this & 0x01 == 0x01;
	}

	@:noCompletion inline function set_x(i:Bool):Bool {
		if (i) this |= 0x01;
		else this &= 0xF0;

		return i;
	}

	@:noCompletion inline function get_y():Bool {
		return this & 0x10 == 0x10;
	}

	@:noCompletion inline function set_y(i:Bool):Bool {
		if (i) this |= 0x10;
		else this &= 0x0F;

		return i;
	}

	@:from static function fromDynamic(i:FlxSpriteFacingFlipDynamic):FlxSpriteFacingFlip {
		return new FlxSpriteFacingFlip(i.x, i.y);
	}

	@:to function toDynamic():FlxSpriteFacingFlipDynamic {
		return {x: x, y: y};
	}
}