#if nme
import nme.display.Sprite;
import nme.display.DisplayObjectContainer;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.events.Event;
#else
import starling.display.Image;
import starling.core.Starling;
import starling.textures.Texture;
import starling.display.Sprite;
import starling.display.DisplayObjectContainer;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import starling.events.Event;
import starling.core.RenderSupport;
#end

import Hooks;
import Util;

class CamAdjustedSprite implements IPositionable {
    //TODO - eventually this should be private
    var sprite:DisplayObjectContainer;

    public var x(getX, setX): Float;
    public var y(getY, setY): Float;

    // The location of the entity, before camera transformations.
    var entitySpacePos : Rect;

    public function setX(val : Float) : Float {
        return entitySpacePos.x = val;
    }

    public function getX() : Float {
        return entitySpacePos.x;
    }

    public function setY(val : Float) : Float {
        return entitySpacePos.y = val;
    }

    public function getY() : Float {
        return entitySpacePos.y;
    }

}
