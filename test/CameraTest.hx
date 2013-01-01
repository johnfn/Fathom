import flash.display.BitmapData;
import Graphic;

class CameraTest extends haxe.unit.TestCase {
  var g:Entity;

  override public function globalSetup() {
    g = new Entity(0, 0, 100, 100);
    g.loadSpritesheet(AllTests.TestAnimation, new Vec(16, 16), new Vec(0, 0));
  }

  override public function globalTeardown() {
    Fathom.destroyAll();
  }

  public function testBasic() {
    Fathom._camera.setFocus(new Vec(Std.int(Fathom.stage.stageWidth / 2), Std.int(Fathom.stage.stageHeight / 2)));
    var bd:BitmapData = Graphic.takeScreenshot();

    assertEquals(bd.getPixel(0, 0), 0xff0000);
  }

  /*
  No idea how to test this!

  public function testNonSquare() {
    assertThrows(function() stage.width = 234234);
  }
  */

  // Entities move instantly when setPos()d (and correctly!).
}

