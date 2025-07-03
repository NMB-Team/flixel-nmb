package flixel.math;

import flixel.util.FlxColor;

/**
 * A class containing a set of functions for random generation. Should be accessed via `FlxG.random`.
 */
class FlxRandom {
	/**
	 * The global base random number generator seed (for deterministic behavior in recordings and saves).
	 * If you want, you can set the seed with an integer between 1 and 2,147,483,647 inclusive.
	 * Altering this yourself may break recording functionality!
	 */
	public var initialSeed(default, set) = 1;

	/**
	 * Current seed used to generate new random numbers. You can retrieve this value if,
	 * for example, you want to store the seed that was used to randomly generate a level.
	 */
	public var currentSeed(get, set):Int;

	/**
	 * Create a new FlxRandom object.
	 *
	 * @param	initialSeed  The first seed of this FlxRandom object. If ignored, a random seed will be generated.
	 */
	public function new(?initialSeed:Int) {
		if (initialSeed != null) this.initialSeed = initialSeed;
		else resetInitialSeed();
	}

	/**
	 * Function to easily set the global seed to a new random number.
	 * Please note that this function is not deterministic!
	 * If you call it in your game, recording may not function as expected.
	 *
	 * @return  The new initial seed.
	 */
	public inline function resetInitialSeed():Int {
		return initialSeed = Std.int(Math.random() * MODULUS); // use rangeBound here is not good idea, when its already uses in setter
	}

	/**
	 * Returns a pseudorandom integer between Min and Max, inclusive.
	 * Will not return a number in the Excludes array, if provided.
	 * Please note that large Excludes arrays can slow calculations.
	 *
	 * @param   min        The minimum value that should be returned. 0 by default.
	 * @param   max        The maximum value that should be returned. 2,147,483,647 by default.
	 * @param   excludes   Optional array of values that should not be returned.
	 */
	public function int(min = 0, max = MODULUS, ?excludes:Array<Int>):Int {
		if (min == max) return min;

		if (min == 0 && max == MODULUS && excludes == null)
			return Std.int(generate());

		// Swap values if reversed
		if (min > max) {
			final tmp = min;
			min = max;
			max = tmp;
		}

		final range = max - min + 1;

		if (excludes != null) {
			var result:Int;

			do {
				result = min + Std.int(generate() / MODULUS * range);
			} while (excludes.indexOf(result) >= 0);

			return result;
		} else
			return min + Std.int(generate() / MODULUS * range);
	}

	/**
	 * Returns a pseudorandom float value between Min (inclusive) and Max (exclusive).
	 * Will not return a number in the Excludes array, if provided.
	 * Please note that large Excludes arrays can slow calculations.
	 *
	 * @param   Min        The minimum value that should be returned. 0 by default.
	 * @param   Max        The maximum value that should be returned. 1 by default.
	 * @param   Excludes   Optional array of values that should not be returned.
	 */
	public function float(min = .0, max = MODULUS_FLOAT, ?excludes:Array<Float>):Float {
		if (min == max) return min;

		if (min == 0 && max == MODULUS_FLOAT && excludes == null)
			return generate() / MODULUS;

		// Swap if reversed
		if (min > max) {
			final tmp = min;
			min = max;
			max = tmp;
		}

		final range = max - min;

		if (excludes != null) {
			var result:Float;

			do {
				result = min + generate() / MODULUS * range;
			} while (excludes.indexOf(result) >= 0);

			return result;
		} else
			return min + generate() / MODULUS * range;
	}

	// helper variables for floatNormal -- it produces TWO random values with each call so we have to store some state outside the function
	var _hasFloatNormalSpare = false;
	var _floatNormalRand1 = .0;
	var _floatNormalRand2 = .0;
	final _twoPI = Math.PI * 2;
	var _floatNormalRho = .0;

	/**
	 * Returns a pseudorandom float value in a statistical normal distribution centered on Mean with a standard deviation size of StdDev.
	 * (This uses the Box-Muller transform algorithm for gaussian pseudorandom numbers)
	 *
	 * Normal distribution: 68% values are within 1 standard deviation, 95% are in 2 StdDevs, 99% in 3 StdDevs.
	 * See this image: https://github.com/HaxeFlixel/flixel-demos/blob/dev/Performance/FlxRandom/normaldistribution.png
	 *
	 * @param	mean		The Mean around which the normal distribution is centered
	 * @param	stdDev		Size of the standard deviation
	 */
	public function floatNormal(mean = .0, stdDev = 1.):Float {
		if (_hasFloatNormalSpare) {
			_hasFloatNormalSpare = false;
			return mean + stdDev * _floatNormalRho * _floatNormalRand2;
		}

		_hasFloatNormalSpare = true;

		final u = generate() / MODULUS;
		final v = generate() / MODULUS;

		final theta = _twoPI * u;
		_floatNormalRho = Math.sqrt(-2.0 * Math.log(1.0 - v));

		_floatNormalRand1 = Math.cos(theta);
		_floatNormalRand2 = Math.sin(theta);

		return mean + stdDev * _floatNormalRho * _floatNormalRand1;
	}

	/**
	 * Returns true or false based on the chance value (default 50%).
	 * For example if you wanted a player to have a 30.5% chance of getting a bonus,
	 * call bool(30.5) - true means the chance passed, false means it failed.
	 *
	 * @param   chance   The chance of receiving the value.
	 *                   Should be given as a number between 0 and 100 (effectively 0% to 100%)
	 * @return  Whether the roll passed or not.
	 */
	public inline function bool(chance = 50.):Bool {
		return float(0, 100) < chance;
	}

	/**
	 * Generates a random string of characters from a given alphabet.
	 *
	 * @param length          The length of the resulting string.
	 * @param includeUpper    If true, includes uppercase letters (A-Z).
	 * @param includeNumbers  If true, includes digits (0-9).
	 * @param includeSymbols  If true, includes common symbols (!()-_ etc.).
	 * @param customAlphabet  Optional custom alphabet (overrides all other options).
	 * @return A random string of specified length.
	 */
	public function stringCombination(length:Int, includeUpper = false, includeNumbers = false, includeSymbols = false, ?customAlphabet:String):String {
		var alphabet = customAlphabet;

		if (alphabet == null) {
			alphabet = "abcdefghijklmnopqrstuvwxyz";

			if (includeUpper)
				alphabet += "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
			if (includeNumbers)
				alphabet += "0123456789";
			if (includeSymbols)
				alphabet += "!@#$%^&*()-_=+[]{}|;:,.<>?";
		}

		final result = new StringBuf();
		for (i in 0...length) {
			final index = int(0, alphabet.length - 1);
			result.add(alphabet.charAt(index));
		}

		return result.toString();
	}

	/**
	 * Returns either a 1 or -1.
	 *
	 * @param   chance   The chance of receiving a positive value.
	 *                   Should be given as a number between 0 and 100 (effectively 0% to 100%)
	 * @return  1 or -1
	 */
	public inline function sign(chance = 50.):Int {
		return bool(chance) ? 1 : -1;
	}

	/**
	 * Pseudorandomly select from an array of weighted options. For example, if you passed in an array of [50, 30, 20]
	 * there would be a 50% chance of returning a 0, a 30% chance of returning a 1, and a 20% chance of returning a 2.
	 * Note that the values in the array do not have to add to 100 or any other number.
	 * The percent chance will be equal to a given value in the array divided by the total of all values in the array.
	 *
	 * @param   weightsArray   An array of weights.
	 * @return  A value between 0 and (SelectionArray.length - 1), with a probability equivalent to the values in SelectionArray.
	 */
	public function weightedPick(weightsArray:Array<Float>):Int {
		var totalWeight = .0;
		var pick = 0;

		for (i in weightsArray) totalWeight += i;
		totalWeight = float(0, totalWeight);

		for (i in 0...weightsArray.length) {
			if (totalWeight < weightsArray[i]) {
				pick = i;
				break;
			}

			totalWeight -= weightsArray[i];
		}

		return pick;
	}

	/**
	 * Returns a random object from an array.
	 *
	 * @param   objects        An array from which to return an object.
	 * @param   weightsArray   Optional array of weights which will determine the likelihood of returning a given value from Objects.
	 * 						   If none is passed, all objects in the Objects array will have an equal likelihood of being returned.
	 *                         Values in WeightsArray will correspond to objects in Objects exactly.
	 * @param   startIndex     Optional index from which to restrict selection. Default value is 0, or the beginning of the Objects array.
	 * @param   endIndex       Optional index at which to restrict selection. Ignored if 0, which is the default value.
	 * @return  A pseudorandomly chosen object from Objects.
	 */
	#if FLX_GENERIC
	@:generic
	#end
	public function getObject<T>(objects:Array<T>, ?weightsArray:Array<Float>, startIndex = 0, ?endIndex:Null<Int>):T {
		if (objects.length == 0) return null;

		final length = objects.length;

		final weights = weightsArray != null ? weightsArray : [for (_ in 0...length) 1.];
		final start = FlxMath.bound(startIndex, 0, length - 1);
		final end = FlxMath.bound(endIndex != null ? endIndex : length - 1, 0, length - 1);

		final from = Std.int(Math.min(start, end));
		final to = Std.int(Math.min(Math.max(start, end), weightsArray.length - 1));

		final subWeights = [for (i in from...to + 1) weights[i]];
		final pickedIndex = weightedPick(subWeights);

		return objects[from + pickedIndex];
	}

	/**
	 * Shuffles the entries in an array in-place into a new pseudorandom order,
	 * using the standard Fisher-Yates shuffle algorithm.
	 *
	 * @param  array  The array to shuffle.
	 * @since  4.2.0
	 */
	#if FLX_GENERIC
	@:generic
	#end
	public function shuffle<T>(array:Array<T>):Void {
		final maxValidIndex = array.length - 1;
		for (i in 0...maxValidIndex) {
			final j = int(i, maxValidIndex);
			final tmp = array[i];
			array[i] = array[j];
			array[j] = tmp;
		}
	}

	/**
	 * Returns a random color.
	 *
	 * @param   min        An optional FlxColor representing the lower bounds for the generated color.
	 * @param   max        An optional FlxColor representing the upper bounds for the generated color.
	 * @param 	alpha      An optional value for the alpha channel of the generated color.
	 * @param   greyScale  Whether or not to create a color that is strictly a shade of grey. False by default.
	 * @return  A color value as a FlxColor.
	 */
	public function color(?min:FlxColor, ?max:FlxColor, ?alpha:Int, greyScale = false):FlxColor {
		final rMin = min?.red ?? 0;
		final rMax = max?.red ?? 255;

		final red = int(rMin, rMax);

		final green = greyScale ? red : int(min?.green ?? 0, max?.green ?? 255);

		final blue = greyScale ? red : int(min?.blue ?? 0, max?.blue ?? 255);

		final aMin = min?.alpha ?? 0;
		final aMax = max?.alpha ?? 255;
		final finalAlpha = alpha != null ? alpha : int(aMin, aMax);

		return FlxColor.fromRGB(red, green, blue, finalAlpha);
	}

	/**
	 * Internal method to quickly generate a pseudorandom number. Used only by other functions of this class.
	 * Also updates the internal seed, which will then be used to generate the next pseudorandom number.
	 *
	 * @return  A new pseudorandom number.
	 */
	inline function generate():Float {
		return internalSeed = (internalSeed * MULTIPLIER) % MODULUS;
	}

	/**
	 * The actual internal seed. Stored as a Float value to prevent inaccuracies due to
	 * integer overflow in the generate() equation.
	 */
	var internalSeed = 1.;

	/**
	 * Internal function to update the current seed whenever the initial seed is reset,
	 * and keep the initial seed's value in range.
	 */
	inline function set_initialSeed(newSeed:Int):Int {
		return initialSeed = currentSeed = rangeBound(newSeed);
	}

	/**
	 * Returns the internal seed as an integer.
	 */
	inline function get_currentSeed():Int {
		return Std.int(internalSeed);
	}

	/**
	 * Sets the internal seed to an integer value.
	 */
	inline function set_currentSeed(newSeed:Int):Int {
		return Std.int(internalSeed = rangeBound(newSeed));
	}

	/**
	 * Internal shared function to ensure an arbitrary value is in the valid range of seed values.
	 */
	static inline function rangeBound(value:Int):Int {
		return Std.int(FlxMath.bound(value, 1, MODULUS - 1));
	}

	/**
	 * Internal shared helper variable. Used by getObject().
	 */
	static var _arrayFloatHelper:Array<Float> = null;

	/**
	 * Constants used in the pseudorandom number generation equation.
	 * These are the constants suggested by the revised MINSTD pseudorandom number generator,
	 * and they use the full range of possible integer values.
	 *
	 * @see http://en.wikipedia.org/wiki/Linear_congruential_generator
	 * @see Stephen K. Park and Keith W. Miller and Paul K. Stockmeyer (1988).
	 *      "Technical Correspondence". Communications of the ACM 36 (7): 105–110.
	 */
	static inline final MULTIPLIER = 48271.;

	static inline final MODULUS = FlxMath.MAX_VALUE_INT;
	static inline final MODULUS_FLOAT = FlxMath.MAX_VALUE_FLOAT;

	#if FLX_RECORD
	/**
	 * Internal storage for the seed used to generate the most recent state.
	 */
	static var _stateSeed = 1;

	/**
	 * The seed to be used by the recording requested in FlxGame.
	 */
	static var _recordingSeed = 1;

	/**
	 * Update the seed that was used to create the most recent state.
	 * Called by FlxGame, needed for replays.
	 *
	 * @return  The new value of the state seed.
	 */
	@:allow(flixel.FlxGame)
	static inline function updateStateSeed():Int {
		return _stateSeed = FlxG.random.currentSeed;
	}

	/**
	 * Used to store the seed for a requested recording. If StandardMode is false, this will also reset the global seed!
	 * This ensures that the state is created in the same way as just before the recording was requested.
	 *
	 * @param   standardMode   If true, entire game will be reset, else just the current state will be reset.
	 */
	@:allow(flixel.system.frontEnds.VCRFrontEnd)
	static inline function updateRecordingSeed(standardMode = true):Int {
		return _recordingSeed = FlxG.random.initialSeed = standardMode ? FlxG.random.initialSeed : _stateSeed;
	}

	/**
	 * Returns the seed to use for the requested recording.
	 */
	@:allow(flixel.FlxGame.handleReplayRequests)
	static inline function getRecordingSeed():Int {
		return _recordingSeed;
	}
	#end
}
