package {
  public class Rect extends Vec implements IPositionable {
    import flash.geom.Point;
    import flash.utils.getQualifiedClassName;

    protected var _width:Number = 0;
    protected var _height:Number = 0;
    protected var _right:Number = 0;
    protected var _bottom:Number = 0;

    function Rect(x:Number, y:Number, width:Number, height:Number = -1) {
      if (height == -1) height = width;

      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;
      this.right = this.x + this.width;
      this.bottom = this.y + this.height;
    }

    public override function set x(val:Number):void {
      _x = val;
    }

    public override function set y(val:Number):void {
      _y = val;
    }

    public function set width(val:Number):void {
      _width = val;
    }

    public function get width():Number {
      return _width;
    }

    public function set height(val:Number):void {
      _height = val;
    }

    public function get height():Number {
      return _height;
    }

    public function set right(val:Number):void {
      this._right = val;
      this.width = this._right - x;
    }

    public function get right():Number {
      return this.width + x;
    }

    public function set bottom(val:Number):void {
      this._bottom = val;
      this.height = this._bottom - y;
    }

    public function get bottom():Number {
      return this.height + y;
    }

    /* Is i contained entirely within this Rect? i can be either a Rect
     * or a Point.
     *
     * This is NOT a collision detection test. This is a contains test. */
    public function contains(i:*):Boolean {
      if (i is Vec) {
        var p:Vec = i as Vec;

        return x <= p.x && p.x < right && y <= p.y && p.y < bottom;
      }

      if (i is Rect) {
        var r:Rect = i as Rect;

        return x <= r.x      && r.x      < right &&
               x <= r.right  && r.right  < right &&
               y <= r.bottom && r.bottom < right &&
               y <= r.y      && r.y      < right;
      }

      throw new Error("Unsupported type for contains.");
    }

    public function makeBigger(size:int):Rect {
      return new Rect(x - size, y - size, width + size * 2, height + size * 2);
    }

    public override function clone():Vec {
      return new Rect(x, y, width, height);
    }

    public function touchingRect(rect:Rect):Boolean {
      return !   (rect.x      > this.x + this.width  ||
         rect.x + rect.width  < this.x               ||
         rect.y               > this.y + this.height ||
         rect.y + rect.height < this.y               );
    }

    public override function toString():String {
      return "[Rect (" + x + ", " + y + ") w: " + width + " h: " + height + "]";
    }

    public override function equals(v:Vec):Boolean {
      // This makes inheritance work.
      if (Util.className(v) != "Rect") return false;

      var r:Rect = v as Rect;

      return x == r.x && y == r.y && width == r.width && right == r.right;
    }
  }
}
