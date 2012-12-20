import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.filters.DropShadowFilter;
import flash.geom.Point;
import flash.debugger.EnterDebugger;
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

class Graphic extends Sprite, implements IPositionable {
	public var absX(getAbsX, never) : Float;
	public var absY(getAbsY, never) : Float;
	public var spriteX(getSpriteX, never) : Int;
	public var spriteY(getSpriteY, never) : Int;
	public var cameraSpaceScaleX(getCameraSpaceScaleX, never) : Float;
	public var cameraSpaceScaleY(getCameraSpaceScaleY, never) : Float;
	public var depth(getDepth, setDepth) : Int;
	public var cameraSpaceX(getCameraSpaceX, setCameraSpaceX) : Float;
	public var cameraSpaceY(getCameraSpaceY, setCameraSpaceY) : Float;

	// The location of the entity, before camera transformations.
		var entitySpacePos : Rect;
	// The location of the entity, after camera transformations.
		public var cameraSpacePos : Rect;
	public var animations : AnimationHandler;
	var pixels : Bitmap;
	var spritesheet : Array<Dynamic>;
	var groupSet : Set;
	var entityChildren : Array<Dynamic>;
	var _depth : Int;
	static var cachedAssets : Dictionary = new Dictionary();
	// Rename spritesheetObj and spritesheet
		// spritesheetObj isnt even necessarily a spritesheet
		var spritesheetObj : Dynamic;
	var spriteSheetWidth : Int;
	var spriteSheetHeight : Int;
	function new(x : Float = 0, y : Float = 0, width : Float = -1, height : Float = -1) {
		pixels = new Bitmap();
		spritesheet = [];
		groupSet = new Set(["persistent"]);
		entityChildren = [];
		_depth = 0;
		spritesheetObj = null;
		spriteSheetWidth = -1;
		spriteSheetHeight = -1;
		facing = 1;
		super();
		if(height == -1) 
			height = width;
		this.cameraSpacePos = new Rect(0, 0, width, height);
		this.entitySpacePos = new Rect(x, y, width, height);
		this.x = x;
		this.y = y;
		if(height != -1)  {
			this.height = height;
		}
		if(width != -1)  {
			this.width = width;
		}
		animations = new AnimationHandler(this);
		// Bypass our overridden addChild method.
		super.addChild(pixels);
	}

	public function raiseToTop() : Void {
		// TODO
		//Util.assert(this.parent != null);
		if(this.parent)  {
			this.parent.setChildIndex(this, this.parent.numChildren - 1);
		}
;
	}

	public function getAbsX() : Float {
		var p : DisplayObjectContainer = this;
		var result : Int = 0;
		while(p != null) {
			result += p.x;
			p = p.parent;
		}

		return result;
	}

	public function getAbsY() : Float {
		var p : DisplayObjectContainer = this;
		var result : Int = 0;
		while(p != null) {
			result += p.y;
			p = p.parent;
		}

		return result;
	}

	// Set this entities graphics to be the sprite at (x, y) on the provided spritesheet.
		public function setTile(x : Int, y : Int) : Graphic {
		Util.assert(this.spritesheetObj != null);
		Util.assert(entityChildren.length == 0);
		var bAsset : BitmapAsset = spritesheetObj;
		//TODO: Cache this
		var uid : String = Util.className(spritesheetObj) + x + " " + y;
		if(!(Reflect.field(cachedAssets, uid)))  {
			var bd : BitmapData = new BitmapData(spriteSheetWidth, spriteSheetHeight, true, 0);
			var source : Rectangle = new Rectangle(x * spriteSheetWidth, y * spriteSheetHeight, spriteSheetWidth, spriteSheetHeight);
			bd.copyPixels(bAsset.bitmapData, source, new Point(0, 0), null, null, true);
			Reflect.setField(cachedAssets, uid, bd);
		}
		this.spritesheet = [x, y];
		pixels.bitmapData = Reflect.field(cachedAssets, uid);
		// TODO: Implicit assumption that bitmap faces right.
		// TODO: Caching?
		if(facing == -1)  {
			pixels.bitmapData = flipBitmapData(pixels.bitmapData);
		}
;
		if(!animations.hasAnimation("default"))  {
			animations.addAnimation("default", x, y, 1);
		}
		return this;
	}

	public function getSpriteX() : Int {
		return this.spritesheet[0];
	}

	public function getSpriteY() : Int {
		return this.spritesheet[1];
	}

	// TODO: This could eventually be called setOrigin.
		public function setRotationOrigin(x : Float, y : Float) : Graphic {
		pixels.x -= x;
		pixels.y -= y;
		return this;
	}

	//TODO: Maybe shouldn't even have to pass in tileDimension.
		/* Load a spritesheet. tileDimension should be the size of the tiles; pass in null if
       there's only one tile. whichTile is the tile that this Graphic will be; pass in
       null if you want to defer the decision by calling setTile() later. */	public function loadSpritesheet(spritesheetClass : Dynamic, tileDimension : Vec = null, whichTile : Vec = null) : Graphic {
		Util.assert(this.spritesheetObj == null);
		this.spritesheetObj = new SpritesheetClass();
		var spritesheetSize : Vec = new Vec(spritesheetObj.width, spritesheetObj.height);
		if(tileDimension != null)  {
			this.spriteSheetWidth = tileDimension.x;
			this.spriteSheetHeight = tileDimension.y;
		}

		else  {
			this.spriteSheetWidth = spritesheetObj.width;
			this.spriteSheetHeight = spritesheetObj.height;
		}

		if(whichTile != null)  {
			setTile(whichTile.x, whichTile.y);
		}

		else  {
			setTile(0, 0);
		}

		return this;
	}

	// In the case that your Graphic is just one big static image, you can use loadImage().
		public function loadImage(imgClass : Dynamic) : Graphic {
		loadSpritesheet(imgClass);
		return this;
	}

	public function flipBitmapData(original : BitmapData, axis : String = "x") : BitmapData {
		var flipped : BitmapData = new BitmapData(original.width, original.height, true, 0);
		var matrix : Matrix;
		if(axis == "x")  {
			matrix = new Matrix(-1, 0, 0, 1, original.width, 0);
		}

		else  {
			matrix = new Matrix(1, 0, 0, -1, 0, original.height);
		}

		flipped.draw(original, matrix, null, null, null, true);
		return flipped;
	}

	public function setPos(v : IPositionable) : Graphic {
		x = v.x;
		y = v.y;
		return this;
	}

	// These two are in Camera space.
		public function getCameraSpaceScaleX() : Float {
		return scaleX;
	}

	public function getCameraSpaceScaleY() : Float {
		return scaleY;
	}

	var facing : Int;
	// Pass in the x-coordinate of your velocity, and this'll orient
		// the Graphic in that direction.
		function face(dir : Int) : Void {
		if(dir > 0 && facing < 0)  {
			pixels.bitmapData = flipBitmapData(pixels.bitmapData);
			facing = dir;
			return;
		}
		if(dir < 0 && facing > 0)  {
			pixels.bitmapData = flipBitmapData(pixels.bitmapData);
			facing = dir;
			return;
		}
	}

	public function setDepth(v : Int) : Int {
		_depth = v;
		return v;
	}

	public function getDepth() : Int {
		return _depth;
	}

	//TODO...
		public function update(e : EntitySet) : Void {
		animations.advance();
		Fathom.camera.translateSingleObject(this);
	}

	public function add(p : IPositionable) : Graphic {
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
    */	// Uninteresting getters and setters.
		override public function setX(val : Float) : Float {
		entitySpacePos.x = val;
		return val;
	}

	override public function getX() : Float {
		return entitySpacePos.x;
	}

	override public function setY(val : Float) : Float {
		entitySpacePos.y = val;
		return val;
	}

	override public function getY() : Float {
		return entitySpacePos.y;
	}

	public function setCameraSpaceX(val : Float) : Float {
		cameraSpacePos.x = val;
		super.x = cameraSpacePos.x;
		return val;
	}

	public function getCameraSpaceX() : Float {
		return cameraSpacePos.x;
	}

	public function setCameraSpaceY(val : Float) : Float {
		cameraSpacePos.y = val;
		super.y = cameraSpacePos.y;
		return val;
	}

	public function getCameraSpaceY() : Float {
		return cameraSpacePos.y;
	}

	override public function setWidth(val : Float) : Float {
		entitySpacePos.width = val;
		return val;
	}

	override public function getWidth() : Float {
		return entitySpacePos.width;
	}

	override public function setHeight(val : Float) : Float {
		entitySpacePos.height = val;
		return val;
	}

	override public function getHeight() : Float {
		return entitySpacePos.height;
	}

	public function rect() : Rect {
		return new Rect(entitySpacePos.x, entitySpacePos.y, width, height);
	}

	public function vec() : Vec {
		return new Vec(entitySpacePos.x, entitySpacePos.y);
	}

}

