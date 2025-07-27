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
class FlxDrawTrianglesItem extends FlxDrawBaseItem<FlxDrawTrianglesItem>
{
	static var point:FlxPoint = new FlxPoint();
	static var size:FlxPoint = FlxPoint.get();
	static var origin:FlxPoint = FlxPoint.get();
	static var rect:FlxRect = new FlxRect();

	public var shader:FlxShader;
	var alphas:Array<Float>;
	var colorMultipliers:Array<Float>;
	var colorOffsets:Array<Float>;

	public var vertices:DrawData<Float> = new DrawData<Float>();
	public var indices:DrawData<Int> = new DrawData<Int>();
	public var uvtData:DrawData<Float> = new DrawData<Float>();
	public var colors:DrawData<Int> = new DrawData<Int>();

	public var verticesPosition:Int = 0;
	public var indicesPosition:Int = 0;
	public var colorsPosition:Int = 0;

	var bounds:FlxRect = FlxRect.get();

	public function new()
	{
		super();
		type = FlxDrawItemType.TRIANGLES;
		alphas = [];
	}

	override public function render(camera:FlxCamera):Void
	{
		if (!FlxG.render.tile)
			return;

		if (numTriangles <= 0)
			return;

		var shader = shader != null ? shader : graphics.shader;
		shader.bitmap.input = graphics.bitmap;
		shader.bitmap.filter = (camera.antialiasing || antialiasing) ? LINEAR : NEAREST;
		shader.bitmap.wrap = REPEAT; // in order to prevent breaking tiling behaviour in classes that use drawTriangles
		shader.alpha.value = alphas;

		if (colored || hasColorOffsets)
		{
			shader.colorMultiplier.value = colorMultipliers;
			shader.colorOffset.value = colorOffsets;
		}
		else
		{
			shader.colorMultiplier.value = null;
			shader.colorOffset.value = null;
		}

		setParameterValue(shader.isFlixelDraw, true);
		setParameterValue(shader.hasColorTransform, colored || hasColorOffsets);

		camera.canvas.graphics.overrideBlendMode(blend);

		camera.canvas.graphics.beginShaderFill(shader);

		camera.canvas.graphics.drawTriangles(vertices, indices, uvtData, TriangleCulling.NONE);
		camera.canvas.graphics.endFill();

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
		{
			var gfx:Graphics = camera.debugLayer.graphics;
			gfx.lineStyle(1, FlxColor.BLUE, 0.5);
			gfx.drawTriangles(vertices, indices, uvtData);
		}
		#end

		super.render(camera);
	}

	override public function reset():Void
	{
		super.reset();
		vertices.length = 0;
		indices.length = 0;
		uvtData.length = 0;
		colors.length = 0;

		verticesPosition = 0;
		indicesPosition = 0;
		colorsPosition = 0;
		alphas.resize(0);
		if (colorMultipliers != null)
			colorMultipliers.resize(0);
		if (colorOffsets != null)
			colorOffsets.resize(0);
	}

	override public function dispose():Void
	{
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

	public function addTriangles(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint,
			angle = .0, ?scale:FlxPoint, ?originPoint:FlxPoint, ?cameraBounds:FlxRect, ?transform:ColorTransform):Void
	{
		addTrianglesAdvanced(vertices, indices, uvtData, colors, position, angle, scale, originPoint, cameraBounds, transform);
	}

	public function addTrianglesAdvanced(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint,
			angle = .0, ?scale:FlxPoint, ?originPoint:FlxPoint, ?cameraBounds:FlxRect, ?transform:ColorTransform):Void
	{
		if (position == null)
			position = point.set();

		if (size == null)
			scale = size.set(1, 1);

		if (originPoint == null)
			originPoint = origin.set();

		if (cameraBounds == null)
			cameraBounds = rect.set(0, 0, FlxG.width, FlxG.height);

		var verticesLength:Int = vertices.length;
		var prevVerticesLength:Int = this.vertices.length;
		var numberOfVertices:Int = verticesLength >> 1;
		var prevIndicesLength:Int = this.indices.length;
		var prevUVTDataLength:Int = this.uvtData.length;
		var prevColorsLength:Int = this.colors.length;
		var prevNumberOfVertices:Int = this.numVertices;

		var tempX:Float, tempY:Float;
		var i:Int = 0;
		var currentVertexPosition:Int = prevVerticesLength;

		var cos = 1.0;
		var sin = 0.0;
		if (angle != 0)
		{
			cos = FlxMath.fastCos(angle * FlxAngle.TO_RAD);
			sin = FlxMath.fastSin(angle * FlxAngle.TO_RAD);
		}

		while (i < verticesLength)
		{
			var vertX = (vertices[i] * scale.x) - originPoint.x;
			var vertY = (vertices[i + 1] * scale.y) - originPoint.y;

			if (angle != 0)
			{
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
			{
				bounds.set(tempX, tempY, 0, 0);
			}
			else
			{
				inflateBounds(bounds, tempX, tempY);
			}

			i += 2;
		}

		var indicesLength:Int = indices.length;
		if (!cameraBounds.overlaps(bounds))
		{
			this.vertices.splice(this.vertices.length - verticesLength, verticesLength);
		}
		else
		{
			var uvtDataLength:Int = uvtData.length;
			for (i in 0...uvtDataLength)
			{
				this.uvtData[prevUVTDataLength + i] = uvtData[i];
			}

			for (i in 0...indicesLength)
			{
				this.indices[prevIndicesLength + i] = indices[i] + prevNumberOfVertices;
			}

			if (colored)
			{
				for (i in 0...numberOfVertices)
				{
					this.colors[prevColorsLength + i] = colors[i];
				}

				colorsPosition += numberOfVertices;
			}

			verticesPosition += verticesLength;
			indicesPosition += indicesLength;
		}

		position.putWeak();
		cameraBounds.putWeak();

		for (_ in 0...indicesLength)
		{
			alphas.push(transform != null ? transform.alphaMultiplier : 1.0);
		}

		if (colored || hasColorOffsets)
		{
			if (colorMultipliers == null)
				colorMultipliers = [];

			if (colorOffsets == null)
				colorOffsets = [];

			for (_ in 0...indicesLength)
			{
				if(transform != null)
				{
					colorMultipliers.push(transform.redMultiplier);
					colorMultipliers.push(transform.greenMultiplier);
					colorMultipliers.push(transform.blueMultiplier);

					colorOffsets.push(transform.redOffset);
					colorOffsets.push(transform.greenOffset);
					colorOffsets.push(transform.blueOffset);
					colorOffsets.push(transform.alphaOffset);
				}
				else
				{
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

	public function addTrianglesColorArray(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>,
			?position:FlxPoint, ?cameraBounds:FlxRect, ?transforms:Array<ColorTransform>):Void
	{
		if (position == null)
			position = point.set();

		if (cameraBounds == null)
			cameraBounds = rect.set(0, 0, FlxG.width, FlxG.height);

		var verticesLength:Int = vertices.length;
		var prevVerticesLength:Int = this.vertices.length;
		var numberOfTriangles:Int = Std.int(indices.length * .5);
		var prevIndicesLength:Int = this.indices.length;
		var prevUVTDataLength:Int = this.uvtData.length;
		var prevNumberOfVertices:Int = this.numVertices;

		var tempX:Float, tempY:Float;
		var i:Int = 0;
		var currentVertexPosition:Int = prevVerticesLength;

		while (i < verticesLength)
		{
			tempX = position.x + vertices[i];
			tempY = position.y + vertices[i + 1];

			this.vertices[currentVertexPosition++] = tempX;
			this.vertices[currentVertexPosition++] = tempY;

			i += 2;
		}

		var uvtDataLength:Int = uvtData.length;
		for (i in 0...uvtDataLength)
		{
			this.uvtData[prevUVTDataLength + i] = uvtData[i];
		}

		var indicesLength:Int = indices.length;
		for (i in 0...indicesLength)
		{
			this.indices[prevIndicesLength + i] = indices[i] + prevNumberOfVertices;
		}

		verticesPosition += verticesLength;
		indicesPosition += indicesLength;

		position.putWeak();
		cameraBounds.putWeak();

		for (_ in 0...numberOfTriangles)
		{
			var transform = transforms[_];
			alphas.push(transform != null ? transform.alphaMultiplier : 1.0);
			alphas.push(transform != null ? transform.alphaMultiplier : 1.0);
			alphas.push(transform != null ? transform.alphaMultiplier : 1.0);
		}

		if (colored || hasColorOffsets)
		{
			if (colorMultipliers == null)
				colorMultipliers = [];

			if (colorOffsets == null)
				colorOffsets = [];

			for (_ in 0...numberOfTriangles)
			{
				var transform = transforms[_];
				for (_ in 0...3)
				{
					if (transform != null)
					{
						colorMultipliers.push(transform.redMultiplier);
						colorMultipliers.push(transform.greenMultiplier);
						colorMultipliers.push(transform.blueMultiplier);

						colorOffsets.push(transform.redOffset);
						colorOffsets.push(transform.greenOffset);
						colorOffsets.push(transform.blueOffset);
						colorOffsets.push(transform.alphaOffset);
					}
					else
					{
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

	inline function setParameterValue(parameter:ShaderParameter<Bool>, value:Bool):Void
	{
		if (parameter.value == null)
			parameter.value = [];
		parameter.value[0] = value;
	}

	public static inline function inflateBounds(bounds:FlxRect, x:Float, y:Float):FlxRect
	{
		if (x < bounds.x)
		{
			bounds.width += bounds.x - x;
			bounds.x = x;
		}

		if (y < bounds.y)
		{
			bounds.height += bounds.y - y;
			bounds.y = y;
		}

		if (x > bounds.x + bounds.width)
		{
			bounds.width = x - bounds.x;
		}

		if (y > bounds.y + bounds.height)
		{
			bounds.height = y - bounds.y;
		}

		return bounds;
	}

	public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform):Void
	{
		final prevVerticesPos:Int = verticesPosition;
		final prevIndicesPos:Int = indicesPosition;
		final prevColorsPos:Int = colorsPosition;
		final prevNumberOfVertices:Int = numVertices;

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

		if (colored)
		{
			var red = 1.0;
			var green = 1.0;
			var blue = 1.0;
			var alpha = 1.0;

			if (transform != null)
			{
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

	override function get_numVertices():Int
	{
		return Std.int(vertices.length * .5);
	}

	override function get_numTriangles():Int
	{
		return Std.int(indices.length / 3);
	}
}
