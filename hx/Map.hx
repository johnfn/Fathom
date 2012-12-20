import flash.display.Sprite;
import flash.geom.Point;
import flash.utils.Dictionary;
import flash.geom.Rectangle;
import mx.core.BitmapAsset;
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
		public var transparency : Array<Dynamic>;
	//TODO POST LD
		var tiles : Array<Dynamic>;
	// Cached array of collideable tiles.
		public var collisionInfo : Array<Dynamic>;
	var topLeftCorner : Vec;
	var exploredMaps : Dynamic;
	var graphics : Entity;
	var persistentItemMapping : Dynamic;
	var persistent : Dynamic;
	public var sizeVector : Vec;
	function new(widthInTiles : Int, heightInTiles : Int, tileSize : Int) {
		data = [];
		transparency = [];
		tiles = [];
		collisionInfo = [];
		topLeftCorner = new Vec(0, 0);
		exploredMaps = { };
		persistentItemMapping = { };
		persistent = { };
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
		tiles = Util.make2DArrayFn(widthInTiles, heightInTiles, function(x : Int, y : Int) : Tile {
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
		var bAsset : BitmapAsset = Type.createInstance(mapClass, []);
		var bData : BitmapData = bAsset.bitmapData;
		this.grounds = groundList;
		this.persistentItemMapping = persistentItemMapping;
		data = Util.make2DArray(bData.width, bData.height, undefined);
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
		var processedItems : Array<Dynamic> = [];
		var items : Array<Dynamic> = persistent[topLeftCorner.asKey()] || [];
		var i : Int = 0;
		while(i < items.length) {
			if(!items[i].destroyed)  {
				items[i].removeFromFathom();
				processedItems.push(items[i]);
			}
			i++;
		}
		persistent[topLeftCorner.asKey()] = processedItems;
	}

	function updatePersistentItems(diff : Vec) : Void {
		hideCurrentPersistentItems();
		for(e in Fathom.entities.select("!persistent")/* AS3HX WARNING could not determine type for var: e exp: ECall(EField(EField(EIdent(Fathom),entities),select),[EConst(CString(!persistent))]) type: null*/) {
			e.destroy();
		}

		topLeftCorner.add(diff);
		dumpToGraphics();
		addNewPersistentItems();
	}

	function isGround(c : Color, s : String) : Bool {
		return grounds.indexOf(c.toString()) != -1 && c.toString() != s;
	}

	function fancyProcessing(itemData : Dynamic, c : String, x : Int, y : Int) : Vec {
		var result : Vec = Reflect.field(itemData, "spritesheet").clone();
		if(Lambda.has(itemData, "roundOutEdges"))  {
			/*
        var X:int = 0;
        var Y:int = 1;
        */var locX : Int = topLeftCorner.x + x;
			var locY : Int = topLeftCorner.y + y;
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
		if(Lambda.has(itemData && Util.randRange(0, 5) == 3, "randoEdges"))  {
			result.x += Util.randRange(-1, 2);
			result.y += Util.randRange(-1, 2);
		}
		if(Lambda.has(itemData, "fancyEdges"))  {
			var cstr : String = c.toString();
			var empty : String = (new Color(255, 255, 255).toString());
			var locX : Int = topLeftCorner.x + x;
			var locY : Int = topLeftCorner.y + y;
			// Horizontal wall, ground below.
			if(!isGround(data[locX - 1][locY], cstr) && !isGround(data[locX + 1][locY], cstr) && isGround(data[locX][locY + 1], cstr))  {
				result.y += 2;
			}
;
			// Horizontal wall, ground above.
			if(data[locX - 1][locY].toString() == cstr && data[locX + 1][locY].toString() == cstr && isGround(data[locX][locY - 1], cstr))  {
				result.y -= 2;
			}
;
			// Vertical wall, ground to the left.
			if(data[locX][locY - 1].toString() == cstr && data[locX][locY + 1].toString() == cstr && isGround(data[locX - 1][locY], cstr))  {
				result.x -= 2;
			}
;
			// Vertical wall, ground to the right.
			if(!isGround(data[locX][locY - 1], cstr) && !isGround(data[locX][locY + 1], cstr) && isGround(data[locX + 1][locY], cstr))  {
				result.x += 2;
			}
;
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
		var itemData : Dynamic = persistentItemMapping[c.toString()];
		if(!(Lambda.has(itemData, "type"))) 
			return;
		var e : Entity;
		if(Lambda.has(itemData, "args"))  {
			// TODO: new ItemData["type"].call(args)
			e = new ItemData()["type"](itemData.args);
		}

		else  {
			e = new ItemData()["type"]();
		}

		if(!(Lambda.has(itemData, "special")))  {
			e.loadSpritesheet(Reflect.field(itemData, "gfx"), C.dim, Reflect.field(itemData, "spritesheet") || new Vec(0, 0));
		}
		e.setPos(new Vec(x * tileSize, y * tileSize));
		if(e.groups().contains("persistent"))  {
			persistent[topLeftCorner.asKey()].push(e);
		}
		if(e.groups().contains("remember-loc"))  {
			trace("I never did this LOL");
		}
	}

	function addNewPersistentItems() : Void {
		var seenBefore : Bool = exploredMaps[topLeftCorner.asKey()];
		this.clearTiles();
		// Scan the map, adding every object to our list of persistent items for this map.
		if(!seenBefore)  {
			// If we haven't seen it before, load in all the persistent items.
			persistent[topLeftCorner.asKey()] = [];
			var x : Int = 0;
			while(x < widthInTiles) {
				var y : Int = 0;
				while(y < heightInTiles) {
					trace(topLeftCorner);
					var dataColor : Color = data[topLeftCorner.x + x][topLeftCorner.y + y];
					addPersistentItem(dataColor, x, y);
					y++;
				}
				x++;
			}
		}

		else  {
			// Add all persistent items.
			persistent[topLeftCorner.asKey()].map(function(e : Dynamic, i : Int, a : Array<Dynamic>) : Void {
				e.addToFathom();
				if(e.groups().contains("remember-loc"))  {
					e.resetLoc();
				}
			}
);
		}
;
		// Cache every persistent item in the 2D array of tiles.
		var persistingItems : Array<Dynamic> = persistent[topLeftCorner.asKey()];
		var i : Int = 0;
		while(i < persistingItems.length) {
			var e : Entity = persistingItems[i];
			if(e.isStatic)  {
				var xCoord : Int = Math.floor(e.x / this.tileSize);
				var yCoord : Int = Math.floor(e.y / this.tileSize);
				tiles[xCoord][yCoord] = e;
			}
			i++;
		}
		exploredMaps[topLeftCorner.asKey()] = true;
	}

	public function itemSwitchedMaps(leftScreen : Entity) : Void {
		var smallerSize : Vec = sizeVector.clone().subtract(leftScreen.width);
		var dir : Vec = leftScreen.rect().divide(smallerSize).map(Math.floor);
		var newMapLoc : Vec = topLeftCorner.clone().add(dir.clone().multiply(widthInTiles));
		var newItemLoc : Vec = leftScreen.rect().add(dir.clone().multiply(-1).multiply(sizeVector.clone().subtract(tileSize * 2)));
		persistent[topLeftCorner.asKey()].remove(leftScreen);
		if(!persistent[newMapLoc.asKey()])  {
			persistent[newMapLoc.asKey()] = [];
		}
		persistent[newMapLoc.asKey()].push(leftScreen);
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
		return;
		persistent[topLeftCorner.asKey()].map(function(e : Dynamic, i : Int, a : Array<Dynamic>) : Void {
			e.visible = val;
		}
);
		return val;
	}

	public function collides(i : Dynamic) : Bool {
		if(Std.is(i, Vec))  {
			return collidesPt(try cast(i, Vec) catch(e:Dynamic) null);
		}
		if(Std.is(i, Rect))  {
			return collidesRect(try cast(i, Rect) catch(e:Dynamic) null);
		}
		throw new Error("Unsupported type for Map#collides.");
	}

	public function update() : Void {
		var items : Array<Dynamic> = persistent[topLeftCorner.asKey()];
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

	static var cachedAssets : Dictionary = new Dictionary();
	function dumpToGraphics() : Void {
		graphics = new Entity();
		while(graphics.numChildren > 0) {
			graphics.removeChildAt(0);
		}

		// Write out the tiles to imgData
		var imgData : BitmapData = new BitmapData(widthInTiles * tileSize, heightInTiles * tileSize, true, 0xFFFFFFFF);
		var x : Int = 0;
		while(x < widthInTiles) {
			var y : Int = 0;
			while(y < heightInTiles) {
				var c : Color = data[topLeftCorner.x + x][topLeftCorner.y + y];
				if(!(Lambda.has(persistentItemMapping, c.toString())))  {
					if(c.toString() != "#ffffff")  {
						Util.log("Color without data: " + c.toString());
					}
					 {
						y++;
						continue;
					}

				}
				var itemData : Dynamic = persistentItemMapping[c.toString()];
				if(!(Lambda.has(itemData, "gfx"))) 
					 {
					y++;
					continue;
				}
;
				var ss : Vec = fancyProcessing(itemData, c.toString(), x, y).multiply(25);
				// Hardcore hardcoding TODO
				var key : String = Util.className(itemData.gfx);
				var bAsset : BitmapAsset;
				if(!(Reflect.field(cachedAssets, key)))  {
					Reflect.setField(cachedAssets, key, new itemdata.Gfx());
				}
				if(!isGround(c, ""))  {
					collisionInfo[x][y] = true;
				}
				transparency[x][y] = Lambda.has(itemData, "transparent");
				bAsset = Reflect.field(cachedAssets, key);
				imgData.copyPixels(bAsset.bitmapData, new Rectangle(ss.x, ss.y, 25, 25), new Point(x * 25, y * 25));
				y++;
			}
			x++;
		}
		// I have this suspicion that I don't need to keep adding the bitmapData TODO
		// Add imgData to screen.
		var bmp : Bitmap = new Bitmap(imgData);
		graphics.addChild(bmp);
		graphics.graphics.drawRect(0, 0, 25, 25);
	}

	public function loadNewMap(diff : Vec) : Map {
		collisionInfo = Util.make2DArray(widthInTiles, heightInTiles, false);
		transparency = Util.make2DArray(widthInTiles, heightInTiles, true);
		diff.multiply(new Vec(widthInTiles, heightInTiles));
		updatePersistentItems(diff);
		Fathom.grid = new SpatialHash(new EntitySet());
		Fathom.grid.loadMap(this, bogusmapentry);
		Fathom.container.sortDepths();
		return this;
	}

	public function getTopLeftCorner() : Vec {
		return this.topLeftCorner.clone();
	}

}

class BogusMapEntry extends Entity {

	function new(x : Int = 0, y : Int = 0) {
		super(x, y, 25, 25);
	}

	// holy freaking christ
		// hack levels are currently off the charts
		override public function touchingRect(rect : Entity) : Bool {
		return true;
	}

	override public function groups() : Set {
		return super.groups().concat("map");
	}

}

