#if nme
import nme.display.Sprite;
import nme.display.DisplayObjectContainer;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.events.Event;
#else
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

class Graphic implements IPositionable {
#if nme
    var texturedObject:Bitmap;
    static var cachedAssets: SuperObjectHash<String, BitmapData> = new SuperObjectHash();
    var fullTexture : BitmapData;
    var hotswapped: ReloadedGraphic;
#else
    var texturedObject:Image;
    static var cachedAssets: SuperObjectHash<String, Texture> = new SuperObjectHash();
    var fullTexture : Texture;
#end

    var sprite:DisplayObjectContainer;

    public var spriteX(getSpriteX, never) : Int;
    public var spriteY(getSpriteY, never) : Int;
    public var cameraSpaceScaleX(getCameraSpaceScaleX, never) : Float;
    public var cameraSpaceScaleY(getCameraSpaceScaleY, never) : Float;
    public var depth(getDepth, setDepth) : Int;
    public var cameraSpaceX(getCameraSpaceX, setCameraSpaceX) : Float;
    public var cameraSpaceY(getCameraSpaceY, setCameraSpaceY) : Float;
    public var numChildren(getNumChildren, never): Int;
    public var visible(getVisible, setVisible): Bool;

    // The location of the entity, before camera transformations.
    var entitySpacePos : Rect;
    // The location of the entity, after camera transformations.
    public var cameraSpacePos : Rect;
    public var animations : AnimationHandler;
    var spritesheet : SpriteSheet;
    // TODO: Rename
    var _depth : Int;
    var tileWidth : Int;
    var tileHeight : Int;

    public var height(getHeight, setHeight): Float;
    public var width(getWidth, setWidth): Float;
    public var x(getX, setX): Float;
    public var y(getY, setY): Float;
    public var scaleX(getScaleX, setScaleX): Float;
    public var scaleY(getScaleY, setScaleY): Float;
    public var alpha(getAlpha, setAlpha): Float;

    //TODO, obviously...
    public function HACK_sprite():DisplayObjectContainer {
        return sprite;
    }

    public function new() {
        Util.assert(Fathom.stage != null, "Stage is null.");

        _depth = 0;
        fullTexture = null;
        tileWidth = -1;
        tileHeight = -1;
        facing = 1;
        spritesheet = {x: 0, y: 0};

        sprite = new Sprite();

        cameraSpacePos = new Rect(0, 0, 0, 0);
        entitySpacePos = new Rect(0, 0, 0, 0);

        animations = new AnimationHandler(this);
    }

    public function addEventListener(etype, f: Event -> Void) {
        texturedObject.addEventListener(etype, f);
    }

    public function removeEventListener(etype, f: Event -> Void) {
        texturedObject.removeEventListener(etype, f);
    }

    public function toString(): String {
        return "[Graphic]";
    }

    // Set this entities graphics to be the sprite at (x, y) on the provided spritesheet.
    // TODO: Implicit assumption that bitmap faces right.
    public function setTile(x : Int, y : Int) : Graphic {
        Util.assert(fullTexture != null, "The spritesheet is null.");

        spritesheet.x = x;
        spritesheet.y = y;

        var region:Rectangle = new Rectangle(x * tileWidth, y * tileHeight, tileWidth, tileHeight);

#if flash
        texturedObject.texture = Texture.fromTexture(fullTexture, region);
#else
        var bd:BitmapData = new BitmapData(tileWidth, tileHeight, true, 0);
        bd.copyPixels(fullTexture, region, new Point(0, 0), null, null, true);

        texturedObject.bitmapData = bd;
#end

        if(!animations.hasAnimation("default"))  {
            animations.addAnimation("default", x, y, 1);
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
    public function loadSpritesheet(spritesheetObj: BitmapData, tileDimension : Vec = null, whichTile : Vec = null) : Graphic {
        Util.assert(fullTexture == null, "fullTexture is already set.");
        Util.assert(tileDimension == null || !tileDimension.equals(new Vec(0, 0)), "tileDimension can't be 0 by 0!");

        if (whichTile == null)     whichTile = new Vec(0, 0);

#if flash
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
        fullTexture = spritesheetObj;
        texturedObject = new Bitmap(fullTexture);

        if (tileDimension == null) tileDimension = new Vec(fullTexture.width, fullTexture.height);
#end

        sprite.addChild(texturedObject);

        texturedObject.x = 0;
        texturedObject.y = 0;

        //texturedObject.pivotX = texturedObject.width / 2;
        //texturedObject.pivotY = texturedObject.height / 2;

        tileWidth  = Std.int(tileDimension.x);
        tileHeight = Std.int(tileDimension.y);

        setTile(Std.int(whichTile.x), Std.int(whichTile.y));

        return this;
    }

    public function loadHotSwapImage(path: String) {
        hotswapped = new ReloadedGraphic(path);
        return this;
    }

    // In the case that your Graphic is just one big static image, you can use loadImage().
    public function loadImage(imgClass : Dynamic) : Graphic {
        loadSpritesheet(imgClass);
        return this;
    }

    public function setPos(v : IPositionable) : Graphic {
        x = v.x;
        y = v.y;
        return this;
    }

    /*
    public function getPixels(): Bitmap {
        return pixels;
    }

    public function setPixels(p: Bitmap): Bitmap {
        return pixels = p;
    }
    */

    // These two are in Camera space.
    public function getCameraSpaceScaleX() : Float {
        return scaleX;
    }

    public function getCameraSpaceScaleY() : Float {
        return scaleY;
    }

    public static function takeScreenshot(): BitmapData {
        var sw:Int, sh: Int;

        sw = Fathom.stage.stageWidth;
        sh = Fathom.stage.stageHeight;

        var result:BitmapData = new BitmapData(sw, sh, true);

#if nme
        result.draw(Fathom.stage);
#else
        var support:RenderSupport = new RenderSupport();
        RenderSupport.clear(flash.Lib.current.stage.color, 1.0);
        support.setOrthographicProjection(0, 0, sw, sh);
        Fathom.starling.stage.render(support, 1.0);
        support.finishQuadBatch();

        Starling.context.drawToBitmapData(result);
#end

        return result;
    }

    /** This method should only be used for testing.
     *  Don't use it in an actual game!
     */
    public function getPixel(x:Int, y:Int): Int {
        return takeScreenshot().getPixel(Std.int(sprite.x) + x, Std.int(sprite.y) + y);
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

    public function add(p : IPositionable) : Graphic {
        Util.assert(Fathom.stage.scaleX == 1, "Haven't considered scaled stages.");
        Util.assert(Fathom.stage.scaleY == 1, "Haven't considered scaled stages.");

        x += p.x;
        y += p.y;

        return this;
    }

    // TODO visibility. this is required for Map currently
    public function removeChildAt(idx: Int): Void {
        sprite.removeChildAt(idx);
    }

    /*
    public function destroy():void {
        entitySpacePos = null;
        cameraSpacePos = null;
        animations = null;
        pixels = null;
        spritesheet = null;
        groupSet = null;
        entityChildren = null;
        cachedAssets = null;
        fullTexture = null;
    }
    */
    // Uninteresting getters and setters.

    public function getScaleX(): Float {
        return sprite.scaleX;
    }

    public function getScaleY(): Float {
        return sprite.scaleY;
    }

    public function setScaleX(v: Float): Float {
        sprite.scaleX = v;

        return sprite.scaleX;
    }

    public function setScaleY(v: Float): Float {
        sprite.scaleY = v;

        return sprite.scaleY;
    }

    public function setX(val : Float) : Float {
        return entitySpacePos.x = val;
    }

    public function getX() : Float {
        return entitySpacePos.x;
    }

    public function setY(val : Float) : Float {
        return entitySpacePos.y = val;
    }

    public function getY() : Float {
        return entitySpacePos.y;
    }

    public function setCameraSpaceX(val : Float) : Float {
        cameraSpacePos.x = val;
        sprite.x = cameraSpacePos.x;
        return val;
    }

    public function getCameraSpaceX() : Float {
        return cameraSpacePos.x;
    }

    public function setCameraSpaceY(val : Float) : Float {
        cameraSpacePos.y = val;
        sprite.y = cameraSpacePos.y;
        return val;
    }

    public function getCameraSpaceY() : Float {
        return cameraSpacePos.y;
    }

    public function setWidth(val : Float) : Float {
        entitySpacePos.width = val;
        cameraSpacePos.width = val;
        return val;
    }

    public function getWidth() : Float {
        return entitySpacePos.width;
    }

    public function setHeight(val : Float) : Float {
        entitySpacePos.height = val;
        cameraSpacePos.height = val;
        return val;
    }

    public function getHeight() : Float {
        return entitySpacePos.height;
    }

    public function setAlpha(val : Float) : Float {
        sprite.alpha = val;
        return val;
    }

    public function getAlpha() : Float {
        return sprite.alpha;
    }

    public function rect() : Rect {
        return new Rect(entitySpacePos.x, entitySpacePos.y, width, height);
    }

    public function vec() : Vec {
        return new Vec(entitySpacePos.x, entitySpacePos.y);
    }

    public function getNumChildren(): Int {
        return sprite.numChildren;
    }

    public function getVisible(): Bool {
        return sprite.visible;
    }

    public function setVisible(val: Bool): Bool {
        return sprite.visible = val;
    }
}

