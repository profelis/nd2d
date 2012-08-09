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

package de.nulldesign.nd2d.display {

	import de.nulldesign.nd2d.geom.Face;
	import de.nulldesign.nd2d.materials.BlendModePresets;
    import de.nulldesign.nd2d.geom.Geometry;
    import de.nulldesign.nd2d.materials.BlendModePresets;
	import de.nulldesign.nd2d.materials.Sprite2DMaskMaterial;
	import de.nulldesign.nd2d.materials.Sprite2DMaterial;
	import de.nulldesign.nd2d.materials.SpriteAnimation;
	import de.nulldesign.nd2d.materials.texture.Texture2D;
	import de.nulldesign.nd2d.utils.Statistics;
    import de.nulldesign.nd2d.utils.nd2d;

    import flash.display3D.Context3D;

    use namespace nd2d;
	/**
	 * <p>2D sprite class</p>
	 * One draw call is used per sprite.
	 * If you have a lot of sprites with the same texture / spritesheet try to use
	 * Sprite2DBatch or Sprite2DCould, it will be a lot faster.
	 */
	public class Sprite2D extends Node2D {

		protected var mask:Sprite2D;
        nd2d var _geometry:Geometry;

		nd2d var _texture:Texture2D;
		nd2d var _animation:SpriteAnimation;
		nd2d var _material:Sprite2DMaterial;

		public var usePixelPerfectHitTest:Boolean = false;

		/**
		 * Constructor of class Sprite2D
		 * @param textureObject Texture2D
		 */
		public function Sprite2D(textureObject:Texture2D = null, geometry:Geometry = null) {
			_geometry = geometry || Geometry.createQuad();
			_animation = new SpriteAnimation(this);

			if(textureObject) {
				setMaterial(new Sprite2DMaterial());
				setTexture(textureObject);
			}
		}

		/**
		 * The texture object
		 * @param Texture2D
		 */
		public function setTexture(value:Texture2D):void {
			_texture = value;

			if(_texture) {
				_width = _texture._bitmapWidth;
				_height = _texture._bitmapHeight;

				hasPremultipliedAlphaTexture = _texture._hasPremultipliedAlpha;
				blendMode = _texture._hasPremultipliedAlpha ? BlendModePresets.NORMAL : BlendModePresets.NORMAL_NO_PREMULTIPLIED_ALPHA;
			}

			_animation.setTexture(value);
		}

		/**
		 * By default a Sprite2D has an instance of Sprite2DMaterial. You can pass
		 * other materials to the sprite to change it's appearance.
		 * @param Sprite2DMaterial
		 */
		public function setMaterial(value:Sprite2DMaterial):void {
			if(_material) {
				_material.dispose();
			}

			this._material = value;
            _geometry.setMaterial(value);
		}

		/**
		 * The mask texture can be any size, but it needs a 1px padding around the
		 * borders, otherwise the masks edges get repeated
		 * Don't disable mipmapping for the masks texture, it won't work...
		 * @param mask sprite
		 */
		public function setMask(mask:Sprite2D):void {
			this.mask = mask;

			if(mask) {
				setMaterial(new Sprite2DMaskMaterial());
			} else {
				setMaterial(new Sprite2DMaterial());
			}
		}

		/**
		 * @private
		 */
		override internal function stepNode(elapsed:Number, timeSinceStartInSeconds:Number):void {
			super.stepNode(elapsed, timeSinceStartInSeconds);

			if(_texture && _texture.sheet) {
				_animation.update(elapsed);
			}
		}

		override public function draw(context:Context3D, camera:Camera2D):void {
			if(!_material) {
				return;
			}

			if(culled) {
				Statistics.spritesCulled++;

				return;
			}

			_material.blendMode = blendMode;
			_material.scrollRect = worldScrollRect;
			_material.modelMatrix = worldModelMatrix;
			_material.clipSpaceMatrix = clipSpaceMatrix;
			_material.viewProjectionMatrix = camera.getViewProjectionMatrix(false);
			_material.colorTransform = combinedColorTransform;
			_material.animation = _animation;
			_material.texture = _texture;
			_material.uvOffsetX = uvOffsetX;
			_material.uvOffsetY = uvOffsetY;
			_material.uvScaleX = uvScaleX;
			_material.uvScaleY = uvScaleY;
			_material.usesUV = usesUV;
			_material.usesColor = usesColor;
			_material.usesColorOffset = usesColorOffset;

			if(mask) {
				if(mask.invalidateMatrix) {
					mask.updateLocalMatrix();
				}
                var ms:Sprite2DMaskMaterial = _material as Sprite2DMaskMaterial;
                ms.maskAlpha = mask.alpha;
                ms.maskTexture = mask._texture;
                ms.maskModelMatrix = mask.localModelMatrix;
			}

			_material.render(context, _geometry);

			Statistics.sprites++;
		}

		/**
		 * By default, only a bounding rectangle test is made. If you need pixel
		 * perfect hittests, enable the usePixelPerfectHitTest.
		 * This only works if this sprite has a Texture2D object with a bitmapData
		 * instance. Otherwise pixels can't be read and a default rectangle
		 * test is made
		 * @return if the sprite was hit or not
		 */
		override protected function hitTest():Boolean {
			var res:Boolean = _geometry.hitTest(_mouseX, _mouseY, _width, _height);

            if(res && usePixelPerfectHitTest && _texture._bitmap) {
                var xCoord:Number = _mouseX + _geometry.mouseDX;
				var yCoord:Number = _mouseY + _geometry.mouseDY;

				if(_texture.sheet) {
					xCoord += _animation.frameRect.x;
					yCoord += _animation.frameRect.y;
				}

				return (_texture._bitmap.getPixel32(xCoord, yCoord) >> 24 & 0xFF) > 0;
			}

            return res;
		}

		public function updateAnimationDimensions():void {
			if(_width != _animation.frameRect.width || _height != _animation.frameRect.height) {
				invalidateClipSpace = true;
			}

			_width = _animation.frameRect.width;
			_height = _animation.frameRect.height;
		}

		override public function updateUV():void {
			super.updateUV();

			// fall back to cheap uv scroll
			if(usesUV && _texture && !_texture.sheet) {
				usesUV = (_texture._bitmapWidth != _texture._textureWidth && _texture._bitmapHeight != _texture._textureHeight)
					|| (_texture._bitmapWidth != _texture._textureWidth && _uvOffsetX != 0.0 && _uvScaleX != 1.0)
					|| (_texture._bitmapHeight != _texture._textureHeight && _uvOffsetY != 0.0 && _uvScaleY != 1.0);
			}
		}

		override public function updateClipSpace():void {
			invalidateClipSpace = false;

			if(!_texture) {
				return;
			}

			clipSpaceMatrix.identity();

			if(texture.sheet) {
				clipSpaceMatrix.appendScale(animation.frameRect.width * 0.5, animation.frameRect.height * 0.5, 1.0);
				clipSpaceMatrix.appendTranslation(animation.frameOffset.x, animation.frameOffset.y, 0.0);
			} else {
				clipSpaceMatrix.appendScale(texture.bitmapWidth * 0.5, texture.bitmapHeight * 0.5, 1.0);
			}

			clipSpaceMatrix.append(worldModelMatrix);
		}

		override public function handleDeviceLoss():void {
			super.handleDeviceLoss();

            _geometry.handleDeviceLoss();

			if(_material) {
				_material.handleDeviceLoss();
			}

			if(_texture) {
				_texture.texture = null;
			}
		}

		override public function dispose():void {
			if(_material) {
				_material.dispose();
				_material = null;
			}

			if(mask) {
				mask.dispose();
				mask = null;
			}

			if(_texture) {
				_texture.dispose();
				_texture = null;
			}

            if (_geometry)
            {
                _geometry.dispose();
                _geometry = null;
            }
			_animation = null;

			super.dispose();
		}

        public function get geometry():Geometry
        {
            return _geometry;
        }

        public function get texture():Texture2D
        {
            return _texture;
        }

        public function get animation():SpriteAnimation
        {
            return _animation;
        }

        public function get material():Sprite2DMaterial
        {
            return _material;
        }
    }
}
