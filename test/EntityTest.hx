import flash.display.BitmapData;
import hx.Entity;

using Lambda;

class EntityTest extends haxe.unit.TestCase {
  var e1:Entity;
  var e2:Entity;
  var e3:Entity;

  override public function beforeEach() {
    e1 = new Entity(0, 0, 10, 10).addGroups(["a"]);
    e2 = new Entity(0, 0, 10, 10).addGroups(["b"]);
    e3 = new Entity(0, 0, 10, 10).addGroups(["c"]);
  }

  override public function afterEach() {
    Fathom.destroyAll();
  }

  public function testBasic() {
    assertEquals(Fathom.entities.get([]).length, 3);
    assertTrue(Fathom.entities.get([]).has(e1));
    assertTrue(Fathom.entities.get([]).has(e2));

    assertEquals(e1.parent, Fathom.stage);
    assertEquals(e2.parent, Fathom.stage);
    assertEquals(e3.parent, Fathom.stage);
  }

  /*
  public function testLocalToGlobal() {
    e2.addChild(e3);
    e1.addChild(e2);

    e1.x = 1;
    e1.y = 2;

    e2.x = 10;
    e2.y = 20;

    e3.x = 100;
    e3.y = 200;

    assertDotEquals(e1.localToGlobal(e2), new Point(11, 22));
    assertDotEquals(e1.localToGlobal(e3), new Point(111, 222));
    assertDotEquals(e2.localToGlobal(e3), new Point(110, 220));
  }
  */

  public function testGroups() {
    assertEquals(Fathom.entities.one([Set.hasGroup("a")]), e1);
    assertEquals(Fathom.entities.one([Set.hasGroup("b")]), e2);
  }

  public function testOnStage() {
    var p = e1.parent;

    while (p.parent != null) {
      p = p.parent;
    }

    assertEquals(p, Fathom.actualStage);
  }

  public function testAddRemove() {
    e2.addChild(e3);
    e1.addChild(e2);

    assertEquals(e1.parent, Fathom.stage);
    assertEquals(e2.parent, e1);
    assertEquals(e3.parent, e2);

    assertEquals(e1.parent, Fathom.stage);
    assertEquals(e2.parent, e1);
    assertEquals(e3.parent, e2);
    e1.removeFromFathom();

    assertFalse(e1.inFathom);
    assertFalse(e2.inFathom);
    assertFalse(e3.inFathom);
  }

  public function testListenUnlisten() {
    var test1:Int = 0;
    var test2:Int = 0;

    var fn1:Void -> Void = function() test1++;
    var fn2:Void -> Void = function() test2 += 2;

    e1.listen(fn1);
    e1.listen(fn2);
    e1.listen(fn2);
    e1.listen(fn2);
    e1.unlisten(fn2);
    e1.unlisten(fn2);

    e1.update();
    e1.update();

    assertEquals(test1, 2);
    assertEquals(test2, 4);
  }

  public function testDestroyAfter() {
    e1.destroyAfter(5);
    for (x in 0...5) {
      e1.update();
    }

    assertTrue(e1.destroyed);

    e2.destroy();
    assertTrue(e2.destroyed);
  }
}

