class SuperObjectHashTest extends haxe.unit.TestCase {
  public function testNonPrimitive() {
    var soh:SuperObjectHash<Array<Int>, Int> = new SuperObjectHash();

    var keys:Array<Array<Int>> = [];

    for (x in 0...100) {
        keys.push([x]);
    }

    for (x in 0...100) {
        soh.set(keys[x], x);
    }

    for (x in 0...100) {
        assertTrue(soh.exists(keys[x]));
        assertEquals(soh.get(keys[x]), x);
    }
  }

  public function testPrimitiveBasicInt() {
    var soh:SuperObjectHash<Int, Int> = new SuperObjectHash();

    for (x in 0...10) {
        soh.set(x, x);
    }

    for (x in 0...5) {
        assertTrue(soh.exists(x));
        assertEquals(soh.get(x), x);
    }
  }

  public function testPrimitiveBasicFloat() {
    var soh:SuperObjectHash<Float, Float> = new SuperObjectHash();

    for (x in 0...10) {
        soh.set(x + 0.5, x + 0.5);
    }

    for (x in 0...5) {
        assertTrue(soh.exists(x + 0.5));
        assertEquals(soh.get(x + 0.5), x + 0.5);
    }
  }

  public function testPrimitiveBasicString() {
    var soh:SuperObjectHash<String, String> = new SuperObjectHash();
    soh.set("a", "a");
    soh.set("b", "b");
    soh.set("c", "c");

    assertTrue(soh.exists("a"));
    assertTrue(soh.exists("b"));
    assertTrue(soh.exists("c"));
  }

  public function testIterator() {
    var soh:SuperObjectHash<Int, Int> = new SuperObjectHash();
    var seen:Array<Bool> = [false, false, false, false, false];

    for (x in 0...5) {
        soh.set(x, x);
    }

    for (i in soh) {
        seen[i] = true;
    }

    for (i in 0...5) {
        assertTrue(seen[i]);
    }
  }

  public function testPrimitiveDupes() {
    var soh:SuperObjectHash<Int, Int> = new SuperObjectHash();

    for (x in 0...5) {
        soh.set(x, x);
        soh.set(x, x);
        soh.set(x, x);
    }

    for (x in 0...5) {
        assertTrue(soh.exists(x));
    }

    var count:Int = 0;
    for (q in soh) {
        ++count;
    }

    assertEquals(count, 5);
  }
}
