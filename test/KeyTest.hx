import hx.Util;
import hx.Fathom;

#if flash
import starling.events.Event;
import starling.events.KeyboardEvent;
#else
import nme.events.Event;
import nme.events.KeyboardEvent;
#end

class KeyTest extends haxe.unit.TestCase {
  public function testSimple() {
    // TODO: For the life of me I can't figure out why I'm required to
    // write "hx.Util" here instead of just Util.
    // Haxe bug???
    assertFalse(hx.Util.KeyDown.X);
    assertFalse(hx.Util.KeyDown.Down);
    assertFalse(hx.Util.KeyDown.Space);
  }

  public function testKeypress() {
    var aDown:KeyboardEvent = new KeyboardEvent(KeyboardEvent.KEY_DOWN, 65, 65);
    var aUp:KeyboardEvent = new KeyboardEvent(KeyboardEvent.KEY_UP, 65, 65);

    Fathom.actualStage.dispatchEvent(aDown);
    assertTrue(hx.Util.KeyDown.A);

    Fathom.actualStage.dispatchEvent(aUp);
    assertFalse(hx.Util.KeyDown.A);
  }
}
