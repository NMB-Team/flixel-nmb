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

		vec4 flixel_applyColorTransform(vec4 color) {
			if (!isFlixelDraw || color.a == 0.0)
				return color;

			if (openfl_HasColorTransform || hasTransform || hasColorTransform) {
				float _tempAlpha = color.a;
				color.rgb /= _tempAlpha;
				color = clamp(openfl_ColorOffsetv + color * openfl_ColorMultiplierv, 0.0, 1.0);
				color.rgb = color.rgb * _tempAlpha;
			}

			return color * openfl_Alphav;
		}

		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord) {
			return flixel_applyColorTransform(texture(bitmap, coord));
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
