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
    import de.nulldesign.nd2d.geom.ParticleVertex;
    import de.nulldesign.nd2d.geom.UV;
    import de.nulldesign.nd2d.geom.Vertex;
    import de.nulldesign.nd2d.materials.shader.ShaderCache;
    import de.nulldesign.nd2d.materials.texture.Texture2D;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.geom.Point;

    public class ParticleSystemMaterial extends MaterialBase {

		private const VERTEX_SHADER:String =
			"alias va0, position;" +
			"alias va1, uv;" +

			"alias va2.x, startTime;" +
			"alias va2.y, lifeTime;" +
			"alias va2.z, startSize;" +
			"alias va2.w, endSize;" +

			"alias va3.xy, velocity;" +
			"alias va3.zw, startPos;" +

			"alias va4, startColor;" +
			"alias va5, endColor;" +

			"alias vc0, viewProjection;" +
			"alias vc4, clipSpace;" +
			"alias vc8.xy, gravity;" +
			"alias vc8.z, currentTime;" +
			"alias vc8.w, CONST(1.0);" +

			// progress calculation
			// 		clamp( frac( (currentTime - startTime) / lifeTime ) )
			"temp0 = currentTime - startTime;" +
			"temp0 /= lifeTime;" +

			"#if !BURST;" +
			"	temp0 = frac(temp0);" +
			"#endif;" +

			"alias temp0, progress;" +

			"progress.x = clamp(progress.x);" +
			"progress.y = 1.0 - progress.x;" +

			// velocity / gravity calculation
			// 		(velocity + (gravity * progress)) * progress
			"temp2 = gravity * progress.x;" +
			"temp1 = velocity + temp2.xy;" +
			"temp1 *= progress.x;" +

			"alias temp1, currentVelocity;" +

			// size calculation
			// 		temp3 = (startSize * (1.0 - progress)) + (endSize * progress)
			"temp3 = startSize * progress.y;" +
			"temp2 = endSize * progress.x;" +
			"temp3 += temp2;" +

			"alias temp3, currentSize;" +

			// move
			// 		(position * currentSize) + startPos + currentVelocity
			"temp2 = position;" +
			"temp2.xy *= currentSize;" +
			"temp2.xy += startPos;" +
			"temp2.xy += currentVelocity;" +

			"temp2 = mul4x4(temp2, clipSpace);" +
			"output = mul4x4(temp2, viewProjection);" +

			// mix colors
			// 		(startColor * (1.0 - progress)) + (endColor * progress)
			"temp3 = startColor * progress.y;" +
			"temp4 = endColor * progress.x;" +
			"temp3 += temp4;" +

			"#if PREMULTIPLIED_ALPHA;" +
			"	temp3.rgb *= temp3.a;" +
			"#endif;" +

			// pass to fragment shader
			"v0 = uv;" +
			"v1 = temp3;";

		private const FRAGMENT_SHADER:String =
			"alias v0, texCoord;" +
			"alias v1, colorMultiplier;" +

			"temp0 = sample(texCoord, texture0);" +
			"output = temp0 * colorMultiplier;";

		public var gravity:Point;
		public var currentTime:Number;

		protected var burst:Boolean;
		protected var texture:Texture2D;
		protected var programConstants:Vector.<Number> = new Vector.<Number>(4, true);

		public function ParticleSystemMaterial(texture:Texture2D, burst:Boolean) {
            super();

			this.burst = burst;
			this.texture = texture;

            numFloatsPerVertex = 20;
		}

		override protected function prepareForRender(context:Context3D,
                                                     geometry:Geometry):void
        {
			super.prepareForRender(context, geometry);

			context.setTextureAt(0, texture.getTexture(context));
			context.setVertexBufferAt(0, geometry.vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2); // vertex
			context.setVertexBufferAt(1, geometry.vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2); // uv
			context.setVertexBufferAt(2, geometry.vertexBuffer, 4, Context3DVertexBufferFormat.FLOAT_4); // misc (starttime, life, startsize, endsize
			context.setVertexBufferAt(3, geometry.vertexBuffer, 8, Context3DVertexBufferFormat.FLOAT_4); // velocity / startpos
			context.setVertexBufferAt(4, geometry.vertexBuffer, 12, Context3DVertexBufferFormat.FLOAT_4); // startcolor
			context.setVertexBufferAt(5, geometry.vertexBuffer, 16, Context3DVertexBufferFormat.FLOAT_4); // endcolor

			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, viewProjectionMatrix, true);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, clipSpaceMatrix, true);

			programConstants[0] = gravity.x;
			programConstants[1] = gravity.y;
			programConstants[2] = currentTime;
			programConstants[3] = 1.0;

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 8, programConstants);
		}

		override protected function clearAfterRender(context:Context3D):void {
			context.setTextureAt(0, null);
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(2, null);
			context.setVertexBufferAt(3, null);
			context.setVertexBufferAt(4, null);
			context.setVertexBufferAt(5, null);
			context.setScissorRectangle(null);
		}

		override public function addVertex(context:Context3D, buffer:Vector.<Number>,
                                           v:Vertex, uv:UV,
                                           face:Face):void
        {
			fillBuffer(buffer, v, uv, face, VERTEX_POSITION, 2);
			fillBuffer(buffer, v, uv, face, VERTEX_UV, 2);
			fillBuffer(buffer, v, uv, face, "PB3D_MISC", 4);
			fillBuffer(buffer, v, uv, face, "PB3D_VELOCITY", 4);
			fillBuffer(buffer, v, uv, face, "PB3D_STARTCOLOR", 4);
			fillBuffer(buffer, v, uv, face, "PB3D_ENDCOLOR", 4);
		}

		override public function fillBuffer(buffer:Vector.<Number>, v:Vertex,
                                            uv:UV, face:Face,
                                            semanticsID:String, floatFormat:int):void
        {
			super.fillBuffer(buffer, v, uv, face, semanticsID, floatFormat);

			var pv:ParticleVertex = ParticleVertex(v);

			if(semanticsID == "PB3D_VELOCITY") {
				buffer.push(pv.vx, pv.vy, pv.startX, pv.startY);
			}

			if(semanticsID == "PB3D_MISC") {
				buffer.push(pv.startTime, pv.life, pv.startSize, pv.endSize);
			}

			if(semanticsID == "PB3D_ENDCOLOR") {
				buffer.push(pv.endColorR, pv.endColorG, pv.endColorB, pv.endAlpha);
			}

			if(semanticsID == "PB3D_STARTCOLOR") {
				buffer.push(pv.startColorR, pv.startColorG, pv.startColorB, pv.startAlpha);
			}
		}

		override protected function initProgram(context:Context3D):void {
			if(!shaderData) {
				var defines:Array = ["ParticleSystem2D",
					"BURST", burst];

				shaderData = ShaderCache.getShader(context, defines, VERTEX_SHADER, FRAGMENT_SHADER, 20, texture);
			}
		}

		override public function handleDeviceLoss():void {
			super.handleDeviceLoss();

			shaderData = null;
			texture.texture = null;
		}

		override public function dispose():void {
			super.dispose();

			if(texture) {
				texture.dispose();
				texture = null;
			}

			programConstants = null;
		}
	}
}
