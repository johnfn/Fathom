
import Graphic;

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
}

