package flixel.util;

/**
 * A set of functions for map manipulation.
 */
class FlxMapUtil {
	/**
	 * Clear the given map.
	 */
	public static inline function clear<K, T>(map:Map<K, T>):Map<K, T> {
		map?.clear();
		return null;
	}

	/**
	 * Return a list of values from the map, as an array.
	 */
	public static function values<K, T>(map:Null<Map<K, T>>):Array<T> {
		if (map == null) return [];
		return [for (i in map.iterator()) i];
	}

	/**
	 * Create a new array with all elements of the given array, to prevent modifying the original.
	 */
	public static function clone<K, T>(map:Null<Map<K, T>>):Null<Map<K, T>> {
		if (map == null) return null;
		return map.copy();
	}

	/**
	 * Create a new map which is a combination of the two given maps.
	 * @param a The base map.
	 * @param b The other map. The values from this take precedence.
	 * @return The combined map.
	 */
	public static function merge<K, T>(a:Map<K, T>, b:Map<K, T>):Map<K, T> {
		final result = a.copy();

		for (pair in b.keyValueIterator())
			result.set(pair.key, pair.value);

		return result;
	}
}