import Set;

class SetTest extends haxe.unit.TestCase {
  public function testInput() {
    var s:Set<Int> = new Set<Int>();

    s.add(1);
    s.add(5);
    s.add(1);

    assertEquals(s.contains(1), true);
    assertEquals(s.contains(5), true);
    assertEquals(s.length, 2);
  }

  public function testRemove() {
    var s:Set<Int> = new Set<Int>();

    s.add(1);
    s.add(2);
    s.add(3);

    s.remove(1);
    s.remove(2);
    s.remove(3);

    assertEquals(s.length, 0);
  }

  public function testEquals() {
    var s1:Set<Int> = new Set([1,2,3]);
    var s2:Set<Int> = new Set([1,2,3]);
    var s3:Set<Int> = new Set([1,2,4]);

    var s4:Set<Int> = new Set([]);
    var s5:Set<Int> = new Set([]);

    assertTrue(s1.equals(s2));
    assertTrue(s2.equals(s1));

    assertFalse(s1.equals(s3));
    assertFalse(s2.equals(s3));

    assertTrue(s4.equals(s5));
    assertTrue(s5.equals(s4));
  }

  public function testIter() {
    var start:Set<Int> = new Set<Int>([1,2,3,4,5]);
    var num:Int = 0;

    for (x in start) {
      num += x;
    }

    assertEquals(num, 15);
  }

  public function testConcat() {
    var result:Set<Int> = (new Set<Int>([1,2,3])).concat(4,5,6);

    for (x in 1...6) {
      assertTrue(result.contains(x));
    }
  }

  /*
  public function testMerge() {
    var s1:Set<Int> = new Set<Int>([1,2,3,4]);
    var s2:Set<Int> = new Set<Int>([0,5,6,7,8]);
    var result:Set<Int> = Set.merge<Int>(s1, s2);

    for (x in 0...8) {
      assertTrue(result.contains(x));
    }

    s1.extend(s2);
    for (x in 0...8) {
      assertTrue(s1.contains(x));
    }
  }
  */

  public function testExtend() {
    var s1:Set<Int> = new Set([1,2,3]);
    var s2:Set<Int> = new Set([4,5,6]);

    s1.extend(s2);

    for (x in 1...6) {
      assertTrue(s1.contains(x));
    }
  }

  public function testFilter() {
    var s:Set<Int> = new Set<Int>([0,1,2,3,4,5,6,7,8]);

    s = s.filter(function(e:Int) { return (e % 2) == 0; });

    assertTrue(s.contains(0));
    assertTrue(s.contains(2));
    assertTrue(s.contains(4));
    assertTrue(s.contains(6));
    assertTrue(s.contains(8));

    assertFalse(s.contains(1));
    assertFalse(s.contains(3));
    assertFalse(s.contains(5));
    assertFalse(s.contains(7));
  }

  public function testLength() {
    var s:Set<Int> = new Set<Int>([0,1,1,1,2,3,4]);
    s.add(1);
    s.add(0);

    assertTrue(s.length == 5);
  }

  public function testPredicates() {
    var s:Set<Int> = new Set([2,4,6,8,10]);

    assertTrue(s.all([function(i:Int) return i % 2 == 0]));
    assertTrue(!s.all([function(i:Int) return i % 2 == 1]));
    assertTrue(s.any([function(i:Int) return i % 2 == 0]));
    assertTrue(s.any([function(i:Int) return i == 8]));
    assertTrue(s.any([function(i:Int) return i == 8]));
    assertTrue(s.none([function(i:Int) return i % 2 == 1]));
  }

  public function testOne() {
    var s:Set<Int> = new Set([1,2,3,5,6]);

    assertEquals(s.one([function(i) return i == 1]), 1);
    assertEquals(s.one([function(i) return i == 5]), 5);

    var didThrow:Bool = false;

    try {
      s.one([function(i) return i == 9]);
    } catch (msg: String) {
      didThrow = true;
    }

    assertTrue(didThrow);

    didThrow = false;

    try {
      s.one([function(i) return i == 9]);
    } catch (msg: String) {
      didThrow = true;
    }

    assertTrue(didThrow);
  }
}
