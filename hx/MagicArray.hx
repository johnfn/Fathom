class MagicArray extends Array<Dynamic> {

	/* MagicArray gives extra power to the standard Array class. */	//TODO: needs better name.
		public function myMap(f : Function) : MagicArray {
		var result : MagicArray = new MagicArray();
		var i : Int = 0;
		while(i < this.length) {
			result.push(f(this[i]));
			i++;
		}
		return result;
	}

	public function any(f : Function = null) : Bool {
		if(f == null)  {
			f = Util.id;
		}
		var i : Int = 0;
		while(i < this.length) {
			if(f(this[i]))  {
				return true;
			}
			i++;
		}
		return false;
	}


	public function new() {
	}
}

