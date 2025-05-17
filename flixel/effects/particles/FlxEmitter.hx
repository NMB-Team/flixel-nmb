package flixel.effects.particles;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxTypes;
import flixel.effects.particles.FlxParticle.IFlxParticle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDirectionFlags;
import flixel.util.helpers.FlxBounds;
import flixel.util.helpers.FlxPointRangeBounds;
import flixel.util.helpers.FlxRangeBounds;
import openfl.display.BlendMode;

typedef FlxEmitter = FlxTypedEmitter<FlxParticle>;

/**
 * FlxTypedEmitter is a lightweight particle emitter.
 * It can be used for one-time explosions or for continuous fx like rain and fire.
 * `FlxEmitter` is not optimized or anything; all it does is launch `FlxParticle` objects out
 * at set intervals by setting their positions and velocities accordingly.
 * It is easy to use and relatively efficient, relying on `FlxGroup`'s RECYCLE POWERS.
 */
class FlxTypedEmitter<T:FlxSprite & IFlxParticle> extends FlxTypedGroup<T> {
	/**
	 * Set your own particle class type here. The custom class must extend `FlxParticle`. Default is `FlxParticle`.
	 */
	public var particleClass:Class<T> = cast FlxParticle;

	/**
	 * Determines whether the emitter is currently emitting particles. It is totally safe to directly toggle this.
	 */
	public var emitting = false;

	/**
	 * How often a particle is emitted (if emitter is started with `Explode == false`).
	 */
	public var frequency = .1;

	/**
	 * Sets particle's blend mode. `null` by default. Warning: Expensive on Flash.
	 */
	public var blend:BlendMode;

	/**
	 * The x position of this emitter.
	 */
	public var x = .0;

	/**
	 * The y position of this emitter.
	 */
	public var y = .0;

	/**
	 * The width of this emitter. Particles can be randomly generated from anywhere within this box.
	 */
	public var width = .0;

	/**
	 * The height of this emitter. Particles can be randomly generated from anywhere within this box.
	 */
	public var height = .0;

	/**
	 * Whether particles spawned by this emitter should be antialiased. 
	 * Defaults to `FlxSprite.defaultAntialiasing`. This only affects rendering.
	 */
	public var antialiasing = FlxSprite.defaultAntialiasing;

	/**
	 * How particles should be launched. If `CIRCLE`, particles will use `launchAngle` and `speed`.
	 * Otherwise, particles will just use `velocity.x` and `velocity.y`.
	 */
	public var launchMode = FlxEmitterMode.CIRCLE;

	/**
	 * Keep the scale ratio of the particle. Uses the `x` values of `scale`.
	 */
	public var keepScaleRatio = false;

	/**
	 * Sets the velocity range of particles launched from this emitter. Only used with `FlxEmitterMode.SQUARE`.
	 */
	public var velocity(default, null) = new FlxPointRangeBounds(-100, -100, 100, 100);

	/**
	 * Set the speed range of particles launched from this emitter. Only used with `FlxEmitterMode.CIRCLE`.
	 */
	public var speed(default, null) = new FlxRangeBounds<Float>(0, 100);

	/**
	 * Set the angular acceleration range of particles launched from this emitter.
	 */
	public var angularAcceleration(default, null) = new FlxRangeBounds<Float>(0, 0);

	/**
	 * Set the angular drag range of particles launched from this emitter.
	 */
	public var angularDrag(default, null) = new FlxRangeBounds<Float>(0, 0);

	/**
	 * The angular velocity range of particles launched from this emitter.
	 */
	public var angularVelocity(default, null) = new FlxRangeBounds<Float>(0, 0);

	/**
	 * The angle range of particles launched from this emitter.
	 * `angle.end` is ignored unless `ignoreAngularVelocity` is set to `true`.
	 */
	public var angle(default, null) = new FlxRangeBounds<Float>(0);

	/**
	 * Set this if you want to specify the beginning and ending value of angle,
	 * instead of using `angularVelocity` (or `angularAcceleration`).
	 */
	public var ignoreAngularVelocity = false;

	/**
	 * The angle range at which particles will be launched from this emitter.
	 * Ignored unless `launchMode` is set to `FlxEmitterMode.CIRCLE`.
	 */
	public var launchAngle(default, null) = new FlxBounds<Float>(-180, 180);

	/**
	 * The life, or duration, range of particles launched from this emitter.
	 */
	public var lifespan(default, null) = new FlxBounds<Float>(3);

	/**
	 * Sets `scale` range of particles launched from this emitter.
	 */
	public var scale(default, null) = new FlxPointRangeBounds(1, 1);

	/**
	 * Sets `alpha` range of particles launched from this emitter.
	 */
	public var alpha(default, null) = new FlxRangeBounds<Float>(1);

	/**
	 * Sets `color` range of particles launched from this emitter.
	 */
	public var color(default, null) = new FlxRangeBounds(FlxColor.WHITE, FlxColor.WHITE);

	/**
	 * Sets X and Y drag component of particles launched from this emitter.
	 */
	public var drag(default, null) = new FlxPointRangeBounds(0, 0);

	/**
	 * Sets the `acceleration` range of particles launched from this emitter.
	 * Set acceleration y-values to give particles gravity.
	 */
	public var acceleration(default, null) = new FlxPointRangeBounds(0, 0);

	/**
	 * Sets the `elasticity`, or bounce, range of particles launched from this emitter.
	 */
	public var elasticity(default, null) = new FlxRangeBounds<Float>(0);

	/**
	 * Whether the particle should be affected by velocity, acceleration, drag, and other motion-related properties.
	 * Set this to `false` to disable automatic physics updates (`updateMotion()`).
	 * Defaults to `true` for `FlxObject` and `FlxSprite`, and `false` for UI/logic-only objects like `FlxText` or `FlxTilemap`.
	 */
	public var moves(default, set) = FlxObject.defaultMoves;

	/**
	 * Sets the `immovable` flag for particles launched from this emitter.
	 */
	public var immovable = false;

	/**
	 * Sets the `autoUpdateHitbox` flag for particles launched from this emitter.
	 * If true, the particles' hitbox will be updated to match scale.
	 */
	public var autoUpdateHitbox = false;

	/**
	 * Sets the `allowCollisions` value for particles launched from this emitter.
	 * Set to `NONE` by default. Don't forget to call `FlxG.collide()` in your update loop!
	 */
	public var allowCollisions = FlxDirectionFlags.NONE;

	/**
	 * Shorthand for toggling `allowCollisions` between `ANY` (if `true`) and `NONE` (if `false`).
	 * Don't forget to call `FlxG.collide()` in your update loop!
	 */
	public var solid(get, set):Bool;

	/**
	 * Internal helper for deciding how many particles to launch.
	 */
	var _quantity = 0;

	/**
	 * Internal helper for the style of particle emission (all at once, or one at a time).
	 */
	var _explode = true;

	/**
	 * Internal helper for deciding when to launch particles or kill them.
	 */
	var _timer = .0;

	/**
	 * Internal counter for figuring out how many particles to launch.
	 */
	var _counter = 0;

	/**
	 * Internal point object, handy for reusing for memory management purposes.
	 */
	var _point = FlxPoint.get();

	/**
	 * Internal helper for automatically calling the `kill()` method
	 */
	var _waitForKill = false;

	/**
	 * Creates a new `FlxTypedEmitter` object at a specific position.
	 * Does NOT automatically generate or attach particles!
	 *
	 * @param   x      The X position of the emitter.
	 * @param   y      The Y position of the emitter.
	 * @param   size   Optional, specifies a maximum capacity for this emitter.
	 */
	public function new(x = .0, y = .0, size = 0) {
		super(size);

		setPosition(x, y);
		exists = false;
	}

	/**
	 * Clean up memory.
	 */
	override public function destroy():Void {
		velocity = FlxDestroyUtil.destroy(velocity);
		scale = FlxDestroyUtil.destroy(scale);
		drag = FlxDestroyUtil.destroy(drag);
		acceleration = FlxDestroyUtil.destroy(acceleration);
		_point = FlxDestroyUtil.put(_point);

		blend = null;
		angularAcceleration = null;
		angularDrag = null;
		angularVelocity = null;
		angle = null;
		speed = null;
		launchAngle = null;
		lifespan = null;
		alpha = null;
		color = null;
		elasticity = null;

		super.destroy();
	}

	/**
	 * This function generates a new array of particle sprites to attach to the emitter.
	 *
	 * @param   Graphics         If you opted to not pre-configure an array of `FlxParticle` objects,
	 *                           you can simply pass in a particle image or sprite sheet.
	 * @param   Quantity         The number of particles to generate when using the "create from image" option.
	 * @param   BakedRotations   How many frames of baked rotation to use (boosts performance).
	 *                           Set to zero to not use baked rotations.
	 * @param   Multiple         Whether the image in the `Graphics` param is a single particle or a bunch of particles
	 *                           (if it's a bunch, they need to be square!).
	 * @param   AutoBuffer       Whether to automatically increase the image size to accommodate rotated corners.
	 *                           Default is `false`. Will create frames that are 150% larger on each axis than the
	 *                           original frame or graphic.
	 * @return  This `FlxEmitter` instance (nice for chaining stuff together).
	 */
	public function loadParticles(width = 20, height = 20, graphics:FlxGraphicAsset, quantity = 50, bakedRotationAngles = 16, multiple = false, autoBuffer = false):FlxTypedEmitter<T> {
		maxSize = quantity;
		var totalFrames = 1;

		if (multiple) {
			final sprite = new FlxSprite();
			sprite.loadGraphic(graphics, true);
			totalFrames = sprite.numFrames;
			sprite.antialiasing = antialiasing;
			sprite.moves = moves;
			sprite.setSize(width, height);
			sprite?.destroy();
		}

		for (i in 0...quantity) add(loadParticle(width, height, graphics, quantity, bakedRotationAngles, multiple, autoBuffer, totalFrames));

		return this;
	}

	inline function loadParticle(width = 20, height = 20, graphics:FlxGraphicAsset, quantity:Int, bakedRotationAngles:Int, multiple = false, autoBuffer = false, totalFrames:Int):T {
		final particle:T = Type.createInstance(particleClass, []);
		final frame = multiple ? FlxG.random.int(0, totalFrames - 1) : -1;

		if (FlxG.renderBlit && bakedRotationAngles > 0) particle.loadRotatedGraphic(graphics, bakedRotationAngles, frame, false, autoBuffer);
		else particle.loadGraphic(graphics, multiple);

		particle.setSize(width, height);
		particle.moves = moves;
		particle.antialiasing = antialiasing;

		if (multiple) particle.animation.frameIndex = frame;

		return particle;
	}

	/**
	 * Similar to `FlxSprite#makeGraphic()`, this function allows you to quickly make single-color particles.
	 *
	 * @param   width      The width of the generated particles. Default is `2` pixels.
	 * @param   height     The height of the generated particles. Default is `2` pixels.
	 * @param   color      The color of the generated particles. Default is white.
	 * @param   quantity   How many particles to generate. Default is `50`.
	 * @return  This `FlxEmitter` instance (nice for chaining stuff together).
	 */
	public function makeParticles(width = 2, height = 2, color = FlxColor.WHITE, quantity = 50):FlxTypedEmitter<T> {
		maxSize = quantity;

		for (i in 0...quantity) {
			final particle:T = Type.createInstance(particleClass, []);
			particle.makeGraphic(width, height, color);
			particle.antialiasing = antialiasing;
			add(particle);
		}

		return this;
	}

	/**
	 * Called automatically by the game loop, decides when to launch particles and when to "die".
	 */
	override public function update(elapsed:Float):Void {
		if (emitting) {
			if (_explode) explode();
			else emitContinuously(elapsed);
		} else if (_waitForKill) {
			_timer += elapsed;

			if ((lifespan.max > 0) && (_timer > lifespan.max)) {
				kill();
				return;
			}
		}

		super.update(elapsed);
	}

	inline function explode() {
		var amount = _quantity;
		if (amount <= 0 || amount > length) amount = length;

		for (i in 0...amount) emitParticle();

		onFinished();
	}

	inline function emitContinuously(elapsed:Float):Void {
		// Spawn one particle per frame
		if (frequency <= 0) emitParticleContinuously();
		else {
			_timer += elapsed;

			while (_timer > frequency) {
				_timer -= frequency;
				emitParticleContinuously();
			}
		}
	}

	inline function emitParticleContinuously():Void {
		emitParticle();
		_counter++;

		if (_quantity > 0 && _counter >= _quantity) onFinished();
	}

	@:noCompletion inline function onFinished():Void {
		emitting = false;
		_waitForKill = true;
		_quantity = 0;
	}

	/**
	 * Call this function to turn off all the particles and the emitter.
	 */
	override public function kill():Void {
		emitting = _waitForKill = false;

		super.kill();
	}

	/**
	 * Call this function to start emitting particles.
	 *
	 * @param   explode     Whether the particles should all burst out at once.
	 * @param   frequency   Ignored if `Explode` is set to `true`. `Frequency` is how often to emit a particle.
	 *                      `0` = never emit, `0.1` = 1 particle every 0.1 seconds, `5` = 1 particle every 5 seconds.
	 * @param   quantity    How many particles to launch. `0` = "all of the particles".
	 * @return  This `FlxEmitter` instance (nice for chaining stuff together).
	 */
	public function start(explode = true, frequency = .1, quantity = 0):FlxTypedEmitter<T> {
		exists = visible = emitting = true;

		_explode = explode;
		this.frequency = frequency;
		_quantity += quantity;

		_counter = 0;
		_timer = 0;
		
		_waitForKill = false;

		return this;
	}

	/**
	 * This function can be used both internally and externally to emit the next particle.
	 */
	public function emitParticle():T {
		final particle:T = cast recycle(cast particleClass);

		particle.reset(0, 0); // Position is set later, after size has been calculated

		particle.blend = blend;
		particle.immovable = immovable;
		particle.antialiasing = antialiasing;
		particle.moves = moves;
		particle.allowCollisions = allowCollisions;
		particle.autoUpdateHitbox = autoUpdateHitbox;

		// Particle lifespan settings
		if (lifespan.active) particle.lifespan = FlxG.random.float(lifespan.min, lifespan.max);

		if (velocity.active) {
			// Particle velocity/launch angle settings
			particle.velocityRange.active = particle.lifespan > 0 && !particle.velocityRange.start.equals(particle.velocityRange.end);

			if (launchMode == FlxEmitterMode.CIRCLE) {
				final particleAngle = launchAngle.active ? FlxG.random.float(launchAngle.min, launchAngle.max) : .0;

				// Calculate launch velocity
				_point = FlxVelocity.velocityFromAngle(particleAngle, FlxG.random.float(speed.start.min, speed.start.max));
				particle.velocity.set(_point.x, _point.y);
				particle.velocityRange.start.set(_point.x, _point.y);

				// Calculate final velocity
				_point = FlxVelocity.velocityFromAngle(particleAngle, FlxG.random.float(speed.end.min, speed.end.max));
				particle.velocityRange.end.set(_point.x, _point.y);
			} else {
				particle.velocityRange.start.set(FlxG.random.float(velocity.start.min.x, velocity.start.max.x), FlxG.random.float(velocity.start.min.y, velocity.start.max.y));
				particle.velocityRange.end.set(FlxG.random.float(velocity.end.min.x, velocity.end.max.x), FlxG.random.float(velocity.end.min.y, velocity.end.max.y));
				particle.velocity.set(particle.velocityRange.start.x, particle.velocityRange.start.y);
			}
		} else
			particle.velocityRange.active = false;

		// Particle angular velocity settings
		particle.angularVelocityRange.active = particle.lifespan > 0 && angularVelocity.start != angularVelocity.end;

		if (!ignoreAngularVelocity) {
			if (angularAcceleration.active) particle.angularAcceleration = FlxG.random.float(angularAcceleration.start.min, angularAcceleration.start.max);

			if (angularVelocity.active) {
				particle.angularVelocityRange.start = FlxG.random.float(angularVelocity.start.min, angularVelocity.start.max);
				particle.angularVelocityRange.end = FlxG.random.float(angularVelocity.end.min, angularVelocity.end.max);
				particle.angularVelocity = particle.angularVelocityRange.start;
			}

			if (angularDrag.active) particle.angularDrag = FlxG.random.float(angularDrag.start.min, angularDrag.start.max);
		} else if (angularVelocity.active) {
			particle.angularVelocity = (FlxG.random.float(angle.end.min, angle.end.max) - FlxG.random.float(angle.start.min, angle.start.max)) / FlxG.random.float(lifespan.min, lifespan.max);
			particle.angularVelocityRange.active = false;
		}

		// Particle angle settings
		if (angle.active) particle.angle = FlxG.random.float(angle.start.min, angle.start.max);

		// Particle scale settings
		if (scale.active) {
			particle.scaleRange.start.x = FlxG.random.float(scale.start.min.x, scale.start.max.x);
			particle.scaleRange.start.y = keepScaleRatio ? particle.scaleRange.start.x : FlxG.random.float(scale.start.min.y, scale.start.max.y);
			particle.scaleRange.end.x = FlxG.random.float(scale.end.min.x, scale.end.max.x);
			particle.scaleRange.end.y = keepScaleRatio ? particle.scaleRange.end.x : FlxG.random.float(scale.end.min.y, scale.end.max.y);
			particle.scaleRange.active = particle.lifespan > 0 && !particle.scaleRange.start.equals(particle.scaleRange.end);
			particle.scale.x = particle.scaleRange.start.x;
			particle.scale.y = particle.scaleRange.start.y;
			if (particle.autoUpdateHitbox) particle.updateHitbox();
		} else particle.scaleRange.active = false;

		// Particle alpha settings
		if (alpha.active) {
			particle.alphaRange.start = FlxG.random.float(alpha.start.min, alpha.start.max);
			particle.alphaRange.end = FlxG.random.float(alpha.end.min, alpha.end.max);
			particle.alphaRange.active = particle.lifespan > 0 && particle.alphaRange.start != particle.alphaRange.end;
			particle.alpha = particle.alphaRange.start;
		} else particle.alphaRange.active = false;

		// Particle color settings
		if (color.active) {
			particle.colorRange.start = FlxG.random.color(color.start.min, color.start.max);
			particle.colorRange.end = FlxG.random.color(color.end.min, color.end.max);
			particle.colorRange.active = particle.lifespan > 0 && particle.colorRange.start != particle.colorRange.end;
			particle.color = particle.colorRange.start;
		} else particle.colorRange.active = false;

		// Particle drag settings
		if (drag.active) {
			particle.dragRange.start.set(FlxG.random.float(drag.start.min.x, drag.start.max.x), FlxG.random.float(drag.start.min.y, drag.start.max.y));
			particle.dragRange.end.set(FlxG.random.float(drag.end.min.x, drag.end.max.x), FlxG.random.float(drag.end.min.y, drag.end.max.y));
			particle.dragRange.active = particle.lifespan > 0 && !particle.dragRange.start.equals(particle.dragRange.end);
			particle.drag.set(particle.dragRange.start.x, particle.dragRange.start.y);
		} else particle.dragRange.active = false;

		// Particle acceleration settings
		if (acceleration.active) {
			particle.accelerationRange.start.set(FlxG.random.float(acceleration.start.min.x, acceleration.start.max.x), FlxG.random.float(acceleration.start.min.y, acceleration.start.max.y));
			particle.accelerationRange.end.set(FlxG.random.float(acceleration.end.min.x, acceleration.end.max.x), FlxG.random.float(acceleration.end.min.y, acceleration.end.max.y));
			particle.accelerationRange.active = particle.lifespan > 0 && !particle.accelerationRange.start.equals(particle.accelerationRange.end);
			particle.acceleration.set(particle.accelerationRange.start.x, particle.accelerationRange.start.y);
		} else particle.accelerationRange.active = false;

		// Particle elasticity settings
		if (elasticity.active) {
			particle.elasticityRange.start = FlxG.random.float(elasticity.start.min, elasticity.start.max);
			particle.elasticityRange.end = FlxG.random.float(elasticity.end.min, elasticity.end.max);
			particle.elasticityRange.active = particle.lifespan > 0 && particle.elasticityRange.start != particle.elasticityRange.end;
			particle.elasticity = particle.elasticityRange.start;
		} else particle.elasticityRange.active = false;

		// Set position
		particle.setPosition(FlxG.random.float(x, x + width) - particle.width * .5, FlxG.random.float(y, y + height) - particle.height * .5);

		// Restart animation
		particle.animation.curAnim?.restart();

		particle.onEmit();

		return particle;
	}

	/**
	 * Change the emitter's midpoint to match the midpoint of a `FlxObject`.
	 *
	 * @param   object   The `FlxObject` that you want to sync up with.
	 */
	public function focusOn(object:FlxObject):Void {
		object.getMidpoint(_point);

		x = _point.x - (Std.int(width) >> 1);
		y = _point.y - (Std.int(height) >> 1);
	}

	/**
	 * Helper function to set the coordinates of this object.
	 */
	public inline function setPosition(x = .0, y = .0):Void {
		this.x = x;
		this.y = y;
	}

	public inline function setSize(width:Float, height:Float):Void {
		this.width = width;
		this.height = height;
	}

	@:noCompletion inline function get_solid():Bool {
		return allowCollisions.has(ANY);
	}

	@:noCompletion inline function set_solid(value:Bool):Bool {
		allowCollisions = value ? ANY : NONE;
		return value;
	}

	@:noCompletion function set_antialiasing(value:Bool):Bool {
		return antialiasing = value;
	}

	@:noCompletion function set_moves(value:Bool):Bool {
		return moves = value;
	}
}

enum abstract FlxEmitterMode(ByteUInt) {
	final SQUARE;
	final CIRCLE;
}
