#if nme
import nme.display.Sprite;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.Assets;
import nme.events.Event;
#else
import starling.display.Sprite;
import flash.display.BitmapData;
import flash.display.Bitmap;
#end

class AllTests extends Sprite {
  public static var stage;

  public static var testSprite:String = "test/testsprite.png";
  public static var testMap:String = "test/testmap.png";
  public static var testAnimation:String = "test/testanimation.png";

  public static function main() {
    Fathom.rootDir = "";
    Fathom.initialize(test);
  }

  static function test() {
    //TODO: Figure out why I need this...
    haxe.Timer.delay(function() {
      var r = new haxe.unit.TestRunner();

#if cpp
      r.add(new ReloadedGraphicTest());
#end

      r.add(new SetTest());
      r.add(new SuperObjectHashTest());
      r.add(new RectTest());
      r.add(new VecTest());
      r.add(new CameraTest());
      r.add(new GraphicTest());
      r.add(new EntityTest());
      r.add(new MapTest());
      r.add(new AnimationTest());
      r.add(new ColorTest());
      r.add(new KeyTest());

      r.run();
    }, 250);

  }
}
