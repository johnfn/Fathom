#if nme
import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.display.Loader;
import nme.net.URLRequest;
import nme.events.Event;
#end

class ReloadedGraphic {
  var url: String;
  var loader: Loader;
  var b:Bitmap;

  public function new(url: String) {
    this.b = new Bitmap();
    this.url = url;
    Fathom.stage.addChild(b);

    this.loader = new Loader();
    this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
    this.loader.load(new URLRequest(url));
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

  function loadComplete(e:Event) {
    var loadedBitmap:Bitmap = cast(e.currentTarget.loader.content, Bitmap);

    if (b.bitmapData == null || !compare(b.bitmapData, loadedBitmap.bitmapData)) {
      b.bitmapData = loadedBitmap.bitmapData;
    }

    haxe.Timer.delay(function() {
      this.loader.load(new URLRequest(url));
    }, 250);
  }
}
