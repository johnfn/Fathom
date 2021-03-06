package fathom;

import fathom.Entity;

/** Collision detection in Fathom is done with a data structure known as a Spatial Hash.
 *  If you're not familiar with a Spatial Hash, think of placing a grid over
 *  the map, and keeping track of which grid locations each Entity is in.
 *  To check for collisions, you just see if any grid location has more than 1
 *  Entity in it.
 */
class SpatialHash {
    // TODO as should be obvious i have barely begun porting this class.

    // A two dimensional array of each entity at that grid location.
    var grid: Array<Array<Array<Entity>>>;
    var widthInTiles: Int;
    var heightInTiles: Int;
    var gridWidth: Int;
    var gridHeight: Int;


    /** Create a new Spatial Hash.
     *
     *  @param list A list of entities the spatial hash should contain.
     */
    public function new(list: Array<Entity>) {
        widthInTiles = 25;
        heightInTiles = 25;
        gridWidth = 25;
        gridHeight = 25;

        grid = Util.make2DArrayFn(widthInTiles, heightInTiles, function(x:Int, y:Int) : Array<Entity> {
            return [];
        });

        for(e in list) {
            add(e);
        }
    }

    public function add(e: Entity): Void {
        var coords: Array<Vec> = getCoords(e);

        for (coord in coords) {
            getAt(coord).push(e);
        }
    }

    /* Return the coordinates that the provided entity hashes to. Could be more than
       one coordinate. An entity with size exactly the gridsize, positioned exactly
       on a grid, will only exist in one coordinate. */
    function getCoords(e : Entity) : Array<Vec> {
        var result : Array<Vec> = [];
        var endSlotX : Int = Math.floor((e.x + e.width) / gridWidth);
        if((e.x + e.width) % gridWidth == 0) endSlotX--;

        var endSlotY : Int = Math.floor((e.y + e.height) / gridHeight);
        if((e.y + e.height) % gridHeight == 0) endSlotY--;

        var startSlotX: Int = Math.floor(e.x / gridWidth);
        var startSlotY: Int = Math.floor(e.y / gridHeight);

        for (slotX in startSlotX...(endSlotX + 1)) {
            for (slotY in startSlotY...(endSlotY + 1)) {
                if(slotX < 0 || slotX >= widthInTiles || slotY < 0 || slotY >= heightInTiles)  {
                    continue;
                }

                result.push(new Vec(slotX, slotY));
            }
        }
        return result;
    }

    /* Return the entity at x, y in the spatial hash. */
    function getAt(coord: Vec) : Array<Entity> {
        return grid[Std.int(coord.x)][Std.int(coord.y)];
    }

    /* Returns whether the entity e collides with any object in the hash,
       excluding itself. */
    public function collides(e : Entity) : Bool {
        return getColliders(e).length > 0;
    }

    /* Return every entity the entity e collides with, excluding itself. */
    public function getColliders(e : Entity) : Set<Entity> {
        var result: Set<Entity> = new Set<Entity>();
        var coords: Array<Vec> = getCoords(e);

        for (coord in coords) {
            if (coord.x >= grid.length || coord.y >= grid[0].length ||
                coord.x < 0 || coord.y < 0) continue;

            var arr : Array<Entity> = getAt(coord);

            for (ent in arr) {
                if(ent == e) {
                    continue;
                }

                if(ent.touchingRect(e))  {
                    result.add(ent);
                }
            }
        }
        return result;
    }

}

