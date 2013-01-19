package fathom.hx;

import flash.display.MovieClip;
import flash.geom.Point;
import flash.geom.Rectangle;

class MovingEntity extends Entity {

    /* Velocity of the MovingEntity. */
    public var vel : Vec;
    public var xColl : Set<Entity>;
    public var yColl : Set<Entity>;
    public var touchingLeft : Bool;
    public var touchingRight : Bool;
    public var touchingTop : Bool;
    public var touchingBottom : Bool;
    /* List of all entities that this entity collided with in this time step. */
    var collisionList : Set<Entity>;

    function new(x : Float = 0, y : Float = 0, width : Float = 20, height : Float = -1) {
        vel = new Vec(0, 0);
        xColl = new Set<Entity>();
        yColl = new Set<Entity>();
        touchingLeft = false;
        touchingRight = false;
        touchingTop = false;
        touchingBottom = false;
        collisionList = new Set<Entity>([]);
        super(x, y, width, height);
        _isStatic = false;
    }

    // TODO. This won't return anything you aren't obstructed by.
    public function isTouching(args: Array<Entity -> Bool>) : Bool {
        return xColl.any(args) || yColl.any(args);
    }

    public function touchingSet(criteria: Array<Entity -> Bool>) : Set<Entity> {
        return new Set<Entity>(xColl.clone().extend(yColl).toArray()).get(criteria);
    }

    public function isBlocked() : Bool {
        return isTouching([Set.doesntHaveGroup("non-blocking")]);
    }
}
