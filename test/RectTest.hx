import flash.display.BitmapData;
import Rect;

using Lambda;

class RectTest extends haxe.unit.TestCase {
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

  public function testEquals() {
    var test1:Rect = new Rect(10, 10, 20, 20);
    var test2:Rect = new Rect(10, 10, 20, 20);

    assertDotEquals(test1, test2);
  }

  public function testClone() {
    var test1:Rect = new Rect(10, 10, 20, 20);
    var test2:Rect = test1.clone();

    assertEquals(test1, test1); //sanity check
    assertNotEquals(test1, test2);
  }

  public function testBigger() {
    var test1:Rect = new Rect(10, 10, 10, 10).makeBigger(10);

    assertEquals(test1.x, 0);
    assertEquals(test1.y, 0);
    assertEquals(test1.width, 30);
    assertEquals(test1.height, 30);
    assertEquals(test1.right, 30);
    assertEquals(test1.bottom, 30);
  }

  public function testSetters() {
    var test:Rect = new Rect(0, 0, 10, 10);

    assertEquals(test.right, 10);
    assertEquals(test.bottom, 10);

    test.x += 10;
    test.y += 10;

    assertEquals(test.right, 20);
    assertEquals(test.bottom, 20);

    test.right += 10;
    test.bottom += 10;

    assertEquals(test.width, 20);
    assertEquals(test.height, 20);
  }
}

