package de.nulldesign.nd2d.geom
{
import de.nulldesign.nd2d.utils.nd2d;

use namespace nd2d;
/**
 * @author Dima Granetchi <system.grand@gmail.com>, <deep@e-citrus.ru>
 */
public class GuiGeometry extends Geometry
{
    public function GuiGeometry()
    {
        super();
    }

    public static function createQuad(w:Number = 2, h:Number = 2):Geometry
    {
        var g:GuiGeometry = new GuiGeometry();
        g.faceList = generateQuadFromDimensions(w, h);
        g.needUpdateVertexBuffer = true;

        return g;
    }

    public static function generateQuadFromDimensions(width:Number, height:Number):Vector.<Face>
    {
        var faceList:Vector.<Face> = new Vector.<Face>(2, true);

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

        v1 = new Vertex(0, 0);
        v2 = new Vertex(width, 0);
        v3 = new Vertex(width, height);
        v4 = new Vertex(0, height);

        faceList[0] = new Face(v1, v2, v3, uv1, uv2, uv3);
        faceList[1] = new Face(v1, v3, v4, uv1, uv3, uv4);

        return faceList;
    }

    override public function hitTest(mx:Number, my:Number, w:Number, h:Number):Boolean
    {
        if(isNaN(w) || isNaN(h)) {
            return false;
        }

        return (mx >= 0 && mx <= w && my >= 0 && my <= h);
    }
}
}
