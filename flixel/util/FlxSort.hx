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
}
