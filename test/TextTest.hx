import nme.display.BitmapData;
import nme.geom.Point;

class TextTest extends haxe.unit.TestCase {
  var g:Text;

  public override function beforeEach() {
    g = new Text("This is a {0, 255, 0} *test*.");
    g.x = 0;
    g.y = 0;
  }

  public override function afterEach() {
    Fathom.destroyAll();
  }

  // It's hard to be too sophisticated with these tests. We just check
  // if it has the right colors.
  function hasColor(color: UInt): Bool {
    var bd: BitmapData = Graphic.takeScreenshot();

    for (x in 0...100) {
      if (bd.getPixel(x, 10) == color) {
        return true;
      }
    }

    return false;
  }

  public function testDraw() {
    assertTrue(hasColor(0x000000));
  }

  public function testChangeText() {
    g.text = "bluh";

    assertTrue(hasColor(0x000000));
  }

  public function testAccent() {
    g.text = "*bluh bluh huge text*";

    assertTrue(hasColor(0xff0000));
  }

  public function testChangedAccent() {
    g.accentColor = 0x00ff00;
    g.text = "*bluh bluh huge text*";

    assertTrue(hasColor(0x00ff00));
  }

  public function testChangedAccentAfter() {
    g.text = "*bluh bluh huge text*";
    g.accentColor = 0x00ff00;

    assertTrue(hasColor(0x00ff00));
  }

  public function testBothColors() {
    g.text = "bluh bluh *huge text*";
    g.accentColor = 0x00ff00;

    assertTrue(hasColor(0x000000));
    assertTrue(hasColor(0x00ff00));
  }

  public function testChangeAccentColor() {
    g.text = "{0, 255, 0} *test test*";

    assertTrue(hasColor(0x00ff00));
  }

  public function testChangeAccentColorDontGetConfused() {
    g.text = "{0, 255, 0} *test test*";
    g.accentColor = 0x0000ff;

    assertTrue(hasColor(0x00ff00));
  }

  public function testSetColor() {
    g.text = "bluh *huge text*";
    g.color = 0xff0000;
    g.accentColor = 0x00ff00;

    assertTrue(hasColor(0xff0000));
    assertTrue(hasColor(0x00ff00));
  }

}

