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

package de.nulldesign.nd2d.materials.texture {

	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class TextureSheet extends TextureSheetBase {

		/**
		 * Divides one texture into equal smaller sprites.
		 *
		 * @param texture
		 * @param spriteWidth
		 * @param spriteHeight
		 * @param distribute		If true, applies this sheet to the texture
		 */
		public function TextureSheet(texture:Texture2D, spriteWidth:Number, spriteHeight:Number, distribute:Boolean = true) {
			var rowIdx:uint;
			var colIdx:uint;
			var numCols:uint = texture._bitmapWidth / spriteWidth;
			var numRows:uint = texture._bitmapHeight / spriteHeight;
			var numSheets:uint = numCols * numRows;

			frames = new Vector.<Rectangle>(numSheets, true);
			offsets = new Vector.<Point>(numSheets, true);
			uvRects = new Vector.<Rectangle>(numSheets, true);

			for(var i:uint = 0; i < numSheets; i++) {
				rowIdx = i % numCols;
				colIdx = i / numCols;

				frames[i] = new Rectangle(
					spriteWidth * rowIdx,
					spriteHeight * colIdx,
					spriteWidth,
					spriteHeight);

				offsets[i] = new Point(0.0, 0.0);

				uvRects[i] = new Rectangle(
					(spriteWidth * rowIdx) / texture._textureWidth,
					(spriteHeight * colIdx) / texture._textureHeight,
					(spriteWidth) / texture._textureWidth,
					(spriteHeight) / texture._textureHeight);
			}

			// distribute to texture
			if(distribute) {
				texture.setSheet(this);
			}
		}

		/**
		 * Adds a new animation to this sheet.
		 *
		 * <pre>
		 * atlas.addAnimation("shoot", [4, 5, 6, 5, 6, 7]);
		 * </pre>
		 *
		 * @param name			Animation name
		 * @param keyFrames		Integer array containing the frame indices
		 * @param loop			If true, the animation will start over when finished
		 * @param fps			Frames per second
		 */
		override public function addAnimation(name:String, keyFrames:Array, loop:Boolean = true, fps:int = 1):void {
			if(keyFrames.length) {
				animationMap[name] = new TextureAnimation(keyFrames, loop, fps);
			}
		}
	}
}

