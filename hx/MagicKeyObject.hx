import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;

class MagicKeyObject {
    public var A(getA, never): Bool; function getA() { return getProperty("A"); }
    public var B(getB, never): Bool; function getB() { return getProperty("B"); }
    public var C(getC, never): Bool; function getC() { return getProperty("C"); }
    public var D(getD, never): Bool; function getD() { return getProperty("D"); }
    public var E(getE, never): Bool; function getE() { return getProperty("E"); }
    public var F(getF, never): Bool; function getF() { return getProperty("F"); }
    public var G(getG, never): Bool; function getG() { return getProperty("G"); }
    public var H(getH, never): Bool; function getH() { return getProperty("H"); }
    public var I(getI, never): Bool; function getI() { return getProperty("I"); }
    public var J(getJ, never): Bool; function getJ() { return getProperty("J"); }
    public var K(getK, never): Bool; function getK() { return getProperty("K"); }
    public var L(getL, never): Bool; function getL() { return getProperty("L"); }
    public var M(getM, never): Bool; function getM() { return getProperty("M"); }
    public var N(getN, never): Bool; function getN() { return getProperty("N"); }
    public var O(getO, never): Bool; function getO() { return getProperty("O"); }
    public var P(getP, never): Bool; function getP() { return getProperty("P"); }
    public var Q(getQ, never): Bool; function getQ() { return getProperty("Q"); }
    public var R(getR, never): Bool; function getR() { return getProperty("R"); }
    public var S(getS, never): Bool; function getS() { return getProperty("S"); }
    public var T(getT, never): Bool; function getT() { return getProperty("T"); }
    public var U(getU, never): Bool; function getU() { return getProperty("U"); }
    public var V(getV, never): Bool; function getV() { return getProperty("V"); }
    public var W(getW, never): Bool; function getW() { return getProperty("W"); }
    public var X(getX, never): Bool; function getX() { return getProperty("X"); }
    public var Y(getY, never): Bool; function getY() { return getProperty("Y"); }
    public var Z(getZ, never): Bool; function getZ() { return getProperty("Z"); }

  public var Enter(getEnter, never): Bool; function getEnter() { return getProperty("Enter"); }
  public var Space(getSpace, never): Bool; function getSpace() { return getProperty("Space"); }
  public var Left(getLeft, never): Bool;   function getLeft()  { return getProperty("Left"); }
  public var Up(getUp, never): Bool;       function getUp()    { return getProperty("Up"); }
  public var Right(getRight, never): Bool; function getRight() { return getProperty("Right"); }
  public var Down(getDown, never): Bool;   function getDown()  { return getProperty("Down"); }

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

    function getProperty(which : Dynamic) : Dynamic {
        which = Reflect.field(Key, Std.string(which));
        return (keyStates[which].state == type || keyStates[which].state == otherType);
    }

    static function keysToKeyCodes() : Dynamic {
        var res: ObjectHash<String, Int> = new ObjectHash();
        res.set("Enter", 13);
        res.set("Space", 32);
        res.set("Left", 37);
        res.set("Up", 38);
        res.set("Right", 39);
        res.set("Down", 40);

        // Add A - Z.
        var k : Int = 65;
        while(k <= 65 + 26) {
            res.set(String.fromCharCode(k), k);
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
    static public function _initializeKeyInput() : Void {
        Fathom.stage.addEventListener(KeyboardEvent.KEY_DOWN, _keyDown);
        Fathom.stage.addEventListener(KeyboardEvent.KEY_UP, _keyUp);
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

