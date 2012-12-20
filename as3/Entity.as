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

  public class Entity extends Graphic {
    private var events:Object = {};

    public var isFlickering:Boolean = false;

    // This indicates that the object should be destroyed.
    // The update loop in Fathom will eventually destroy it.
    public var destroyed:Boolean = false;

    // These are purely for debugging purposes.
    protected static var counter:int = 0;
    protected var uid:Number = ++counter;

    protected var rememberedParent:DisplayObjectContainer;

    // Allows for a fast check to see if this entity moves.
    protected var _isStatic:Boolean = true;

    public function get isStatic():Boolean { return _isStatic; }
    private function set isStatic(val:Boolean):void { _isStatic = val; }

    function Entity(x:Number = 0, y:Number = 0, width:Number = -1, height:Number = -1):void {
      super(x, y, width, height);

      if (!Fathom.initialized) {
        throw new Error("Util.initialize() has not been called. Failing.");
      }

      //TODO: I had this idea about how parents should bubble down events to children.

      // All Entities are added to the container, except the container itself, which
      // has to be bootstrapped onto the Stage. If Fathom.container does not exist, `this`
      // must be the container.

      if (Fathom.container) {
        this.rememberedParent = Fathom.container;
        addToFathom();
      }
   }

    public function withDepth(d:int):Entity {
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

    public function listen(f:Function):Entity {
      this.addEventListener(Event.ENTER_FRAME, f);

      return this;
    }

    public function unlisten(f:Function):Entity {
      this.removeEventListener(Event.ENTER_FRAME, f);

      return this;
    }

    public function debugDraw():Entity {
      graphics.beginFill(0xFF0000);
      graphics.drawRect(0, 0, this.width, this.height);
      graphics.endFill();

      return this;
    }

    public function disappearAfter(frames:int):Entity {
      var timeLeft:int = frames;
      var that:Entity = this;

      listen(function():void {
        if (timeLeft-- == 0) {
          that.destroy();
        }
      });

      return this;
    }

    /* Put this entity in the middle of the screen. Useful for dialogs,
       inventory screens, etc. */
    public function centerOnScreen():void {
      x = Fathom.stage.width / 2 - this.width / 2;
      y = Fathom.stage.height / 2 - this.height / 2;
    }

    public override function addChild(child:DisplayObject):DisplayObject {
      if (!entityChildren) throw new Error("You need to call super() before addChild().")
      Util.assert(!entityChildren.contains(child));

      super.addChild(child);

      if (child is Entity) {
        entityChildren.push(child);
      }

      return child;
    }

    // Remove child: The child entity does not belong to this entity as a child.
    // It continues to exist in the game.
    public override function removeChild(child:DisplayObject):DisplayObject {
      if (child is Entity) Util.assert(entityChildren.contains(child));

      entityChildren.remove(child);

      super.removeChild(child);

      return child;
    }

    /* This causes the Entity to cease existing in-game. The only way to
       bring it back is to call addToFathom(). */
    public function removeFromFathom(recursing:Boolean = false):void {
      Util.assert(this.parent != null);

      if (!Fathom.entities.contains(this)) {
        trace(this, " removed but not in Fathom.")
        Util.assert(false);
      }

      this.rememberedParent = this.parent;

      for (var i:int = 0; i < entityChildren.length; i++){
        entityChildren[i].removeFromFathom(true);
      }

      if (!recursing && this.parent) this.parent.removeChild(this);

      Fathom.entities.remove(this);
    }

    /* This causes the Entity to exist in the game. There is no need to call
       this except after a call to removeFromFathom(). */
    public function addToFathom(recursing:Boolean = false):void {
      Util.assert(!destroyed);
      Util.assert(!this.parent);

      if (!recursing) rememberedParent.addChild(this);

      Fathom.entities.add(this);

      Util.assert(rememberedParent != null);
    }

    /* This flags an Entity to be removed permanently. It can't be add()ed back. */
    public function destroy():void {
      Util.assert(Fathom.entities.contains(this));

      destroyed = true;
    }

    //TODO: Does not entirely clear memory.

    // If an entity is flagged for removal with destroy(), clearMemory() will eventually
    // be called on it.
    public function clearMemory():void {
      removeFromFathom();

      events = null;

      destroyed = true;
    }

    public function addGroups(...args):Entity {
      groupSet.extend(new Set(args));

      return this;
    }

    public function sortDepths():void {
      entityChildren.sort(function(a:Entity, b:Entity):int {
        return a.depth - b.depth;
      });

      for (var i:int = 0; i < entityChildren.length; i++) {
        entityChildren[i].raiseToTop();
      }
    }

    //TODO: Group strings to enums with Inheritable property.
    //TODO: There is a possible namespace collision here. assert no 2 groups have same name.
    //TODO: Enumerations are better.
    public function groups():Set {
      return groupSet.concat(Util.className(this));
    }

    public function touchingRect(rect:Entity):Boolean {
      return     (rect.x      < this.x + this.width  &&
         rect.x + rect.width  > this.x               &&
         rect.y               < this.y + this.height &&
         rect.y + rect.height > this.y               );
    }

    public function collides(other:Entity):Boolean {
      return (!(this == other)) && touchingRect(other);
    }

    public function collidesPt(point:Point):Boolean {
      return hitTestPoint(point.x, point.y);
    }

    public override function update(e:EntitySet):void {
      super.update(e);
    }

    public override function toString():String {
      return "[" + Util.className(this) + " " + this.x + " " + this.y + " " + this.groups() + "]"
    }


    // Modes for which this entity receives events.
    public function modes():Array { return [0]; }
  }
}
