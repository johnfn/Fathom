package hx;

/* Collision detection in Fathom is done with a data structure known as a Spatial Hash.
   If you're not familiar with a Spatial Hash, you can just think of it as a 2D array
   of every entity. */
class SpatialHash {
    // TODO as should be obvious i have barely begun porting this class.

    var grid : Array<Dynamic>;
    var widthInTiles : Int;
    var heightInTiles : Int;
    var gridWidth : Int;
    var gridHeight : Int;

    public function new(list : Set<Entity>) {
        widthInTiles = 25;
        heightInTiles = 25;
        gridWidth = 25;
        gridHeight = 25;
        grid = Util.make2DArrayFn(widthInTiles, heightInTiles, function(x:Int, y:Int) : Array<Dynamic> {
            return [];
        });

        for(e in list/* AS3HX WARNING could not determine type for var: e exp: EIdent(list) type: Set<Entity>*/) {
            var coords : Array<Dynamic> = getCoords(e);
            var j : Int = 0;
            while(j < coords.length) {
                grid[coords[j].x][coords[j].y].push(e);
                j++;
            }
        }

    }

    public function loadMap(m : Map, e : Entity) : Void {
        var i : Int = 0;
        while(i < m.widthInTiles) {
            var j : Int = 0;
            while(j < m.heightInTiles) {
                if(!m.collisionInfo[i][j]) {
                    j++;
                    continue;
                }

                grid[i][j].push(e);
                j++;
            }
            i++;
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

        var slotX : Int = Math.floor(e.x / gridWidth);
        while(slotX <= endSlotX) {
            var slotY : Int = Math.floor(e.y / gridHeight);
            while(slotY <= endSlotY) {
                if(slotX < 0 || slotX >= widthInTiles || slotY < 0 || slotY >= heightInTiles)  {
                    slotY++;
                    continue;

                }
                result.push(new Vec(slotX, slotY));
                slotY++;
            }
            slotX++;
        }
        return result;
    }

    /* Return the entity at x, y in the spatial hash. */    public function getAt(x : Int, y : Int) : Set<Entity> {
        return new Set<Entity>(grid[x][y]);
    }

    /* Returns whether the entity e collides with any object in the hash,
       excluding itself. */
    public function collides(e : Entity) : Bool {
        var coords : Array<Dynamic> = getCoords(e);
        var i : Int = 0;
        while(i < coords.length) {
            if (coords[i].x >= grid.length || coords[i].y >= grid[0].length ||
                coords[i].x < 0 || coords[i].y < 0) continue;

            var arr : Array<Dynamic> = grid[coords[i].x][coords[i].y];
            var j : Int = 0;
            while(j < arr.length) {
                if(arr[j] == e)
                     {
                    j++;
                    continue;
                }
;
                if(arr[j].touchingRect(e))  {
                    return true;
                }
                j++;
            }
            i++;
        }
        return false;
    }

    /* Return every entity the entity e collides with, excluding itself. */    public function getColliders(e : Entity) : Set<Entity> {
        var result : Set<Entity> = new Set<Entity>();
        var coords : Array<Dynamic> = getCoords(e);
        var i : Int = 0;
        while(i < coords.length) {
            var arr : Array<Dynamic> = grid[coords[i].x][coords[i].y];
            var j : Int = 0;
            while(j < arr.length) {
                if(arr[j] == e)
                     {
                    j++;
                    continue;
                }
;
                if(arr[j].touchingRect(e))  {
                    result.add(arr[j]);
                }
                j++;
            }
            i++;
        }
        return result;
    }

}

