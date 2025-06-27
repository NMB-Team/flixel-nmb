package flixel.system.debug;

private typedef IconBitmapData = openfl.display.BitmapData;

#if FLX_DEBUG @:bitmap("assets/images/debugger/cursorCross.png") #end
private final class Cross extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/mover.png") #end
private final class Mover extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/eraser.png") #end
private final class Eraser extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/bitmapLog.png") #end
private final class BitmapLog extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/transform.png") #end
private final class Transform extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/cursors/transformScaleY.png") #end
private final class ScaleY extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/cursors/transformScaleX.png") #end
private final class ScaleX extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/cursors/transformScaleXY.png") #end
private final class ScaleXY extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/cursors/transformRotate.png") #end
private final class Rotate extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/flixel.png") #end
private final class Flixel extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/drawDebug.png") #end
private final class DrawDebug extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/log.png") #end
private final class Log extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/stats.png") #end
private final class Stats extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/watch.png") #end
private final class Watch extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/console.png") #end
private final class Console extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/arrowLeft.png") #end
private final class ArrowLeft extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/arrowRight.png") #end
private final class ArrowRight extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/close.png") #end
private final class Close extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/interactive.png") #end
private final class Interactive extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/windowHandle.png") #end
private final class WindowHandle extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/minimize.png") #end
private final class Minimize extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/maximize.png") #end
private final class Maximize extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/open.png") #end
private final class Open extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/pause.png") #end
private final class Pause extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/record_off.png") #end
private final class RecordOff extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/record_on.png") #end
private final class RecordOn extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/restart.png") #end
private final class Restart extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/step.png") #end
private final class Step extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/stop.png") #end
private final class Stop extends IconBitmapData {}

@:publicFields class Icon {
	@:noCompletion private static inline final DEFAULT_POS = 11;

	static final flixel = new Flixel(DEFAULT_POS, DEFAULT_POS);
	static final cross = new Cross(DEFAULT_POS, DEFAULT_POS);
	static final mover = new Mover(DEFAULT_POS, DEFAULT_POS);
	static final eraser = new Eraser(DEFAULT_POS, DEFAULT_POS);
	static final bitmapLog = new BitmapLog(DEFAULT_POS, DEFAULT_POS);
	static final transform = new Transform(DEFAULT_POS, DEFAULT_POS);
	static final scaleX = new ScaleX(DEFAULT_POS, DEFAULT_POS);
	static final scaleY = new ScaleY(DEFAULT_POS, DEFAULT_POS);
	static final scaleXY = new ScaleXY(DEFAULT_POS, DEFAULT_POS);
	static final rotate = new Rotate(DEFAULT_POS, DEFAULT_POS);
	static final drawDebug = new DrawDebug(DEFAULT_POS, DEFAULT_POS);
	static final log = new Log(DEFAULT_POS, DEFAULT_POS);
	static final stats = new Stats(DEFAULT_POS, DEFAULT_POS);
	static final watch = new Watch(DEFAULT_POS, DEFAULT_POS);
	static final console = new Console(DEFAULT_POS, DEFAULT_POS);
	static final arrowLeft = new ArrowLeft(DEFAULT_POS, DEFAULT_POS);
	static final arrowRight = new ArrowRight(DEFAULT_POS, DEFAULT_POS);
	static final close = new Close(DEFAULT_POS, DEFAULT_POS);
	static final interactive = new Interactive(DEFAULT_POS, DEFAULT_POS);
	static final windowHandle = new WindowHandle(DEFAULT_POS, DEFAULT_POS);
	static final minimize = new Minimize(DEFAULT_POS, DEFAULT_POS);
	static final maximize = new Maximize(DEFAULT_POS, DEFAULT_POS);
	static final open = new Open(DEFAULT_POS, DEFAULT_POS);
	static final pause = new Pause(DEFAULT_POS, DEFAULT_POS);
	static final recordOff = new RecordOff(DEFAULT_POS, DEFAULT_POS);
	static final recordOn = new RecordOn(DEFAULT_POS, DEFAULT_POS);
	static final restart = new Restart(DEFAULT_POS, DEFAULT_POS);
	static final step = new Step(DEFAULT_POS, DEFAULT_POS);
	static final stop = new Stop(DEFAULT_POS, DEFAULT_POS);
}
