package de.nulldesign.nd2d.geom
{
import de.nulldesign.nd2d.materials.MaterialBase;
import de.nulldesign.nd2d.utils.TextureHelper;

import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.utils.Dictionary;

/**
 * @author Dima Granetchi <system.grand@gmail.com>, <deep@e-citrus.ru>
 */
public class Geometry
{
    public var faceList:Vector.<Face>;

    public var needUploadVertexBuffer:Boolean = false;

    public var indexBuffer:IndexBuffer3D;
    public var vertexBuffer:VertexBuffer3D;

    protected var mIndexBuffer:Vector.<uint>;
    protected var mVertexBuffer:Vector.<Number>;

    public var needUpdateVertexBuffer:Boolean = false;

    public var startTri:uint = 0;
    public var numTris:uint;

    public var material:MaterialBase;

    public var numFloatsPerVertex:uint;

    public function Geometry()
    {
    }

    public static function createQuad(w:Number = 2, h:Number = 2):Geometry
    {
        var g:Geometry = new Geometry();
        g.faceList = TextureHelper.generateQuadFromDimensions(w, h);
        g.needUpdateVertexBuffer = true;

        return g;
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
    }

    public function update(context:Context3D):void
    {
        if (needUpdateVertexBuffer)
        {
            generateBufferData(context);
            needUpdateVertexBuffer = false;
        }
        else if(needUploadVertexBuffer)
        {
            needUploadVertexBuffer = false;
            vertexBuffer.uploadFromVector(mVertexBuffer, 0, mVertexBuffer.length / numFloatsPerVertex);
        }
    }

    public function setMaterial(value:MaterialBase):void
    {
        material = value;

        if (value)
        {
            numFloatsPerVertex = material.numFloatsPerVertex;
            needUpdateVertexBuffer = true;
        }
    }

    public function generateBatch(size:uint):void
    {
        if (faceList.length == size * 2) return;

        var f0:Face = faceList[0];
        var f1:Face = faceList[1];
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
        faceList = newFaceList;

        needUpdateVertexBuffer = true;
    }
}
}
