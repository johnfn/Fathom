import flash.display.BitmapData;
import Rect;

using Lambda;

class RectTest extends haxe.unit.TestCase {

  override public function setup() {

  }

  override public function tearDown() {

  }

  public function testRectRectCollision() {
    var test1:Rect = new Rect(10, 10, 20, 20);
    var test2:Rect = new Rect(15, 15, 20, 20);
    var test3:Rect = new Rect(35, 35, 20, 20);
    var test4:Rect = new Rect(15, 5, 5, 60);

    assertTrue(test1.touchingRect(test2));
    assertTrue(test2.touchingRect(test1));

    assertFalse(test1.touchingRect(test3));
    assertFalse(test3.touchingRect(test1));

    assertTrue(test3.touchingRect(test2));
    assertTrue(test2.touchingRect(test3));

    assertTrue(test1.touchingRect(test4));
    assertTrue(test4.touchingRect(test1));
  }

  public function testRectPointCollision() {
    var test:Rect = new Rect(10, 10, 20, 20);

    assertTrue(test.containsPt(new Vec(15, 15)));
    assertTrue(test.containsPt(new Vec(10, 10))); // Literally an edge case. HA! HA!
    assertFalse(test.containsPt(new Vec(9, 9)));
  }
}

