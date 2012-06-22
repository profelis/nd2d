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
	import de.nulldesign.nd2d.geom.UV;
	import de.nulldesign.nd2d.geom.Vertex;
	import de.nulldesign.nd2d.materials.shader.ShaderCache;
	import de.nulldesign.nd2d.materials.texture.Texture2D;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;

	public class Sprite2DMaterial extends BaseMaterial {

		private const VERTEX_SHADER:String =
			"alias va0, position;" +
			"alias va1.xy, uv;" +
			"alias vc0, viewProjection;" +
			"alias vc4, clipSpace;" +
			"alias vc8, colorMultiplier;" +
			"alias vc9, colorOffset;" +
			"alias vc10, uvSheet;" +
			"alias vc11.xy, uvOffset;" +
			"alias vc11.zw, uvScale;" +

			"temp0 = mul4x4(position, clipSpace);" +
			"output = mul4x4(temp0, viewProjection);" +

			"#if USE_UV;" +
			"	temp0 = uv * uvScale;" +
			"	temp0 += uvOffset;" +
			"#else;" +
			"	temp0 = uv * uvSheet.zw;" +
			"	temp0 += uvSheet.xy;" +
			"#endif;" +

			// pass to fragment shader
			"v0 = temp0;" +
			"v1 = colorMultiplier;" +
			"v2 = colorOffset;" +
			"v3 = uvSheet;";

		private const FRAGMENT_SHADER:String =
			"alias v0, texCoord;" +
			"alias v1, colorMultiplier;" +
			"alias v2, colorOffset;" +
			"alias v3.xy, uvSheetOffset;" +
			"alias v3.zw, uvSheetScale;" +

			"#if USE_UV;" +
			"	temp0 = frac(texCoord);" +
			"	temp0 *= uvSheetScale;" +
			"	temp0 += uvSheetOffset;" +
			"	temp0 = sampleNoMip(temp0, texture0);" +
			"#else;" +
			"	temp0 = sample(texCoord, texture0);" +
			"#endif;" +

			"output = colorize(temp0, colorMultiplier, colorOffset);";

		public var texture:Texture2D;
		public var animation:SpriteAnimation;
		public var colorTransform:ColorTransform;

		public var uvOffsetX:Number = 0.0;
		public var uvOffsetY:Number = 0.0;
		public var uvScaleX:Number = 1.0;
		public var uvScaleY:Number = 1.0;

		private var programConstants:Vector.<Number> = new Vector.<Number>(16, true);

		public function Sprite2DMaterial() {
		}

		override protected function prepareForRender(context:Context3D):void {
			super.prepareForRender(context);

			var uvSheet:Rectangle = (texture.sheet ? animation.frameUV : texture.uvRect);

			context.setTextureAt(0, texture.getTexture(context));
			context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2); // vertex
			context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2); // uv

			programConstants[0] = colorTransform.redMultiplier;
			programConstants[1] = colorTransform.greenMultiplier;
			programConstants[2] = colorTransform.blueMultiplier;
			programConstants[3] = colorTransform.alphaMultiplier;

			programConstants[4] = colorTransform.redOffset;
			programConstants[5] = colorTransform.greenOffset;
			programConstants[6] = colorTransform.blueOffset;
			programConstants[7] = colorTransform.alphaOffset;

			programConstants[8] = uvSheet.x;
			programConstants[9] = uvSheet.y;
			programConstants[10] = uvSheet.width;
			programConstants[11] = uvSheet.height;

			programConstants[12] = uvOffsetX;
			programConstants[13] = uvOffsetY;
			programConstants[14] = uvScaleX;
			programConstants[15] = uvScaleY;

			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, viewProjectionMatrix, true);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, clipSpaceMatrix, true);

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 8, programConstants);
		}

		override protected function clearAfterRender(context:Context3D):void {
			context.setTextureAt(0, null);
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
		}

		override protected function addVertex(context:Context3D, buffer:Vector.<Number>, v:Vertex, uv:UV, face:Face):void {
			fillBuffer(buffer, v, uv, face, VERTEX_POSITION, 2);
			fillBuffer(buffer, v, uv, face, VERTEX_UV, 2);
		}

		override protected function initProgram(context:Context3D):void {
			if(!shaderData) {
				var defines:String =
					"#define PREMULTIPLIED_ALPHA=" + int(texture.hasPremultipliedAlpha) + ";" +
					"#define USE_UV=" + int(usesUV) + ";" +
					"#define USE_COLOR=" + int(usesColor) + ";" +
					"#define USE_COLOR_OFFSET=" + int(usesColorOffset) + ";";

				shaderData = ShaderCache.getShader(context, defines, VERTEX_SHADER, FRAGMENT_SHADER, 4, texture.textureOptions);
			}
		}

		public function modifyVertexInBuffer(bufferIdx:uint, x:Number, y:Number):void {
			if(!mVertexBuffer || mVertexBuffer.length == 0) {
				return;
			}

			const idx:uint = bufferIdx * shaderData.numFloatsPerVertex;

			mVertexBuffer[idx] = x;
			mVertexBuffer[idx + 1] = y;

			needUploadVertexBuffer = true;
		}

		override public function dispose():void {
			super.dispose();

			texture = null;
			animation = null;
			colorTransform = null;
			programConstants = null;
		}

	}
}
