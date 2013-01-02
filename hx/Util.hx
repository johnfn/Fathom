import flash.events.KeyboardEvent;
import flash.display.DisplayObject;
import flash.display.Sprite;
import haxe.Stack;

class Util {

	static public var uid : Float = 0;
	static public var KeyDown : MagicKeyObject;
	static public var KeyJustDown : MagicKeyObject;
	static public var KeyUp : MagicKeyObject;
	static public var KeyJustUp : MagicKeyObject;
	//TODO: Should move Array.prototype stuff into separate ArrayExtensions class.
	/* Ties each element e in the array to a value k(e) and sorts the array
   how you'd sort the values from low to high. */

    // Array::indexOf only works with String values.
	// Remove all occurances of item from array.
	static public function id(x : Dynamic) : Dynamic {
		return x;
	}

	// Divide a by b, always rounding up unless a % b == 0.
  // Looks simple, doesn't it? But see: http://stackoverflow.com/questions/921180/how-can-i-ensure-that-a-division-of-integers-is-always-rounded-up
  static public function divRoundUp(a : Float, b : Float) : Float {
		return (a + b - 1) / b;
	}

	static public function sign(x : Float) : Float {
		if(x > 0)
			return 1;
		if(x < 0)
			return -1;
		return 0;
	}

	// TODO: Rename -> clamp
	static public function bind(x : Float, low : Float, high : Float) : Float {
		if(x < low)
			return low;
		if(x > high)
			return high;
		return x;
	}

	static public function className<T>(c : T) : String {
		return Type.getClassName(Type.getClass(c));
	}

	static public function printStackTrace() : Void {
		Util.log(haxe.Stack.toString(haxe.Stack.exceptionStack()));
	}

	/* The reason for this wrapper method is to separate debugging messages
       that should eventually be removed from more serious error logs, which
       should stay. For instance, if you're checking the x value of an Entity, do
       trace (e.x). If you just failed an assertion, do Util.log("Assertion failed!").

       We separate them so that it's easy to search for "trace" with a following "("
       to find debugging messages you need to remove.
       */
    static public function log(s:String) : Void {
    	trace(s);
	}

	// Short for print (like in Ruby). Attempts to print a human readable representation
	// of the given object, for any object type.
	static public function p(o : Dynamic) : Void {
		Util.log(Util.pHelper(o));
	}

	// Recursive helper method for Util.p.
	static function pHelper(o : Dynamic) : String {
		var result : String;
		if(Util.className(o) == "Object")  {
			result = "{ ";
			for(k in Reflect.fields(o)) {
				result += k + ": " + pHelper(Reflect.field(o, k)) + ", ";
			}

			// result = result.slice(0, -2) + " ";
			result += "}";
		} else if (Util.className(o) == "flash.utils.TypedDictionary") {
#if flash
			var td:flash.utils.TypedDictionary<Dynamic, Dynamic> = cast(o, flash.utils.TypedDictionary<Dynamic, Dynamic>);
			result = "{ ";

			untyped {
				for (k in td) {
					result += k + ": " + o + ",";
				}
			}

			result += "}";
#else
			result = "WHAT IN GODS NAME HAPPENED HERE.";
#end
		} else if(Util.className(o) == "Array")  {
			var arr : Array<Dynamic> = try cast(o, Array<Dynamic>) catch(e:Dynamic) null;
			result = "[";
			var i : Int = 0;
			while(i < arr.length) {
				result += pHelper(arr[i]) + (i == arr.length - (1) ? "" : ", ");
				i++;
			}
			result += "]";
		}

		else if(o == null)  {
			result = "null";
		}

		else  {
			result = o.toString();
		}

		return result;
	}

	static public function assert(b : Bool, ?s: String) : Void {
		if(!b)  {
			Util.log("Assertion failed" + s);
			Util.printStackTrace();
			throw "Assertion failed: " + s;
		}
	}

	static public function epsilonEq(a : Float, b : Float, threshold : Float) : Bool {
		return Math.abs(a - b) < threshold;
	}

	static public function getUniqueID() : Float {
		return ++uid;
	}

	// This function is currently broken if val is an object, and there's no
	// easy way to fix it.
	//public static function make2DArrayVal(width:int, height:int, val:*):Array {
	//  return make2DArrayFn(width, height, function():* { return val; });
	//}
	static public function make2DArrayFn<T>(width : Int, height : Int, fn : Int -> Int -> T) : Array<Array<T>> {
		var result : Array<Array<T>> = new Array<Array<T>>();

		for (i in 0...width) {
			result.push(new Array<T>());
			for (j in 0...height) {
				result[i].push(fn(i, j));
			}
		}
		return result;
	}

	static public function foreach2D(a : Array<Dynamic>, fn : Int -> Int -> Dynamic -> Void) : Void {
		var i : Int = 0;
		while(i < a.length) {
			var j : Int = 0;
			while(j < a[0].length) {
				fn(i, j, a[i][j]);
				j++;
			}
			i++;
		}
	}

	// With thanks to http://kirill-poletaev.blogspot.com/2010/07/rotate-object-to-mouse-using-as3.html
	static public function rotateToFace(pointer : Vec, target : Vec) : Float {
		var cx : Float = target.x - pointer.x;
		var cy : Float = target.y - pointer.y;
		var radians : Float = Math.atan2(cy, cx);
		var degrees : Float = radians * 180 / Math.PI;
		return degrees;
	}

	static public function make2DArray<T>(width : Int, height : Int, defaultValue : T) : Array<Array<T>> {
		return make2DArrayFn(width, height, function(x : Int, y : Int) : T {
			return defaultValue;
		});
	}

	static public function movementVector() : Vec {
		var x : Int = ((KeyDown.Right) ? 1 : 0) - ((KeyDown.Left) ? 1 : 0);
		var y : Int = ((KeyDown.Down) ? 1 : 0) - ((KeyDown.Up) ? 1 : 0);
		return new Vec(x, y);
	}

	static public function randRange(low : Int, high : Int) : Int {
		return low + Math.floor(Math.random() * (high - low));
	}

	static public function randNum(low : Float, high : Float) : Float {
		return low + (Math.random() * (high - low));
	}


	public function new() {

	}
}

