#if flash
import starling.events.Event;
import starling.events.KeyboardEvent;
#else
import nme.events.Event;
import nme.events.KeyboardEvent;
#end

class KeyTest extends haxe.unit.TestCase {
  public function testSimple() {
    assertFalse(Util.KeyDown.X);
    assertFalse(Util.KeyDown.Down);
    assertFalse(Util.KeyDown.Space);
  }

  public function testKeypress() {
    var aDown:KeyboardEvent = new KeyboardEvent(KeyboardEvent.KEY_DOWN, 65, 65);
    var aUp:KeyboardEvent = new KeyboardEvent(KeyboardEvent.KEY_UP, 65, 65);
    Fathom.stage.dispatchEvent(aDown);

    assertTrue(Util.KeyDown.A);
    Fathom.actualStage.dispatchEvent(aUp);
    assertFalse(Util.KeyDown.A);
  }
}
