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

package de.nulldesign.nd2d.materials {

	import de.nulldesign.nd2d.display.Sprite2D;
	import de.nulldesign.nd2d.events.SpriteAnimationEvent;
	import de.nulldesign.nd2d.materials.texture.Texture2D;
	import de.nulldesign.nd2d.materials.texture.TextureAnimation;

	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * Dispatched when the current animation has finished.
	 * @eventType SpriteSheetAnimationEvent.ANIMATION_FINISHED
	 */
	[Event(name="animationFinished", type="de.nulldesign.nd2d.events.SpriteAnimationEvent")]

	public class SpriteAnimation extends EventDispatcher {

		public var fps:int;
		public var frameOffset:Point;
		public var frameRect:Rectangle;
		public var frameUV:Rectangle;
		public var frameUpdated:Boolean = true;

		protected var parent:Sprite2D;
		protected var frameIdx:uint = 0;
		protected var texture:Texture2D;
		protected var frameInterpolation:Number = 0.0;
		protected var activeAnimation:TextureAnimation;

		public function SpriteAnimation(parent:Sprite2D) {
			this.parent = parent;
		}

		public function setTexture(value:Texture2D):void {
			texture = value;

			if(texture.sheet) {
				frame = 0;
			} else {
				frameUV = texture.uvRect;
				frameRect = new Rectangle(0, 0, texture.bitmapWidth, texture.bitmapHeight);
				frameOffset = new Point(0, 0);
			}
		}

		protected var _frame:uint = int.MAX_VALUE;

		public function get frame():uint {
			return _frame;
		}

		public function set frame(value:uint):void {
			if(_frame != value && texture && texture.sheet) {
				frameUpdated = true;
				_frame = value % texture.sheet.frames.length;

				frameUV = texture.sheet.uvRects[_frame];
				frameRect = texture.sheet.frames[_frame];
				frameOffset = texture.sheet.offsets[_frame];

				parent.updateAnimationDimensions();
			}
		}

		public function setFrameByName(name:String):void {
			if(texture && texture.sheet) {
				frame = texture.sheet.getIndexForFrame(name);
			}
		}

		public function setFrameByAnimation(name:String, idx:uint = 0):void {
			if(!texture || !texture.sheet) {
				return;
			}

			var animation:TextureAnimation = texture.sheet.animationMap[name];

			if(animation) {
				frameIdx = idx % animation.numFrames;
				frame = animation.frames[frameIdx];
			}
		}

		public function play(name:String, startIdx:uint = 0, fps:int = 0, restart:Boolean = false):void {
			if(!texture || !texture.sheet || !texture.sheet.animationMap[name]) {
				return;
			}

			if(restart || activeAnimation != texture.sheet.animationMap[name]) {
				frameInterpolation = 0;

				activeAnimation = texture.sheet.animationMap[name];
				frameIdx = startIdx % activeAnimation.numFrames;
				frame = activeAnimation.frames[frameIdx];

				this.fps = (!fps ? activeAnimation.fps : fps);
			}
		}

		public function stop():void {
			activeAnimation = null;
		}

		public function update(elapsed:Number):void {
			if(!activeAnimation || !fps) {
				return;
			}

			// time based animation
			frameInterpolation += fps * elapsed;

			// there is nothing to do
			if(frameInterpolation < 1.0) {
				return;
			}

			// frame skip, this compensates lag and also can run animations at very high framerates, e.g. 120
			frameIdx += frameInterpolation;
			frameInterpolation = 0;

			// last frame finished
			if(frameIdx >= activeAnimation.numFrames) {
				dispatchEvent(new SpriteAnimationEvent(SpriteAnimationEvent.ANIMATION_FINISHED));

				if(!activeAnimation.loop) {
					frame = activeAnimation.frames[activeAnimation.numFrames - 1];
					activeAnimation = null;
					return;
				}
			}

			frameIdx %= activeAnimation.numFrames;
			frame = activeAnimation.frames[frameIdx];
		}
	}
}
