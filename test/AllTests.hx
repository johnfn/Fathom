#if nme
import nme.display.Sprite;
import nme.display.Bitmap;
import nme.Assets;
import nme.events.Event;
#else
import starling.display.Sprite;
import flash.display.BitmapData;
import flash.display.Bitmap;
#end

#if flash
@:bitmap("testsprite.png") class MyBitmapData extends flash.display.BitmapData {}
@:bitmap("testmap.png") class TestMap extends flash.display.BitmapData {}
@:bitmap("testanimation.png") class TestAnimation extends flash.display.BitmapData {}
#end

class AllTests extends Sprite {
  public static var stage;

#if flash
  public static var testSprite:BitmapData;
  public static var testMap:BitmapData;
  public static var testAnimation:BitmapData;
#end

  public static function main() {

#if flash
    testSprite = Type.createInstance(MyBitmapData, []);
    testMap = Type.createInstance(TestMap, []);
    testAnimation = Type.createInstance(TestAnimation, []);

    Fathom.initialize(flash.Lib.current.stage, test);
#else
    nme.Lib.current.addChild(new AllTests());
#end
  }

#if nme
  public function new () {
    super ();
    addEventListener(Event.ADDED_TO_STAGE, this_onAddedToStage);
  }

  private function this_onAddedToStage(e):Void {
    Fathom.initialize(stage);
    AllTests.stage = this;
    Fathom.container = Entity.fromDO(this).addGroup("container");

    test();
  }
#end

  static function test() {
#if nme
    var g:Entity = new Entity(200, 200, 100, 100);
    g.loadSpritesheet(Assets.getBitmapData("test/testanimation.png"));
    return;
#end
    //g.setTile(0, 0);

    //TODO: Figure out why I need this...
    haxe.Timer.delay(function() {
#if flash9
        Fathom.camera.setFocus(new Vec(flash.Lib.current.stage.stageWidth/2, flash.Lib.current.stage.stageHeight/2));
#end

        var r = new haxe.unit.TestRunner();

        r.add(new SetTest());
        r.add(new SuperObjectHashTest());
        r.add(new RectTest());
        r.add(new VecTest());
#if flash9
        r.add(new GraphicTest());
        r.add(new EntityTest());
        r.add(new MapTest());
        r.add(new AnimationTest());
        r.add(new CameraTest());
        r.add(new ColorTest());
#end

        r.run();

        //nme.Lib.close();
    }, 250);

  }
}
