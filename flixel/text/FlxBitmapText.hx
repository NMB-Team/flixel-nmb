package flixel.text;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

/**
 * Extends FlxSprite to support rendering text.
 * Can tint, fade, rotate and scale just like a sprite.
 * Doesn't really animate though, as far as I know.
 */
class FlxBitmapText extends FlxSprite
{
	/**
	 * Font for text rendering.
	 */
	public var font(default, set):FlxBitmapFont;

	/**
	 * Text to display.
	 */
	public var text(default, set):UnicodeString = "";

	/**
	 * Helper object to avoid many ColorTransform allocations
	 */
	var _colorParams:ColorTransform = new ColorTransform();

	/**
	 * Helper array which contains actual strings for rendering.
	 */
	var _lines:Array<UnicodeString> = [];

	/**
	 * Helper array which contains width of each displayed lines.
	 */
	var _linesWidth:Array<Int> = [];

	/**
	 * Specifies how the text field should align text.
	 * JUSTIFY alignment isn't supported.
	 * Note: 'autoSize' must be set to false or alignment won't show any visual differences.
	 */
	public var alignment(default, set):FlxTextAlign = FlxTextAlign.LEFT;

	/**
	 * The distance to add between lines.
	 */
	public var lineSpacing(default, set):Int = 0;

	/**
	 * The distance to add between letters.
	 */
	public var letterSpacing(default, set):Int = 0;

	/**
	 * Whether to convert text to upper case or not.
	 */
	public var autoUpperCase(default, set):Bool = false;

	/**
	 * The type of automatic wrapping to use, when the text doesn't fit the width. Ignored when
	 * `autoSize` is true. Use options like: `NONE`, `CHAR`, `WORD(NEVER)` and `WORD(FIELD_WIDTH)`
	 */
	public var wrap(default, set):Wrap = WORD(NEVER);

	/**
	 * Whether this text field have fixed width or not.
	 * Default value if true.
	 */
	public var autoSize(default, set):Bool = true;

	/**
	 * Whether to autmatically adjust the `width`, `height`, `offset` and
	 * `origin` whenever the size of the text is changed.
	 * @since 6.1.0
	 */
	public var autoBounds(default, set):Bool = true;

	/**
	 * Number of pixels between text and text field border
	 */
	public var padding(default, set):Int = 0;

	/**
	 * Width of the text in this text field.
	 */
	public var textWidth(get, never):Int;

	/**
	 * Height of the text in this text field.
	 */
	public var textHeight(get, never):Int;

	/**
	 * Height of the single line of text (without lineSpacing).
	 */
	public var lineHeight(get, never):Int;

	/**
	 * Number of space characters in one tab.
	 */
	public var numSpacesInTab(default, set):Int = 4;

	/**
	 * The color of the text in 0xAARRGGBB format.
	 * Result color of text will be multiplication of textColor and color.
	 */
	public var textColor(default, set):FlxColor = FlxColor.WHITE;

	/**
	 * Whether to use textColor while rendering or not.
	 */
	public var useTextColor(default, set):Bool = false;

	/**
	 * Use a border style
	 */
	public var borderStyle(default, set):FlxTextBorderStyle = NONE;

	/**
	 * The color of the border in 0xAARRGGBB format
	 */
	public var borderColor(default, set):FlxColor = FlxColor.BLACK;

	/**
	 * The size of the border, in pixels.
	 */
	public var borderSize(default, set):Float = 1;

	/**
	 * How many iterations do use when drawing the border. 0: only 1 iteration, 1: one iteration for every pixel in borderSize
	 * A value of 1 will have the best quality for large border sizes, but might reduce performance when changing text.
	 * NOTE: If the borderSize is 1, borderQuality of 0 or 1 will have the exact same effect (and performance).
	 */
	public var borderQuality(default, set):Float = 0;

	/**
	 * Specifies whether the text should have a background. It is recommended to use a
	 * `padding` of `1` or more with a background, especially when using a border style
	 */
	public var background(default, set):Bool = false;

	/**
	 * Specifies the color of background
	 */
	public var backgroundColor(default, set):FlxColor = FlxColor.TRANSPARENT;

	/**
	 * Specifies whether the text field will break into multiple lines or not on overflow.
	 */
	public var multiLine(default, set):Bool = true;

	/**
	 * Reflects how many lines have this text field.
	 */
	public var numLines(get, never):Int;

	/**
	 * The width of the TextField object used for bitmap generation for this FlxText object.
	 * Use it when you want to change the visible width of text. Enables autoSize if <= 0.
	 */
	public var fieldWidth(get, set):Int;

	var _fieldWidth:Int;

	var pendingTextChange:Bool = true;
	var pendingTextBitmapChange:Bool = true;
	var pendingPixelsChange:Bool = true;

	var textData:CharList;
	var textDrawData:CharList;
	var borderDrawData:CharList;

	/**
	 * Helper bitmap buffer for text pixels but without any color transformations
	 */
	var textBitmap:BitmapData;

	/**
	 * Constructs a new text field component.
	 * Warning: The default font may work incorrectly on HTML5
	 * and is utterly unreliable on Brave Browser with shields up.
	 *
	 * @param   x     The initial X position of the text.
	 * @param   y     The initial Y position of the text.
	 * @param   text  The text to display.
	 * @param   font  Optional parameter for component's font prop
	 */
	public function new(?x = 0.0, ?y = 0.0, text:UnicodeString = "", ?font:FlxBitmapFont)
	{
		super(x, y);

		width = fieldWidth = 2;
		alpha = 1;

		this.font = (font == null) ? FlxBitmapFont.getDefaultFont() : font;

		if (FlxG.render.blit)
		{
			pixels = new BitmapData(1, 1, true, FlxColor.TRANSPARENT);
		}
		else
		{
			textData = [];
			textDrawData = [];
			borderDrawData = [];
		}

		this.text = text;
	}

	/**
	 * Clears all resources used.
	 */
	override public function destroy():Void
	{
		font = null;
		text = null;
		_lines = null;
		_linesWidth = null;

		textBitmap = FlxDestroyUtil.dispose(textBitmap);

		_colorParams = null;

		if (FlxG.render.tile)
		{
			textData = null;
			textDrawData = null;
			borderDrawData = null;
		}
		super.destroy();
	}

	/**
	 * Forces graphic regeneration for this text field.
	 */
	override public function drawFrame(Force:Bool = false):Void
	{
		if (FlxG.render.tile)
		{
			Force = true;
		}
		pendingTextBitmapChange = pendingTextBitmapChange || Force;
		checkPendingChanges(false);
		if (FlxG.render.blit)
		{
			super.drawFrame(Force);
		}
	}

	override function updateHitbox()
	{
		checkPendingChanges(true);
		super.updateHitbox();
	}

	function checkPendingChanges(useTiles:Bool = false):Void
	{
		if (FlxG.render.blit)
		{
			useTiles = false;
		}

		if (pendingTextChange)
		{
			updateText();
			pendingTextBitmapChange = true;
		}

		if (pendingTextBitmapChange)
		{
			updateTextBitmap(useTiles);
			pendingPixelsChange = true;
		}

		if (pendingPixelsChange)
		{
			updatePixels(useTiles);
		}
	}

	// TODO: Make these all local statics when min haxe-ver is 4.3
	static final bgColorTransformDrawHelper = new ColorTransform();
	static final borderColorTransformDrawHelper = new ColorTransform();
	static final textColorTransformDrawHelper = new ColorTransform();
	static final matrixDrawHelper = new FlxMatrix();
	static final frameDrawHelper = new ReusableFrame();
	override function draw()
	{
		if (FlxG.render.blit)
		{
			checkPendingChanges(false);
			super.draw();
		}
		else
		{
			checkPendingChanges(true);

			final colorHelper = Std.int(alpha * 0xFF) << 24 | this.color.rgb;

			final textColorTransform = textColorTransformDrawHelper.reset();
			textColorTransform.setMultipliers(colorHelper);
			if (useTextColor)
				textColorTransform.scaleMultipliers(textColor);

			final borderColorTransform = borderColorTransformDrawHelper.reset();
			borderColorTransform.setMultipliers(borderColor).scaleMultipliers(colorHelper);

			final scaleX:Float = scale.x * _facingHorizontalMult;
			final scaleY:Float = scale.y * _facingVerticalMult;

			final originX:Float = _facingHorizontalMult != 1 ? frameWidth - origin.x : origin.x;
			final originY:Float = _facingVerticalMult != 1 ? frameHeight - origin.y : origin.y;

			final clippedFrameRect = FlxRect.get(0, 0, frameWidth, frameHeight);

			if (clipRect != null)
				clippedFrameRect.clipTo(clipRect);

			if (clippedFrameRect.isEmpty)
				return;

			final charClipHelper = FlxRect.get();
			final charClippedFrame = frameDrawHelper;
			final screenPos = FlxPoint.get();

			final cameras = getCamerasLegacy();
			for (camera in cameras)
			{
				if (!camera.visible || !camera.exists || !isOnScreen(camera))
				{
					continue;
				}

				getScreenPosition(screenPos, camera).subtractPoint(offset);

				if (isPixelPerfectRender(camera))
				{
					screenPos.floor();
				}

				updateTrig();

				if (background)
				{
					// backround tile transformations
					final matrix = matrixDrawHelper;
					matrix.identity();
					matrix.scale(0.1 * clippedFrameRect.width, 0.1 * clippedFrameRect.height);
					matrix.translate(clippedFrameRect.x - originX, clippedFrameRect.y - originY);
					matrix.scale(scaleX, scaleY);

					if (angle != 0)
					{
						matrix.rotateWithTrig(_cosAngle, _sinAngle);
					}

					matrix.translate(screenPos.x + originX, screenPos.y + originY);
					final colorTransform = bgColorTransformDrawHelper.reset();
					colorTransform.setMultipliers(colorHelper).scaleMultipliers(backgroundColor);
					camera.drawPixels(FlxG.bitmap.whitePixel, null, matrix, colorTransform, blend, antialiasing);
				}

				final hasColorOffsets = (colorTransform != null && colorTransform.hasRGBAOffsets());
				final drawItem = camera.startQuadBatch(font.parent, true, hasColorOffsets, blend, antialiasing, shader);
				function addQuad(charCode:Int, x:Float, y:Float, color:ColorTransform)
				{
					var frame = font.getCharFrame(charCode);
					if (clipRect != null)
					{
						charClipHelper.copyFrom(clippedFrameRect).offset(-x, -y);
						if (!frame.isContained(charClipHelper))
							frame = frame.clipTo(charClipHelper, charClippedFrame);
					}

					final matrix = matrixDrawHelper;
					frame.prepareMatrix(matrix);
					matrix.translate(x - originX, y - originY);
					matrix.scale(scaleX, scaleY);
					if (angle != 0)
					{
						matrix.rotateWithTrig(_cosAngle, _sinAngle);
					}

					matrix.translate(screenPos.x + originX, screenPos.y + originY);
					drawItem.addQuad(frame, matrix, color);
				}

				borderDrawData.forEach(addQuad.bind(_, _, _, borderColorTransform));
				textDrawData.forEach(addQuad.bind(_, _, _, textColorTransform));
				#if FLX_DEBUG
				FlxBasic.visibleCount++;
				#end
			}

			// dispose helpers
			charClipHelper.put();
			clippedFrameRect.put();
			screenPos.put();

			#if FLX_DEBUG
			if (FlxG.debugger.drawDebug)
			{
				drawDebug();
			}
			#end
		}
	}

	override function set_clipRect(Rect:FlxRect):FlxRect
	{
		super.set_clipRect(Rect);
		if (!FlxG.render.blit)
		{
			pendingTextBitmapChange = true;
		}
		return clipRect;
	}

	override function set_color(Color:FlxColor):FlxColor
	{
		super.set_color(Color);
		if (FlxG.render.blit)
		{
			pendingTextBitmapChange = true;
		}
		return color;
	}

	override function set_alpha(value:Float):Float
	{
		super.set_alpha(value);
		if (FlxG.render.blit)
		{
			pendingTextBitmapChange = true;
		}
		return value;
	}

	function set_textColor(value:FlxColor):FlxColor
	{
		if (textColor != value)
		{
			textColor = value;
			if (FlxG.render.blit)
			{
				pendingPixelsChange = true;
			}
		}

		return value;
	}

	function set_useTextColor(value:Bool):Bool
	{
		if (useTextColor != value)
		{
			useTextColor = value;
			if (FlxG.render.blit)
			{
				pendingPixelsChange = true;
			}
		}

		return value;
	}

	override function calcFrame(RunOnCpp:Bool = false):Void
	{
		if (FlxG.render.tile)
		{
			drawFrame(RunOnCpp);
		}
		else
		{
			super.calcFrame(RunOnCpp);
		}
	}

	function set_text(value:UnicodeString):UnicodeString
	{
		if (value != text)
		{
			text = value;
			pendingTextChange = true;
		}

		return value;
	}

	function updateText():Void
	{
		var tmp:UnicodeString = (autoUpperCase) ? (text : UnicodeString).toUpperCase() : text;

		_lines = tmp.split("\n");

		if (!autoSize)
		{
			if (wrap != NONE)
			{
				_lines = autoWrap(_lines);
			}
			else
			{
				_lines = cutLines(_lines);
			}
		}

		if (!multiLine)
		{
			_lines = [_lines[0]];
		}

		var numLines:Int = _lines.length;
		for (i in 0...numLines)
		{
			_lines[i] = StringTools.rtrim(_lines[i]);
		}

		pendingTextChange = false;
		pendingTextBitmapChange = true;
	}

	/**
	 * Calculates the size of text field.
	 */
	function computeTextSize():Void
	{
		final txtWidth = autoSize ? textWidth + padding * 2 : fieldWidth;
		final txtHeight = textHeight + padding * 2;

		frameWidth = (txtWidth == 0) ? 1 : txtWidth;
		frameHeight = (txtHeight == 0) ? 1 : txtHeight;
	}

	/**
	 * Calculates width of the line with provided index
	 *
	 * @param	lineIndex	index of the line in _lines array
	 * @return	The width of the line
	 */
	public function getLineWidth(lineIndex:Int):Int
	{
		if (lineIndex < 0 || lineIndex >= _lines.length)
		{
			return 0;
		}

		return getStringWidth(_lines[lineIndex]);
	}

	/**
	 * Calculates width of provided string (for current font).
	 *
	 * @param	str	String to calculate width for
	 * @return	The width of result bitmap text.
	 */
	public function getStringWidth(str:UnicodeString):Int
	{
		var spaceWidth:Int = font.spaceWidth;
		var tabWidth:Int = spaceWidth * numSpacesInTab;

		var lineLength:Int = str.length;
		var lineWidth:Float = font.minOffsetX;

		var charCode:Int; // current character in word
		var charWidth:Float; // the width of current character
		var charFrame:FlxFrame;

		for (c in 0...lineLength)
		{
			charCode = str.charCodeAt(c);
			charWidth = 0;

			if (charCode == FlxBitmapFont.SPACE_CODE)
			{
				charWidth = spaceWidth;
			}
			else if (charCode == FlxBitmapFont.TAB_CODE)
			{
				charWidth = tabWidth;
			}
			else if (font.charExists(charCode))
			{
				charWidth = font.getCharAdvance(charCode);

				if (c == (lineLength - 1))
				{
					charFrame = font.getCharFrame(charCode);
					charWidth = Std.int(charFrame.sourceSize.x);
				}
			}

			lineWidth += (charWidth + letterSpacing);
		}

		if (lineLength > 0)
		{
			lineWidth -= letterSpacing;
		}

		return Std.int(lineWidth);
	}

	/**
	 * Just cuts the lines which are too long to fit in the field.
	 */
	function cutLines(lines:Array<UnicodeString>)
	{
		for (i in 0...lines.length)
		{
			final line = lines[i];
			var lineWidth = font.minOffsetX;

			var prevCode = -1;
			for (c in 0...line.length)
			{
				// final char = line.charAt(c);
				final charCode = line.charCodeAt(c);
				if (prevCode == -1)
				{
					lineWidth += getCharAdvance(charCode, font.spaceWidth) + letterSpacing;
				}
				else
					lineWidth += getCharPairAdvance(prevCode, charCode, font.spaceWidth) + letterSpacing;

				if (lineWidth > _fieldWidth - 2 * padding)
				{
					// cut every character after this
					lines[i] = lines[i].substr(0, c);
					break;
				}
			}
		}
		return lines;
	}

	function getCharAdvance(charCode:Int, spaceWidth:Int)
	{
		switch (charCode)
		{
			case FlxBitmapFont.SPACE_CODE:
				return spaceWidth;
			case FlxBitmapFont.TAB_CODE:
				return spaceWidth * numSpacesInTab;
			case charCode:
				final advance = font.getCharAdvance(charCode);
				if (isUnicodeComboMark(charCode))
					return -advance;
				return advance;
		}
	}

	function getCharPairAdvance(prevCode:Int, nextCode:Int, spaceWidth:Int)
	{
		return getCharAdvance(prevCode, spaceWidth) + font.getKerning(prevCode, nextCode);
	}

	/**
	 * Adds soft wraps to the text and cuts lines based on how it would be displayed in this field,
	 * Also converts to upper-case, if `autoUpperCase` is `true`
	 */
	public function getRenderedText(text:UnicodeString)
	{
		text = (autoUpperCase) ? (text : UnicodeString).toUpperCase() : text;

		if (!autoSize)
		{
			var lines = text.split("\n");
			if (wrap != NONE)
				return autoWrap(lines).join("\n");

			return cutLines(lines).join("\n");
		}

		return text;
	}

	/**
	 * Automatically wraps text by figuring out how many characters can fit on a
	 * single line, and splitting the remainder onto a new line.
	 */
	function autoWrap(lines:Array<UnicodeString>)
	{
		// subdivide lines
		var newLines:Array<UnicodeString> = [];
		var words:Array<UnicodeString>; // the array of words in the current line

		for (line in lines)
		{
			words = [];
			// split this line into words
			splitLineIntoWords(line, words);

			switch(wrap)
			{
				case NONE:
					throw "autoWrap called with wrap:NONE";
				case WORD(splitWords):
					wrapLineByWord(words, newLines, splitWords);
				case CHAR:
					wrapLineByCharacter(words, newLines);
			}
		}

		return newLines;
	}

	/**
	 * Helper function for splitting line of text into separate words.
	 *
	 * @param   line   Line to split.
	 * @param   words  Result array to fill with words.
	 */
	function splitLineIntoWords(line:UnicodeString, words:Array<UnicodeString>):Void
	{
		var word:UnicodeString = ""; // current word to process
		var isSpaceWord:Bool = false; // whether current word consists of spaces or not
		var lineLength:Int = line.length; // lenght of the current line

		var c:Int = 0; // char index on the line
		while (c < lineLength)
		{
			final charCode = line.charCodeAt(c);
			if (charCode == FlxBitmapFont.SPACE_CODE || charCode == FlxBitmapFont.TAB_CODE)
			{
				if (!isSpaceWord)
				{
					isSpaceWord = true;

					if (word != "")
					{
						words.push(word);
						word = "";
					}
				}

				word = word + String.fromCharCode(charCode);
			}
			else if (charCode == '-'.code)
			{
				if (isSpaceWord && word != "")
				{
					isSpaceWord = false;
					words.push(word);
					words.push('-');
				}
				else if (!isSpaceWord)
				{
					words.push(word + String.fromCharCode(charCode));
				}

				word = "";
			}
			else
			{
				if (isSpaceWord && word != "")
				{
					isSpaceWord = false;
					words.push(word);
					word = "";
				}

				word = word + String.fromCharCode(charCode);
			}

			c++;
		}

		if (word != "")
			words.push(word);
	}

	/**
	 * Wraps provided line by words.
	 *
	 * @param   words     The array of words in the line to process.
	 * @param   newLines  Array to fill with result lines.
	 */
	function wrapLineByWord(words:Array<UnicodeString>, lines:Array<UnicodeString>, wordSplit:WordSplitConditions):Void
	{
		if (words.length == 0)
			return;

		final maxLineWidth = _fieldWidth - 2 * padding;
		final startX:Int = font.minOffsetX;
		var lineWidth = startX;
		var line:UnicodeString = "";
		var word:String = null;
		var wordWidth:Int = 0;
		var i = 0;

		function addWord(word:String, wordWidth = -1)
		{
			line = line + word; // `line += word` is broken in html5 on haxe 4.2.5
			lineWidth += (wordWidth < 0 ? getWordWidth(word) : wordWidth) + letterSpacing;
		}

		inline function addCurrentWord()
		{
			addWord(word, wordWidth);
			i++;
		}

		function startNewLine()
		{
			if (line != "")
				lines.push(line);

			// start a new line
			line = "";
			lineWidth = startX;
		}

		function addWordByChars()
		{
			// put the word on the next line and split the word if it exceeds fieldWidth
			var chunks:Array<UnicodeString> = [];
			wrapLineByCharacter([line, word], chunks);

			// add all but the last chunk as a new line, the last chunk starts the next line
			while (chunks.length > 1)
				lines.push(chunks.shift());

			line = chunks.shift();
			lineWidth = startX + getWordWidth(line);
			i++;
		}

		while (i < words.length)
		{
			word = words[i];
			wordWidth = getWordWidth(word);

			if (lineWidth + wordWidth <= maxLineWidth)
			{
				// the word fits in the current line
				addCurrentWord();
				continue;
			}

			if (isSpaceWord(word))
			{
				// skip spaces when starting a new line
				startNewLine();
				i++;
				continue;
			}

			final wordFitsLine = startX + wordWidth <= maxLineWidth;

			switch (wordSplit)
			{
				case LINE_WIDTH if(!wordFitsLine):
					addWordByChars();
				case LENGTH(min) if (word.length >= min) :
					addWordByChars();
				case WIDTH(min) if (wordWidth >= min) :
					addWordByChars();
				case NEVER | LINE_WIDTH | LENGTH(_) | WIDTH(_):
					// add word to next line, continue as normal
					startNewLine();
					addCurrentWord();
			}

			if (lineWidth > maxLineWidth)
				startNewLine();
		}

		// add the final line, since previous lines were added when the next one started
		if (line != "")
			lines.push(line);
	}

	/**
	 * Wraps provided line by characters (as in standart text fields).
	 *
	 * @param	words		The array of words in the line to process.
	 * @param	newLines	Array to fill with result lines.
	 */
	function wrapLineByCharacter(words:Array<UnicodeString>, lines:Array<UnicodeString>):Void
	{
		if (words.length == 0)
			return;

		final startX:Int = font.minOffsetX;
		var line:UnicodeString = "";
		var lineWidth = startX;

		for (word in words)
		{
			for (c in 0...word.length)
			{
				final char = word.charAt(c);
				final charWidth = getCharWidth(char);

				lineWidth += charWidth;

				if (lineWidth <= _fieldWidth - 2 * padding) // the char fits, add it
				{
					line = line + char; // `line += char` is broken in html5 on haxe 4.2.5
					lineWidth += letterSpacing;
				}
				else // the char cannot fit on the current line
				{
					if (isSpaceWord(word)) // end the line, eat the spaces
					{
						lines.push(line);
						line = "";
						lineWidth = startX;
						break; // skip all remaining space/tabs in the "word"
					}
					else
					{
						if (line != "") // new line isn't empty so we should add it to sublines array and start another one
							lines.push(line);

						// start a new line with the next character
						line = char;
						lineWidth = startX + charWidth + letterSpacing;
					}
				}
			}
		}

		if (line != "")
			lines.push(line);
	}

	function getWordWidth(word:UnicodeString)
	{
		var wordWidth = 0;
		for (c in 0...word.length)
			wordWidth += getCharAdvance(word.charCodeAt(c), font.spaceWidth);

		return wordWidth + (word.length - 1) * letterSpacing;
	}

	function getCharWidth(char:UnicodeString)
	{
		return getCharAdvance(char.charCodeAt(0), font.spaceWidth);
	}

	static inline function isSpaceWord(word:UnicodeString)
	{
		final firstCode = word.charCodeAt(0);
		return isSpaceChar(firstCode);
	}

	static inline function isSpaceChar(charCode:Int)
	{
		return charCode == FlxBitmapFont.SPACE_CODE || charCode == FlxBitmapFont.TAB_CODE;
	}

	/**
	 * Internal method for updating helper data for text rendering
	 */
	function updateTextBitmap(useTiles:Bool = false):Void
	{
		computeTextSize();

		if (FlxG.render.blit)
		{
			useTiles = false;
		}

		if (!useTiles)
		{
			textBitmap = FlxDestroyUtil.disposeIfNotEqual(textBitmap, frameWidth, frameHeight);

			if (textBitmap == null)
			{
				textBitmap = new BitmapData(frameWidth, frameHeight, true, FlxColor.TRANSPARENT);
			}
			else
			{
				textBitmap.fillRect(textBitmap.rect, FlxColor.TRANSPARENT);
			}

			textBitmap.lock();
		}
		else if (FlxG.render.tile)
		{
			textData.clear();
		}

		_fieldWidth = frameWidth;

		var numLines:Int = _lines.length;
		var line:UnicodeString;
		var lineWidth:Int;

		var ox:Int, oy:Int;

		for (i in 0...numLines)
		{
			line = _lines[i];
			lineWidth = _linesWidth[i];

			// LEFT
			ox = font.minOffsetX;
			oy = i * (font.lineHeight + lineSpacing) + padding;

			if (alignment == FlxTextAlign.CENTER)
			{
				ox += Std.int((frameWidth - lineWidth) * .5);
			}
			else if (alignment == FlxTextAlign.RIGHT)
			{
				ox += (frameWidth - lineWidth) - padding;
			}
			else // LEFT OR JUSTIFY
			{
				ox += padding;
			}

			drawLine(_lines[i], ox, oy, useTiles);
		}

		if (!useTiles)
		{
			textBitmap.unlock();
		}

		pendingTextBitmapChange = false;
	}

	function drawLine(line:UnicodeString, posX:Int, posY:Int, useTiles:Bool = false):Void
	{
		if (FlxG.render.blit)
		{
			useTiles = false;
		}

		if (useTiles)
		{
			tileLine(line, posX, posY);
		}
		else
		{
			blitLine(line, posX, posY);
		}
	}

	function blitLine(line:UnicodeString, startX:Int, startY:Int):Void
	{
		final data:CharList = [];
		addLineData(line, startX, startY, data);

		data.forEach(function (charCode, x, y)
		{
			final charFrame = font.getCharFrame(charCode);
			_flashPoint.setTo(x, y);
			charFrame.paint(textBitmap, _flashPoint, true);
		});
	}

	function tileLine(line:UnicodeString, startX:Int, startY:Int)
	{
		if (!FlxG.render.tile)
			return;

		addLineData(line, startX, startY, textData);
	}

	function addLineData(line:UnicodeString, startX:Int, startY:Int, data:CharList)
	{
		var curX:Float = startX;
		var curY:Int = startY;

		final lineLength:Int = line.length;
		final textWidth:Int = this.textWidth;

		var spaceWidth:Int = font.spaceWidth;
		if (alignment == FlxTextAlign.JUSTIFY)
		{
			final lineWidth:Int = getStringWidth(line);
			final numSpaces = countSpaces(line);
			final totalSpacesWidth:Int = numSpaces * font.spaceWidth;
			spaceWidth = Std.int((textWidth - lineWidth + totalSpacesWidth) / numSpaces);
		}

		final tabWidth:Int = spaceWidth * numSpacesInTab;

		for (i in 0...lineLength)
		{
			final charCode = line.charCodeAt(i);
			final isSpace = isSpaceChar(charCode);
			final hasFrame = font.charExists(charCode);
			if (hasFrame && !isSpace)
				data.push(charCode, curX, curY);

			if (hasFrame || isSpace)
			{
				if (i + 1 < lineLength)
				{
					final nextCode = line.charCodeAt(i + 1);
					curX += getCharPairAdvance(charCode, nextCode, spaceWidth) + letterSpacing;
				}
				else
				{
					curX += getCharAdvance(charCode, spaceWidth) + letterSpacing;
				}
			}
		}
	}

	function countSpaces(line:UnicodeString)
	{
		var i = line.length;

		var numSpaces = 0;
		while (i-- > 0)
		{
			final charCode = line.charCodeAt(i);

			if (charCode == FlxBitmapFont.SPACE_CODE)
				numSpaces++;
			else if (charCode == FlxBitmapFont.TAB_CODE)
				numSpaces += numSpacesInTab;
		}

		return numSpaces;
	}

	function updatePixels(useTiles:Bool = false):Void
	{
		pendingPixelsChange = false;

		var colorForFill:Int = background ? backgroundColor : FlxColor.TRANSPARENT;
		var bitmap:BitmapData = null;

		if (FlxG.render.blit)
		{
			if (pixels == null || (frameWidth != pixels.width || frameHeight != pixels.height))
			{
				pixels = new BitmapData(frameWidth, frameHeight, true, colorForFill);
			}
			else
			{
				pixels.fillRect(graphic.bitmap.rect, colorForFill);
			}

			bitmap = pixels;
		}
		else
		{
			if (!useTiles)
			{
				if (framePixels == null || (frameWidth != framePixels.width || frameHeight != framePixels.height))
				{
					framePixels = FlxDestroyUtil.dispose(framePixels);
					framePixels = new BitmapData(frameWidth, frameHeight, true, colorForFill);
				}
				else
				{
					framePixels.fillRect(framePixels.rect, colorForFill);
				}

				bitmap = framePixels;
			}
			else
			{
				textDrawData.clear();
				borderDrawData.clear();
			}

			if (autoBounds)
				autoAdjustBounds();
		}

		if (!useTiles)
		{
			bitmap.lock();
		}

		forEachBorder(drawText.bind(_, _, false, bitmap, useTiles));
		drawText(0, 0, true, bitmap, useTiles);

		if (!useTiles)
		{
			bitmap.unlock();
		}

		if (FlxG.render.blit)
		{
			dirty = true;
		}

		if (pendingPixelsChange)
			throw "pendingPixelsChange was changed to true while processing changed pixels";
	}

	function forEachBorder(func:(xOffset:Int, yOffset:Int)->Void)
	{
		switch (borderStyle)
		{
			case SHADOW:
				final iterations = borderQuality < 1 ? 1 : Std.int(Math.abs(borderSize) * borderQuality);
				final delta = borderSize / iterations;
				var i = iterations + 1;
				while (i-- > 1)
				{
					func(Std.int(delta * i), Std.int(delta * i));
				}

			case SHADOW_XY(shadowX, shadowY):
				// Size is max of both, so (4, 4) has 4 iterations, just like SHADOW
				final size = Math.max(shadowX, shadowY);
				final iterations = borderQuality < 1 ? 1 : Std.int(size * borderQuality);
				var i = iterations + 1;
				while (i-- > 1)
				{
					func(Std.int(shadowX / iterations * i), Std.int(shadowY / iterations * i));
				}

			case OUTLINE:
				// Render an outline around the text (8 draws)
				var iterations:Int = Std.int(borderSize * borderQuality);
				iterations = (iterations <= 0) ? 1 : iterations;
				final delta = Std.int(borderSize / iterations);
				for (iter in 0...iterations)
				{
					final i = delta * (iter + 1);
					func(-i, -i); // upper-left
					func( 0, -i); // upper-middle
					func( i, -i); // upper-right
					func(-i,  0); // middle-left
					func( i,  0); // middle-right
					func(-i,  i); // lower-left
					func( 0,  i); // lower-middle
					func( i,  i); // lower-right
				}
			case OUTLINE_FAST:
				// Render an outline around the text in each corner (4 draws)
				var iterations:Int = Std.int(borderSize * borderQuality);
				iterations = (iterations <= 0) ? 1 : iterations;
				final delta = Std.int(borderSize / iterations);
				for (iter in 0...iterations)
				{
					final i = delta * (iter + 1);
					func(-i, -i); // upper-left
					func( i, -i); // upper-right
					func(-i,  i); // lower-left
					func( i,  i); // lower-right
				}
			case NONE:
		}
	}

	function autoAdjustBounds()
	{
		// use local var to avoid get_width and recursion
		final newWidth = width = Math.abs(scale.x) * frameWidth;
		final newHeight = height = Math.abs(scale.y) * frameHeight;
		offset.set(-0.5 * (newWidth - frameWidth), -0.5 * (newHeight - frameHeight));
		centerOrigin();
	}

	function drawText(posX:Int, posY:Int, isFront:Bool = true, ?bitmap:BitmapData, useTiles:Bool = false):Void
	{
		if (FlxG.render.blit)
		{
			useTiles = false;
		}

		if (useTiles)
		{
			tileText(posX, posY, isFront);
		}
		else
		{
			blitText(posX, posY, isFront, bitmap);
		}
	}

	// TODO: Make this a local statics when min haxe-ver is 4.3
	static final matrixBlitHelper = new FlxMatrix();
	function blitText(posX:Int, posY:Int, isFront:Bool = true, ?bitmap:BitmapData):Void
	{
		var colorToApply = FlxColor.WHITE;

		if (isFront && useTextColor)
		{
			colorToApply = textColor;
		}
		else if (!isFront)
		{
			colorToApply = borderColor;
		}

		_colorParams.setMultipliers(colorToApply.redFloat, colorToApply.greenFloat, colorToApply.blueFloat, colorToApply.alphaFloat);

		if (isFront && !useTextColor)
		{
			_flashRect.setTo(0, 0, textBitmap.width, textBitmap.height);
			bitmap.copyPixels(textBitmap, _flashRect, _flashPointZero, null, null, true);
		}
		else
		{
			matrixBlitHelper.identity();
			matrixBlitHelper.translate(posX, posY);
			bitmap.draw(textBitmap, matrixBlitHelper, _colorParams);
		}
	}

	function tileText(posX:Int, posY:Int, isFront:Bool = true):Void
	{
		if (!FlxG.render.tile)
			return;

		final data:CharList = isFront ? textDrawData : borderDrawData;
		final rect = FlxRect.get();

		textData.forEach(function (charCode:Int, charX:Float, charY:Float)
		{
			final charFrame = font.getCharFrame(charCode);

			if (clipRect != null)
			{
				rect.copyFrom(clipRect);
				rect.offset(-charX - posX, -charY - posY);
				if (!charFrame.overlaps(rect))
					return;
			}

			data.push(charCode, charX + posX, charY + posY);
		});

		rect.put();
	}

	/**
	 * Set border's style (shadow, outline, etc), color, and size all in one go!
	 *
	 * @param   style    Outline style, such as `OUTLINE` or `SHADOW`
	 * @param   color    Outline color
	 * @param   size     Outline size in pixels.
	 *                   **If `background` is `true`, you may want to increase this text's `padding`**
	 * @param   quality  Outline quality, or the number of iterations to use when drawing.
	 *                   `0` means `1` iteration, otherwise it draws `size * quality` iterations
	 */
	public inline function setBorderStyle(style:FlxTextBorderStyle, color:FlxColor = 0, size = 1.0, quality = 1.0)
	{
		borderStyle = style;
		borderColor = color;
		borderSize = size;
		borderQuality = quality;
		pendingTextBitmapChange = true;
	}

	function get_fieldWidth():Int
	{
		return (autoSize) ? textWidth : _fieldWidth;
	}

	/**
	 * Sets the width of the text field. If the text does not fit, it will spread on multiple lines.
	 */
	function set_fieldWidth(value:Int):Int
	{
		value = (value > 1) ? value : 1;

		if (value != _fieldWidth)
		{
			if (value <= 0)
				autoSize = true;

			pendingTextChange = true;
		}

		return _fieldWidth = value;
	}

	function set_alignment(value:FlxTextAlign):FlxTextAlign
	{
		if (alignment != value && alignment != FlxTextAlign.JUSTIFY)
			pendingTextBitmapChange = true;

		return alignment = value;
	}

	function set_multiLine(value:Bool):Bool
	{
		if (multiLine != value)
			pendingTextChange = true;

		return multiLine = value;
	}

	function set_font(value:FlxBitmapFont):FlxBitmapFont
	{
		if (font != value)
			pendingTextChange = true;

		return font = value;
	}

	function set_lineSpacing(value:Int):Int
	{
		if (lineSpacing != value)
			pendingTextBitmapChange = true;

		return lineSpacing = value;
	}

	function set_letterSpacing(value:Int):Int
	{
		if (value != letterSpacing)
			pendingTextChange = true;

		return letterSpacing = value;
	}

	function set_autoUpperCase(value:Bool):Bool
	{
		if (autoUpperCase != value)
			pendingTextChange = true;

		return autoUpperCase = value;
	}

	function set_wrap(value:Wrap):Wrap
	{
		if (wrap != value)
			pendingTextChange = true;

		return wrap = value;
	}

	function set_autoSize(value:Bool):Bool
	{
		if (autoSize != value)
			pendingTextChange = true;

		return autoSize = value;
	}

	function set_autoBounds(value:Bool):Bool
	{
		if (autoBounds != value)
			pendingTextChange = true;

		return this.autoBounds = value;
	}

	function set_padding(value:Int):Int
	{
		if (value != padding)
			pendingTextChange = true;

		return padding = value;
	}

	function set_numSpacesInTab(value:Int):Int
	{
		if (numSpacesInTab != value && value > 0)
		{
			numSpacesInTab = value;
			pendingTextChange = true;
		}

		return value;
	}

	function set_background(value:Bool):Bool
	{
		if (background != value)
		{
			background = value;
			if (FlxG.render.blit)
			{
				pendingPixelsChange = true;
			}
		}

		return value;
	}

	function set_backgroundColor(value:Int):Int
	{
		if (backgroundColor != value)
		{
			backgroundColor = value;
			if (FlxG.render.blit)
			{
				pendingPixelsChange = true;
			}
		}

		return value;
	}

	function set_borderStyle(style:FlxTextBorderStyle):FlxTextBorderStyle
	{
		if (style != borderStyle)
		{
			borderStyle = style;
			pendingTextBitmapChange = true;
		}

		return borderStyle;
	}

	function set_borderColor(value:Int):Int
	{
		if (borderColor != value)
		{
			borderColor = value;
			if (FlxG.render.blit)
			{
				pendingPixelsChange = true;
			}
		}

		return value;
	}

	function set_borderSize(value:Float):Float
	{
		if (value != borderSize)
		{
			borderSize = value;

			if (borderStyle != FlxTextBorderStyle.NONE)
			{
				pendingTextBitmapChange = true;
			}
		}

		return value;
	}

	function set_borderQuality(value:Float):Float
	{
		value = Math.min(1, Math.max(0, value));

		if (value != borderQuality)
		{
			borderQuality = value;

			if (borderStyle != FlxTextBorderStyle.NONE)
			{
				pendingTextBitmapChange = true;
			}
		}

		return value;
	}

	function get_numLines():Int
	{
		return _lines.length;
	}

	function get_textWidth():Int
	{
		var max:Int = 0;
		var numLines:Int = _lines.length;
		var lineWidth:Int;
		_linesWidth = [];

		for (i in 0...numLines)
		{
			lineWidth = getLineWidth(i);
			_linesWidth[i] = lineWidth;
			max = (max > lineWidth) ? max : lineWidth;
		}

		return max;
	}

	function get_textHeight():Int
	{
		return (lineHeight + lineSpacing) * _lines.length - lineSpacing;
	}

	function get_lineHeight():Int
	{
		return font.lineHeight;
	}

	override function get_width():Float
	{
		checkPendingChanges(true);
		return super.get_width();
	}

	override function get_height():Float
	{
		checkPendingChanges(true);
		return super.get_height();
	}

	/**
	 * Checks if the specified code is one of the Unicode Combining Diacritical Marks
	 * @param	Code	The charactercode we want to check
	 * @return 	Bool	Returns true if the code is a Unicode Combining Diacritical Mark
	 */
	function isUnicodeComboMark(Code:Int):Bool
	{
		return ((Code >= 768 && Code <= 879) || (Code >= 6832 && Code <= 6911) || (Code >= 7616 && Code <= 7679) || (Code >= 8400 && Code <= 8447)
			|| (Code >= 65056 && Code <= 65071));
	}
}

enum Wrap
{
	/**
	 * No automatic wrapping, use \n chars to split manually.
	 */
	NONE;
	/**
	 * Automatically adds new line chars based on `fieldWidth`, splits by character.
	 */
	CHAR;
	/**
	 * Automatically adds new line chars based on `fieldWidth`, splits by word, if a single word is
	 * too long `mode` will determine how (or whether) it is split.
	 *
	 * Note: Words with hypens will be treated as separate words, the hyphen is also it's own word
	 */
	WORD(splitWords:WordSplitConditions);
}

enum WordSplitConditions
{
	/**
	 * Won't ever split words, long words will start on a new line and extend beyond `fieldWidth`.
	 */
	NEVER;
	/**
	 * Will only split words that can't fit in a single line, alone. The word starts on the previous line,
	 * if possible, and is added character by character until the line is filled.
	 */
	LINE_WIDTH;

	/**
	 * May split words longer than the specified number of characters. The word starts on the previous
	 * line, if possible, and is added character by character until the line is filled.
	 */
	LENGTH(minChars:Int);

	/**
	 * May split words wider than the specified number of pixels. The word starts on the previous
	 * line, if possible, and is added character by character until the line is filled.
	 */
	WIDTH(minPixels:Int);
}

@:forward(length)
abstract CharList(Array<Float>) from Array<Float>
{
	public inline function new ()
	{
		this = [];
	}

	// TODO: deprecate
	overload public inline extern function push(item:Float)
	{
		this.push(item);
	}

	overload public inline extern function push(charCode:Int, x:Float, y:Float)
	{
		this.push(charCode);
		this.push(x);
		this.push(y);
	}

	public function forEach(func:(charCode:Int, x:Float, y:Float)->Void)
	{
		for (i in 0...Std.int(this.length / 3))
		{
			final pos = i * 3;
			func(Std.int(this[pos]), this[pos + 1], this[pos + 2]);
		}
	}

	public inline function clear()
	{
		this.resize(0);
	}
}

/**
 * Helper to avoid creating a new frame every draw call
 */
private class ReusableFrame extends FlxFrame
{
	public function new ()
	{
		super(null);
		// We need to define this now, since it's created before render.tile is set
		tileMatrix = new MatrixVector();
	}

	override function destroy() {}
}

/*
 * TODO - enum WordSplitMethod: determines how words look when split, ex:
 * 	* whether split words start on a new line
 * 	* whether split words get a hypen added automatically
 *  * minimum character length of split word chunk
 *  * whether to cut words that extend beyond the width
 */
