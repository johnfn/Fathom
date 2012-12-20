package {
  import flash.utils.Proxy;
  import flash.utils.Dictionary;
  import flash.utils.flash_proxy;

  // TODO: High level stuff - should have some consistency with mutable/immutable
  // function calls.

  // This class mimics the Set data type found in languages like Python.
  public class Set extends Proxy {

    private var contents:Dictionary = new Dictionary();
    private var _length:int = 0;

    public function Set(init:Array = null) {
        if (init == null) return;

        for (var i:int = 0; i < init.length; i++) {
            add(init[i]);
        }
    }

    override flash_proxy function hasProperty(name:*):Boolean {
        return name in contents;
    }

    /* These two functions are the special sauce that make the for-in loop work. */

    private var startedIterating:Boolean = false;
    private var iterationList:Array = [];

    override flash_proxy function nextNameIndex(index:int):int {
        if (index == 0 && startedIterating) {
            throw new Error("Sorry, can't double loop through the same Set. I can fix this, it's just a minor hassle.");
        }

        if (!startedIterating) {
            startedIterating = true;

            for (var k:* in contents) {
                iterationList.push(k);
            }
        }

        if (index >= iterationList.length) {
            startedIterating = false;
            return 0;
        }

        return index + 1;
    }

    override flash_proxy function nextValue(index:int):* {
        return iterationList[index - 1];
    }

    public function add(item:*):void {
        if (startedIterating && !iterationList.contains(item)) {
            iterationList.push(item);
        }

        if (!contents[item]) {
            _length++;
        }

        contents[item] = true;
    }

    public function remove(item:*):void {
        if (!contents[item]) {
            throw new Error("Set#remove called on non-existant item");
        }

        if (startedIterating && iterationList.contains(item)) {
            iterationList.remove(item);
        }

        delete contents[item];
        _length--;
    }

    public function contains(item:*):Boolean {

        // This looks redundant, but if we don't have the item
        // contents[item] == undefined.

        return contents[item] == true;
    }

    public static function merge(s1:Set, s2:Set):Set {
        var result:Set = new Set();
        var k:*;

        for (k in s1.contents) {
            result.add(k);
        }

        for (k in s2.contents) {
            result.add(k);
        }

        return result;
    }

    public function extend(other:Set):void {
        for (var k:* in other.contents) {
            add(k);
        }
    }

    public function concat(...args):Set {
        var result:Set = new Set();
        var k:*;

        for (k in contents) {
            result.add(k);
        }

        for (var i:int = 0; i < args.length; i++) {
            result.add(args[i]);
        }

        return result;
    }

    public function filter(f:Function):Set {
        var result:Set = new Set();

        for (var k:* in contents) {
            if (f(k)) {
                result.add(k);
            }
        }

        return result;
    }

    public function get length():int {
        return _length;
    }

    public function toArray():Array {
      var result:Array = [];

      for (var k:* in contents) {
        result.push(k);
      }

      return result;
    }

    public function toString():String {
        var result:String = "{ ";

        for (var k:* in contents) {
            result += k.toString() + ", ";
        }

        result += " }";

        return result;
    }
  }
}
