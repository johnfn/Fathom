package fathom;

import nme.geom.Point;

class Rect extends Vec {
	public var width(getWidth, setWidth) : Float;
	public var height(getHeight, setHeight) : Float;
	public var right(getRight, setRight) : Float;
	public var bottom(getBottom, setBottom) : Float;

	var _width  : Float  = 0;
	var _height : Float = 0;
	var _right  : Float  = 0;
	var _bottom : Float = 0;

	public function new(x : Float, y : Float, width : Float, height : Float = -1) {
		super(x, y);

		if(height == -1)
			height = width;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		this.right = this.x + this.width;
		this.bottom = this.y + this.height;
	}

	public function setWidth(val : Float) : Float {
		return _width = val;
	}

	public function getWidth() : Float {
		return _width;
	}

	public function setHeight(val : Float) : Float {
		return _height = val;
	}

	public function getHeight() : Float {
		return _height;
	}

	public function setRight(val : Float) : Float {
		this._right = val;
		this.width = this._right - x;
		return val;
	}

	public function getRight() : Float {
		return this.width + x;
	}

	public function setBottom(val : Float) : Float {
		this._bottom = val;
		this.height = this._bottom - y;
		return val;
	}

	public function getBottom() : Float {
		return this.height + y;
	}

	/* Is i contained by this Rect? */
    public function containsPt(p: Vec): Bool {
		return x <= p.x && p.x < right && y <= p.y && p.y < bottom;
    }

	/* Is i contained entirely within this Rect?
     *
     * This is NOT a collision detection test. This is a contains test. */
  public function containsRect(r: Rect): Bool {
		return x <= r.x && r.x < right && x <= r.right && r.right < right && y <= r.bottom && r.bottom < right && y <= r.y && r.y < right;
  }

    /* Makes this rect SIZE bigger on each side. */
	public function makeBigger(size : Int) : Rect {
		return new Rect(x - size, y - size, width + size * 2, height + size * 2);
	}

	override public function clone() : Rect {
		return new Rect(x, y, width, height);
	}

	public function touchingRect(rect : Rect) : Bool {
		return !(rect.x > this.x + this.width || rect.x + rect.width < this.x || rect.y > this.y + this.height || rect.y + rect.height < this.y);
	}

	override public function toString() : String {
		return "[Rect (" + x + ", " + y + ") w: " + width + " h: " + height + "]";
	}

	override public function equals(val : Vec) : Bool {
		if (!Std.is(val, Rect)) return false;
		var r: Rect = cast(val, Rect);

		return x == r.x && y == r.y && width == r.width && right == r.right;
	}

}

