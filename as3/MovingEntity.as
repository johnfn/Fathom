package {
  import flash.display.MovieClip;
  import flash.geom.Point;
  import flash.geom.Rectangle;

  import Hooks;
  import Util;

  public class MovingEntity extends Entity {
    /* Velocity of the MovingEntity. */
    public var vel:Vec = new Vec(0, 0);

    public var xColl:EntitySet = new EntitySet();
    public var yColl:EntitySet = new EntitySet();

    public var touchingLeft:Boolean     = false;
    public var touchingRight:Boolean    = false;
    public var touchingTop:Boolean      = false;
    public var touchingBottom:Boolean   = false;

    /* List of all entities that this entity collided with in this time step. */
    internal var collisionList:EntitySet = new EntitySet([]);

    function MovingEntity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1):void {
      super(x, y, width, height);
      _isStatic = false;
    }

    // TODO. This won't return anything you aren't obstructed by.
    public function isTouching(...args):Boolean {
      return xColl.any.apply(this, args) || yColl.any.apply(this, args);
    }

    public function touchingSet(...args):EntitySet {
      return new EntitySet(Set.merge(xColl, yColl).toArray()).select.apply(this, args);
    }

    public function isBlocked(...args):Boolean {
      return isTouching("!non-blocking");
    }
  }
}
