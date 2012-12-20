package {
	// AnimationHandler takes care of animating Graphics. You add animations
	// with addAnimations(), turn one on with play(), and advance() will
	// take care of the rest.

	public class AnimationHandler {
		private var animations:Object = {};

		private var currentAnimation:String = "";
		private var currentFrame:int = 0;
		private var currentTick:int = 0;

		private var _ticksPerFrame:int = 6;
		private var gfx:Graphic;
		private var andThenFn:Function = null;

		function AnimationHandler(s:Graphic) {
			currentAnimation = "default";
			this.gfx = s;
		}

		public function set ticksPerFrame(val:int):void {
			_ticksPerFrame = val;
		}

		// We assume that you hold y is constant, with numFrames frames starting at x.

		public function addAnimation(name:String, frameX:int, frameY:int, numFrames:int):void {
			var frames:Array = [];

			for (var i:int = 0; i < numFrames; i++) {
				frames.push([frameX + i, frameY]);
			}

			animations[name] = frames;
		}

		public function toString():String {
			return "[Animation " + currentAnimation + " " + currentFrame + "]";
		}

		// Stops all animations and resets all counters.

		public function stop():void {
			currentAnimation = "";
			currentFrame = 0;
			currentTick = 0;
			andThenFn = null;
		}

		// In case addAnimation() isn't good enough, you can just use an array
		// to specify x positions of frames.

		public function addAnimationArray(name:String, frames:Array, frameY:int):void {
			var framesWithY:Array = [];

			for (var i:int = 0; i < frames.length; i++) {
				framesWithY.push([frames[i], frameY]);
			}

			animations[name] = framesWithY;
		}

		// In case you don't want to hold y constant, you can specify the x and y coordinate of
		// each frame.

		// addAnimationXY("walk", [[0, 0], [0, 1], [0, 2]]);
		public function addAnimationXY(name:String, frames:Array):void {
			animations[name] = frames;
		}

		public function deleteAnimation(name:String):void {
			delete animations[name];
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

		public function addAnimations(animationList:Object):void {
	        for (var animName:String in animationList) {
		        var val:Object = animationList[animName];
		        var frames:Array = [];
		        var y:int;

		        if (val["startPos"]) {
		          addAnimation(animName, val["startPos"][0], val["startPos"][1], val["numFrames"]);
		        } else {
		          addAnimationArray(animName, val["array"], val["y"]);
		        }
	        }
		}

		public function advance():void {
			if (!hasAnyAnimations()) {
				return;
			}

			var lastFrame:int = currentFrame;
			var callback:Boolean = false; // TODO: When/if I do issue #9, I should remove this.

			++currentTick;

			if (currentTick > _ticksPerFrame) {
				++currentFrame;
				currentTick = 0;

				if (currentFrame >= animations[currentAnimation].length) {
					currentFrame = 0;

					if (andThenFn != null) {
						andThenFn();

						callback = true;
						andThenFn = null;
					}
				}
			}

			// Update tile if necessary.

			if (lastFrame != currentFrame && !callback) {
				this.gfx.setTile(animations[currentAnimation][currentFrame][0], animations[currentAnimation][currentFrame][1]);
			}
		}

		private function hasAnyAnimations():Boolean {
			for (var i:String in animations) {
				return true;
			}

			return false;
		}

		public function hasAnimation(name:String):Boolean {
			return (name in animations);
		}

		public function play(name:String):AnimationHandler {
			if (currentAnimation != name) {
				currentAnimation = name;
				currentTick = 0;
				currentFrame  = 0;
			}

			return this;
		}

		// Returns true if it's on the final frame of the animation, false otherwise.
		public function lastFrame():Boolean {
			return currentFrame == animations[currentAnimation].length - 1 &&
			       currentTick  == _ticksPerFrame - 1;
		}

		// Plays the animation, starting offsetInTicks ticks ahead of the
		// beginning of the animation.

		public function playWithOffset(name:String, offsetInTicks:int):AnimationHandler {
			play(name);

			currentFrame = Math.floor(offsetInTicks / _ticksPerFrame);
			currentTick = offsetInTicks % _ticksPerFrame;

			return this;
		}

		/* Typical usage of this function looks like this:

			   animations.play("die").andThen(this.destroy);

 	    */
		public function andThen(f:Function):AnimationHandler {
			this.andThenFn = f;

			return this;
		}

		public function getAnimationFrame():int {
			return currentFrame;
		}
	}
}