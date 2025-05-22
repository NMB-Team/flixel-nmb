package flixel.graphics.tile;

import openfl.display.GraphicsShader;

class FlxGraphicsShader extends GraphicsShader
{
	@:glVertexHeader("
		attribute float alpha;
		attribute vec4 colorMultiplier;
		attribute vec4 colorOffset;
		uniform bool hasColorTransform;
	", true)
	@:glVertexBody("
		openfl_Alphav = openfl_Alpha * alpha;
		
		if (hasColorTransform)
		{
			if (openfl_HasColorTransform)
			{
				openfl_ColorOffsetv = (openfl_ColorOffsetv * colorMultiplier) + (colorOffset / 255.0);
				openfl_ColorMultiplierv *= colorMultiplier;
			}
			else
			{
				openfl_ColorOffsetv = colorOffset / 255.0;
				openfl_ColorMultiplierv = colorMultiplier;
			}
		}
	", true)
	@:glFragmentHeader("
		uniform bool hasTransform;  // TODO: Is this still needed? Apparently, yes!
		uniform bool hasColorTransform;
		uniform vec4 _camSize;

		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
		{
			vec4 color = texture2D(bitmap, coord);
			if (!(hasTransform || openfl_HasColorTransform))
				return color;

			if (color.a == 0.0)
				return vec4(0.0, 0.0, 0.0, 0.0);

			if (openfl_HasColorTransform || hasColorTransform)
			{
				color = vec4 (color.rgb / color.a, color.a);
				vec4 mult = vec4 (openfl_ColorMultiplierv.rgb, 1.0);
				color = clamp (openfl_ColorOffsetv + (color * mult), 0.0, 1.0);
				
				if (color.a == 0.0)
					return vec4 (0.0, 0.0, 0.0, 0.0);
				
				return vec4 (color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
			}
			return color * openfl_Alphav;
		}

		float map(float value, float min1, float max1, float min2, float max2) {
			return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
		}
		
		vec2 getCamPos(vec2 pos) {
			vec4 size = _camSize / vec4(openfl_TextureSize, openfl_TextureSize);
			return vec2(map(pos.x, size.x, size.x + size.z, 0.0, 1.0), map(pos.y, size.y, size.y + size.w, 0.0, 1.0));
		}
		vec2 camToOg(vec2 pos) {
			vec4 size = _camSize / vec4(openfl_TextureSize, openfl_TextureSize);
			return vec2(map(pos.x, 0.0, 1.0, size.x, size.x + size.z), map(pos.y, 0.0, 1.0, size.y, size.y + size.w));
		}
		vec4 textureCam(sampler2D bitmap, vec2 pos) {
			return flixel_texture2D(bitmap, camToOg(pos));
		}
	", true)
	@:glFragmentBody("
		gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
	", true)
	public function new()
	{
		super();
	}
}