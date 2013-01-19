import hx.ReloadedGraphic;
import hx.Fathom;
import hx.Graphic;

import flash.display.BitmapData;

using Lambda;

class ReloadedGraphicTest extends haxe.unit.TestCase {
  public var g: ReloadedGraphic = null;

  public override function beforeEach() {
    g = new ReloadedGraphic(AllTests.testSprite);
    Fathom.stage.addChild(g);
  }

  override public function afterEach() {
    Fathom.destroyAll();
  }

  public function testLoad() {
    var b:BitmapData = Graphic.takeScreenshot();

    assertEquals(b.getPixel(0, 0), 0xffffff);
    assertEquals(b.getPixel(1, 1), 0xffffff);
    assertEquals(b.getPixel(0, 1), 0x000000);
    assertEquals(b.getPixel(1, 0), 0x000000);
  }
}

