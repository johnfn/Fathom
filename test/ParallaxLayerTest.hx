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
      for (y in 0...20) {
        pl.update();
      }
      ensureValid();
    }

    Fathom.destroyAll();
  }

  public function testMoveSmall() {
    var pl: ParallaxLayer = new ParallaxLayer(AllTests.testBlack8x8);
    for (x in 0...8) {
      for (y in 0...20) {
        pl.update();
      }
      ensureValid();
    }

    Fathom.destroyAll();
  }
}

