package flixel.ui;

import openfl.events.MouseEvent;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.atlas.FlxNode;
import flixel.graphics.frames.FlxTileFrames;
import flixel.input.FlxInput;
import flixel.input.FlxPointer;
import flixel.input.IFlxInput;
import flixel.input.mouse.FlxMouseButton;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxDestroyUtil;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end

enum abstract FlxButtonState(Int) to Int {
	/** The button is not highlighted or pressed */
	final NORMAL = 0;

	/** The button is selected, usually meaning the mouse is hovering over it */
	final HIGHLIGHT = 1;

	/** The button is being pressed usually by a mouse */
	final PRESSED = 2;

	/** The button is not interactible */
	final DISABLED = 3;

	public function toInt() {
		return this;
	}

	public function toString() {
		return switch (cast this:FlxButtonState) {
			case NORMAL: "normal";
			case HIGHLIGHT: "highlight";
			case PRESSED: "pressed";
			case DISABLED: "disabled";
		}
	}
}

/**
 * A simple button class that calls a function when clicked by the mouse.
 */
class FlxButton extends FlxTypedButton<FlxText> {
	/**
	 * Shortcut to setting label.text
	 */
	public var text(get, set):String;

	/**
	 * Creates a new `FlxButton` object with a gray background
	 * and a callback function on the UI thread.
	 *
	 * @param   x         The x position of the button.
	 * @param   y         The y position of the button.
	 * @param   text      The text that you want to appear on the button.
	 * @param   onClick   The function to call whenever the button is clicked.
	 */
	public function new(x = .0, y = .0, ?text:String, ?onClick:Void -> Void) {
		super(x, y, onClick);

		for (point in labelOffsets) point.set(point.x, point.y + 3);

		initLabel(text);
	}

	/**
	 * Updates the size of the text field to match the button.
	 */
	override function resetHelpers():Void {
		super.resetHelpers();

		if (label != null) {
			label.fieldWidth = label.frameWidth = Std.int(width);
			label.size = label.size; // Calls set_size(), don't remove!
		}
	}

	inline function initLabel(text:String):Void {
		if (text == null) return;

		label = new FlxText(x + labelOffsets[FlxButtonState.NORMAL.toInt()].x, y + labelOffsets[FlxButtonState.NORMAL.toInt()].y, 80, text);
		label.setFormat(null, 8, 0x333333, "center");
		label.alpha = labelAlphas[status.toInt()];
		label.drawFrame(true);
	}

	inline function get_text():String {
		return (label != null) ? label.text : null;
	}

	inline function set_text(text:String):String {
		if (label == null)
			initLabel(text);
		else
			label.text = text;

		return text;
	}
}

/**
 * A simple button class that calls a function when clicked by the mouse.
 */
#if (!display && FLX_GENERIC)
@:generic
#end
class FlxTypedButton<T:FlxSprite> extends FlxSprite implements IFlxInput {
	/**
	 * The label that appears on the button. Can be any `FlxSprite`.
	 */
	public var label(default, set):T;

	/**
	 * What offsets the `label` should have for each status.
	 */
	public var labelOffsets = [FlxPoint.get(), FlxPoint.get(), FlxPoint.get(0, 1), FlxPoint.get()];

	/**
	 * What alpha value the label should have for each status. Default is `[0.8, 1.0, 0.5]`.
	 * Multiplied with the button's `alpha`.
	 */
	public var labelAlphas = [.8, 1., .5, .3];

	/**
	 * Whether you can press the button simply by releasing the touch / mouse button over it (default).
	 * If false, the input has to be pressed while hovering over the button.
	 */
	public var allowSwiping = true;

	#if FLX_MOUSE
	/**
	 * Which mouse buttons can trigger the button - by default only the left mouse button.
	 */
	public final mouseButtons:Array<FlxMouseButtonID> = [FlxMouseButtonID.LEFT];
	#end

	/**
	 * Maximum distance a pointer can move to still trigger event handlers.
	 * If it moves beyond this limit, onOut is triggered.
	 * Defaults to `Math.POSITIVE_INFINITY` (i.e. no limit).
	 */
	public final maxInputMovement = Math.POSITIVE_INFINITY;

	/**
	 * Shows the current state of the button, either `NORMAL`,
	 * `HIGHLIGHT` or `PRESSED`.
	 */
	public var status(default, set):FlxButtonState;

	/**
	 * The properties of this button's `onUp` event (callback function, sound).
	 */
	public var onUp(default, null):FlxButtonEvent;

	/**
	 * The properties of this button's `onDown` event (callback function, sound).
	 */
	public var onDown(default, null):FlxButtonEvent;

	/**
	 * The properties of this button's `onOver` event (callback function, sound).
	 */
	public var onOver(default, null):FlxButtonEvent;

	/**
	 * The properties of this button's `onOut` event (callback function, sound).
	 */
	public var onOut(default, null):FlxButtonEvent;

	public var justReleased(get, never):Bool;
	public var released(get, never):Bool;
	public var pressed(get, never):Bool;
	public var justPressed(get, never):Bool;

	/**
	 * We cast label to a `FlxSprite` for internal operations to avoid Dynamic casts in C++
	 */
	var _spriteLabel:FlxSprite;

	/**
	 * We don't need an ID here, so let's just use `Int` as the type.
	 */
	var input:FlxInput<Int>;

	/**
	 * The input currently pressing this button, if none, it's `null`. Needed to check for its release.
	 */
	var currentInput:IFlxInput;

	var lastStatus:FlxButtonState = cast -1;

	/**
	 * Creates a new `FlxTypedButton` object with a gray background.
	 *
	 * @param   x         The x position of the button.
	 * @param   y         The y position of the button.
	 * @param   onClick   The function to call whenever the button is clicked.
	 */
	public function new(x = .0, y = .0, ?onClick:Void -> Void) {
		super(x, y);

		loadDefaultGraphic();

		onUp = new FlxButtonEvent(onClick);
		onDown = new FlxButtonEvent();
		onOver = new FlxButtonEvent();
		onOut = new FlxButtonEvent();

		status = NORMAL;

		// Since this is a UI element, the default scrollFactor is (0, 0)
		scrollFactor.set();

		#if FLX_MOUSE
		FlxG.stage.addEventListener(MouseEvent.MOUSE_UP, onUpEventListener);
		#end

		#if FLX_NO_MOUSE // no need for highlight frame without mouse input
		labelAlphas[HIGHLIGHT.toInt()] = 1;
		#end

		input = new FlxInput(0);
	}

	override public function graphicLoaded():Void {
		super.graphicLoaded();

		setupAnimation("normal", NORMAL.toInt());
		setupAnimation("highlight", (#if FLX_MOUSE HIGHLIGHT #else NORMAL #end).toInt());
		setupAnimation("pressed", PRESSED.toInt());
		setupAnimation("disabled", DISABLED.toInt());
	}

	private function loadDefaultGraphic():Void {
		loadGraphic("flixel/images/ui/button.png", true, 80, 20);
	}

	private function setupAnimation(animationName:String, frameIndex:Int):Void {
		// make sure the animation doesn't contain an invalid frame
		frameIndex = Std.int(Math.min(frameIndex, animation.numFrames - 1));
		animation.add(animationName, [frameIndex]);
	}

	/**
	 * Called by the game state when state is changed (if this object belongs to the state)
	 */
	override public function destroy():Void {
		label = FlxDestroyUtil.destroy(label);
		_spriteLabel = null;

		onUp = FlxDestroyUtil.destroy(onUp);
		onDown = FlxDestroyUtil.destroy(onDown);
		onOver = FlxDestroyUtil.destroy(onOver);
		onOut = FlxDestroyUtil.destroy(onOut);

		labelOffsets = FlxDestroyUtil.putArray(labelOffsets);

		labelAlphas = null;
		currentInput = null;
		input = null;

		#if FLX_MOUSE
		FlxG.stage.removeEventListener(MouseEvent.MOUSE_UP, onUpEventListener);
		#end

		super.destroy();
	}

	/**
	 * Called by the game loop automatically, handles mouseover and click detection.
	 */
	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (visible) {
			// Update the button, but only if at least either mouse or touches are enabled
			#if FLX_POINTER_INPUT
			updateButton();
			#end

			// Trigger the animation only if the button's input status changes.
			if (lastStatus != status) {
				updateStatusAnimation();
				lastStatus = status;
			}
		}

		input.update();
	}

	inline function updateStatusAnimation():Void {
		animation.play(status.toString());
	}

	/**
	 * Just draws the button graphic and text label to the screen.
	 */
	override public function draw():Void {
		super.draw();

		if (_spriteLabel != null && _spriteLabel.visible) {
			_spriteLabel.cameras = _cameras;
			_spriteLabel.draw();
		}
	}

	#if FLX_DEBUG
	/**
	 * Helper function to draw the debug graphic for the label as well.
	 */
	override public function drawDebug():Void {
		super.drawDebug();

		_spriteLabel?.drawDebug();
	}
	#end

	/**
	 * Stamps button's graphic and label onto specified atlas object and loads graphic from this atlas.
	 * This method assumes that you're using whole image for button's graphic and image has no spaces between frames.
	 * And it assumes that label is a single frame sprite.
	 *
	 * @param   atlas   Atlas to stamp graphic to.
	 * @return  Whether the button's graphic and label's graphic were stamped on the atlas successfully.
	 */
	public function stampOnAtlas(atlas:FlxAtlas):Bool {
		final buttonNode = atlas.addNode(graphic.bitmap, graphic.key);
		var result = (buttonNode != null);

		if (buttonNode != null) {
			final buttonFrames:FlxTileFrames = cast frames;
			final tileSize:FlxPoint = FlxPoint.get(buttonFrames.tileSize.x, buttonFrames.tileSize.y);
			final tileFrames:FlxTileFrames = buttonNode.getTileFrames(tileSize);
			this.frames = tileFrames;
		}

		if (result && label != null) {
			final labelNode = atlas.addNode(label.graphic.bitmap, label.graphic.key);
			result = result && (labelNode != null);

			if (labelNode != null) label.frames = labelNode.getImageFrame();
		}

		return result;
	}

	/**
	 * Basic button update logic - searches for overlaps with touches and
	 * the mouse cursor and calls `updateStatus()`.
	 */
	private function updateButton():Void {
		// Prevent interactions with this input if it's currently disabled
		if (status == DISABLED) return;
		// We're looking for any touch / mouse overlaps with this button
		var overlapFound = checkMouseOverlap();
		if (!overlapFound) overlapFound = checkTouchOverlap();

		if (currentInput != null && currentInput.justReleased && overlapFound) onUpHandler();
		if (status != NORMAL && (!overlapFound || (currentInput != null && currentInput.justReleased))) onOutHandler();
	}

	private function checkMouseOverlap():Bool {
		var overlap = false;
		#if FLX_MOUSE
		for (camera in getCameras())
			for (buttonID in mouseButtons) {
				final button = FlxMouseButton.getByID(buttonID);
				if (button != null && checkInput(FlxG.mouse, button, button.justPressedPosition, camera)) overlap = true;
			}
		#end

		return overlap;
	}

	private function checkTouchOverlap():Bool {
		var overlap = false;
		#if FLX_TOUCH
		for (camera in getCameras())
			for (touch in FlxG.touches.list)
				if (checkInput(touch, touch, touch.justPressedPosition, camera))
					overlap = true;
		#end

		return overlap;
	}

	private function checkInput(pointer:FlxPointer, input:IFlxInput, justPressedPosition:FlxPoint, camera:FlxCamera):Bool {
		if (maxInputMovement != Math.POSITIVE_INFINITY && justPressedPosition.distanceTo(pointer.getViewPosition(camera, FlxPoint.weak())) > maxInputMovement && input == currentInput)
			currentInput = null;
		else if (overlapsPoint(pointer.getWorldPosition(camera, _point), true, camera)) {
			updateStatus(input);
			return true;
		}

		return false;
	}

	/**
	 * Updates the button status by calling the respective event handler function.
	 */
	private function updateStatus(input:IFlxInput):Void {
		if (input.justPressed) {
			currentInput = input;
			onDownHandler();
		} else if (status == NORMAL) {
			// Allow "swiping" to press a button (dragging it over the button while pressed)
			if (allowSwiping && input.pressed) onDownHandler();
			else onOverHandler();
		}
	}

	private function updateLabelPosition() {
		if (_spriteLabel != null) { // Label positioning
			_spriteLabel.x = (pixelPerfectPosition ? Math.floor(x) : x) + labelOffsets[status.toInt()].x;
			_spriteLabel.y = (pixelPerfectPosition ? Math.floor(y) : y) + labelOffsets[status.toInt()].y;
		}
	}

	private function updateLabelAlpha() {
		if (_spriteLabel != null && labelAlphas.length > status.toInt())
			_spriteLabel.alpha = alpha * labelAlphas[status.toInt()];
	}

	/**
	 * Using an event listener is necessary for security reasons -
	 * certain things like opening a new window are only allowed when they are user-initiated.
	 */
	#if FLX_MOUSE
	private function onUpEventListener(_):Void {
		if (visible && exists && active && status == PRESSED) onUpHandler();
	}
	#end

	/**
	 * Internal function that handles the onUp event.
	 */
	private function onUpHandler():Void {
		status = HIGHLIGHT;
		input.release();
		currentInput = null;
		// Order matters here, because onUp.fire() could cause a state change and destroy this object.
		onUp.fire();
	}

	/**
	 * Internal function that handles the onDown event.
	 */
	private function onDownHandler():Void {
		status = PRESSED;
		input.press();
		// Order matters here, because onDown.fire() could cause a state change and destroy this object.
		onDown.fire();
	}

	/**
	 * Internal function that handles the onOver event.
	 */
	private function onOverHandler():Void {
		#if FLX_MOUSE
		// If mouse input is not enabled, this button must ignore over actions
		// by remaining in the normal state (until mouse input is re-enabled).
		if (!FlxG.mouse.enabled) {
			status = NORMAL;
			return;
		}
		#end
		status = HIGHLIGHT;
		// Order matters here, because onOver.fire() could cause a state change and destroy this object.
		onOver.fire();
	}

	/**
	 * Internal function that handles the onOut event.
	 */
	private function onOutHandler():Void {
		status = NORMAL;
		input.release();
		// Order matters here, because onOut.fire() could cause a state change and destroy this object.
		onOut.fire();
	}

	private function set_label(value:T):T {
		if (value != null) {
			// use the same FlxPoint object for both
			value.scrollFactor.put();
			value.scrollFactor = scrollFactor;
		}

		label = value;
		_spriteLabel = label;

		updateLabelPosition();

		return value;
	}

	private function set_status(value:FlxButtonState):FlxButtonState {
		status = value;
		updateLabelAlpha();
		updateLabelPosition();
		return status;
	}

	override function set_alpha(value:Float):Float {
		super.set_alpha(value);
		updateLabelAlpha();
		return alpha;
	}

	override function set_x(value:Float):Float {
		super.set_x(value);
		updateLabelPosition();
		return x;
	}

	override function set_y(value:Float):Float {
		super.set_y(value);
		updateLabelPosition();
		return y;
	}

	inline function get_justReleased():Bool {
		return input.justReleased;
	}

	inline function get_released():Bool {
		return input.released;
	}

	inline function get_pressed():Bool {
		return input.pressed;
	}

	inline function get_justPressed():Bool {
		return input.justPressed;
	}
}

/**
 * Helper function for `FlxButton` which handles its events.
 */
private class FlxButtonEvent implements IFlxDestroyable {
	/**
	 * The callback function to call when this event fires.
	 */
	public var callback:Void -> Void;

	#if FLX_SOUND_SYSTEM
	/**
	 * The sound to play when this event fires.
	 */
	public var sound:FlxSound;
	#end

	/**
	 * @param   callback   The callback function to call when this event fires.
	 * @param   sound      The sound to play when this event fires.
	 */
	public function new(?callback:Void -> Void, ?sound:FlxSound) {
		this.callback = callback;

		#if FLX_SOUND_SYSTEM
		this.sound = sound;
		#end
	}

	/**
	 * Cleans up memory.
	 */
	public inline function destroy():Void {
		callback = null;

		#if FLX_SOUND_SYSTEM
		sound = FlxDestroyUtil.destroy(sound);
		#end
	}

	/**
	 * Fires this event (calls the callback and plays the sound)
	 */
	public inline function fire():Void {
		if (callback != null) callback();

		#if FLX_SOUND_SYSTEM
		sound?.play(true);
		#end
	}
}
