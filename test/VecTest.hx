import Vec;

class VecTest extends haxe.unit.TestCase {
  public function testBasic() {
    var v:Vec = new Vec(2, 5);
    var v2:Vec = new Vec(2, 5);

    assertTrue(v.x == 2);
    assertTrue(v2.y == 5);

    assertTrue(v.equals(v2));

    assertTrue(v.map(function(i:Float) { return i * 2; }).equals(new Vec(4, 10)));

    v.setPos(new Vec(1, 1));
    assertTrue(v.equals(new Vec(1, 1)));
  }

  public function testArith() {
    var v:Vec = new Vec(1, 1);

    v.add(v);
    assertTrue(v.equals(new Vec(2, 2)));

    v.add(1);
    assertTrue(v.equals(new Vec(3, 3)));

    v.subtract(v);
    assertTrue(v.equals(new Vec(0, 0)));

    v.subtract(1);
    assertTrue(v.equals(new Vec(-1, -1)));

    v.setPos(new Vec(2, 2));

    v.multiply(v);
    assertTrue(v.equals(new Vec(4, 4)));

    v.multiply(2);
    assertTrue(v.equals(new Vec(8, 8)));

    v.divide(2);
    assertTrue(v.equals(new Vec(4, 4)));

    v.divide(new Vec(4, 1));
    assertTrue(v.equals(new Vec(1, 4)));

    v.setPos(new Vec(3, 4));
    v.normalize();
    assertTrue(v.multiply(5).equals(new Vec(3, 4)));
  }

  public function testMisc() {
    var v:Vec = new Vec(-1, 1);
    v.addAwayFromZero(1, 1);
    assertTrue(v.equals(new Vec(-2, 2)));

    v.setPos(new Vec(3, 4));

    assertEquals(v.magnitude(), 5);

    assertTrue(v.nonzero());
    v.setPos(new Vec(0, 0));
    assertTrue(!v.nonzero());
  }

  public function testAngle() {
    var v:Vec = new Vec(1, 0);

    assertTrue(v.angle() == 0);
  }

  public function testEquals() {
    var v1:Vec = new Vec(0, 0);
    var v2:Vec = new Vec(0, 0);
    var v3:Vec = new Vec(0, 0);

    this.assertDotEquals(v1, v2);
  }
}
