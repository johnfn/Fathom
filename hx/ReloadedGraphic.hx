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

typedef ReloadedData = {
  // BitmapData that everyone else holds a reference to.
  var masterBitmapData: BitmapData;
  var finishedLoading: Bool;
  var waiters: Array<ReloadedGraphic>;
  var loader: Loader;
}

class ReloadedGraphic extends Bitmap {
  var url: String;
  var loader: Loader;

  static var urlData: SuperObjectHash<String, ReloadedData> = null;

  public function new(url: String) {
  	super();
    this.url = url;

    if (urlData == null) {
      urlData = new SuperObjectHash();
    }

    if (urlData.exists(url)) {
      if (urlData.get(url).finishedLoading) {
        var data:BitmapData = cast(urlData.get(url).loader.content, Bitmap).bitmapData;
        var rect:Rectangle = new Rectangle(0, 0, data.width, data.height);
        var point:Point = new Point(0, 0);

        this.bitmapData.copyPixels(data, rect, point);
      }

      urlData.get(url).waiters.push(this);
    } else {
      loader = new Loader();
      urlData.set(url, {masterBitmapData: null, finishedLoading: false, waiters: [this], loader: loader});
      loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
    	Thread.create(beginLoad);
    }
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
    var rect:Rectangle = new Rectangle(0, 0, this.width, this.height);
    var point:Point = new Point(0, 0);

    urlData.get(url).finishedLoading = true;

    if (bitmapData == null || !compare(bitmapData, loadedBitmap.bitmapData)) {
      for (waiter in urlData.get(url).waiters) {
        waiter.bitmapData = loadedBitmap.bitmapData;
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