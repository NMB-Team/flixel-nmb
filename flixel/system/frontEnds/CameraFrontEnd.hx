package flixel.system.frontEnds;

import openfl.geom.Rectangle;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSignal.FlxTypedSignal;

using flixel.util.FlxArrayUtil;

/**
 * Accessed via `FlxG.cameras`.
 */
class CameraFrontEnd
{
	/**
	 * An array listing FlxCamera objects that are used to draw stuff.
	 * By default flixel creates one camera the size of the screen.
	 * Do not edit directly, use `add` and `remove` instead.
	 */
	public var list(default, null):Array<FlxCamera> = [];

	/**
	 * Array listing all cameras marked as default draw targets, `FlxBasics` with no
	 *`cameras` set will render to them.
	 */
	var defaults:Array<FlxCamera> = [];

	/**
	 * The current (global, applies to all cameras) bgColor.
	 */
	public var bgColor(default, set):FlxColor;

	/** @since 4.2.0 */
	public var cameraAdded(default, null):FlxTypedSignal<FlxCamera->Void> = new FlxTypedSignal<FlxCamera->Void>();

	/** @since 4.2.0 */
	public var cameraRemoved(default, null):FlxTypedSignal<FlxCamera->Void> = new FlxTypedSignal<FlxCamera->Void>();

	/** @since 6.2.0 */
	public var preCameraResized(default, null):FlxTypedSignal<FlxCamera->Void> = new FlxTypedSignal<FlxCamera->Void>();

	/** @since 4.2.0 */
	public var cameraResized(default, null):FlxTypedSignal<FlxCamera->Void> = new FlxTypedSignal<FlxCamera->Void>();

	/** @since 6.2.0 */
	public var cameraReset(default, null):FlxTypedSignal<FlxCamera->Void> = new FlxTypedSignal<FlxCamera->Void>();

	/** @since 6.2.0 */
	public var cameraResetPost(default, null):FlxTypedSignal<FlxCamera->Void> = new FlxTypedSignal<FlxCamera->Void>();

	/**
	 * Allows you to possibly slightly optimize the rendering process IF
	 * you are not doing any pre-processing in your game state's draw() call.
	 */
	public var useBufferLocking:Bool = false;

	/**
	 * Internal helper variable for clearing the cameras each frame.
	 */
	var _cameraRect:Rectangle = new Rectangle();

	/**
	 * Add a new camera object to the game.
	 * Handy for PiP, split-screen, etc.
	 * @see flixel.FlxBasic.cameras
	 *
	 * @param	newCamera         The camera you want to add.
	 * @param	defaultDrawTarget Whether to add the camera to the list of default draw targets. If false,
	 *                            `FlxBasics` will not render to it unless you add it to their `cameras` list.
	 * @return	This FlxCamera instance.
	 */
	public function add<T:FlxCamera>(newCamera:T, defaultDrawTarget:Bool = true):T
	{
		FlxG.game.addChildAt(newCamera.flashSprite, FlxG.game.getChildIndex(FlxG.game._inputContainer));

		list.push(newCamera);
		if (defaultDrawTarget)
			defaults.push(newCamera);

		newCamera.ID = list.length - 1;
		cameraAdded.dispatch(newCamera);
		return newCamera;
	}

	/**
	 * Inserts a new camera object to the game.
	 *
	 * - If `position` is negative, `list.length + position` is used
	 * - If `position` exceeds `list.length`, the camera is added to the end.
	 *
	 * @param	newCamera         The camera you want to add.
	 * @param	position          The position in the list where you want to insert the camera
	 * @param	defaultDrawTarget Whether to add the camera to the list of default draw targets. If false,
	 *                            `FlxBasics` will not render to it unless you add it to their `cameras` list.
	 * @return	This FlxCamera instance.
	 */
	public function insert<T:FlxCamera>(newCamera:T, position:Int, defaultDrawTarget = true):T
	{
		// negative numbers are relative to the length (match Array.insert's behavior)
		if (position < 0)
			position += list.length;

		// invalid ranges are added (match Array.insert's behavior)
		if (position >= list.length)
			return add(newCamera);

		final childIndex = FlxG.game.getChildIndex(list[position].flashSprite);
		FlxG.game.addChildAt(newCamera.flashSprite, childIndex);

		list.insert(position, newCamera);
		if (defaultDrawTarget)
			defaults.push(newCamera);

		for (i in position...list.length)
			list[i].ID = i;

		cameraAdded.dispatch(newCamera);
		return newCamera;
	}

	public function removeAtIndex(index:Int, destroy:Bool = true)
	{
		var camera:FlxCamera = list[index];
		if (camera != null)
		{
			remove(camera, destroy);
		}
	}

	/**
	 * Remove a camera from the game.
	 *
	 * @param   camera    The camera you want to remove.
	 * @param   destroy   Whether to call destroy() on the camera, default value is true.
	 */
	public function remove(camera:FlxCamera, destroy:Bool = true):Void
	{
		final index:Int = list.indexOf(camera);
		if (index == -1 || camera == null)
		{
			FlxG.log.warn("FlxG.cameras.remove(): The camera you attempted to remove is not a part of the game.");
			return;
		}
		removeAt(index, destroy);
	}

	/**
	 * Set the order of the cameras.
	 *
	 * @param   order     The order of the cameras.
	 * @param   defaults  The default draw targets. (If null, the first camera will be used as default.)
	 * @param   destroy   Whether to destroy the removed cameras. Default value is false.
	**/
	public function setOrder(order:Array<FlxCamera>, ?defaults:Null<Array<FlxCamera>>, ?destroy:Bool = false):Void
	{
		for (camera in list)
		{
			FlxG.game.removeChild(camera.flashSprite);

			if (!order.contains(camera))
			{
				if (destroy)
					camera.destroy();
				cameraRemoved.dispatch(camera);
			}
		}
		var oldList = this.list.copy();
		this.list.resize(0); // clear but keep references
		this.defaults.resize(0);

		for (i => camera in order)
		{
			if (camera == null)
			{
				FlxG.log.warn('FlxG.cameras.setOrder(): Camera at index $i is null.');
				continue;
			}
			FlxG.game.addChildAt(camera.flashSprite, FlxG.game.getChildIndex(FlxG.game._inputContainer));
			camera.ID = list.length;
			list.push(camera);
			if (!oldList.contains(camera))
				cameraAdded.dispatch(camera);
		}

		if (defaults == null && list.length > 0)
			defaults = [list[0]];

		if (defaults != null)
			for (camera in defaults)
			{
				if (camera == null)
					continue;
				if (list.contains(camera))
					this.defaults.push(camera);
			}
	}

	/**
	 * Remove a camera from the game.
	 *
	 * @param   Index     The index of the camera you want to remove.
	 * @param   Destroy   Whether to call destroy() on the camera, default value is true.
	 */
	public function removeAt(index:Int, destroy:Bool = true):Void
	{
		if (index < 0 || index >= list.length)
		{
			FlxG.log.warn("FlxG.cameras.removeAt(): The camera you attempted to remove is not a part of the game.");
			return;
		}

		var camera = list[index];

		FlxG.game.removeChild(camera.flashSprite);
		list.splice(index, 1);
		defaults.remove(camera);

		if (FlxG.render.tile)
		{
			for (i in 0...list.length)
			{
				list[i].ID = i;
			}
		}

		if (destroy)
			camera.destroy();

		cameraRemoved.dispatch(camera);
	}

	/**
	 * Returns the index of the specified camera in the list.
	 *
	 * @param   Camera    The camera you want to find the index of.
	 * @return  The index of the camera in the list.
	**/
	public inline function indexOf(camera:FlxCamera):Int
	{
		return list.indexOf(camera);
	}

	/**
	 * Returns true if the specified camera is in the list.
	 *
	 * @param   Camera    The camera you want to check for.
	 * @return  True if the camera is in the list.
	**/
	public inline function contains(camera:FlxCamera):Bool
	{
		return list.contains(camera);
	}

	/**
	 * If set to true, the camera is listed as a default draw target, meaning `FlxBasics`
	 * render to the specified camera if the `FlxBasic` has a null `cameras` value.
	 * @see flixel.FlxBasic.cameras
	 *
	 * @param camera The camera you wish to change.
	 * @param value  If false, FlxBasics will not render to it unless you add it to their `cameras` list.
	 * @since 4.9.0
	 */
	public function setDefaultDrawTarget(camera:FlxCamera, value:Bool)
	{
		if (!list.contains(camera))
		{
			FlxG.log.warn("FlxG.cameras.setDefaultDrawTarget(): The specified camera is not a part of the game.");
			return;
		}

		var index = defaults.indexOf(camera);

		if (value && index == -1)
			defaults.push(camera);
		else if (!value)
			defaults.splice(index, 1);
	}

	/**
	 * Dumps all the current cameras and resets to just one camera.
	 * Handy for doing split-screen especially.
	 *
	 * @param	newCamera	Optional; specify a specific camera object to be the new main camera.
	 */
	public function reset(?newCamera:FlxCamera):Void
	{
		FlxG.camera = null;

		cameraReset.dispatch(newCamera);
		while (list.length > 0)
			remove(list[0]);

		if (newCamera == null)
			newCamera = new FlxCamera();

		FlxG.camera = add(newCamera);
		newCamera.ID = 0;

		FlxCamera._defaultCameras = defaults;
		cameraResetPost.dispatch(newCamera);
	}

	/**
	 * All screens are filled with this color and gradually return to normal.
	 *
	 * @param	Color		The color you want to use.
	 * @param	Duration	How long it takes for the flash to fade.
	 * @param	OnComplete	A function you want to run when the flash finishes.
	 * @param	Force		Force the effect to reset.
	 */
	public function flash(Color:FlxColor = FlxColor.WHITE, Duration:Float = 1, ?OnComplete:Void->Void, Force:Bool = false):Void
	{
		for (camera in list)
		{
			camera.flash(Color, Duration, OnComplete, Force);
		}
	}

	/**
	 * The screen is gradually filled with this color.
	 *
	 * @param	Color		The color you want to use.
	 * @param	Duration	How long it takes for the fade to finish.
	 * @param 	FadeIn 		True fades from a color, false fades to it.
	 * @param	OnComplete	A function you want to run when the fade finishes.
	 * @param	Force		Force the effect to reset.
	 */
	public function fade(Color:FlxColor = FlxColor.BLACK, Duration:Float = 1, FadeIn:Bool = false, ?OnComplete:Void->Void, Force:Bool = false):Void
	{
		for (camera in list)
		{
			camera.fade(Color, Duration, FadeIn, OnComplete, Force);
		}
	}

	/**
	 * A simple screen-shake effect.
	 *
	 * @param	Intensity	Percentage of screen size representing the maximum distance that the screen can move while shaking.
	 * @param	Duration	The length in seconds that the shaking effect should last.
	 * @param	OnComplete	A function you want to run when the shake effect finishes.
	 * @param	Force		Force the effect to reset (default = true, unlike flash() and fade()!).
	 * @param	Axes		On what axes to shake. Default value is XY / both.
	 */
	public function shake(Intensity:Float = 0.05, Duration:Float = 0.5, ?OnComplete:Void->Void, Force:Bool = true, ?Axes:FlxAxes):Void
	{
		for (camera in list)
		{
			camera.shake(Intensity, Duration, OnComplete, Force, Axes);
		}
	}

	@:allow(flixel.FlxG)
	function new()
	{
		FlxCamera._defaultCameras = defaults;
	}

	/**
	 * Called by the game object to lock all the camera buffers and clear them for the next draw pass.
	 */
	@:allow(flixel.FlxGame)
	inline function lock():Void
	{
		for (camera in list)
		{
			if (camera == null || !camera.exists || !camera.visible)
			{
				continue;
			}

			if (FlxG.render.blit)
			{
				camera.checkResize();

				if (useBufferLocking)
				{
					camera.buffer.lock();
				}
			}

			if (FlxG.render.tile)
			{
				camera.clearDrawStack();
				camera.canvas.graphics.clear();
				// Clearing camera's debug sprite
				#if FLX_DEBUG
				camera.debugLayer.graphics.clear();
				#end
			}

			if (FlxG.render.blit)
			{
				camera.fill(camera.bgColor, camera.useBgAlphaBlending);
				camera.screen.dirty = true;
			}
			else
			{
				camera.fill(camera.bgColor.rgb, camera.useBgAlphaBlending, camera.bgColor.alphaFloat);
			}
		}
	}

	@:allow(flixel.FlxGame)
	inline function render():Void
	{
		if (FlxG.render.tile)
		{
			for (camera in list)
			{
				if (camera != null && camera.exists && camera.visible)
				{
					camera.render();
				}
			}
		}
	}

	/**
	 * Called by the game object to draw the special FX and unlock all the camera buffers.
	 */
	@:allow(flixel.FlxGame)
	inline function unlock():Void
	{
		for (camera in list)
		{
			if ((camera == null) || !camera.exists || !camera.visible)
			{
				continue;
			}

			camera.drawFX();

			if (FlxG.render.blit)
			{
				if (useBufferLocking)
				{
					camera.buffer.unlock();
				}

				camera.screen.dirty = true;
			}
		}
	}

	/**
	 * Called by the game object to update the cameras and their tracking/special effects logic.
	 */
	@:allow(flixel.FlxGame)
	inline function update(elapsed:Float):Void
	{
		for (camera in list)
		{
			if (camera != null && camera.exists && camera.active)
			{
				camera.update(elapsed);
			}
		}
	}

	/**
	 * Resizes and moves cameras when the game resizes (onResize signal).
	 */
	@:allow(flixel.FlxGame)
	function resize():Void
	{
		for (camera in list)
		{
			camera.onResize();
		}
	}

	function set_bgColor(Color:FlxColor):FlxColor
	{
		for (camera in list)
		{
			camera.bgColor = Color;
		}

		return Color;
	}
}
