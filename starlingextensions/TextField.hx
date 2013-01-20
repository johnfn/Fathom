package starlingextensions;

import flash.text.TextFormat;

class TextField extends starling.text.TextField {
  public var textFormatCallback(getCB, setCB): flash.text.TextField -> TextFormat -> Void;
  var _cb: flash.text.TextField -> TextFormat -> Void;

  public function new(x: Int, y: Int, content: String) {
    super(x, y, content);
  }

  function getCB(): flash.text.TextField -> TextFormat -> Void {
    return _cb;
  }

  function setCB(val: flash.text.TextField -> TextFormat -> Void): flash.text.TextField -> TextFormat -> Void {
    return _cb = val;
  }

  override function formatText(tf:flash.text.TextField, format: TextFormat) {
    _cb(tf, format);
  }
}

