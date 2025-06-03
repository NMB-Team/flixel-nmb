package flixel.graphics.tile;

import openfl.display.GraphicsShader;

class FlxGraphicsShader extends GraphicsShader
{
	@:glVertexHeader("
		in float alpha;
		in vec4 colorMultiplier;
		in vec4 colorOffset;
		uniform bool hasColorTransform;
	", true)
	@:glVertexBody("
		openfl_Alphav = openfl_Alpha;
		openfl_TextureCoordv = openfl_TextureCoord;

		if (openfl_HasColorTransform) {
			openfl_ColorMultiplierv = openfl_ColorMultiplier;
			openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
		}

		openfl_Alphav = openfl_Alpha * alpha;

		if (hasColorTransform) {
			openfl_ColorOffsetv = colorOffset / 255.0;
			openfl_ColorMultiplierv = colorMultiplier;
		}

		gl_Position = openfl_Matrix * openfl_Position;
	", true)
	@:glFragmentHeader("
		// Note: this is being set to false somewhere!
		uniform bool hasTransform;
		uniform bool hasColorTransform;
		uniform vec4 _camSize;

		vec4 transform(vec4 color, vec4 mult, vec4 offset, float alpha)
		{
			color = clamp(offset + (color * mult), 0.0, 1.0);
			return vec4(color.rgb, 1.0) * color.a * alpha;
		}

		vec4 transformIf(bool hasTransform, vec4 color, vec4 mult, vec4 offset, float alpha)
		{
			return mix(color * alpha, transform(color, mult, offset, alpha), float(hasTransform));
		}

		vec4 applyFlixelEffects(vec4 color) {
			if (!hasTransform && !openfl_HasColorTransform)
				return color;

			color = mix(color, vec4(0.0), float(color.a == 0.0));

			bool _hasTransform = openfl_HasColorTransform || hasColorTransform;
			return transformIf(_hasTransform, color, openfl_ColorMultiplierv, openfl_ColorOffsetv, openfl_Alphav);
		}

		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord) {
			vec4 color = texture(bitmap, coord);
			return applyFlixelEffects(color);
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
		ofl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
	", true)
	public function new()
	{
		super();
	}
}
