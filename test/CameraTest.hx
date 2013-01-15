import nme.display.BitmapData;
import nme.geom.Point;

class CameraTest extends haxe.unit.TestCase {
  var g:Entity;

  public override function globalSetup() {
    Util.assert(Fathom.entities.length == 0, "there's an entity!");

    g = new Entity(-8, -8, 100, 100); // Centered at the origin
    g.loadSpritesheet(AllTests.testAnimation, new Vec(16, 16), new Vec(0, 0));
    g.setTile(0, 0);
  }

  override public function globalTeardown() {
    Fathom.destroyAll();
    Fathom.camera.setFocusTarget(new Point(Fathom.actualStage.stageWidth/2, Fathom.actualStage.stageHeight/2));

    for (x in 0...500) {
      Fathom.camera.update();
    }
  }

  public function testBasic() {
    Fathom.camera.setFocusTarget(new Point(0, 0));

    for (x in 0...500) Fathom.camera.update(); // force it to move all the way there, despite any lag

    var bd:BitmapData = Graphic.takeScreenshot();

    assertEquals(bd.getPixel(Std.int(Fathom.actualStage.stageWidth / 2), Std.int(Fathom.actualStage.stageHeight / 2)), 0xff0000);
  }

  public function testCanFollowEntity() {
    Fathom.camera.setFocusTarget(g);

    for (x in 0...500) {
      assertDoesNotThrow(function() Fathom.camera.update());
    }

    var bd:BitmapData = Graphic.takeScreenshot();
    assertEquals(bd.getPixel(Std.int(Fathom.actualStage.stageWidth / 2), Std.int(Fathom.actualStage.stageHeight / 2)), 0xff0000);
  }

  public function testCanFollowVec() {
    Fathom.camera.setFocusTarget(new Vec(0, 0));

    for (x in 0...500) {
      assertDoesNotThrow(function() Fathom.camera.update());
    }

    var bd:BitmapData = Graphic.takeScreenshot();
    assertEquals(bd.getPixel(Std.int(Fathom.actualStage.stageWidth / 2), Std.int(Fathom.actualStage.stageHeight / 2)), 0xff0000);
  }

  public function testSnap() {
    Fathom.camera.setFocusTarget(new Vec(500, 500));

    Fathom.pixelSnapping = true;

    for (x in 0...50) {
      var p: Point = g.localToGlobal(new Point(0, 0));
      assertTrue(p.x == Math.round(p.x));
      assertTrue(p.y == Math.round(p.y));
    }
  }
  // Camera can follow Vec and Entity
}

