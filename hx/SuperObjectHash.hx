import nme.ObjectHash;

/**
  * SuperObjectHash is like ObjectHash, but it supports primitive values
  * as keys too.
  *
  * Because sometimes it's worthwhile to sacrifice a tiny bit of efficiency for
  * a lot of elegance. :-)
  */

enum PrimType {
	IntType;
	StringType;
	FloatType;
	BoolType; // Probably useless, but who can say?
	NotPrimitive;
	DontKnow;
}

typedef Primitive = {
	var type:PrimType;

	@:optional var intValue:Int;
	@:optional var strValue:String;
	@:optional var floatValue:Float;
	@:optional var boolValue:Bool;
};


// Subtle problem - we can't directly extend ObjectHash because we don't
// have the same Key, Val values as the ObjectHash we would extend at all times.
class SuperObjectHash<Key, Val> {
	var primKey:PrimType;
	var objHash:ObjectHash<Dynamic, Val>;

	public function new() {
		primKey = DontKnow;
		objHash = new ObjectHash();
	}

	function setPrimitiveType(k:Key) {
		var s:String = Std.string(Type.typeof(k));

		switch (s) {
			case "TInt":           primKey = IntType;
			case "TClass(String)": primKey = StringType;
			case "TFloat":         primKey = FloatType;
			case "TBool":          primKey = BoolType;
			default:               primKey = NotPrimitive;
		}
	}

	function constructNonPrimitiveKey(k: Key):Dynamic {
		switch (primKey) {
			case IntType: return {type: IntType, intValue: cast(k, Int)};
			case StringType: return {type: StringType, strValue: cast(k, String)};
			case FloatType: return {type: FloatType, floatValue: cast(k, Float)};
			case BoolType: return {type: BoolType, boolValue: cast(k, Bool)};
			default: return k;
		}
	}

	function grabPrimitiveValue(p: Dynamic): Key untyped {
		switch (primKey) {
			case IntType: return p.intValue;
			case StringType: return p.strValue;
			case FloatType: return p.floatValue;
			case BoolType: return p.boolValue;
			default: return p;
		}
	}

	public function set(k:Key, v:Val) {
		if (primKey == DontKnow) setPrimitiveType(k);

		if (primKey == NotPrimitive) {
			objHash.set(k, v);
		} else {
			objHash.set(constructNonPrimitiveKey(k), v);
		}
	}

	public function get(k: Key): Val {
		if (primKey == DontKnow) setPrimitiveType(k);

		return objHash.get(constructNonPrimitiveKey(k));
	}

	public function exists(k: Key): Bool {
		if (primKey == DontKnow) setPrimitiveType(k);
		if (primKey == NotPrimitive) return objHash.exists(k);

		return objHash.exists(constructNonPrimitiveKey(k));
	}

	public function delete(k: Key): Void {
		if (primKey == DontKnow) setPrimitiveType(k);

		objHash.remove(constructNonPrimitiveKey(k));
	}

	// This one is a little harder because we have to sneakily
	// modify the values on the fly.
	public function keys(): Iterator<Key> {
		var itr:Iterator<Key> = objHash.keys();

		if (primKey == NotPrimitive) return itr;

		// The wonderful idea of just creating & returning an Iterator object
		// on the fly was borrowed from ObjectHash. It's a prime example of how
		// Haxe strikes a balance between JS and Java.
		return { hasNext: function() return itr.hasNext()
					 , next: function() return grabPrimitiveValue(itr.next())
					 };
	}

	// dont even bother overriding ObjectHash#values - it's exactly the same.

}
