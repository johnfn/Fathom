@:bitmap("testsprite.png") class MyBitmapData extends flash.display.BitmapData {}
@:bitmap("testmap.png") class TestMap extends flash.display.BitmapData {}

class AllTests {
  static function main() {
    var r = new haxe.unit.TestRunner();
    r.add(new SetTest());
    r.add(new VecTest());
    r.add(new GraphicTest());
    r.add(new EntityTest());

    r.run();
  }
}
