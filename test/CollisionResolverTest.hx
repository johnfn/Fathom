import fathom.Text;
import fathom.Map;
import fathom.Fathom;
import fathom.Graphic;

import nme.display.BitmapData;
import nme.geom.Point;
import flash.geom.Matrix;

class CollisionResolverTest extends haxe.unit.TestCase {
  var m: Map;

  public override function beforeEach() {
    m = new Map(5, 5, 25);
  }

  public override function afterEach() {
    Fathom.destroyAll();
  }
}

