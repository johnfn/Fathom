import fathom.CameraFocus;
import fathom.ParallaxLayer;
import fathom.Util;
import fathom.Entity;
import fathom.Vec;
import fathom.Fathom;
import fathom.Graphic;

import nme.display.BitmapData;
import nme.geom.Point;

class ParallaxLayerTest extends haxe.unit.TestCase {
  var g:Entity;

  public function ensureValid() {
    var sw: Int = Fathom.actualStage.stageWidth;
    var sh: Int = Fathom.actualStage.stageHeight;

    var bd: BitmapData = Graphic.takeScreenshot();

    // check borders to make sure that there's nothing wrong
    assertTrue(bd.getPixel(5, 5) == 0x000000);
    assertTrue(bd.getPixel(sw - 5, 5) == 0x000000);
    assertTrue(bd.getPixel(5, sh - 5) == 0x000000);
    assertTrue(bd.getPixel(sw - 5, sh - 5) == 0x000000);
  }

  public function testLoadBig() {
    var pl: ParallaxLayer = new ParallaxLayer(AllTests.testBlack222x222);

    ensureValid();

    Fathom.destroyAll();
  }

  public function testLoadSmall() {
    var pl: ParallaxLayer = new ParallaxLayer(AllTests.testBlack8x8);

    ensureValid();

    Fathom.destroyAll();
  }

  public function testMoveBig() {
    var pl: ParallaxLayer = new ParallaxLayer(AllTests.testBlack222x222);
    for (x in 0...5) {
      pl.update();
      ensureValid();
    }

    Fathom.destroyAll();
  }

  public function testMoveSmall() {
    var pl: ParallaxLayer = new ParallaxLayer(AllTests.testBlack8x8);
    for (x in 0...8) {
      pl.update();
      ensureValid();
    }

    Fathom.destroyAll();
  }

  public function testdxdy() {
    var pl: ParallaxLayer = new ParallaxLayer(AllTests.testCheckerboard8x8);

    pl.dx = 2;
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0xffffff);
    pl.update();
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0x000000);
    pl.update();
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0xffffff);
    pl.dx = -1;

    pl.update();
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0xffffff);
    pl.update();
    assertEquals(Graphic.takeScreenshot().getPixel(0, 0), 0x000000);
  }
}

