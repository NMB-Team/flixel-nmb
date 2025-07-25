package flixel.system.frontEnds;

import flixel.FlxG;

class RenderFrontEnd
{
	public var method:FlxRenderMethod;
	public var blit(default, null):Bool;
	public var tile(default, null):Bool;

	public var pixelMode(default, null):FlxPixelMode = CUSTOM;

	public function new() {}

	@:allow(flixel.FlxG)
	function init()
	{
		method = BLITTING;

		#if (!lime_legacy)
		method = switch (FlxG.stage.window.context.type)
		{
			case OPENGL, OPENGLES, WEBGL: DRAW_TILES;
			default: BLITTING;
		}
		#else
		#if web
		method = BLITTING;
		#else
		method = DRAW_TILES;
		#end
		#end

		blit = method == BLITTING;
		tile = method == DRAW_TILES;

		FlxObject.defaultPixelPerfectPosition = blit;
	}

	public function setPixelMode(value:FlxPixelMode)
	{
		this.pixelMode = value;
		switch value
		{
			case CUSTOM: // do nothing
			case PIXELATED:
				FlxSprite.defaultAntialiasing = false;

				if (FlxG.state != null)
					FlxG.stage.quality = LOW;

				#if html5
				lime.app.Application.current.window.element.style.setProperty("image-rendering", "pixelated");
				#end
			case SMOOTH:
				FlxSprite.defaultAntialiasing = true;

				if (FlxG.state != null)
					FlxG.stage.quality = HIGH;

				#if html5
				lime.app.Application.current.window.element.style.removeProperty("image-rendering");
				#end
		}
	}
}

enum FlxRenderMethod
{
	DRAW_TILES;
	BLITTING;
}

enum FlxPixelMode
{
	/**
	 * Enables various features that result in crisp pixels, namely:
	 * - Changes `FlxSprite.defaultAntialiasing` to `false`
	 * - On web, changes the window's `image-rendering` to `"pixelated"`
	 */
	PIXELATED;

	/**
	 * Makes no changes to any default rendering properties
	 */
	CUSTOM;

	/**
	 * Enables various features that result in crisp pixels, namely:
	 * - Changes `FlxSprite.defaultAntialiasing` to `true`
	 * - On web, removes the window's `image-rendering` its default value (no value)
	 */
	SMOOTH;
}