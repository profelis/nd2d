package de.nulldesign.nd2d.geom
{
import de.nulldesign.nd2d.materials.MaterialBase;
import de.nulldesign.nd2d.utils.nd2d;

import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.utils.Dictionary;

use namespace nd2d;

/**
 * @author Dima Granetchi <system.grand@gmail.com>, <deep@e-citrus.ru>
 */
public class Geometry
{
    nd2d var faceList:Vector.<Face>;

    protected var needUploadVertexBuffer:Boolean = false;

    nd2d var indexBuffer:IndexBuffer3D;
    nd2d var vertexBuffer:VertexBuffer3D;

    protected var mIndexBuffer:Vector.<uint>;
    protected var mVertexBuffer:Vector.<Number>;

    nd2d var needUpdateVertexBuffer:Boolean = false;

    nd2d var startTri:uint = 0;
    nd2d var numTris:uint;

    protected var material:MaterialBase;

    protected var numFloatsPerVertex:uint;

    public function Geometry()
    {
    }

    public function resize(w:Number, h:Number):void
    {
        faceList = generateQuadFromDimensions(w, h);
        needUpdateVertexBuffer = true;
    }

    public static function createQuad(w:Number = 2, h:Number = 2):Geometry
    {
        var g:Geometry = new Geometry();
        g.faceList = generateQuadFromDimensions(w, h);
        g.needUpdateVertexBuffer = true;

        return g;
    }

    nd2d var mouseDX:int = 0;
    nd2d var mouseDY:int = 0;

    public function hitTest(mx:Number, my:Number, w:Number, h:Number):Boolean
    {
        if(isNaN(w) || isNaN(h)) {
            return false;
        }

        mouseDX = w >> 1;
        mouseDY = h >> 1;

        return (mx >= -mouseDX && mx <= mouseDX && my >= -mouseDY && my <= mouseDY);
    }

    public function handleDeviceLoss():void {
        indexBuffer = null;
        vertexBuffer = null;
        mIndexBuffer = null;
        mVertexBuffer = null;

        needUpdateVertexBuffer = true;
    }

    public function dispose():void
    {
        if(indexBuffer) {
            indexBuffer.dispose();
            indexBuffer = null;
        }

        if(vertexBuffer) {
            vertexBuffer.dispose();
            vertexBuffer = null;
        }

        material = null;

        mIndexBuffer = null;
        mVertexBuffer = null;

        faceList = null;
        needUploadVertexBuffer = false;
    }

    public function modifyVertexInBuffer(bufferIdx:uint, x:Number, y:Number):void {
        if(!mVertexBuffer || mVertexBuffer.length == 0) {
            return;
        }

        const idx:uint = bufferIdx * numFloatsPerVertex;

        mVertexBuffer[idx] = x;
        mVertexBuffer[idx + 1] = y;

        needUploadVertexBuffer = true;
    }

    public function modifyColorInBuffer(bufferIdx:uint, r:Number, g:Number, b:Number, a:Number):void {
        if(!mVertexBuffer || mVertexBuffer.length == 0) {
            return;
        }

        const idx:uint = bufferIdx * numFloatsPerVertex;

        mVertexBuffer[idx + 2] = r;
        mVertexBuffer[idx + 3] = g;
        mVertexBuffer[idx + 4] = b;
        mVertexBuffer[idx + 5] = a;

        needUploadVertexBuffer = true;
    }

    protected function generateBufferData(context:Context3D):void {

        numTris = faceList.length;

        var i:int;
        const numFaces:int = faceList.length;
        var numIndices:int;

        mIndexBuffer = new Vector.<uint>();
        mVertexBuffer = new Vector.<Number>();

        var duplicateCheck:Dictionary = new Dictionary();
        var tmpUID:String;
        var indexBufferIdx:uint = 0;
        var face:Face;

        // generate index + vertexbuffer
        // integrated check if the vertex / uv combination is already in the buffer and skip these vertices
        for(i = 0; i < numFaces; i++) {
            face = faceList[i];

            tmpUID = face.v1.uid + "." + face.uv1.uid;

            if(duplicateCheck[tmpUID] == undefined) {
                material.addVertex(context, mVertexBuffer, face.v1, face.uv1, face);
                duplicateCheck[tmpUID] = indexBufferIdx;
                mIndexBuffer.push(indexBufferIdx);
                face.v1.bufferIdx = indexBufferIdx;
                ++indexBufferIdx;
            } else {
                mIndexBuffer.push(duplicateCheck[tmpUID]);
            }

            tmpUID = face.v2.uid + "." + face.uv2.uid;

            if(duplicateCheck[tmpUID] == undefined) {
                material.addVertex(context, mVertexBuffer, face.v2, face.uv2, face);
                duplicateCheck[tmpUID] = indexBufferIdx;
                mIndexBuffer.push(indexBufferIdx);
                face.v2.bufferIdx = indexBufferIdx;
                ++indexBufferIdx;
            } else {
                mIndexBuffer.push(duplicateCheck[tmpUID]);
            }

            tmpUID = face.v3.uid + "." + face.uv3.uid;

            if(duplicateCheck[tmpUID] == undefined) {
                material.addVertex(context, mVertexBuffer, face.v3, face.uv3, face);
                duplicateCheck[tmpUID] = indexBufferIdx;
                mIndexBuffer.push(indexBufferIdx);
                face.v3.bufferIdx = indexBufferIdx;
                ++indexBufferIdx;
            } else {
                mIndexBuffer.push(duplicateCheck[tmpUID]);
            }
        }

        duplicateCheck = null;
        numIndices = mVertexBuffer.length / numFloatsPerVertex;

        // GENERATE BUFFERS
        if (vertexBuffer) vertexBuffer.dispose();

        vertexBuffer = context.createVertexBuffer(numIndices, numFloatsPerVertex);
        vertexBuffer.uploadFromVector(mVertexBuffer, 0, numIndices);

        if (indexBuffer) indexBuffer.dispose();

        const mIndexBuffer_length:int = mIndexBuffer.length;

        indexBuffer = context.createIndexBuffer(mIndexBuffer_length);
        indexBuffer.uploadFromVector(mIndexBuffer, 0, mIndexBuffer_length);

        needUpdateVertexBuffer = false;
        needUploadVertexBuffer = false;
    }

    nd2d function update(context:Context3D):void
    {
        if (needUpdateVertexBuffer)
        {
            generateBufferData(context);
        }
        if(needUploadVertexBuffer)
        {
            needUploadVertexBuffer = false;
            vertexBuffer.uploadFromVector(mVertexBuffer, 0, mVertexBuffer.length / numFloatsPerVertex);
        }
    }

    nd2d function setMaterial(value:MaterialBase):void
    {
        material = value;

        if (value)
        {
            numFloatsPerVertex = material.numFloatsPerVertex;
            needUpdateVertexBuffer = true;
        }
    }

    public static function createBatch(size:uint):Geometry
    {
        var g:Geometry = createQuad();

        var f0:Face = g.faceList[0];
        var f1:Face = g.faceList[1];
        var newF0:Face;
        var newF1:Face;

        var newFaceList:Vector.<Face> = new Vector.<Face>(size * 2, true);

        for(var i:int = 0; i < size; i++) {
            newF0 = f0.clone();
            newF1 = f1.clone();

            newF0.idx = i;
            newF1.idx = i;

            newFaceList[i * 2] = newF0;
            newFaceList[i * 2 + 1] = newF1;
        }
        g.faceList = newFaceList;

        g.needUpdateVertexBuffer = true;

        return g;
    }

    public static function generateQuadFromDimensions(width:Number, height:Number):Vector.<Face>
    {
        var faceList:Vector.<Face> = new Vector.<Face>(2, true);

        var texW:Number = width * 0.5;
        var texH:Number = height * 0.5;
        var uv1:UV;
        var uv2:UV;
        var uv3:UV;
        var uv4:UV;
        var v1:Vertex;
        var v2:Vertex;
        var v3:Vertex;
        var v4:Vertex;

        uv1 = new UV(0, 0);
        uv2 = new UV(1, 0);
        uv3 = new UV(1, 1);
        uv4 = new UV(0, 1);

        v1 = new Vertex(-texW, -texH, 0.0);
        v2 = new Vertex(texW, -texH, 0.0);
        v3 = new Vertex(texW, texH, 0.0);
        v4 = new Vertex(-texW, texH, 0.0);

        faceList[0] = new Face(v1, v2, v3, uv1, uv2, uv3);
        faceList[1] = new Face(v1, v3, v4, uv1, uv3, uv4);

        return faceList;
    }
}
}
