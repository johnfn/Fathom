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
    var e3: Entity = new Entity(12, 0, 25, 25)
        .loadSpritesheet(AllTests.testAnimation, d, w);

    sh.add(e1);
    sh.add(e2);

    assertEquals(sh.getColliders(e1).length, 0);
    assertEquals(sh.getColliders(e2).length, 0);


    sh.add(e3);

    assertEquals(sh.getColliders(e1).length, 1);
    assertEquals(sh.getColliders(e2).length, 1);

    //assertEquals(sh.getColliders(e1).first(), e3);
    //assertEquals(sh.getColliders(e2).first(), e3);
  }

  public function testBig() {
    var sh:SpatialHash = new SpatialHash([]);

    var e1: Entity = new Entity(0, 0, 25, 25)
        .loadSpritesheet(AllTests.testAnimation, new Vec(50, 50), w);

    var e2: Entity = new Entity(0, 0, 25, 25)
        .loadSpritesheet(AllTests.testAnimation, d, w);
    var e3: Entity = new Entity(25, 0, 25, 25)
        .loadSpritesheet(AllTests.testAnimation, d, w);
    var e4: Entity = new Entity(0, 25, 25, 25)
        .loadSpritesheet(AllTests.testAnimation, d, w);
    var e5: Entity = new Entity(25, 25, 25, 25)
        .loadSpritesheet(AllTests.testAnimation, d, w);

    sh.add(e1);
    sh.add(e2);
    sh.add(e3);
    sh.add(e4);
    sh.add(e5);

    assertEquals(sh.getColliders(e1).length, 4);

    assertTrue(sh.getColliders(e1).exists(e2));
    assertTrue(sh.getColliders(e1).exists(e3));
    assertTrue(sh.getColliders(e1).exists(e4));

    assertEquals(sh.getColliders(e2).length, 1);
    assertEquals(sh.getColliders(e2).first(), e1);

    assertEquals(sh.getColliders(e3).length, 1);
    assertEquals(sh.getColliders(e3).first(), e1);

    assertEquals(sh.getColliders(e4).length, 1);
    assertEquals(sh.getColliders(e4).first(), e1);

    assertEquals(sh.getColliders(e5).length, 1);
    assertEquals(sh.getColliders(e5).first(), e1);
  }

  public override function globalTeardown() {
    Fathom.destroyAll();
  }
}
