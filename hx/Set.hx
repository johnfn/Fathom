import flash.utils.Proxy;
import flash.utils.TypedDictionary;

// TODO: High level stuff - should have some consistency with mutable/immutable
// function calls.
// This class mimics the Set data type found in languages like Python.
class Set<T> {
	public var length(getLength, never) : Int;

	var contents : TypedDictionary<T, Bool>;
	var _length : Int;

	public function new(init : Array<T> = null) {
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

	public function add(item : T) : Void {
		//if(startedIterating && !iterationList.contains(item))  {
		//	iterationList.push(item);
		//}
	    if (!contents.exists(item)) {
	      _length++;
	    }

	    contents.set(item, true);
	}

	public function remove(item : T) : Void {
		if(!Reflect.field(contents, Std.string(item)))  {
			throw "Set#remove called on non-existant item";
		}

	    untyped __delete__(contents, item);
		_length--;
	}

	public function contains(item : T) : Bool {
		// This looks redundant, but if we don't have the item
		// contents[item] == undefined.
		return contents.get(item) == true;
	}

	/*
	static public function merge(s1 : Set<T>, s2 : Set<T>) : Set<T> {
		var result : Set = new Set();
		var k : T;
		for(k in Reflect.fields(s1.contents)) {
			result.add(k);
		}

		for(k in Reflect.fields(s2.contents)) {
			result.add(k);
		}

		return result;
	}
	*/

	public function extend(other : Set<T>) : Set<T> {
		for(k in other.contents) {
			add(k);
		}

		return this;
	}

  function _concatHelper(args : Array<T>) : Set<T> {
		var result : Set<T> = new Set<T>();
		var k : T;
		for (k in contents.keys()) {
			result.add(k);
		}

		for (val in args) {
			result.add(val);
		}

		return result;
  }

	public function concat(i1: T, i2:T=null, i3:T=null) : Set<T> {
	    var list:Array<T> = [i1];

	    if (i2 != null) list.push(i2);
	    if (i3 != null) list.push(i3);

	    return _concatHelper(list);
	}

	public function filter(f : T -> Bool) : Set<T> {
		var result : Set<T> = new Set<T>();
		for(k in contents) {
			if (f(k))  {
				result.add(k);
			}
		}

		return result;
	}

	public function map<T2>(f: T -> T2) : Set<T2> {
		var result: Set<T2> = new Set<T2>();

		for (k in contents) {
			result.add(f(k));
		}

		return result;
	}

	public function getLength() : Int {
		return _length;
	}

	public function toArray() : Array<T> {
		var result : Array<T> = [];
		for(k in contents) {
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

	public function iterator() : Iterator<T> {
		return new Set.SetIter(this);
	}

	public function select(criteria: Array<T -> Bool>) : Set<T> {
		var eList : Set<T> = clone();
		var i : Int = 0;
		while(i < criteria.length) {
			eList = eList.myfilter(criteria[i]);
			i++;
		}
		return eList;
	}

	public function clone() : Set<T> {
		return new Set<T>(this.toArray());
	}

	public function union(criteria:Array<T -> Bool>) : Set<T> {
		var eList : Set<T> = clone();
		var resultList : Set<T> = new Set<T>([]);
		for (crit in criteria) {
			var filteredList : Set<T> = eList.myfilter(crit);
			for(e in filteredList/* AS3HX WARNING could not determine type for var: e exp: EIdent(filteredList) type: Set<Entity>*/) {
				resultList.add(e);
			}
		}
		return resultList;
	}

	public function all(criteria:Array<T -> Bool>) : Bool {
		return this.length == this.select(criteria).length;
	}

	public function one(criteria:Array<T -> Bool>) : T {
		var results : Set<T> = this.select(criteria);
		if(results.length == 0)  {
			throw ("Set<Entity>#one called with criteria " + criteria.toString() + ", but no results found.");
		} else if(results.length > 1)  {
			throw ("Set<Entity>#one called with criteria " + criteria.toString() + ", and " + results.length + " results found.");
		}

		for(e in results) {
			return e;
		}

		Util.assert(false);
		// It's impossible to ever get here. Ever.
		return null;
	}

	public function any(criteria: Array<T -> Bool>) : Bool {
		return this.select(criteria).length > 0;
	}

	public function none(criteria: Array<T -> Bool>) : Bool {
		return this.select(criteria).length == 0;
	}

	// Filters a list by 1 criteria item. Returns the filtered list.
	//
	// Criteria types:
	//
	// * String   -> match all entities with that group
	//
	// * !String  -> in the case that the string starts with "!",
	//              perform the inverse of the above.
	//
	// * Function -> match all entities e such that f(e) == true.
	function myfilter(criteria : T -> Bool) : Set<T> {
		var pass : Array<T> = [];

		for(entity in this) {
			if (criteria(entity)) {
				pass.push(entity);
			}
		}

		return new Set<T>(pass);
	}

	public static function hasGroup(g: String) : Entity -> Bool {
		return function(e:Entity): Bool {
			return e.groups().contains(g);
		}
	}

	public static function doesntHaveGroup(g: String) : Entity -> Bool {
		return function(e:Entity): Bool {
			return e.groups().contains(g);
		}
	}

}

class SetIter<T> {
	var contents:Array<T>;
	var loc:Int;

	public function new(s:Set<T>) {
		contents = s.toArray();
		loc = 0;
	}

    public function hasNext() {
        return loc < contents.length;
    }

    public function next() {
    	return contents[loc++];
    }
}
