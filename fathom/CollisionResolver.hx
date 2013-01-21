package fathom;

class CollisionResolver {
    static public var grid: SpatialHash;

    public static function moveEverything(list: Set<fathom.MovingEntity>) : Void {
    	  grid = new fathom.SpatialHash(Fathom.entities.toArray());
        // Move every non-static entity.
        for(e in list) {
            var oldVelX: Float = e.vel.x;
            var oldVelY: Float = e.vel.y;

            var onceThrough : Bool = true;
            e.xColl = new Set<Entity>();
            e.yColl = new Set<Entity>();
            // Resolve 1 px in the x-direction at a time...
            while (onceThrough || oldVelX != 0) {
                // Attempt to resolve as much of dy as possible on every tick.
                while (oldVelY != 0) {
                    var amtY : Float = Util.clamp(oldVelY, -1, 1);
                    e.y += amtY;
                    oldVelY -= amtY;
                    if(grid.collides(e))  {
                        var yColliders : Set<Entity> = grid.getColliders(e);
                        e.yColl.extend(yColliders);
                        if(yColliders.any([Set.doesntHaveGroup("non-blocking")]))  {
                            e.y -= amtY;
                            oldVelY += amtY;
                            break;
                        }
                    }
                }

                onceThrough = false;
                var amtX : Float = Util.clamp(oldVelX, -1, 1);
                e.x += amtX;
                oldVelX -= amtX;

                if(grid.collides(e))  {
                    var xColliders : Set<Entity> = grid.getColliders(e);
                    e.xColl.extend(xColliders);
                    if(xColliders.any([Set.doesntHaveGroup("non-blocking")]))  {
                        e.x -= amtX;
                    }
                }
            }

            e.x = Math.floor(e.x);
            e.y = Math.floor(e.y);
            e.xColl.extend(grid.getColliders(e));
            e.yColl.extend(grid.getColliders(e));
            e.touchingBottom = (e.yColl.any([Set.doesntHaveGroup("non-blocking")]) && e.vel.y > 0);
            e.touchingTop    = (e.yColl.any([Set.doesntHaveGroup("non-blocking")]) && e.vel.y < 0);
            e.touchingLeft   = (e.xColl.any([Set.doesntHaveGroup("non-blocking")]) && e.vel.x < 0);
            e.touchingRight  = (e.xColl.any([Set.doesntHaveGroup("non-blocking")]) && e.vel.x > 0);
        }
    }
}