/*
 * ND2D - A Flash Molehill GPU accelerated 2D engine
 *
 * Author: Lars Gerckens
 * Copyright (c) nulldesign 2011
 * Repository URL: http://github.com/nulldesign/nd2d
 * Getting started: https://github.com/nulldesign/nd2d/wiki
 *
 *
 * Licence Agreement
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package de.nulldesign.nd2d.utils {

	public class NumberUtil {

		/**
		 * Forces a number into a specified range.
		 *
		 * <pre>
		 * // 1.5
		 * trace( NumberUtil.clamp(1.5, 1.0, 2.0) );
		 *
		 * // 1
		 * trace( NumberUtil.clamp(0.5, 1.0, 2.0) );
		 *
		 * // 2
		 * trace( NumberUtil.clamp(2.5, 1.0, 2.0) );
		 * </pre>
		 *
		 * @param value
		 * @param min
		 * @param max
		 * @return
		 */
		public static function clamp(value:Number, min:Number, max:Number):Number {
			return (value < min ? min : (value > max ? max : value));
		}

		/**
		 * Mathematical modulo for negative numbers.
		 *
		 * <pre>
		 * // -1
		 * trace( -1 % 6 );
		 *
		 * // 5
		 * trace( NumberUtil.mod(-1, 6) );
		 * </pre>
		 *
		 * @param a
		 * @param n
		 * @return
		 */
		public static function mod(a:Number, n:Number):Number {
			return ((a % n + n) % n);
		}

		/**
		 * Generates a pseudo-random number between <em>min</em> and <em>max</em>.
		 *
		 * @param min
		 * @param max
		 * @return		Pseudo-random number.
		 */
		public static function random(min:Number = 0, max:Number = 1):Number {
			return min + Math.random() * (max - min);
		}

		/**
		 * Rounding to a specified precision.
		 *
		 * <pre>
		 * // 1
		 * trace( Math.round(1.23456) );
		 *
		 * // 1.235
		 * trace( NumberUtil.round(1.23456, 3) );
		 *
		 * // 1.235
		 * trace( NumberUtil.roundTo(1.23456, 0.001) );
		 * </pre>
		 *
		 * @param number
		 * @param precision
		 * @return
		 */
		public static function round(number:Number, precision:uint = 0):Number {
			if(!precision) {
				return Math.round(number);
			}

			var decimals:Number = Math.pow(10, precision);

			return Math.round(number * decimals) / decimals;
		}

		/**
		 * Rounding to a specified increment.
		 *
		 * <pre>
		 * // 1
		 * trace( NumberUtil.roundTo(1.16, 0.5) );
		 *
		 * // 1.5
		 * trace( NumberUtil.roundTo(1.47, 0.5) );
		 *
		 * // 2
		 * trace( NumberUtil.roundTo(1.84, 0.5) );
		 * </pre>
		 *
		 * @param number
		 * @param increment
		 * @return
		 */
		public static function roundTo(number:Number, increment:Number = 0):Number {
			if(!increment) {
				return number;
			}

			return Math.round(number / increment) * increment;
		}

		/**
		 * Like Math.cos() but scales the result to specified <em>min</em> and
		 * <em>max</em>.
		 *
		 * @param angleRadians
		 * @param min
		 * @param max
		 * @return
		 */
		public static function cos(angleRadians:Number, min:Number = 0, max:Number = 1):Number {
			var value:Number = 0.5 + 0.5 * Math.cos(angleRadians);

			return min + value * (max - min);
		}

		/**
		 * Like Math.sin() but scales the result to specified <em>min</em> and
		 * <em>max</em>.
		 *
		 * @param angleRadians
		 * @param min
		 * @param max
		 * @return
		 */
		public static function sin(angleRadians:Number, min:Number = 0, max:Number = 1):Number {
			var value:Number = 0.5 + 0.5 * Math.sin(angleRadians);

			return min + value * (max - min);
		}
	}
}
