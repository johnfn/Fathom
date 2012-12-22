import flash.display.BitmapData;
import Graphic;

class GraphicTest extends haxe.unit.TestCase {
  var g:Graphic;

  override public function setup() {
    g = new Graphic(0, 0, 10, 10);
    g.loadSpritesheet(AllTests.MyBitmapData, new Vec(2, 2));
  }

  override public function tearDown() {

  }

  public function testInit() {
    assertEquals(g.x, 0);
    assertEquals(g.y, 0);
  }

  public function testImageLoading() {
    g.setTile(0, 0);

    assertEquals(g.getPixel(0, 0), 0xffffff);
    assertEquals(g.getPixel(1, 1), 0xffffff);
    assertEquals(g.getPixel(0, 1), 0x000000);
    assertEquals(g.getPixel(1, 0), 0x000000);
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
  }

  public function testFlip() {
    g.setTile(0, 0);
    assertEquals(g.getPixel(0, 0), 0xffffff);

    g.face(-1);
    assertEquals(g.getPixel(0, 0), 0x000000);

    g.face(1);
  }
}

