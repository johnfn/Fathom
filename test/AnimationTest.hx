import flash.display.BitmapData;
import Rect;

using Lambda;

class AnimationTest extends haxe.unit.TestCase {
  var g:Graphic;

  // The animation test graphic looks like this:
  // RED BLACK GREEN WHITE
  override public function setup() {
    g = new Graphic(0, 0);
    g.loadSpritesheet(AllTests.TestAnimation, new Vec(25, 25), new Vec(0, 0));
    g.animations.ticksPerFrame = 1;
  }

  override public function tearDown() {

  }

  public function testSimpleAnimations() {
    g.animations.addAnimationXY("a", [[0,0], [0,1], [0,2], [0,3]]);
    g.animations.play("a");

    assertEquals(g.animations.currentFrame, 0);
    assertEquals(g.getPixel(0, 0), 0xFF0000);

    g.update();
    assertEquals(g.animations.currentFrame, 1);
    assertEquals(g.getPixel(0, 0), 0x000000);

    g.update();
    assertEquals(g.animations.currentFrame, 2);
    assertEquals(g.getPixel(0, 0), 0x0000FF);

    g.update();
    assertEquals(g.animations.currentFrame, 3);
    assertEquals(g.getPixel(0, 0), 0xFFFFFF);

    g.update();
    assertEquals(g.animations.currentFrame, 0);
    assertEquals(g.getPixel(0, 0), 0xFF0000);
  }
}

