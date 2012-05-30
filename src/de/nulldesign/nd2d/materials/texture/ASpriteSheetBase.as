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

	import de.nulldesign.nd2d.events.SpriteSheetAnimationEvent;
	import de.nulldesign.nd2d.materials.texture.SpriteSheetAnimation;
	
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	public class ASpriteSheetBase extends EventDispatcher {

		protected var frames:Vector.<Rectangle> = new Vector.<Rectangle>();
		protected var offsets:Vector.<Point> = new Vector.<Point>();
		protected var frameNameToIndex:Dictionary = new Dictionary();
		protected var uvRects:Vector.<Rectangle>;
		protected var animationMap:Dictionary = new Dictionary();
		protected var activeAnimation:SpriteSheetAnimation;

		protected var spritesPackedWithoutSpace:Boolean;

		protected var lastTime:Number = 0.0;
		protected var interpolation:Number = 0.0;

		protected var triggerEventOnLastFrame:Boolean = false;

		protected var frameIdx:uint = 0;

		public var frameUpdated:Boolean = true;

		public var fps:uint;
		protected var defaultFPS:uint;

		public var spriteWidth:Number;
		public var spriteHeight:Number;

		protected var _sheetWidth:Number;
		protected var _sheetHeight:Number;

		protected var _frame:uint = int.MAX_VALUE;

		public function get frame():uint {
			return _frame;
		}

		public function set frame(value:uint):void {
			if(_frame != value) {
				_frame = value % frames.length;
				frameUpdated = true;

				var rect:Rectangle = frames[_frame];

				spriteWidth = rect.width;
				spriteHeight = rect.height;
			}
		}

		/**
		 * returns the total number of frames (sprites) in a spritesheet
		 */
		public function get totalFrames():uint {
			return frames.length;
		}

		public function ASpriteSheetBase() {
		}

		public function update(timeSinceStartInSeconds:Number):void {
			if(!activeAnimation) {
				return;
			}

			// time based animation
			interpolation += fps * (timeSinceStartInSeconds - lastTime);
			lastTime = timeSinceStartInSeconds;

			// there is nothing to do
			if(interpolation < 1.0) {
				return;
			}

			// allow frame skip
			frameIdx += interpolation;
			interpolation = 0;

			// last frame finished
			if(frameIdx >= activeAnimation.numFrames) {
				if(triggerEventOnLastFrame) {
					dispatchEvent(new SpriteSheetAnimationEvent(SpriteSheetAnimationEvent.ANIMATION_FINISHED));
				}

				if(!activeAnimation.loop) {
					frame = activeAnimation.frames[activeAnimation.numFrames - 1];
					stopCurrentAnimation();
					return;
				}
			}

			frameIdx %= activeAnimation.numFrames;
			frame = activeAnimation.frames[frameIdx];
		}

		public function stopCurrentAnimation():void {
			activeAnimation = null;
		}

		public function playAnimation(name:String, startIdx:uint = 0, restart:Boolean = false, fps:uint = 0, triggerEventOnLastFrame:Boolean = false):void {
			if(!animationMap[name]) {
				return;
			}

			this.fps = (fps > 0 ? fps : defaultFPS);
			this.triggerEventOnLastFrame = triggerEventOnLastFrame;

			if(restart || activeAnimation != animationMap[name]) {
				interpolation = 0;

				activeAnimation = animationMap[name];
				frameIdx = startIdx % activeAnimation.numFrames;
				frame = activeAnimation.frames[frameIdx];
			}
		}

		public function addAnimation(name:String, keyFrames:Array, loop:Boolean):void {
		}

		public function clone():ASpriteSheetBase {
			return null;
		}

		public function getOffsetForFrame():Point {
			return offsets[_frame];
		}

		/**
		 * Returns the current selected frame rectangle if no frameIdx is specified, otherwise the rect of the given frameIdx
		 * @param frameIdx
		 * @return
		 */
		public function getDimensionForFrame(frameIdx:int = -1):Rectangle {
			return frames[frameIdx > -1 ? frameIdx : _frame];
		}

		public function getIndexForFrame(name:String):uint {
			return frameNameToIndex[name];
		}

		public function setFrameByName(value:String):void {
			frame = getIndexForFrame(value);
		}

		public function getUVRectForFrame(textureWidth:Number, textureHeight:Number):Rectangle {
			if(uvRects[_frame]) {
				return uvRects[_frame];
			}

			var rect:Rectangle = frames[_frame].clone();
			var texturePixelOffset:Point = new Point((textureWidth - _sheetWidth) / 2.0, (textureHeight - _sheetHeight) / 2.0);

			rect.x += texturePixelOffset.x;
			rect.y += texturePixelOffset.y;

			if(spritesPackedWithoutSpace) {
				rect.x += 0.5;
				rect.y += 0.5;

				rect.width -= 1.0;
				rect.height -= 1.0;
			}

			rect.x /= textureWidth;
			rect.y /= textureHeight;
			rect.width /= textureWidth;
			rect.height /= textureHeight;

			uvRects[_frame] = rect;

			return rect;
		}
	}
}
