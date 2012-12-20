import flash.system.Fscommand;
import flash.events.KeyboardEvent;
import flash.display.DisplayObject;
import flash.display.Sprite;

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

	static public function className(c : Dynamic) : String {
		var qualifiedName : String = Type.getClassName(c);
		if(qualifiedName.indexOf(":") == -1) 
			return qualifiedName;
		var split : Array<Dynamic> = qualifiedName.split(":");
		return split[split.length - 1];
	}

	static public function printStackTrace() : Void {
		var e : Error = new Error("[stack trace requested - no error]");
		Util.log(e.getStackTrace());
	}

	/* The reason for this wrapper method is to separate debugging messages
       that should eventually be removed from more serious error logs, which
       should stay. For instance, if you're checking the x value of an Entity, do
       trace (e.x). If you just failed an assertion, do Util.log("Assertion failed!").

       We separate them so that it's easy to search for "trace" with a following "("
       to find debugging messages you need to remove.
       */	static public function log() : Void {
		trace.apply(null, args);
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
			var object : Dynamic = try cast(o, Dynamic) catch(e:Dynamic) null;
			result = "{ ";
			for(k in Reflect.fields(object)) {
				result += k + ": " + pHelper(Reflect.field(object, k)) + ", ";
			}

			result = result.slice(0, -2) + " ";
			result += "}";
		}

		else if(Util.className(o) == "Array")  {
			var arr : Array<Dynamic> = try cast(o, Array) catch(e:Dynamic) null;
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

	static public function assert(b : Bool) : Void {
		if(!b)  {
			var e : Error = new Error("Assertion failed.");
			Util.log(e.getStackTrace());
			fscommand("quit");
			throw e;
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
		static public function make2DArrayFn(width : Int, height : Int, fn : Function) : Array<Dynamic> {
		var result : Array<Dynamic> = new Array<Dynamic>(width);
		var i : Int = 0;
		while(i < width) {
			result[i] = new Array<Dynamic>(height);
			var j : Int = 0;
			while(j < height) {
				result[i][j] = fn(i, j);
				j++;
			}
			i++;
		}
		return result;
	}

	static public function foreach2D(a : Array<Dynamic>, fn : Function) : Void {
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

	static public function make2DArray(width : Int, height : Int, defaultValue : Dynamic) : Array<Dynamic> {
		return make2DArrayFn(width, height, function(x : Int, y : Int) : Dynamic {
			return defaultValue;
		}
);
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

	static function __init__() {
		Array.prototype.sortBy = function(k : Function) : Void {
			// TODO: Calls k O(n^2) times; can reduce to O(n) with little trouble.
			this.sort(function(a : Dynamic, b : Dynamic) : Int {
				return k(a) - k(b);
			}
);
		}
;
		Array.prototype.contains = function(val : Dynamic) : Bool {
			return this.getIndex(val) != -1;
		}
;
		Array.prototype.getIndex = function(val : Dynamic) : Int {
			var i : Int = 0;
			while(i < this.length) {
				if(this[i] == val) 
					return i;
				i++;
			}
			return -1;
		}
;
		Array.prototype.remove = function(item : Dynamic) : Void {
			var i : Int = 0;
			while(i < this.length) {
				if(this[i] == item)  {
					this.splice(i, 1);
					i--;
				}
				i++;
			}
		}
;
		Array.prototype.extend = function(a : Array<Dynamic>) : Void {
			var i : Int = 0;
			while(i < a.length) {
				this.push(a[i]);
				i++;
			}
		}
;
		Array.prototype.setPropertyIsEnumerable("sortBy", false);
		Array.prototype.setPropertyIsEnumerable("contains", false);
		Array.prototype.setPropertyIsEnumerable("collect", false);
		Array.prototype.setPropertyIsEnumerable("getIndex", false);
		Array.prototype.setPropertyIsEnumerable("remove", false);
		Array.prototype.setPropertyIsEnumerable("extend", false);
	}
}

