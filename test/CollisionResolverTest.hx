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

class Block extends Entity {
  public function new() {
    super(0, 0, 25, 25);
  }

  public override function groups():Set<String> {
    return groupSet.concat("block");
  }
}

class FallingBlock extends MovingEntity {
  public function new() {
    super(0, 0, 25, 25);

  	this.vel = new Vec(0, 2);
  }

  public override function groups():Set<String> {
    return groupSet.concat("falling");
  }
}

class CollisionResolverTest extends haxe.unit.TestCase {
  var m: Map;

  public override function beforeEach() {
    m = new Map(5, 5, 25);
  }

  public override function afterEach() {
    Fathom.destroyAll();
  }

  public function testStringArray(): Void {
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

    assertEquals(Fathom.entities.length, 25);
    assertEquals(Fathom.entities.get([Set.hasGroup("block")]).length, 5);

    Fathom.destroyAll();
  }

  public function testSimpleFallingBlock(): Void {
    m.fromStringArray
      (
        [ "..O.."
        , "....."
        , "....."
        , "....."
        , "XXXXX"
        ]
      , [ { color: ".", gfx: AllTests.testSprite, spritesheet: new Vec(0, 0) }
		    , { color: "X", spc: Block, spritesheet: new Vec(1, 1) }
		    , { color: "O", spc: FallingBlock, spritesheet: new Vec(1, 1) }
		    ]
		  );

		var block: FallingBlock = cast(Fathom.entities.get([Set.hasGroup("falling")]).first(), FallingBlock);

    CollisionResolver.moveEverything(Fathom.movingEntities());

    assertEquals(block.y, 2);

    Fathom.destroyAll();
  }
}
