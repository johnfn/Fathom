class AllTests {
  static function main() {
    var r = new haxe.unit.TestRunner();
    r.add(new SetTest());
    r.add(new VecTest());
    r.add(new GraphicTest());

    r.run();
  }
}
