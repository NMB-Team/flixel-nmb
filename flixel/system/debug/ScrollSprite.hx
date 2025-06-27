package flixel.system.debug;

import flixel.FlxG;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class ScrollSprite extends Sprite {
	public var maxScrollY(get, never):Float;
	inline function get_maxScrollY():Float return this.height - scroll.height;

	public var viewHeight(get, never):Float;
	inline function get_viewHeight():Float return scroll.height;

	/**
	 * The current amount of scrolling
	 */
	public var scrollY(get, set):Float;
	inline function get_scrollY():Float return scroll.y;
	inline function set_scrollY(value):Float {
		scroll.y = value;
		updateScroll();
		return scroll.y;
	}

	final scroll = new Rectangle();
	var scrollBar:ScrollBar = null;

	public function new () {
		super();

		addEventListener(Event.ADDED_TO_STAGE, Void -> {
			final stage = this.stage;
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseScroll);
			addEventListener(Event.REMOVED_FROM_STAGE, Void -> stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseScroll));
		});
	}

	public function createScrollBar() {
		return scrollBar = new ScrollBar(this);
	}

	private function onMouseScroll(e:MouseEvent) {
		if (mouseX > 0 && mouseX < scroll.width && mouseY - scroll.y > 0 && mouseY - scroll.y < scroll.height) {
			scroll.y -= e.delta;
			updateScroll();
		}
	}

	public function setScrollSize(width:Float, height:Float) {
		scroll.width = width;
		scroll.height = height;

		updateScroll();
	}

	private function updateScroll() {
		scrollRect = null;

		if (scroll.bottom > this.height) scroll.y = height - scroll.height;
		if (scroll.y < 0) scroll.y = 0;

		scrollRect = scroll;

		scrollBar?.onViewChange();
	}

	override function addChild(child) {
		super.addChild(child);
		updateScroll();
		return child;
	}

	public function isChildVisible(child:DisplayObject) {
		if (getChildIndex(child) == -1)
			FlxG.log.critical("Invalid child, not a child of this container");

		return child.y < scroll.bottom && child.y + child.height > scroll.y;
	}
}

@:allow(flixel.system.debug.ScrollSprite)
class ScrollBar extends Sprite {
	static inline final WIDTH = 10;

	final target:ScrollSprite;

	final handle = new Sprite();
	final bg = new Sprite();

	var state:ScrollState = IDLE;

	public function new (target:ScrollSprite) {
		this.target = target;
		super();

		bg.mouseChildren = bg.mouseEnabled = true;
		bg.graphics.beginFill(0xFFFFFF, .1);
		bg.graphics.drawRect(0, 0, WIDTH, 1);
		bg.graphics.endFill();
		addChild(bg);

		handle.mouseChildren = handle.mouseEnabled = handle.buttonMode = true;
		handle.graphics.beginFill(0xFFFFFF, .3);
		handle.graphics.drawRect(0, 0, WIDTH, 1);
		handle.graphics.endFill();
		addChild(handle);

		function onAdded(_) {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			final stage = this.stage;

			bg.addEventListener(MouseEvent.MOUSE_DOWN, onBgMouseDown);
			handle.addEventListener(MouseEvent.MOUSE_DOWN, onHandleMouse);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onHandleMouse);

			function onRemoved(_) {
				removeEventListener(Event.REMOVED_FROM_STAGE, onRemoved);

				bg.removeEventListener(MouseEvent.MOUSE_DOWN, onBgMouseDown);
				handle.removeEventListener(MouseEvent.MOUSE_DOWN, onHandleMouse);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				stage.removeEventListener(MouseEvent.MOUSE_UP, onHandleMouse);
			}

			addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
		}

		addEventListener(Event.ADDED_TO_STAGE, onAdded);
	}

	private function onBgMouseDown(e:MouseEvent) {
		if (state != IDLE)
			FlxG.log.critical("expected state: IDLE");

		state = DRAG_BG;
		mouseMoveHelper(e.stageY);
	}

	private function onHandleMouse(e:MouseEvent) {
		if (e.type == MouseEvent.MOUSE_DOWN) {
			if (state != IDLE)
				FlxG.log.critical("expected state: IDLE");

			state = DRAG_HANDLE(getLocalY(e.stageY) - handle.y);
		} else
			state = IDLE;
	}

	private function onMouseMove(e:MouseEvent) {
		mouseMoveHelper(e.stageY);
	}

	private function getLocalY(stageY:Float) {
		return globalToLocal(new Point(0, stageY)).y;
	}

	private function mouseMoveHelper(stageY:Float) {
		final localY = getLocalY(stageY);
		switch state {
			case IDLE:
			case DRAG_HANDLE(offsetY):
				handle.y = localY - offsetY;
				onHandleMove();
			case DRAG_BG:
				handle.y = localY - handle.height * .5;
				onHandleMove();
		}
	}

	private function onHandleMove() {
		if (handle.y < 0) handle.y = 0;

		final calc_height = bg.height - handle.height;
		if (handle.y > calc_height) handle.y = calc_height;

		target.scrollY = handle.y / (bg.height - handle.height) * target.maxScrollY;
	}

	public function resize(height:Float) {
		bg.height = height;
		handle.height = height / target.height * target.viewHeight;
		onViewChange();
	}

	private function onViewChange() {
		mouseEnabled = mouseChildren = visible = target.maxScrollY > 0 && target.maxScrollY < target.height;
		handle.y = (target.scrollY / target.maxScrollY) * (bg.height - handle.height);
	}
}

private enum ScrollState {
	IDLE;
	DRAG_HANDLE(offsetY:Float);
	DRAG_BG;
}