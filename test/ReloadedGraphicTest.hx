import flash.display.BitmapData;
import Rect;

using Lambda;

class ReloadedGraphicTest extends haxe.unit.TestCase {
  override public function setup() {
    Fathom.hotswapPrefix = "/Users/grantm/code/ep1/FathomHaxe/";
  }

  override public function tearDown() {

  }

  public function asyncLoadTest(done: Void -> Void) {
    var g:ReloadedGraphic = null;

    g = new ReloadedGraphic(AllTests.testSprite, function() {
      var b:BitmapData = Graphic.takeScreenshot();

      assertEquals(b.getPixel(0, 0), 0xffffff);
      assertEquals(b.getPixel(1, 1), 0xffffff);
      assertEquals(b.getPixel(0, 1), 0x000000);
      assertEquals(b.getPixel(1, 0), 0x000000);

      done();
    });

    Fathom.stage.addChild(g);
  }
}

