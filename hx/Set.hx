import flash.utils.Proxy;
import flash.utils.TypedDictionary;

// TODO: High level stuff - should have some consistency with mutable/immutable
// function calls.
// This class mimics the Set data type found in languages like Python.
class Set {
	public var length(getLength, never) : Int;

	var contents : TypedDictionary<Dynamic, Bool>;
	var _length : Int;

	public function new(init : Array<Dynamic> = null) {
		contents = new TypedDictionary();
		_length = 0;
		if(init == null)
			return;
		var i : Int = 0;
		while(i < init.length) {
			add(init[i]);
			i++;
		}
	}

	public function add(item : Dynamic) : Void {
		//if(startedIterating && !iterationList.contains(item))  {
		//	iterationList.push(item);
		//}
    if (!contents.exists(item)) {
      _length++;
    }
    contents.set(item, true);
	}

	public function remove(item : Dynamic) : Void {
		if(!Reflect.field(contents, Std.string(item)))  {
			throw "Set#remove called on non-existant item";
		}
    untyped __delete__(contents, item);
		_length--;
	}

	public function contains(item : Dynamic) : Bool {
		// This looks redundant, but if we don't have the item
		// contents[item] == undefined.
		return contents.get(item) == true;
	}

	static public function merge(s1 : Set, s2 : Set) : Set {
		var result : Set = new Set();
		var k : Dynamic;
		for(k in Reflect.fields(s1.contents)) {
			result.add(k);
		}

		for(k in Reflect.fields(s2.contents)) {
			result.add(k);
		}

		return result;
	}

	public function extend(other : Set) : Void {
		for(k in Reflect.fields(other.contents)) {
			add(k);
		}
	}

  function _concatHelper(args : Array<Dynamic>) : Set {
		var result : Set = new Set();
		var k : Dynamic;
		for (k in contents.keys()) {
			result.add(k);
		}

		for (val in args) {
			result.add(val);
		}

		return result;
  }

	public function concat(i1: Dynamic, i2:Dynamic=null, i3:Dynamic=null) : Set {
    var list:Array<Dynamic> = [i1];

    if (i2 != null) list.push(i2);
    if (i3 != null) list.push(i3);

    return _concatHelper(list);
	}

	public function filter(f : Dynamic -> Bool) : Set {
		var result : Set = new Set();
		for(k in Reflect.fields(contents)) {
			if(f(k))  {
				result.add(k);
			}
		}

		return result;
	}

	public function getLength() : Int {
		return _length;
	}

	public function toArray() : Array<Dynamic> {
		var result : Array<Dynamic> = [];
		for(k in Reflect.fields(contents)) {
			result.push(k);
		}

		return result;
	}

	public function toString() : String {
		var result : String = "{ ";
		for(k in Reflect.fields(contents)) {
			result += k.toString() + ", ";
		}

		result += " }";
		return result;
	}

	public function iterator() : Iterator<Dynamic> {
		return new Set.SetIter(this);
	}

}

class SetIter {
	var contents:Array<Dynamic>;
	var loc:Int;

	public function new(s:Set) {
		contents = s.toArray();
		loc = 0;
	}

    public function hasNext() {
        return loc < contents.length - 1;
    }

    public function next() {
    	return contents[loc++];
    }
}
