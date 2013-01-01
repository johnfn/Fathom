import starling.display.Sprite;

@:bitmap("testsprite.png") class MyBitmapData extends flash.display.BitmapData {}
@:bitmap("testmap.png") class TestMap extends flash.display.BitmapData {}
@:bitmap("testanimation.png") class TestAnimation extends flash.display.BitmapData {}

class AllTests extends Sprite {
  public static function main() {
    Fathom.initialize(flash.Lib.current.stage, test);
  }

  static function test() {
    Fathom.camera.setFocus(new Vec(flash.Lib.current.stage.stageWidth/2, flash.Lib.current.stage.stageHeight/2));

    var e:Entity = new Entity(0, 0, 50, 50).loadSpritesheet(AllTests.TestAnimation, new Vec(25, 25)).setTile(0, 0);


    /*
    var r = new haxe.unit.TestRunner();

    r.add(new SetTest());
    r.add(new RectTest());
    r.add(new VecTest());
    r.add(new GraphicTest());
    //r.add(new EntityTest());
    //r.add(new MapTest());
    //r.add(new AnimationTest());

    r.run();
    */
  }
}
