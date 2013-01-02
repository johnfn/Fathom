#if nme
import nme.display.Sprite;
import nme.display.Shape;
#else
import starling.display.Sprite;
import flash.display.BitmapData;
import flash.display.Bitmap;
#end

#if nme

#else
@:bitmap("testsprite.png") class MyBitmapData extends flash.display.BitmapData {}
@:bitmap("testmap.png") class TestMap extends flash.display.BitmapData {}
@:bitmap("testanimation.png") class TestAnimation extends flash.display.BitmapData {}
#end

class AllTests extends Sprite {
  public static function main() {

#if flash9
    Fathom.initialize(flash.Lib.current.stage, test);
#else
    test();
#end
  }

  static function test() {
    //TODO: Figure out why I need this...

    haxe.Timer.delay(function() {
#if flash9
        Fathom.camera.setFocus(new Vec(flash.Lib.current.stage.stageWidth/2, flash.Lib.current.stage.stageHeight/2));
#end

        var r = new haxe.unit.TestRunner();
        r.add(new SetTest());
#if flash9
        r.add(new RectTest());
        r.add(new VecTest());
        r.add(new GraphicTest());

        r.add(new EntityTest());
        r.add(new MapTest());
        r.add(new AnimationTest());
        r.add(new CameraTest());
        r.add(new ColorTest());
#end

        r.run();
    }, 250);

  }
}
