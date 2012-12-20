import flash.utils.Proxy;
import nme.utils.Proxy;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;

class MagicKeyObject extends Proxy {

	static var Key : Dynamic = keysToKeyCodes();
	var type : Int;
	var otherType : Int;
	static var keyStates : Array<Dynamic> = [];
	function new(type : Int) {
		this.type = type;
		if(this.type == KeyState.KEYSTATE_DOWN)  {
			this.otherType = KeyState.KEYSTATE_JUST_DOWN;
		}

		else if(this.type == KeyState.KEYSTATE_UP)  {
			this.otherType = KeyState.KEYSTATE_JUST_UP;
		}

		else  {
			this.otherType = this.type;
		}

	}

	override function getProperty(which : Dynamic) : Dynamic {
		which = Reflect.field(Key, Std.string(which));
		return (keyStates[which].state == type || keyStates[which].state == otherType);
	}

	static function keysToKeyCodes() : Dynamic {
		var res : Dynamic = { };
		Reflect.setField(res, "Enter", 13);
		Reflect.setField(res, "Space", 32);
		Reflect.setField(res, "Left", 37);
		Reflect.setField(res, "Up", 38);
		Reflect.setField(res, "Right", 39);
		Reflect.setField(res, "Down", 40);
		// Add A - Z.
		var k : Int = 65;
		while(k <= 65 + 26) {
			res[String.fromCharCode(k)] = k;
			k++;
		}
;
		return res;
	}

	static function _keyDown(event : KeyboardEvent) : Void {
		var keystate : KeyState = keyStates[event.keyCode];
		if(keystate.state != KeyState.KEYSTATE_JUST_DOWN && keystate.state != KeyState.KEYSTATE_DOWN)  {
			keystate.state = KeyState.KEYSTATE_JUST_DOWN;
		}
	}

	static function _keyUp(event : KeyboardEvent) : Void {
		var keystate : KeyState = keyStates[event.keyCode];
		if(keystate.state != KeyState.KEYSTATE_JUST_UP && keystate.state != KeyState.KEYSTATE_UP)  {
			keystate.state = KeyState.KEYSTATE_JUST_UP;
		}
	}

	// You should never have to call this function.
		// TODO: Move into Fathom, I guess.
		// TODO: should there be a container...which i construct..? I'm confused.
		static public function _initializeKeyInput(container : Sprite) : Void {
		Fathom.stage.addEventListener(KeyboardEvent.KEY_DOWN, _keyDown, false, 0, true);
		Fathom.stage.addEventListener(KeyboardEvent.KEY_UP, _keyUp, false, 0, true);
		var i : Int = 0;
		while(i < 255) {
			keyStates[i] = new KeyState();
			i++;
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
		static public function dealWithVariableKeyRepeatRates() : Void {
		var i : Int = 0;
		while(i < keyStates.length) {
			if(keyStates[i].state == KeyState.KEYSTATE_JUST_UP)  {
				keyStates[i].state = KeyState.KEYSTATE_UP;
			}
			if(keyStates[i].state == KeyState.KEYSTATE_JUST_DOWN)  {
				keyStates[i].state = KeyState.KEYSTATE_DOWN;
			}
			i++;
		}
	}

}

class KeyState {

	static public var KEYSTATE_JUST_DOWN : Int = 0;
	static public var KEYSTATE_DOWN : Int = 1;
	static public var KEYSTATE_JUST_UP : Int = 2;
	static public var KEYSTATE_UP : Int = 3;
	public var state : Int;
	public var timeoutID : Int;

	public function new() {
		state = KEYSTATE_UP;
		timeoutID = 0;
	}
}

