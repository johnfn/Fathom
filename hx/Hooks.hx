import flash.display.Sprite;
import flash.geom.Point;

class Hooks {

    static public function move(who:Rect, direction : Vec) : Void -> Void {
        return function() : Void {
            who.add(direction);
        };
    }

    //TODO...
  static public function after(time : Int, cb : Void -> Dynamic) : Void -> Dynamic {
        var timeLeft : Int = time;
        return function() : Void {
            if(timeLeft-- == 0)  {
                cb();
            }
        };
    }

    //TODO...
        static public function entityDestroyed(e : Entity, cb : Void -> Void) : Void -> Void {
        var sentCallback : Bool = false;
        return function() : Void {
            if(!sentCallback)  {
                cb();
                sentCallback = true;
            }
        };
    }

    //TODO: Not a Hook.
        static public function hasLeftMap(who : Entity, map : Map) : Bool {
        if(who.x < 0 || who.y < 0 || who.x > map.width - who.width || who.y > map.height - who.width)  {
            return true;
        }
        return false;
    }

    //TODO: onxxxx methods could be moved into an Events.as file.
    static public function onLeaveMap(who : Entity, map : Map, cb : Entity -> Void) : Void {
        if(who.x < 0 || who.y < 0 || who.x > map.width - who.width || who.y > map.height - who.width)  {
            cb(who);
        }
    }

    static public function loadNewMap(leftScreen : MovingEntity, map : Map) : Void -> Void {
        //TODO: This code is pretty obscure.
        //TODO: This will only work if leftScreen.width is less than the tileSize.
        //TODO: This should obviously be in Map, not Hooks.
        return function() : Void {
            Util.assert(leftScreen.width < map.tileSize);
            var smallerSize : Vec = map.sizeVector.clone().subtract(leftScreen.width);
            var dir : Vec = leftScreen.vec().divide(smallerSize).map(Math.floor);
            var toOtherSide : Vec = dir.clone().multiply(smallerSize);
            if(toOtherSide.x > 0)
                leftScreen.x = 1;
            if(toOtherSide.x < 0)
                leftScreen.x = map.sizeVector.x - map.tileSize + 1;
            if(toOtherSide.y > 0)
                leftScreen.y = 1;
            if(toOtherSide.y < 0)
                leftScreen.y = map.sizeVector.y - map.tileSize + 1;
            map.loadNewMap(dir);
        }
    }

    static public function rpgLike(e:MovingEntity, speed : Int) : Void -> Void {
        return function() : Void {
            e.vel.add(Util.movementVector().multiply(speed));
        }
    }

    static public function removeUnnecessaryVelocity(entity : MovingEntity) : Void {
        if(entity.touchingRight)
            entity.vel.x = Math.min(entity.vel.x, 0);
        if(entity.touchingLeft)
            entity.vel.x = Math.max(entity.vel.x, 0);
        if(entity.touchingTop)
            entity.vel.y = Math.max(entity.vel.y, 0);
        if(entity.touchingBottom)
            entity.vel.y = Math.min(entity.vel.y, 0);
    }

    static public function flicker(who : Entity, duration : Int = 20, cb : Void -> Void = null) : Void -> Void {
        var counter : Int = 0;
        var fn: Void -> Void = null;

        who.isFlickering = true;
        fn = function() : Void {
            counter++;
            who.visible = (Math.floor(counter / 3) % 2 == 0);
            if(counter > duration)  {
                who.isFlickering = false;
                who.visible = true;
                who.unlisten(fn);
                if(cb != null)
                    cb();
            }
        }
        return fn;
    }

    static public function decel(e:MovingEntity, decel : Float = 2.0) : Void -> Void {
        var truncate : Float -> Float = function(val : Float) : Float {
            if(Math.abs(val) <= decel)
                return 0;
            return val;
        };

        return function() : Void {
            e.vel.map(truncate).addAwayFromZero(-decel, -decel);
        };
    }

    static public function truncate(e:MovingEntity) : Void -> Void {
        var cutoff : Float = 0.4;
        var lowCutoff : Float = 20;
        var cutoffFn : Float -> Float = function(val : Float) : Float {
            if(Math.abs(val) < cutoff)  {
                return 0;
            }
            if(Math.abs(val) > lowCutoff)
                return Util.sign(val) * lowCutoff;
            //TODO: This hides a problem where falling velocity gets too large.
            return val;
        };

        return function() : Void {
            e.vel.map(cutoffFn);
        };
    }


    public function new() {
    }
}

