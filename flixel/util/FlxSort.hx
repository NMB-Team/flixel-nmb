package flixel.util;

import flixel.graphics.frames.FlxFrame;
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
	 * Sorts the input array using the merge sort algorithm.
	 * Stable and guaranteed to run in linearithmic time `O(n log n)`,
	 * but less efficient in "best-case" situations.
	 *
	 * @param input The array to sort in-place.
	 * @param compare The comparison function to use.
	 */
	public static function mergeSort<T>(input:Array<T>, compare:CompareFunction<T>):Void {
		if (input == null || input.length <= 1) return;
		if (compare == null) throw 'No comparison function provided.';

		// Haxe implements merge sort by default.
		haxe.ds.ArraySort.sort(input, compare);
	}

	/**
	 * Sorts the input array using the quick sort algorithm.
	 * More efficient on smaller arrays, but is inefficient `O(n^2)` in "worst-case" situations.
	 * Not stable; relative order of equal elements is not preserved.
	 *
	 * @see https://stackoverflow.com/questions/33884057/quick-sort-stackoverflow-error-for-large-arrays
	 *      Fix for stack overflow issues.
	 * @param input The array to sort in-place.
	 * @param compare The comparison function to use.
	 */
	public static function quickSort<T>(input:Array<T>, compare:CompareFunction<T>):Void {
		if (input == null || input.length <= 1) return;
		if (compare == null) throw 'No comparison function provided.';

		quickSortInner(input, 0, input.length - 1, compare);
	}

	/**
	 * Internal recursive function for the quick sort algorithm.
	 */
	static function quickSortInner<T>(input:Array<T>, low:Int, high:Int, compare:CompareFunction<T>):Void {
		// When low == high, the array is empty or too small to sort.

		while (low < high) {
			final pivot = quickSortPartition(input, low, high, compare);

			if ((pivot) - low <= high - (pivot + 1)) {
				quickSortInner(input, low, pivot, compare);
				low = pivot + 1;
			} else {
				quickSortInner(input, pivot + 1, high, compare);
				high = pivot;
			}
		}
	}

	/**
	 * Internal function for sorting a partition of an array in the quick sort algorithm.
	 */
	static function quickSortPartition<T>(input:Array<T>, low:Int, high:Int, compare:CompareFunction<T>):Int {
		final pivot:T = input[low];
		var i = low - 1;
		var j = high + 1;

		while (true) {
			do {
				i++;
			} while (compare(input[i], pivot) < 0);

			do {
				j--;
			} while (compare(input[j], pivot) > 0);

			if (i >= j) return j;

			final temp:T = input[i];
			input[i] = input[j];
			input[j] = temp;
		}

		return -1;
	}

	/**
	 * Sorts the input array using the insertion sort algorithm.
	 * Stable and is very fast on nearly-sorted arrays,
	 * but is inefficient `O(n^2)` in "worst-case" situations.
	 *
	 * @param input The array to sort in-place.
	 * @param compare The comparison function to use.
	 */
	public static function insertionSort<T>(input:Array<T>, compare:CompareFunction<T>):Void {
		if (input == null || input.length <= 1) return;
		if (compare == null) throw 'No comparison function provided.';

		// Iterate through the array, starting at the second element.
		for (i in 1...input.length) {
			final current:T = input[i];
			var j = i - 1;

			// While the previous element is greater than the current element,
			// move the previous element to the right and move the index to the left.
			while (j >= 0 && compare(input[j], current) > 0) {
				input[j + 1] = input[j];
				j--;
			}

			input[j + 1] = current;
		}
	}

	/**
	 * You can use this function in FlxTypedGroup.sort() to sort FlxObjects by their z-index values.
	 * The value defaults to 0, but by assigning it you can easily rearrange objects as desired.
	 *
	 * @param order Either `FlxSort.ASCENDING` or `FlxSort.DESCENDING`
	 * @param a The first FlxObject to compare.
	 * @param b The second FlxObject to compare.
	 * @return 1 if `a` has a higher z-index, -1 if `b` has a higher z-index.
	 */
	public static inline function byZIndex(order:Int, a:FlxBasic, b:FlxBasic):Int {
		if (a == null || b == null) return 0;
		return byValues(order, a.zIndex, b.zIndex);
	}

	/**
	 * Given two FlxFrames, sort their names alphabetically.
	 *
	 * @param order Either `FlxSort.ASCENDING` or `FlxSort.DESCENDING`
	 * @param a The first Frame to compare.
	 * @param b The second Frame to compare.
	 * @return 1 if `a` has an earlier time, -1 if `b` has an earlier time.
	 */
	public static inline function byFrameName(a:FlxFrame, b:FlxFrame):Int {
		return alphabetically(a.name, b.name);
	}

	/**
	 * Sort predicate for sorting strings alphabetically.
	 * @param a The first string to compare.
	 * @param b The second string to compare.
	 * @return 1 if `a` comes before `b`, -1 if `b` comes before `a`, 0 if they are equal
	 */
	public static function alphabetically(a:String, b:String):Int {
		a = a.toUpperCase();
		b = b.toUpperCase();

		// Sort alphabetically. Yes that's how this works.
		return a == b ? 0 : a > b ? 1 : -1;
	}

	/**
	 * Sort predicate which sorts two strings alphabetically, but prioritizes a specific string first.
	 * Example usage: `array.sort(defaultThenAlphabetical.bind('test'))` will sort the array so that the string 'test' is first.
	 *
	 * @param defaultValue The value to prioritize.
	 * @param a The first string to compare.
	 * @param b The second string to compare.
	 * @return 1 if `a` comes before `b`, -1 if `b` comes before `a`, 0 if they are equal
	 */
	public static function defaultThenAlphabetically(defaultValue:String, a:String, b:String):Int {
		if (a == b) return 0;
		if (a == defaultValue) return -1;
		if (b == defaultValue) return 1;

		return alphabetically(a, b);
	}

	/**
	 * Sort predicate which sorts two strings alphabetically, but prioritizes a specific string first.
	 * Example usage: `array.sort(defaultsThenAlphabetical.bind(['test']))` will sort the array so that the string 'test' is first.
	 *
	 * @param defaultValues The values to prioritize.
	 * @param a The first string to compare.
	 * @param b The second string to compare.
	 * @return 1 if `a` comes before `b`, -1 if `b` comes before `a`, 0 if they are equal
	 */
	public static function defaultsThenAlphabetically(defaultValues:Array<String>, a:String, b:String):Int {
		if (a == b) return 0;
		if (defaultValues.contains(a) && defaultValues.contains(b)) return defaultValues.indexOf(a) - defaultValues.indexOf(b); // Sort by index in defaultValues

		if (defaultValues.contains(a)) return -1;
		if (defaultValues.contains(b)) return 1;

		return alphabetically(a, b);
	}

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
 * A comparison function.
 * Returns a negative number if the first argument is less than the second,
 * a positive number if the first argument is greater than the second,
 * or zero if the two arguments are equal.
 */
typedef CompareFunction<T> = T -> T -> Int;

/**
 * An interface for objects that can be sorted.
 *
 * The `ISortable` interface contains a single property, `order`, which is used to determine the order of the object in a list.
 * The `order` property is required to be an integer.
 */
interface ISortable {
	var order:Int;
}
