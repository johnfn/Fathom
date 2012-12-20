package {
  import flash.display.Sprite;
  import flash.display.DisplayObject;
  import flash.display.DisplayObjectContainer;
  import flash.filters.DropShadowFilter;
  import flash.geom.Point;
  import flash.utils.getQualifiedClassName;
  import flash.debugger.enterDebugger;
  import mx.core.BitmapAsset;
  import flash.utils.Dictionary;
  import flash.display.BitmapData;

  import flash.display.Bitmap;
  import flash.geom.Rectangle;
  import flash.geom.Matrix;
  import flash.events.*;

  import Hooks;
  import Util;
  import MagicArray;

  public class Graphic extends Sprite implements IPositionable {
    // The location of the entity, before camera transformations.
    private var entitySpacePos:Rect;

    // The location of the entity, after camera transformations.
    public var cameraSpacePos:Rect;

    public var animations:AnimationHandler;

    protected var pixels:Bitmap = new Bitmap();
    protected var spritesheet:Array = []
    protected var groupSet:Set = new Set(["persistent"]);
    protected var entityChildren:Array = [];
    protected var _depth:int = 0;

    private static var cachedAssets:Dictionary = new Dictionary();

    // Rename spritesheetObj and spritesheet
    // spritesheetObj isnt even necessarily a spritesheet
    protected var spritesheetObj:* = null;

    protected var spriteSheetWidth:int = -1;
    protected var spriteSheetHeight:int = -1;

  	function Graphic(x:Number = 0, y:Number = 0, width:Number = -1, height:Number = -1):void {
  		super();

        if (height == -1) height = width;

        this.cameraSpacePos = new Rect(0, 0, width, height);
        this.entitySpacePos = new Rect(x, y, width, height);

  		this.x = x;
  		this.y = y;

        if (height != -1) {
	        this.height = height;
        }

        if (width != -1) {
	        this.width = width;
        }

        animations = new AnimationHandler(this);

	    // Bypass our overridden addChild method.
	    super.addChild(pixels);
  	}

    public function raiseToTop():void {
      // TODO
    	//Util.assert(this.parent != null);

      if (this.parent) {
	      this.parent.setChildIndex(this, this.parent.numChildren - 1);
      }
    }


    public function get absX():Number {
      var p:DisplayObjectContainer = this;
      var result:int = 0;

      while (p != null) {
        result += p.x;

        p = p.parent;
      }

      return result;
    }

    public function get absY():Number {
      var p:DisplayObjectContainer = this;
      var result:int = 0;

      while (p != null) {
        result += p.y;

        p = p.parent;
      }

      return result;
    }

    // Set this entities graphics to be the sprite at (x, y) on the provided spritesheet.
    public function setTile(x:int, y:int):Graphic {
      Util.assert(this.spritesheetObj != null);
      Util.assert(entityChildren.length == 0);

      var bAsset:BitmapAsset = spritesheetObj; //TODO: Cache this
      var uid:String = Util.className(spritesheetObj) + x + " " + y;

      if (!(cachedAssets[uid])) {
        var bd:BitmapData = new BitmapData(spriteSheetWidth, spriteSheetHeight, true, 0);
        var source:Rectangle = new Rectangle(x * spriteSheetWidth, y * spriteSheetHeight, spriteSheetWidth, spriteSheetHeight);

        bd.copyPixels(bAsset.bitmapData, source, new Point(0, 0), null, null, true);

        cachedAssets[uid] = bd;
      }

      this.spritesheet = [x, y];
      pixels.bitmapData = cachedAssets[uid];


      // TODO: Implicit assumption that bitmap faces right.
      // TODO: Caching?
      if (facing == -1) {
        pixels.bitmapData = flipBitmapData(pixels.bitmapData)
      }

      if (!animations.hasAnimation("default")) {
        animations.addAnimation("default", x, y, 1);
      }

      return this;
    }

    public function get spriteX():int {
      return this.spritesheet[0];
    }

    public function get spriteY():int {
      return this.spritesheet[1];
    }

    // TODO: This could eventually be called setOrigin.
    public function setRotationOrigin(x:Number, y:Number):Graphic {
      pixels.x -= x;
      pixels.y -= y;

      return this;
    }

    //TODO: Maybe shouldn't even have to pass in tileDimension.

    /* Load a spritesheet. tileDimension should be the size of the tiles; pass in null if
       there's only one tile. whichTile is the tile that this Graphic will be; pass in
       null if you want to defer the decision by calling setTile() later. */
    public function loadSpritesheet(spritesheetClass:*, tileDimension:Vec = null, whichTile:Vec = null):Graphic {
      Util.assert(this.spritesheetObj == null);

      this.spritesheetObj = new spritesheetClass();

      var spritesheetSize:Vec = new Vec(spritesheetObj.width, spritesheetObj.height)

      if (tileDimension != null) {
        this.spriteSheetWidth = tileDimension.x;
        this.spriteSheetHeight = tileDimension.y;
      } else {
        this.spriteSheetWidth = spritesheetObj.width;
        this.spriteSheetHeight = spritesheetObj.height;
      }

      if (whichTile != null) {
        setTile(whichTile.x, whichTile.y)
      } else {
        setTile(0, 0);
      }

      return this;
    }

    // In the case that your Graphic is just one big static image, you can use loadImage().
    public function loadImage(imgClass:*):Graphic {
      loadSpritesheet(imgClass);
      return this;
    }

    public function flipBitmapData(original:BitmapData, axis:String = "x"):BitmapData {
      var flipped:BitmapData = new BitmapData(original.width, original.height, true, 0);
      var matrix:Matrix;

      if (axis == "x") {
          matrix = new Matrix( -1, 0, 0, 1, original.width, 0);
      } else {
          matrix = new Matrix( 1, 0, 0, -1, 0, original.height);
      }

      flipped.draw(original, matrix, null, null, null, true);
      return flipped;
    }

    public function setPos(v:IPositionable):Graphic {
      x = v.x;
      y = v.y;

      return this;
    }

    // These two are in Camera space.
    public function get cameraSpaceScaleX():Number { return scaleX; }
    public function get cameraSpaceScaleY():Number { return scaleY; }

    protected var facing:int = 1;

    // Pass in the x-coordinate of your velocity, and this'll orient
    // the Graphic in that direction.
    protected function face(dir:int):void {
      if (dir > 0 && facing < 0) {
        pixels.bitmapData = flipBitmapData(pixels.bitmapData)
        facing = dir;
        return;
      }
      if (dir < 0 && facing > 0) {
        pixels.bitmapData = flipBitmapData(pixels.bitmapData)
        facing = dir;
        return;
      }
    }

    public function set depth(v:int):void {
      _depth = v;
    }

    public function get depth():int {
      return _depth;
    }

    //TODO...
    public function update(e:EntitySet):void {
      animations.advance();
      Fathom.camera.translateSingleObject(this);
    }

    public function add(p:IPositionable):Graphic {
      this.x += p.x;
      this.y += p.y;

      return this;
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
	    spritesheetObj = null;
    }
    */

    // Uninteresting getters and setters.

    public override function set x(val:Number):void {
      entitySpacePos.x = val;
    }

    public override function get x():Number {
      return entitySpacePos.x;
    }

    public override function set y(val:Number):void {
      entitySpacePos.y = val;
    }

    public override function get y():Number {
      return entitySpacePos.y;
    }

    public function set cameraSpaceX(val:Number):void {
      cameraSpacePos.x = val;
      super.x = cameraSpacePos.x;
    }

    public function get cameraSpaceX():Number {
      return cameraSpacePos.x;
    }

    public function set cameraSpaceY(val:Number):void {
      cameraSpacePos.y = val;
      super.y = cameraSpacePos.y
    }

    public function get cameraSpaceY():Number {
      return cameraSpacePos.y;
    }

    public override function set width(val:Number):void {
      entitySpacePos.width = val;
    }

    public override function get width():Number {
      return entitySpacePos.width;
    }

    public override function set height(val:Number):void {
      entitySpacePos.height = val;
    }

    public override function get height():Number {
      return entitySpacePos.height;
    }

    public function rect():Rect {
      return new Rect(entitySpacePos.x, entitySpacePos.y, width, height);
    }

    public function vec():Vec {
      return new Vec(entitySpacePos.x, entitySpacePos.y);
    }
  }
}