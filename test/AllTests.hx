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

#if flash
@:bitmap("testsprite.png") class TestSprite extends flash.display.BitmapData {}
@:bitmap("testmap.png") class TestMap extends flash.display.BitmapData {}
@:bitmap("testanimation.png") class TestAnimation extends flash.display.BitmapData {}
#end

class AllTests extends Sprite {
  public static var stage;

  public static var testSprite:BitmapData;
  public static var testMap:BitmapData;
  public static var testAnimation:BitmapData;

  public static function main() {

#if flash
    testSprite    = Type.createInstance(TestSprite, []);
    testMap       = Type.createInstance(TestMap, []);
    testAnimation = Type.createInstance(TestAnimation, []);
#else
    testSprite    = Assets.getBitmapData("test/testsprite.png");
    testMap       = Assets.getBitmapData("test/testmap.png");
    testAnimation = Assets.getBitmapData("test/testanimation.png");
#end

    Fathom.initialize(test);
  }

  static function test() {
    //TODO: Figure out why I need this...
    haxe.Timer.delay(function() {
      var r = new haxe.unit.TestRunner();

      r.add(new SetTest());
      r.add(new SuperObjectHashTest());
      r.add(new RectTest());
      r.add(new VecTest());
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
