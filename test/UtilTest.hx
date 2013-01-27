import fathom.Entity;
import fathom.Util;
import fathom.SuperObjectHash;
import fathom.Mode;
import fathom.Fathom;
import fathom.Set;

import flash.display.BitmapData;

using Lambda;
using StringTools;

class UtilTest extends haxe.unit.TestCase {
  public function testAnythingToString() {
    var s: String = Util.anythingToString([1, 'a', {'a': 1}]);

    assertEquals(s.replace(" ", ""), '[1, "a", { a => 1 }]'.replace(" ", ""));

    assertEquals(Util.anythingToString("a"), '"a"');

    var soh: fathom.SuperObjectHash<String, Int> = new fathom.SuperObjectHash();
    soh.set("a", 1);

    assertEquals(Util.anythingToString(soh).replace(" ", ""), '{"a"=>1}');

    assertEquals(Util.anythingToString(null), "null");
  }

  public function testSmallFunctions() {
    assertEquals(Util.sign(-5), -1);
    assertEquals(Util.sign(5),   1);
    assertEquals(Util.sign(0),   0);

    assertEquals(Util.clamp(7, -5, 5), 5);
    assertEquals(Util.clamp(5, -5, 5), 5);
    assertEquals(Util.clamp(1, -5, 5), 1);
    assertEquals(Util.clamp(-5, -5, 5), -5);
    assertEquals(Util.clamp(-7, -5, 5), -5);
  }

  public function testGetClassName() {
    assertEquals(Util.className(this), "UtilTest");
  }

  public function test2D() {
    var arr2d: Array<Array<Int>> = Util.make2DArrayFn(5, 5, function(x, y) return x+y);

    assertEquals(arr2d[0][0], 0);
    assertEquals(arr2d[4][3], 7);
    assertEquals(arr2d[2][4], 6);

    Util.foreach2D(arr2d, function (x, y, val) assertEquals(x + y, val));
  }
}
