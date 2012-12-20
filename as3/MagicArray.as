package {
  public dynamic class MagicArray extends Array {
    /* MagicArray gives extra power to the standard Array class. */

    //TODO: needs better name.
    public function myMap(f:Function):MagicArray {
      var result:MagicArray = new MagicArray();

      for (var i:int = 0; i < this.length; i++) {
        result.push(f(this[i]));
      }

      return result;
    }

    public function any(f:Function = null):Boolean {
      if (f == null) {
        f = Util.id;
      }

      for (var i:int = 0; i < this.length; i++) {
        if (f(this[i])) {
          return true;
        }
      }

      return false;
    }
  }
}
