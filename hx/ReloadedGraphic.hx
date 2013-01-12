#if cpp
import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.display.Loader;
import nme.net.URLRequest;
import nme.events.Event;
import nme.geom.Rectangle;
import nme.geom.Point;
import nme.display.Shape;
import cpp.vm.Thread;
import Sys;

import haxe.Timer;
import haxe.macro.Context;

typedef ReloadedData = {
  var waiters: Array<ReloadedGraphic>;
  var loader: Loader;
  var url: String;
}

class ReloadedGraphic extends Bitmap {
  var url: String;
  var loader: Loader;
  var tileWidth: Int = 25;
  var tileHeight: Int = 25;
  var tileX: Int = 0;
  var tileY: Int = 0;
  var masterBitmapData:BitmapData;

  static var timer: Timer;
  static var urlData: SuperObjectHash<String, ReloadedData> = null;

  public function new(url: String) {
  	super();
    this.url = url;

    if (urlData == null) {
      urlData = new SuperObjectHash();
      timer = new Timer(1000);
      timer.run = constantlyReload;
    }

    if (urlData.exists(url)) {
      urlData.get(url).waiters.push(this);
    } else {
      loader = new Loader();
      urlData.set(url, {url: url, waiters: [this], loader: loader});
      loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
    }
  }

  public function setTile(tileX: Int, tileY: Int): Void {
    this.tileX = tileX;
    this.tileY = tileY;

    if (masterBitmapData != null) {
      var region:Rectangle = new Rectangle(tileX * tileWidth, tileY * tileHeight, tileWidth, tileHeight);
      bitmapData = new BitmapData(tileWidth, tileHeight);
      bitmapData.copyPixels(masterBitmapData, region, new Point(0, 0), null, null, true);
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
    for (val in urlData.values()) {
      val.loader.load(new URLRequest(Fathom.hotswapPrefix + val.url));
    }
  }

  function loadComplete(e:Event) {
    var loadedBitmap:Bitmap = cast(e.currentTarget.loader.content, Bitmap);
    var rect:Rectangle = new Rectangle(0, 0, loadedBitmap.width, loadedBitmap.height);
    var point:Point = new Point(0, 0);

    for (waiter in urlData.get(url).waiters) {
      if (waiter.bitmapData == null || !compare(waiter.bitmapData, loadedBitmap.bitmapData)) {
        waiter.masterBitmapData = loadedBitmap.bitmapData;
        waiter.setTile(waiter.tileX, waiter.tileY);
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