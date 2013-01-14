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
  var loaded: Bool;
}

class ReloadedGraphic extends Bitmap {
  var url: String;
  var loader: Loader;
  var tileWidth: Int = 0;
  var tileHeight: Int = 0;
  var tileX: Int = 0;
  var tileY: Int = 0;
  var masterBitmapData:BitmapData;
  var doneCB: Void -> Void;
  var updateCB: Void -> Void;

  static var timer: Timer;
  static var urlData: SuperObjectHash<String, ReloadedData> = null;

  public function new(url: String, cb: Void -> Void = null) {
  	super();
    this.url = url;
    this.doneCB = cb;

    if (urlData == null) {
      urlData = new SuperObjectHash();
      timer = new Timer(1000);
      timer.run = constantlyReload;
    }

    if (urlData.exists(url)) {
      if (urlData.get(url).loaded) {

        // Even if we were able to load it immediately rather than deferring,
        // we can't call the `done` callback here because it would break
        // our established continuation-passing semantics.
        //
        // Imagine if someone did this:
        //
        // var reloadedG = new ReloadedGraphic("something", function() {
        //   reloadedG.x = 5;
        // })
        //
        // Normally that would work fine, but in this case `done` would be
        // called before reloadedG was assigned, so you'd get a null pointer
        // exception.
        //
        // The long and short of it is: we can load really fast, but
        // we may lie to the end user about just how fast.
        //
        // I don't anticipate people using the loaded callback much, so
        // I'm fine making this tradeoff.

        this.masterBitmapData = cast(urlData.get(url).loader.content, Bitmap).bitmapData;
        this.setTile(tileX, tileY);
      }

      urlData.get(url).waiters.push(this);
    } else {
      loader = new Loader();
      urlData.set(url, {url: url, waiters: [this], loader: loader, loaded: false});
      loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
    }
  }

  public function addUpdateCallback(cb: Void -> Void): Void {
    this.updateCB = cb;
  }

  public function reloadEvent(newBD:BitmapData) {
    this.masterBitmapData = newBD;
    this.setTile(tileX, tileY);

    if (this.doneCB != null) {
      this.doneCB();
      this.doneCB = null;
    }

    if (this.updateCB != null) {
      this.updateCB();
    }
  }

  public function setTileSize(tWidth: Int, tHeight: Int) {
    tileWidth = tWidth;
    tileHeight = tHeight;
  }

  public function setTile(tileX: Int, tileY: Int): Void {
    this.tileX = tileX;
    this.tileY = tileY;

    if (tileWidth == 0 || tileHeight == 0) {
      tileWidth = this.masterBitmapData.width;
      tileHeight = this.masterBitmapData.height;
    }

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

    urlData.get(url).loaded = true;
    for (waiter in urlData.get(url).waiters) {
      if (waiter.bitmapData == null || !compare(waiter.bitmapData, loadedBitmap.bitmapData)) {
        waiter.reloadEvent(loadedBitmap.bitmapData);
      }
    }
  }
}

#else
class ReloadedGraphic extends nme.display.Bitmap {
  public function new(url: String) {
    Util.assert(false, "something bad happened 3:");
    super();
  }
}
#end