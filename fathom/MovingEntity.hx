package fathom;

import fathom.Vec;
import fathom.Entity;
import fathom.Set;

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

    public function new(x : Float = 0, y : Float = 0) {
        vel = new Vec(0, 0);
        xColl = new Set<Entity>();
        yColl = new Set<Entity>();
        touchingLeft = false;
        touchingRight = false;
        touchingTop = false;
        touchingBottom = false;
        collisionList = new Set<Entity>([]);
        super(x, y);
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

    /** Decelerate the velocity of this entity by a given amount. */
    function decel(e: MovingEntity, decel: Float = 2.0) : Void {
        var truncate: Float -> Float = function(val: Float): Float {
            if(Math.abs(val) <= decel)
                return 0;
            return val;
        };

        e.vel.map(truncate).addAwayFromZero(-decel, -decel);
    }

    function truncate(): Void {
        var cutoff : Float = 0.4;
        var lowCutoff : Float = 20;
        var cutoffFn : Float -> Float = function(val : Float) : Float {
            if(Math.abs(val) < cutoff)  {
                return 0;
            }
            if(Math.abs(val) > lowCutoff)
                return Util.sign(val) * lowCutoff;
            //TODO: This hides a problem where falling velocity gets too large.
            return val;
        };

        vel.map(cutoffFn);
    }
}
