import flash.display.BitmapData;
import Graphic;

using Lambda;

class MapTest extends haxe.unit.TestCase {

  public var m:Map;

  override public function setup() {
    Fathom.initialize(flash.Lib.current.stage);

    m = new Map(2, 2, 2);

    m.fromImage(AllTests.TestMap, [], {
      (new Color(0, 0, 0).toString())   : { gfx: AllTests.MyBitmapData, spritesheet: new Vec(0, 0) }
    , (new Color(0, 0, 255).toString()) : { gfx: AllTests.MyBitmapData, spritesheet: new Vec(1, 0) }
    });
  }

  override public function tearDown() {
    Fathom.destroyAll();
  }

  public function testMapLoad() {

  }
}

