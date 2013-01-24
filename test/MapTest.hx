import fathom.Map;
import fathom.Fathom;
import fathom.Vec;
import fathom.Graphic;
import fathom.Entity;
import fathom.Set;

import flash.display.BitmapData;
import flash.display.Bitmap;

using Lambda;

class SpecialThing extends Entity {
  public function new() {
    super(0, 0);
    MapTest.constructedCount++;
    debug(2, 2, 0xff0000);
  }

  public override function groups():Set<String> {
    return groupSet.concat("test");
  }
}

class RedThing extends Entity {
  public function new(x: Int, y: Int) {
    super(x, y);

    debug(25, 25, 0xff0000);
  }
}

class BlueThing extends Entity {
  public function new(x: Int, y: Int) {
    super(x, y);

    debug(25, 25, 0x0000ff);
  }
}

class MapTest extends haxe.unit.TestCase {
  public var m:Map;

  public static var constructedCount:Int = 0;

  public override function beforeEach() {
  }

  // A map with small tiles (2x2).
  function constructNormalMap() {
    m = new Map(2, 2, 2);
    m.fromImage(AllTests.testMap, [
      { key: "#ffffff", gfx: AllTests.testSprite, spritesheet: new Vec(0, 0) }
    , { key: "#0000ff", gfx: AllTests.testSprite, spritesheet: new Vec(1, 0) }
    , { key: "#ff0000", spc: MapTest.SpecialThing, spritesheet: new Vec(1, 1) } //represented as green
    ]);
    m.loadNewMap(new Vec(0, 0));
  }

  // A map with big tiles (25x25).
  function constructBigMap() {
    m = new Map(2, 2, 25);

    m.fromStringArray
      (
        [ "RB"
        , "BR"
        ]
      , [ { key: "R", spc: RedThing }
        , { key: "B", spc: BlueThing }
        ]
      );

    m.loadNewMap(new Vec(0, 0));
  }

  override public function afterEach() {
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

    constructNormalMap();
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0x0000ff);
  }

  public function testMapChangeDiff() {
    constructNormalMap();

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
    constructNormalMap();

    m.loadNewMapAbs(new Vec(1, 0));
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0xFFFFFF);
    m.loadNewMapAbs(new Vec(0, 1)); // now at map (0, 1)
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0xFFFFFF);
    m.loadNewMapAbs(new Vec(1, 1)); // now at map (1, 1)
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0x0000FF);
  }

  public function testSpecialItems() {
    constructNormalMap();

    m.loadNewMapAbs(new Vec(0, 0));

    m.loadNewMap(new Vec(0, 1));

    assertEquals(Fathom.entities.get([Set.hasGroup("test")]).length, 1);
    var s:Entity = Fathom.entities.one([Set.hasGroup("test")]);

    m.loadNewMapAbs(new Vec(0, 0));

    assertEquals(Fathom.entities.get([Set.hasGroup("test")]).length, 0);
  }

  public function testDontFreakOutForOutOfMapEntities() {
    constructNormalMap();

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
    constructNormalMap();

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

  public function testBigTiles() {
    constructBigMap();

    //  [ "RB"
    //  , "BR"
    //  ]

    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0xFF0000);
    assertEquals(Graphic.takeScreenshot().getPixel(25, 0), 0x0000FF);
    assertEquals(Graphic.takeScreenshot().getPixel(0, 25), 0x0000FF);
    assertEquals(Graphic.takeScreenshot().getPixel(25, 25), 0xFF0000);
  }

  public function testSwitchMaps() {
    constructNormalMap();

    var s:Entity;

    m.loadNewMapAbs(new Vec(0, 1));
    s = Fathom.entities.one([Set.hasGroup("test")]);

    // test up and down

    s.setPos(1, -2);

    m.update();
    assertTrue(!s.inFathom);

    m.loadNewMapAbs(new Vec(0, 0));
    assertTrue(s.inFathom);

    s.setPos(0, 3);
    m.update();
    assertTrue(!s.inFathom);

    m.loadNewMapAbs(new Vec(0, 1));
    assertTrue(s.inFathom);

    // test left and right

    s.setPos(3, 0);
    m.update();
    assertTrue(!s.inFathom);

    // This is the first time we've been on (1, 1), so we could
    // run into bugs from how we handle that too.
    m.loadNewMapAbs(new Vec(1, 1));
    assertTrue(s.inFathom);

    s.setPos(-3, 0);
    m.update();
    assertTrue(!s.inFathom);
    m.loadNewMapAbs(new Vec(0, 1));
  }

  /*
  public function testReload() {
    m.loadNewMapAbs(new Vec(0, 0));
    // do something surprising
    m.loadNewMapAbs(new Vec(0, 0));
  }
  */
}
