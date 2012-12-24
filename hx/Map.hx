import flash.display.Sprite;
import flash.geom.Point;
import flash.utils.TypedDictionary;
import flash.geom.Rectangle;
import flash.display.BitmapData;
import flash.display.Bitmap;
import Color;
import Util;
import Entity;

using Lambda;

typedef ItemDetail = {
    var color: String;
    var spritesheet: Vec;
    var gfx: Class<Dynamic>;

    // Optional settings

    @:optional var type: Class<Dynamic>;
    @:optional var roundOutEdges: Bool;
    @:optional var fancyEdges: Bool;
    @:optional var randoEdges: Bool;

    // Private use by Map
    @:optional var special:Bool;
}

//TODO: Map should extend Entity. Will need to change update loop.
class Map extends Rect {
    public var tileSize(getTileSize, never) : Int;
    public var widthInTiles(getWidthInTiles, never) : Int;
    public var heightInTiles(getHeightInTiles, never) : Int;
    public var visible(never, setVisible) : Bool;

    var _widthInTiles : Int;
    var _heightInTiles : Int;
    var bogusmapentry : Entity;
    var grounds : Array<String>;
    var _tileSize : Int;
    var data : Array<Array<Color>>;
    // Color data from the map.

    var tiles : Array<Array<Entity>>;
    // Cached array of collideable tiles.

    public var collisionInfo : Array<Array<Bool>>;
    var topLeftCorner : Vec;
    var exploredMaps : TypedDictionary<String, Bool>;
    var _graphics : Entity;
    // Mapping between colors and items.
    var persistentItemMapping : TypedDictionary<String, ItemDetail>;
    var persistent : TypedDictionary<String, Array<Entity>>;
    public var sizeVector : Vec;

    public var graphics(getGraphics, setGraphics): Entity;

    public function getGraphics(): Entity {
        return _graphics;
    }

    private function setGraphics(e: Entity): Entity {
        return _graphics = e;
    }

    public function new(widthInTiles : Int, heightInTiles : Int, tileSize : Int) {
        data = [];
        tiles = [];
        _graphics = new Entity();
        collisionInfo = [];
        topLeftCorner = new Vec(0, 0);
        exploredMaps = new TypedDictionary();
        persistentItemMapping = new TypedDictionary();
        persistent = new TypedDictionary();
        super(0, 0, widthInTiles * tileSize, heightInTiles * tileSize);
        Util.assert(widthInTiles == heightInTiles);
        this.sizeVector = new Vec(width, height);
        this._widthInTiles = widthInTiles;
        this._heightInTiles = heightInTiles;
        this._tileSize = tileSize;
        this.clearTiles();
        bogusmapentry = new BogusMapEntry(tileSize);
    }

    function clearTiles() : Void {
        tiles = Util.make2DArrayFn(widthInTiles, heightInTiles, function(x : Int, y : Int) : Entity {
            return null;
        });
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
        return (x < 0 || x >= width || y < 0 || y >= height);
    }

    public function fromImage(mapClass : Class<Dynamic>, groundList : Array<String>, mappings : Array<ItemDetail>) : Map {
        // Load ground list
        this.grounds = groundList;

        // Load item mapping
        for (s in mappings) {
            this.persistentItemMapping.set(s.color, s);
        }

        // Load data from image.
        var bData = Type.createInstance(mapClass, []);
        data = Util.make2DArray(bData.width, bData.height, null);

        for (x in 0...bData.width) {
            for (y in 0...bData.height) {
                data[x][y] = Color.fromInt(bData.getPixel(x, y));
            }
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
        for(e in Fathom.entities.select([Set.doesntHaveGroup("persistent")])) {
            e.destroy();
        }

        topLeftCorner.add(diff);
        dumpToGraphics();
        addNewPersistentItems();
    }

    function isGround(c : String, s : String) : Bool {
        return grounds.has(c) && c.toString() != s;
    }

    function fancyProcessing(itemData : ItemDetail, c : String, x : Int, y : Int) : Vec {
        var result : Vec = itemData.spritesheet.clone();
        if(itemData.roundOutEdges) {
            var locX : Int = Std.int(topLeftCorner.x) + x;
            var locY : Int = Std.int(topLeftCorner.y) + y;
            if(locY == 0 || data[locX][locY - 1].toString() != c.toString())  {
                result.y--;
            }
            if(locX == 0 || data[locX - 1][locY].toString() != c)  {
                result.x--;
            }
            if(locY != heightInTiles - 1 && data[locX][locY + 1].toString() != c)  {
                result.y++;
            }
            if(locX == widthInTiles - 1 || data[locX + 1][locY].toString() != c)  {
                result.x++;
            }
            if(locY != 0 && data[locX][locY - 1].toString() != c && locY != heightInTiles - 1 && data[locX][locY + 1].toString() != c)  {
                result.y--;
            }
        }

        if(itemData.randoEdges && Util.randRange(0, 5) == 3)  {
            result.x += Util.randRange(-1, 2);
            result.y += Util.randRange(-1, 2);
        }

        if(itemData.fancyEdges)  {
            var empty : String = (new Color(255, 255, 255).toString());
            var locX : Int = Std.int(topLeftCorner.x) + x;
            var locY : Int = Std.int(topLeftCorner.y) + y;
            // Horizontal wall, ground below.
            if(!isGround(data[locX - 1][locY].toString(), c) && !isGround(data[locX + 1][locY].toString(), c) && isGround(data[locX][locY + 1].toString(), c))  {
                result.y += 2;
            }
            // Horizontal wall, ground above.
            if(data[locX - 1][locY].toString() == c && data[locX + 1][locY].toString() == c && isGround(data[locX][locY - 1].toString(), c))  {
                result.y -= 2;
            }
            // Vertical wall, ground to the left.
            if(data[locX][locY - 1].toString() == c && data[locX][locY + 1].toString() == c && isGround(data[locX - 1][locY].toString(), c))  {
                result.x -= 2;
            }
            // Vertical wall, ground to the right.
            if(!isGround(data[locX][locY - 1].toString(), c) && !isGround(data[locX][locY + 1].toString(), c) && isGround(data[locX + 1][locY].toString(), c))  {
                result.x += 2;
            }
            // - - -
            // - x x
            // - x -
            if(data[locX + 1][locY].toString() == c && data[locX][locY + 1].toString() == c && isGround(data[locX - 1][locY].toString(), c) && isGround(data[locX][locY - 1].toString(), c))  {
                result.x -= 2;
                result.y -= 2;
            } else if(data[locX + 1][locY].toString() == c && data[locX][locY + 1].toString() == c)  {
                // x x x
                // x x x
                // x x -
                result.x += 2;
                result.y += 1;
            }
            // - - -
            // x x -
            // - x -
            if(data[locX - 1][locY].toString() == c && data[locX][locY + 1].toString() == c && isGround(data[locX + 1][locY].toString(), c) && isGround(data[locX][locY - 1].toString(), c))  {
                result.x += 2;
                result.y -= 2;
            } else if(data[locX - 1][locY].toString() == c && data[locX][locY + 1].toString() == c)  {
                result.x -= 2;
                result.y += 1;
            }
            // - x -
            // x x -
            // - - -
            if(data[locX - 1][locY].toString() == c && data[locX][locY - 1].toString() == c && isGround(data[locX + 1][locY].toString(), c) && isGround(data[locX][locY + 1].toString(), c))  {
                result.x += 2;
                result.y += 2;
            } else if(data[locX - 1][locY].toString() == c && data[locX][locY - 1].toString() == c)  {
                result.x -= 2;
                result.y -= 1;
            }
            // - x -
            // - x x
            // - - -
            if(data[locX + 1][locY].toString() == c && data[locX][locY - 1].toString() == c && isGround(data[locX - 1][locY].toString(), c) && isGround(data[locX][locY + 1].toString(), c))  {
                result.x -= 2;
                result.y += 2;
            } else if(data[locX + 1][locY].toString() == c && data[locX][locY - 1].toString() == c)  {
                result.x += 2;
                result.y -= 1;
            }
        }
        return result;
    }

    function isSpecial(itemData: ItemDetail): Bool {
        var gfxName: String = Type.getClassName(Type.getSuperClass(itemData.gfx));
        return gfxName.indexOf("BitmapData") == -1;
    }

    function addPersistentItem(c : Color, x : Int, y : Int) : Void {
        if(!persistentItemMapping.has(c.toString()))  {
            if(c.toString() != "#ffffff")  {
                Util.log("Color without data: " + c.toString());
            }
            return;
        }

        var itemData : ItemDetail = persistentItemMapping.get(c.toString());

        // If the provided graphics are BitmapData, this is a static object.
        // We won't treat it specially in that case.

        if(!isSpecial(itemData)) return;

        // Otherwise, we create it.

        var e : Entity = Type.createInstance(itemData.gfx, []);

        var ssLoc:Vec;
        if (itemData.spritesheet != null) {
            ssLoc = itemData.spritesheet;
        } else {
            ssLoc = new Vec(0, 0);
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
            for (x in 0...widthInTiles) {
                for (y in 0...heightInTiles) {
                    var dataColor : Color = data[Std.int(topLeftCorner.x + x)][Std.int(topLeftCorner.y + y)];
                    addPersistentItem(dataColor, x, y);
                }
            }
        } else  {
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

    public function collidesPt(other : Vec) : Bool {
        if(!contains(other))
            return true;
        var xPt : Int = Math.floor(other.x / this.tileSize);
        var yPt : Int = Math.floor(other.y / this.tileSize);
        return tiles[xPt][yPt] != null;
    }

    public function collidesRect(other : Rect) : Bool {
        var xStart : Int = Math.floor(other.x / this.tileSize);
        var xStop : Int = Math.floor((other.x + other.width) / this.tileSize) + 1;
        var yStart : Int = Math.floor(other.y / this.tileSize);
        var yStop : Int = Math.floor((other.y + other.height) / this.tileSize) + 1;

        for (x in xStart...xStop) {
            for (y in yStart...yStop) {
                if(0 <= x && x < widthInTiles && 0 <= y && y < heightInTiles)  {
                    if(tiles[x][y] != null)  {
                        return true;
                    }
                }
            }
        }
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
        var diff : Vec = abs.subtract(getTopLeftCorner().clone().divide(_tileSize));
        loadNewMap(diff);
        return this;
    }

    static var cachedAssets : TypedDictionary<String, Dynamic> = new TypedDictionary();

    function dumpToGraphics() : Void {
        // Write out the tiles to imgData
        var imgData : BitmapData = new BitmapData(widthInTiles * tileSize, heightInTiles * tileSize, true, 0xFFFFFFFF);
        for (x in 0...widthInTiles) {
            for (y in 0...heightInTiles) {
                var c: String = data[Std.int(topLeftCorner.x + x)][Std.int(topLeftCorner.y + y)].toString();

                if(!persistentItemMapping.has(c))  {
                    if(c.toString() != "#ffffff")  {
                        Util.log("Color without data: " + c);
                        continue;
                    }
                }

                var itemData : ItemDetail = persistentItemMapping.get(c);

                var ss: Vec = fancyProcessing(itemData, c, x, y).multiply(_tileSize);
                var key : String = Type.getClassName(itemData.gfx);

                var bAsset;

                if (isSpecial(itemData)) continue;

                if (!cachedAssets.exists(key)) {
                    cachedAssets.set(key, Type.createInstance(itemData.gfx, []));
                }

                if(!isGround(c, ""))  {
                    collisionInfo[x][y] = true;
                }
                bAsset = cachedAssets.get(key);
                imgData.copyPixels(bAsset, new Rectangle(ss.x, ss.y, _tileSize, _tileSize), new Point(x * 25, y * 25));
            }
        }
        // I have this suspicion that I don't need to keep adding the bitmapData TODO
        // Add imgData to screen.
        var bmp : Bitmap = new Bitmap(imgData);
        graphics.setPixels(bmp);
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
    public function new(size : Int) {
        super(0, 0, size, size);
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
