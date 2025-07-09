package flixel.system.debug;

private typedef IconBitmapData = openfl.display.BitmapData;

#if FLX_DEBUG @:bitmap("assets/images/debugger/cursorCross.png") #end
private class Cross extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/mover.png") #end
private class Mover extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/eraser.png") #end
private class Eraser extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/bitmapLog.png") #end
private class BitmapLog extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/transform.png") #end
private class Transform extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/cursors/transformScaleY.png") #end
private class ScaleY extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/cursors/transformScaleX.png") #end
private class ScaleX extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/cursors/transformScaleXY.png") #end
private class ScaleXY extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/cursors/transformRotate.png") #end
private class Rotate extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/flixel.png") #end
private class Flixel extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/drawDebug.png") #end
private class DrawDebug extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/log.png") #end
private class Log extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/stats.png") #end
private class Stats extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/watch.png") #end
private class Watch extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/console.png") #end
private class Console extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/arrowLeft.png") #end
private class ArrowLeft extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/arrowRight.png") #end
private class ArrowRight extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/close.png") #end
private class Close extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/interactive.png") #end
private class Interactive extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/windowHandle.png") #end
private class WindowHandle extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/minimize.png") #end
private class Minimize extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/maximize.png") #end
private class Maximize extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/open.png") #end
private class Open extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/pause.png") #end
private class Pause extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/record_off.png") #end
private class RecordOff extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/record_on.png") #end
private class RecordOn extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/restart.png") #end
private class Restart extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/step.png") #end
private class Step extends IconBitmapData {}

#if FLX_DEBUG @:bitmap("assets/images/debugger/buttons/stop.png") #end
private class Stop extends IconBitmapData {}

class Icon {
	static inline final defaultPos = 11;

	public static final flixel = new Flixel(defaultPos, defaultPos);
	public static final cross = new Cross(defaultPos, defaultPos);
	public static final mover = new Mover(defaultPos, defaultPos);
	public static final eraser = new Eraser(defaultPos, defaultPos);
	public static final bitmapLog = new BitmapLog(defaultPos, defaultPos);
	public static final transform = new Transform(defaultPos, defaultPos);
	public static final scaleX = new ScaleX(defaultPos, defaultPos);
	public static final scaleY = new ScaleY(defaultPos, defaultPos);
	public static final scaleXY = new ScaleXY(defaultPos, defaultPos);
	public static final rotate = new Rotate(defaultPos, defaultPos);
	public static final drawDebug = new DrawDebug(defaultPos, defaultPos);
	public static final log = new Log(defaultPos, defaultPos);
	public static final stats = new Stats(defaultPos, defaultPos);
	public static final watch = new Watch(defaultPos, defaultPos);
	public static final console = new Console(defaultPos, defaultPos);
	public static final arrowLeft = new ArrowLeft(defaultPos, defaultPos);
	public static final arrowRight = new ArrowRight(defaultPos, defaultPos);
	public static final close = new Close(defaultPos, defaultPos);
	public static final interactive = new Interactive(defaultPos, defaultPos);
	public static final windowHandle = new WindowHandle(defaultPos, defaultPos);
	public static final minimize = new Minimize(defaultPos, defaultPos);
	public static final maximize = new Maximize(defaultPos, defaultPos);
	public static final open = new Open(defaultPos, defaultPos);
	public static final pause = new Pause(defaultPos, defaultPos);
	public static final recordOff = new RecordOff(defaultPos, defaultPos);
	public static final recordOn = new RecordOn(defaultPos, defaultPos);
	public static final restart = new Restart(defaultPos, defaultPos);
	public static final step = new Step(defaultPos, defaultPos);
	public static final stop = new Stop(defaultPos, defaultPos);
}
