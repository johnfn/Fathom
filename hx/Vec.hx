import flash.display.Sprite;

/** Vector. Vector is a pair of 2 numbers, typically (x, y), used
    to represent both position and direction. */
class Vec implements IPositionable {
    public var x(getX, setX) : Float;
    public var y(getY, setY) : Float;

    var _x : Float;
    var _y : Float;

    public function new(x : Float = 0, y : Float = 0) {
        this.x = x;
        this.y = y;
    }

    public function getX() : Float {
        return _x;
    }

    public function setX(val : Float) : Float {
        return this._x = val;
    }

    public function getY() : Float {
        return _y;
    }

    public function setY(val : Float) : Float {
        return this._y = val;
    }

    public function equals(v : Vec) : Bool {
        return x == v.x && y == v.y;
    }

    public function toString() : String {
        return "Vec[" + x + ", " + y + "]";
    }

    public function angle() : Float {
        return Math.atan2(this.y, this.x) * 180.0 / Math.PI;
    }

    public function randomize() : Vec {
        var r : Float = Util.randRange(0, 4);
        if(r == 0)  {
            return new Vec(0, 1);
        }
        if(r == 1)  {
            return new Vec(0, -1);
        }
        if(r == 2)  {
            return new Vec(1, 0);
        }
        if(r == 3)  {
            return new Vec(-1, 0);
        }
        return new Vec(0, 0);
    }

    public function clone() : Vec {
        return new Vec(x, y);
    }

    public function map(f : Float -> Dynamic) : Vec {
        x = f(x);
        y = f(y);
        return this;
    }

    public function setPos(v : IPositionable) : Vec {
        x = v.x;
        y = v.y;
        return this;
    }

    public function add(v : Dynamic) : Vec {
    if (Std.is(v, IPositionable)) {
            var vec : IPositionable = cast(v, IPositionable);

      x += vec.x;
      y += vec.y;
    } else {
      untyped {
        x += v;
        y += v;
      }
    }
        return this;
    }

    public function NaNsTo(val : Float) : Vec {
        if(Math.isNaN(x))
            x = val;
        if(Math.isNaN(y))
            y = val;
        return this;
    }

    public function subtract(v : Dynamic) : Vec {
        if(Std.is(v, IPositionable))  {
            var vec : Vec = cast(v, Vec);

            x -= vec.x;
            y -= vec.y;
        }

        else { // Int, Float
      untyped {
        x -= v;
        y -= v;
      }
        }
        return this;
    }

  // TODO in haxe i can just overload this stuff

    // Takes either a Vector or an int (treated as a Vector(int, int))
  public function multiply(v : Dynamic) : Vec {
    if (Std.is(v, IPositionable)) {
      var i:IPositionable = cast(v, IPositionable);

      x *= i.x;
      y *= i.y;
    } else { //int, float
      untyped {
        x *= v;
        y *= v;
      }
    }

        return this;
    }

    public function divide(v : Dynamic) : Vec {
    if (Std.is(v, IPositionable)) {
      var i:IPositionable = cast(v, IPositionable);

      x /= i.x;
      y /= i.y;
    } else {
      untyped {
        x /= v;
        y /= v;
      }
    }

        return this;
    }

    public function normalize() : Vec {
        var mag : Float = magnitude();
        x /= mag;
        y /= mag;
        return this;
    }

    public function addAwayFromZero(dx : Float, dy : Float) : Vec {
        x += (x > 0 ? 1 : -1) * dx;
        y += (y > 0 ? 1 : -1) * dy;
        return this;
    }

    // TODO: I should think about how to mark "ignore this value". Here I do it with -1.
        public function threshold(cutoffX : Float, cutoffY : Float = -1) : Vec {
        if(cutoffX != -1 && Math.abs(x) < Math.abs(cutoffX))
            x = 0;
        if(cutoffY != -1 && Math.abs(y) < Math.abs(cutoffY))
            y = 0;
        return this;
    }

    public function magnitude() : Float {
        return Math.sqrt(x * x + y * y);
    }

    public function nonzero() : Bool {
        return x != 0 || y != 0;
    }

    public function max() : Float {
        return x > (y) ? x : y;
    }

    public function min() : Float {
        return x < (y) ? x : y;
    }

    /* Create a unique key to store in an object. */
    public function asKey() : String {
        return x + "," + y;
    }

}

