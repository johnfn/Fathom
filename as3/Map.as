package {
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

  public class Map extends Rect {
    private var _widthInTiles:int;
    private var _heightInTiles:int;

    private var bogusmapentry:Entity;
    private var grounds:Array;

    private var _tileSize:int;
    private var data:Array = []; // Color data from the map.
    public var transparency:Array = []; //TODO POST LD
    private var tiles:Array = []; // Cached array of collideable tiles.
    public var collisionInfo:Array = [];
    private var topLeftCorner:Vec = new Vec(0, 0);
    private var exploredMaps:Object = {};

    private var graphics:Entity;

    private var persistentItemMapping:Object = {};
    private var persistent:Object = {};

    public var sizeVector:Vec;

    function Map(widthInTiles:int, heightInTiles:int, tileSize:int) {
      super(0, 0, widthInTiles * tileSize, heightInTiles * tileSize);

      Util.assert(widthInTiles == heightInTiles);

      this.sizeVector = new Vec(width, height);
      this._widthInTiles = widthInTiles;
      this._heightInTiles = heightInTiles;
      this._tileSize = tileSize;

      this.clearTiles();
      bogusmapentry = new BogusMapEntry();
    }

    private function clearTiles():void {
      tiles = Util.make2DArrayFn(widthInTiles, heightInTiles, function(x:int, y:int):Tile {
        return null;
      });
    }

    public function get tileSize():int {
      return _tileSize;
    }

    public function get widthInTiles():int {
      return _widthInTiles;
    }

    public function get heightInTiles():int {
      return _heightInTiles;
    }

    public function outOfBoundsPt(x:int, y:int):Boolean {
      if (x < 0) return true;
      if (x >= width) return true;
      if (y < 0) return true;
      if (y >= height) return true;

      return false;
    }

    public function fromImage(mapClass:Class, groundList:Array, persistentItemMapping:Object):Map {
      var bAsset:BitmapAsset = new mapClass();
      var bData:BitmapData = bAsset.bitmapData;

      this.grounds = groundList;
      this.persistentItemMapping = persistentItemMapping;

      data = Util.make2DArray(bData.width, bData.height, undefined);

      for (var x:int=0; x < bData.width; x++) {
        for (var y:int=0; y < bData.height; y++) {
          data[x][y] = Color.fromInt(bData.getPixel(x, y));
        }
      }

      return this;
    }

    private function hideCurrentPersistentItems():void {
      var processedItems:Array = [];
      var items:Array = persistent[topLeftCorner.asKey()] || [];

      for (var i:int = 0; i < items.length; i++) {
        if (!items[i].destroyed) {
          items[i].removeFromFathom();
          processedItems.push(items[i]);
        }
      }

      persistent[topLeftCorner.asKey()] = processedItems;
    }

    private function updatePersistentItems(diff:Vec):void {
      hideCurrentPersistentItems();

      for each (var e:Entity in Fathom.entities.select("!persistent")) {
        e.destroy();
      }

      topLeftCorner.add(diff)

      dumpToGraphics();
      addNewPersistentItems();
    }

    private function isGround(c:Color, s:String):Boolean {
      return grounds.indexOf(c.toString()) != -1 && c.toString() != s;
    }

    private function fancyProcessing(itemData:Object, c:String, x:int, y:int):Vec {
      var result:Vec = itemData["spritesheet"].clone();

      if ("roundOutEdges" in itemData) {
        /*
        var X:int = 0;
        var Y:int = 1;
        */

        var locX:int = topLeftCorner.x + x;
        var locY:int = topLeftCorner.y + y;

        if (locY == 0 || data[locX][locY - 1].toString() != c.toString()) {
          result.y--;
        }

        if (locX == 0 || data[locX - 1][locY].toString() != c.toString()) {
          result.x--;
        }

        if (locY != heightInTiles - 1 && data[locX][locY + 1].toString() != c.toString()) {
          result.y++;
        }

        if (locX == widthInTiles - 1 || data[locX + 1][locY].toString() != c.toString()) {
          result.x++;
        }

        if (locY != 0 && data[locX][locY - 1].toString() != c.toString()  && locY != heightInTiles - 1 && data[locX][locY + 1].toString() != c.toString()) {
          result.y--;
        }
      }

      if ("randoEdges" in itemData && Util.randRange(0, 5) == 3) {
        result.x += Util.randRange(-1, 2);
        result.y += Util.randRange(-1, 2);
      }

      if ("fancyEdges" in itemData) {
        var cstr:String = c.toString();
        var empty:String = (new Color(255, 255, 255).toString());

        var locX:int = topLeftCorner.x + x;
        var locY:int = topLeftCorner.y + y;

        // Horizontal wall, ground below.

        if (!isGround(data[locX - 1][locY], cstr) &&
            !isGround(data[locX + 1][locY], cstr) &&
            isGround(data[locX][locY + 1], cstr)) {
          result.y += 2;
        }

        // Horizontal wall, ground above.

        if (data[locX - 1][locY].toString() == cstr &&
            data[locX + 1][locY].toString() == cstr &&
            isGround(data[locX][locY - 1], cstr)) {
          result.y -= 2;
        }

        // Vertical wall, ground to the left.

        if (data[locX][locY - 1].toString() == cstr &&
            data[locX][locY + 1].toString() == cstr &&
            isGround(data[locX - 1][locY], cstr)) {
          result.x -= 2;
        }

        // Vertical wall, ground to the right.

        if (!isGround(data[locX][locY - 1], cstr) &&
            !isGround(data[locX][locY + 1], cstr) &&
             isGround(data[locX + 1][locY], cstr)) {
          result.x += 2;
        }

        // - - -
        // - x x
        // - x -

        if (data[locX + 1][locY].toString() == cstr &&
            data[locX][locY + 1].toString() == cstr &&
            isGround(data[locX - 1][locY], cstr) &&
            isGround(data[locX][locY - 1], cstr)) {
          result.x -= 2;
          result.y -= 2;
        } else if (data[locX + 1][locY].toString() == cstr &&
            data[locX][locY + 1].toString() == cstr) {

          // x x x
          // x x x
          // x x -

          result.x += 2;
          result.y += 1;
        }

        // - - -
        // x x -
        // - x -

        if (data[locX - 1][locY].toString() == cstr &&
            data[locX][locY + 1].toString() == cstr &&
            isGround(data[locX + 1][locY], cstr) &&
            isGround(data[locX][locY - 1], cstr)) {
          result.x += 2;
          result.y -= 2;
        } else if (data[locX - 1][locY].toString() == cstr &&
                   data[locX][locY + 1].toString() == cstr) {
          result.x -= 2;
          result.y += 1;
        }

        // - x -
        // x x -
        // - - -

        if (data[locX - 1][locY].toString() == cstr &&
            data[locX][locY - 1].toString() == cstr &&
            isGround(data[locX + 1][locY], cstr) &&
            isGround(data[locX][locY + 1], cstr)) {
          result.x += 2;
          result.y += 2;
        } else if (data[locX - 1][locY].toString() == cstr &&
                   data[locX][locY - 1].toString() == cstr) {
          result.x -= 2;
          result.y -= 1;
        }

        // - x -
        // - x x
        // - - -

        if (data[locX + 1][locY].toString() == cstr &&
            data[locX][locY - 1].toString() == cstr &&
            isGround(data[locX - 1][locY], cstr) &&
            isGround(data[locX][locY + 1], cstr)) {
          result.x -= 2;
          result.y += 2;
        } else if (data[locX + 1][locY].toString() == cstr &&
                   data[locX][locY - 1].toString() == cstr) {
          result.x += 2;
          result.y -= 1;
        }
      }

      return result;
    }

    private function addPersistentItem(c:Color, x:int, y:int):void {
      if (!(c.toString() in persistentItemMapping)) {
        if (c.toString() != "#ffffff") {
          Util.log("Color without data: " + c.toString());
        }
        return;
      }

      var itemData:Object = persistentItemMapping[c.toString()];

      if (!("type" in itemData)) return;

      var e:Entity;
      if ("args" in itemData) {
        // TODO: new ItemData["type"].call(args)
        e = new itemData["type"](itemData.args);
      } else {
        e = new itemData["type"]();
      }

      if (!("special" in itemData)) {
        e.loadSpritesheet(itemData["gfx"], C.dim, itemData["spritesheet"] || new Vec(0, 0));
      }

      e.setPos(new Vec(x * tileSize, y * tileSize));

      if (e.groups().contains("persistent")) {
        persistent[topLeftCorner.asKey()].push(e);
      }

      if (e.groups().contains("remember-loc")) {
        trace("I never did this LOL");
      }
    }

    private function addNewPersistentItems():void {
      var seenBefore:Boolean = exploredMaps[topLeftCorner.asKey()];

      this.clearTiles();

      // Scan the map, adding every object to our list of persistent items for this map.
      if (!seenBefore) {
        // If we haven't seen it before, load in all the persistent items.

        persistent[topLeftCorner.asKey()] = [];

        for (var x:int = 0; x < widthInTiles; x++) {
          for (var y:int = 0; y < heightInTiles; y++) {
            trace(topLeftCorner);

            var dataColor:Color = data[topLeftCorner.x + x][topLeftCorner.y + y];

            addPersistentItem(dataColor, x, y);
          }
        }
      } else {

        // Add all persistent items.
        persistent[topLeftCorner.asKey()].map(function(e:*, i:int, a:Array):void {
          e.addToFathom();

          if (e.groups().contains("remember-loc")) {
            e.resetLoc();
          }
        });
      }

      // Cache every persistent item in the 2D array of tiles.
      var persistingItems:Array = persistent[topLeftCorner.asKey()];

      for (var i:int = 0; i < persistingItems.length; i++) {
        var e:Entity = persistingItems[i];

        if (e.isStatic) {
          var xCoord:int = Math.floor(e.x / this.tileSize);
          var yCoord:int = Math.floor(e.y / this.tileSize);

          tiles[xCoord][yCoord] = e;
        }
      }

      exploredMaps[topLeftCorner.asKey()] = true;
    }

    public function itemSwitchedMaps(leftScreen:Entity):void {
      var smallerSize:Vec = sizeVector.clone().subtract(leftScreen.width);
      var dir:Vec = leftScreen.rect().divide(smallerSize).map(Math.floor);
      var newMapLoc:Vec = topLeftCorner.clone().add(dir.clone().multiply(widthInTiles));
      var newItemLoc:Vec = leftScreen.rect().add(dir.clone().multiply(-1).multiply(sizeVector.clone().subtract(tileSize * 2)));

      persistent[topLeftCorner.asKey()].remove(leftScreen);
      if (!persistent[newMapLoc.asKey()]) {
        persistent[newMapLoc.asKey()] = [];
      }
      persistent[newMapLoc.asKey()].push(leftScreen);

      leftScreen.setPos(newItemLoc);

      leftScreen.removeFromFathom();
    }

    private function collidesPt(other:Vec):Boolean {
      if (!contains(other)) return true;

      var xPt:int = Math.floor(other.x / this.tileSize);
      var yPt:int = Math.floor(other.y / this.tileSize);

      return tiles[xPt][yPt] != null;
    }

    private function collidesRect(other:Rect):Boolean {
      var xStart:int = Math.floor(other.x / this.tileSize);
      var xStop:int  = Math.floor((other.x + other.width) / this.tileSize);
      var yStart:int = Math.floor(other.y / this.tileSize);
      var yStop:int  = Math.floor((other.y + other.height) / this.tileSize);

      for (var x:int = xStart; x < xStop + 1; x++) {
        for (var y:int = yStart; y < yStop + 1; y++) {
          if (0 <= x && x < widthInTiles && 0 <= y && y < heightInTiles) {
            if (tiles[x][y] != null) {
              return true;
            }
          }
        }
      }

      if (!makeBigger(3).contains(other)) return true;

      return false;
    }

    public function set visible(val:Boolean):void {
      return;

      persistent[topLeftCorner.asKey()].map(function(e:*, i:int, a:Array):void {
        e.visible = val;
      });
    }

    public function collides(i:*):Boolean {
      if (i is Vec) {
        return collidesPt(i as Vec);
      }

      if (i is Rect) {
        return collidesRect(i as Rect);
      }

      throw new Error("Unsupported type for Map#collides.")
    }

    public function update():void {
      var items:Array = persistent[topLeftCorner.asKey()];

      return;

      for (var i:int = 0; i < items.length; i++) {
        if (Hooks.hasLeftMap(items[i], this)) {
          Util.assert(!items[i].groups().contains("Character"));
          this.itemSwitchedMaps(items[i]);
        }
      }
    }

    public override function toString():String {
      return "[Map]";
    }

    public function modes():Array {
      return [0];
    }

    public function loadNewMapAbs(abs:Vec):Map {
      var diff:Vec = abs.subtract(getTopLeftCorner().clone().divide(25));

      loadNewMap(diff);

      return this;
    }

    private static var cachedAssets:Dictionary = new Dictionary();

    private function dumpToGraphics():void {
      graphics = new Entity();

      while (graphics.numChildren > 0) {
        graphics.removeChildAt(0);
      }

      // Write out the tiles to imgData
      var imgData:BitmapData = new BitmapData(widthInTiles * tileSize, heightInTiles * tileSize, true, 0xFFFFFFFF);

      for (var x:int = 0; x < widthInTiles; x++) {
        for (var y:int = 0; y < heightInTiles; y++) {
          var c:Color = data[topLeftCorner.x + x][topLeftCorner.y + y];

          if (!(c.toString() in persistentItemMapping)) {
            if (c.toString() != "#ffffff") {
              Util.log("Color without data: " + c.toString());
            }
            continue;
          }

          var itemData:Object = persistentItemMapping[c.toString()];

          if (!("gfx" in itemData)) continue;

          var ss:Vec = fancyProcessing(itemData, c.toString(), x, y).multiply(25); // Hardcore hardcoding TODO

          var key:String = Util.className(itemData.gfx);
          var bAsset:BitmapAsset;

          if (!(cachedAssets[key])) {
            cachedAssets[key] = new itemData.gfx();
          }

          if (!isGround(c, "")) {
            collisionInfo[x][y] = true;
          }

          transparency[x][y] = "transparent" in itemData;

          bAsset = cachedAssets[key];

          imgData.copyPixels(bAsset.bitmapData, new Rectangle(ss.x, ss.y, 25, 25), new Point(x * 25, y * 25));
        }
      }

      // I have this suspicion that I don't need to keep adding the bitmapData TODO

      // Add imgData to screen.
      var bmp:Bitmap = new Bitmap(imgData);
      graphics.addChild(bmp);

      graphics.graphics.drawRect(0, 0, 25, 25);
      //addChild(graphics);
    }

    public function loadNewMap(diff:Vec):Map {
      collisionInfo = Util.make2DArray(widthInTiles, heightInTiles, false);
      transparency = Util.make2DArray(widthInTiles, heightInTiles, true);

      diff.multiply(new Vec(widthInTiles, heightInTiles));

      updatePersistentItems(diff);

      Fathom.grid = new SpatialHash(new EntitySet());
      Fathom.grid.loadMap(this, bogusmapentry);

      Fathom.container.sortDepths();

      return this;
    }

    public function getTopLeftCorner():Vec {
      return this.topLeftCorner.clone();
    }
  }
}

class BogusMapEntry extends Entity {
  function BogusMapEntry(x:int=0, y:int=0) {
    super(x, y, 25, 25);
  }

  // holy freaking christ
  // hack levels are currently off the charts
  public override function touchingRect(rect:Entity):Boolean {
    return true;
  }

  public override function groups():Set {
    return super.groups().concat("map");
  }
}
