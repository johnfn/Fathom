package {
  import flash.display.Sprite;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  import mx.core.BitmapAsset;
  import flash.display.BitmapData;
  import flash.display.Stage;

  /*

   * Entity Space: the coordinates you use 99% of the time.
   * Camera Space: the coordinates of the sprite, post camera transformations.
  */

  public class Camera extends Rect {
    // The larger this number, the longer the camera takes to catch up.
    private var CAM_LAG:int = 90;

    // This is the rect that the camera will always stay inside.
    private var camBoundingRect:Rect = null;

    private static var EVENT_TYPE_SHAKE:String = "Shake";

    // This is a list of all events currently happening to this camera.
    // There can only ever be 1 event of each type.
    private var events:Object = {};

    // These two variables are the focal points of the camera.
    private var _focalX:Number;
    private var _focalY:Number;

    // If our camera lags behing the player, this is where it will eventually want to be.
    private var goalFocalX:Number;
    private var goalFocalY:Number;

    // If the camera is normalWidth by normalHeight, then no MovieClips will have to be scaled.
    private var normalWidth:Number;
    private var normalHeight:Number;

    // Rate at which the camera eases. Larger values -> faster easing.
    private var easeRate:int = 1;

    // These dimensions are the default scaled width of the camera. The camera may temporarily adjust
    // itself out of these dimensions, if, say, it's told to keepInScene() an Entity
    // that wandered out of the Camera bounds.
    private var scaledWidth:Number;
    private var scaledHeight:Number;

    private var FOLLOW_MODE_NONE:int = 0;
    private var FOLLOW_MODE_SLIDE:int = 1;

    private var followMode:int = FOLLOW_MODE_SLIDE;

    // This just helps us fix a bug we may encounter.
    private var isFocused:Boolean = false;

    // The Rect we extend from is the area from the game the camera displays.

    // TODO: This camera does not at all take into consideration non-square
    // dimensions. That would make life a bit harder.

    public function Camera(stage:Stage) {
      super(0, 0, stage.stageWidth / Fathom.scaleX, stage.stageHeight / Fathom.scaleY);

      this.normalWidth  = this.width;
      this.normalHeight = this.height;

      this.scaledWidth = this.width;
      this.scaledHeight = this.height;
    }

    public function scaleBy(val:Number):Camera {
      this.width = this.normalWidth * val;
      this.height = this.normalHeight * val;

      this.scaledWidth = this.width;
      this.scaledHeight = this.height;

      if (camBoundingRect) {
        camBoundingRect.x *= val;
        camBoundingRect.y *= val;

        camBoundingRect.width *= val;
        camBoundingRect.height *= val;
      }

      return this;
    }

    public function bind(val:Number, low:Number, high:Number):Number {
      if (val < low) return low;
      if (val > high) return high;

      return val;
    }

    public function isBound():Boolean {
      return camBoundingRect != null;
    }

    // Updating the focus updates the x, y coordinates also.

    public function set focalX(val:Number):void {
      _focalX = isBound() ? bind(val, focalBoundingRect.x, focalBoundingRect.right) : val;

      _x = _focalX - width  / 2;
    }

    public function get focalX():Number {
      return _x + width / 2;
    }

    public function set focalY(val:Number):void {
      _focalY = isBound() ? bind(val, focalBoundingRect.y, focalBoundingRect.bottom) : val;

      _y = _focalY - height / 2;
    }

    public function get focalY():Number {
      return _y + height / 2;
    }

    // We have to ensure that setting these properties does not cause the camera to
    // exceed its bounding box.

    public override function set x(val:Number):void {
      _x = isBound() ? bind(val, camBoundingRect.x, camBoundingRect.right) : val;
    }

    public override function set y(val:Number):void {
      _y = isBound() ? bind(val, camBoundingRect.y, camBoundingRect.bottom) : val;
    }

    public override function set width(val:Number):void {
      _width = isBound() ? bind(_x + val, camBoundingRect.x, camBoundingRect.right) - _x: val;
    }

    public override function set height(val:Number):void {
      _height = isBound() ? bind(_y + val, camBoundingRect.y, camBoundingRect.bottom) - _y: val;
    }

    public override function get right():Number {
      return width + _x;
    }

    public override function get bottom():Number {
      return height + _y;
    }

    public function beBoundedBy(m:Map):Camera {
      this.focalBoundingRect = new Rect(0, 0, m.sizeVector.x, m.sizeVector.y);

      return this;
    }

    // Set the bounding rectangle that the camera can't move outside of.
    // We reduce the size so that we can compare the center coordinate of the
    // camera to see if it's in bounds.
    public function set focalBoundingRect(val:Rect):void {
      camBoundingRect = val;
    }

    // Since the focalBoundingRect depends on the width and height, we need to
    // recalculate it every time someone calls this getter method.
    public function get focalBoundingRect():Rect {
      return new Rect( camBoundingRect.x + this.width / 2
                     , camBoundingRect.y + this.height / 2
                     , camBoundingRect.width - this.width
                     , camBoundingRect.height - this.height);
    }

    // Sets the center of the Camera to look at `loc`.
    public function setFocus(loc:Vec):void {
      this.isFocused = true;

      goalFocalX = isBound() ? bind(loc.x, focalBoundingRect.x, focalBoundingRect.right) : loc.x;
      goalFocalY = isBound() ? bind(loc.y, focalBoundingRect.y, focalBoundingRect.bottom) : loc.x;
    }

    /* Force the camera to go snap to the desired focal point, ignoring any
     * lag. This is expected for example when a new map is loaded.
     */

    public function snapTo(e:Entity):void {
      focalX = e.x;
      focalY = e.y;
    }

    /* Shake the camera for duration ticks, up to range pixels
     * away from where it started. Pass -1 as a duration to shake indefinitely. */
    public function shake(duration:int = 30, range:int = 5):void {
      var that:Camera = this;

      var fn:Function = function():void {
        that.focalX = that._focalX + Util.randRange(-range, range);
        that.focalY = that._focalY + Util.randRange(-range, range);

        if (duration == 0) {
          that.events.remove(fn);
        }

        duration--;
      };

      events[EVENT_TYPE_SHAKE] = fn;
    }

    public function stopAllEvents():void {
      events = {};
    }

    private function easeXY():void {
      if (followMode == FOLLOW_MODE_SLIDE) {
        if (Math.abs(goalFocalX - _focalX) > .0000001) {
          focalX = _focalX + (goalFocalX - _focalX) / (CAM_LAG / this.easeRate);
        } else {
          focalX = goalFocalX;
        }

        if (Math.abs(goalFocalY - _focalY) > .0000001) {
          focalY = _focalY + (goalFocalY - _focalY) / (CAM_LAG / this.easeRate);
        } else {
          focalY = goalFocalY;
        }

        return;
      }

      if (followMode == FOLLOW_MODE_NONE) {
        focalX = goalFocalX;
        focalY = goalFocalY;

        return;
      }

      throw new Error("Invalid Camera mode: " + followMode);
    }

    public function setEaseSpeed(ease:int):Camera {
      this.easeRate = ease;

      return this;
    }

    /* Adjust camera to follow the focus, and have the other points
       all also be visible. */
    public function follow(focus:Vec, ...points):void {
      points.push(new Vec(focus.x - scaledWidth / 2, focus.y - scaledHeight / 2));
      points.push(new Vec(focus.x - scaledWidth / 2, focus.y + scaledHeight / 2));
      points.push(new Vec(focus.x + scaledWidth / 2, focus.y - scaledHeight / 2));
      points.push(new Vec(focus.x + scaledWidth / 2, focus.y + scaledHeight / 2));

      var VERY_BIG:Number = 99999999999;

      var left:Number = VERY_BIG;
      var right:Number = -VERY_BIG;

      var top:Number = VERY_BIG;
      var bottom:Number = -VERY_BIG;

      for (var i:int = 0; i < points.length; i++) {
        if (points[i].x < left)   left   = points[i].x;
        if (points[i].x > right)  right  = points[i].x;

        if (points[i].y < top)    top    = points[i].y;
        if (points[i].y > bottom) bottom = points[i].y;
      }

      // This implies we were passed in bad data, but it can't hurt to check.
      if (left < camBoundingRect.x) left = camBoundingRect.x;
      if (right > camBoundingRect.right) right = camBoundingRect.right;

      if (top < camBoundingRect.y) top = camBoundingRect.y;
      if (bottom > camBoundingRect.bottom) bottom = camBoundingRect.bottom;

      // Calculate the new w/h of the square camera.
      var newDimension:Number = Math.max(right - left, bottom - top);

      if (newDimension < scaledWidth) newDimension = scaledWidth;

      // Recalculate the camera's bounds.

      // At this point, a Rect with top left coords (top, left) and width
      // (_width, _height) would satisfy all of the provided constraints.

      // But it's possible that this camera eases, so we just set the goalFocal
      // position and let easeXY do the rest of the work.

      width  = newDimension;
      height = newDimension;

      goalFocalX = left + width  / 2;
      goalFocalY = top +  height / 2;

      this.isFocused = true;
    }

    // TODO: Remove this whole thing and thereby decouple Camera and Graphic (woo!)
    public function update():void {
      //TODO: If this isn't here, bad times.
      //if (Fathom.currentMode == C.MODE_TITLE) return;

      var e:Entity;
      var camScaleX:Number = normalWidth / width;
      var camScaleY:Number = normalHeight / height;

      if (!this.isFocused) {
        Util.log("WARNING: Camera has no focus, so you probably won't see anything.");
      }

      for each (var event:Function in events) {
        event();
      }

      easeXY();

      for each (e in Fathom.entities.select("!no-camera")) {
        e.cameraSpaceX = (e.x - this.x) * camScaleX;
        e.cameraSpaceY = (e.y - this.y) * camScaleY;

        e.scaleX = e.cameraSpaceScaleX * camScaleX;
        e.scaleY = e.cameraSpaceScaleY * camScaleY;
      }

      for each (e in Fathom.entities.select("no-camera")) {
        e.cameraSpaceX = e.x;
        e.cameraSpaceY = e.y;
      }
    }

    public function translateSingleObject(s:Graphic):void {
      var camScaleX:Number = normalWidth / width;
      var camScaleY:Number = normalHeight / height;

      s.cameraSpaceX = (s.x - this.x) * camScaleX;
      s.cameraSpaceY = (s.y - this.y) * camScaleY;
    }
  }
}
