#if flash
import flash.display.BitmapData;
import flash.geom.Point;
#else
import nme.display.BitmapData;
import nme.geom.Point;
#end

class CameraTest extends haxe.unit.TestCase {
  var g:Entity;

  override public function globalSetup() {
    g = new Entity(-8, -8, 100, 100); // Centered at the origin
    g.loadSpritesheet(AllTests.testAnimation, new Vec(16, 16), new Vec(0, 0));
    Fathom.camera.setFocusTarget(new Point(0, 0));

    for (x in 0...500) {
      Fathom.camera.update();
    }
  }

  override public function globalTeardown() {
    Fathom.destroyAll();
    Fathom.camera.setFocusTarget(new Point(Fathom.actualStage.stageWidth/2, Fathom.actualStage.stageHeight/2));

    for (x in 0...500) {
      Fathom.camera.update();
    }
  }

  public function testBasic() {
    var bd:BitmapData = Graphic.takeScreenshot();

    assertEquals(bd.getPixel(Std.int(Fathom.actualStage.stageWidth / 2), Std.int(Fathom.actualStage.stageHeight / 2)), 0xff0000);
  }

  public function testCanFollowEntity() {
    Fathom.camera.setFocusTarget(g);

    for (x in 0...4) {
      assertDoesNotThrow(function() Fathom.camera.update());
    }

    var bd:BitmapData = Graphic.takeScreenshot();
    assertEquals(bd.getPixel(Std.int(Fathom.actualStage.stageWidth / 2), Std.int(Fathom.actualStage.stageHeight / 2)), 0xff0000);
  }

  public function testCanFollowVec() {
    Fathom.camera.setFocusTarget(new Vec(0, 0));

    for (x in 0...4) {
      assertDoesNotThrow(function() Fathom.camera.update());
    }

    var bd:BitmapData = Graphic.takeScreenshot();
    assertEquals(bd.getPixel(Std.int(Fathom.actualStage.stageWidth / 2), Std.int(Fathom.actualStage.stageHeight / 2)), 0xff0000);
  }
  // Camera can follow Vec and Entity
}

