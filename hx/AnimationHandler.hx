import flash.utils.TypedDictionary;
using Lambda;

// AnimationHandler takes care of animating Graphics. You add animations
// with addAnimations(), turn one on with play(), and advance() will
// take care of the rest.
class AnimationHandler {
	public var ticksPerFrame(never, setTicksPerFrame) : Int;

	var animations : TypedDictionary<String, Array<Dynamic>>;
	var currentAnimation : String;
	var currentFrame : Int;
	var currentTick : Int;
	var _ticksPerFrame : Int;
	var gfx : Graphic;
	var andThenFn: Void -> Void;

	public function new(s : Graphic) {
		animations = new TypedDictionary();
		currentAnimation = "";
		currentFrame = 0;
		currentTick = 0;
		_ticksPerFrame = 6;
		andThenFn = null;
		currentAnimation = "default";
		this.gfx = s;
	}

	public function setTicksPerFrame(val : Int) : Int {
		_ticksPerFrame = val;
		return val;
	}

	// We assume that you hold y is constant, with numFrames frames starting at x.
		public function addAnimation(name : String, frameX : Int, frameY : Int, numFrames : Int) : Void {
		var frames : Array<Dynamic> = [];
		var i : Int = 0;
		while(i < numFrames) {
			frames.push([frameX + i, frameY]);
			i++;
		}
		animations.set(name, frames);
	}

	public function toString() : String {
		return "[Animation " + currentAnimation + " " + currentFrame + "]";
	}

	// Stops all animations and resets all counters.
		public function stop() : Void {
		currentAnimation = "";
		currentFrame = 0;
		currentTick = 0;
		andThenFn = null;
	}

	// In case addAnimation() isn't good enough, you can just use an array
		// to specify x positions of frames.
		public function addAnimationArray(name : String, frames : Array<Dynamic>, frameY : Int) : Void {
		var framesWithY : Array<Dynamic> = [];
		var i : Int = 0;
		while(i < frames.length) {
			framesWithY.push([frames[i], frameY]);
			i++;
		}
		animations.set(name, framesWithY);
	}

	// In case you don't want to hold y constant, you can specify the x and y coordinate of
		// each frame.
		// addAnimationXY("walk", [[0, 0], [0, 1], [0, 2]]);
	public function addAnimationXY(name : String, frames : Array<Dynamic>) : Void {
		animations.set(name, frames);
	}

	public function deleteAnimation(name : String) : Void {
		animations.delete(name);
	}

	/* Convenient function for adding many animations simultaneously.

	    addAnimations({ "walk": {startPos: [0, 0], numFrames: 4 }
	                  , "die" : {startPos: [4, 0], numFrames: 4 }
	                  , "hurt": {array: [1, 3, 5], y: 0}
	                  });

	    "start" is the starting x and y position of the animation on the tilesheet.
	    "numFrames" is the length of the animation.

	    You can alternatively specify an array and a y value.
	    */
    public function addAnimations(animationList : Dynamic) : Void {
		for(animName in Reflect.fields(animationList)) {
			var val : Dynamic = Reflect.field(animationList, animName);
			var frames : Array<Dynamic> = [];
			var y : Int;

			if(Reflect.field(val, "startPos"))  {
				addAnimation(animName, Reflect.field(val, "startPos")[0], Reflect.field(val, "startPos")[1], Reflect.field(val, "numFrames"));
			} else  {
				addAnimationArray(animName, Reflect.field(val, "array"), Reflect.field(val, "y"));
			}

		}

	}

	public function advance() : Void {
		if(!hasAnyAnimations())  {
			return;
		}
		var lastFrame : Int = currentFrame;
		var cb : Bool = false;

		// TODO: When/if I do issue #9, I should remove this.
		++currentTick;
		if(currentTick > _ticksPerFrame)  {
			++currentFrame;
			currentTick = 0;
			if(currentFrame >= animations.get(currentAnimation).length)  {
				currentFrame = 0;
				if(andThenFn != null)  {
					andThenFn();
					cb = true;
					andThenFn = null;
				}
			}
		}
		// Update tile if necessary.
		if(lastFrame != currentFrame && !cb)  {
			this.gfx.setTile(animations.get(currentAnimation)[currentFrame][0], animations.get(currentAnimation)[currentFrame][1]);
		}
;
	}

	function hasAnyAnimations() : Bool {
		for(i in animations) {
			return true;
		}

		return false;
	}

	public function hasAnimation(name : String) : Bool {
		return animations.has(name);
	}

	public function play(name : String) : AnimationHandler {
		if(currentAnimation != name)  {
			currentAnimation = name;
			currentTick = 0;
			currentFrame = 0;
		}
		return this;
	}

	// Returns true if it's on the final frame of the animation, false otherwise.
		public function lastFrame() : Bool {
		return currentFrame == animations.get(currentAnimation).length - 1 && currentTick == _ticksPerFrame - 1;
	}

	// Plays the animation, starting offsetInTicks ticks ahead of the
		// beginning of the animation.
		public function playWithOffset(name : String, offsetInTicks : Int) : AnimationHandler {
		play(name);
		currentFrame = Math.floor(offsetInTicks / _ticksPerFrame);
		currentTick = offsetInTicks % _ticksPerFrame;
		return this;
	}

	/* Typical usage of this function looks like this:

	   animations.play("die").andThen(this.destroy);

 	    */
 	   public function andThen(f) : AnimationHandler {
		this.andThenFn = f;
		return this;
	}

	public function getAnimationFrame() : Int {
		return currentFrame;
	}

}

