package flixel.system.debug.completion;

import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.ui.Keyboard;

using flixel.util.FlxArrayUtil;
using flixel.util.FlxStringUtil;
using StringTools;

#if hscript
import flixel.system.debug.console.ConsoleUtil;
#end

class CompletionHandler {
	static inline final ENTRY_VALUE = "Entry Value";
	static inline final ENTRY_TYPE = "Entry Type";

	var completionList:CompletionList;
	var input:TextField;
	var watchingSelection = false;

	public function new(completionList:CompletionList, input:TextField) {
		this.completionList = completionList;
		this.input = input;

		completionList.completed = completed;
		completionList.selectionChanged = selectionChanged;
		completionList.closed = completionClosed;

		input.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}

	inline function getTextUntilCaret():String {
		return input.text.substring(0, getCaretIndex());
	}

	inline function getCaretIndex():Int {
		return input.caretIndex;
	}

	private function onKeyUp(e:KeyboardEvent) {
		final text = getTextUntilCaret();

		// close completion so that enter works
		if (text.endsWith(")") || text.endsWith("\"") || text.endsWith("'") || text.endsWith(";")) {
			completionList.close();
			return;
		}

		switch (e.keyCode) {
			case Keyboard.LEFT, Keyboard.RIGHT:
				completionList.close();
			case Keyboard.ENTER, Keyboard.ESCAPE, Keyboard.UP, Keyboard.DOWN, Keyboard.TAB:
			// do nothing
			case _:
				invokeCompletion(getPathBeforeDot(text), e.keyCode == Keyboard.PERIOD);
				if (completionList.visible) completionList.filter = getWordAfterDot(text);
		}
	}

	private function invokeCompletion(path:String, isPeriod:Bool) {
		#if hscript
		var items:Array<String> = null;

		try {
			if (path.length != 0) {
				final output = ConsoleUtil.runCommand(path);
				items = ConsoleUtil.getFields(output);
			}
		} catch (e:Dynamic) {
			if (isPeriod) { // special case for cases like 'flxg.'
				completionList.close();
				return;
			}
		}

		items ??= getGlobals();

		if (items.length > 0) completionList.show(getCharXPosition(), items);
		else completionList.close();
		#end
	}

	inline function getGlobals():Array<String> {
		#if hscript
		return ConsoleUtil.interp.getGlobals().sortAlphabetically();
		#else
		return [];
		#end
	}

	inline function getCharXPosition():Float {
		var pos = .0;
		for (i in 0...getCaretIndex()) pos += 6;
		return pos;
	}

	inline function getCompletedText(text:String, selectedItem:String):String {
		// replace the last occurrence with the selected item
		return new EReg(getWordAfterDot(text) + "$", "g").replace(text, selectedItem);
	}

	private function completed(selectedItem:String) {
		final textUntilCaret = getTextUntilCaret();
		final insert = getCompletedText(textUntilCaret, selectedItem);
		input.text = insert + input.text.substr(getCaretIndex());
		input.setSelection(insert.length, insert.length);
	}

	private function selectionChanged(selectedItem:String) {
		#if hscript
		try {
			final lastWord = getLastWord(input.text);
			final command = getCompletedText(lastWord, selectedItem);
			final output = ConsoleUtil.runCommand(command);

			watchingSelection = true;
			FlxG.watch.addQuick(ENTRY_VALUE, output);
			FlxG.watch.addQuick(ENTRY_TYPE, getReadableType(output));
		} catch (e:Dynamic) {}
		#end
	}

	private function getReadableType(v:Dynamic):String {
		return switch (Type.typeof(v)) {
			case TNull: null;
			case TInt: "Int";
			case TFloat: "Float";
			case TBool: "Bool";
			case TObject: "Object";
			case TFunction: "Function";
			case TClass(Array): 'Array[${v.length}]';
			case TClass(c): FlxStringUtil.getClassName(c, true);
			case TEnum(e): FlxStringUtil.getClassName(e, true);
			case TUnknown: "Unknown";
		}
	}

	private function completionClosed() {
		if (!watchingSelection) return;

		FlxG.watch.removeQuick(ENTRY_VALUE);
		FlxG.watch.removeQuick(ENTRY_TYPE);
		watchingSelection = false;
	}

	inline function getPathBeforeDot(text:String):String {
		final lastWord = getLastWord(text);
		final dotIndex = lastWord.lastIndexOf(".");
		return lastWord.substr(0, dotIndex);
	}

	private function getWordAfterDot(text:String):String {
		final lastWord = getLastWord(text);

		var index = lastWord.lastIndexOf(".");
		if (index < 0) index = 0;
		else index++;

		final word = lastWord.substr(index);
		return (word == null) ? "" : word;
	}

	inline function getLastWord(text:String):String {
		return ~/([^.a-zA-Z0-9_\[\]"']+)/g.split(text).last();
	}
}
