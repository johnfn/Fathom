class ColorTest extends haxe.unit.TestCase {
  public function testBasic() {
    var c1:Color = new Color(255, 0, 0);
    var c2:Color = new Color(255, 0, 0);

    assertDotEquals(c1, c2);
    assertEquals(c1.toString(), c2.toString());
    assertEquals(c1.r, c2.r);
    assertEquals(c1.r, 255);
  }

  public function testToString(): Void {
    var red:Color = new Color(255, 0, 0);
    var blue:Color = new Color(0, 0, 255);

    assertEquals(red.toString(), "#ff0000");
    assertEquals(blue.toString(), "#0000ff");

    assertEquals(red.toInt(), 16711680);
    assertEquals(blue.toInt(), 255);
  }

  public function testRead(): Void {
    var red:Color = Color.read("#ff0000");
    var red2:Color = new Color(255, 0, 0);

    assertDotEquals(red, red2);
    assertEquals(red.toInt(), red2.toInt());
  }

  public function testFromInt(): Void {
    var blue:Color = new Color(0, 0, 255);
    var blue2:Color = Color.fromInt(255);

    assertDotEquals(blue, blue2);
    assertEquals(blue.toInt(), blue2.toInt());
  }
}
