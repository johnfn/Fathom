import flash.display.BitmapData;
import Graphic;

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

  override public function setup() {
    m = new Map(2, 2, 2);

    m.fromImage(AllTests.testMap, [], [
      { color: "#ffffff", gfx: AllTests.testSprite, spritesheet: new Vec(0, 0) }
    , { color: "#0000ff", gfx: AllTests.testSprite, spritesheet: new Vec(1, 0) }
    , { color: "#ff0000", spc: MapTest.SpecialThing, spritesheet: new Vec(1, 1) } //represented as green
    ]);

    m.loadNewMap(new Vec(0, 0));
    constructedCount = 0;
  }

  //TODO TEST: Map collisions with moving entities...

  override public function tearDown() {
    Fathom.destroyAll();
  }

  public function testMapLoad() {
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0x0000ff);
  }

  public function testMapChangeDiff() {
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
    constructedCount = 0;
    m.loadNewMap(new Vec(0, 1));

    assertEquals(constructedCount, 1);

    assertEquals(Fathom.entities.select([Set.hasGroup("test")]).length, 1);
    var s:Entity = Fathom.entities.one([Set.hasGroup("test")]);

    assertEquals(s.x, 0);
    assertEquals(s.y, 2);

    var s:String;

    constructedCount = 0;
    m.loadNewMapAbs(new Vec(0, 0));

    assertEquals(constructedCount, 0);
    assertEquals(Fathom.entities.select([Set.hasGroup("test")]).length, 0);
  }

  public function testDontFreakOutForOutOfMapEntities() {
    var s:Entity;

    m.loadNewMapAbs(new Vec(0, 1));
    s = Fathom.entities.one([Set.hasGroup("test")]);

    s.setPos(new Vec(7, 7));

    m.loadNewMapAbs(new Vec(0, 0));
    m.loadNewMapAbs(new Vec(0, 1));

    s = Fathom.entities.one([Set.hasGroup("test")]);

    assertDotEquals(s.vec(), new Vec(7, 7));
  }

  public function testPersistentItem() {
    var s:Entity;

    m.loadNewMapAbs(new Vec(0, 1));
    s = Fathom.entities.one([Set.hasGroup("test")]);

    s.setPos(new Vec(1, 1));

    m.loadNewMapAbs(new Vec(0, 0));
    m.loadNewMapAbs(new Vec(0, 1));

    s = Fathom.entities.one([Set.hasGroup("test")]);

    assertDotEquals(s.vec(), new Vec(1, 1));
  }
}
