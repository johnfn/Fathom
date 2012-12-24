import flash.display.BitmapData;
import Graphic;

using Lambda;

class SpecialThing extends Entity {
  public function new() {
    super();
    //e.loadSpritesheet(AllTests.MyBitmapData, new Vec(_tileSize, _tileSize), ssLoc);

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
    Fathom.initialize(flash.Lib.current.stage);


    m = new Map(2, 2, 2);

    m.fromImage(AllTests.TestMap, [], [
      { color: "#ffffff", gfx: AllTests.MyBitmapData, spritesheet: new Vec(0, 0) }
    , { color: "#0000ff", gfx: AllTests.MyBitmapData, spritesheet: new Vec(1, 0) }
    , { color: "#ff0000", gfx: SpecialThing, spritesheet: new Vec(1, 1) } //represented as green
    ]);

    m.loadNewMap(new Vec(0, 0));
    constructedCount = 0;
  }

  override public function tearDown() {
    Fathom.destroyAll();
  }

  public function testMapLoad() {
    assertEquals(m.graphics.getPixel(0, 0), 0x0000ff);
  }

  public function testMapChangeDiff() {
    m.loadNewMap(new Vec(1, 0));
    assertEquals(m.graphics.getPixel(0, 0), 0xFFFFFF);
    m.loadNewMap(new Vec(-1, 0));
    m.loadNewMap(new Vec(0, 1)); // now at map (0, 1)
    assertEquals(m.graphics.getPixel(0, 0), 0xFFFFFF);
    m.loadNewMap(new Vec(1, 0)); // now at map (1, 1)
    assertEquals(m.graphics.getPixel(0, 0), 0x0000ff);
  }

  public function testMapChangeAbs() {
    m.loadNewMapAbs(new Vec(1, 0));
    assertEquals(m.graphics.getPixel(0, 0), 0xFFFFFF);
    m.loadNewMapAbs(new Vec(0, 1)); // now at map (0, 1)
    assertEquals(m.graphics.getPixel(0, 0), 0xFFFFFF);
    m.loadNewMapAbs(new Vec(1, 1)); // now at map (1, 1)
    assertEquals(m.graphics.getPixel(0, 0), 0x0000ff);
  }

  public function testSpecialItems() {
    m.loadNewMap(new Vec(0, 1));

    assertEquals(constructedCount, 1);

    assertEquals(Fathom.entities.select([Set.hasGroup("test")]).length, 1);
    var s:Entity = Fathom.entities.one([Set.hasGroup("test")]);

    assertEquals(s.x, 0);
    assertEquals(s.y, 2);
  }
}

