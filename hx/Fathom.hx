#if flash
import starling.core.Starling;
import starling.events.Event;
import starling.display.Sprite;
import flash.display.Stage;
#else
import nme.display.Stage;
import nme.events.Event;
import nme.display.Sprite;
#end

#if profile
import com.sociodox.theminer.TheMiner;
#end

using Lambda;

class Fathom {
    static public var camera(getCamera, never) : Camera;
    static public var paused(getPaused, never) : Bool;
    static public var scaleX(getScaleX, never) : Float;
    static public var scaleY(getScaleY, never) : Float;
    static public var currentMode(getCurrentMode, never) : Int;
    static public var showingFPS(never, setShowingFPS) : Bool;

    static public var sContainer:Sprite;

#if flash
    static public var starling:Starling;
#end
    static public var cb:Void -> Void;

    static var gameloopID : Int;
    static var FPS : Int = 0;
    static var fpsFn : Void -> String;
    static public var _camera : Camera;
    //TODO
    static var _currentMode : Int = 0;
    static public function getCamera() : Camera {
        return _camera;
    }

    static public var mapRef : Map;
    //static public var fpsTxt : Text;
    static public var entities : Set<Entity> = new Set([]);
    static public var container : Entity;
    static public var initialized : Bool = false;
    static public var stage : Stage;
    static public var grid : SpatialHash;
    static public var modes : Array<Int> = [Fathom._currentMode];
    static var _paused : Bool = false;

    public function new() {
        throw ("You can't initialize a Fathom object. Use Fathom.initialize() instead.");
    }

    static public function getPaused() : Bool {
        return _paused;
    }

    static public function getScaleX() : Float {
        return container.scaleX;
    }

    static public function getScaleY() : Float {
        return container.scaleY;
    }

    static public function getCurrentMode() : Int {
        return modes[modes.length - 1];
    }

    // TODO this stuff should go in Mode.as
        static public function pushMode(mode : Int) : Void {
        modes.push(mode);
    }

    static public function popMode() : Void {
        modes.pop();
    }

    static public function replaceMode(mode : Int) : Void {
        modes[modes.length - 1] = mode;
    }

    static public function setShowingFPS(b : Bool) : Bool {
        //fpsTxt.visible = b;
        return b;
    }

    //TODO: Eventually main class should extend this or something...
    static public function initialize(stage : Stage, cb: Void -> Void = null, FPS : Int = 30) : Void {
        // Inside of the Entity constructor, we assert Fathom.initialized, because all
        // MCs must be added to the container MC.

#if flash
        Fathom.starling = new Starling(RootEntity, stage);
    #if profile
        Fathom.starling.showStats = true;
    #end
        Fathom.starling.start();
#end

        Fathom.stage = stage;
        Fathom.initialized = true;
        Fathom.FPS = FPS;
        Fathom.cb = cb;

        MagicKeyObject._initializeKeyInput();
        grid = new SpatialHash(Fathom.entities.select([]));
    }

    static public function start(): Void {
        sContainer.addEventListener(Event.ENTER_FRAME, update);
    }

    static public function destroyAll(): Void {
        Fathom.entities = new Set();
    }

    /* This stops everything. The only conceivable use would be
       possibly for some sort of end game situation. */
    static public function stop() : Void {
        sContainer.removeEventListener(Event.ENTER_FRAME, update);
#if flash
        Fathom.starling.stop();
#end
    }

    static public function anythingAt(x : Int, y : Int) : Bool {
        return grid.getAt(x, y).all([Set.hasGroup("transparent")]);
    }

    // TODO: These should be static functions on MovingEntity.
    // A fast way to find collisions is to subdivide the map into a grid and
    // see if any individual square of the grid contains more than one item in
    // it.
    static function moveEverything() : Void {
        var active: Entity -> Bool = function(e : Entity) : Bool {
            return e.modes().has(currentMode);
        };

        var list : Set<MovingEntity> = movingEntities().filter(active);

        // TODO: Optimization: You shouldn't have to recreate this
        // hash every loop.
        //grid = new SpatialHash(Fathom.entities.select());
        // Move every non-static entity.
        for(e in list) {
            var oldVelX : Float = e.vel.x;
            var oldVelY : Float = e.vel.y;
            var onceThrough : Bool = true;
            e.xColl = new Set<Entity>();
            e.yColl = new Set<Entity>();
            // Resolve 1 px in the x-direction at a time...
            while (onceThrough || oldVelX != 0) {
                // Attempt to resolve as much of dy as possible on every tick.
                while (oldVelY != 0) {
                    var amtY : Float = Util.bind(oldVelY, -1, 1);
                    e.y += amtY;
                    oldVelY -= amtY;
                    if(grid.collides(e))  {
                        var yColliders : Set<Entity> = grid.getColliders(e);
                        e.yColl.extend(yColliders);
                        if(yColliders.any([Set.doesntHaveGroup("non-blocking")]))  {
                            e.y -= amtY;
                            oldVelY += amtY;
                            break;
                        }
                    }
                }

                onceThrough = false;
                var amtX : Float = Util.bind(oldVelX, -1, 1);
                e.x += amtX;
                oldVelX -= amtX;
                if(grid.collides(e))  {
                    var xColliders : Set<Entity> = grid.getColliders(e);
                    e.xColl.extend(xColliders);
                    if(xColliders.any([Set.doesntHaveGroup("non-blocking")]))  {
                        e.x -= amtX;
                    }
                }
            }

            e.x = Math.floor(e.x);
            e.y = Math.floor(e.y);
            e.xColl.extend(grid.getColliders(e));
            e.yColl.extend(grid.getColliders(e));
            e.touchingBottom = (e.yColl.any([Set.doesntHaveGroup("non-blocking")]) && e.vel.y > 0);
            e.touchingTop    = (e.yColl.any([Set.doesntHaveGroup("non-blocking")]) && e.vel.y < 0);
            e.touchingLeft   = (e.xColl.any([Set.doesntHaveGroup("non-blocking")]) && e.vel.x < 0);
            e.touchingRight  = (e.xColl.any([Set.doesntHaveGroup("non-blocking")]) && e.vel.x > 0);
        }
    }

    static function movingEntities() : Set<MovingEntity> {
        return Fathom.entities.select([function(e : Entity) : Bool {
            return !e.isStatic;
        }]).map(function(e: Entity): MovingEntity {
            return cast(e, MovingEntity);
        });
    }

    static function updateFPS() : Void {
        //fpsTxt.text = fpsFn();
    }

    static function update(event : Event) : Void {
        // We copy the entity list so that it doesn't change while we're
        // iterating through it.
        var list : Set<Entity> = entities.clone();
        // Similarly, if something changes the current mode, that shouldn't
        // be reflected until the next update cycle.
        var cachedMode : Int = currentMode;

        updateFPS();
        moveEverything();
        for (e in list) {
            if (!e.modes().has(cachedMode)) {
                continue;
            }

            // This acts as a pseudo garbage-collector. We separate out the
            // destroyed() call from the clearMemory() call because we sometimes
            // want to destroy() an item halfway through this update() call, so the
            // actual destruction would have to wait until the end of the update.
            if (e.destroyed)  {
                e.clearMemory();
                continue;
            }

            e.update();
        }

        Particles.updateAll();

        //TODO: map should just be another Entity.
        if(mapRef != null && mapRef.modes().has(cachedMode))  {
            mapRef.update();
        }

        camera.update();
        MagicKeyObject.dealWithVariableKeyRepeatRates(); //TODO
    }
}

class RootEntity extends Sprite {
    private static var count:Int = 0;

    public function new() {
        if (++count != 1) {
            throw "THERE CAN ONLY BE ONE.";
        }

        super();

        Fathom.sContainer = this;

        Fathom.container = Entity.fromDO(this).addGroup("container");

        // Can't initialize the Cam until the container is initialized...
        Fathom._camera = new Camera(Fathom.stage).scaleBy(1).setEaseSpeed(3);
        Fathom.start();
        Fathom.cb();

#if profile
        flash.Lib.current.addChild(new TheMiner());
#end
    }
}