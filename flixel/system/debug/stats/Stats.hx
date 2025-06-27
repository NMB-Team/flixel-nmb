package flixel.system.debug.stats;

import openfl.display.BitmapData;
import openfl.system.System;
import openfl.text.TextField;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.system.FlxLinkedList;
import flixel.system.FlxQuadTree;
import flixel.system.debug.DebuggerUtil;
import flixel.system.ui.FlxSystemButton;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;


/**
 * A simple performance monitor widget, for use in the debugger overlay.
 *
 * @author Adam "Atomic" Saltsman
 * @author Anton Karlov
 */
#if FLX_DEBUG
class Stats extends Window {
	/**
	 * How often to update the stats, in ms. The lower, the more performance-intense!
	 */
	static inline final UPDATE_DELAY = 250;

	/**
	 * The initial width of the stats window.
	 */
	static inline final INITIAL_WIDTH = 160;

	static inline final FPS_COLOR:FlxColor = 0xff96ff00;
	static inline final MEMORY_COLOR:FlxColor = 0xff009cff;
	static inline final DRAW_TIME_COLOR:FlxColor = 0xffA60004;
	static inline final UPDATE_TIME_COLOR:FlxColor = 0xffdcd400;

	public static inline final LABEL_COLOR:FlxColor = 0xaaffffff;
	public static inline final TEXT_SIZE = 11;
	public static inline final DECIMALS = 1;

	var _leftTextField:TextField;
	var _rightTextField:TextField;

	var _itvTime = .0;
	var _frameCount:Int;
	var _currentTime:Float;

	var fpsGraph:StatsGraph;
	var memoryGraph:StatsGraph;
	var drawTimeGraph:StatsGraph;
	var updateTimeGraph:StatsGraph;

	var flashPlayerFramerate = .0;
	var visibleCount = 0;
	var activeCount = 0;
	var updateTime = .0;
	var drawTime = .0;
	var drawCallsCount = 0;

	var _lastTime = .0;
	var _updateTimer = .0;

	var _update:Array<Float> = [];
	var _updateMarker = 0;

	var _draw:Array<Float> = [];
	var _drawMarker = 0;

	var _drawCalls:Array<Int> = [];
	var _drawCallsMarker = 0;

	var _visibleObject:Array<Int> = [];
	var _visibleObjectMarker = 0;

	var _activeObject:Array<Int> = [];
	var _activeObjectMarker:Int = 0;

	var _paused = true;

	var _toggleSizeButton:FlxSystemButton;

	/**
	 * Creates a new window with fps and memory graphs, as well as other useful stats for debugging.
	 */
	public function new() {
		super("Stats", Icon.stats, 0, 0, false);

		final minHeight = FlxG.render.tile ? 200 : 185;
		minSize.y = minHeight;
		resize(INITIAL_WIDTH, minHeight);

		start();

		final gutter = 5;
		final graphHeight = 40;
		var graphX = gutter;
		var graphY = Std.int(_header.height) + gutter;
		var graphWidth = INITIAL_WIDTH - 20;

		fpsGraph = new StatsGraph(graphX, graphY, graphWidth, graphHeight, FPS_COLOR, "fps");
		addChild(fpsGraph);
		fpsGraph.maxValue = FlxG.drawFramerate;
		fpsGraph.minValue = 0;

		graphY = (Std.int(_header.height) + graphHeight + 20);

		memoryGraph = new StatsGraph(graphX, graphY, graphWidth, graphHeight, MEMORY_COLOR, "MB");
		addChild(memoryGraph);

		graphY = Std.int(_header.height) + gutter;
		graphX += (gutter + graphWidth + 20);
		graphWidth -= 10;

		updateTimeGraph = new StatsGraph(graphX, graphY, graphWidth, graphHeight, UPDATE_TIME_COLOR, "ms", 35, "Update");
		updateTimeGraph.visible = false;
		addChild(updateTimeGraph);

		graphY = Std.int(_header.height) + graphHeight + 20;

		drawTimeGraph = new StatsGraph(graphX, graphY, graphWidth, graphHeight, DRAW_TIME_COLOR, "ms", 35, "Draw");
		drawTimeGraph.visible = false;
		addChild(drawTimeGraph);

		addChild(_leftTextField = DebuggerUtil.createTextField(gutter, (graphHeight * 2) + 45, LABEL_COLOR, TEXT_SIZE));
		addChild(_rightTextField = DebuggerUtil.createTextField(gutter + 75, (graphHeight * 2) + 45, FlxColor.WHITE, TEXT_SIZE));

		_leftTextField.multiline = _rightTextField.multiline = true;

		var drawMethod = "";
		if (FlxG.render.tile) {
			drawMethod =
				#if FLX_RENDER_TRIANGLE
				"DrawTrian.";
				#else
				"DrawQuads";
				#end
			drawMethod = '\n$drawMethod:';
		}

		_leftTextField.text = "Update: \nDraw:" + drawMethod + "\nQuadTrees: \nLists:";

		_toggleSizeButton = new FlxSystemButton(Icon.maximize, toggleSize);
		_toggleSizeButton.alpha = Window.HEADER_ALPHA;
		addChild(_toggleSizeButton);

		updateSize();
	}

	/**
	 * Starts Stats window update logic
	 */
	public function start():Void {
		if (!_paused) return;
		_paused = false;
		_itvTime = FlxG.game.ticks;
		_frameCount = 0;
	}

	/**
	 * Stops Stats window
	 */
	public function stop():Void {
		_paused = true;
	}

	/**
	 * Clean up memory.
	 */
	override public function destroy():Void {
		fpsGraph?.destroy();
		fpsGraph = FlxDestroyUtil.removeChild(this, fpsGraph);

		memoryGraph = FlxDestroyUtil.removeChild(this, memoryGraph);
		_leftTextField = FlxDestroyUtil.removeChild(this, _leftTextField);
		_rightTextField = FlxDestroyUtil.removeChild(this, _rightTextField);

		_update = null;
		_draw = null;
		_activeObject = null;
		_visibleObject = null;
		_drawCalls = null;

		super.destroy();
	}

	/**
	 * Called each frame, but really only updates once every second or so, to save on performance.
	 * Takes all the data in the accumulators and parses it into useful performance data.
	 */
	override public function update():Void {
		if (_paused) return;

		final time = _currentTime = FlxG.game.ticks;

		var elapsed = time - _lastTime;
		if (Math.abs(elapsed) > UPDATE_DELAY) elapsed = UPDATE_DELAY;

		_lastTime = time;

		_updateTimer += elapsed;

		_frameCount++;

		if (_updateTimer > UPDATE_DELAY) {
			fpsGraph.update(currentFps());
			memoryGraph.update(currentMem());
			updateTexts();

			_frameCount = 0;
			_itvTime = _currentTime;

			updateTime = 0;
			for (i in 0..._updateMarker) updateTime += _update[i];

			for (i in 0..._activeObjectMarker) activeCount += _activeObject[i];
			activeCount = Std.int(divide(activeCount, _activeObjectMarker));

			drawTime = 0;
			for (i in 0..._drawMarker) drawTime += _draw[i];

			for (i in 0..._visibleObjectMarker) visibleCount += _visibleObject[i];
			visibleCount = Std.int(divide(visibleCount, _visibleObjectMarker));

			if (FlxG.render.tile) {
				for (i in 0..._drawCallsMarker) drawCallsCount += _drawCalls[i];
				drawCallsCount = Std.int(divide(drawCallsCount, _drawCallsMarker));
			}

			_updateMarker = _drawMarker = _activeObjectMarker = _visibleObjectMarker = 0;
			if (FlxG.render.tile) _drawCallsMarker = 0;

			_updateTimer = 0;
		}
	}

	private function updateTexts():Void {
		final updTime = FlxMath.roundDecimal(divide(updateTime, _updateMarker), DECIMALS);
		final drwTime = FlxMath.roundDecimal(divide(drawTime, _drawMarker), DECIMALS);

		drawTimeGraph.update(drwTime);
		updateTimeGraph.update(updTime);

		_rightTextField.text = activeCount + " (" + updTime + "ms)\n" + visibleCount + " (" + drwTime + "ms)\n"
			+ (FlxG.render.tile ? (drawCallsCount + "\n") : "") + FlxQuadTree._NUM_CACHED_QUAD_TREES + "\n" + FlxLinkedList._NUM_CACHED_FLX_LIST;
	}

	private function divide(f1:Float, f2:Float):Float {
		return (f2 == 0) ? 0 : f1 / f2;
	}

	/**
	 * Calculates current game fps.
	 */
	public inline function currentFps():Float {
		return _frameCount / intervalTime();
	}

	/**
	 * Time since performance monitoring started.
	 */
	public inline function intervalTime():Float {
		return (_currentTime - _itvTime) * .001;
	}

	/**
	 * Current RAM consumption.
	 */
	public inline function currentMem():Float {
		return (System.totalMemoryNumber / 1024) * .001;
	}

	/**
	 * How long updates took.
	 *
	 * @param 	elapsed		How long this update took.
	 */
	public function flixelUpdate(elapsed:Float):Void {
		if (_paused) return;
		_update[_updateMarker++] = elapsed;
	}

	/**
	 * How long rendering took.
	 *
	 * @param	elapsed		How long this render took.
	 */
	public function flixelDraw(elapsed:Float):Void {
		if (_paused) return;
		_draw[_drawMarker++] = elapsed;
	}

	/**
	 * How many objects were updated.
	 *
	 * @param 	count	How many objects were updated.
	 */
	public function activeObjects(count:Int):Void {
		if (_paused) return;
		_activeObject[_activeObjectMarker++] = count;
	}

	/**
	 * How many objects were rendered.
	 *
	 * @param 	count	How many objects were rendered.
	 */
	public function visibleObjects(count:Int):Void {
		if (_paused) return;
		_visibleObject[_visibleObjectMarker++] = count;
	}

	/**
	 * How many times drawTiles() method was called.
	 *
	 * @param 	drawcalls	How many times drawTiles() method was called.
	 */
	public function drawCalls(drawcalls:Int):Void {
		if (_paused) return;
		_drawCalls[_drawCallsMarker++] = drawcalls;
	}

	/**
	 * Re-enables tracking of the stats.
	 */
	public function onFocus():Void {
		_paused = false;
	}

	/**
	 * Pauses tracking of the stats.
	 */
	public function onFocusLost():Void {
		_paused = true;
	}

	private function toggleSize():Void {
		if (_width == INITIAL_WIDTH) {
			resize(INITIAL_WIDTH * 2, _height);
			x -= INITIAL_WIDTH;
			drawTimeGraph.visible = updateTimeGraph.visible = true;
			_toggleSizeButton.changeIcon(Icon.minimize);
		} else {
			resize(INITIAL_WIDTH, _height);
			x += INITIAL_WIDTH;
			drawTimeGraph.visible = updateTimeGraph.visible = false;
			_toggleSizeButton.changeIcon(Icon.maximize);
		}

		updateSize();
		bound();
	}

	override function updateSize():Void {
		super.updateSize();
		if (_toggleSizeButton == null) return;

		_toggleSizeButton.x = _width - _toggleSizeButton.width - 3;
		_toggleSizeButton.y = 3;
	}
}
#end
