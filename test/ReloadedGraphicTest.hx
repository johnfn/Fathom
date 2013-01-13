import flash.display.BitmapData;
import Rect;

using Lambda;

class ReloadedGraphicTest extends haxe.unit.TestCase {
  public var g: ReloadedGraphic = null;

  public function globalAsyncSetup(done: Void -> Void) {
    Fathom.hotswapPrefix = "/Users/grantm/code/ep1/FathomHaxe/";

    g = new ReloadedGraphic(AllTests.testSprite, function() {
      Fathom.stage.addChild(g);
      done();
    });
  }

  override public function tearDown() {

  }

  public function testLoad() {
    var b:BitmapData = Graphic.takeScreenshot();

    assertEquals(b.getPixel(0, 0), 0xffffff);
    assertEquals(b.getPixel(1, 1), 0xffffff);
    assertEquals(b.getPixel(0, 1), 0x000000);
    assertEquals(b.getPixel(1, 0), 0x000000);
  }
}

