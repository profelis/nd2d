package
{
import de.nulldesign.nd2d.display.World2D;
import de.nulldesign.nd2d.utils.Statistics;

import flash.events.Event;

/**
 * @author Dima Granetchi <system.grand@gmail.com>, <deep@e-citrus.ru>
 */
public class TestGui extends World2D
{
    public function TestGui()
    {
        stage.align = "TL";
        stage.scaleMode = "noScale";

        setActiveScene(new TestScene());
        scene.backgroundColor = 0xFFFFFF;

        start();
    }

    override protected function addedToStage(event:Event):void
    {
        super.addedToStage(event);

        Statistics.enabled = true;
        Statistics.alignRight = true;
    }
}
}

import de.nulldesign.nd2d.display.Quad2D;
import de.nulldesign.nd2d.display.Scene2D;
import de.nulldesign.nd2d.display.Sprite2D;
import de.nulldesign.nd2d.geom.Geometry;
import de.nulldesign.nd2d.materials.texture.Texture2D;

import flash.display.BitmapData;

import flash.events.MouseEvent;
import flash.geom.Point;

class TestScene extends Scene2D
{
    [Embed(source="bt_gr_pressed.png")]
    private static var Tex:Class;

    private var s:Sprite2D;

    public function TestScene()
    {
        super();

        var q:Quad2D = new Quad2D(100, 100, Geometry.createGUIQuad());
        q.color = 0xFF000000;
        q.useFrustumCulling = true;
        q.y = 1000;
        sceneGUILayer.addChild(q);

        q = new Quad2D(100, 100, q.geometry.clone());
        q.color = 0xFF00FF00;
        q.y = 100;
        sceneGUILayer.addChild(q);

        q = new Quad2D(100, 100, q.geometry.clone());
        q.color = 0xFF0000FF;
        q.y = 200;
        sceneGUILayer.addChild(q);

        var bitmap:BitmapData = new Tex().bitmapData;

        sceneGUILayer.addChild(s = new Sprite2D(Texture2D.textureFromBitmapData(bitmap)));
        s.x = 100;
        s.y = 100;
        s.pivot = new Point(-bitmap.width*0.5, -bitmap.height*0.5);
        s.mouseEnabled = true;
        s.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        s.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

        s.useFrustumCulling = true;
        s.x = -100;

        sceneGUILayer.addChild(s = new Sprite2D(Texture2D.textureFromBitmapData(bitmap), Geometry.createGUIQuad()));
        s.x = 100;
        s.y = 200;
        s.mouseEnabled = true;
        s.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        s.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
    }

    private function onMouseOver(event:MouseEvent):void
    {
        (event.currentTarget as Sprite2D).tint = 0xFF0000;
    }

    private function onMouseOut(event:MouseEvent):void
    {
        (event.currentTarget as Sprite2D).tint = 0xFFFFFF;
    }
}