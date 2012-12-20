package {
	/* Collision detection in Fathom is done with a data structure known as a Spatial Hash.
	   If you're not familiar with a Spatial Hash, you can just think of it as a 2D array
	   of every entity. */
	public class SpatialHash {
		private var grid:Array;

		private var widthInTiles:int = 25;
		private var heightInTiles:int = 25;
		private var gridWidth:int = 25;
		private var gridHeight:int = 25;

		function SpatialHash(list:EntitySet) {
		    grid = Util.make2DArrayFn(widthInTiles, heightInTiles, function():Array { return []; });

		    for each (var e:Entity in list) {
		    	var coords:Array = getCoords(e);

		        for (var j:int = 0; j < coords.length; j++) {
			        grid[coords[j].x][coords[j].y].push(e);
		        }
		    }
		}

		public function loadMap(m:Map, e:Entity):void {
			for (var i:int = 0; i < m.widthInTiles; i++) {
				for (var j:int = 0; j < m.heightInTiles; j++) {
					if (!m.collisionInfo[i][j]) continue;

					grid[i][j].push(e);
				}
			}
		}

		/* Return the coordinates that the provided entity hashes to. Could be more than
		   one coordinate. An entity with size exactly the gridsize, positioned exactly
		   on a grid, will only exist in one coordinate. */
	    private function getCoords(e:Entity):Array {
	      var result:Array = [];

	      var endSlotX:int = (e.x + e.width) / gridWidth;
	      if ((e.x + e.width) % gridWidth == 0) endSlotX--;

	      var endSlotY:int = (e.y + e.height) / gridHeight;
	      if ((e.y + e.height) % gridHeight == 0) endSlotY--;

	      for (var slotX:int = (e.x / gridWidth); slotX <= endSlotX; slotX++) {
	        for (var slotY:int = (e.y / gridHeight); slotY <= endSlotY; slotY++) {
	          if (slotX < 0 || slotX >= widthInTiles || slotY < 0 || slotY >= heightInTiles) {
	            continue;
	          }

	          result.push(new Vec(slotX, slotY));
	        }
	      }

	      return result;
	    }

	    /* Return the entity at x, y in the spatial hash. */
		public function getAt(x:int, y:int):EntitySet {
			return new EntitySet(grid[x][y]);
		}

		/* Returns whether the entity e collides with any object in the hash,
		   excluding itself. */
		public function collides(e:Entity):Boolean {
			var coords:Array = getCoords(e);

			for (var i:int = 0; i < coords.length; i++) {
		        var arr:Array = grid[coords[i].x][coords[i].y];

		        for (var j:int = 0; j < arr.length; j++) {
		        	if (arr[j] == e) continue;

		        	if (arr[j].touchingRect(e)) {
		        		return true;
		        	}
		        }
			}

			return false;
		}

		/* Return every entity the entity e collides with, excluding itself. */
	    public function getColliders(e:Entity):EntitySet {
	      var result:EntitySet = new EntitySet();
	      var coords:Array = getCoords(e);

	      for (var i:int = 0; i < coords.length; i++) {
	        var arr:Array = grid[coords[i].x][coords[i].y];

	        for (var j:int = 0; j < arr.length; j++) {
	          if (arr[j] == e) continue;

              if (arr[j].touchingRect(e)) {
	            result.add(arr[j]);
	          }
	        }
	      }

	      return result;
	    }
	}
}