#if flash
import starling.display.Image;
import starling.core.Starling;
import starling.textures.Texture;
import starling.display.Sprite;
import starling.display.DisplayObjectContainer;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import starling.events.Event;
import starling.core.RenderSupport;
#else
import nme.display.Sprite;
import nme.display.DisplayObjectContainer;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.events.Event;
#end

import Hooks;
import Util;

typedef SpriteSheet = {
    var x:Int;
    var y:Int;
}

/** Graphic is a wrapper around a Starling Image with some additional smarts
 *  for game-related development.
 *
 *  Smarts include:
 *
 *  Tilemap support with Graphic.loadSpritesheet (TODO) and setTile().
 *
 *  Animation support with `animation`.
 */

class Graphic extends Sprite {
#if flash
    var texturedObject:Image;
    static var cachedAssets: SuperObjectHash<String, Texture> = new SuperObjectHash();
    var fullTexture : Texture;
#else
    var texturedObject:Bitmap;
    static var cachedAssets: SuperObjectHash<String, BitmapData> = new SuperObjectHash();
    var fullTexture : BitmapData;
    var hotswapped: ReloadedGraphic;
#end

    public var depth(getDepth, setDepth) : Int;

    public var animations : AnimationHandler;
    var spritesheet : SpriteSheet;
    // TODO: Rename
    var _depth : Int;
    var tileWidth : Int;
    var tileHeight : Int;

    public function new() {
        _depth = 0;
        fullTexture = null;
        tileWidth = -1;
        tileHeight = -1;
        facing = 1;
        spritesheet = {x: 0, y: 0};

        super();

        animations = new AnimationHandler(this);
    }

    public #if !flash override #end function toString(): String {
        return "[Graphic]";
    }

    // Set this entities graphics to be the sprite at (x, y) on the provided spritesheet.
    // TODO: Implicit assumption that bitmap faces right.
    public function setTile(spriteX: Int, spriteY: Int) : Graphic {
        Util.assert(fullTexture != null, "The spritesheet is null.");

        spritesheet.x = spriteX;
        spritesheet.y = spriteY;

        var region:Rectangle = new Rectangle(spriteX * tileWidth, spriteY * tileHeight, tileWidth, tileHeight);

#if flash
        texturedObject.texture = Texture.fromTexture(fullTexture, region);
#else
        var bd:BitmapData = new BitmapData(tileWidth, tileHeight);
        bd.copyPixels(fullTexture, region, new Point(0, 0), null, null, true);

        texturedObject.bitmapData = bd;
#end

        if(!animations.hasAnimation("default"))  {
            animations.addAnimation("default", spriteX, spriteY, 1);
        }

        return this;
    }

    public function getSpriteX() : Int {
        return this.spritesheet.x;
    }

    public function getSpriteY() : Int {
        return this.spritesheet.y;
    }

    //TODO: Maybe shouldn't even have to pass in tileDimension.
    //TODO: this should be a static method.
    /** Load a spritesheet. tileDimension should be the size of the tiles or null if
     *  there's only one tile. whichTile is the tile that this Graphic will be; pass in
     *  null if you want to defer the decision by calling setTile() later.
     */
    public function loadSpritesheet(filepath: String, tileDimension : Vec = null, whichTile : Vec = null) : Graphic {
        Util.assert(fullTexture == null, "fullTexture is already set.");
        Util.assert(tileDimension == null || !tileDimension.equals(new Vec(0, 0)), "tileDimension can't be 0 by 0!");

        if (whichTile == null)     whichTile = new Vec(0, 0);

#if flash
        var spritesheetObj = nme.Assets.getBitmapData(filepath);
        var classAsKey:String = Type.getClassName(Type.getClass(spritesheetObj));
        // TODO Probably completely unnecessary, I'm sure Starling caches this.
        if (cachedAssets.exists(classAsKey)) {
            fullTexture = cachedAssets.get(classAsKey);
        } else {
            fullTexture = Texture.fromBitmapData(spritesheetObj);
            cachedAssets.set(classAsKey, fullTexture);
        }

        if (tileDimension == null) tileDimension = new Vec(fullTexture.nativeWidth, fullTexture.nativeHeight);

        texturedObject = new Image(fullTexture);
        texturedObject.width  = tileDimension.x;
        texturedObject.height = tileDimension.y;
#else
        var spritesheetObj = nme.Assets.getBitmapData(filepath);
        fullTexture = spritesheetObj;
        texturedObject = new Bitmap(fullTexture);

        if (tileDimension == null) tileDimension = new Vec(fullTexture.width, fullTexture.height);
#end

        addChild(texturedObject);

        texturedObject.x = 0;
        texturedObject.y = 0;

        //texturedObject.pivotX = texturedObject.width / 2;
        //texturedObject.pivotY = texturedObject.height / 2;

        tileWidth  = Std.int(tileDimension.x);
        tileHeight = Std.int(tileDimension.y);

        setTile(Std.int(whichTile.x), Std.int(whichTile.y));

        return this;
    }

#if cpp
    public function loadHotSwapImage(path: String) {
        if (hotswapped == null) {
            hotswapped = new ReloadedGraphic(path);
            addChild(hotswapped);
        } else {
            Util.assert(false, "haven't figured this out TODO");
        }

        return this;
    }
#end

    // In the case that your Graphic is just one big static image, you can use loadImage().
    public function loadImage(imgClass : Dynamic) : Graphic {
        loadSpritesheet(imgClass);
        return this;
    }

    public function setPos(newX: Int, newY: Int): Graphic {
        this.x = newX;
        this.y = newY;
        return this;
    }

    public static function takeScreenshot(): BitmapData {
        var sw:Int, sh: Int;

        sw = Fathom.actualStage.stageWidth;
        sh = Fathom.actualStage.stageHeight;

        var result:BitmapData = new BitmapData(sw, sh, true);

#if flash
        var support:RenderSupport = new RenderSupport();
        RenderSupport.clear(flash.Lib.current.stage.color, 1.0);
        support.setOrthographicProjection(0, 0, sw, sh);
        Fathom.starling.stage.render(support, 1.0);
        support.finishQuadBatch();

        Starling.context.drawToBitmapData(result);
#else
        result.draw(Fathom.actualStage);
#end

        return result;
    }

    public static function showScreenshot(): Void {
        var bd:BitmapData = takeScreenshot();
#if flash
        var img = new Image(Texture.fromBitmapData(bd));
        img.x = 200;
        img.y = 200;
        Fathom.stage.addChild(img);
#else
        var b:Bitmap = new Bitmap(bd);
        b.x = 200;
        b.y = 200;

        Fathom.stage.addChild(b);
#end
    }

    /** This method should only be used for testing.
     *  Don't use it in an actual game!
     */
    public function getPixel(pixelX:Int, pixelY:Int): Int {
        Util.assert(Math.floor(x) == x && Math.floor(y) == y, "x or y coordinates are non-int.");

        return takeScreenshot().getPixel(Std.int(x) + pixelX, Std.int(y) + pixelY);
    }

    var facing : Int;
    // Pass in the x-coordinate of your velocity, and this'll orient
    // the Graphic in that direction.
    public function face(dir : Int) : Void {
        texturedObject.scaleX = dir;
    }

    public function setDepth(v : Int) : Int {
        _depth = v;
        return v;
    }

    public function getDepth() : Int {
        return _depth;
    }

    //TODO...
    public function update() : Void {
        animations.advance();
    }

    public function add(p: Vec) : Graphic {
        x += p.x;
        y += p.y;

        return this;
    }

    /*
    public function destroy():void {
        animations = null;
        pixels = null;
        spritesheet = null;
        groupSet = null;
        entityChildren = null;
        cachedAssets = null;
        fullTexture = null;
    }
    */

    public function rect() : Rect {
        return new Rect(x, y, width, height);
    }

    public function vec() : Vec {
        return new Vec(x, y);
    }
}

