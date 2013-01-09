#if cpp
import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.display.Loader;
import nme.net.URLRequest;
import nme.events.Event;
import nme.geom.Rectangle;
import nme.geom.Point;
import cpp.vm.Thread;

class ReloadedGraphic extends Bitmap {
  var url: String;
  var loader: Loader;

  public function new(url: String) {
  	super();

    this.url = url;

    this.loader = new Loader();
    this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
  	Thread.create(beginLoad);
  }

  // Returns true if the two BitmapDatas are equal, false otherwise.
  // BitmapData#compare exists in AS3 but not elsewhere.
  // Could be moved into some utility mixin.
  function compare(b1:BitmapData, b2:BitmapData): Bool {
#if flash
    return b1.compare(b2) == 0;
#end

    if (b1.width != b2.width || b1.height != b2.height) return false;

    for (i in 0...b1.width) {
      for (j in 0...b1.height) {
        if (b1.getPixel(i, j) != b2.getPixel(i, j)) return false;
      }
    }

    return true;
  }

  function beginLoad() {
    this.loader.load(new URLRequest(url));
  }

  function loadComplete(e:Event) {
    var loadedBitmap:Bitmap = cast(e.currentTarget.loader.content, Bitmap);

    if (bitmapData == null || !compare(bitmapData, loadedBitmap.bitmapData)) {
      if (bitmapData == null) {
      	var b:Bitmap = new Bitmap(loadedBitmap.bitmapData);
      	b.x = 50;
      	b.y = 50;
      	Fathom.stage.addChild(b);

      	bitmapData = loadedBitmap.bitmapData;
      } else {
	      var rect:Rectangle = new Rectangle(0, 0, this.width, this.height);
	      var point:Point = new Point(0, 0);

	      this.bitmapData.copyPixels(loadedBitmap.bitmapData, rect, point);
	    }
    }

    haxe.Timer.delay(function() {
    	Thread.create(beginLoad);
    }, 1000);
  }
}

#else
class ReloadedGraphic extends Bitmap {
  public function new(url: String) {

  }
}
#end