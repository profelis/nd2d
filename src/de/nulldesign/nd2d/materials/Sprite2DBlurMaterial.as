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

	import de.nulldesign.nd2d.display.Camera2D;
	import de.nulldesign.nd2d.geom.Face;
	import de.nulldesign.nd2d.materials.shader.Shader2D;
	import de.nulldesign.nd2d.materials.shader.ShaderCache;
	import de.nulldesign.nd2d.materials.texture.TextureSheetBase;
	import de.nulldesign.nd2d.materials.texture.Texture2D;
	import de.nulldesign.nd2d.utils.Statistics;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;

	/**
	 * http://www.gamerendering.com/2008/10/11/gaussian-blur-filter-shader/
	 */
	public class Sprite2DBlurMaterial extends Sprite2DMaterial {

		private const VERTEX_SHADER:String =
			"alias va0, position;" +
			"alias va1.xy, uv;" +
			"alias vc0, viewProjection;" +
			"alias vc4, clipSpace;" +
			"alias vc8, colorMultiplier;" +
			"alias vc9, colorOffset;" +
			"alias vc10, uvSheet;" +
			"alias vc11, uvScroll;" +

			"temp0 = mul4x4(position, clipSpace);" +
			"output = mul4x4(temp0, viewProjection);" +

			"temp0 = applyUV(uv, uvScroll, uvSheet);" +

			// pass to fragment shader
			"v0 = temp0;" +
			"v1 = colorMultiplier;" +
			"v2 = colorOffset;" +
			"v3 = uvSheet;";

		private const HORIZONTAL_FRAGMENT_SHADER:String =
			"alias v0, texCoord;" +
			"alias v1, colorMultiplier;" +
			"alias v2, colorOffset;" +
			"alias v3.xy, uvSheet;" +

			"#if USE_UV;" +
			"	#if REPEAT_CLAMP;" +
			"		temp0 = clamp(texCoord);" +
			"	#else;" +
			"		temp0 = frac(texCoord);" +
			"	#endif;" +

			"	temp0 *= uvSheet.zw;" +
			"	temp0 += uvSheet.xy;" +
			"#else;" +
			"	temp0 = texCoord;" +
			"#endif;" +

			// -4
			"temp0.x -= fc3.y;" +
			"temp1 = sampleNoMip(temp0, texture0);" +
			"temp1 *= fc2.x;" +

			// -3
			"temp0.x += fc3.z;" +
			"temp2 = sampleNoMip(temp0, texture0);" +
			"temp2 *= fc2.y;" +
			"temp1 += temp2;" +

			// -2
			"temp0.x += fc3.z;" +
			"temp2 = sampleNoMip(temp0, texture0);" +
			"temp2 *= fc2.z;" +
			"temp1 += temp2;" +

			// -1
			"temp0.x += fc3.z;" +
			"temp2 = sampleNoMip(temp0, texture0);" +
			"temp2 *= fc2.w;" +
			"temp1 += temp2;" +

			// 0
			"temp0.x += fc3.z;" +
			"temp2 = sampleNoMip(temp0, texture0);" +
			"temp2 *= fc3.x;" +
			"temp1 += temp2;" +

			// 1
			"temp0.x += fc3.z;" +
			"temp2 = sampleNoMip(temp0, texture0);" +
			"temp2 *= fc2.w;" +
			"temp1 += temp2;" +

			// 2
			"temp0.x += fc3.z;" +
			"temp2 = sampleNoMip(temp0, texture0);" +
			"temp2 *= fc2.z;" +
			"temp1 += temp2;" +

			// 3
			"temp0.x += fc3.z;" +
			"temp2 = sampleNoMip(temp0, texture0);" +
			"temp2 *= fc2.y;" +
			"temp1 += temp2;" +

			// 4
			"temp0.x += fc3.z;" +
			"temp2 = sampleNoMip(temp0, texture0);" +
			"temp2 *= fc2.x;" +
			"temp1 += temp2;" +

			"output = colorize(temp1, colorMultiplier, colorOffset);";

		private var VERTICAL_FRAGMENT_SHADER:String;

		protected var horizontalShader:Shader2D;
		protected var verticalShader:Shader2D;

		protected const MAX_BLUR:uint = 4;

		protected var blurredTexture:Texture2D;
		protected var blurredTexture2:Texture2D;
		protected var activeRenderToTexture:Texture;

		protected var blurredMatrix:Matrix3D = new Matrix3D();
		protected var blurredTextureCam:Camera2D = new Camera2D(1, 1);

		protected var blurX:uint;
		protected var blurY:uint;

		protected const BLUR_DIRECTION_HORIZONTAL:uint = 0;
		protected const BLUR_DIRECTION_VERTICAL:uint = 1;

		protected var programConstants:Vector.<Number> = new Vector.<Number>(8, true);

		public function Sprite2DBlurMaterial(blurX:uint = 4, blurY:uint = 4) {
			super();

			VERTICAL_FRAGMENT_SHADER = HORIZONTAL_FRAGMENT_SHADER.replace("temp0.x -= fc3.y", "temp0.y -= fc3.y");
			VERTICAL_FRAGMENT_SHADER = VERTICAL_FRAGMENT_SHADER.replace(/temp0.x \+= fc3.z/g, "temp0.y += fc3.z");

			setBlur(blurX, blurY);
		}

		public function setBlur(blurX:uint = 4, blurY:uint = 4):void {
			this.blurX = blurX;
			this.blurY = blurY;
		}

		protected function updateBlurKernel(radius:uint, direction:uint):void {
			programConstants[0] = 0.0; //0.05; // fc2.x
			programConstants[1] = 0.0; //0.09; // fc2.y
			programConstants[2] = 0.0; //0.12; // fc2.z
			programConstants[3] = 0.0; //0.15; // fc2.w
			programConstants[4] = 1.0; //0.16; // fc3.x
			// movement: minus 4 and plus 1 several times...
			programConstants[5] = 4.0 * (1.0 / (direction == BLUR_DIRECTION_HORIZONTAL ? texture.textureWidth : texture.textureHeight)); // fc3.y
			programConstants[6] = 1.0 * (1.0 / (direction == BLUR_DIRECTION_HORIZONTAL ? texture.textureWidth : texture.textureHeight)); // fc3.z
			programConstants[7] = 0.0;  // fc3.w

			// http://stackoverflow.com/questions/1696113/how-do-i-gaussian-blur-an-image-without-using-any-in-built-gaussian-functions
			if(radius == 0) {
				return;
			}

			var kernelLen:uint = radius * 2 + 1;
			var r:Number = -radius;
			var kernel:Array = [];
			var twoRadiusSquaredRecip:Number = 1.0 / (2.0 * radius * radius);
			var sqrtTwoPiTimesRadiusRecip:Number = 1.0 / (Math.sqrt(2.0 * Math.PI) * radius);
			var kernelSum:Number = 0.0;
			var i:int = 0;

			for(i = 0; i < kernelLen; i++) {
				var x:Number = r * r;

				kernel[i] = sqrtTwoPiTimesRadiusRecip * Math.exp(-x * twoRadiusSquaredRecip);
				kernelSum += kernel[i];
				r++;
			}

			for(i = 0; i < kernelLen; i++) {
				kernel[i] /= kernelSum;
			}

			var idx:uint = 4;

			for(i = kernelLen / 2; i >= 0; i--) {
				programConstants[idx--] = kernel[i];
			}
		}

		override protected function prepareForRender(context:Context3D):void {
			super.prepareForRender(context);

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, programConstants, 2);

			if(!blurredTexture) {
				blurredTexture = Texture2D.textureFromSize(texture.textureWidth, texture.textureHeight);
			}

			if(!blurredTexture2) {
				blurredTexture2 = Texture2D.textureFromSize(texture.textureWidth, texture.textureHeight);
			}
		}

		protected function renderBlur(context:Context3D, startTri:uint, numTris:uint):void {
			activeRenderToTexture = (activeRenderToTexture == blurredTexture.getTexture(context) ? blurredTexture2.getTexture(context) : blurredTexture.getTexture(context));
			context.setRenderToTexture(activeRenderToTexture, false, 2, 0);
			context.clear(0.0, 0.0, 0.0, 0.0);

			context.drawTriangles(indexBuffer, startTri * 3, numTris);

			Statistics.drawCalls++;
			Statistics.triangles += numTris - startTri;

			context.setTextureAt(0, activeRenderToTexture);
		}

		override public function render(context:Context3D, faceList:Vector.<Face>, startTri:uint, numTris:uint):void {
			generateBufferData(context, faceList);

			// set up camera for blurry texture
			blurredTextureCam.resizeCameraStage(texture.textureWidth, texture.textureHeight);
			blurredTextureCam.x = -texture.bitmapWidth * 0.5;
			blurredTextureCam.y = -texture.bitmapHeight * 0.5;

			blurredMatrix.identity();
			blurredMatrix.appendScale(texture.bitmapWidth >> 1, texture.bitmapHeight >> 1, 1.0);

			// save camera matrix
			var savedCamMatrix:Matrix3D = viewProjectionMatrix;
			var savedSpriteSheet:TextureSheetBase = texture.sheet;
			var savedClipSpaceMatrix:Matrix3D = clipSpaceMatrix;
			var savedUvOffsetX:Number = uvOffsetX;
			var savedUvOffsetY:Number = uvOffsetY;
			var savedUvScaleX:Number = uvScaleX;
			var savedUvScaleY:Number = uvScaleY;
			viewProjectionMatrix = blurredTextureCam.getViewProjectionMatrix();
			texture.sheet = null;
			clipSpaceMatrix = blurredMatrix;
			uvOffsetX = 0.0;
			uvOffsetY = 0.0;
			uvScaleX = 1.0;
			uvScaleY = 1.0;

			updateBlurKernel(MAX_BLUR, BLUR_DIRECTION_HORIZONTAL);
			prepareForRender(context);

			activeRenderToTexture = null;
			var totalSteps:int;
			var i:uint;

			// BLUR X
			totalSteps = Math.floor(blurX / MAX_BLUR);

			for(i = 0; i < totalSteps; i++) {
				renderBlur(context, startTri, numTris);
			}

			if(blurX % MAX_BLUR != 0) {
				updateBlurKernel(blurX % MAX_BLUR, BLUR_DIRECTION_HORIZONTAL);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, programConstants, 2);

				renderBlur(context, startTri, numTris);
			}

			// BLUR Y
			context.setProgram(verticalShader.shader);
			updateBlurKernel(MAX_BLUR, BLUR_DIRECTION_VERTICAL);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, programConstants, 2);

			totalSteps = Math.floor(blurY / MAX_BLUR);

			for(i = 0; i < totalSteps; i++) {
				renderBlur(context, startTri, numTris);
			}

			if(blurY % MAX_BLUR != 0) {
				updateBlurKernel(blurY % MAX_BLUR, BLUR_DIRECTION_VERTICAL);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, programConstants, 2);

				renderBlur(context, startTri, numTris);
			}

			context.setRenderToBackBuffer();

			// FINAL PASS
			viewProjectionMatrix = savedCamMatrix;
			texture.sheet = savedSpriteSheet;
			clipSpaceMatrix = savedClipSpaceMatrix;
			uvOffsetX = savedUvOffsetX;
			uvOffsetY = savedUvOffsetY;
			uvScaleX = savedUvScaleX;
			uvScaleY = savedUvScaleY;

			updateBlurKernel(0, BLUR_DIRECTION_HORIZONTAL);
			prepareForRender(context);

			if(!blurX && !blurY) {
				activeRenderToTexture = texture.getTexture(context);
			}

			context.setTextureAt(0, activeRenderToTexture);

			context.drawTriangles(indexBuffer, startTri * 3, numTris);

			Statistics.drawCalls++;
			Statistics.triangles += numTris - startTri;

			clearAfterRender(context);
		}

		override protected function initProgram(context:Context3D):void {
			if(!shaderData) {
				var defines:Array = ["Sprite2DBlur",
					"USE_UV", usesUV,
					"USE_COLOR", usesColor,
					"USE_COLOR_OFFSET", usesColorOffset];

				defines[0] = "Sprite2DBlurX";
				horizontalShader = ShaderCache.getShader(context, defines, VERTEX_SHADER, HORIZONTAL_FRAGMENT_SHADER, 4, texture);

				defines[0] = "Sprite2DBlurY";
				verticalShader = ShaderCache.getShader(context, defines, VERTEX_SHADER, VERTICAL_FRAGMENT_SHADER, 4, texture);

				shaderData = horizontalShader;
			}
		}

		override public function handleDeviceLoss():void {
			super.handleDeviceLoss();

			blurredTexture.texture = null;
			blurredTexture2.texture = null;
		}

		override public function dispose():void {
			super.dispose();

			if(blurredTexture) {
				blurredTexture.dispose();
				blurredTexture = null;
			}

			if(blurredTexture2) {
				blurredTexture2.dispose();
				blurredTexture2 = null;
			}

			blurredMatrix = null;
			programConstants = null;
			blurredTextureCam = null;
		}
	}
}
