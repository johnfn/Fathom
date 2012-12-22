import flash.display.BitmapData;
import Graphic;

using Lambda;

class EntityTest extends haxe.unit.TestCase {
  var e1:Entity;
  var e2:Entity;

  override public function setup() {
    Fathom.initialize(flash.Lib.current.stage);

    e1 = new Entity(0, 0, 10, 10).addGroups(["a"]);
    e2 = new Entity(0, 0, 10, 10).addGroups(["b"]);
  }

  override public function tearDown() {
    Fathom.destroyAll();
  }

  public function testBasic() {
    assertEquals(Fathom.entities.select([]).length, 2);
    assertTrue(Fathom.entities.select([]).has(e1));
    assertTrue(Fathom.entities.select([]).has(e2));
  }

  public function testGroups() {
    assertEquals(Fathom.entities.one([Set.hasGroup("a")]), e1);
    assertEquals(Fathom.entities.one([Set.hasGroup("b")]), e2);
  }
}

