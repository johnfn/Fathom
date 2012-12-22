import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.filters.DropShadowFilter;
import flash.geom.Point;
import flash.utils.Dictionary;
import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.geom.Rectangle;
import flash.events.Event;
import flash.geom.Matrix;
import Hooks;
import Util;

using Lambda;

class Entity extends Graphic {
	public var isStatic(getIsStatic, setIsStatic) : Bool;

	public var absX(getAbsX, never) : Float;
	public var absY(getAbsY, never) : Float;

	var events : Dynamic;
	public var isFlickering : Bool;
	// This indicates that the object should be destroyed.
	// The update loop in Fathom will eventually destroy it.
	public var destroyed : Bool;
	// These are purely for debugging purposes.
	static var counter : Int = 0;
	var uid : Float;
	var rememberedParent : Graphic;
	var groupSet : Set<String>;
	var entityChildren : Array<Entity>;
	// Allows for a fast check to see if this entity moves.
	var _isStatic : Bool;

	public function getIsStatic() : Bool {
		return _isStatic;
	}

	function setIsStatic(val : Bool) : Bool {
		_isStatic = val;
		return val;
	}

	public function new(x : Float = 0, y : Float = 0, width : Float = -1, height : Float = -1) {
		entityChildren = [];
		events = { };
		isFlickering = false;
		destroyed = false;
		uid = ++counter;
		_isStatic = true;
		groupSet = new Set(["persistent"]);
		super(x, y, width, height);
		if(!Fathom.initialized)  {
			throw "Util.initialize() has not been called. Failing.";
		}

		//TODO: I had this idea about how parents should bubble down events to children.
		// All Entities are added to the container, except the container itself, which
		// has to be bootstrapped onto the Stage. If Fathom.container does not exist, `this`
		// must be the container.
		if(Fathom.container != null)  {
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
		sprite.addEventListener(Event.ENTER_FRAME, f);
		return this;
	}

	public function unlisten(f) : Entity {
		sprite.removeEventListener(Event.ENTER_FRAME, f);
		return this;
	}

	public function debugDraw() : Entity {
		sprite.graphics.beginFill(0xFF0000);
		sprite.graphics.drawRect(0, 0, this.width, this.height);
		sprite.graphics.endFill();
		return this;
	}

	public function disappearAfter(frames : Int) : Entity {
		var timeLeft : Int = frames;
		var that : Entity = this;
		listen(function(_:Dynamic) : Void {
			if(timeLeft-- == 0)  {
				that.destroy();
			}
		});

		return this;
	}

	/* Put this entity in the middle of the screen. Useful for dialogs,
       inventory screens, etc. */
    public function centerOnScreen() : Void {
		x = Fathom.stage.width / 2 - this.width / 2;
		y = Fathom.stage.height / 2 - this.height / 2;
	}

	public function addChild(child : Entity) : Entity {
		if(entityChildren != null)
			throw "You need to call super() before addChild().";

		Util.assert(entityChildren.has(child));
		sprite.addChild(child.sprite);
		if(Std.is(child, Entity))  {
			entityChildren.push(child);
		}
		return child;
	}

	// Remove child: The child entity does not belong to this entity as a child.
	// It continues to exist in the game.
	public function removeChild(child : Entity) : Entity {
		if(Std.is(child, Entity))
			Util.assert(entityChildren.has(child));

		entityChildren.remove(child);
		sprite.removeChild(child.sprite);
		return child;
	}

	/* This causes the Entity to cease existing in-game. The only way to
       bring it back is to call addToFathom(). */
    public function removeFromFathom(recursing : Bool = false) : Void {
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
		if(!recursing && this.parent != null)
			sprite.parent.removeChild(this.sprite);
		Fathom.entities.remove(this);
	}

	/* This causes the Entity to exist in the game. There is no need to call
       this except after a call to removeFromFathom(). */
    public function addToFathom(recursing : Bool = false) : Void {
		Util.assert(!destroyed);
		Util.assert(this.parent == null);
		if(!recursing)
			rememberedParent.sprite.addChild(this.sprite);
		Fathom.entities.add(this);
		Util.assert(rememberedParent != null);
	}

	/* This flags an Entity to be removed permanently. It can't be add()ed back. */
	public function destroy() : Void {
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

	public function addGroups(list:Array<String>) : Entity {
		groupSet.extend(new Set(list));
		return this;
	}

	public function sortDepths() : Void {
		entityChildren.sort(function(a : Graphic, b : Graphic) : Int {
			return a.depth - b.depth;
		});

		var i : Int = 0;
		while(i < entityChildren.length) {
			entityChildren[i].raiseToTop();
			i++;
		}
	}

	//TODO: Group strings to enums with Inheritable property.
	//TODO: There is a possible namespace collision here. assert no 2 groups have same name.
	//TODO: Enumerations are better.
	public function groups() : Set<String> {
		return groupSet.concat(Util.className(this));
	}

	public function touchingRect(rect : Entity) : Bool {
		return (rect.x < this.x + this.width && rect.x + rect.width > this.x && rect.y < this.y + this.height && rect.y + rect.height > this.y);
	}

	public function collides(other : Entity) : Bool {
		return (!(this == other)) && touchingRect(other);
	}

	public function collidesPt(point : Point) : Bool {
		return point.x >= this.x && point.x <= this.x + this.width &&
		       point.y >= this.y && point.y <= this.y + this.height;
	}

	override public function update(e : Set<Entity>) : Void {
		super.update(e);
	}

	override public function toString() : String {
		return "[" + Util.className(this) + " " + this.x + " " + this.y + " " + this.groups() + "]";
	}

	// Modes for which this entity receives events.
	public function modes() : Array<Dynamic> {
		return [0];
	}

	public function getAbsX() : Float {
		var p : Graphic = this;
		var result : Float = 0;
		while(p != null) {
			result += p.x;
			p = p.parent;
		}

		return result;
	}

	public function getAbsY() : Float {
		var p : Graphic = this;
		var result : Float = 0;
		while(p != null) {
			result += p.y;
			p = p.parent;
		}

		return result;
	}


}

