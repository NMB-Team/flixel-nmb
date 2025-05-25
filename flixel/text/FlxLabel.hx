package flixel.text;

import flixel.FlxG;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormatAlign;
import openfl.Assets;
import flixel.FlxSprite;
import flixel.util.FlxAxes;
import flixel.system.FlxAssets;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import openfl.display.DisplayObjectContainer;

/**
 * FlxLabel is a text class that can be used to display fonts and labels 
 * Much like `FlxText` however text renders without software bitmaps
 * In many cases FlxLabel out performs FlxText in rendering speed and
 * memory efficiency
 */
class FlxLabel extends FlxSprite
{
	/**
	 * The `TextField` of this label provides the text engine for display
	 */
	public var field:Field;
	
	public var align:Convert;
	
	/**
	 * useful for rendering text behind or infront of all objects on a `FlxCamera`
	 */
	public var inFront:Bool = true;
	
	/**
	 * The current font expressed as String
	 */
	public var font(get, set):String;
	
	/**
	 * The text you want to display.
	 */
	public var text(get, set):String;
	
	/**
	 * enables cached label width which prevents jittery text updates.
	 * also can improve text engine speed.
	 * 
	 * can cause alignment problems if updated less frequent.
	 */
	public var stabilize:Bool = false;
	
	/**
	 * Tells wether or not if the label should load a pixelated font.
	 */
	public var isPixel(default, set):Bool;
	
	/**
	 * The text alignment of this label done in Float values 1.0-0.0
	 */
	public var alignment(default, set):Float = 0.0;
	
	var _size:Int;
	var _align:Float;
	var _width:Float;
	var _height:Float;
	var _pixel:Bool = false;
	var _FORMAT:TextFormat;
	var ADDED_TO_SCENE:Bool = false;
	var _color:UInt = flixel.util.FlxColor.BLACK; // 0xFFFFFF;
	var _wrapAlign:TextFormatAlign = JUSTIFY;
	
	/**
	 * Creates a new label you can specify font justify and more!
	 *
	 * @param x:Float the x coord of the label
	 * @param y:Float the y coord of the label
	 * @param Text:String the text to display
	 * @param fnt:String the font to load 
	 * @param size:Int the size of the txt
	 * @param justify:TextFieldAutoSize alignment
	 * @param add:Bool wether or not to add this label to the display
	 */
	override public function new(?x:Float, ?y:Float, ?Text:String = "N/A", ?fnt:String = '', ?Size:Int = 14, ?Justify:TextFieldAutoSize = LEFT, ?add:Bool)
	{
		field = new Field();
		setField(Text, Justify);
		setFormat(Size);
		active = false;
		
		super(x, y);
		
		if (fnt != '')
			font = fnt;
			
		if (add)
			FlxG.state.add(this);
			
		width = field.textWidth;
		height = field.textHeight;
	}
	
	public function setField(text:String, options:TextFieldAutoSize)
	{
		alignment = align > options; // i freaking love Abstracts.
		field.mouseEnabled = false;
		field.autoSize = options;
		field.selectable = false;
		field.embedFonts = true;
		field.multiline = false;
		field.wordWrap = false;
		field.sharpness = 50;
		field.text = text;
	}
	
	/**
	 * Draws the text on a graphic of your choice useful for manipulation
	 * @param graphic 
	 */
	public function drawGraphic(?graphic:FlxGraphic)
	{
		if (graphic == null)
		{
			graphic = FlxGraphic.fromBitmapData(new BitmapData(Std.int(field.width), Std.int(field.height), true, 0x000000), false, false);
		}
		graphic.bitmap.draw(field);
		return graphic;
	}
	
	override public function draw()
	{
		if (!ADDED_TO_SCENE)
		{
			ADDED_TO_SCENE = true;
			addToCamera();
			updateAlign();
		}
		if (field.alpha != alpha)
			field.alpha = alpha;
		@:privateAccess
		field.scrollRect = camera.canvas.scrollRect;
		_matrix.identity();
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);
		if (angle != 0)
		{
			updateTrig();
			origin.set(_width * 0.5, height * 0.5);
			_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}
		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);
		if (field.transform.matrix != _matrix)
			field.transform.matrix = _matrix;
		@:privateAccess
		if (field.__renderDirty)
		{
			field.cacheAsBitmapMatrix = _matrix;
		}
	}
	
	function addToCamera()
	{
		final display:DisplayObjectContainer = camera.canvas;
		camera.canvas.addChildAt(field, display.numChildren);
	}
	
	function get_font():String
		return _FORMAT.font;
		
	function set_font(str:String):String
	{
		var newFontName:String = str;
		
		if (str != null)
		{
			if (Assets.exists(str, FONT))
				newFontName = Assets.getFont(str).fontName;
			_FORMAT.font = newFontName;
		}
		else
			_FORMAT.font = _pixel ? FlxAssets.FONT_DEFAULT : FlxAssets.FONT_DEBUGGER;
			
		field.defaultTextFormat = _FORMAT = new TextFormat(newFontName, _size, _color, _wrapAlign);
		return _FORMAT.font;
	}
	
	function set_alignment(val:Float)
	{
		switch (val)
		{
			case 0.0:
				field.autoSize = LEFT;
			case 0.5:
				field.autoSize = CENTER;
			case 1.0:
				field.autoSize = RIGHT;
			case _:
				field.autoSize = CENTER;
		}
		return _align = val;
	}
	
	function set_isPixel(val:Bool)
	{
		_pixel = val;
		setFormat(_size);
		return val;
	}
	
	function get_text():String
		return field.text;
		
	function set_text(str:String):String
	{
		field.text = str;
		updateAlign();
		return text;
	}
	
	@:access(openfl.text.TextField)
	public inline function updateAlign()
	{
		switch (stabilize)
		{
			case true:
				final __width:Float = field.__cacheWidth;
				final dtw:Float = Math.abs(__width - _width);
				if (dtw > _size * 0.5 || _width < __width)
				{
					_width = __width;
				}
				offset.x = (_width) * _align;
			case false:
				if (field.__renderDirty)
				{
					width = field.textWidth; // regens text :sob:
					offset.x = (width) * _align;
					_width = width;
				}
		}
	}
	
	function setFormat(size:Int)
	{
		_FORMAT = new TextFormat(_pixel ? FlxAssets.FONT_DEFAULT : FlxAssets.FONT_DEBUGGER, size, _color, JUSTIFY);
		field.defaultTextFormat = _FORMAT;
		width = field.width;
		height = field.height;
		_width = width;
		_height = height;
		_size = size;
	}
	
	override public function gameCenter(axes:FlxAxes = XY)
	{
		if (axes.x)
			x = FlxG.width * 0.5;
		if (axes.y)
			y = (FlxG.height - height) * 0.5;
			
		return this;
	}
	
	override function destroy():Void
	{
		camera.canvas.removeChild(field);
		active = visible = false;
		_FORMAT = null;
		field = null;
		super.destroy();
	}
}

class Field extends TextField
{
	public var __cacheWidth:Float;
	
	@:access(openfl.text._internal.TextEngine)
	override function __updateLayout()
	{
		if (__layoutDirty)
		{
			__cacheWidth = __textEngine.width;
			__textEngine.update();
			
			if (__textEngine.autoSize != NONE)
			{
				if (__textEngine.width != __cacheWidth)
				{
					switch (__textEngine.autoSize)
					{
						case RIGHT:
							x += __cacheWidth - __textEngine.width;
							
						case CENTER:
							x += (__cacheWidth - __textEngine.width) * .5;
							
						default:
					}
				}
				
				__textEngine.getBounds();
			}
			
			__layoutDirty = false;
			
			setSelection(__selectionIndex, __caretIndex);
		}
	}
}

enum abstract Alignment(Float) to Float
{
	var LEFT = 0.0;
	var CENTER = 0.5;
	var RIGHT = 1.0;
}

abstract Convert(Float) from Int to Float
{
	@:op(a > b)
	function fromInt(a:TextFieldAutoSize)
	{
		var val:Float;
		switch (a)
		{
			case CENTER:
				val = 0.5;
			case LEFT:
				val = 0.0;
			case RIGHT:
				val = 1.0;
			case NONE:
				val = 0.5;
		}
		return val;
	}
}