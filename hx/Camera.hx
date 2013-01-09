#if flash
import starling.display.Stage;
#else
import nme.display.Stage;
#end
/*
 *  Entity Space: the coordinates you use 99% of the time.
 *  Camera Space: the coordinates of the sprite, post camera transformations.
 */
class Camera extends Rect {
    public var focalX(getFocalX, setFocalX) : Float;
    public var focalY(getFocalY, setFocalY) : Float;
    public var focalBoundingRect(getFocalBoundingRect, setFocalBoundingRect) : Rect;

    // The larger this number, the longer the camera takes to catch up.
    var CAM_LAG : Int;
    // This is the rect that the camera will always stay inside.
    var camBoundingRect : Rect;
    static var EVENT_TYPE_SHAKE : String = "Shake";
    // This is a list of all events currently happening to this camera.
    var events : Array<Void -> Void>;
    // These two variables are the focal points of the camera.
    var _focalX : Float;
    var _focalY : Float;
    // If our camera lags behing the player, this is where it will eventually want to be.
    var goalFocalX : Float;
    var goalFocalY : Float;
    // If the camera is normalWidth by normalHeight, then no MovieClips will have to be scaled.
    var normalWidth : Float;
    var normalHeight : Float;
    // Rate at which the camera eases. Larger values -> faster easing.
    var easeRate : Int;
    // These dimensions are the default scaled width of the camera. The camera may temporarily adjust
    // itself out of these dimensions, if, say, it's told to keepInScene() an Entity
    // that wandered out of the Camera bounds.
    var scaledWidth : Float;
    var scaledHeight : Float;
    var FOLLOW_MODE_NONE : Int;
    var FOLLOW_MODE_SLIDE : Int;
    var followMode : Int;
    // This just helps us fix a bug we may encounter.
    var isFocused : Bool;
    // The Rect we extend from is the area from the game the camera displays.
    // TODO: This camera does not at all take into consideration non-square
    // dimensions. That would make life a bit harder.
    public function new(stage : Stage) {
        CAM_LAG = 90;
        camBoundingRect = null;
        events = [];
        easeRate = 1;
        FOLLOW_MODE_NONE = 0;
        FOLLOW_MODE_SLIDE = 1;
        followMode = FOLLOW_MODE_NONE;
        isFocused = false;
        Util.assert(stage.stageWidth == stage.stageHeight, "Non-square dimensions not supported for Cam. Sorry :(");

        super(0, 0, stage.stageWidth / Fathom.scaleX, stage.stageHeight / Fathom.scaleY);
        this.normalWidth = this.width;
        this.normalHeight = this.height;
        this.scaledWidth = this.width;
        this.scaledHeight = this.height;
    }

    public function scaleBy(val : Float) : Camera {
        this.width = this.normalWidth * val;
        this.height = this.normalHeight * val;
        this.scaledWidth = this.width;
        this.scaledHeight = this.height;
        if(camBoundingRect != null)  {
            camBoundingRect.x *= val;
            camBoundingRect.y *= val;
            camBoundingRect.width *= val;
            camBoundingRect.height *= val;
        }
        return this;
    }

    public function bind(val : Float, low : Float, high : Float) : Float {
        if(val < low)
            return low;
        if(val > high)
            return high;
        return val;
    }

    public function isBound() : Bool {
        return camBoundingRect != null;
    }

    // Updating the focus updates the x, y coordinates also.
    public function setFocalX(val : Float) : Float {
        _focalX = (isBound()) ? bind(val, focalBoundingRect.x, focalBoundingRect.right) : val;
        _x = _focalX - width / 2;
        return val;
    }

    public function getFocalX() : Float {
        return _x + width / 2;
    }

    public function setFocalY(val : Float) : Float {
        _focalY = (isBound()) ? bind(val, focalBoundingRect.y, focalBoundingRect.bottom) : val;
        _y = _focalY - height / 2;
        return val;
    }

    public function getFocalY() : Float {
        return _y + height / 2;
    }

    // We have to ensure that setting these properties does not cause the camera to
    // exceed its bounding box.
    override public function setX(val : Float) : Float {
        _x = (isBound()) ? bind(val, camBoundingRect.x, camBoundingRect.right) : val;
        return val;
    }

    override public function setY(val : Float) : Float {
        _y = (isBound()) ? bind(val, camBoundingRect.y, camBoundingRect.bottom) : val;
        return val;
    }

    override public function setWidth(val : Float) : Float {
        _width = (isBound()) ? bind(_x + val, camBoundingRect.x, camBoundingRect.right) - _x : val;
        return val;
    }

    override public function setHeight(val : Float) : Float {
        _height = (isBound()) ? bind(_y + val, camBoundingRect.y, camBoundingRect.bottom) - _y : val;
        return val;
    }

    override public function getRight() : Float {
        return width + _x;
    }

    override public function getBottom() : Float {
        return height + _y;
    }

    public function beBoundedBy(m : Map) : Camera {
        this.focalBoundingRect = new Rect(0, 0, m.sizeVector.x, m.sizeVector.y);
        return this;
    }

    // Set the bounding rectangle that the camera can't move outside of.
    // We reduce the size so that we can compare the center coordinate of the
    // camera to see if it's in bounds.
    public function setFocalBoundingRect(val : Rect) : Rect {
        camBoundingRect = val;
        return val;
    }

    // Since the focalBoundingRect depends on the width and height, we need to
    // recalculate it every time someone calls this getter method.
    public function getFocalBoundingRect() : Rect {
        return new Rect(camBoundingRect.x + this.width / 2, camBoundingRect.y + this.height / 2, camBoundingRect.width - this.width, camBoundingRect.height - this.height);
    }

    // Sets the center of the Camera to look at `loc`.
    public function setFocus(loc: Vec): Void {
        this.isFocused = true;
        goalFocalX = (isBound()) ? bind(loc.x, focalBoundingRect.x, focalBoundingRect.right) : loc.x;
        goalFocalY = (isBound()) ? bind(loc.y, focalBoundingRect.y, focalBoundingRect.bottom) : loc.y;
    }

    public function getFocus(): Vec {
        return new Vec(goalFocalX, goalFocalY);
    }

    /* Force the camera to go snap to the desired focal point, ignoring any
     * lag. This is expected for example when a new map is loaded.
     */
    public function snapTo(e : Entity) : Void {
        focalX = e.x;
        focalY = e.y;
    }

    /* Shake the camera for duration ticks, up to range pixels
     * away from where it started. Pass -1 as a duration to shake indefinitely. */
    public function shake(duration : Int = 30, range : Int = 5) : Void {
        var that : Camera = this;
        var fn : Void -> Void = null;

        fn = function() : Void {
            that.focalX = that._focalX + Util.randRange(-range, range);
            that.focalY = that._focalY + Util.randRange(-range, range);
            if(duration == 0)  {
                that.events.remove(fn);
            }
            duration--;
        };

        events.push(fn);
    }

    public function stopAllEvents() : Void {
        events = [];
    }

    function easeXY() : Void {
        if (followMode == FOLLOW_MODE_SLIDE)  {
            if(Math.abs(goalFocalX - _focalX) > .0000001)  {
                focalX = _focalX + (goalFocalX - _focalX) / (CAM_LAG / this.easeRate);
            } else  {
                focalX = goalFocalX;
            }

            if(Math.abs(goalFocalY - _focalY) > .0000001)  {
                focalY = _focalY + (goalFocalY - _focalY) / (CAM_LAG / this.easeRate);
            } else  {
                focalY = goalFocalY;
            }

            return;
        }
        if (followMode == FOLLOW_MODE_NONE)  {
            focalX = goalFocalX;
            focalY = goalFocalY;
            return;
        }
        throw ("Invalid Camera mode: " + followMode);
    }

    public function setEaseSpeed(ease : Int) : Camera {
        this.easeRate = ease;

        return this;
    }

    /* Adjust camera to follow the focus, and have the other points
       all also be visible. */
    public function follow(focus : Vec, points:Array<Vec>) : Void {
        var VERY_BIG : Float = 9999999;
        var left : Float = VERY_BIG;
        var right : Float = -VERY_BIG;
        var top : Float = VERY_BIG;
        var bottom : Float = -VERY_BIG;

        points.push(new Vec(focus.x - scaledWidth / 2, focus.y - scaledHeight / 2));
        points.push(new Vec(focus.x - scaledWidth / 2, focus.y + scaledHeight / 2));
        points.push(new Vec(focus.x + scaledWidth / 2, focus.y - scaledHeight / 2));
        points.push(new Vec(focus.x + scaledWidth / 2, focus.y + scaledHeight / 2));

        for (p in points) {
            if(p.x < left) left = p.x;
            if(p.x > right) right = p.x;
            if(p.y < top) top = p.y;
            if(p.y > bottom) bottom = p.y;
        }

        // This implies we were passed in bad data, but it can't hurt to check.
        if(left < camBoundingRect.x)
            left = camBoundingRect.x;
        if(right > camBoundingRect.right)
            right = camBoundingRect.right;
        if(top < camBoundingRect.y)
            top = camBoundingRect.y;
        if(bottom > camBoundingRect.bottom)
            bottom = camBoundingRect.bottom;
        // Calculate the new w/h of the square camera.
        var newDimension : Float = Math.max(right - left, bottom - top);
        if(newDimension < scaledWidth)
            newDimension = scaledWidth;
        // Recalculate the camera's bounds.
        // At this point, a Rect with top left coords (top, left) and width
        // (_width, _height) would satisfy all of the provided constraints.
        // But it's possible that this camera eases, so we just set the goalFocal
        // position and let easeXY do the rest of the work.
        width = newDimension;
        height = newDimension;
        goalFocalX = left + width / 2;
        goalFocalY = top + height / 2;
        this.isFocused = true;
    }

    // TODO: Remove this whole thing and thereby decouple Camera and Graphic (woo!)
    public function update() : Void {
        //TODO: If this isn't here, bad times.
        //if (Fathom.currentMode == C.MODE_TITLE) return;
        var e : Entity;
        var camScaleX : Float = normalWidth / width;
        var camScaleY : Float = normalHeight / height;
        if(!this.isFocused)  {
            Util.log("WARNING: Camera has no focus, so you probably won't see anything.");
        }

        for(ev in events) {
            ev();
        }

        easeXY();
        for(e in Fathom.entities.select([Set.doesntHaveGroup("no-camera")])) {
            e.cameraSpaceX = (e.x - this.x) * camScaleX;
            e.cameraSpaceY = (e.y - this.y) * camScaleY;

            e.scaleX = e.cameraSpaceScaleX * camScaleX;
            e.scaleY = e.cameraSpaceScaleY * camScaleY;
        }

        for(e in Fathom.entities.select([Set.hasGroup("no-camera")])) {
            e.cameraSpaceX = e.x;
            e.cameraSpaceY = e.y;
        }

    }

    public function translateSingleObject(s : Graphic) : Void {
        var camScaleX : Float = normalWidth / width;
        var camScaleY : Float = normalHeight / height;

        s.cameraSpaceX = (s.x - this.x) * camScaleX;
        s.cameraSpaceY = (s.y - this.y) * camScaleY;
    }
}
