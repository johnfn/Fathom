package fathom;

import fathom.MagicKeyObject;
import fathom.Vec;
import fathom.SuperObjectHash;

import haxe.Stack;

class Util {
	static public var KeyDown : MagicKeyObject;
	static public var KeyJustDown : MagicKeyObject;
	static public var KeyUp : MagicKeyObject;
	static public var KeyJustUp : MagicKeyObject;

	static public function id(x : Dynamic) : Dynamic {
		return x;
	}

	/**
	 * Divide a by b, always rounding up unless a % b == 0.
	 */
  static public function divRoundUp(a: Float, b: Float): Int {
	  // Looks simple, doesn't it? But see: http://stackoverflow.com/questions/921180/how-can-i-ensure-that-a-division-of-integers-is-always-rounded-up !
		return Std.int((a + b - 1) / b);
	}

	static public function sign(x: Float): Float {
		if(x > 0) return 1;
		if(x < 0) return -1;
		return 0;
	}

	static public function clamp(x: Float, low: Float, high: Float): Float {
		if(x < low)  return low;
		if(x > high) return high;
		return x;
	}

	static public function className<T>(c: T): String {
		return Type.getClassName(Type.getClass(c));
	}

	static public function printStackTrace(): Void {
		trace(haxe.Stack.toString(haxe.Stack.callStack()));
	}

	/**
	 *  The this wrapper is used to separate debugging messages
   *  that should eventually be removed from more serious error logs, which
   *  should stay. For instance, if you're checking the x value of an Entity, do
   *  trace (e.x). If you just failed an assertion, do Util.log("Assertion failed!").
	 *
   *  We separate them so that it's easy to search for "trace" with a following "("
   *  to find debugging messages you need to remove.
   */
  static public function log(s:String) : Void {
  	trace(s);
	}

	// Short for print (like in Ruby). Attempts to print a human readable representation
	// of the given object, for any object type.
	static public function p(o : Dynamic) : Void {
		Util.log(Util.anythingToString(o));
	}

	// Recursive helper method for Util.p.
	static public function anythingToString(o : Dynamic) : String {
		var result : String;

		if (o == null)  {
			result = "null";
		} else if (Util.className(o) == null) {
			var fields: Array<String> = Reflect.fields(o);

			if (fields.length == 0) {
				// happens if o == 1 for instance
				return o;
			} else {
				result = "{ ";

				// o might be an anonymous object like {x: 5, y: 7}.
				for (f in Reflect.fields(o)) {
					result += f + " => " + anythingToString(Reflect.field(o, f)) + ",";
				}

				result = result.substr(0, -1);
				result += "}";
			}
		} else if(Util.className(o) == "Object")  {
			result = "{ ";
			for(k in Reflect.fields(o)) {
				result += k + ": " + anythingToString(Reflect.field(o, k)) + ", ";
			}

			result = result.substr(0, -1);
			// result = result.slice(0, -2) + " ";
			result += "}";
		} else if (Util.className(o) == "flash.utils.TypedDictionary") {
#if flash
			var td:flash.utils.TypedDictionary<Dynamic, Dynamic> = cast(o, flash.utils.TypedDictionary<Dynamic, Dynamic>);
			result = "{ ";

			untyped {
				for (k in td) {
					result += anythingToString(k) + "=> " + anythingToString(td.get(k)) + ",";
				}
			}

			result = result.substr(0, -1);
			result += "}";
#else
			result = "WHAT IN GODS NAME HAPPENED HERE.";
#end
		} else if (Util.className(o).indexOf("SuperObjectHash") != -1) {
			var soh:SuperObjectHash<Dynamic, Dynamic> = cast(o, SuperObjectHash<Dynamic, Dynamic>);
			result = "{ ";

			untyped {
				for (k in soh) {
					result += anythingToString(k) + "=> " + anythingToString(soh.get(k)) + ",";
				}
			}

			result = result.substr(0, -1);

			result += "}";
		} else if(Util.className(o) == "Array")  {
			var arr : Array<Dynamic> = try cast(o, Array<Dynamic>) catch(e:Dynamic) null;
			result = "[";

			for (i in 0...arr.length) {
				result += anythingToString(arr[i]) + (i == arr.length - 1 ? "" : ", ");
			}
			result += "]";
		} else if (Util.className(o) == "String") {
			result = '"' + o + '"';
		} else {
			trace("idk what this is " + Util.className(o));
			result = o.toString();
		}

		return result;
	}

	static public function assert(b : Bool, ?s: String) : Void {
		if (s == null) s = "(no message)";

		if (!b) {
			Util.log("Assertion failed: " + s);
			Util.printStackTrace();
			throw "Assertion failed: " + s;
		}
	}

	static public function epsilonEq(a : Float, b : Float, threshold : Float) : Bool {
		return Math.abs(a - b) < threshold;
	}

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

	static public function foreach2D<T>(a : Array<Array<T>>, fn : Int -> Int -> T -> Void) : Void {
		for (i in 0...a.length) {
			for (j in 0...a.length) {
				fn(i, j, a[i][j]);
			}
		}
	}

	// With thanks to http://kirill-poletaev.blogspot.com/2010/07/rotate-object-to-mouse-using-as3.html
	static public function rotateToFace(pointer: Vec, target: Vec): Float {
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

	/**
	 * Generates a random number between `low` inclusive and `high` exclusive.
	 */
	static public function randRange(low: Int, high: Int) : Int {
		return low + Math.floor(Math.random() * (high - low));
	}

	static public function randFloat(low: Float, high: Float) : Float {
		return low + (Math.random() * (high - low));
	}

	public function new() {
		throw "Don't instantiate Util! Just use its static methods.";
	}
}

