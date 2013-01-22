import fathom.Text;
import fathom.Vec;
import fathom.Set;
import fathom.Entity;
import fathom.Map;
import fathom.Fathom;
import fathom.Graphic;

import nme.display.BitmapData;
import nme.geom.Point;
import flash.geom.Matrix;

class Block extends Entity {
  public function new() {
    super(0, 0, 2, 2);

    MapTest.constructedCount++;
  }

  public override function groups():Set<String> {
    return groupSet.concat("test");
  }
}

class CollisionResolverTest extends haxe.unit.TestCase {
  var m: Map;

  public override function beforeEach() {
    m = new Map(5, 5, 25);
    m.fromStringArray
      (
        [ "....."
        , "....."
        , "....."
        , "....."
        , "XXXXX"
        ]
      , [ { color: ".", gfx: AllTests.testSprite, spritesheet: new Vec(0, 0) }
		    , { color: "X", spc: Block, spritesheet: new Vec(1, 1) }
		    ]
		  );
  }

  public override function afterEach() {
    Fathom.destroyAll();
  }

  public function testStringArray(): Void {
    assertEquals(Fathom.entities.length, 25);
    assertEquals(Fathom.entities.get([Set.hasGroup("test")]).length, 5);
  }
}

