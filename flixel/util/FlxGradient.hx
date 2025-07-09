package flixel.util;

import openfl.display.BitmapData;

/**
	Adds a set of color gradient creation / rendering functions

	@version 1.6 - May 9th 2011
	@link http://www.photonstorm.com
	@author Richard Davey / Photon Storm
	@see Requires FlxMath
**/
class FlxGradient {
	public static function createGradientMatrix(width:Int, height:Int, colors:Array<FlxColor>, chunkSize:UInt = 1, rotation = 90):GradientMatrix {
		final gradientMatrix = new openfl.geom.Matrix();
		final rot = flixel.math.FlxAngle.asRadians(rotation); // Rotation (in radians) that the gradient is rotated
		final alpha:Array<Float> = []; // Create the alpha and ratio arrays

		gradientMatrix.createGradientBox(width, height / chunkSize, rot, 0, 0); // Last 2 values = horizontal and vertical shift (in pixels)

		for (ai in 0...colors.length)
			alpha.push(colors[ai].alphaFloat);

		final ratio:Array<Int> = [];

		if (colors.length == 2) {
			ratio[0] = 0;
			ratio[1] = 255;
		} else {
			final spread = Std.int(255 / (colors.length - 1)); // Spread value

			ratio.push(0);

			for (ri in 1...(colors.length - 1))
				ratio.push(ri * spread);

			ratio.push(255);
		}

		return {matrix: gradientMatrix, alpha: alpha, ratio: ratio};
	}

	public static function createGradientArray(width:Int, height:Int, colors:Array<FlxColor>, chunkSize:UInt = 1, rotation = 90, interpolate = true):Array<FlxColor> {
		final data = createGradientBitmapData(width, height, colors, chunkSize, rotation, interpolate);
		final result:Array<Int> = [];

		for (y in 0...data.height)
			result.push(data.getPixel32(0, y));

		return result;
	}

	/**
		Creates a FlxSprite of the given width/height with a colour gradient flowing through it.

		@param   width         The width of the FlxSprite (and therefore gradient)
		@param   height        The height of the FlxSprite (and therefore gradient)
		@param   colors        An array of colour values for the gradient to cycle through
		@param   chunkSize     If you want a more old-skool looking chunky gradient, increase this value!
		@param   rotation      Angle of the gradient in degrees. 90 = top to bottom, 180 = left to right. Any angle is valid
		@param   interpolate   Interpolate the colours? True uses RGB interpolation, false uses linear RGB
		@return  A FlxSprite containing your gradient (if valid parameters given!)
	**/
	public static function createGradientFlxSprite(width:Int, height:Int, colors:Array<FlxColor>, chunkSize:UInt = 1, rotation = 90, interpolate = true):FlxSprite {
		final data = createGradientBitmapData(width, height, colors, chunkSize, rotation, interpolate);
		final dest = new FlxSprite();
		dest.pixels = data;
		return dest;
	}

	public static function createGradientBitmapData(width:UInt, height:UInt, colors:Array<FlxColor>, chunkSize:UInt = 1, rotation = 90, interpolate = true):BitmapData {
		// Sanity checks
		final safeCoordinate:UInt = 1;
		if (width < safeCoordinate)
			width = safeCoordinate;

		if (height < safeCoordinate)
			height = safeCoordinate;

		final gradient = createGradientMatrix(width, height, colors, chunkSize, rotation);
		final shape = new openfl.display.Shape();
		final interpolationMethod = interpolate ? openfl.display.InterpolationMethod.RGB : openfl.display.InterpolationMethod.LINEAR_RGB;

		shape.graphics.beginGradientFill(openfl.display.GradientType.LINEAR, colors, gradient.alpha, gradient.ratio, gradient.matrix, openfl.display.SpreadMethod.PAD, interpolationMethod, 0);

		shape.graphics.drawRect(0, 0, width, height / chunkSize);

		final data = new BitmapData(width, height, true, FlxColor.TRANSPARENT);

		if (chunkSize != 1) {
			final tempBitmap = new openfl.display.Bitmap(new BitmapData(width, Std.int(height / chunkSize), true, FlxColor.TRANSPARENT));
			tempBitmap.bitmapData.draw(shape);
			tempBitmap.scaleY = chunkSize;

			final sM = new openfl.geom.Matrix();
			sM.scale(tempBitmap.scaleX, tempBitmap.scaleY);

			data.draw(tempBitmap, sM);

			// The scaled bitmap might not have filled the data. Fill the remaining pixels with the last color.
			final remainingRect = new openfl.geom.Rectangle(0, tempBitmap.height, width, height - tempBitmap.height);
			data.fillRect(remainingRect, colors[colors.length - 1]);
		} else
			data.draw(shape);

		return data;
	}

	/**
		Creates a new gradient and overlays that on-top of the given FlxSprite at the destX/destY coordinates (default 0,0)
		Use low alpha values in the colours to have the gradient overlay and not destroy the image below

		@param   dest          The FlxSprite to overlay the gradient onto
		@param   width         The width of the FlxSprite (and therefore gradient)
		@param   height        The height of the FlxSprite (and therefore gradient)
		@param   colors        An array of colour values for the gradient to cycle through
		@param   destX         The X offset the gradient is drawn at (default 0)
		@param   destY         The Y offset the gradient is drawn at (default 0)
		@param   chunkSize     If you want a more old-skool looking chunky gradient, increase this value!
		@param   rotation      Angle of the gradient in degrees. 90 = top to bottom, 180 = left to right. Any angle is valid
		@param   interpolate   Interpolate the colours? True uses RGB interpolation, false uses linear RGB
		@return  The composited FlxSprite (for chaining, if you need)
	**/
	public static function overlayGradientOnFlxSprite(dest:FlxSprite, width:Int, height:Int, colors:Array<FlxColor>, destX = 0, destY = 0, chunkSize:UInt = 1, rotation = 90, interpolate = true):FlxSprite {
		if (width > dest.width)
			width = Std.int(dest.width);

		if (height > dest.height)
			height = Std.int(dest.height);

		final source = createGradientFlxSprite(width, height, colors, chunkSize, rotation, interpolate);
		dest.stamp(source, destX, destY);
		source.destroy();
		return dest;
	}

	/**
		Creates a new gradient and overlays that on-top of the given BitmapData at the destX/destY coordinates (default 0,0)
		Use low alpha values in the colours to have the gradient overlay and not destroy the image below

		@param   dest          The BitmapData to overlay the gradient onto
		@param   width         The width of the FlxSprite (and therefore gradient)
		@param   height        The height of the FlxSprite (and therefore gradient)
		@param   colors        An array of colour values for the gradient to cycle through
		@param   destX         The X offset the gradient is drawn at (default 0)
		@param   destY         The Y offset the gradient is drawn at (default 0)
		@param   chunkSize     If you want a more old-skool looking chunky gradient, increase this value!
		@param   rotation      Angle of the gradient in degrees. 90 = top to bottom, 180 = left to right. Any angle is valid
		@param   interpolate   Interpolate the colours? True uses RGB interpolation, false uses linear RGB
		@return  The composited BitmapData
	**/
	public static function overlayGradientOnBitmapData(dest:BitmapData, width:Int, height:Int, colors:Array<FlxColor>, destX = 0, destY = 0, chunkSize:UInt = 1, rotation = 90, interpolate = true):BitmapData {
		if (width > dest.width)
			width = dest.width;

		if (height > dest.height)
			height = dest.height;

		final source = createGradientBitmapData(width, height, colors, chunkSize, rotation, interpolate);
		dest.copyPixels(source, new openfl.geom.Rectangle(0, 0, source.width, source.height), new openfl.geom.Point(destX, destY), null, null, true);
		source.dispose();
		return dest;
	}
}

typedef GradientMatrix = {
	matrix:openfl.geom.Matrix,
	alpha:Array<Float>,
	ratio:Array<Int>
}
