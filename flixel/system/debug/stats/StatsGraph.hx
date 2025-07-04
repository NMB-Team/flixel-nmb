package flixel.system.debug.stats;

import openfl.display.Graphics;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormatAlign;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

/**
 * This is a helper function for the stats window to draw a graph with given values.
 */
#if FLX_DEBUG
class StatsGraph extends Sprite {
	static inline final AXIS_COLOR:FlxColor = 0xffffff;
	static inline final AXIS_ALPHA = .5;
	static inline final HISTORY_MAX = 15;

	public var minLabel:TextField;
	public var curLabel:TextField;
	public var maxLabel:TextField;
	public var avgLabel:TextField;

	public var minValue = FlxMath.MAX_VALUE_FLOAT;
	public var maxValue = FlxMath.MIN_VALUE_FLOAT;

	public var graphColor:FlxColor;

	public var history:Array<Float> = [];

	var _axis:Shape;
	var _width:Int;
	var _height:Int;
	var _unit:String;
	var _labelWidth:Int;
	var _label:String;

	public function new(x:Int, y:Int, width:Int, height:Int, graphColor:FlxColor, unit:String, labelWidth = 45, ?label:String) {
		super();
		this.x = x;
		this.y = y;
		_width = width - labelWidth;
		_height = height;
		this.graphColor = graphColor;
		_unit = unit;
		_labelWidth = labelWidth;
		_label = (label == null) ? "" : label;

		_axis = new Shape();
		_axis.x = _labelWidth + 10;

		maxLabel = DebuggerUtil.createTextField(0, 0, Stats.LABEL_COLOR, Stats.TEXT_SIZE);
		curLabel = DebuggerUtil.createTextField(0, (_height * .5) - (Stats.TEXT_SIZE * .5), graphColor, Stats.TEXT_SIZE);
		minLabel = DebuggerUtil.createTextField(0, _height - Stats.TEXT_SIZE, Stats.LABEL_COLOR, Stats.TEXT_SIZE);

		avgLabel = DebuggerUtil.createTextField(_labelWidth + 20, (_height * .5) - (Stats.TEXT_SIZE * .5) - 10, Stats.LABEL_COLOR, Stats.TEXT_SIZE);
		avgLabel.width = _width;
		avgLabel.defaultTextFormat.align = TextFormatAlign.CENTER;
		avgLabel.alpha = .5;

		addChild(_axis);
		addChild(maxLabel);
		addChild(curLabel);
		addChild(minLabel);
		addChild(avgLabel);

		drawAxes();
	}

	/**
	 * Redraws the axes of the graph.
	 */
	inline function drawAxes():Void {
		final gfx = _axis.graphics;
		gfx.clear();
		gfx.lineStyle(1, AXIS_COLOR, AXIS_ALPHA);

		// y-Axis
		gfx.moveTo(0, 0);
		gfx.lineTo(0, _height);

		// x-Axis
		gfx.moveTo(0, _height);
		gfx.lineTo(_width, _height);
	}

	/**
	 * Redraws the graph based on the values stored in the history.
	 */
	inline function drawGraph():Void {
		final gfx = graphics;
		gfx.clear();
		gfx.lineStyle(1, graphColor, 1);

		final inc = _width / (HISTORY_MAX - 1);
		final range = Math.max(maxValue - minValue, maxValue * .1);
		final graphX = _axis.x + 1;

		for (i in 0...history.length) {
			final value = (history[i] - minValue) / range;
			final pointY = (-value * _height - 1) + _height;

			if (i == 0)
				gfx.moveTo(graphX, _axis.y + pointY);

			gfx.lineTo(graphX + (i * inc), pointY);
		}
	}

	public function update(value:Float):Void {
		history.unshift(value);
		if (history.length > HISTORY_MAX) history.pop();

		// Update range
		maxValue = Math.max(maxValue, value);
		minValue = Math.min(minValue, value);

		minLabel.text = formatValue(minValue);
		curLabel.text = formatValue(value);
		maxLabel.text = formatValue(maxValue);

		avgLabel.text = _label + "\nAvg: " + formatValue(average());

		drawGraph();
	}

	inline function formatValue(value:Float):String {
		return FlxMath.roundDecimal(value, Stats.DECIMALS) + " " + _unit;
	}

	public inline function average():Float {
		final len = history.length;
		if (len == 0) return 0;

		var sum = .0;
		for (val in history) sum += val;

		return sum / len;
	}

	public function destroy():Void {
		_axis = FlxDestroyUtil.removeChild(this, _axis);
		minLabel = FlxDestroyUtil.removeChild(this, minLabel);
		curLabel = FlxDestroyUtil.removeChild(this, curLabel);
		maxLabel = FlxDestroyUtil.removeChild(this, maxLabel);
		avgLabel = FlxDestroyUtil.removeChild(this, avgLabel);
		history = flixel.util.FlxArrayUtil.clearArray(history);
	}
}
#end