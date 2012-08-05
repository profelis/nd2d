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
import de.nulldesign.nd2d.geom.GuiGeometry;
import de.nulldesign.nd2d.materials.texture.Texture2D;

import flash.events.MouseEvent;

class TestScene extends Scene2D
{
    [Embed(source="bt_gr_pressed.png")]
    private static var Tex:Class;

    private var s:Sprite2D;

    public function TestScene()
    {
        super();

        var q:Quad2D = new Quad2D(100, 100, GuiGeometry.createQuad(100, 100));
        q.color = 0xFF000000;
        sceneGUILayer.addChild(q);

        q = new Quad2D(100, 100, GuiGeometry.createQuad(100, 100));
        q.color = 0xFF00FF00;
        q.x = 100;
        sceneGUILayer.addChild(q);

        q = new Quad2D(100, 100, GuiGeometry.createQuad(100, 100));
        q.color = 0xFF0000FF;
        q.y = 100;
        sceneGUILayer.addChild(q);

        q = new Quad2D(100, 100, GuiGeometry.createQuad(100, 100));
        q.color = 0xFFFF00FF;
        q.x = 100;
        q.y = 100;
        sceneGUILayer.addChild(q);

        sceneGUILayer.addChild(s = new Sprite2D(Texture2D.textureFromBitmapData(new Tex().bitmapData)));
        s.x = 100;
        s.y = 100;

        sceneGUILayer.addChild(s = new Sprite2D(Texture2D.textureFromBitmapData(new Tex().bitmapData), GuiGeometry.createQuad()));
        s.x = 100;
        s.y = 200;
        s.mouseEnabled = true;
        s.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        s.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
    }

    private function onMouseOver(event:MouseEvent):void
    {
        s.tint = 0xFF0000;
    }

    private function onMouseOut(event:MouseEvent):void
    {
        s.tint = 0xFFFFFF;
    }
}