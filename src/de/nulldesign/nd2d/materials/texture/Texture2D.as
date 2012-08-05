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

	import de.nulldesign.nd2d.utils.Statistics;
	import de.nulldesign.nd2d.utils.TextureHelper;
    import de.nulldesign.nd2d.utils.nd2d;

    import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

    use namespace nd2d;

	public class Texture2D {

		private var _textureOptions:uint = TextureOption.QUALITY_ULTRA;

		public function get textureOptions():uint {
			return _textureOptions;
		}

		public function set textureOptions(value:uint):void {
			if(_textureOptions != value) {
				_textureOptions = value;
				textureFilteringOptionChanged = true;
			}
		}

		nd2d var texture:Texture;
        nd2d var _bitmap:BitmapData;
        nd2d var _compressedBitmap:ByteArray;

        public var sheet:TextureSheetBase;

		/*
		 * These sizes are needed to calculate the UV offset in a texture.
		 * because the GPU texturesize can differ from the provided bitmap (not a
		 * 2^n size)
		 * This is the BitmapData's or the ATF textures original size
		 */
        nd2d var _bitmapWidth:Number;
        nd2d var _bitmapHeight:Number;

        nd2d var _textureWidth:Number;
        nd2d var _textureHeight:Number;

		nd2d var uvRect:Rectangle = new Rectangle(0, 0, 1, 1);

        nd2d var _hasPremultipliedAlpha:Boolean = true;
        nd2d var textureFilteringOptionChanged:Boolean = true;

        nd2d var memoryUsed:uint = 0;

		protected var autoCleanUpResources:Boolean;

		/**
		 * Texture2D object
		 * @param autoCleanUpResources	If set to true, the Bitmap and the
		 * SpriteSheet/Atlas will be disposed with the texture.
		 * This will prevent most memory leaks but if you need to dispose and
		 * recreate Sprite2D's set this to false and dispose the texture
		 * manually.
		 */
		public function Texture2D(autoCleanUpResources:Boolean = true) {
			this.autoCleanUpResources = autoCleanUpResources;
		}

		public static function textureFromBitmapData(bitmap:BitmapData, autoCleanUpResources:Boolean = true):Texture2D {
			var tex:Texture2D = new Texture2D(autoCleanUpResources);

			if(bitmap) {
				tex._bitmap = bitmap;
				tex._bitmapWidth = bitmap.width;
				tex._bitmapHeight = bitmap.height;

				var dimensions:Point = TextureHelper.getTextureDimensionsFromBitmap(bitmap);
				tex._textureWidth = dimensions.x;
				tex._textureHeight = dimensions.y;
				tex._hasPremultipliedAlpha = true;

				tex.updateUvRect();
			}

			return tex;
		}

		public static function textureFromATF(atf:ByteArray, autoCleanUpResources:Boolean = true):Texture2D {
			var tex:Texture2D = new Texture2D(autoCleanUpResources);

			if(atf) {
				var w:int = Math.pow(2, atf[7]);
				var h:int = Math.pow(2, atf[8]);

				tex._compressedBitmap = atf;
				tex._textureWidth = tex._bitmapWidth = w;
				tex._textureHeight = tex._bitmapHeight = h;
				tex._hasPremultipliedAlpha = false;

				tex.updateUvRect();
			}

			return tex;
		}

		public static function textureFromSize(textureWidth:uint, textureHeight:uint):Texture2D {
			var tex:Texture2D = new Texture2D();
			var size:Point = TextureHelper.getTextureDimensionsFromSize(textureWidth, textureHeight);

			tex._textureWidth = size.x;
			tex._textureHeight = size.y;
			tex._bitmapWidth = size.x;
			tex._bitmapHeight = size.y;

			tex.updateUvRect();

			return tex;
		}

		protected function updateUvRect():void {
			uvRect.width = _bitmapWidth / _textureWidth;
			uvRect.height = _bitmapHeight / _textureHeight;
		}

		/**
		 *
		 * @param value		TextureSheet or TextureAtlas
		 */
		public function setSheet(value:TextureSheetBase):void {
			sheet = value;
		}

		public function getTexture(context:Context3D):Texture {
			if(!texture) {
				memoryUsed = 0;

				if(_bitmap) {
					var useMipMapping:Boolean = (_textureOptions & TextureOption.MIPMAP_LINEAR) + (_textureOptions & TextureOption.MIPMAP_NEAREST) > 0;

					texture = TextureHelper.generateTextureFromBitmap(context, _bitmap, useMipMapping, this);
				} else if(_compressedBitmap) {
					texture = TextureHelper.generateTextureFromByteArray(context, _compressedBitmap);
				} else {
					texture = context.createTexture(_textureWidth, _textureHeight, Context3DTextureFormat.BGRA, true);
					memoryUsed = _textureWidth * _textureHeight * 4;
				}

				Statistics.textures++;
				Statistics.texturesMem += memoryUsed;
			}

			return texture;
		}

		public function dispose(forceCleanUpResources:Boolean = false):void {
			if(texture) {
				texture.dispose();
				texture = null;

				Statistics.textures--;
				Statistics.texturesMem -= memoryUsed;
			}

			if(forceCleanUpResources || autoCleanUpResources) {
				if(_bitmap) {
					_bitmap.dispose();
					_bitmap = null;
				}

				if(sheet) {
					sheet.dispose();
					sheet = null;
				}

				_compressedBitmap = null;
			}
		}

        public function get bitmap():BitmapData
        {
            return _bitmap;
        }

        public function get compressedBitmap():ByteArray
        {
            return _compressedBitmap;
        }

        public function get bitmapWidth():Number
        {
            return _bitmapWidth;
        }

        public function get bitmapHeight():Number
        {
            return _bitmapHeight;
        }

        public function get textureWidth():Number
        {
            return _textureWidth;
        }

        public function get textureHeight():Number
        {
            return _textureHeight;
        }

        public function get hasPremultipliedAlpha():Boolean
        {
            return _hasPremultipliedAlpha;
        }
    }
}
