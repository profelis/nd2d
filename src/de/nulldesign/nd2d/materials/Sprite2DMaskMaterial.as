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
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;

	public class Sprite2DMaskMaterial extends Sprite2DMaterial {

		private const VERTEX_SHADER:String =
			"alias va0, position;" +
			"alias va1.xy, uv;" +
			"alias vc0, clipSpace;" +
			"alias vc4, maskClipSpace;" +
			"alias vc8.xy, maskSizeHalf;" +
			"alias vc8.zw, maskSize;" +
			"alias vc9.xy, uvOffset;" +
			"alias vc9.zw, uvScale;" +

			"temp0 = mul4x4(position, clipSpace);" +
			"output = temp0;" +

			"temp1 = mul4x4(temp0, maskClipSpace);" +
			"temp1 += maskSizeHalf;" +
			"temp1 /= maskSize;" +

			"temp2 = uv * uvScale;" +
			"temp2 += uvOffset;" +

			// pass to fragment shader
			"v0 = temp2;" +
			"v1 = temp1;";

		private const FRAGMENT_SHADER:String =
			"alias v0, texCoord;" +
			"alias v1, maskCoord;" +
			"alias fc0, colorMultiplier;" +
			"alias fc1, colorOffset;" +
			"alias fc2, CONST(1.0, 1.0, 1.0, 1.0);" +
			"alias fc3, maskAlpha;" +

			// texture
			"temp0 = sample(texCoord, texture0);" +
			"temp0 = colorize(temp0, colorMultiplier, colorOffset);" +

			// mask
			// 		maskColor + (1.0 - maskColor) * (1.0 - maskAlpha)
			"tex temp1, maskCoord, texture1 <2d,miplinear,linear,clamp>;" +
			"temp2 = 1.0 - temp1;" +
			"temp3 = maskAlpha;" +
			"temp3 = 1.0 - temp3;" +
			"temp3 = temp2 * temp3;" +
			"temp3 = temp1 + temp3;" +

			// texture * mask
			"output = temp0 * temp3;";

		public var maskAlpha:Number;
		public var maskTexture:Texture2D;
		public var maskModelMatrix:Matrix3D;

		protected var maskClipSpaceMatrix:Matrix3D = new Matrix3D();

		private var programConstants:Vector.<Number> = new Vector.<Number>(4, true);

		public function Sprite2DMaskMaterial() {
			super();
		}

		override public function handleDeviceLoss():void {
			super.handleDeviceLoss();

			shaderData = null;
			maskTexture.texture = null;
		}

		override protected function prepareForRender(context:Context3D):void {
			super.prepareForRender(context);

			context.setTextureAt(0, texture.getTexture(context));
			context.setTextureAt(1, maskTexture.getTexture(context));
			context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2); // vertex
			context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2); // uv

			var uvSheet:Rectangle;

			if(texture.sheet) {
				uvSheet = animation.frameUV;

				clipSpaceMatrix.identity();
				clipSpaceMatrix.appendScale(animation.frameRect.width >> 1, animation.frameRect.height >> 1, 1.0);
				clipSpaceMatrix.appendTranslation(animation.frameOffset.x, animation.frameOffset.y, 0.0);
				clipSpaceMatrix.append(modelMatrix);
				clipSpaceMatrix.append(viewProjectionMatrix);
			} else {
				uvSheet = texture.uvRect;

				clipSpaceMatrix.identity();
				clipSpaceMatrix.appendScale(texture.textureWidth >> 1, texture.textureHeight >> 1, 1.0);
				clipSpaceMatrix.append(modelMatrix);
				clipSpaceMatrix.append(viewProjectionMatrix);
			}

			maskClipSpaceMatrix.identity();
			maskClipSpaceMatrix.append(maskModelMatrix);
			maskClipSpaceMatrix.append(viewProjectionMatrix);
			maskClipSpaceMatrix.invert();

			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, clipSpaceMatrix, true);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, maskClipSpaceMatrix, true);

			programConstants[0] = maskTexture.textureWidth >> 1;
			programConstants[1] = maskTexture.textureHeight >> 1;
			programConstants[2] = maskTexture.textureWidth;
			programConstants[3] = maskTexture.textureHeight;

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 8, programConstants);

			programConstants[0] = uvSheet.x;
			programConstants[1] = uvSheet.y;
			programConstants[2] = uvSheet.width;
			programConstants[3] = uvSheet.height;

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 9, programConstants);

			programConstants[0] = colorTransform.redMultiplier;
			programConstants[1] = colorTransform.greenMultiplier;
			programConstants[2] = colorTransform.blueMultiplier;
			programConstants[3] = colorTransform.alphaMultiplier;

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, programConstants);

			programConstants[0] = colorTransform.redOffset;
			programConstants[1] = colorTransform.greenOffset;
			programConstants[2] = colorTransform.blueOffset;
			programConstants[3] = colorTransform.alphaOffset;

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, programConstants);

			programConstants[0] = 1.0;
			programConstants[1] = 1.0;
			programConstants[2] = 1.0;
			programConstants[3] = 1.0;

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, programConstants);

			programConstants[0] = maskAlpha;
			programConstants[1] = maskAlpha;
			programConstants[2] = maskAlpha;
			programConstants[3] = maskAlpha;

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, programConstants);
		}

		override protected function clearAfterRender(context:Context3D):void {
			context.setTextureAt(0, null);
			context.setTextureAt(1, null);
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(2, null);
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

		override public function dispose():void {
			super.dispose();

			if(maskTexture) {
				maskTexture.dispose();
				maskTexture = null;
			}

			maskModelMatrix = null;
			programConstants = null;
			maskClipSpaceMatrix = null;
		}
	}
}
