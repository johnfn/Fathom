import fathom.Text;
import fathom.CollisionResolver;
import fathom.Vec;
import fathom.Set;
import fathom.Entity;
import fathom.Map;
import fathom.Fathom;
import fathom.Graphic;
import fathom.MovingEntity;

import nme.display.BitmapData;
import nme.geom.Point;
import flash.geom.Matrix;

class MovingEntityTest extends haxe.unit.TestCase {
	var m: Map;

  public override function beforeEach() {
    m = new Map(5, 5, 25);
  }

  public override function afterEach() {
    Fathom.destroyAll();
  }

  public function testSimpleFallingBlock(): Void {

    m.fromStringArray
      (
        [ "....."
        , "....."
        , "....."
        , "..O.."
        , "XXXXX"
        ]
      , [ { key: ".", gfx: AllTests.testSprite, spritesheet: new Vec(0, 0) }
        , { key: "X", spc: CollisionResolverTest.Block, spritesheet: new Vec(1, 1) }
        , { key: "O", spc: CollisionResolverTest.FallingBlock, spritesheet: new Vec(1, 1) }
        ]
      );

    var block: CollisionResolverTest.FallingBlock = cast(Fathom.entities.get([Set.hasGroup("falling")]).first(), CollisionResolverTest.FallingBlock);

    CollisionResolver.moveEverything(Fathom.movingEntities());

    assertTrue(block.touchingBottom);
    assertFalse(block.touchingTop);
    assertFalse(block.touchingLeft);
    assertFalse(block.touchingRight);

    Fathom.destroyAll();
  }
}