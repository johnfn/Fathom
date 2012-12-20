package {
  import flash.display.Sprite;
  import flash.geom.Point;
  import flash.utils.getTimer;

  public class Hooks {
    public static function move(direction:Vec):Function {
      return function():void {
        this.add(direction);
      }
    }

    //TODO...
    public static function after(time:int, callback:Function):Function {
      var timeLeft:int = time;

      return function():void {
        if (!timeLeft--) {
          callback();
        }
      }
    }

    //TODO...
    public static function entityDestroyed(e:Entity, callback:Function):Function {
      var sentCallback:Boolean = false;

      return function():void {
        if (!sentCallback) {
          callback();
          sentCallback = true;
        }
      }
    }

    //TODO: Not a Hook.
    public static function hasLeftMap(who:Entity, map:Map):Boolean {
      if (who.absX < 0 || who.absY < 0 || who.absX > map.width - who.width || who.absY > map.height - who.width) {
        return true;
      }

      return false;
    }

    //TODO: onxxxx methods could be moved into an Events.as file.
    public static function onLeaveMap(who:Entity, map:Map, callback:Function):void {
      if (who.x < 0 || who.y < 0 || who.x > map.width - who.width || who.y > map.height - who.width) {
        callback.call(who);
      }
    }

    public static function loadNewMap(leftScreen:MovingEntity, map:Map):Function {
      //TODO: This code is pretty obscure.
      //TODO: This will only work if leftScreen.width is less than the tileSize.
      //TODO: This should obviously be in Map, not Hooks.

      return function():void {
        Util.assert(leftScreen.width < map.tileSize);

        var smallerSize:Vec = map.sizeVector.clone().subtract(leftScreen.width);

        var dir:Vec = leftScreen.vec().divide(smallerSize).map(Math.floor);
        var toOtherSide:Vec = dir.clone().multiply(smallerSize);

        if (toOtherSide.x > 0) leftScreen.x = 1;
        if (toOtherSide.x < 0) leftScreen.x = map.sizeVector.x - map.tileSize + 1;

        if (toOtherSide.y > 0) leftScreen.y = 1;
        if (toOtherSide.y < 0) leftScreen.y = map.sizeVector.y - map.tileSize + 1;

        map.loadNewMap(dir);
      }
    }

    public static function rpgLike(speed:int):Function {
      return function():void {
        this.vel.add(Util.movementVector().multiply(speed));
        this.add(this.vel);
      }
    }

    public static function removeUnnecessaryVelocity(entity:MovingEntity):void {
      if (entity.touchingRight) entity.vel.x = Math.min(entity.vel.x, 0);
      if (entity.touchingLeft) entity.vel.x = Math.max(entity.vel.x, 0);

      if (entity.touchingTop) entity.vel.y = Math.max(entity.vel.y, 0);
      if (entity.touchingBottom) entity.vel.y = Math.min(entity.vel.y, 0);
    }

    public static function fpsCounter():Function {
      // With thanks to http://kaioa.com/node/83

      var last:uint = getTimer();
      var ticks:uint = 0;
      var text:String = "--.- FPS";

      return (function():String {
        var now:uint = getTimer();
        var delta:uint = now - last;

        ticks++;
        if (delta >= 1000) {
          var fps:Number = ticks / delta * 1000;
          text = fps.toFixed(1) + " FPS";
          ticks = 0;
          last = now;
        }
        return text;
      });
    }

    public static function flicker(who:Entity, duration:int = 20, callback:Function=null):Function {
      var counter:int = 0;
      who.isFlickering = true;

      var fn:Function = function():void {
        counter++;

        who.visible = (Math.floor(counter / 3) % 2 == 0)

        if (counter > duration) {
          who.isFlickering = false;
          who.visible = true;
          who.unlisten(fn);
          if (callback != null) callback();
        }
      }

      return fn;
    }

    public static function decel(decel:Number = 2.0):Function {

      var truncate:Function = function(val:Number):Number {
        if (Math.abs(val) <= decel) return 0;
        return val;
      }

      return function():void {
        this.vel.map(truncate).addAwayFromZero(-decel, -decel);
      }
    }

    public static function truncate():Function {
      var cutoff:Number = 0.4;
      var lowCutoff:Number = 20;

      var cutoffFn:Function = function(val:Number):Number {
        if (Math.abs(val) < cutoff) {
          return 0;
        }

        if (Math.abs(val) > lowCutoff) return Util.sign(val) * lowCutoff; //TODO: This hides a problem where falling velocity gets too large.
        return val;
      }

      return function():void {
        this.vel.map(cutoffFn)//.addAwayFromZero(0.6, 0.0);
      }
    }
  }
}
