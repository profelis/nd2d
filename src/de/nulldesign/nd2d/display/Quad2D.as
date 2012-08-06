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

    import de.nulldesign.nd2d.geom.Geometry;
    import de.nulldesign.nd2d.geom.Vertex;
	import de.nulldesign.nd2d.materials.BlendModePresets;
	import de.nulldesign.nd2d.materials.Quad2DColorMaterial;
import de.nulldesign.nd2d.utils.nd2d;

import flash.display3D.Context3D;

    use namespace nd2d;
	/**
	 * A quad can have four custom colors (in ARGB format. eg. 0xFF990022) for
	 * each corner. The colors will be interpolated between the corners.
	 */
	public class Quad2D extends Node2D {

		nd2d var _geometry:Geometry;
		protected var material:Quad2DColorMaterial;

		public function get topLeftColor():uint {
			return _geometry.faceList[0].v1.color;
		}

		public function set topLeftColor(value:uint):void {
			var v:Vertex = _geometry.faceList[0].v1;
			v.color = value;

			_geometry.modifyColorInBuffer(0, v.r, v.g, v.b, v.a);
		}

		public function get topRightColor():uint {
			return _geometry.faceList[0].v2.color;
		}

		public function set topRightColor(value:uint):void {
			var v:Vertex = _geometry.faceList[0].v2;
			v.color = value;

            _geometry.modifyColorInBuffer(1, v.r, v.g, v.b, v.a);
		}

		public function get bottomRightColor():uint {
			return _geometry.faceList[0].v3.color;
		}

		public function set bottomRightColor(value:uint):void {
			var v:Vertex = _geometry.faceList[0].v3;
			v.color = value;

            _geometry.modifyColorInBuffer(2, v.r, v.g, v.b, v.a);
		}

		public function get bottomLeftColor():uint {
			return _geometry.faceList[1].v3.color;
		}

		public function set bottomLeftColor(value:uint):void {
			var v:Vertex = _geometry.faceList[1].v3;
			v.color = value;

            _geometry.modifyColorInBuffer(3, v.r, v.g, v.b, v.a);
		}

        public function set color(value:uint):void
        {
            topLeftColor = value;
            topRightColor = value;
            bottomLeftColor = value;
            bottomRightColor = value;
        }

		public function Quad2D(pWidth:Number, pHeight:Number, geometry:Geometry = null) {
			_width = pWidth;
			_height = pHeight;

            if (geometry)
            {
                geometry.resize(_width, _height);
            }
            _geometry = geometry || Geometry.createQuad(pWidth, pHeight);
			_geometry.setMaterial(material = new Quad2DColorMaterial());

			topLeftColor = 0xFFFF0000;
			topRightColor = 0xFF00FF00;
			bottomRightColor = 0xFF0000FF;
			bottomLeftColor = 0xFFFFFF00;

			blendMode = BlendModePresets.NORMAL_NO_PREMULTIPLIED_ALPHA;
		}

		override public function handleDeviceLoss():void {
			super.handleDeviceLoss();
            _geometry.handleDeviceLoss();

			if(material) {
				material.handleDeviceLoss();
			}
		}

        override protected function hitTest():Boolean
        {
            return _geometry.hitTest(_mouseX, _mouseY, _width, _height);
        }

        override public function draw(context:Context3D, camera:Camera2D):void {
            _geometry.update(context);

            material.blendMode = blendMode;
			material.modelMatrix = worldModelMatrix;
			material.clipSpaceMatrix = clipSpaceMatrix;
			material.viewProjectionMatrix = camera.getViewProjectionMatrix(false);
			material.render(context, _geometry);
		}

		override public function dispose():void {
			if(material) {
				material.dispose();
				material = null;
			}

            if (_geometry) {
                _geometry.dispose();
                _geometry = null;
            }

			super.dispose();
		}

        public function get geometry():Geometry
        {
            return _geometry;
        }
    }
}
