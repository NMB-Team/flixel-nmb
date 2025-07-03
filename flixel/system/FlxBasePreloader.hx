package flixel.system;

import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import openfl.Lib;
import openfl.Vector;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.GradientType;
import openfl.display.GraphicsPathWinding;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.ProgressEvent;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.net.URLRequest;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

class FlxBasePreloader extends DefaultPreloader {
	/**
	 * Add this string to allowedURLs array if you want to be able to test game with enabled site-locking on local machine
	 */
	public static inline final LOCAL = "localhost";

	/**
	 * Change this if you want the flixel logo to show for more or less time.  Default value is 0 seconds (no delay).
	 */
	public var minDisplayTime = .0;

	/**
	 * List of allowed URLs for built-in site-locking.
	 * Set it in FlxPreloader's constructor as: `['http://adamatomic.com/canabalt/', FlxPreloader.LOCAL]`;
	 */
	public var allowedURLs:Array<String>;

	/**
	 * The index of which URL in allowedURLs will be triggered when a user clicks on the Site-lock Message.
	 * For example, if allowedURLs is `['mysite.com', 'othersite.com']`, and `siteLockURLIndex = 1`, then
	 * the user will go to 'othersite.com' when they click the message, but sitelocking will allow either of those URLs to work.
	 * Defaults to 0.
	 */
	public var siteLockURLIndex = 0;

	/**
	 * The title text to display on the sitelock failure screen.
	 * NOTE: This string should be reviewed for accuracy and may need to be localized.
	 *
	 * To customize this variable, create a class extending `FlxBasePreloader`, and override its value in the constructor:
	 *
	 * ```haxe
	 * class Preloader extends FlxBasePreloader {
	 *     public function new():Void  {
	 *         super(0, ["http://placeholder.domain.test/path/document.html"]);
	 *
	 *         siteLockTitleText = "Custom title text.";
	 *         siteLockBodyText = "Custom body text.";
	 *     }
	 * }
	 * ```
	 * @since 4.3.0
	 */
	public var siteLockTitleText = "Sorry.";

	/**
	 * The body text to display on the sitelock failure screen.
	 * NOTE: This string should be reviewed for accuracy and may need to be localized.
	 *
	 * To customize this variable, create a class extending `FlxBasePreloader`, and override its value in the constructor.
	 * @see `siteLockTitleText`
	 * @since 4.3.0
	 */
	public var siteLockBodyText = "It appears the website you are using is hosting an unauthorized copy of this game. "
		+ "Storage or redistribution of this content, without the express permission of the "
		+ "developer or other copyright holder, is prohibited under copyright law.\n\n"
		+ "Thank you for your interest in this game! Please support the developer by "
		+ "visiting the following website to play the game:";

	var _percent = .0;
	var _width:Int;
	var _height:Int;
	var _loaded = false;
	var _urlChecked = false;
	var _destroyed = false;
	var _startTime:Float;

	/**
	 * FlxBasePreloader Constructor.
	 * @param	minDisplayTime	Minimum time (in seconds) the preloader should be shown. (Default = 0)
	 * @param	allowedURLs		Allowed URLs used for Site-locking. If the game is run anywhere else, a message will be displayed on the screen (Default = [])
	 */
	public function new(minDisplayTime = .0, ?allowedURLs:Array<String>) {
		super();

		this.minDisplayTime = minDisplayTime;
		this.allowedURLs = (allowedURLs != null) ? allowedURLs : [];

		_startTime = Date.now().getTime();

		#if !web
		// just skip the preloader on native targets
		onLoaded();
		#end
	}

	/**
	 * Override this to create your own preloader objects.
	 */
	private function create():Void {}

	/**
	 * This function is called externally to initialize the Preloader.
	 */
	override public function onInit() {
		super.onInit();

		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		Lib.current.stage.align = StageAlign.TOP_LEFT;
		create();
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		checkSiteLock();
	}

	/**
	 * This function is called each update to check the load status of the project.
	 * It is highly recommended that you do NOT override this.
	 */
	override public function onUpdate(bytesLoaded:Int, bytesTotal:Int) {
		#if web
		_percent = (bytesTotal != 0) ? bytesLoaded / bytesTotal : 0;
		#else
		super.onUpdate(bytesLoaded, bytesTotal);
		#end
	}

	/**
	 * This function is triggered on each 'frame'.
	 * It is highly recommended that you do NOT override this.
	 */
	private function onEnterFrame(E:Event):Void {
		final time = Date.now().getTime() - _startTime;
		final min = minDisplayTime * 1000;
		var percent = _percent;
		if ((min > 0) && (_percent > time / min)) percent = time / min;

		if (!_destroyed) update(percent);

		if (_loaded && (min <= 0 || time / min >= 1)) {
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			super.onLoaded();
			destroy();
			_destroyed = true;
		}
	}

	/**
	 * This function is called when the project has finished loading.
	 * Override it to remove all of your objects.
	 */
	private function destroy():Void {}

	/**
	 * Override to draw your preloader objects in response to the Percent
	 *
	 * @param	Percent		How much of the program has loaded.
	 */
	private function update(Percent:Float):Void {}

	/**
	 * This function is called EXTERNALLY once the movie has actually finished being loaded.
	 * Highly recommended you DO NOT override.
	 */
	override public function onLoaded() {
		_loaded = true;
		_percent = 1;
	}

	/**
	 * This should be used whenever you want to create a Bitmap that uses BitmapData embedded with the
	 * @:bitmap metadata, if you want to support both Flash and HTML5. Because the embedded data is loaded
	 * asynchronously in HTML5, any code that depends on the pixel data or size of the bitmap should be
	 * in the onLoad function; any such code executed before it is called will fail on the HTML5 target.
	 *
	 * @param	bitmapDataClass		A reference to the BitmapData child class that contains the embedded data which is to be used.
	 * @param	onLoad				Executed once the bitmap data is finished loading in HTML5, and immediately in Flash. The new Bitmap instance is passed as an argument.
	 * @return  The Bitmap instance that was created.
	 */
	private function createBitmap(bitmapDataClass:Class<BitmapData>, onLoad:Bitmap -> Void):Bitmap {
		#if html5
		final bmp = new Bitmap();
		bmp.bitmapData = Type.createInstance(bitmapDataClass, [0, 0, true, 0xFFFFFFFF, _ -> onLoad(bmp)]);
		return bmp;
		#else
		final bmp = new Bitmap(Type.createInstance(bitmapDataClass, [0, 0]));
		onLoad(bmp);
		return bmp;
		#end
	}

	/**
	 * This should be used whenever you want to create a BitmapData object from a class containing data embedded with
	 * the @:bitmap metadata. Often, you'll want to use the BitmapData in a Bitmap object; in this case, createBitmap()
	 * can should be used instead. Because the embedded data is loaded asynchronously in HTML5, any code that depends on
	 * the pixel data or size of the bitmap should be in the onLoad function; any such code executed before it is called
	 * will fail on the HTML5 target.
	 *
	 * @param	bitmapDataClass		A reference to the BitmapData child class that contains the embedded data which is to be used.
	 * @param	onLoad				Executed once the bitmap data is finished loading in HTML5, and immediately in Flash. The new BitmapData instance is passed as an argument.
	 * @return  The BitmapData instance that was created.
	 */
	private function loadBitmapData(bitmapDataClass:Class<BitmapData>, onLoad:BitmapData -> Void):BitmapData {
		#if html5
		return Type.createInstance(bitmapDataClass, [0, 0, true, 0xFFFFFFFF, onLoad]);
		#else
		final bmpData = Type.createInstance(bitmapDataClass, [0, 0]);
		onLoad(bmpData);
		return bmpData;
		#end
	}

	/**
	 * Site-locking Functionality
	 */
	private function checkSiteLock():Void {
		#if web
		if (_urlChecked) return;

		if (!isHostUrlAllowed()) {
			removeChildren();
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);

			createSiteLockFailureScreen();
		} else
			_urlChecked = true;
		#end
	}

	#if web
	/**
	 * When overridden, allows the customized creation of the sitelock failure screen.
	 * @since 4.3.0
	 */
	private function createSiteLockFailureScreen():Void {
		addChild(createSiteLockFailureBackground(0xffffff, 0xe5e5e5));
		addChild(createSiteLockFailureIcon(0xe5e5e5, .9));
		addChild(createSiteLockFailureText(30));
	}

	private function createSiteLockFailureBackground(innerColor:FlxColor, outerColor:FlxColor):Shape {
		final shape = new Shape();
		final graphics = shape.graphics;
		graphics.clear();

		final fillMatrix = new Matrix();
		fillMatrix.createGradientBox(1, 1, 0, -.5, -.5);

		final scaling = Math.max(stage.stageWidth, stage.stageHeight);
		fillMatrix.scale(scaling, scaling);
		fillMatrix.translate(.5 * stage.stageWidth, .5 * stage.stageHeight);

		graphics.beginGradientFill(GradientType.RADIAL, [innerColor, outerColor], [1, 1], [0, 255], fillMatrix);
		graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		graphics.endFill();
		return shape;
	}

	private function createSiteLockFailureIcon(color:FlxColor, scale:Float):Shape {
		final shape = new Shape();
		final graphics = shape.graphics;
		graphics.clear();

		graphics.beginFill(color);
		graphics.drawPath(Vector.ofArray([1, 6, 2, 2, 2, 6, 6, 2, 2, 2, 6, 1, 6, 2, 6, 2, 6, 2, 6, 1, 6, 6, 2, 2, 2, 6, 6]), Vector.ofArray([
			120.0, 0, 164, 0, 200, 35, 200, 79, 200, 130, 160, 130, 160, 79, 160, 57, 142, 40, 120, 40, 97, 40, 79, 57, 79, 79, 80, 130, 40, 130, 40, 79, 40,
			35, 75, 0, 120, 0, 220, 140, 231, 140, 240, 148, 240, 160, 240, 300, 240, 311, 231, 320, 220, 320, 20, 320, 8, 320, 0, 311, 0, 300, 0, 160, 0,
			148, 8, 140, 20, 140, 120, 190, 108, 190, 100, 198, 100, 210, 100, 217, 104, 223, 110, 227, 110, 270, 130, 270, 130, 227, 135, 223, 140, 217, 140,
			210, 140, 198, 131, 190, 120, 190
		]), GraphicsPathWinding.NON_ZERO);
		graphics.endFill();

		final transformMatrix = new Matrix();
		transformMatrix.translate(-.5 * shape.width, -.5 * shape.height);

		final scaling = scale * Math.min(stage.stageWidth / shape.width, stage.stageHeight / shape.height);
		transformMatrix.scale(scaling, scaling);
		transformMatrix.translate(.5 * stage.stageWidth, .5 * stage.stageHeight);
		shape.transform.matrix = transformMatrix;
		return shape;
	}

	private function createSiteLockFailureText(margin:Float):Sprite {
		final sprite = new Sprite();
		final bounds = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
		bounds.inflate(-margin, -margin);

		final titleText = new TextField();
		final titleTextFormat = new TextFormat("_sans", 33, 0x333333, true);
		titleTextFormat.align = TextFormatAlign.LEFT;
		titleText.defaultTextFormat = titleTextFormat;
		titleText.selectable = false;
		titleText.width = bounds.width;
		titleText.text = siteLockTitleText;

		final bodyText = new TextField();
		final bodyTextFormat = new TextFormat("_sans", 22, 0x333333);
		bodyTextFormat.align = TextFormatAlign.JUSTIFY;
		bodyText.defaultTextFormat = bodyTextFormat;
		bodyText.multiline = bodyText.wordWrap = true;
		bodyText.selectable = false;
		bodyText.width = bounds.width;
		bodyText.text = siteLockBodyText;

		final hyperlinkText = new TextField();
		final hyperlinkTextFormat = new TextFormat("_sans", 22, 0x6e97cc, true, false, true);
		hyperlinkTextFormat.align = TextFormatAlign.CENTER;
		hyperlinkTextFormat.url = allowedURLs[siteLockURLIndex];
		hyperlinkText.defaultTextFormat = hyperlinkTextFormat;
		hyperlinkText.selectable = true;
		hyperlinkText.width = bounds.width;
		hyperlinkText.text = allowedURLs[siteLockURLIndex];

		// Do customization before final layout.
		adjustSiteLockTextFields(titleText, bodyText, hyperlinkText);

		final gutterSize = 4;
		titleText.height = titleText.textHeight + gutterSize;
		bodyText.height = bodyText.textHeight + gutterSize;
		hyperlinkText.height = hyperlinkText.textHeight + gutterSize;
		titleText.x = bodyText.x = hyperlinkText.x = bounds.left;
		titleText.y = bounds.top;
		bodyText.y = titleText.y + 2 * titleText.height;
		hyperlinkText.y = bodyText.y + bodyText.height + hyperlinkText.height;

		sprite.addChild(titleText);
		sprite.addChild(bodyText);
		sprite.addChild(hyperlinkText);
		return sprite;
	}

	/**
	 * When overridden, allows the customization of the text fields in the sitelock failure screen.
	 * @since 4.3.0
	 */
	private function adjustSiteLockTextFields(titleText:TextField, bodyText:TextField, hyperlinkText:TextField):Void {}

	private function goToMyURL(?e:MouseEvent):Void {
		// if the chosen URL isn't "local", use FlxG's openURL() function.
		if (allowedURLs[siteLockURLIndex] != FlxBasePreloader.LOCAL)
			FlxG.openURL(allowedURLs[siteLockURLIndex]);
		else
			Lib.getURL(new URLRequest(allowedURLs[siteLockURLIndex]));
	}

	private function isHostUrlAllowed():Bool {
		if (allowedURLs.length == 0) return true;

		final homeURL = #if js js.Browser.location.href #else "" #end;
		final homeDomain = FlxStringUtil.getDomain(homeURL);
		for (allowedURL in allowedURLs) {
			final allowedDomain = FlxStringUtil.getDomain(allowedURL);
			if (allowedDomain == homeDomain) return true;
		}
		return false;
	}
	#end
}

// This is a slightly trimmed down version of the NMEPreloader present in older OpenFL versions
private class DefaultPreloader extends Sprite {
	public function new() {
		super();
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	public function onAddedToStage(_) {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

		onInit();
		onUpdate(loaderInfo.bytesLoaded, loaderInfo.bytesTotal);

		addEventListener(ProgressEvent.PROGRESS, onProgress);
		addEventListener(Event.COMPLETE, onComplete);
	}

	private function onComplete(event:Event):Void {
		event.preventDefault();

		removeEventListener(ProgressEvent.PROGRESS, onProgress);
		removeEventListener(Event.COMPLETE, onComplete);

		onLoaded();
	}

	public function onProgress(event:ProgressEvent):Void {
		onUpdate(Std.int(event.bytesLoaded), Std.int(event.bytesTotal));
	}

	public function onInit() {}

	public function onLoaded() {
		dispatchEvent(new Event(Event.UNLOAD));
	}

	public function onUpdate(bytesLoaded:Int, bytesTotal:Int):Void {
		var percentLoaded = .0;
		if (bytesTotal > 0) {
			percentLoaded = bytesLoaded / bytesTotal;
			if (percentLoaded > 1) percentLoaded = 1;
		}
	}
}
