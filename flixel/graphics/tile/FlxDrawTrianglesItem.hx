package flixel.graphics.tile;

import flixel.FlxCamera;
import flixel.math.FlxAngle;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.Graphics;
import openfl.display.ShaderParameter;
import openfl.display.TriangleCulling;
import openfl.geom.ColorTransform;

typedef DrawData<T> = openfl.Vector<T>;

/**
 * @author Zaphod
 */
class FlxDrawTrianglesItem extends FlxDrawBaseItem<FlxDrawTrianglesItem> {
	static var point = new FlxPoint();
	static var size = FlxPoint.get();
	static var origin = FlxPoint.get();
	static var rect = new FlxRect();

	public var shader:FlxShader;
	var alphas:Array<Float>;
	var colorMultipliers:Array<Float>;
	var colorOffsets:Array<Float>;

	public var vertices = new DrawData<Float>();
	public var indices = new DrawData<Int>();
	public var uvtData = new DrawData<Float>();
	public var colors = new DrawData<Int>();

	public var verticesPosition = 0;
	public var indicesPosition = 0;
	public var colorsPosition = 0;

	var bounds = FlxRect.get();

	public function new() {
		super();
		type = FlxDrawItemType.TRIANGLES;
		alphas = [];
	}

	override public function render(camera:FlxCamera):Void {
		if (!FlxG.render.tile) return;

		if (numTriangles <= 0) return;

		final shader = shader != null ? shader : graphics.shader;
		shader.bitmap.input = graphics.bitmap;
		shader.bitmap.filter = (camera.antialiasing || antialiasing) ? LINEAR : NEAREST;
		shader.bitmap.wrap = REPEAT; // in order to prevent breaking tiling behaviour in classes that use drawTriangles
		shader.alpha.value = alphas;

		if (colored || hasColorOffsets) {
			shader.colorMultiplier.value = colorMultipliers;
			shader.colorOffset.value = colorOffsets;
		} else {
			shader.colorMultiplier.value = null;
			shader.colorOffset.value = null;
		}

		setParameterValue(shader.hasTransform, true);
		setParameterValue(shader.hasColorTransform, colored || hasColorOffsets);

		camera.canvas.graphics.overrideBlendMode(blend);

		camera.canvas.graphics.beginShaderFill(shader);

		camera.canvas.graphics.drawTriangles(vertices, indices, uvtData, TriangleCulling.NONE);
		camera.canvas.graphics.endFill();

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug) {
			final gfx = camera.debugLayer.graphics;
			gfx.lineStyle(1, FlxColor.BLUE, .5);
			gfx.drawTriangles(vertices, indices, uvtData);
		}
		#end

		super.render(camera);
	}

	override public function reset():Void {
		super.reset();
		vertices.length = indices.length = uvtData.length = colors.length = 0;

		verticesPosition = indicesPosition = colorsPosition = 0;

		alphas.resize(0);
		colorMultipliers?.resize(0);
		colorOffsets?.resize(0);
	}

	override public function dispose():Void {
		super.dispose();

		vertices = null;
		indices = null;
		uvtData = null;
		colors = null;
		bounds = FlxDestroyUtil.put(bounds);
		alphas = null;
		colorMultipliers = null;
		colorOffsets = null;
	}

	public function addTriangles(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint, angle = .0, ?scale:FlxPoint, ?originPoint:FlxPoint, ?cameraBounds:FlxRect, ?transform:ColorTransform):Void {
		addTrianglesAdvanced(vertices, indices, uvtData, colors, position, angle, scale, originPoint, cameraBounds, transform);
	}

	public function addTrianglesAdvanced(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint, angle = .0, ?scale:FlxPoint, ?originPoint:FlxPoint, ?cameraBounds:FlxRect, ?transform:ColorTransform):Void {
		position ??= point.set();
		scale ??= size.set(1, 1);
		originPoint ??= origin.set();
		cameraBounds ??= rect.set(0, 0, FlxG.width, FlxG.height);

		final verticesLength = vertices.length;
		final prevVerticesLength = this.vertices.length;
		final numberOfVertices = verticesLength >> 1;
		final prevIndicesLength = this.indices.length;
		final prevUVTDataLength = this.uvtData.length;
		final prevColorsLength = this.colors.length;
		final prevNumberOfVertices = this.numVertices;

		var tempX:Float, tempY:Float;
		var i = 0;
		var currentVertexPosition = prevVerticesLength;

		var cos = 1.;
		var sin = .0;
		if (angle != 0) {
			cos = Math.cos(angle * FlxAngle.TO_RAD);
			sin = Math.sin(angle * FlxAngle.TO_RAD);
		}

		while (i < verticesLength) {
			var vertX = (vertices[i] * scale.x) - originPoint.x;
			var vertY = (vertices[i + 1] * scale.y) - originPoint.y;

			if (angle != 0) {
				final vx = vertX;
				final vy = vertY;

				vertX = (vx * cos) + (vy * -sin);
				vertY = (vx * sin) + (vy * cos);
			}

			tempX = position.x + vertX;
			tempY = position.y + vertY;

			this.vertices[currentVertexPosition++] = tempX;
			this.vertices[currentVertexPosition++] = tempY;

			if (i == 0)
				bounds.set(tempX, tempY, 0, 0);
			else
				inflateBounds(bounds, tempX, tempY);

			i += 2;
		}

		final indicesLength = indices.length;
		if (cameraBounds.overlaps(bounds)) {
			final uvtDataLength = uvtData.length;
			for (i in 0...uvtDataLength)
				this.uvtData[prevUVTDataLength + i] = uvtData[i];

			for (i in 0...indicesLength)
				this.indices[prevIndicesLength + i] = indices[i] + prevNumberOfVertices;

			if (colored) {
				for (i in 0...numberOfVertices)
					this.colors[prevColorsLength + i] = colors[i];

				colorsPosition += numberOfVertices;
			}

			verticesPosition += verticesLength;
			indicesPosition += indicesLength;
		} else 
			this.vertices.splice(this.vertices.length - verticesLength, verticesLength);

		position.putWeak();
		cameraBounds.putWeak();

		for (_ in 0...indicesLength)
			alphas.push(transform != null ? transform.alphaMultiplier : 1);

		if (colored || hasColorOffsets) {
			colorMultipliers ??= [];
			colorOffsets ??= [];

			for (_ in 0...indicesLength) {
				if(transform != null) {
					colorMultipliers.push(transform.redMultiplier);
					colorMultipliers.push(transform.greenMultiplier);
					colorMultipliers.push(transform.blueMultiplier);

					colorOffsets.push(transform.redOffset);
					colorOffsets.push(transform.greenOffset);
					colorOffsets.push(transform.blueOffset);
					colorOffsets.push(transform.alphaOffset);
				} else {
					colorMultipliers.push(1);
					colorMultipliers.push(1);
					colorMultipliers.push(1);

					colorOffsets.push(0);
					colorOffsets.push(0);
					colorOffsets.push(0);
					colorOffsets.push(0);
				}

				colorMultipliers.push(1);
			}
		}
	}

	public function addTrianglesColorArray(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint, ?cameraBounds:FlxRect, ?transforms:Array<ColorTransform>):Void {
		position ??= point.set();
		cameraBounds ??= rect.set(0, 0, FlxG.width, FlxG.height);

		final verticesLength = vertices.length;
		final prevVerticesLength = this.vertices.length;
		final numberOfVertices = Std.int(verticesLength * .5);
		final numberOfTriangles = Std.int(indices.length * .5);
		final prevIndicesLength = this.indices.length;
		final prevUVTDataLength = this.uvtData.length;
		final prevColorsLength = this.colors.length;
		final prevNumberOfVertices = this.numVertices;

		var tempX:Float, tempY:Float;
		var i = 0;
		var currentVertexPosition = prevVerticesLength;

		while (i < verticesLength) {
			tempX = position.x + vertices[i];
			tempY = position.y + vertices[i + 1];

			this.vertices[currentVertexPosition++] = tempX;
			this.vertices[currentVertexPosition++] = tempY;

			i += 2;
		}

		final uvtDataLength = uvtData.length;
		for (i in 0...uvtDataLength)
			this.uvtData[prevUVTDataLength + i] = uvtData[i];

		final indicesLength = indices.length;
		for (i in 0...indicesLength)
			this.indices[prevIndicesLength + i] = indices[i] + prevNumberOfVertices;

		verticesPosition += verticesLength;
		indicesPosition += indicesLength;

		position.putWeak();
		cameraBounds.putWeak();

		for (_ in 0...numberOfTriangles) {
			final transform = transforms[_];
			alphas.push(transform != null ? transform.alphaMultiplier : 1);
			alphas.push(transform != null ? transform.alphaMultiplier : 1);
			alphas.push(transform != null ? transform.alphaMultiplier : 1);
		}

		if (colored || hasColorOffsets) {
			colorMultipliers ??= [];
			colorOffsets ??= [];

			for (_ in 0...numberOfTriangles) {
				final transform = transforms[_];
				for (_ in 0...3) {
					if (transform != null) {
						colorMultipliers.push(transform.redMultiplier);
						colorMultipliers.push(transform.greenMultiplier);
						colorMultipliers.push(transform.blueMultiplier);

						colorOffsets.push(transform.redOffset);
						colorOffsets.push(transform.greenOffset);
						colorOffsets.push(transform.blueOffset);
						colorOffsets.push(transform.alphaOffset);
					} else {
						colorMultipliers.push(1);
						colorMultipliers.push(1);
						colorMultipliers.push(1);

						colorOffsets.push(0);
						colorOffsets.push(0);
						colorOffsets.push(0);
						colorOffsets.push(0);
					}

					colorMultipliers.push(1);
				}
			}
		}
	}

	inline function setParameterValue(parameter:ShaderParameter<Bool>, value:Bool):Void {
		parameter.value ??= [];
		parameter.value[0] = value;
	}

	public static inline function inflateBounds(bounds:FlxRect, x:Float, y:Float):FlxRect {
		if (x < bounds.x) {
			bounds.width += bounds.x - x;
			bounds.x = x;
		}

		if (y < bounds.y) {
			bounds.height += bounds.y - y;
			bounds.y = y;
		}

		if (x > bounds.x + bounds.width)
			bounds.width = x - bounds.x;

		if (y > bounds.y + bounds.height)
			bounds.height = y - bounds.y;

		return bounds;
	}

	override public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform):Void {
		final prevVerticesPos = verticesPosition;
		final prevIndicesPos = indicesPosition;
		final prevColorsPos = colorsPosition;
		final prevNumberOfVertices = numVertices;

		final point = FlxPoint.get();
		point.transform(matrix);

		vertices[prevVerticesPos] = point.x;
		vertices[prevVerticesPos + 1] = point.y;

		uvtData[prevVerticesPos] = frame.uv.left;
		uvtData[prevVerticesPos + 1] = frame.uv.top;

		point.set(frame.frame.width, 0);
		point.transform(matrix);

		vertices[prevVerticesPos + 2] = point.x;
		vertices[prevVerticesPos + 3] = point.y;

		uvtData[prevVerticesPos + 2] = frame.uv.right;
		uvtData[prevVerticesPos + 3] = frame.uv.top;

		point.set(frame.frame.width, frame.frame.height);
		point.transform(matrix);

		vertices[prevVerticesPos + 4] = point.x;
		vertices[prevVerticesPos + 5] = point.y;

		uvtData[prevVerticesPos + 4] = frame.uv.right;
		uvtData[prevVerticesPos + 5] = frame.uv.bottom;

		point.set(0, frame.frame.height);
		point.transform(matrix);

		vertices[prevVerticesPos + 6] = point.x;
		vertices[prevVerticesPos + 7] = point.y;

		point.put();

		uvtData[prevVerticesPos + 6] = frame.uv.left;
		uvtData[prevVerticesPos + 7] = frame.uv.bottom;

		indices[prevIndicesPos] = prevNumberOfVertices;
		indices[prevIndicesPos + 1] = prevNumberOfVertices + 1;
		indices[prevIndicesPos + 2] = prevNumberOfVertices + 2;
		indices[prevIndicesPos + 3] = prevNumberOfVertices + 2;
		indices[prevIndicesPos + 4] = prevNumberOfVertices + 3;
		indices[prevIndicesPos + 5] = prevNumberOfVertices;

		if (colored) {
			var red = 1.;
			var green = 1.;
			var blue = 1.;
			var alpha = 1.;

			if (transform != null) {
				red = transform.redMultiplier;
				green = transform.greenMultiplier;
				blue = transform.blueMultiplier;

				alpha = transform.alphaMultiplier;
			}

			final color = FlxColor.fromRGBFloat(red, green, blue, alpha);

			colors[prevColorsPos] = color;
			colors[prevColorsPos + 1] = color;
			colors[prevColorsPos + 2] = color;
			colors[prevColorsPos + 3] = color;

			colorsPosition += 4;
		}

		verticesPosition += 8;
		indicesPosition += 6;
	}

	override function get_numVertices():Int {
		return Std.int(vertices.length * .5);
	}

	override function get_numTriangles():Int {
		return Std.int(indices.length / 3);
	}
}
