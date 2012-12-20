import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.filters.DropShadowFilter;
import flash.geom.Point;
import flash.utils.Dictionary;
import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.geom.Rectangle;
import flash.geom.Matrix;
import Hooks;
import Util;

class Entity extends Graphic {
	public var isStatic(getIsStatic, setIsStatic) : Bool;

	var events : Dynamic;
	public var isFlickering : Bool;
	// This indicates that the object should be destroyed.
		// The update loop in Fathom will eventually destroy it.
		public var destroyed : Bool;
	// These are purely for debugging purposes.
		static var counter : Int = 0;
	var uid : Float;
	var rememberedParent : DisplayObjectContainer;
	// Allows for a fast check to see if this entity moves.
		var _isStatic : Bool;
	public function getIsStatic() : Bool {
		return _isStatic;
	}

	function setIsStatic(val : Bool) : Bool {
		_isStatic = val;
		return val;
	}

	function new(x : Float = 0, y : Float = 0, width : Float = -1, height : Float = -1) {
		events = { };
		isFlickering = false;
		destroyed = false;
		uid = ++counter;
		_isStatic = true;
		super(x, y, width, height);
		if(!Fathom.initialized)  {
			throw new Error("Util.initialize() has not been called. Failing.");
		}
		//TODO: I had this idea about how parents should bubble down events to children.
		// All Entities are added to the container, except the container itself, which
		// has to be bootstrapped onto the Stage. If Fathom.container does not exist, `this`
		// must be the container.
		if(Fathom.container)  {
			this.rememberedParent = Fathom.container;
			addToFathom();
		}
	}

	public function withDepth(d : Int) : Entity {
		_depth = d;
		return this;
	}

	// Chainable methods.
	//
	// Often you'll want a lightweight custom Entity without wanting to
	// code up an entirely new class that extends. Chainable methods are
	// for you. If I want to make an explosion that quickly disappears,
	// for instance, I can do something like this:
	//
	// new Entity().fromExternalMC("Explosion").ignoreCollisions().disappearAfter(20);
	// TODO: These two need work.

	public function listen(f) : Entity {
		this.addEventListener(Event.ENTER_FRAME, f);
		return this;
	}

	public function unlisten(f) : Entity {
		this.removeEventListener(Event.ENTER_FRAME, f);
		return this;
	}

	public function debugDraw() : Entity {
		graphics.beginFill(0xFF0000);
		graphics.drawRect(0, 0, this.width, this.height);
		graphics.endFill();
		return this;
	}

	public function disappearAfter(frames : Int) : Entity {
		var timeLeft : Int = frames;
		var that : Entity = this;
		listen(function() : Void {
			if(timeLeft-- == 0)  {
				that.destroy();
			}
		}
);
		return this;
	}

	/* Put this entity in the middle of the screen. Useful for dialogs,
       inventory screens, etc. */	public function centerOnScreen() : Void {
		x = Fathom.stage.width / 2 - this.width / 2;
		y = Fathom.stage.height / 2 - this.height / 2;
	}

	override public function addChild(child : DisplayObject) : DisplayObject {
		if(!entityChildren)
			throw new Error("You need to call super() before addChild().");
		Util.assert(!entityChildren.contains(child));
		super.addChild(child);
		if(Std.is(child, Entity))  {
			entityChildren.push(child);
		}
		return child;
	}

	// Remove child: The child entity does not belong to this entity as a child.
		// It continues to exist in the game.
		override public function removeChild(child : DisplayObject) : DisplayObject {
		if(Std.is(child, Entity))
			Util.assert(entityChildren.contains(child));
		entityChildren.remove(child);
		super.removeChild(child);
		return child;
	}

	/* This causes the Entity to cease existing in-game. The only way to
       bring it back is to call addToFathom(). */	public function removeFromFathom(recursing : Bool = false) : Void {
		Util.assert(this.parent != null);
		if(!Fathom.entities.contains(this))  {
			trace(this, " removed but not in Fathom.");
			Util.assert(false);
		}
		this.rememberedParent = this.parent;
		var i : Int = 0;
		while(i < entityChildren.length) {
			entityChildren[i].removeFromFathom(true);
			i++;
		}
		if(!recursing && this.parent)
			this.parent.removeChild(this);
		Fathom.entities.remove(this);
	}

	/* This causes the Entity to exist in the game. There is no need to call
       this except after a call to removeFromFathom(). */	public function addToFathom(recursing : Bool = false) : Void {
		Util.assert(!destroyed);
		Util.assert(!this.parent);
		if(!recursing)
			rememberedParent.addChild(this);
		Fathom.entities.add(this);
		Util.assert(rememberedParent != null);
	}

	/* This flags an Entity to be removed permanently. It can't be add()ed back. */	public function destroy() : Void {
		Util.assert(Fathom.entities.contains(this));
		destroyed = true;
	}

	//TODO: Does not entirely clear memory.
		// If an entity is flagged for removal with destroy(), clearMemory() will eventually
		// be called on it.
		public function clearMemory() : Void {
		removeFromFathom();
		events = null;
		destroyed = true;
	}

	public function addGroups() : Entity {
		groupSet.extend(new Set(args));
		return this;
	}

	public function sortDepths() : Void {
		entityChildren.sort(function(a : Entity, b : Entity) : Int {
			return a.depth - b.depth;
		}
);
		var i : Int = 0;
		while(i < entityChildren.length) {
			entityChildren[i].raiseToTop();
			i++;
		}
	}

	//TODO: Group strings to enums with Inheritable property.
		//TODO: There is a possible namespace collision here. assert no 2 groups have same name.
		//TODO: Enumerations are better.
		public function groups() : Set {
		return groupSet.concat(Util.className(this));
	}

	public function touchingRect(rect : Entity) : Bool {
		return (rect.x < this.x + this.width && rect.x + rect.width > this.x && rect.y < this.y + this.height && rect.y + rect.height > this.y);
	}

	public function collides(other : Entity) : Bool {
		return (!(this == other)) && touchingRect(other);
	}

	public function collidesPt(point : Point) : Bool {
		return hitTestPoint(point.x, point.y);
	}

	override public function update(e : EntitySet) : Void {
		super.update(e);
	}

	override public function toString() : String {
		return "[" + Util.className(this) + " " + this.x + " " + this.y + " " + this.groups() + "]";
	}

	// Modes for which this entity receives events.
		public function modes() : Array<Dynamic> {
		return [0];
	}

}

