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
}
