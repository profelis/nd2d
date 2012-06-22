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

package materials {

	import de.nulldesign.nd2d.materials.Sprite2DMaterial;
	import de.nulldesign.nd2d.materials.shader.ShaderCache;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.utils.getTimer;

	public class Sprite2DDizzyMaterial extends Sprite2DMaterial {

		private const DIZZY_VERTEX_SHADER:String =
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

		private const DIZZY_FRAGMENT_SHADER:String =
			"alias v0, texCoord;" +
			"alias v1, colorMultiplier;" +
			"alias v2, colorOffset;" +
			"alias v3.xy, uvSheetOffset;" +
			"alias v3.zw, uvSheetScale;" +

			"alias fc0, dizzy;" +

			"temp1 = texCoord * dizzy.y;" +
			"temp1 += dizzy.x;" +
			"temp1.y = cos(temp1.w);" +
			"temp1.x = sin(temp1.z);" +
			"temp1.xy *= dizzy.zw;" +
			"temp0 = texCoord + temp1;" +

			"#if USE_UV;" +
			"	temp0 = frac(temp0);" +
			"	temp0 *= uvSheetScale;" +
			"	temp0 += uvSheetOffset;" +
			"	temp0 = sampleNoMip(temp0, texture0);" +
			"#else;" +
			"	temp0 = sample(temp0, texture0);" +
			"#endif;" +

			"output = colorize(temp0, colorMultiplier, colorOffset);";

		public function Sprite2DDizzyMaterial() {
			super();
		}

		override protected function prepareForRender(context:Context3D):void {
			super.prepareForRender(context);

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([
				getTimer() * 0.002,
				8 * Math.PI,
				0.01,
				0.02]));
		}

		override protected function initProgram(context:Context3D):void {
			if(!shaderData) {
				var defines:String =
					"#define PREMULTIPLIED_ALPHA=" + int(texture.hasPremultipliedAlpha) + ";" +
					"#define USE_UV=" + int(usesUV) + ";" +
					"#define USE_COLOR=" + int(usesColor) + ";" +
					"#define USE_COLOR_OFFSET=" + int(usesColorOffset) + ";";

				shaderData = ShaderCache.getShader(context, defines, DIZZY_VERTEX_SHADER, DIZZY_FRAGMENT_SHADER, 4, texture.textureOptions);
			}
		}
	}
}
