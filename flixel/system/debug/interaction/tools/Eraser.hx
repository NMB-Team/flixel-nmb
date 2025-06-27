package flixel.system.debug.interaction.tools;

import openfl.display.BitmapData;
import openfl.ui.Keyboard;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.system.debug.interaction.Interaction;

/**
 * A tool to delete items from the screen.
 *
 * @author Fernando Bevilacqua (dovyski@gmail.com)
 */
class Eraser extends Tool {
	override public function init(brain:Interaction):Tool {
		super.init(brain);
		_name = "Eraser";
		return this;
	}

	override public function update():Void {
		if (_brain.keyJustPressed(Keyboard.DELETE))
			doDeletion(_brain.keyPressed(Keyboard.SHIFT));
	}

	override public function activate():Void {
		doDeletion(_brain.keyPressed(Keyboard.SHIFT));
		_brain.setActiveTool(null); // No need to stay active
	}

	inline function doDeletion(remove:Bool):Void {
		final selectedItems = _brain.selectedItems;
		if (selectedItems != null) {
			findAndDelete(selectedItems, remove);
			selectedItems.clear();
		}
	}

	private function findAndDelete(items:FlxTypedGroup<FlxObject>, remove:Bool = false):Void {
		for (member in items) {
			if (member == null)
				continue;

			if (!(member is FlxTypedGroup)) {
				member.kill();
				if (remove) removeFromMemory(member, FlxG.state);
			} else
				findAndDelete(cast member, remove);
		}
	}

	private function removeFromMemory(item:FlxBasic, parentGroup:FlxGroup):Void {
		for (member in parentGroup.members) {
			if (member == null) continue;

			if ((member is FlxTypedGroup)) removeFromMemory(item, cast member);
			else if (member == item) parentGroup.remove(member);
		}
	}
}
