package flixel.graphics.tile;

class FlxGraphicsShader extends openfl.display.GraphicsShader {
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
		uniform bool isFlixelDraw;
		#define hasTransform isFlixelDraw
		uniform bool hasColorTransform;

		vec4 transform(vec4 color, vec4 mult, vec4 offset, float alpha) {
			color = clamp(offset + (color * mult), 0.0, 1.0);
			return vec4(color.rgb, 1.0) * color.a * alpha;
		}

		vec4 transformIf(bool _isFlixelDraw, vec4 color, vec4 mult, vec4 offset, float alpha) {
			return mix(color * alpha, transform(color, mult, offset, alpha), float(_isFlixelDraw));
		}

		vec4 applyFlixelEffects(vec4 color) {
			if (!isFlixelDraw && !openfl_HasColorTransform)
				return color;

			color = mix(color, vec4(0.0), float(color.a == 0.0));

			bool _hasTransform = openfl_HasColorTransform || hasColorTransform;
			return transformIf(_hasTransform, color, openfl_ColorMultiplierv, openfl_ColorOffsetv, openfl_Alphav);
		}

		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord) {
			return applyFlixelEffects(texture(bitmap, coord));
		}
	", true)
	@:glFragmentBody("
		ofl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
	", true)
	public function new() {
		super();
	}
}
