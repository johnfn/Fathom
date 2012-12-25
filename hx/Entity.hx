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

    public var isFlickering : Bool;
    // This indicates that the object should be destroyed.
    // The update loop in Fathom will eventually destroy it.
    public var destroyed : Bool;
    // These are purely for debugging purposes.
    static var counter : Int = 0;
    var uid : Float;
    var groupSet : Set<String>;
    var entityChildren : Array<Entity>;
    var events: Array<Void -> Void>;

    // Allows for a fast check to see if this entity moves.
    var _isStatic : Bool;
    var _currentlyInFathom: Bool = false;
    var _parent: Entity = null;

    public var inFathom(getInFathom, setInFathom): Bool;
    public var parent(getParent, setParent): Entity;

    public function getIsStatic() : Bool {
        return _isStatic;
    }

    function setIsStatic(val : Bool) : Bool {
        _isStatic = val;
        return val;
    }

    public function inFathom(): Bool {
        return _currentlyInFathom;
    }

    private function setInFathom(v: Bool): Bool {
        return _currentlyInFathom = v;
    }

    public function new(x : Float = 0, y : Float = 0, width : Float = -1, height : Float = -1) {
        entityChildren = [];
        events = [];
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
            Fathom.container.addChild(this);
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

    public function listen(f: Void -> Void) : Entity {
        events.push(f);
        return this;
    }

    public function unlisten(f) : Entity {
        Util.assert(events.remove(f), "In Entity#unlisten, event not found!");
        return this;
    }

    public function debugDraw() : Entity {
        sprite.graphics.beginFill(0xFF0000);
        sprite.graphics.drawRect(0, 0, this.width, this.height);
        sprite.graphics.endFill();
        return this;
    }

    public function destroyAfter(frames : Int) : Entity {
        var timeLeft : Int = frames;
        var that : Entity = this;

        listen(function() : Void {
            if(--timeLeft == 0)  {
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
        if(entityChildren == null)
            throw "You need to call super() before addChild().";
        Util.assert(!entityChildren.has(child), "Already has that child.");

        child.parent = this;
        sprite.addChild(child.sprite);
        entityChildren.push(child);
        return child;
    }

    // Remove child: The child entity does not belong to this entity as a child.
    // It continues to exist in the game.
    public function removeChild(child : Entity) : Entity {
        if(Std.is(child, Entity))
            Util.assert(entityChildren.has(child), "Doesn't have that child.");

        child.parent = null;
        entityChildren.remove(child);
        sprite.removeChild(child.sprite);
        return child;
    }

    /* This makes the entity disappear, but stay in memory. Think of a
       moveable block that you saw on another screen. You only need to call
       it on the parent object, not the children. */
    public function removeFromFathom() : Void {
        Util.assert(!destroyed, "Entity was destroyed.");
        Util.assert(Fathom.entities.contains(this), "Removed but not in Fathom.");

        for (ch in entityChildren) {
            ch.removeFromFathom();
        }

        this.visible = false;
        Fathom.entities.remove(this);
        _currentlyInFathom = false;
    }

    /* This causes the Entity to exist in the game. There is no need to call
       this except after a call to removeFromFathom(). */
    public function addToFathom() : Void {
        Util.assert(!destroyed, "Entity was destroyed.");
        Util.assert(!Fathom.entities.contains(this), "Added but already in Fathom.");

        for (ch in entityChildren) {
            ch.addToFathom();
        }

        this.visible = true;
        Fathom.entities.add(this);
        _currentlyInFathom = true;
    }

    /* This flags an Entity to be removed permanently. It can't be add()ed back. */
    public function destroy() : Void {
        Util.assert(Fathom.entities.contains(this), "That entity is not in Fathom.");
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

    public function addGroup(s: String): Entity {
        groupSet.add(s);
        return this;
    }

    public function sortDepths() : Void {
        entityChildren.sort(function(a : Graphic, b : Graphic) : Int {
            return a.depth - b.depth;
        });

        for (e in entityChildren) {
            if (e._currentlyInFathom) {
                e.raiseToTop();
            }
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

    // The reason that we use our own event handlers is that it allows us to
    // selectively update entities - to make them move faster, for instance -
    // just by calling someEntity.update() a lot.
    override public function update() : Void {
        for (e in events) {
            e();
        }

        super.update();
    }

    override public function toString() : String {
        return "[" + Util.className(this) + " " + this.x + " " + this.y + " " + this.groups() + "]";
    }

    // Modes for which this entity receives events.
    public function modes() : Array<Dynamic> {
        return [0];
    }

    public function getAbsX() : Float {
        var p : Entity = this;
        var result : Float = 0;
        while(p != null) {
            result += p.x;
            p = p.parent;
        }

        return result;
    }

    public function getAbsY() : Float {
        var p : Entity = this;
        var result : Float = 0;
        while(p != null) {
            result += p.y;
            p = p.parent;
        }

        return result;
    }

    public function raiseToTop() : Void {
        Util.assert(this.parent != null, "raiseToTop called with no parent.");
        sprite.parent.setChildIndex(sprite, sprite.parent.numChildren - 1);
    }

    public function getParent(): Entity {
        return _parent;
    }

    private function setParent(p: Entity): Entity {
        return _parent = p;
    }
}

