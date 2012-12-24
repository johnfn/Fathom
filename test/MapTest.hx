import flash.display.BitmapData;
import Graphic;

using Lambda;

class MapTest extends haxe.unit.TestCase {
  public var m:Map;

  override public function setup() {
    Fathom.initialize(flash.Lib.current.stage);

    m = new Map(2, 2, 2);

    m.fromImage(AllTests.TestMap, [], [
      { color: "#ffffff", gfx: AllTests.MyBitmapData, spritesheet: new Vec(0, 0) }
    , { color: "#0000ff", gfx: AllTests.MyBitmapData, spritesheet: new Vec(1, 0) }
    ]);

    m.loadNewMap(new Vec(0, 0));
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

}

