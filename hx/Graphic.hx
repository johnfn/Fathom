import starling.display.Image;
import starling.textures.Texture;
import starling.display.Sprite;
import starling.display.DisplayObjectContainer;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.Matrix;
import starling.events.Event;
import flash.utils.TypedDictionary;

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
    var texturedObject:Image;
    var sprite:Sprite;

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
    static var cachedAssets : TypedDictionary<String, Texture> = new TypedDictionary();
    // Rename spritesheet
    var fullTexture : Texture;
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

    public function new(x : Float = 0, y : Float = 0, width : Float = -1, height : Float = -1) {
        _depth = 0;
        fullTexture = null;
        tileWidth = -1;
        tileHeight = -1;
        facing = 1;
        spritesheet = {x: 0, y: 0};

        sprite = new Sprite();
        sprite.x = x;
        sprite.y = y;

        if (height == -1) height = width;

        cameraSpacePos = new Rect(0, 0, width, height);
        entitySpacePos = new Rect(x, y, width, height);
        this.x = x;
        this.y = y;

        if (height != -1) {
            this.height = height;
        }

        if (width != -1) {
            this.width = width;
        }

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
    public function setTile(x : Int, y : Int) : Graphic {
        Util.assert(fullTexture != null, "The spritesheet is null.");
        spritesheet.x = x;
        spritesheet.y = y;

        var region:Rectangle = new Rectangle(x * tileWidth, y * tileHeight, tileWidth, tileHeight);
        texturedObject.texture = Texture.fromTexture(fullTexture, region);

        // TODO: Implicit assumption that bitmap faces right.
        /*
        if(facing == -1)  {
            pixels.bitmapData = flipBitmapData(pixels.bitmapData);
        }
        */

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
    public function loadSpritesheet<T : (BitmapData)>(spritesheetClass : Class<T>, tileDimension : Vec = null, whichTile : Vec = null) : Graphic {
        Util.assert(fullTexture == null);
        Util.assert(tileDimension == null || !tileDimension.equals(new Vec(0, 0)));

        var classAsKey:String = Type.getClassName(spritesheetClass);
        if (cachedAssets.exists(classAsKey)) {
            fullTexture = cachedAssets.get(classAsKey);
        } else {
            fullTexture = Texture.fromBitmapData(Type.createInstance(spritesheetClass, [0, 0]));
            cachedAssets.set(classAsKey, fullTexture);
        }

        if (whichTile == null)     whichTile = new Vec(0, 0);
        if (tileDimension == null) tileDimension = new Vec(fullTexture.nativeWidth, fullTexture.nativeHeight);

        texturedObject = new Image(fullTexture);
        texturedObject.width  = tileDimension.x;
        texturedObject.height = tileDimension.y;

        texturedObject.x = 0;
        texturedObject.y = 0;

        sprite.addChild(texturedObject);

        tileWidth  = Std.int(tileDimension.x);
        tileHeight = Std.int(tileDimension.y);

        setTile(Std.int(whichTile.x), Std.int(whichTile.y));

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

    public function getTexture(): Texture {
        return texturedObject.texture;
    }

    public function setTexture(t: Texture): Texture {
        return texturedObject.texture = t;
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

#if debug
    /** This method is ONLY for testing.
     *  Don't use it in an actal game!
     */
    public function getPixel(x:Int, y:Int) : UInt {
        sprite.x = 0;
        sprite.y = 0;

        var bd:BitmapData = new BitmapData(Std.int(Fathom.stage.width), Std.int(Fathom.stage.height));
        bd.draw(Fathom.stage);
        var b:Bitmap = new Bitmap(bd);

        return b.bitmapData.getPixel(x, y);
    }
#end

    var facing : Int;
    // Pass in the x-coordinate of your velocity, and this'll orient
    // the Graphic in that direction.
    public function face(dir : Int) : Void {
        Util.assert(false, "under construction");
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
        Fathom.camera.translateSingleObject(this);
    }

    public function add(p : IPositionable) : Graphic {
        this.x += p.x;
        this.y += p.y;

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
        return val;
    }

    public function getWidth() : Float {
        return entitySpacePos.width;
    }

    public function setHeight(val : Float) : Float {
        entitySpacePos.height = val;
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

