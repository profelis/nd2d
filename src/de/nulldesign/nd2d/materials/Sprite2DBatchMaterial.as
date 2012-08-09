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
    import de.nulldesign.nd2d.display.Node2D;
    import de.nulldesign.nd2d.display.Sprite2D;
    import de.nulldesign.nd2d.geom.Face;
    import de.nulldesign.nd2d.geom.Geometry;
    import de.nulldesign.nd2d.geom.UV;
    import de.nulldesign.nd2d.geom.Vertex;
    import de.nulldesign.nd2d.materials.shader.ShaderCache;
    import de.nulldesign.nd2d.utils.Statistics;
    import de.nulldesign.nd2d.utils.nd2d;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;

    use namespace nd2d;

    public class Sprite2DBatchMaterial extends Sprite2DMaterial {

		private const VERTEX_SHADER:String =
			"alias va0, position;" +
			"alias va1.xy, uv;" +

			"alias vc0, viewProjection;" +
			"alias vc[va2.x], clipSpace;" +
			"alias vc[va2.y], colorMultiplier;" +
			"alias vc[va2.z], colorOffset;" +
			"alias vc[va2.w], uvSheet;" +
			"alias vc[va3.x], uvScroll;" +

			"temp0 = mul4x4(position, clipSpace);" +
			"output = mul4x4(temp0, viewProjection);" +

			"temp0 = applyUV(uv, uvScroll, uvSheet);" +

			// pass to fragment shader
			"v0 = temp0;" +
			"v1 = colorMultiplier;" +
			"v2 = colorOffset;" +
			"v3 = uvSheet;";

		private const FRAGMENT_SHADER:String =
			"alias v0, texCoord;" +
			"alias v1, colorMultiplier;" +
			"alias v2, colorOffset;" +
			"alias v3, uvSheet;" +

			"temp0 = sampleUV(texCoord, texture0, uvSheet);" +

			"output = colorize(temp0, colorMultiplier, colorOffset);";

		private var idx:uint = 0;
		private const constantsGlobal:uint = 4;
		private const constantsPerMatrix:uint = 4;
		private const constantsPerSprite:uint = 4; // colorMultiplier, colorOffset, uvSheet, uvOffsetAndScale

		private var batchLen:uint = 0;
		private const BATCH_SIZE:uint = (126 - constantsGlobal) / (constantsPerMatrix + constantsPerSprite);

		private var programConstants:Vector.<Number> = new Vector.<Number>(4 * constantsPerSprite * BATCH_SIZE, true);

		nd2d var camera:Camera2D;

		public static const VERTEX_IDX:String = "PB3D_IDX";
		public static const VERTEX_IDX2:String = "PB3D_IDX2";

        nd2d var batchSize:uint = BATCH_SIZE;

		public function Sprite2DBatchMaterial() {
			super();
            numFloatsPerVertex = 9;
		}

		override public function render(context:Context3D, geometry:Geometry):void {
			throw new Error("please call renderBatch for this material");
		}

		override protected function prepareForRender(context:Context3D,
                                                     geometry:Geometry):void
        {
			updateProgram(context, geometry);

			context.setProgram(shaderData.shader);
			context.setTextureAt(0, texture.getTexture(context));
			context.setBlendFactors(blendMode.src, blendMode.dst);

			context.setVertexBufferAt(0, geometry.vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2); // vertex
			context.setVertexBufferAt(1, geometry.vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2); // uv
			context.setVertexBufferAt(2, geometry.vertexBuffer, 4, Context3DVertexBufferFormat.FLOAT_4); // idx
			context.setVertexBufferAt(3, geometry.vertexBuffer, 8, Context3DVertexBufferFormat.FLOAT_1); // idx2

			if(scrollRect) {
				context.setScissorRectangle(scrollRect);
			}

			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, viewProjectionMatrix, true);
		}

		public function renderBatch(context:Context3D, geometry:Geometry,
                                    childList:Node2D):void
        {
			if(!childList) {
				return;
			}

			batchLen = 0;

			usesUV = childList.usesUV;
			usesColor = usesColor || childList.usesColor;
			usesColorOffset = usesColorOffset || childList.usesColorOffset;

			prepareForRender(context, geometry);

			processAndRenderNodes(context, geometry, childList);

			drawCurrentBatch(context, geometry);

			clearAfterRender(context);
		}

		protected function drawCurrentBatch(context:Context3D,
                                            geometry:Geometry):void
        {
			if(batchLen) {
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX,
					constantsGlobal + BATCH_SIZE * constantsPerMatrix, programConstants, batchLen * constantsPerSprite);

				context.drawTriangles(geometry.indexBuffer, 0, batchLen << 1);

				Statistics.drawCalls++;
				Statistics.triangles += (batchLen << 1);
			}

			idx = 0;
			batchLen = 0;
		}

		protected function processAndRenderNodes(context:Context3D,
                                                 geometry:Geometry,
                                                 childList:Node2D):void
        {
			if(!childList) {
				return;
			}

			var child:Sprite2D;
			var childNode:Node2D;

			for(childNode = childList; childNode; childNode = childNode.next) {
				if(!childNode.visible) {
					continue;
				}

				if(childNode.invalidateUV) {
					childNode.updateUV();
				}

				if(childNode.invalidateColors) {
					childNode.updateColors();
				}

				if(childNode.invalidateMatrix || childNode.parent.invalidateMatrix) {
					if(childNode.invalidateMatrix) {
						childNode.updateLocalMatrix();
					}

					childNode.updateWorldMatrix();
					childNode.invalidateMatrix = true;
				} else if(childNode.invalidateClipSpace) {
					childNode.updateClipSpace();
				}

				if(childNode.useFrustumCulling && childNode.invalidateCullingCount != camera.invalidateCount) {
					childNode.updateCulling();
				}

				child = childNode as Sprite2D;

				if(child) {
					if(!child.culled) {
						usesUV = child.usesUV;
						usesColor = child.usesColor;
						usesColorOffset = child.usesColorOffset;

						updateProgram(context);

						context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,
							constantsGlobal + batchLen * constantsPerMatrix, child.clipSpaceMatrix, true);

						programConstants[idx++] = child.combinedColorTransform.redMultiplier;
						programConstants[idx++] = child.combinedColorTransform.greenMultiplier;
						programConstants[idx++] = child.combinedColorTransform.blueMultiplier;
						programConstants[idx++] = child.combinedColorTransform.alphaMultiplier;

						programConstants[idx++] = child.combinedColorTransform.redOffset;
						programConstants[idx++] = child.combinedColorTransform.greenOffset;
						programConstants[idx++] = child.combinedColorTransform.blueOffset;
						programConstants[idx++] = child.combinedColorTransform.alphaOffset;

						programConstants[idx++] = child.animation.frameUV.x;
						programConstants[idx++] = child.animation.frameUV.y;
						programConstants[idx++] = child.animation.frameUV.width;
						programConstants[idx++] = child.animation.frameUV.height;

						programConstants[idx++] = child.uvOffsetX;
						programConstants[idx++] = child.uvOffsetY;
						programConstants[idx++] = child.uvScaleX;
						programConstants[idx++] = child.uvScaleY;

						batchLen++;

						Statistics.sprites++;

						if(batchLen == BATCH_SIZE) {
							drawCurrentBatch(context);
						}
					} else {
						Statistics.spritesCulled++;
					}
				}

				processAndRenderNodes(context, geometry, childNode.childFirst);

				childNode.invalidateMatrix = false;
			}
		}

		override protected function clearAfterRender(context:Context3D):void {
			context.setTextureAt(0, null);
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(2, null);
			context.setVertexBufferAt(3, null);
			context.setScissorRectangle(null);
		}

		override protected function updateProgram(context:Context3D,
                                                  geometry:Geometry):void
        {
			if(shaderData == null || usesUV != lastUsesUV || usesColor != lastUsesColor || usesColorOffset != lastUsesColorOffset) {
				drawCurrentBatch(context, geometry);

				shaderData = null;
				initProgram(context);
				context.setProgram(shaderData.shader);

				lastUsesUV = usesUV;
				lastUsesColor = usesColor;
				lastUsesColorOffset = usesColorOffset;
			}
		}

		override protected function initProgram(context:Context3D):void {
			if(!shaderData) {
				var defines:Array = ["Sprite2DBatch",
					"USE_UV", usesUV,
					"USE_COLOR", usesColor,
					"USE_COLOR_OFFSET", usesColorOffset];

				shaderData = ShaderCache.getShader(context, defines, VERTEX_SHADER, FRAGMENT_SHADER, 9, texture);
			}
		}

		override public function addVertex(context:Context3D, buffer:Vector.<Number>,
                                           v:Vertex, uv:UV,
                                           face:Face):void
        {
			fillBuffer(buffer, v, uv, face, VERTEX_POSITION, 2);
			fillBuffer(buffer, v, uv, face, VERTEX_UV, 2);
			fillBuffer(buffer, v, uv, face, VERTEX_IDX, 4);
			fillBuffer(buffer, v, uv, face, VERTEX_IDX2, 1);
		}

		override protected function fillBuffer(buffer:Vector.<Number>, v:Vertex,
                                               uv:UV, face:Face,
                                               semanticsID:String, floatFormat:int):void
        {
			if(semanticsID == VERTEX_IDX) {
				// va2.x	clipSpace index
				buffer.push(constantsGlobal + face.idx * constantsPerMatrix);
				// va2.y	colorMultiplier index
				buffer.push(constantsGlobal + BATCH_SIZE * constantsPerMatrix + face.idx * constantsPerSprite);
				// va2.z	colorOffset index
				buffer.push(constantsGlobal + BATCH_SIZE * constantsPerMatrix + face.idx * constantsPerSprite + 1);
				// va2.w	uvSheet index
				buffer.push(constantsGlobal + BATCH_SIZE * constantsPerMatrix + face.idx * constantsPerSprite + 2);
			} else if(semanticsID == VERTEX_IDX2) {
				// va3.x	uvOffset index
				buffer.push(constantsGlobal + BATCH_SIZE * constantsPerMatrix + face.idx * constantsPerSprite + 3);
			} else {
				super.fillBuffer(buffer, v, uv, face, semanticsID, floatFormat);
			}
		}

		override public function dispose():void {
			super.dispose();

			camera = null;
			programConstants = null;
		}
	}
}
