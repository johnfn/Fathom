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
  var waiters: Array<ReloadedGraphic>;
  var loader: Loader;
  var url: String;
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

      constantlyReload();
    }

    if (urlData.exists(url)) {
      urlData.get(url).waiters.push(this);
    } else {
      loader = new Loader();
      urlData.set(url, {url: url, waiters: [this], loader: loader});
      loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
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

  static function constantlyReload() {
    Thread.create(function() {

      for (val in urlData.values()) {
        val.loader.load(new URLRequest(val.url));
      }

      haxe.Timer.delay(function() {
        constantlyReload();
      }, 1000);
    });
  }

  function loadComplete(e:Event) {
    var loadedBitmap:Bitmap = cast(e.currentTarget.loader.content, Bitmap);
    var rect:Rectangle = new Rectangle(0, 0, loadedBitmap.width, loadedBitmap.height);
    var point:Point = new Point(0, 0);

    for (waiter in urlData.get(url).waiters) {
      if (waiter.bitmapData == null || !compare(waiter.bitmapData, loadedBitmap.bitmapData)) {
        waiter.bitmapData = loadedBitmap.bitmapData;
      }
    }
  }
}

#else
class ReloadedGraphic extends nme.display.Bitmap {
  public function new(url: String) {

  }
}
#end