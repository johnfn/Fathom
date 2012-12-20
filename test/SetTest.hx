import Set;

class SetTest extends haxe.unit.TestCase {
  public function testInput() {
    var s:Set<Int> = new Set<Int>();

    s.add(1);
    s.add(5);
    s.add(1);

    assertEquals(s.contains(1), true);
    assertEquals(s.contains(5), true);
    assertEquals(s.length, 3);
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

}
