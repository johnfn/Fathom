package {
import flash.utils.Proxy;
import flash.utils.flash_proxy;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;

public dynamic class MagicKeyObject extends Proxy {
  private static var Key:Object = keysToKeyCodes();

  private var type:int;
  private var otherType:int;
  private static var keyStates:Array = [];

  function MagicKeyObject(type:int) {
    this.type = type;

    if (this.type == KeyState.KEYSTATE_DOWN) {
      this.otherType = KeyState.KEYSTATE_JUST_DOWN;
    } else if (this.type == KeyState.KEYSTATE_UP) {
      this.otherType = KeyState.KEYSTATE_JUST_UP;
    } else {
      this.otherType = this.type;
    }
  }

  override flash_proxy function getProperty(which:*):* {
    which = Key[which];

    return (keyStates[which].state == type || keyStates[which].state == otherType)
  }

  private static function keysToKeyCodes():Object {
    var res:Object = {};

    res["Enter"] = 13;
    res["Space"] = 32;
    res["Left"]  = 37;
    res["Up"]    = 38;
    res["Right"] = 39;
    res["Down"]  = 40;

    // Add A - Z.
    for (var k:int = 65; k <= 65 + 26; k++) {
      res[String.fromCharCode(k)] = k;
    }

    return res;
  }

  private static function _keyDown(event:KeyboardEvent):void {
    var keystate:KeyState = keyStates[event.keyCode];

    if (keystate.state != KeyState.KEYSTATE_JUST_DOWN && keystate.state != KeyState.KEYSTATE_DOWN) {
      keystate.state = KeyState.KEYSTATE_JUST_DOWN;
    }
  }

  private static function _keyUp(event:KeyboardEvent):void {
    var keystate:KeyState = keyStates[event.keyCode];

    if (keystate.state != KeyState.KEYSTATE_JUST_UP && keystate.state != KeyState.KEYSTATE_UP) {
      keystate.state = KeyState.KEYSTATE_JUST_UP;
    }
  }

  // You should never have to call this function.
  // TODO: Move into Fathom, I guess.
  // TODO: should there be a container...which i construct..? I'm confused.
  public static function _initializeKeyInput(container:Sprite):void {
    Fathom.stage.addEventListener(KeyboardEvent.KEY_DOWN, _keyDown, false, 0, true);
    Fathom.stage.addEventListener(KeyboardEvent.KEY_UP, _keyUp, false, 0, true);

    for (var i:int = 0; i < 255; i++) {
      keyStates[i] = new KeyState();
    }

    Util.KeyDown = new MagicKeyObject(KeyState.KEYSTATE_DOWN);
    Util.KeyJustDown = new MagicKeyObject(KeyState.KEYSTATE_JUST_DOWN);

    Util.KeyUp = new MagicKeyObject(KeyState.KEYSTATE_UP);
    Util.KeyJustUp = new MagicKeyObject(KeyState.KEYSTATE_JUST_UP);
  }

  // This is very frustrating.

  // This method is called from an onEnterFrame function. Everything will
  // work correctly as long as this is called FPS times per second or so, as
  // to properly flush the keys through.
  public static function dealWithVariableKeyRepeatRates():void {
    for (var i:int = 0; i < keyStates.length; i++) {
      if (keyStates[i].state == KeyState.KEYSTATE_JUST_UP) {
        keyStates[i].state = KeyState.KEYSTATE_UP;
      }

      if (keyStates[i].state == KeyState.KEYSTATE_JUST_DOWN) {
        keyStates[i].state = KeyState.KEYSTATE_DOWN;
      }
    }
  }
}
}

class KeyState {
  public static var KEYSTATE_JUST_DOWN:int = 0;
  public static var KEYSTATE_DOWN:int      = 1;
  public static var KEYSTATE_JUST_UP:int   = 2;
  public static var KEYSTATE_UP:int        = 3;

  public var state:int = KEYSTATE_UP;
  public var timeoutID:int = 0;
}