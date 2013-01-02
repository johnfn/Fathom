// TODO: High level stuff - should have some consistency with mutable/immutable
// function calls.
// This class mimics the Set data type found in languages like Python.
class Set<T> {
    public var length(getLength, never) : Int;

    var contents : ObjectHash<T, Bool>;
    var _length : Int;
    var restrictedTypes:Array<String>;

    public function new(init : Array<T> = null) {
        contents = new ObjectHash();
        _length = 0;

        if(init == null)
            return;

        for (item in init) {
            add(item);
        }
    }

    public function equals(other: Set<T>): Bool {
        if (length != other.length) return false;

        for (x in this) {
            if (!other.has(x)) return false;
        }

        return true;
    }

    public function add(item : T) : Void {
        if (!has(item)) {
          _length++;
        }

        contents.set(item, true);
    }

    public function remove(item : T) : Void {
        if(!has(item))  {
            throw "Set#remove called on non-existant item";
        }

        contents.delete(item);
        _length--;
    }

    public function has(item : T) : Bool {
        return false;
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
        for (k in other.contents.keys()) {
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

    public function first(): T {
        for (k in contents.keys()) {
            return k;
        }

        Util.assert(false, "Set#first called on empty set.");
        return null;
    }

    public function filter(f : T -> Bool) : Set<T> {
        var result : Set<T> = new Set<T>();
        for(k in contents.keys()) {
            if (f(k))  {
                result.add(k);
            }
        }

        return result;
    }

    public function map<T2>(f: T -> T2) : Set<T2> {
        var result: Set<T2> = new Set<T2>();

        for (k in contents.keys()) {
            result.add(f(k));
        }

        return result;
    }

    public function getLength() : Int {
        return _length;
    }

    public function toArray() : Array<T> {
        var result : Array<T> = [];
        for (k in contents.keys()) {
            result.push(k);
        }

        return result;
    }

    public function toString() : String {
        var result : String = "{ ";
        for(k in this) {
            untyped {
                result += k.toString() + ", ";
            }
        }

        result += " }";
        return result;
    }

    public function iterator() : Iterator<T> {
        return new Set.SetIter(this);
    }

    public function select(criteria: Array<T -> Bool>) : Set<T> {
        var eList : Set<T> = clone();

        for (crit in criteria) {
            eList = eList.filter(crit);
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
            var filteredList : Set<T> = eList.filter(crit);
            for(e in filteredList) {
                resultList.add(e);
            }
        }
        return resultList;
    }

    public function one(criteria:Array<T -> Bool>) : T {
        var results : Set<T> = select(criteria);
        if(results.length == 0)  {
            throw ("Set<Entity>#one called with criteria " + criteria.toString() + ", but no results found.");
        } else if(results.length > 1)  {
            throw ("Set<Entity>#one called with criteria " + criteria.toString() + ", and " + results.toString() + "(" + results.length + ")" + " results found.");
        }

        for(e in results) {
            return e;
        }

        Util.assert(false);
        // It's impossible to ever get here. Ever.
        return null;
    }

    public function all(criteria:Array<T -> Bool>) : Bool {
        return this.length == this.select(criteria).length;
    }

    public function any(criteria: Array<T -> Bool>) : Bool {
        return this.select(criteria).length > 0;
    }

    public function none(criteria: Array<T -> Bool>) : Bool {
        return this.select(criteria).length == 0;
    }

    public static function hasGroup(g: String) : Entity -> Bool {
        return function(e:Entity): Bool {
            return e.groups().has(g);
        }
    }

    public static function doesntHaveGroup(g: String) : Entity -> Bool {
        return function(e:Entity): Bool {
            return !e.groups().has(g);
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
