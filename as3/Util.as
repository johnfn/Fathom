package {
  public class Util {
    import flash.system.fscommand;
    import flash.utils.*;
    import flash.events.KeyboardEvent;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.utils.getQualifiedClassName;

    public static var uid:Number = 0;

    public static var KeyDown:MagicKeyObject;
    public static var KeyJustDown:MagicKeyObject;

    public static var KeyUp:MagicKeyObject;
    public static var KeyJustUp:MagicKeyObject;

    //TODO: Should move Array.prototype stuff into separate ArrayExtensions class.


    /* Ties each element e in the array to a value k(e) and sorts the array
       how you'd sort the values from low to high. */
    Array.prototype.sortBy = function(k:Function):void {
      // TODO: Calls k O(n^2) times; can reduce to O(n) with little trouble.

      this.sort(function(a:*, b:*):int {
        return k(a) - k(b);
      });
    }

    Array.prototype.contains = function(val:*):Boolean {
      return this.getIndex(val) != -1;
    }

    // Array::indexOf only works with String values.
    Array.prototype.getIndex = function(val:*):int {
      for (var i:int = 0; i < this.length; i++) {
        if (this[i] == val) return i;
      }

      return -1;
    }

    // Remove all occurances of item from array.
    Array.prototype.remove = function(item:*):void {
      for (var i:int = 0; i < this.length; i++) {
        if (this[i] == item) {
          this.splice(i, 1);
          i--;
        }
      }
    }

    Array.prototype.extend = function(a:Array):void {
      for (var i:int = 0; i < a.length; i++) {
        this.push(a[i]);
      }
    }

    Array.prototype.setPropertyIsEnumerable('sortBy', false);
    Array.prototype.setPropertyIsEnumerable('contains', false);
    Array.prototype.setPropertyIsEnumerable('collect', false);
    Array.prototype.setPropertyIsEnumerable('getIndex', false);
    Array.prototype.setPropertyIsEnumerable('remove', false);
    Array.prototype.setPropertyIsEnumerable('extend', false);



    public static function id(x:*):* {
      return x;
    }

    // Divide a by b, always rounding up unless a % b == 0.
    // Looks simple, doesn't it? But see: http://stackoverflow.com/questions/921180/how-can-i-ensure-that-a-division-of-integers-is-always-rounded-up
    public static function divRoundUp(a:Number, b:Number):Number {
      return (a + b - 1) / b;
    }

    public static function sign(x:Number):Number {
      if (x > 0) return  1;
      if (x < 0) return -1;
                 return  0;
    }

    // TODO: Rename -> clamp
    public static function bind(x:Number, low:Number, high:Number):Number {
      if (x < low) return low;
      if (x > high) return high;
      return x;
    }

    public static function className(c:*):String {
      var qualifiedName:String = getQualifiedClassName(c);
      if (qualifiedName.indexOf(":") == -1) return qualifiedName;
      var split:Array = qualifiedName.split(":");

      return split[split.length - 1];
    }

    public static function printStackTrace():void {
      var e:Error = new Error("[stack trace requested - no error]");
      Util.log(e.getStackTrace());
    }

    /* The reason for this wrapper method is to separate debugging messages
       that should eventually be removed from more serious error logs, which
       should stay. For instance, if you're checking the x value of an Entity, do
       trace (e.x). If you just failed an assertion, do Util.log("Assertion failed!").

       We separate them so that it's easy to search for "trace" with a following "("
       to find debugging messages you need to remove.
       */

    public static function log(...args):void {
      trace.apply(null, args);
    }

    // Short for print (like in Ruby). Attempts to print a human readable representation
    // of the given object, for any object type.
    public static function p(o:*):void {
      Util.log(Util.pHelper(o));
    }

    // Recursive helper method for Util.p.
    private static function pHelper(o:*):String {
      var result:String;

      if (Util.className(o) == "Object") {
        var object:Object = o as Object;
        result = "{ "

        for (var k:String in object) {
          result += k + ": " + pHelper(object[k]) + ", ";
        }

        result = result.slice(0, -2) + " ";

        result += "}";
      } else if (Util.className(o) == "Array") {
        var arr:Array = o as Array;
        result = "["

        for (var i:int = 0; i < arr.length; i++) {
          result += pHelper(arr[i]) + (i == arr.length - 1 ? "" : ", ");
        }

        result += "]";
      } else if (o == null) {
        result = "null";
      } else {
        result = o.toString();
      }

      return result;
    }

    public static function assert(b:Boolean):void {
      if (!b) {
        var e:Error = new Error("Assertion failed.");
        Util.log(e.getStackTrace());
        fscommand("quit");
        throw e;
      }
    }

    public static function epsilonEq(a:Number, b:Number, threshold:Number):Boolean {
      return Math.abs(a - b) < threshold;
    }

    public static function getUniqueID():Number {
      return ++uid;
    }

    // This function is currently broken if val is an object, and there's no
    // easy way to fix it.

    //public static function make2DArrayVal(width:int, height:int, val:*):Array {
    //  return make2DArrayFn(width, height, function():* { return val; });
    //}

    public static function make2DArrayFn(width:int, height:int, fn:Function):Array {
      var result:Array = new Array(width);

      for (var i:int = 0; i < width; i++) {
        result[i] = new Array(height);
        for (var j:int = 0; j < height; j++) {
          result[i][j] = fn(i, j);
        }
      }

      return result;
    }

    public static function foreach2D(a:Array, fn:Function):void {
      for (var i:int = 0; i < a.length; i++) {
        for (var j:int = 0; j < a[0].length; j++) {
          fn(i, j, a[i][j]);
        }
      }
    }

    // With thanks to http://kirill-poletaev.blogspot.com/2010/07/rotate-object-to-mouse-using-as3.html
    public static function rotateToFace(pointer:Vec, target:Vec):Number {
      var cx:Number = target.x - pointer.x;
      var cy:Number = target.y - pointer.y;

      var radians:Number = Math.atan2(cy, cx);
      var degrees:Number = radians * 180 / Math.PI;

      return degrees;
    }

    public static function make2DArray(width:int, height:int, defaultValue:*):Array {
      return make2DArrayFn(width, height, function(x:int, y:int):* { return defaultValue; });
    }

    public static function movementVector():Vec {
      var x:int = (KeyDown.Right ? 1 : 0) - (KeyDown.Left ? 1 : 0);
      var y:int = (KeyDown.Down  ? 1 : 0) -   (KeyDown.Up ? 1 : 0);

      return new Vec(x, y);
    }

    public static function randRange(low:int, high:int):int {
      return low + Math.floor(Math.random() * (high - low));
    }

    public static function randNum(low:Number, high:Number):Number {
      return low + (Math.random() * (high - low));
    }
  }
}
