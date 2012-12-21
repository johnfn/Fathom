import flash.display.Sprite;
import flash.geom.Point;
import flash.utils.TypedDictionary;
import flash.geom.Rectangle;
import flash.display.BitmapData;
import flash.display.Bitmap;
import Color;
import Util;
import Entity;

//TODO: Map should extend Entity. Will need to change update loop.
class Map extends Rect {
	public var tileSize(getTileSize, never) : Int;
	public var widthInTiles(getWidthInTiles, never) : Int;
	public var heightInTiles(getHeightInTiles, never) : Int;
	public var visible(never, setVisible) : Bool;

	var _widthInTiles : Int;
	var _heightInTiles : Int;
	var bogusmapentry : Entity;
	var grounds : Array<Dynamic>;
	var _tileSize : Int;
	var data : Array<Dynamic>;
	// Color data from the map.

	var tiles : Array<Array<Entity>>;
	// Cached array of collideable tiles.

	public var collisionInfo : Array<Dynamic>;
	var topLeftCorner : Vec;
	var exploredMaps : Dynamic;
	var graphics : Entity;
	// Mapping between colors and items.
	var persistentItemMapping : Dynamic;
	var persistent : TypedDictionary<String, Array<Entity>>;
	public var sizeVector : Vec;

	function new(widthInTiles : Int, heightInTiles : Int, tileSize : Int) {
		data = [];
		tiles = [];
		collisionInfo = [];
		topLeftCorner = new Vec(0, 0);
		exploredMaps = { };
		persistentItemMapping = { };
		persistent = new TypedDictionary();
		super(0, 0, widthInTiles * tileSize, heightInTiles * tileSize);
		Util.assert(widthInTiles == heightInTiles);
		this.sizeVector = new Vec(width, height);
		this._widthInTiles = widthInTiles;
		this._heightInTiles = heightInTiles;
		this._tileSize = tileSize;
		this.clearTiles();
		bogusmapentry = new BogusMapEntry();
	}

	function clearTiles() : Void {
		tiles = Util.make2DArrayFn(widthInTiles, heightInTiles, function(x : Int, y : Int) : Entity {
			return null;
		}
);
	}

	public function getTileSize() : Int {
		return _tileSize;
	}

	public function getWidthInTiles() : Int {
		return _widthInTiles;
	}

	public function getHeightInTiles() : Int {
		return _heightInTiles;
	}

	public function outOfBoundsPt(x : Int, y : Int) : Bool {
		if(x < 0)
			return true;
		if(x >= width)
			return true;
		if(y < 0)
			return true;
		if(y >= height)
			return true;
		return false;
	}

	public function fromImage(mapClass : Class<Dynamic>, groundList : Array<Dynamic>, persistentItemMapping : Dynamic) : Map {
		var bAsset = Type.createInstance(mapClass, []);
		var bData : BitmapData = bAsset.bitmapData;
		this.grounds = groundList;
		this.persistentItemMapping = persistentItemMapping;
		data = Util.make2DArray(bData.width, bData.height, null);
		var x : Int = 0;
		while(x < bData.width) {
			var y : Int = 0;
			while(y < bData.height) {
				data[x][y] = Color.fromInt(bData.getPixel(x, y));
				y++;
			}
			x++;
		}
		return this;
	}

	function hideCurrentPersistentItems() : Void {
		var processedItems : Array<Entity> = [];
		var k:String = topLeftCorner.asKey();
		var items : Array<Dynamic> = persistent.exists(k) ? persistent.get(k) : [];
		var i : Int = 0;
		while(i < items.length) {
			if(!items[i].destroyed)  {
				items[i].removeFromFathom();
				processedItems.push(items[i]);
			}
			i++;
		}
		persistent.set(topLeftCorner.asKey(), processedItems);
	}

	function updatePersistentItems(diff : Vec) : Void {
		hideCurrentPersistentItems();
		for(e in Fathom.entities.select(["!persistent"])) {
			e.destroy();
		}

		topLeftCorner.add(diff);
		dumpToGraphics();
		addNewPersistentItems();
	}

	function isGround(c : Color, s : String) : Bool {
		return Lambda.indexOf(grounds, c.toString) != -1 && c.toString() != s;
	}

	function fancyProcessing(itemData : Dynamic, c : String, x : Int, y : Int) : Vec {
		var result : Vec = Reflect.field(itemData, "spritesheet").clone();
		if(Lambda.has(itemData, "roundOutEdges"))  {
			/*
	        var X:int = 0;
	        var Y:int = 1;
	        */

	        var locX : Int = Std.int(topLeftCorner.x) + x;
			var locY : Int = Std.int(topLeftCorner.y) + y;
			if(locY == 0 || data[locX][locY - 1].toString() != c.toString())  {
				result.y--;
			}
			if(locX == 0 || data[locX - 1][locY].toString() != c.toString())  {
				result.x--;
			}
			if(locY != heightInTiles - 1 && data[locX][locY + 1].toString() != c.toString())  {
				result.y++;
			}
			if(locX == widthInTiles - 1 || data[locX + 1][locY].toString() != c.toString())  {
				result.x++;
			}
			if(locY != 0 && data[locX][locY - 1].toString() != c.toString() && locY != heightInTiles - 1 && data[locX][locY + 1].toString() != c.toString())  {
				result.y--;
			}
		}
		if(Lambda.has(itemData, "randoEdges") && Util.randRange(0, 5) == 3)  {
			result.x += Util.randRange(-1, 2);
			result.y += Util.randRange(-1, 2);
		}
		if(Lambda.has(itemData, "fancyEdges"))  {
			var cstr : String = c.toString();
			var empty : String = (new Color(255, 255, 255).toString());
			var locX : Int = Std.int(topLeftCorner.x) + x;
			var locY : Int = Std.int(topLeftCorner.y) + y;
			// Horizontal wall, ground below.
			if(!isGround(data[locX - 1][locY], cstr) && !isGround(data[locX + 1][locY], cstr) && isGround(data[locX][locY + 1], cstr))  {
				result.y += 2;
			}
			// Horizontal wall, ground above.
			if(data[locX - 1][locY].toString() == cstr && data[locX + 1][locY].toString() == cstr && isGround(data[locX][locY - 1], cstr))  {
				result.y -= 2;
			}
			// Vertical wall, ground to the left.
			if(data[locX][locY - 1].toString() == cstr && data[locX][locY + 1].toString() == cstr && isGround(data[locX - 1][locY], cstr))  {
				result.x -= 2;
			}
			// Vertical wall, ground to the right.
			if(!isGround(data[locX][locY - 1], cstr) && !isGround(data[locX][locY + 1], cstr) && isGround(data[locX + 1][locY], cstr))  {
				result.x += 2;
			}
			// - - -
			// - x x
			// - x -
			if(data[locX + 1][locY].toString() == cstr && data[locX][locY + 1].toString() == cstr && isGround(data[locX - 1][locY], cstr) && isGround(data[locX][locY - 1], cstr))  {
				result.x -= 2;
				result.y -= 2;
			}

			else if(data[locX + 1][locY].toString() == cstr && data[locX][locY + 1].toString() == cstr)  {
				// x x x
				// x x x
				// x x -
				result.x += 2;
				result.y += 1;
			}
;
			// - - -
			// x x -
			// - x -
			if(data[locX - 1][locY].toString() == cstr && data[locX][locY + 1].toString() == cstr && isGround(data[locX + 1][locY], cstr) && isGround(data[locX][locY - 1], cstr))  {
				result.x += 2;
				result.y -= 2;
			}

			else if(data[locX - 1][locY].toString() == cstr && data[locX][locY + 1].toString() == cstr)  {
				result.x -= 2;
				result.y += 1;
			}
;
			// - x -
			// x x -
			// - - -
			if(data[locX - 1][locY].toString() == cstr && data[locX][locY - 1].toString() == cstr && isGround(data[locX + 1][locY], cstr) && isGround(data[locX][locY + 1], cstr))  {
				result.x += 2;
				result.y += 2;
			}

			else if(data[locX - 1][locY].toString() == cstr && data[locX][locY - 1].toString() == cstr)  {
				result.x -= 2;
				result.y -= 1;
			}
;
			// - x -
			// - x x
			// - - -
			if(data[locX + 1][locY].toString() == cstr && data[locX][locY - 1].toString() == cstr && isGround(data[locX - 1][locY], cstr) && isGround(data[locX][locY + 1], cstr))  {
				result.x -= 2;
				result.y += 2;
			}

			else if(data[locX + 1][locY].toString() == cstr && data[locX][locY - 1].toString() == cstr)  {
				result.x += 2;
				result.y -= 1;
			}
;
		}
		return result;
	}

	function addPersistentItem(c : Color, x : Int, y : Int) : Void {
		if(!(Lambda.has(persistentItemMapping, c.toString())))  {
			if(c.toString() != "#ffffff")  {
				Util.log("Color without data: " + c.toString());
			}
			return;
		}
		var itemData : Dynamic = persistentItemMapping.get(c.toString());
		if(!(Lambda.has(itemData, "type")))
			return;

		var e : Entity;
		if(Lambda.has(itemData, "args"))  {
			// TODO: new ItemData["type"].call(args)
			e = Type.createInstance(itemData, [itemData.args]);
		} else  {
			e = Type.createInstance(itemData, []);
		}

		if(!(Lambda.has(itemData, "special")))  {
			var ssLoc:Vec;
			if (Reflect.hasField(itemData, "spritesheet")) {
				ssLoc = Reflect.field(itemData, "spritesheet");
			} else {
				ssLoc = new Vec(0, 0);
			}
			e.loadSpritesheet(Reflect.field(itemData, "gfx"), new Vec(_tileSize, _tileSize), ssLoc);
		}
		e.setPos(new Vec(x * tileSize, y * tileSize));
		if(e.groups().contains("persistent"))  {
			persistent.get(topLeftCorner.asKey()).push(e);
		}
		if(e.groups().contains("remember-loc"))  {
			trace("I never did this LOL");
		}
	}

	function addNewPersistentItems() : Void {
		var seenBefore : Bool = exploredMaps.get(topLeftCorner.asKey());
		this.clearTiles();
		// Scan the map, adding every object to our list of persistent items for this map.
		if(!seenBefore)  {
			// If we haven't seen it before, load in all the persistent items.
			persistent.set(topLeftCorner.asKey(), []);
			var x : Int = 0;
			while(x < widthInTiles) {
				var y : Int = 0;
				while(y < heightInTiles) {
					var dataColor : Color = data[Std.int(topLeftCorner.x + x)][Std.int(topLeftCorner.y + y)];
					addPersistentItem(dataColor, x, y);
					y++;
				}
				x++;
			}
		}

		else  {
			// Add all persistent items.
			Lambda.map(persistent.get(topLeftCorner.asKey()), function(e : Entity) : Void {
				e.addToFathom();
			});
		};

		// Cache every persistent item in the 2D array of tiles.
		var persistingItems : Array<Dynamic> = persistent.get(topLeftCorner.asKey());

		for (e in persistingItems) {
			if(e.isStatic)  {
				var xCoord : Int = Math.floor(e.x / this.tileSize);
				var yCoord : Int = Math.floor(e.y / this.tileSize);
				tiles[xCoord][yCoord] = e;
			}
		}
		exploredMaps.set(topLeftCorner.asKey(), true);
	}

	public function itemSwitchedMaps(leftScreen : Entity) : Void {
		var smallerSize : Vec = sizeVector.clone().subtract(leftScreen.width);
		var dir : Vec = leftScreen.rect().divide(smallerSize).map(Math.floor);
		var newMapLoc : Vec = topLeftCorner.clone().add(dir.clone().multiply(widthInTiles));
		var newItemLoc : Vec = leftScreen.rect().add(dir.clone().multiply(-1).multiply(sizeVector.clone().subtract(tileSize * 2)));

		persistent.get(topLeftCorner.asKey()).remove(leftScreen);
		if(!persistent.exists(newMapLoc.asKey()))  {
			persistent.set(newMapLoc.asKey(), []);
		}
		persistent.get(newMapLoc.asKey()).push(leftScreen);
		leftScreen.setPos(newItemLoc);
		leftScreen.removeFromFathom();
	}

	function collidesPt(other : Vec) : Bool {
		if(!contains(other))
			return true;
		var xPt : Int = Math.floor(other.x / this.tileSize);
		var yPt : Int = Math.floor(other.y / this.tileSize);
		return tiles[xPt][yPt] != null;
	}

	function collidesRect(other : Rect) : Bool {
		var xStart : Int = Math.floor(other.x / this.tileSize);
		var xStop : Int = Math.floor((other.x + other.width) / this.tileSize);
		var yStart : Int = Math.floor(other.y / this.tileSize);
		var yStop : Int = Math.floor((other.y + other.height) / this.tileSize);
		var x : Int = xStart;
		while(x < xStop + 1) {
			var y : Int = yStart;
			while(y < yStop + 1) {
				if(0 <= x && x < widthInTiles && 0 <= y && y < heightInTiles)  {
					if(tiles[x][y] != null)  {
						return true;
					}
				}
				y++;
			}
			x++;
		}
		if(!makeBigger(3).contains(other))
			return true;
		return false;
	}

	public function setVisible(val : Bool) : Bool {
		Util.assert(false);
		return false;
		/*
		persistent.get(topLeftCorner.asKey()).map(function(e : Dynamic, i : Int, a : Array<Dynamic>) : Void {
			e.visible = val;
		}
);
		return val;
		*/
	}

	public function collides(i : Dynamic) : Bool {
		if(Std.is(i, Vec)) {
			untyped {
				return collidesPt(i);
			}
		}
		if(Std.is(i, Rect))  {
			untyped {
				return collidesRect(i);
			}
		}
		throw "Unsupported type for Map#collides.";
	}

	public function update() : Void {
		var items : Array<Dynamic> = persistent.get(topLeftCorner.asKey());
		return;
		var i : Int = 0;
		while(i < items.length) {
			if(Hooks.hasLeftMap(items[i], this))  {
				Util.assert(!items[i].groups().contains("Character"));
				this.itemSwitchedMaps(items[i]);
			}
			i++;
		}
	}

	override public function toString() : String {
		return "[Map]";
	}

	public function modes() : Array<Dynamic> {
		return [0];
	}

	public function loadNewMapAbs(abs : Vec) : Map {
		var diff : Vec = abs.subtract(getTopLeftCorner().clone().divide(25));
		loadNewMap(diff);
		return this;
	}

	static var cachedAssets : TypedDictionary<String, Dynamic> = new TypedDictionary();
	function dumpToGraphics() : Void {
		graphics = new Entity();
		while(graphics.numChildren > 0) {
			graphics.removeChildAt(0);
		}

		// Write out the tiles to imgData
		var imgData : BitmapData = new BitmapData(widthInTiles * tileSize, heightInTiles * tileSize, true, 0xFFFFFFFF);
		for (x in 0...widthInTiles - 1) {
			for (y in 0...heightInTiles - 1) {
				var c : Color = data[Std.int(topLeftCorner.x + x)][Std.int(topLeftCorner.y + y)];
				if(!(Lambda.has(persistentItemMapping, c.toString())))  {
					if(c.toString() != "#ffffff")  {
						Util.log("Color without data: " + c.toString());
						continue;
					}

				}
				var itemData : Dynamic = persistentItemMapping.get(c.toString());
				if(!(Lambda.has(itemData, "gfx"))) {
					continue;
				};

				var ss : Vec = fancyProcessing(itemData, c.toString(), x, y).multiply(25);
				// Hardcore hardcoding TODO
				var key : String = Util.className(itemData.gfx);
				var bAsset;

				if (!cachedAssets.exists(key)) {
					cachedAssets.set(key, Type.createInstance(itemData.Gfx, []));
				}

				if(!isGround(c, ""))  {
					collisionInfo[x][y] = true;
				}
				bAsset = cachedAssets.get(key);
				imgData.copyPixels(bAsset.bitmapData, new Rectangle(ss.x, ss.y, 25, 25), new Point(x * 25, y * 25));
			}
		}
		// I have this suspicion that I don't need to keep adding the bitmapData TODO
		// Add imgData to screen.
		var bmp : Bitmap = new Bitmap(imgData);
		graphics.addDO(bmp);
	}

	public function loadNewMap(diff : Vec) : Map {
		collisionInfo = Util.make2DArray(widthInTiles, heightInTiles, false);
		diff.multiply(new Vec(widthInTiles, heightInTiles));
		updatePersistentItems(diff);
		Fathom.grid = new SpatialHash(new Set<Entity>());
		Fathom.grid.loadMap(this, bogusmapentry);
		Fathom.container.sortDepths();
		return this;
	}

	public function getTopLeftCorner() : Vec {
		return this.topLeftCorner.clone();
	}

}

class BogusMapEntry extends Entity {

	public function new(x : Int = 0, y : Int = 0) {
		super(x, y, 25, 25);
	}

	// holy freaking christ
		// hack levels are currently off the charts
		override public function touchingRect(rect : Entity) : Bool {
		return true;
	}

	override public function groups() : Set<String> {
		return super.groups().concat("map");
	}

}

