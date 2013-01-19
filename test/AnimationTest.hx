import hx.AnimationHandler;
import hx.Entity;

using Lambda;

class AnimationTest extends haxe.unit.TestCase {
  var g:Entity;

  // The animation test graphic looks like this:
  // RED BLACK GREEN WHITE
  public override function globalSetup() {
    g = new Entity(0, 0, 16, 16);
    g.loadSpritesheet(AllTests.testAnimation, new Vec(16, 16), new Vec(0, 0));
    g.animations.ticksPerFrame = 1;
  }

  override public function globalTeardown() {
    Fathom.destroyAll();
  }

  public function testSimpleAnimations() {
    g.animations.addAnimationXY("a", [{x: 0, y: 0}, {x: 1, y: 0}, {x: 2, y: 0}, {x: 3, y: 0}]);
    g.animations.play("a");

    assertEquals(g.animations.currentFrame, 0);
    assertEquals(g.getPixel(0, 0), 0xFF0000);

    g.update();
    assertEquals(g.animations.currentFrame, 1);
    assertEquals(g.getPixel(0, 0), 0x000000);

    g.update();
    assertEquals(g.animations.currentFrame, 2);
    assertEquals(g.getPixel(0, 0), 0x00FF00);

    g.update();
    assertEquals(g.animations.currentFrame, 3);
    assertEquals(g.getPixel(0, 0), 0xFFFFFF);

    g.update();
    assertEquals(g.animations.currentFrame, 0);
    assertEquals(g.getPixel(0, 0), 0xFF0000);
  }

  public function testStop() {
    g.animations.addAnimationXY("a", [{x: 0, y: 0}, {x: 1, y: 0}, {x: 2, y: 0}, {x: 3, y: 0}]);
    g.animations.play("a");

    assertEquals(g.animations.currentFrame, 0);
    assertEquals(g.getPixel(0, 0), 0xFF0000);

    g.animations.stop();

    for (x in 0...3) {
      g.update();
      assertEquals(g.animations.currentFrame, 0);
      assertEquals(g.getPixel(0, 0), 0xFF0000);
    }
  }

  public function testTwoAnimations() {
    g.animations.addAnimationXY("a", [{x: 0, y: 0}]);
    g.animations.addAnimationXY("b", [{x: 1, y: 0}]);

    g.animations.play("a");
    assertEquals(g.animations.currentFrame, 0);
    assertEquals(g.getPixel(0, 0), 0xFF0000);

    g.animations.play("b");
    // It should have instantly switched to b's first frame.
    assertEquals(g.animations.currentFrame, 0);
    assertEquals(g.getPixel(0, 0), 0x000000);
  }

  public function testAndThen() {
    var tester:Int = 0;
    var test:Void -> Void = function() {
      ++tester;
    }

    g.animations.addAnimationXY("a", [{x: 0, y: 0}, {x: 1, y: 0}]);
    g.animations.play("a").andThen(test);

    assertEquals(tester, 0);
    g.update();
    assertEquals(tester, 0);
    g.update();
    assertEquals(tester, 1);

  }
}

