package fathom;

import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.display.Loader;
import nme.net.URLRequest;
import nme.events.Event;
import nme.geom.Rectangle;
import nme.geom.Point;
import nme.display.Shape;
import Sys;

import haxe.Timer;
import haxe.macro.Context;

typedef ReloadedData = {
  var waiters: Array<ReloadedGraphic>;
  var loader: Loader;
  var url: String;
  var loaded: Bool;
}

/** ReloadedGraphic is essentially a Bitmap that reloads itself every
 *  time the file it was loaded from changes.
 *
 *  You should never have to deal with ReloadedGraphics unless you are
 *  extending Fathom in some way.
 */
class ReloadedGraphic extends Bitmap {
  var url: String;
  var loader: Loader;
  var tileWidth: Int = 0;
  var tileHeight: Int = 0;
  var tileX: Int = 0;
  var tileY: Int = 0;
  var masterBitmapData:BitmapData;
  var updateCB: Void -> Void;

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
      if (urlData.get(url).loaded) {
        this.masterBitmapData = cast(urlData.get(url).loader.content, Bitmap).bitmapData;
        this.setTile(tileX, tileY);
      }

      urlData.get(url).waiters.push(this);
    } else {
      loader = new Loader();
      urlData.set(url, {url: url, waiters: [this], loader: loader, loaded: false});
      loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
    }

    this.masterBitmapData = nme.Assets.getBitmapData(url);
    this.bitmapData = this.masterBitmapData;

    if (Fathom.rootDir == null) {
      trace("Fathom.rootDir is null. You should set it to be the root directory of your project - otherwise hot reloading won't work.");
    } else {
      haxe.Timer.delay(function() {
        if (!urlData.get(url).loaded) {
          trace("I can't seem to open the file: " + (Fathom.rootDir + url) + " - that, or it's taking a while.");
        }
      }, 2000);
    }
  }

  public function addUpdateCallback(cb: Void -> Void): Void {
    this.updateCB = cb;
  }

  function reloadEvent(newBD:BitmapData) {
    this.masterBitmapData = newBD;
    this.setTile(tileX, tileY);

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
      val.loader.load(new URLRequest(Fathom.rootDir + val.url));
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
