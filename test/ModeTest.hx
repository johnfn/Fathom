import fathom.Entity;
import fathom.Mode;
import fathom.Fathom;
import fathom.Set;

import flash.display.BitmapData;

using Lambda;

class OneThing extends Entity {
  public var didUpdate: Bool = false;

  public function new() {
    super(0, 0);
    debug(25, 25, 0xff0000);
  }

  public override function modes(): Array<Int> {
    return [1];
  }

  public override function update(): Void {
    didUpdate = true;

    super.update();
  }
}

class ZeroThing extends Entity {
  public var didUpdate: Bool = false;

  public function new() {
    super(0, 0);
    debug(25, 25, 0xff0000);
  }

  public override function modes(): Array<Int> {
    return [0];
  }

  public override function update(): Void {
    didUpdate = true;

    super.update();
  }
}

class BothThing extends Entity {
  public var didUpdate: Bool = false;

  public function new() {
    super(0, 0);
    debug(25, 25, 0xff0000);
  }

  public override function modes(): Array<Int> {
    return [0, 1];
  }

  public override function update(): Void {
    didUpdate = true;

    super.update();
  }
}

class ModeTest extends haxe.unit.TestCase {
  var one: OneThing;
  var zero: ZeroThing;
  var onezero: BothThing;

  override public function beforeEach() {
    one = new OneThing();
    zero = new ZeroThing();
    onezero = new BothThing();

    // (You should never have to write this in your code)
    Fathom.mode = new Mode();
  }

  override public function afterEach() {
    Fathom.destroyAll();
  }

  public function testBasic() {
    Fathom.update();

    assertTrue(zero.didUpdate);
    assertFalse(one.didUpdate);
    assertTrue(onezero.didUpdate);
  }

  public function testPushPop() {
    Fathom.mode.push(1);
    Fathom.update();

    assertFalse(zero.didUpdate);
    assertTrue(one.didUpdate);
    assertTrue(onezero.didUpdate);

    Fathom.mode.pop();

    zero.didUpdate = false;
    one.didUpdate = false;
    onezero.didUpdate = false;

    Fathom.update();

    assertTrue(zero.didUpdate);
    assertFalse(one.didUpdate);
    assertTrue(onezero.didUpdate);
  }

  public function testReplace() {
    Fathom.mode.push(1);
    Fathom.update();

    assertFalse(zero.didUpdate);
    assertTrue(one.didUpdate);
    assertTrue(onezero.didUpdate);

    Fathom.mode.replace(0);

    zero.didUpdate = false;
    one.didUpdate = false;
    onezero.didUpdate = false;

    Fathom.update();

    assertTrue(zero.didUpdate);
    assertFalse(one.didUpdate);
    assertTrue(onezero.didUpdate);

    Fathom.mode.pop();
  }
}
