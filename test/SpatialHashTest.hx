import fathom.SpatialHash;
import fathom.Fathom;
import fathom.Vec;
import fathom.Entity;

class SpatialHashTest extends haxe.unit.TestCase {
  private var d: Vec;
  private var w: Vec;

  public override function globalSetup() {
    d = new Vec(25, 25);
    w = new Vec(0, 0);
  }

  public function testBasic() {
    var sh:SpatialHash = new SpatialHash([]);

    var e1: Entity = new Entity(0, 0, 25, 25)
        .loadSpritesheet(AllTests.testAnimation, d, w);
    var e2: Entity = new Entity(25, 0, 25, 25)
        .loadSpritesheet(AllTests.testAnimation, d, w);

    sh.add(e1);
    sh.add(e2);

    assertEquals(sh.getColliders(e1).length, 0);
    assertEquals(sh.getColliders(e2).length, 0);

    var e3: Entity = new Entity(12, 0, 25, 25)
        .loadSpritesheet(AllTests.testAnimation, d, w);

    sh.add(e3);

    assertEquals(sh.getColliders(e1).length, 1);
    assertEquals(sh.getColliders(e2).length, 1);

    //assertEquals(sh.getColliders(e1).first(), e3);
    //assertEquals(sh.getColliders(e2).first(), e3);
  }

  public override function globalTeardown() {
    Fathom.destroyAll();
  }
}
