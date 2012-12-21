
import Graphic;

@:bitmap("testsprite.png") class MyBitmapData extends flash.display.BitmapData {}

class GraphicTest extends haxe.unit.TestCase {
  var parentG:Graphic;
  var childG:Graphic;

  override public function setup() {
    parentG = new Graphic(0, 0, 10, 10);
    childG  = new Graphic(0, 0, 10, 10);
  }

  override public function tearDown() {

  }

  public function testBasic() {
    assertEquals(childG.x, 0);
    assertEquals(childG.y, 0);
    assertEquals(parentG.x, 0);
    assertEquals(parentG.y, 0);
  }

  public function testImageLoading() {
    parentG.loadSpritesheet(MyBitmapData, new Vec(25, 25), new Vec(0, 0));

    assertTrue(true);
  }
}

