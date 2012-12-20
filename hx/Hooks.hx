import flash.display.Sprite;
import flash.geom.Point;

class Hooks {

	static public function move(direction : Vec) : Function {
		return function() : Void {
			this.add(direction);
		}
;
	}

	//TODO...
		static public function after(time : Int, callback : Function) : Function {
		var timeLeft : Int = time;
		return function() : Void {
			if(timeLeft-- == 0)  {
				callback();
			}
		}
;
	}

	//TODO...
		static public function entityDestroyed(e : Entity, callback : Function) : Function {
		var sentCallback : Bool = false;
		return function() : Void {
			if(!sentCallback)  {
				callback();
				sentCallback = true;
			}
		}
;
	}

	//TODO: Not a Hook.
		static public function hasLeftMap(who : Entity, map : Map) : Bool {
		if(who.absX < 0 || who.absY < 0 || who.absX > map.width - who.width || who.absY > map.height - who.width)  {
			return true;
		}
		return false;
	}

	//TODO: onxxxx methods could be moved into an Events.as file.
		static public function onLeaveMap(who : Entity, map : Map, callback : Function) : Void {
		if(who.x < 0 || who.y < 0 || who.x > map.width - who.width || who.y > map.height - who.width)  {
			callback.call(who);
		}
	}

	static public function loadNewMap(leftScreen : MovingEntity, map : Map) : Function {
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
;
	}

	static public function rpgLike(speed : Int) : Function {
		return function() : Void {
			this.vel.add(Util.movementVector().multiply(speed));
			this.add(this.vel);
		}
;
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

	static public function fpsCounter() : Function {
		// With thanks to http://kaioa.com/node/83
		var last : UInt = Math.round(haxe.Timer.getStamp() / 1000)();
		var ticks : UInt = 0;
		var text : String = "--.- FPS";
		return (function() : String {
			var now : UInt = Math.round(haxe.Timer.getStamp() / 1000)();
			var delta : UInt = now - last;
			ticks++;
			if(delta >= 1000)  {
				var fps : Float = ticks / delta * 1000;
				text = fps.toFixed(1) + " FPS";
				ticks = 0;
				last = now;
			}
			return text;
		}
);
	}

	static public function flicker(who : Entity, duration : Int = 20, callback : Function = null) : Function {
		var counter : Int = 0;
		who.isFlickering = true;
		var fn : Function = function() : Void {
			counter++;
			who.visible = (Math.floor(counter / 3) % 2 == 0);
			if(counter > duration)  {
				who.isFlickering = false;
				who.visible = true;
				who.unlisten(fn);
				if(callback != null) 
					callback();
			}
		}
;
		return fn;
	}

	static public function decel(decel : Float = 2.0) : Function {
		var truncate : Function = function(val : Float) : Float {
			if(Math.abs(val) <= decel) 
				return 0;
			return val;
		}
;
		return function() : Void {
			this.vel.map(truncate).addAwayFromZero(-decel, -decel);
		}
;
	}

	static public function truncate() : Function {
		var cutoff : Float = 0.4;
		var lowCutoff : Float = 20;
		var cutoffFn : Function = function(val : Float) : Float {
			if(Math.abs(val) < cutoff)  {
				return 0;
			}
			if(Math.abs(val) > lowCutoff) 
				return Util.sign(val) * lowCutoff;
			//TODO: This hides a problem where falling velocity gets too large.
			return val;
		}
;
		return function() : Void {
			this.vel.map(cutoffFn);
		}
;
	}


	public function new() {
	}
}

