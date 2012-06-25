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

	import de.nulldesign.nd2d.materials.texture.parser.ParserBase;
	import de.nulldesign.nd2d.materials.texture.parser.ParserTexturePacker;

	public class TextureAtlas extends TextureSheetBase {

		/**
		 *
		 * @param texture
		 * @param xmlData
		 * @param xmlParser		If unset TexturePackerParser(), alternative
		 * ZwopTexParser(), ...
		 */
		public function TextureAtlas(texture:Texture2D, xmlData:XML, xmlParser:ParserBase = null) {
			if(xmlData) {
				if(!xmlParser) {
					xmlParser = new ParserTexturePacker();
				}

				xmlParser.parse(texture, xmlData);

				frames = xmlParser.frames;
				offsets = xmlParser.offsets;
				uvRects = xmlParser.uvRects;

				frameNames = xmlParser.frameNames;
				frameNameToIndex = xmlParser.frameNameToIndex;

				// distribute to texture
				texture.setSheet(this);
			}
		}

		/**
		 * Adds a new animation to this Atlas. Frames can be Integers or Strings
		 * to represent the frame name.
		 *
		 * <p>Frame names support wildcards with <em>*</em> (asterisk) and
		 * <em>?</em> (questionmark) to match multiple frames. Frame order is
		 * defined by the XML, no sort is applied.</p>
		 *
		 * <pre>
		 * atlas.addAnimation("shoot", [4, 5, 6, 7]);
		 * atlas.addAnimation("run", ["run*", "walk_end", "walk_stand"]);
		 * </pre>
		 *
		 * @param name			Animation name
		 * @param keyFrames		Integer or String array
		 * @param loop			If true, the animation will start over when finished
		 * @param fps			Frames per second
		 */
		override public function addAnimation(name:String, keyFrames:Array, loop:Boolean = true, fps:int = 1):void {
			if(keyFrames[0] is String) {
				// make indices out of names
				var keyFramesIndices:Array = [];

				for(var i:int = 0; i < keyFrames.length; i++) {
					var frameName:String = keyFrames[i];

					// wildcard match
					if(frameName.indexOf("?") >= 0 || frameName.indexOf("*") >= 0) {
						var pattern:RegExp = new RegExp("^" + frameName.replace(/\^|\$|\\|\.|\+|\(|\)|\[|\]|\||\{|\}/g, "\\$1").replace(/\?/g, ".").replace(/\*/g, ".*") + "$");

						for each(frameName in frameNames) {
							if(frameName.search(pattern) >= 0) {
								keyFramesIndices.push(frameNameToIndex[frameName]);
							}
						}
					} else {
						keyFramesIndices.push(frameNameToIndex[frameName]);
					}
				}

				animationMap[name] = new TextureAnimation(keyFramesIndices, loop, fps);
			} else {
				animationMap[name] = new TextureAnimation(keyFrames, loop, fps);
			}
		}
	}
}

