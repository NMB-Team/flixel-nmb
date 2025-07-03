package flixel.graphics.frames.bmfont;

import haxe.io.BytesInput;

/**
 * Kerning data used internally via `FlxBitmapFont.fromAngelCode` to serialize text, xml or binary
 * files exported from [BMFont](https://www.angelcode.com/products/bmfont/)
 *
 * @since 5.6.0
 * @see [flixel.graphics.frames.FlxBitmapFont.fromAngelCode](https://api.haxeflixel.com/flixel/graphics/frames/FlxBitmapFont.html#fromAngelCode)
 */
@:allow(flixel.graphics.frames.bmfont.BMFont)
@:structInit class BMFontKerning {
	public var first:Int;
	public var second:Int;
	public var amount:Int;

	public inline function new(first = -1, second = -1, amount = 0) {
		this.first = first;
		this.second = second;
		this.amount = amount;
	}

	static function fromXml(kerningNode:BMFontXml):BMFontKerning {
		return {
			first: kerningNode.att.int("first"),
			second: kerningNode.att.int("second"),
			amount: kerningNode.att.int("amount")
		}
	}

	static function listFromXml(kerningsNode:BMFontXml):Array<BMFontKerning> {
		final kernings = kerningsNode.nodes("kerning");
		return [for (pair in kernings) fromXml(pair)];
	}

	static function fromText(kerningText:String):BMFontKerning {
		var first = -1;
		var second = -1;
		var amount = -1;
		BMFontUtil.forEachAttribute(kerningText, (key:String, value:UnicodeString) -> {
				switch key {
					case 'first': first = Std.parseInt(value);
					case 'second': second = Std.parseInt(value);
					case 'amount': amount = Std.parseInt(value);
				}
			}
		);
		return new BMFontKerning(first, second, amount);
	}

	static function listFromBytes(bytes:BytesInput) {
		var blockSize = bytes.readInt32();
		final kernings = new Array<BMFontKerning>();
		while (blockSize > 0) {
			final kerning:BMFontKerning = {
				first: bytes.readInt32(),
				second: bytes.readInt32(),
				amount: bytes.readInt16()
			};
			kernings.push(kerning);
			blockSize -= 10; // 4 + 4 + 2
		}
		return kernings;
	}
}