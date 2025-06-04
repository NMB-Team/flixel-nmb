package flixel.util;

import flixel.FlxObject;

/**
 * Helper class for sort() in FlxTypedGroup, but could theoretically be used on regular arrays as well.
 */
class FlxSort {
	/** Sort order constant for ascending (smallest to largest) sorting. */
	public static inline final ASCENDING = -1;
	/** Sort order constant for descending (largest to smallest) sorting. */
	public static inline final DESCENDING = 1;

	/**
	 * You can use this function in FlxTypedGroup.sort() to sort FlxObjects by their y values.
	 *
	 * @param order The sorting order; use FlxSort.ASCENDING or FlxSort.DESCENDING.
	 * @param obj1 First object to compare.
	 * @param obj2 Second object to compare.
	 * @return Sorting value: -1, 0, or 1.
	 */
	public static inline function byY(order:Int, obj1:FlxObject, obj2:FlxObject):Int {
		return byValues(order, obj1.y, obj2.y);
	}

	/**
	 * You can use this function as a backend to write a custom sorting function (see byY() for an example).
	 *
	 * @param order The sorting order; use FlxSort.ASCENDING or FlxSort.DESCENDING.
	 * @param value1 First value to compare.
	 * @param value2 Second value to compare.
	 * @return Sorting value: -1, 0, or 1.
	 */
	public static inline function byValues(order:Int, value1:Float, value2:Float):Int {
		return (value1 < value2) ? order : ((value1 > value2) ? -order : 0);
	}

	/**
	 * Sorts two objects with a `order` property by their `order` properties.
	 * 
	 * @param index The index to use for sorting (usually either 1 or -1).
	 * @param obj1 The first object to compare.
	 * @param obj2 The second object to compare.
	 */
	public static inline function sortByOrder(index:Int, obj1:ISortable, obj2:ISortable):Int {
		return obj1.order > obj2.order ? -index : obj2.order > obj1.order ? index : 0;
	}

	/**
	 * Sorts two objects by their `ID` properties.
	 * 
	 * @param index The index to use for sorting (usually either 1 or -1).
	 * @param basic1 The first object to compare.
	 * @param basic2 The second object to compare.
	 */
	public static inline function sortByID(index:Int, basic1:FlxBasic, basic2:FlxBasic):Int {
		return basic1.ID > basic2.ID ? -index : basic2.ID > basic1.ID ? index : 0;
	}
}

/**
 * An interface for objects that can be sorted.
 * 
 * The `ISortable` interface contains a single property, `order`, which is used to determine the order of the object in a list.
 * The `order` property is required to be an integer.
 */
interface ISortable {
	var order:Int;
}
