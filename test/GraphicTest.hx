import flash.display.BitmapData;
import Graphic;

class GraphicTest extends haxe.unit.TestCase {
  var g:Entity;

  override public function globalSetup() {
    g = new Entity(200, 200, 100, 100);
    g.loadSpritesheet(AllTests.MyBitmapData, new Vec(2, 2));
    g.setTile(0, 0);
  }

  override public function globalTeardown() {
    Fathom.destroyAll();
  }


  override public function tearDown() {

  }

  public function testInit() {
    assertEquals(g.x, 200);
    assertEquals(g.y, 200);
  }

  public function testImageLoading() {
    g.setTile(0, 0);

    assertEquals(g.getPixel(0, 0), 0xffffff);
    assertEquals(g.getPixel(1, 1), 0xffffff);
    assertEquals(g.getPixel(0, 1), 0x000000);
    assertEquals(g.getPixel(1, 0), 0x000000);
  }

  public function testSpriteSheetLoc() {
    g.setTile(1, 2);

    assertEquals(g.getSpriteX(), 1);
    assertEquals(g.getSpriteY(), 2);

    g.setTile(0, 1);

    assertEquals(g.getSpriteX(), 0);
    assertEquals(g.getSpriteY(), 1);

  }

  public function testSetTile() {
    // Black
    g.setTile(0, 0);
    assertEquals(g.getPixel(0, 0), 0xffffff);

    // Blue
    g.setTile(1, 0);
    assertEquals(g.getPixel(0, 0), 0x0000ff);

    // Red
    g.setTile(0, 1);
    assertEquals(g.getPixel(0, 0), 0xff0000);

    // Green
    g.setTile(1, 1);
    assertEquals(g.getPixel(0, 0), 0x00ff00);

    // Black
    g.setTile(0, 0);
    assertEquals(g.getPixel(0, 0), 0xffffff);
  }

  /*
  public function testFlip() {
    g.setTile(0, 0);
    assertEquals(g.getPixel(0, 0), 0xffffff);

    g.face(-1);
    assertEquals(g.getPixel(0, 0), 0x000000);

    g.face(1);
  }
  */
}

