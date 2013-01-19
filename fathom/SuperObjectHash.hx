package fathom;

import fathom.ObjectHash;

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

// Subtle problem - we can't directly extend ObjectHash because we don't
// have the same Key, Val values as the ObjectHash we would extend at all times.
class SuperObjectHash<Key, Val> {
	var primKey:PrimType;
	var backingHash:ObjectHash<Key, Val>;
	var primitiveHashTable:Hash<Val>;

	public function new() {
		primKey = DontKnow;
		backingHash = new ObjectHash();
		primitiveHashTable = new Hash();
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

	// Makes a primitive key hashable.
	function hashPrimitiveKey(k: Key):String {
		return Std.string(k);
	}

	// Turns a hashed key back into it's original value.
	// We need to use `untyped` here because there's no way Haxe
	// will trust us that it's really of type Key otherwise.
	function grabPrimitiveValue(p: Dynamic): Key untyped {
		switch (primKey) {
			case IntType:    return Std.parseInt(p);
			case StringType: return p;
			case FloatType:  return Std.parseFloat(p);
			case BoolType:   return p == "true" ? true : false;
			default:         return p;
		}
	}

	public function set(k:Key, v:Val) {
		if (primKey == DontKnow) setPrimitiveType(k);

		if (primKey == NotPrimitive) {
			backingHash.set(k, v);
		} else {
			primitiveHashTable.set(hashPrimitiveKey(k), v);
		}
	}

	public function get(k: Key): Val {
		if (primKey == DontKnow) setPrimitiveType(k);

		if (primKey == NotPrimitive) {
			return backingHash.get(k);
		} else {
			return primitiveHashTable.get(hashPrimitiveKey(k));
		}
	}

	public function exists(k: Key): Bool {
		if (primKey == DontKnow) setPrimitiveType(k);

		if (primKey == NotPrimitive) {
			return backingHash.exists(k);
		} else {
			return primitiveHashTable.exists(hashPrimitiveKey(k));
		}
	}

	public function delete(k: Key): Void {
		if (primKey == DontKnow) setPrimitiveType(k);

		if (primKey == NotPrimitive) {
			backingHash.delete(k);
		} else {
			primitiveHashTable.remove(hashPrimitiveKey(k));
		}
	}

	public function keys(): Iterator<Key> {
		if (primKey == NotPrimitive) {
#if flash
			return backingHash.keys().iterator();
#else
			return backingHash.keys();
#end
		}

		var keyItr:Iterator<String> = primitiveHashTable.keys();

		// This one is a little harder because we have to sneakily
		// modify the values on the fly.
		return {
			hasNext: function() return keyItr.hasNext(),
			next: function() return grabPrimitiveValue(keyItr.next())
		};
	}

	public function iterator():Iterator<Key> {
		return keys();
	}

	public function values():Iterator<Val> {
		if (primKey == NotPrimitive) {
			//ObjectHash doesn't have a values() iterator, so we make one.
			var keyItr:Iterator<Key> = backingHash.iterator();

			return {
				hasNext: function() return keyItr.hasNext(),
				next: function() return backingHash.get(keyItr.next())
			};
		}

		return primitiveHashTable.iterator();
	}
}
