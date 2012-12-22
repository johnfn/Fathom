import flash.display.BitmapData;
import Graphic;

using Lambda;

class EntityTest extends haxe.unit.TestCase {
  var e1:Entity;
  var e2:Entity;
  var e3:Entity;

  override public function setup() {
    Fathom.initialize(flash.Lib.current.stage);

    e1 = new Entity(0, 0, 10, 10).addGroups(["a"]);
    e2 = new Entity(0, 0, 10, 10).addGroups(["b"]);
    e3 = new Entity(0, 0, 10, 10).addGroups(["c"]);
  }

  override public function tearDown() {
    Fathom.destroyAll();
  }

  public function testBasic() {
    assertEquals(Fathom.entities.select([]).length, 3);
    assertTrue(Fathom.entities.select([]).has(e1));
    assertTrue(Fathom.entities.select([]).has(e2));

    assertEquals(e1.parent, Fathom.container);
    assertEquals(e2.parent, Fathom.container);
    assertEquals(e3.parent, Fathom.container);
  }

  public function testGroups() {
    assertEquals(Fathom.entities.one([Set.hasGroup("a")]), e1);
    assertEquals(Fathom.entities.one([Set.hasGroup("b")]), e2);
  }

  /*
  public function testOnStage() {
    var p = e1.HACK_sprite().parent;

    while (p.parent != null) {
      p = p.parent;
    }

    assertEquals(p, flash.Lib.current.stage);
  }
  */

  public function testAddRemove() {
    e2.addChild(e3);
    e1.addChild(e2);

    assertEquals(e1.parent, Fathom.container);
    assertEquals(e2.parent, e1);
    assertEquals(e3.parent, e2);

    assertEquals(e1.HACK_sprite().parent, Fathom.container.HACK_sprite());
    assertEquals(e2.HACK_sprite().parent, e1.HACK_sprite());
    assertEquals(e3.HACK_sprite().parent, e2.HACK_sprite());
    e1.removeFromFathom();

    assertEquals(e1.parent, null);
    assertEquals(e2.parent, null);
    assertEquals(e3.parent, null);

    assertEquals(e1.HACK_sprite().parent, null);
    assertEquals(e2.HACK_sprite().parent, e1.HACK_sprite());
    assertEquals(e3.HACK_sprite().parent, e2.HACK_sprite());
  }
}
