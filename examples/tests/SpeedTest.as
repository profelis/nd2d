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

package tests {

	import com.bit101.components.ComboBox;
	import com.bit101.components.Style;

	import de.nulldesign.nd2d.display.Node2D;
	import de.nulldesign.nd2d.display.Scene2D;
	import de.nulldesign.nd2d.display.Sprite2D;
	import de.nulldesign.nd2d.display.Sprite2DBatch;
	import de.nulldesign.nd2d.display.Sprite2DCloud;
	import de.nulldesign.nd2d.materials.texture.Texture2D;
	import de.nulldesign.nd2d.materials.texture.TextureSheet;
	import de.nulldesign.nd2d.utils.NumberUtil;

	import flash.events.Event;
	import flash.geom.ColorTransform;

	public class SpeedTest extends Scene2D {

		private var comboBox:ComboBox;

		[Embed(source="/assets/spritechar2.png")]
		private var spriteTexture:Class;

		private var spriteCloud:Sprite2DCloud;
		private var spriteBatch:Sprite2DBatch;

		private var tex:Texture2D;
		private var sheet:TextureSheet;

		private var selectedTestIdx:int = -1;
		private var maxCloudSize:uint = 16383;

		private var spritesPerFrame:uint = 128;

		public function SpeedTest() {
			mouseEnabled = false;
			backgroundColor = 0x666666;

			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}

		private function addedToStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, addedToStage);

			Style.LABEL_TEXT = 0x000000;

			comboBox = new ComboBox(stage, 0, 130, "- Select -", [
				"Sprite2D (static)",
				"   Sprite2D (animated)",
				"   Sprite2D (moving)",
				"Sprite2DCloud (static)",
				"   Sprite2DCloud (animated)",
				"   Sprite2DCloud (moving)",
				"Sprite2DBatch (static)",
				"   Sprite2DBatch (animated)",
				"   Sprite2DBatch (moving)",
				"Sprite2D individual Texture",
				"   animated",
				"   moving",
				"Clear"]);
			comboBox.width = 150;
			comboBox.addEventListener(Event.SELECT, onTestSelect);
			comboBox.numVisibleItems = 13;

			// don't dispose this bitmap and sheet when we dispose the childs but always
			// remember to manually dispose it when no longer needed (see dispose function below)
			tex = Texture2D.textureFromBitmapData(new spriteTexture().bitmapData, false);

			sheet = new TextureSheet(tex, 24, 32);
			sheet.addAnimation("blah", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], true, 5);
		}

		private function onTestSelect(e:Event):void {
			// clean up
			if(spriteBatch) {
				spriteBatch.dispose();
				spriteBatch = null;
			}

			if(spriteCloud) {
				spriteCloud.dispose();
				spriteCloud = null;
			}

			while(childFirst) {
				var sprite:Sprite2D = childFirst as Sprite2D;

				// dispose individual textures
				if(sprite && sprite.texture != tex) {
					sprite.texture.bitmap.dispose();
					sprite.texture.bitmap = null;

					sprite.texture.sheet = null;
				}

				childFirst.dispose();
			}

			selectedTestIdx = comboBox.selectedIndex;

			switch(selectedTestIdx) {
				case 3:
				case 4:
				case 5:  {
					spriteCloud = new Sprite2DCloud(maxCloudSize, tex);
					addChild(spriteCloud);
					break;
				}

				case 6:
				case 7:
				case 8:  {
					spriteBatch = new Sprite2DBatch(tex);
					addChild(spriteBatch);
					break;
				}
			}
		}

		override protected function step(elapsed:Number):void {
			super.step(elapsed);

			// camera movement comes for "free", keep that in mind! it's
			// faster to move the camera instead of hundreds of sprites
			camera.x = Math.cos(timeSinceStartInSeconds * 2) * 50;

			if(Main.stats.measuredFPS >= stage.frameRate) {
				var s:Sprite2D;

				for(var i:uint = 0; i < spritesPerFrame; i++) {
					switch(selectedTestIdx) {
						case 0:
						case 1:
						case 2:  {
							s = new Sprite2D(tex);
							addChild(s);
							break;
						}

						case 3:
						case 4:
						case 5:  {
							if(spriteCloud.numChildren >= maxCloudSize) {
								spriteCloud = new Sprite2DCloud(maxCloudSize, tex);
								addChild(spriteCloud);
							}

							s = new Sprite2D();
							spriteCloud.addChild(s);
							break;
						}

						case 6:
						case 7:
						case 8:  {
							s = new Sprite2D();
							spriteBatch.addChild(s);
							break;
						}

						case 9:
						case 10:
						case 11:  {
							var rndTex:Texture2D = Texture2D.textureFromBitmapData(new spriteTexture().bitmapData, false);
							rndTex.setSheet(sheet);

							// optional, just makes it more obvious
							var c:ColorTransform = new ColorTransform();
							c.redMultiplier = Math.random();
							c.greenMultiplier = Math.random();
							c.blueMultiplier = Math.random();
							rndTex.bitmap.colorTransform(rndTex.bitmap.rect, c);

							s = new Sprite2D(rndTex);
							addChild(s);
							break;
						}
					}

					if(s) {
						s.x = Math.round(camera.sceneWidth * Math.random());
						s.y = Math.round(camera.sceneHeight * Math.random());

						switch(selectedTestIdx) {
							case 1:
							case 4:
							case 7:
							case 10:  {
								s.animation.play("blah", 1000 * Math.random());
								break;
							}
						}
					}
				}
			}

			switch(selectedTestIdx) {
				case 2:
				case 5:
				case 8:
				case 11:  {
					for(var p:Node2D = childFirst; p; p = p.next) {
						if(p is Sprite2DBatch || p is Sprite2DCloud) {
							for(var n:Node2D = p.childFirst; n; n = n.next) {
								n.rotation += 10.0;
							}
						} else {
							p.rotation += 10.0;
						}
					}
					break;
				}
			}
		}

		override public function dispose():void {
			super.dispose();

			// force dispose of texture because we
			// created it with "autoCleanUpResources = false"
			if(tex) {
				tex.dispose(true);
				tex = null;
			}

			if(comboBox) {
				stage.removeChild(comboBox);
			}

			sheet = null;
			comboBox = null;
			spriteCloud = null;
			spriteBatch = null;
		}
	}
}
