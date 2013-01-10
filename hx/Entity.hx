import Util;
#if nme
import nme.display.BitmapData;
import nme.display.DisplayObjectContainer;
import nme.display.DisplayObject;
import nme.display.Sprite;
#else
import flash.display.BitmapData;
import starling.display.DisplayObjectContainer;
import starling.display.Sprite;
import starling.display.DisplayObject;
#end

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

    public var inFathom(getInFathom, setInFathom): Bool;

    public function getIsStatic() : Bool {
        return _isStatic;
    }

    function setIsStatic(val : Bool) : Bool {
        _isStatic = val;
        return val;
    }

    public function getInFathom(): Bool {
        return _currentlyInFathom;
    }

    private function setInFathom(v: Bool): Bool {
        return _currentlyInFathom = v;
    }

    public function new(x : Float = 0, y : Float = 0, width : Float = -1, height : Float = -1, d:DisplayObjectContainer = null) {
        if(!Fathom.initialized)  {
            throw "Fathom.initialize() has not been called. Failing.";
        }

        entityChildren = [];
        events = [];
        isFlickering = false;
        destroyed = false;
        uid = ++counter;
        _isStatic = true;
        groupSet = new Set(["persistent"]);
        super();
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;

        if (d != null) {
            this.sprite = d;
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

    public static function fromDO(d:DisplayObjectContainer):Entity {
        return new Entity(0, 0, 20, 20, d);
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
        /*
        sprite.graphics.beginFill(0xFF0000);
        sprite.graphics.drawRect(0, 0, this.width, this.height);
        sprite.graphics.endFill();
        */
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

    public override function addChild(child : DisplayObject) : DisplayObject {
        Util.assert(entityChildren != null, "You need to call super() before addChild().");
        if (Std.is(child, Entity)) {
            Util.assert(!entityChildren.has(cast(child, Entity)), "Already has that child.");
            entityChildren.push(cast(child, Entity));
        }

        return super.addChild(child);
    }

    /**
     * Remove child: The child entity does not belong to this entity as a child.
     * It continues to exist in the game.
     *
     * Note: removeChild has an optional `dispose` parameter if you're using flash.
     * This is because starling.display.Sprite#removeChild has this parameter. Since
     * nme.display.Sprite does *not* have this parameter, it is highly recommended not
     * to use it - you're just going to break cross platform compatibility. I can't get
     * rid of it completely because I have to override the removeChild function.
     */
    public override function removeChild(child : DisplayObject #if flash , dispose: Bool = false #end) : DisplayObject {
        if(Std.is(child, Entity)) {
            Util.assert(entityChildren.has(cast(child, Entity)), "Doesn't have that child.");
            entityChildren.remove(cast(child, Entity));
        }

        return super.removeChild(child #if flash , dispose #end);
    }

    /* This makes the entity disappear, but stay in memory. Think of a
       moveable block that you saw on another screen. You only need to call
       it on the parent object, not the children. */
    public function removeFromFathom() : Void {
        Util.assert(!destroyed, "Entity was destroyed.");
        Util.assert(Fathom.entities.has(this), "Removed but not in Fathom.");

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
        Util.assert(!Fathom.entities.has(this), "Added but already in Fathom.");

        for (ch in entityChildren) {
            ch.addToFathom();
        }

        this.visible = true;
        Fathom.entities.add(this);
        _currentlyInFathom = true;
    }

    /* This flags an Entity to be removed permanently. It can't be add()ed back. */
    public function destroy() : Void {
        Util.assert(Fathom.entities.has(this), "That entity is not in Fathom.");
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

    // We do some casting so you don't have to.
    public override function loadSpritesheet(spritesheetClass: BitmapData, tileDimension : Vec = null, whichTile : Vec = null) : Entity {
        return cast(super.loadSpritesheet(spritesheetClass, tileDimension, whichTile), Entity);
    }

#if cpp
    public override function loadHotSwapImage(path: String) {
        return cast(super.loadHotSwapImage(path), Entity);
    }
#end

    public override function setTile(x : Int, y : Int) : Entity {
        return cast(super.setTile(x, y), Entity);
    }

    public override function setPos(v : IPositionable) : Entity {
        return cast(super.setPos(v), Entity);
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

    public function collidesPt(point : Vec) : Bool {
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
    public function modes() : Array<Int> {
        return [0];
    }

    public function getAbsX() : Float {
        var p : DisplayObjectContainer = this;
        var result : Float = 0;
        while(p != null) {
            result += p.x;
            p = p.parent;
        }

        return result;
    }

    public function getAbsY() : Float {
        var p : DisplayObjectContainer = this;
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
}

