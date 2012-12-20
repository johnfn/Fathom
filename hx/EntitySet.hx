class EntitySet extends Set {

	function new(entities : Array<Dynamic> = null) {
		super(entities);
	}

	public function select() : EntitySet {
		var eList : EntitySet = clone();
		var i : Int = 0;
		while(i < criteria.length) {
			eList = eList.myfilter(criteria[i]);
			i++;
		}
		return eList;
	}

	public function clone() : EntitySet {
		return new EntitySet(this.toArray());
	}

	public function union() : EntitySet {
		var eList : EntitySet = clone();
		var resultList : EntitySet = new EntitySet([]);
		var i : Int = 0;
		while(i < criteria.length) {
			var filteredList : EntitySet = eList.myfilter(criteria[i]);
			for(e in filteredList/* AS3HX WARNING could not determine type for var: e exp: EIdent(filteredList) type: EntitySet*/) {
				resultList.add(e);
			}

			i++;
		}
		return resultList;
	}

	public function all() : Bool {
		return this.length == this.select.apply(this, criteria).length;
	}

	public function one() : Entity {
		var results : EntitySet = this.select.apply(this, criteria);
		if(results.length == 0)  {
			throw new Error("EntitySet#one called with criteria " + criteria.toString() + ", but no results found.");
		}

		else if(results.length > 1)  {
			throw new Error("EntitySet#one called with criteria " + criteria.toString() + ", and " + results.length + " results found.");
		}
		for(e in results/* AS3HX WARNING could not determine type for var: e exp: EIdent(results) type: EntitySet*/) {
			return e;
		}

		Util.assert(false);
		// It's impossible to ever get here. Ever.
		return null;
	}

	public function any() : Bool {
		return this.select.apply(this, criteria).length > 0;
	}

	public function none() : Bool {
		return this.select.apply(this, criteria).length == 0;
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
		function myfilter(criteria : Dynamic) : EntitySet {
		var pass : Array<Dynamic> = [];
		var desired : Bool = true;
		if(Std.is(criteria, String && criteria.charAt(0) == "!"))  {
			desired = false;
			criteria = criteria.substring(1);
		}
		for(entity in this/* AS3HX WARNING could not determine type for var: entity exp: EIdent(this) type: null*/) {
			if(Std.is(criteria, String))  {
				if((entity.groups().contains(criteria)) == desired)  {
					pass.push(entity);
				}
			}

			else if(Std.is(criteria, Function))  {
				if(criteria(entity))  {
					pass.push(entity);
				}
			}

			else  {
				throw new Error("Unsupported Criteria type " + criteria + " " + Util.className(criteria));
			}

		}

		return new EntitySet(pass);
	}

}

