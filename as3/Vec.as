package {
  import flash.display.Sprite;
  import flash.utils.getQualifiedClassName;

  /** Vector. Vector is a pair of 2 numbers, typically (x, y), used
      to represent both position and direction. */

  public class Vec implements IPositionable {
    protected var _x:Number;
    protected var _y:Number;

    function Vec(x:Number = 0, y:Number = 0) {
      this.x = x;
      this.y = y;
    }

    public function get x():Number { return _x; }
    public function set x(val:Number):void { this._x = val; }

    public function get y():Number { return _y; }
    public function set y(val:Number):void { this._y = val; }

    public function equals(v:Vec):Boolean {
      return x == v.x && y == v.y;
    }

    public function toString():String {
      return "Vec[" + this.x + ", " + this.y + "]";
    }

    public function angle():Number {
      return Math.atan2(this.y, this.x) * 180.0 / Math.PI;
    }

    public function randomize():Vec {
      var r:Number = Util.randRange(0, 4);

      if (r == 0) { return new Vec( 0,  1); }
      if (r == 1) { return new Vec( 0, -1); }
      if (r == 2) { return new Vec( 1,  0); }
      if (r == 3) { return new Vec(-1,  0); }

      return new Vec(0, 0); //This line never executes. It's just to satisfy type checker.
    }

    public function clone():Vec {
      return new Vec(x, y);
    }

    public function map(f:Function):Vec {
      x = f(x);
      y = f(y);

      return this;
    }

    public function setPos(v:IPositionable):Vec {
      x = v.x;
      y = v.y;

      return this;
    }

    public function add(v:IPositionable):Vec {
      x += v.x;
      y += v.y;

      return this;
    }

    public function NaNsTo(val:Number):Vec {
      if (isNaN(x)) x = val;
      if (isNaN(y)) y = val;

      return this;
    }

    public function subtract(v:*):Vec {
      if (v is IPositionable) {
        var vec:Vec = v as Vec;

        x -= v.x;
        y -= v.y;
      } else if (getQualifiedClassName(v) == "int") {
        var val:Number = v as Number;

        x -= val;
        y -= val;
      }

      return this;
    }

    // Takes either a Vector or an int (treated as a Vector(int, int))
    public function multiply(n:*):Vec {
      var name:String = getQualifiedClassName(n);

      if (name == "int" || name == "Number") {
        var val:Number = n as Number;

        x *= n;
        y *= n;
      } else if (name == "Vec") {
        var vec:Vec = n as Vec;

        x *= n.x;
        y *= n.y;
      } else {
        throw new Error("Unsupported type for Vec#multiply.");
      }

      return this;
    }

    public function divide(n:*):Vec {
      if (getQualifiedClassName(n) == "int") {
        var val:Number = n as Number;

        x /= n;
        y /= n;
      } else if (getQualifiedClassName(n) == "Vec") {
        var vec:Vec = n as Vec;

        x /= n.x;
        y /= n.y;
      } else {
        throw new Error("Unsupported type for Vec#multiply.");
      }

      return this;
    }

    public function normalize():Vec {
      var mag:Number = magnitude();

      x /= mag;
      y /= mag;

      return this;
    }

    public function addAwayFromZero(dx:Number, dy:Number):Vec {
      x += Util.sign(x) * dx;
      y += Util.sign(y) * dy;

      return this;
    }

    // TODO: I should think about how to mark "ignore this value". Here I do it with -1.
    public function threshold(cutoffX:Number, cutoffY:Number = -1):Vec {
      if (cutoffX != -1 && Math.abs(x) < Math.abs(cutoffX)) x = 0;
      if (cutoffY != -1 && Math.abs(y) < Math.abs(cutoffY)) y = 0;

      return this;
    }

    public function magnitude():Number {
      return Math.sqrt(x * x + y * y);
    }

    public function nonzero():Boolean {
      return x != 0 || y != 0;
    }

    public function max():Number {
      return x > y ? x : y;
    }

    public function min():Number {
      return x < y ? x : y;
    }

    /* Create a unique key to store in an object. */
    public function asKey():String {
      return x + "," + y;
    }
  }
}
