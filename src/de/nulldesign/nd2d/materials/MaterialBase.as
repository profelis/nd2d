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
    import de.nulldesign.nd2d.geom.Face;
    import de.nulldesign.nd2d.geom.Geometry;
    import de.nulldesign.nd2d.geom.UV;
    import de.nulldesign.nd2d.geom.Vertex;
    import de.nulldesign.nd2d.materials.shader.Shader2D;
    import de.nulldesign.nd2d.utils.NodeBlendMode;
    import de.nulldesign.nd2d.utils.Statistics;
    import de.nulldesign.nd2d.utils.nd2d;

    import flash.display3D.Context3D;
    import flash.geom.Matrix3D;
    import flash.geom.Rectangle;

    use namespace nd2d;

    public class MaterialBase {

		nd2d var viewProjectionMatrix:Matrix3D;

        nd2d var scrollRect:Rectangle;

        nd2d var modelMatrix:Matrix3D;

        nd2d var clipSpaceMatrix:Matrix3D = new Matrix3D();

        nd2d var blendMode:NodeBlendMode = BlendModePresets.NORMAL;

		protected var shaderData:Shader2D;

        nd2d var usesUV:Boolean = false;
		protected var lastUsesUV:Boolean = false;

        nd2d var usesColor:Boolean = false;
		protected var lastUsesColor:Boolean = false;

        nd2d var usesColorOffset:Boolean = false;
		protected var lastUsesColorOffset:Boolean = false;

        public static const VERTEX_POSITION:String = "PB3D_POSITION";
        public static const VERTEX_UV:String = "PB3D_UV";
        public static const VERTEX_COLOR:String = "PB3D_COLOR";

        /**
         * @private
         */
        public var numFloatsPerVertex:uint = 4;

		public function MaterialBase() {
		}

		protected function prepareForRender(context:Context3D, geometry:Geometry):void
        {
			context.setBlendFactors(blendMode.src, blendMode.dst);

			updateProgram(context, geometry);
		}

		public function render(context:Context3D, geometry:Geometry):void {
			prepareForRender(context, geometry);

			context.drawTriangles(geometry.indexBuffer, geometry.startTri * 3, geometry.numTris);

			Statistics.drawCalls++;
			Statistics.triangles += geometry.numTris - geometry.startTri;

			clearAfterRender(context);
		}

		protected function clearAfterRender(context:Context3D):void {
			// implement in concrete material
			throw new Error("You have to implement clearAfterRender for your material");
		}

		protected function updateProgram(context:Context3D,
                                         geometry:Geometry):void
        {
			if(shaderData == null || usesUV != lastUsesUV || usesColor != lastUsesColor || usesColorOffset != lastUsesColorOffset) {
				shaderData = null;
				initProgram(context);

				lastUsesUV = usesUV;
				lastUsesColor = usesColor;
				lastUsesColorOffset = usesColorOffset;
			}

			context.setProgram(shaderData.shader);
		}

		protected function initProgram(context:Context3D):void {
			// implement in concrete material
			throw new Error("You have to implement initProgram for your material");
		}

		public function addVertex(context:Context3D, buffer:Vector.<Number>,
                                  v:Vertex, uv:UV,
                                  face:Face):void
        {
			// implement in concrete material
			throw new Error("You have to implement addVertex for your material");
		}

        public function fillBuffer(buffer:Vector.<Number>, v:Vertex,
                                   uv:UV, face:Face, semanticsID:String,
                                   floatFormat:int):void
        {
            if(semanticsID == VERTEX_POSITION) {
                buffer.push(v.x, v.y);

                if(floatFormat >= 3) {
                    buffer.push(v.z);

                    if(floatFormat == 4) {
                        buffer.push(v.w);
                    }
                }
            } else if(semanticsID == VERTEX_UV) {
                buffer.push(uv.u, uv.v);

                if(floatFormat >= 3) {
                    buffer.push(0.0);

                    if(floatFormat == 4) {
                        buffer.push(0.0);
                    }
                }
            } else if(semanticsID == VERTEX_COLOR) {
                buffer.push(v.r, v.g, v.b);

                if(floatFormat == 4) {
                    buffer.push(v.a);
                }
            }
        }


		public function handleDeviceLoss():void {
			shaderData = null;
		}

		public function dispose():void {
			blendMode = null;
			shaderData = null;
			scrollRect = null;

			modelMatrix = null;
			clipSpaceMatrix = null;
			viewProjectionMatrix = null;
		}
	}
}
