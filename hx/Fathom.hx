#if flash
import starling.core.Starling;
import starling.events.Event;
import starling.display.Sprite;
import starling.display.Stage;
import starling.display.DisplayObjectContainer;
#else
import nme.display.Stage;
import nme.events.Event;
import nme.display.Sprite;
import nme.display.DisplayObjectContainer;
#end

#if profile
import com.sociodox.theminer.TheMiner;
#end

using Lambda;

class Fathom {
#if flash
    static public var starling:Starling;
#end

    static public var pixelSnapping: Bool = true;

    static public var rootDir: String;
    static public var mapRef: Map;
    static public var mode: Mode;
    static public var entities: Set<Entity> = new Set([]);
    static public var initialized: Bool = false;
    static public var stage: Entity;
    static public var actualStage: Stage;
    static public var grid: SpatialHash;
    static public var cb:Void -> Void;
    static public var camera: CameraFocus;

    static private var fpsFn : Void -> String;

    public function new() {
        throw ("You can't initialize a Fathom object. Use Fathom.initialize() instead.");
    }

    //TODO: Eventually main class should extend this or something...
    static public function initialize(cb: Void -> Void = null) : Void {
        // Inside of the Entity constructor, we assert Fathom.initialized, because all
        // MCs must be added to the container MC.

        Fathom.initialized = true;
        Fathom.cb = cb;
        Fathom.mode = new Mode();
#if flash
        Fathom.starling = new Starling(RootEntity, flash.Lib.current.stage);
        Fathom.starling.start();
    #if profile
        Fathom.starling.showStats = true;
        flash.Lib.current.addChild(new TheMiner());
    #end
#else
        Fathom._postInitialize();
#end

    }

    static public function _postInitialize(): Void {
#if flash
        Fathom.actualStage = Fathom.starling.stage;
#else
        Fathom.actualStage = nme.Lib.current.stage;
#end
        Fathom.stage = new Entity();
        Fathom.actualStage.addChild(Fathom.stage);
        Fathom.grid = new SpatialHash(Fathom.entities.get([]));

        MagicKeyObject._initializeKeyInput();
        Fathom.start();
        Fathom.camera = new CameraFocus(Fathom.actualStage, Fathom.stage, new Vec(Fathom.actualStage.stageWidth / 2, Fathom.actualStage.stageHeight / 2), []);

        if (cb != null) {
            cb();
        }
    }

    static public function start(): Void {
        Fathom.stage.addEventListener(Event.ENTER_FRAME, update);
    }

    static public function destroyAll(): Void {
        for (f in Fathom.entities) {
            f.removeFromFathom();
        }
    }

    /* This stops everything. The only conceivable use would be
       possibly for some sort of end game situation. */
    static public function stop() : Void {
        Fathom.stage.removeEventListener(Event.ENTER_FRAME, update);
    }

    static public function anythingAt(x : Int, y : Int) : Bool {
        return grid.getAt(x, y).all([Set.hasGroup("transparent")]);
    }

    // TODO: These should be static functions on MovingEntity.
    // A fast way to find collisions is to subdivide the map into a grid and
    // see if any individual square of the grid contains more than one item in
    // it.
    static function moveEverything() : Void {
        var active: Entity -> Bool = function(e: Entity) : Bool {
            return e.modes().has(mode.currentMode);
        };

        var list : Set<MovingEntity> = movingEntities().filter(active);

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
                    var amtY : Float = Util.clamp(oldVelY, -1, 1);
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
                var amtX : Float = Util.clamp(oldVelX, -1, 1);
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
        return Fathom.entities.get([function(e : Entity) : Bool {
            return !e.isStatic;
        }]).map(function(e: Entity): MovingEntity {
            return cast(e, MovingEntity);
        });
    }

    static function update(event : Event) : Void {
        // We copy the entity list so that it doesn't change while we're
        // iterating through it.
        var list : Set<Entity> = entities.clone();
        // Similarly, if something changes the current mode, that shouldn't
        // be reflected until the next update cycle.
        var cachedMode : Int = mode.currentMode;

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

        MagicKeyObject.dealWithVariableKeyRepeatRates(); //TODO
        Fathom.camera.update();
    }
}

#if flash
class RootEntity extends Sprite {
    private static var count:Int = 0;

    public function new() {
        if (++count != 1) {
            throw "THERE CAN ONLY BE ONE.";
        }
        super();

        Fathom._postInitialize();
    }
}
#end