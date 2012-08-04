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
    import de.nulldesign.nd2d.materials.shader.ShaderCache;
    import de.nulldesign.nd2d.utils.nd2d;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;

    use namespace nd2d

    public class Quad2DColorMaterial extends MaterialBase {

		private const VERTEX_SHADER:String =
			"alias va0, position;" +
			"alias va1, colorOffset;" +
			"alias vc0, viewProjection;" +
			"alias vc4, clipSpace;" +

			"temp0 = mul4x4(position, clipSpace);" +
			"output = mul4x4(temp0, viewProjection);" +

			// pass to fragment shader
			"v0 = colorOffset;";

		private const FRAGMENT_SHADER:String =
			"alias v0, colorOffset;" +

			"output = colorOffset;";

		public function Quad2DColorMaterial() {
            super();
            numFloatsPerVertex = 6;
		}

		override protected function prepareForRender(context:Context3D,
                                                     geometry:Geometry):void
        {
			super.prepareForRender(context, geometry);

			context.setVertexBufferAt(0, geometry.vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2); // vertex
			context.setVertexBufferAt(1, geometry.vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_4); // color

			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, viewProjectionMatrix, true);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, clipSpaceMatrix, true);
		}

		override protected function clearAfterRender(context:Context3D):void {
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
		}

		override public function addVertex(context:Context3D, buffer:Vector.<Number>,
                                           v:Vertex, uv:UV,
                                           face:Face):void
        {
			fillBuffer(buffer, v, uv, face, VERTEX_POSITION, 2);
			fillBuffer(buffer, v, uv, face, VERTEX_COLOR, 4);
		}

		override protected function initProgram(context:Context3D):void {
			if(!shaderData) {
				shaderData = ShaderCache.getShader(context, ["Quad2D"], VERTEX_SHADER, FRAGMENT_SHADER, 6, null);
			}
		}
	}
}
