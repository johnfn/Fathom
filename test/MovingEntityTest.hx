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

class GenericBlock extends MovingEntity {
  public function new() {
    super(x, y);
    loadSpritesheet(AllTests.testAnimation, new Vec(25, 25), new Vec(1, 1));
  }

  public override function groups():Set<String> {
    return groupSet.concat("moving");
  }
}

class MovingEntityTest extends haxe.unit.TestCase {
	var m: Map;

  public override function beforeEach() {
    m = new Map(5, 5, 25);
  }

  public override function afterEach() {
    Fathom.destroyAll();
  }

  public function makeDebugMap() {
    m.fromStringArray
      (
        [ "....."
        , "....."
        , "..X.."
        , ".XOX."
        , "..X.."
        ]
      , [ { key: ".", gfx: AllTests.testSprite, spritesheet: new Vec(0, 0) }
        , { key: "X", spc: CollisionResolverTest.Block, spritesheet: new Vec(1, 1) }
        , { key: "O", spc: GenericBlock, spritesheet: new Vec(1, 1) }
        ]
      );
  }

  public function testTouchingBottom(): Void {
    makeDebugMap();

    var block: GenericBlock = cast(Fathom.entities.get([Set.hasGroup("moving")]).first(), GenericBlock);
    block.vel.y = 2;

    CollisionResolver.moveEverything(Fathom.movingEntities());

    assertTrue(block.touchingBottom);
    assertFalse(block.touchingTop);
    assertFalse(block.touchingLeft);
    assertFalse(block.touchingRight);

    Fathom.destroyAll();
  }

  public function testTouchingUp(): Void {
    makeDebugMap();

    var block: GenericBlock = cast(Fathom.entities.get([Set.hasGroup("moving")]).first(), GenericBlock);
    block.vel.y = -2;

    CollisionResolver.moveEverything(Fathom.movingEntities());

    assertFalse(block.touchingBottom);
    assertTrue(block.touchingTop);
    assertFalse(block.touchingLeft);
    assertFalse(block.touchingRight);

    Fathom.destroyAll();
  }

  public function testTouchingLeft(): Void {
    makeDebugMap();

    var block: GenericBlock = cast(Fathom.entities.get([Set.hasGroup("moving")]).first(), GenericBlock);
    block.vel.x = -2;

    CollisionResolver.moveEverything(Fathom.movingEntities());

    assertTrue(block.touchingLeft);

    Fathom.destroyAll();
  }

  public function testTouchingRight(): Void {
    makeDebugMap();

    var block: GenericBlock = cast(Fathom.entities.get([Set.hasGroup("moving")]).first(), GenericBlock);
    block.vel.x = 2;

    CollisionResolver.moveEverything(Fathom.movingEntities());

    assertTrue(block.touchingRight);

    Fathom.destroyAll();
  }

  public function testTouchingMultiple(): Void {
    makeDebugMap();

    var block: GenericBlock = cast(Fathom.entities.get([Set.hasGroup("moving")]).first(), GenericBlock);
    block.vel.x = 2;
    block.vel.y = 2;

    CollisionResolver.moveEverything(Fathom.movingEntities());

    assertTrue(block.touchingRight);
    assertTrue(block.touchingBottom);

    Fathom.destroyAll();
  }

  public function testTouchingMultipleFast(): Void {
    makeDebugMap();

    var block: GenericBlock = cast(Fathom.entities.get([Set.hasGroup("moving")]).first(), GenericBlock);
    block.vel.x = 50;
    block.vel.y = 50;

    CollisionResolver.moveEverything(Fathom.movingEntities());

    assertTrue(block.touchingRight);
    assertTrue(block.touchingBottom);

    Fathom.destroyAll();
  }
}