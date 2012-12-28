import flash.utils.TypedDictionary;
using Lambda;

//TODO use this...
typedef Pair = {
    var x: Int;
    var y: Int;
}

// AnimationHandler takes care of animating Graphics. You add animations
// with addAnimations(), turn one on with play(), and advance() will
// take care of the rest.
class AnimationHandler {
    public var ticksPerFrame(getTicksPerFrame, setTicksPerFrame) : Int;
    public var currentFrame(getCurrentFrame, never): Int;

    var animations : TypedDictionary<String, Array<Array<Int>>>;
    var currentAnimation : String;
    var _currentFrame : Int;
    var currentTick : Int;
    var _ticksPerFrame : Int;
    var gfx : Graphic;
    var andThenFn: Void -> Void;

    public function new(s : Graphic) {
        animations = new TypedDictionary();
        currentAnimation = "";
        _currentFrame = 0;
        currentTick = 0;
        _ticksPerFrame = 6;
        andThenFn = null;
        this.gfx = s;
    }

    public function setTicksPerFrame(val : Int) : Int {
        _ticksPerFrame = val;
        return val;
    }

    public function getTicksPerFrame(): Int {
        return _ticksPerFrame;
    }

    public function getCurrentFrame(): Int {
        return _currentFrame;
    }

    // We assume that you hold y is constant, with numFrames frames starting at x.
    public function addAnimation(name : String, frameX : Int, frameY : Int, numFrames : Int) : Void {
        var frames : Array<Array<Int>> = [];

        for (i in 0...numFrames) {
            frames.push([frameX + i, frameY]);
        }
        animations.set(name, frames);
    }

    public function toString() : String {
        return "[Animation " + currentAnimation + " " + _currentFrame + "]";
    }

    // Stops all animations and resets all counters.
    public function stop() : Void {
        currentAnimation = "";
        _currentFrame = 0;
        currentTick = 0;
        andThenFn = null;
    }

    // In case addAnimation() isn't good enough, you can just use an array
    // to specify x positions of frames.
    public function addAnimationArray(name : String, frames : Array<Dynamic>, frameY : Int) : Void {
        var framesWithY : Array<Array<Int>> = [];
        for (i in 0...frames.length) {
            framesWithY.push([frames[i], frameY]);
        }
        animations.set(name, framesWithY);
    }

    // In case you don't want to hold y constant, you can specify the x and y coordinate of
    // each frame.
    // addAnimationXY("walk", [[0, 0], [0, 1], [0, 2]]);
    public function addAnimationXY(name : String, frames : Array<Array<Int>>) : Void {
        animations.set(name, frames);
    }

    public function deleteAnimation(name : String) : Void {
        animations.delete(name);
    }

    public function advance() : Void {
        if (!hasAnyAnimations())  {
            return;
        }

        if (!animations.has(currentAnimation)) {
            return;
        }

        var lastFrame : Int = _currentFrame;
        var cb : Bool = false;

        // TODO: When/if I do issue #9, I should remove this.
        ++currentTick;
        if(currentTick >= _ticksPerFrame)  {
            ++_currentFrame;
            currentTick = 0;
            if(_currentFrame >= animations.get(currentAnimation).length)  {
                _currentFrame = 0;
                if(andThenFn != null)  {
                    andThenFn();
                    cb = true;
                    andThenFn = null;
                }
            }
        }

        // Update tile if necessary.
        if(lastFrame != _currentFrame && !cb)  {
            this.gfx.setTile(animations.get(currentAnimation)[_currentFrame][0], animations.get(currentAnimation)[_currentFrame][1]);
        }
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
        Util.assert(animations.has(name), "No animation named " + name);

        if(currentAnimation != name) {
            currentAnimation = name;
            currentTick = 0;
            _currentFrame = 0;
        }

        var anim:Array<Int> = animations.get(currentAnimation)[_currentFrame];

        gfx.setTile(anim[0], anim[1]);
        return this;
    }

    // Returns true if it's on the final frame of the animation, false otherwise.
    public function lastFrame() : Bool {
        return _currentFrame == animations.get(currentAnimation).length - 1 && currentTick == _ticksPerFrame - 1;
    }

    // Plays the animation, starting offsetInTicks ticks ahead of the
        // beginning of the animation.
    public function playWithOffset(name : String, offsetInTicks : Int) : AnimationHandler {
        play(name);
        _currentFrame = Math.floor(offsetInTicks / _ticksPerFrame);
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

}

