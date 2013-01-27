package fathom;

import nme.geom.Point;
import nme.geom.Rectangle;
import nme.display.BitmapData;

using Lambda;

typedef ItemDetail = {
    var key: String;

    // One of these two is required.
    // TODO: Fancy magic to require at least one of them in compile time?

    /* If it's just a static image, the path to the spritesheet that contains
       that image. */
    @:optional var gfx: String;

    /* If it has special properties, the class that should be created. */
    @:optional var spc: Dynamic;

    /* The location of the image on the spritesheet. */
    // TODO - make optional, no spritesheet =
    @:optional var spritesheet: Vec;

    // Optional settings

    @:optional var roundOutEdges: Bool;
    @:optional var fancyEdges: Bool;
    @:optional var randoEdges: Bool;
}

enum MapDataType {
    Image;
    StringArray;
    //Tiled;
}

private class MapData {
    var datatype: MapDataType;
    var imgData: ReloadedGraphic;

    var loaded: Bool = false;
    var img: ReloadedGraphic;
    var str: Array<String>;

    var data: Array<Array<String>>;
    var reloadCB: Void -> Void = null;

    // This is private. Use the static constructor functions like fromImage
    // or fromStringArray instead.
    function new() {
    }

    public static function fromImage(url: String): MapData {
        var md: MapData = new MapData();

        md.datatype = Image;

        md.img = new ReloadedGraphic(url);
        md.img.addUpdateCallback(md.onReload);
        md.loadData();

        return md;
    }

    public static function fromStringArray(data: Array<String>): MapData {
        var md: MapData = new MapData();

        md.data = Util.make2DArrayFn(data.length, data[0].length, function(x, y): String {
            return data[y].charAt(x);
        });

        return md;
    }

    public function hasLoaded(): Bool {
        return loaded;
    }

    public function get(x: Int, y: Int): String {
        return data[x][y];
    }

    public function setReloadCallback(cb: Void -> Void): Void {
        reloadCB = cb;
    }

    function loadData(): Void {
        var bData: BitmapData = img.bitmapData;
        data = Util.make2DArray(bData.width, bData.height, null);

        for (x in 0...bData.width) {
            for (y in 0...bData.height) {
                data[x][y] = Color.fromInt(bData.getPixel(x, y)).toString();
            }
        }
    }

    function onReload(): Void {
        loadData();

        if (reloadCB != null) {
            reloadCB();
        }
    }
}

//TODO: Map should extend Entity. Will need to change update loop.
class Map extends Rect {
    public var tileSize(getTileSize, never) : Int;
    public var widthInTiles(getWidthInTiles, never) : Int;
    public var heightInTiles(getHeightInTiles, never) : Int;

    public var loaded: Void -> Void = null;

    var itemsLeftToLoad: Int = 1; //the map data

    var _widthInTiles : Int;
    var _heightInTiles : Int;
    var grounds : Array<String>;
    var _tileSize : Int;

    // Color data from the map.
    var data : MapData = null;

    // Cached array of collideable tiles.
    var tiles : Array<Array<Entity>>;

    public var collisionInfo : Array<Array<Bool>>;
    var topLeftCorner : Vec;
    var exploredMaps : SuperObjectHash<String, Bool>;
    // Mapping between colors and items.
    var persistentItemMapping : SuperObjectHash<String, ItemDetail>;
    var persistent : SuperObjectHash<String, Array<Entity>>;
    public var sizeVector : Vec;

    public function new(widthInTiles : Int, heightInTiles : Int, tileSize : Int) {
        tiles = [];
        collisionInfo = [];
        topLeftCorner = new Vec(0, 0);
        exploredMaps = new SuperObjectHash();
        persistentItemMapping = new SuperObjectHash();
        persistent = new SuperObjectHash();
        super(0, 0, widthInTiles * tileSize, heightInTiles * tileSize);
        Util.assert(widthInTiles == heightInTiles);
        this.sizeVector = new Vec(width, height);
        this._widthInTiles = widthInTiles;
        this._heightInTiles = heightInTiles;
        this._tileSize = tileSize;
        this.clearTiles();
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

    public function fromImage(mapFilepath: String, mappings : Array<ItemDetail>, groundList : Array<String> = null) : Map {
        if (groundList == null) groundList = [];

        var that: Map = this;

        data = MapData.fromImage(mapFilepath);
        data.setReloadCallback(function() {
            that.exploredMaps = new SuperObjectHash();
            that.loadNewMap(0, 0);
        });

        // Load ground list
        this.grounds = groundList;

        // Load item mapping
        for (s in mappings) {
            this.persistentItemMapping.set(s.key, s);

            Util.assert(s.spc != null || s.gfx != null, "Both SPC and GFX are null.");
        }

        this.loadNewMap(0, 0);

        return this;
    }

    public function fromStringArray(arr: Array<String>, mappings: Array<ItemDetail>, groundList: Array<String> = null): Map {
        if (groundList == null) groundList = [];

        data = MapData.fromStringArray(arr);
        this.grounds = groundList;

        for (s in mappings) {
            this.persistentItemMapping.set(s.key, s);

            Util.assert(s.spc != null || s.gfx != null, "Both SPC and GFX are null.");
        }

        this.loadNewMap(0, 0);
        return this;
    }

    function hideCurrentPersistentItems() : Void {
        var processedItems : Array<Entity> = [];
        var k:String = topLeftCorner.asKey();
        var items : Array<Entity> = persistent.exists(k) ? persistent.get(k) : [];

        for (i in items) {
            if(!i.destroyed)  {
                i.removeFromFathom();
                processedItems.push(i);
            }
        }
        persistent.set(topLeftCorner.asKey(), processedItems);
    }

    function updatePersistentItems(diff : Vec) : Void {
        hideCurrentPersistentItems();
        topLeftCorner.add(diff);
        addNewPersistentItems();
    }

    function isGround(c : String, s : String) : Bool {
        return grounds.has(c) && c != s;
    }

    function fancyProcessing(itemData: ItemDetail, c : String, x : Int, y : Int) : Vec {
        var result : Vec = itemData.spritesheet.clone();
        if(itemData.roundOutEdges) {
            var locX : Int = Std.int(topLeftCorner.x) + x;
            var locY : Int = Std.int(topLeftCorner.y) + y;
            if(locY == 0 || data.get(locX, locY - 1) != c)  {
                result.y--;
            }
            if(locX == 0 || data.get(locX - 1, locY) != c)  {
                result.x--;
            }
            if(locY != heightInTiles - 1 && data.get(locX, locY + 1) != c)  {
                result.y++;
            }
            if(locX == widthInTiles - 1 || data.get(locX + 1, locY) != c)  {
                result.x++;
            }
            if(locY != 0 && data.get(locX, locY - 1) != c && locY != heightInTiles - 1 && data.get(locX, locY + 1) != c)  {
                result.y--;
            }
        }

        if(itemData.randoEdges && Util.randRange(0, 5) == 3)  {
            result.x += Util.randRange(-1, 2);
            result.y += Util.randRange(-1, 2);
        }

        if(itemData.fancyEdges)  {
            var empty: String = (new Color(255, 255, 255)).toString();
            var locX : Int = Std.int(topLeftCorner.x) + x;
            var locY : Int = Std.int(topLeftCorner.y) + y;
            // Horizontal wall, ground below.
            if(!isGround(data.get(locX - 1, locY), c) && !isGround(data.get(locX + 1, locY), c) && isGround(data.get(locX, locY + 1), c))  {
                result.y += 2;
            }
            // Horizontal wall, ground above.
            if(data.get(locX - 1, locY) == c && data.get(locX + 1, locY) == c && isGround(data.get(locX, locY - 1), c))  {
                result.y -= 2;
            }
            // Vertical wall, ground to the left.
            if(data.get(locX, locY - 1) == c && data.get(locX, locY + 1) == c && isGround(data.get(locX - 1, locY), c))  {
                result.x -= 2;
            }
            // Vertical wall, ground to the right.
            if(!isGround(data.get(locX, locY - 1), c) && !isGround(data.get(locX, locY + 1), c) && isGround(data.get(locX + 1, locY), c))  {
                result.x += 2;
            }
            // - - -
            // - x x
            // - x -
            if(data.get(locX + 1, locY) == c && data.get(locX, locY + 1) == c && isGround(data.get(locX - 1, locY), c) && isGround(data.get(locX, locY - 1), c))  {
                result.x -= 2;
                result.y -= 2;
            } else if(data.get(locX + 1, locY) == c && data.get(locX, locY + 1) == c)  {
                // x x x
                // x x x
                // x x -
                result.x += 2;
                result.y += 1;
            }
            // - - -
            // x x -
            // - x -
            if(data.get(locX - 1, locY) == c && data.get(locX, locY + 1) == c && isGround(data.get(locX + 1, locY), c) && isGround(data.get(locX, locY - 1), c))  {
                result.x += 2;
                result.y -= 2;
            } else if(data.get(locX - 1, locY) == c && data.get(locX, locY + 1) == c)  {
                result.x -= 2;
                result.y += 1;
            }
            // - x -
            // x x -
            // - - -
            if(data.get(locX - 1, locY) == c && data.get(locX, locY - 1) == c && isGround(data.get(locX + 1, locY), c) && isGround(data.get(locX, locY + 1), c))  {
                result.x += 2;
                result.y += 2;
            } else if(data.get(locX - 1, locY) == c && data.get(locX, locY - 1) == c)  {
                result.x -= 2;
                result.y -= 1;
            }
            // - x -
            // - x x
            // - - -
            if(data.get(locX + 1, locY) == c && data.get(locX, locY - 1) == c && isGround(data.get(locX - 1, locY), c) && isGround(data.get(locX, locY + 1), c))  {
                result.x -= 2;
                result.y += 2;
            } else if(data.get(locX + 1, locY) == c && data.get(locX, locY - 1) == c)  {
                result.x += 2;
                result.y -= 1;
            }
        }
        return result;
    }

    function isSpecial(itemData: ItemDetail): Bool {
        return itemData.gfx == null;
    }

    function addPersistentItem(c: String, x : Int, y : Int) : Void {
        if(!persistentItemMapping.has(c))  {
            if(c != "#ffffff")  {
                Util.log("Color without data: " + c);
            }
            return;
        }

        var itemData: ItemDetail = persistentItemMapping.get(c);

        // If the provided graphics are BitmapData, this is a static object.
        // We won't treat it specially in that case.

        var ssLoc:Vec;
        if (itemData.spritesheet != null) {
            ssLoc = itemData.spritesheet;
        } else {
            ssLoc = new Vec(0, 0);
        }

        var e: Entity;

        if (isSpecial(itemData)) {
            e = Type.createInstance(itemData.spc, []).setPos(x * tileSize, y * tileSize);
        } else {
            e = new Entity(x * tileSize, y * tileSize);
            e.loadSpritesheet(itemData.gfx, new Vec(tileSize, tileSize));
            e.setTile(Std.int(ssLoc.x), Std.int(ssLoc.y));
            e.addGroup("non-blocking");
        }

        persistent.get(topLeftCorner.asKey()).push(e);

        if (e.groups().has("remember-loc")) {
            Util.assert(false, "I never did this LOL");
        }
    }

    function addNewPersistentItems() : Void {
        var seenBefore : Bool = exploredMaps.get(topLeftCorner.asKey());
        this.clearTiles();
        // Scan the map, adding every object to our list of persistent items for this map.
        if(!seenBefore)  {
            // If we haven't seen it before, load in all the persistent items.

            // We could have pushed something into this room
            // without seeing it.
            if (!persistent.exists(topLeftCorner.asKey())) {
                persistent.set(topLeftCorner.asKey(), []);
            } else {
                Lambda.map(persistent.get(topLeftCorner.asKey()), function(e : Entity) : Void {
                    e.addToFathom();
                });
            }

            itemsLeftToLoad = widthInTiles * heightInTiles;
            for (x in 0...widthInTiles) {
                for (y in 0...heightInTiles) {
                    var dataColor: String = data.get(Std.int(topLeftCorner.x + x), Std.int(topLeftCorner.y + y));
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
        var persistingItems : Array<Entity> = persistent.get(topLeftCorner.asKey());

        for (e in persistingItems) {
            if(e.isStatic)  {
                var xCoord : Int = Math.floor(e.x / this.tileSize);
                var yCoord : Int = Math.floor(e.y / this.tileSize);

                if (containsCoord(xCoord, yCoord)) {
                    tiles[xCoord][yCoord] = e;
                }
            }
        }
        exploredMaps.set(topLeftCorner.asKey(), true);
    }

    function itemSwitchedMaps(leftScreen : Entity) : Void {
        var smallerSize : Vec = sizeVector.clone().subtract(leftScreen.width);
        var dir : Vec = leftScreen.rect().divide(smallerSize).map(Math.floor);
        var newMapLoc : Vec = topLeftCorner.clone().add(dir.clone().multiply(widthInTiles));
        var newItemLoc : Vec = leftScreen.rect().add(dir.clone().multiply(-1).multiply(sizeVector.clone().subtract(tileSize * 2)));

        persistent.get(topLeftCorner.asKey()).remove(leftScreen);
        if(!persistent.exists(newMapLoc.asKey()))  {
            persistent.set(newMapLoc.asKey(), []);
        }
        persistent.get(newMapLoc.asKey()).push(leftScreen);
        leftScreen.setPos(Std.int(newItemLoc.x), Std.int(newItemLoc.y));
        leftScreen.removeFromFathom();
    }

    public function collidesPt(other : Vec) : Bool {
        if(!containsPt(other)) return true;

        var xPt : Int = Math.floor(other.x / this.tileSize);
        var yPt : Int = Math.floor(other.y / this.tileSize);
        return tiles[xPt][yPt] != null;
    }

    public function containsCoord(x: Int, y: Int): Bool {
        return 0 <= x && x < widthInTiles && 0 <= y && y < heightInTiles;
    }

    public function update() : Void {
        var items: Array<Entity> = persistent.get(topLeftCorner.asKey());

        for (it in items) {
            if(hasLeftMap(it))  {
                Util.assert(!it.groups().has("Character"));
                this.itemSwitchedMaps(it);
            }
        }
    }

    override public function toString() : String {
        return "[Map]";
    }

    public function modes() : Array<Dynamic> {
        return [0];
    }

    public function loadNewMapAbs(x: Int, y: Int) : Map {
        var diff: Vec = new Vec(x, y).subtract(getTopLeftCorner());
        loadNewMap(Std.int(diff.x), Std.int(diff.y));
        return this;
    }

    static var cachedAssets : SuperObjectHash<String, Dynamic> = new SuperObjectHash();

    public function loadNewMap(dx: Int, dy: Int) : Map {
        var diff: Vec = new Vec(dx, dy);

        collisionInfo = Util.make2DArray(widthInTiles, heightInTiles, false);
        diff.multiply(new Vec(widthInTiles, heightInTiles));
        updatePersistentItems(diff);
        //TODO
        //Fathom.container.sortDepths();
        return this;
    }

    public function getTopLeftCorner(): Vec {
        return this.topLeftCorner.clone().divide(new Vec(widthInTiles, heightInTiles));
    }

    /**
     * Returns true if the provided entity is outside of this Map, false otherwise.
     */
    public function hasLeftMap(who: Entity): Bool {
        return who.x < 0 || who.y < 0 || who.x > this.width - who.width || who.y > this.height - who.height;
    }

    public function loadNewMapWithCharacter(leftScreen: MovingEntity): Void {
        //TODO: This code is pretty obscure.
        //TODO: This will only work if leftScreen.width is less than the tileSize.

        Util.assert(leftScreen.width < this.tileSize, "loadNewMapWithCharacter: bad character size");
        Util.assert(hasLeftMap(leftScreen), "loadNewMapWithCharacter was called with an entity that hasn't left the Map.");

        var smallerSize : Vec = this.sizeVector.clone().subtract(leftScreen.width);
        var dir : Vec = leftScreen.vec().divide(smallerSize).map(Math.floor);
        var toOtherSide : Vec = dir.clone().multiply(smallerSize);

        if(toOtherSide.x > 0) leftScreen.x = 1;
        if(toOtherSide.x < 0) leftScreen.x = this.sizeVector.x - this.tileSize + 1;
        if(toOtherSide.y > 0) leftScreen.y = 1;
        if(toOtherSide.y < 0) leftScreen.y = this.sizeVector.y - this.tileSize + 1;

        this.loadNewMap(Std.int(dir.x), Std.int(dir.y));
    }

}
