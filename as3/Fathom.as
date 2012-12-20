package {
  public class Fathom {
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.display.MovieClip;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.utils.Dictionary;

    private static var gameloopID:int;
    private static var FPS:int = 0;
    private static var fpsFn:Function;
    public static var _camera:Camera; //TODO

    private static var _currentMode:int = 0;

    public static function get camera():Camera { return _camera; }

    public static var mapRef:Map;
    public static var fpsTxt:Text;
    public static var entities:EntitySet = new EntitySet([]);
    public static var container:Entity;
    public static var initialized:Boolean = false;
    public static var stage:Stage;

    public static var grid:SpatialHash;

    public static var modes:Array = [Fathom._currentMode];

    private static var _paused:Boolean = false;

    public static var MCPool:Object = {};

    public function Fathom() {
      throw ("You can't initialize a Fathom object. Call the static methods on Fathom instead.")
    }

    public static function get paused():Boolean { return _paused; }

    public static function get scaleX():Number {
      return container.scaleX;
    }

    public static function get scaleY():Number {
      return container.scaleY;
    }

    public static function get currentMode():int {
      return modes[modes.length - 1]
    }

    // TODO this stuff should go in Mode.as
    public static function pushMode(mode:int):void {
      modes.push(mode);
    }

    public static function popMode():void {
      modes.pop();
    }

    public static function replaceMode(mode:int):void {
      modes[modes.length - 1] = mode;
    }

    public static function set showingFPS(b:Boolean):void {
      fpsTxt.visible = b;
    }

    //TODO: Eventually main class should extend this or something...
    public static function initialize(stage:Stage, FPS:int = 30):void {
      // Inside of the Entity constructor, we assert Fathom.initialized, because all
      // MCs must be added to the container MC.

      Fathom.stage = stage;
      Fathom.initialized = true;

      Fathom.FPS = FPS;

      Fathom.container = new Entity();
      Fathom.stage.addChild(Fathom.container);

      Fathom._camera = new Camera(stage).scaleBy(1).setEaseSpeed(3);

      fpsFn = Hooks.fpsCounter();
      fpsTxt = new Text();
      fpsTxt.addGroups("no-camera", "non-blocking");
      fpsTxt.setPos(new Vec(200, 20));
      fpsTxt.width = 200;
      //fpsTxt.visible = false;

      MagicKeyObject._initializeKeyInput(container);

      grid = new SpatialHash(Fathom.entities.select());
    }

    public static function start():void {
      container.addEventListener(Event.ENTER_FRAME, update);
    }

    /* This stops everything. The only conceivable use would be
       possibly for some sort of end game situation. */
    public static function stop():void {
      container.removeEventListener(Event.ENTER_FRAME, update);
    }

    public static function anythingAt(x:int, y:int):Boolean {
      return grid.getAt(x, y).all("transparent");
    }

    // TODO: These should be static functions on MovingEntity.

    // A fast way to find collisions is to subdivide the map into a grid and
    // see if any individual square of the grid contains more than one item in
    // it.
    private static function moveEverything():void {
      var list:Set = movingEntities().filter(function(e:MovingEntity):Boolean { return e.modes().contains(currentMode); });
      // TODO: Optimization: You shouldn't have to recreate this
      // hash every loop.
      //grid = new SpatialHash(Fathom.entities.select());

      // Move every non-static entity.
      for each (var e:MovingEntity in list) {
        var oldVelX:Number = e.vel.x;
        var oldVelY:Number = e.vel.y;
        var onceThrough:Boolean = true;

        e.xColl = new EntitySet();
        e.yColl = new EntitySet();

        // Resolve 1 px in the x-direction at a time...
        for (; onceThrough || oldVelX != 0;) {
          // Attempt to resolve as much of dy as possible on every tick.
          for (; oldVelY != 0;) {
            var amtY:Number = Util.bind(oldVelY, -1, 1);

            e.y += amtY;
            oldVelY -= amtY;

            if (grid.collides(e)) {
              var yColliders:EntitySet = grid.getColliders(e);

              trace(yColliders.length);

              e.yColl.extend(yColliders);

              if (yColliders.any("!non-blocking")) {
                e.y -= amtY;
                oldVelY += amtY;
                break;
              }
            }
          }

          onceThrough = false;

          var amtX:Number = Util.bind(oldVelX, -1, 1);

          e.x += amtX;
          oldVelX -= amtX;
          if (grid.collides(e)) {
            var xColliders:EntitySet = grid.getColliders(e);

            e.xColl.extend(xColliders);

            if (xColliders.any("!non-blocking")) {
              e.x -= amtX;
            }
          }
        }

        e.x = Math.floor(e.x);
        e.y = Math.floor(e.y);

        e.xColl.extend(grid.getColliders(e));
        e.yColl.extend(grid.getColliders(e));

        e.touchingBottom = (e.yColl.any("!non-blocking") && e.vel.y > 0);
        e.touchingTop    = (e.yColl.any("!non-blocking") && e.vel.y < 0);

        e.touchingLeft   = (e.xColl.any("!non-blocking") && e.vel.x < 0);
        e.touchingRight  = (e.xColl.any("!non-blocking") && e.vel.x > 0);
      }
    }

    private static function movingEntities():EntitySet {
      return Fathom.entities.select(function(e:Entity):Boolean {
        return !e.isStatic;
      });
    }

    private static function updateFPS():void {
      fpsTxt.text = fpsFn();
      //trace(fpsTxt.text);
    }

    private static function update(event:Event):void {
      // We copy the entity list so that it doesn't change while we're
      // iterating through it.
      var list:EntitySet = entities.select();

      // Similarly, if something changes the current mode, that shouldn't
      // be reflected until the next update cycle.
      var cachedMode:int = currentMode;

      updateFPS();
      moveEverything();

      for each (var e:Entity in list) {
        if (!e.modes().contains(cachedMode)) continue;

        // This acts as a pseudo garbage-collector. We separate out the
        // destroyed() call from the clearMemory() call because we sometimes
        // want to destroy() an item halfway through this update() call, so the
        // actual destruction would have to wait until the end of the update.
        if (e.destroyed) {
          e.clearMemory();
          continue;
        }

        e.update(entities);
      }

      Particles.updateAll();

      if (mapRef.modes().contains(cachedMode)) {
        mapRef.update();
      }

      camera.update();
      MagicKeyObject.dealWithVariableKeyRepeatRates();
    }
  }
}

