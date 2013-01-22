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
  public function new(x: Int, y: Int) {
    super(x, y, 25, 25);
    loadSpritesheet(AllTests.testAnimation, new Vec(25, 25), new Vec(1, 1));
  }

  public override function groups():Set<String> {
    return groupSet.concat("block");
  }
}

class FallingBlock extends MovingEntity {
  public function new() {
    super(x, y, 25, 25);
    loadSpritesheet(AllTests.testAnimation, new Vec(25, 25), new Vec(1, 1));

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
  	// The block should fall.

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

  public function testSimpleCollision(): Void {
  	// The block should not fall through the ground.

    m.fromStringArray
      (
        [ "....."
        , "....."
        , "....."
        , "..O.."
        , "XXXXX"
        ]
      , [ { color: ".", gfx: AllTests.testSprite, spritesheet: new Vec(0, 0) }
        , { color: "X", spc: Block, spritesheet: new Vec(1, 1) }
        , { color: "O", spc: FallingBlock, spritesheet: new Vec(1, 1) }
        ]
      );

    var block: FallingBlock = cast(Fathom.entities.get([Set.hasGroup("falling")]).first(), FallingBlock);

    for (x in 0...5) {
	    CollisionResolver.moveEverything(Fathom.movingEntities());
	  }

    assertEquals(block.y, 75);

    Fathom.destroyAll();
  }

  public function testSlightlyMoreComplexCollision(): Void {
  	// Blocks should stack and not fall through other blocks.

    m.fromStringArray
      (
        [ "....."
        , "....."
        , "..O.."
        , "..O.."
        , "XXXXX"
        ]
      , [ { color: ".", gfx: AllTests.testSprite, spritesheet: new Vec(0, 0) }
        , { color: "X", spc: Block, spritesheet: new Vec(1, 1) }
        , { color: "O", spc: FallingBlock, spritesheet: new Vec(1, 1) }
        ]
      );

    var blocks: Set<Entity> = Fathom.entities.get([Set.hasGroup("falling")]);

    for (x in 0...5) {
	    CollisionResolver.moveEverything(Fathom.movingEntities());
	  }

    for (b in blocks) {
    	assertTrue(b.y % 25 == 0);
    }

    Fathom.destroyAll();
  }

  public function testPixelPerfectFalling(): Void {
  	// When pushed, the block should fall into the crevasse.

    m.fromStringArray
      (
        [ "....."
        , "....."
        , ".O..."
        , ".X.X."
        , "XXXXX"
        ]
      , [ { color: ".", gfx: AllTests.testSprite, spritesheet: new Vec(0, 0) }
        , { color: "X", spc: Block, spritesheet: new Vec(1, 1) }
        , { color: "O", spc: FallingBlock, spritesheet: new Vec(1, 1) }
        ]
      );

    var block: FallingBlock = cast(Fathom.entities.get([Set.hasGroup("falling")]).first(), FallingBlock);
    for (x in 0...50) {
    	block.vel.x = 4;
	    CollisionResolver.moveEverything(Fathom.movingEntities());
	  }

	  assertEquals(block.x, 50);
	  assertEquals(block.y, 75);

    Fathom.destroyAll();
  }
}
