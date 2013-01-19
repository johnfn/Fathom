import fathom.SuperObjectHash;

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

  public function testNonPrimIter() {
    var soh:SuperObjectHash<Array<Int>, Int> = new SuperObjectHash();

    var keys:Array<Array<Int>> = [[0], [1], [2], [3], [4]];
    var found:Array<Bool> = [false, false, false, false, false];

    for (k in keys) {
        soh.set(k, k[0]);
    }

    for (k in soh) {
        found[k[0]] = true;
    }

    for (val in found) {
        assertTrue(val);
    }
  }

  public function testNonPrimValIter() {
    var soh:SuperObjectHash<Array<Int>, Int> = new SuperObjectHash();

    var keys:Array<Array<Int>> = [[0], [1], [2], [3], [4]];
    var found:Array<Bool> = [false, false, false, false, false];

    for (k in keys) {
        soh.set(k, k[0]);
    }

    for (k in soh.values()) {
        found[k] = true;
    }

    for (val in found) {
        assertTrue(val);
    }
  }

  public function testPrimIter() {
    var soh:SuperObjectHash<Int, Int> = new SuperObjectHash();
    var found:Array<Bool> = [false, false, false, false, false];

    for (x in 0...5) {
        soh.set(x, x);
    }

    for (k in soh) {
        found[k] = true;
    }

    for (val in found) {
        assertTrue(val);
    }
  }

  public function testPrimValIter() {
    var soh:SuperObjectHash<Int, Int> = new SuperObjectHash();
    var found:Array<Bool> = [false, false, false, false, false];

    for (x in 0...5) {
        soh.set(x, x);
    }

    for (k in soh.values()) {
        found[k] = true;
    }

    for (val in found) {
        assertTrue(val);
    }
  }

  public function testRemovePrim() {
    var soh:SuperObjectHash<Int, Int> = new SuperObjectHash();

    for (x in 0...5) {
        soh.set(x, x);
    }

    soh.delete(0);
    soh.delete(2);
    soh.delete(4);

    for (q in soh) {
        if (q % 2 == 0) {
            assertFalse(soh.exists(q));
        } else {
            assertTrue(soh.exists(q));
        }
    }
  }

  public function testRemoveNonPrim() {
    var soh:SuperObjectHash<Array<Int>, Int> = new SuperObjectHash();
    var keys:Array<Array<Int>> = [[0], [1], [2], [3], [4]];

    for (x in keys) {
        soh.set(x, x[0]);
    }

    soh.delete(keys[0]);
    soh.delete(keys[2]);
    soh.delete(keys[4]);

    for (q in soh) {
        if (q[0] % 2 == 0) {
            assertFalse(soh.exists(q));
        } else {
            assertTrue(soh.exists(q));
        }
    }
  }


  public function testWhyIsSetBreaking() {
    var soh:SuperObjectHash<Int, Bool> = new SuperObjectHash();
    soh.set(1, true);
    soh.set(2, false);
    soh.set(3, false);
    soh.set(4, true);

    assertEquals(soh.get(1), true);
    assertEquals(soh.get(2), false);
    assertEquals(soh.get(3), false);
    assertEquals(soh.get(4), true);
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

  public function testIntToString() {
    var soh:SuperObjectHash<Int, String> = new SuperObjectHash();
    soh.set(1, "a");
    soh.set(2, "b");
    soh.set(3, "c");

    assertEquals(soh.get(1), "a");
    assertEquals(soh.get(2), "b");
    assertEquals(soh.get(3), "c");
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
