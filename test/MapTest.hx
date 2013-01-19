import hx.Map;
import hx.Fathom;
import hx.Vec;
import hx.Graphic;
import hx.Entity;
import hx.Set;

import flash.display.BitmapData;
import flash.display.Bitmap;

using Lambda;

class SpecialThing extends Entity {
  public function new() {
    super();

    MapTest.constructedCount++;
  }

  public override function groups():Set<String> {
    return groupSet.concat("test");
  }
}

class MapTest extends haxe.unit.TestCase {
  public var m:Map;

  public static var constructedCount:Int = 0;

  public override function globalSetup() {
    m = new Map(2, 2, 2);
    m.fromImage(AllTests.testMap, [], [
      { color: "#ffffff", gfx: AllTests.testSprite, spritesheet: new Vec(0, 0) }
    , { color: "#0000ff", gfx: AllTests.testSprite, spritesheet: new Vec(1, 0) }
    , { color: "#ff0000", spc: MapTest.SpecialThing, spritesheet: new Vec(1, 1) } //represented as green
    ]);
    m.loadNewMap(new Vec(0, 0));
  }

  //TODO TEST: Map collisions with moving entities...

  override public function globalTeardown() {
    Fathom.destroyAll();
  }

  // Can't tell why this fails. Everything looks fine to me.
  public function testMapLoad() {
    /*
    var b:Bitmap = new Bitmap(Graphic.takeScreenshot());
    b.x = 200;
    b.y = 200;
    Fathom.stage.addChild(b);
    */

    m.loadNewMapAbs(new Vec(0, 0));
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0x0000ff);
  }

  public function testMapChangeDiff() {
    m.loadNewMapAbs(new Vec(0, 0));

    m.loadNewMap(new Vec(1, 0));
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0xFFFFFF);
    m.loadNewMap(new Vec(-1, 0));
    m.loadNewMap(new Vec(0, 1)); // now at map (0, 1)
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0xFFFFFF);
    m.loadNewMap(new Vec(1, 0)); // now at map (1, 1)
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0x0000FF);
  }

  public function testMapChangeAbs() {
    m.loadNewMapAbs(new Vec(1, 0));
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0xFFFFFF);
    m.loadNewMapAbs(new Vec(0, 1)); // now at map (0, 1)
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0xFFFFFF);
    m.loadNewMapAbs(new Vec(1, 1)); // now at map (1, 1)
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0x0000FF);
  }

  public function testSpecialItems() {
    m.loadNewMapAbs(new Vec(0, 0));

    m.loadNewMap(new Vec(0, 1));

    assertEquals(Fathom.entities.get([Set.hasGroup("test")]).length, 1);
    var s:Entity = Fathom.entities.one([Set.hasGroup("test")]);

    m.loadNewMapAbs(new Vec(0, 0));

    assertEquals(Fathom.entities.get([Set.hasGroup("test")]).length, 0);
  }

  public function testDontFreakOutForOutOfMapEntities() {
    var s:Entity;

    m.loadNewMapAbs(new Vec(0, 1));
    s = Fathom.entities.one([Set.hasGroup("test")]);

    assertEquals(s.x, 0);
    assertEquals(s.y, 2);

    s.setPos(7, 7);

    m.loadNewMapAbs(new Vec(0, 0));
    m.loadNewMapAbs(new Vec(0, 1));

    s = Fathom.entities.one([Set.hasGroup("test")]);

    assertDotEquals(s.vec(), new Vec(7, 7));
    s.setPos(0, 2);
  }

  public function testPersistentItem() {
    var s:Entity;

    m.loadNewMapAbs(new Vec(0, 1));
    s = Fathom.entities.one([Set.hasGroup("test")]);

    s.setPos(1, 1);

    m.loadNewMapAbs(new Vec(0, 0));
    m.loadNewMapAbs(new Vec(0, 1));

    s = Fathom.entities.one([Set.hasGroup("test")]);

    assertDotEquals(s.vec(), new Vec(1, 1));
    s.setPos(0, 2);
  }

  /*
  public function testSwitchMaps() {
    var s:Entity;

    m.loadNewMapAbs(new Vec(0, 1));
    s = Fathom.entities.one([Set.hasGroup("test")]);
    s.setPos(-2, 1);

    m.update();
    assertTrue(!s.inFathom);

    m.loadNewMapAbs(new Vec(0, 0));
    assertTrue(s.inFathom);

    s.setPos(2, 1);
    assertTrue(!s.inFathom);

    m.loadNewMapAbs(new Vec(0, 1));
    assertTrue(s.inFathom);
    s.setPos(0, 2); //original position
  }
  */

  /*
  public function testReload() {
    m.loadNewMapAbs(new Vec(0, 0));
    // do something surprising
    m.loadNewMapAbs(new Vec(0, 0));
  }
  */
}
