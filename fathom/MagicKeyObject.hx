package fathom;

import fathom.SuperObjectHash;

#if flash
import starling.events.Event;
import starling.events.KeyboardEvent;
#else
import nme.events.Event;
import nme.events.KeyboardEvent;
#end

using StringTools;

class MagicKeyObject {
    public var A(getA, never): Bool; function getA() { return checkKey("A"); }
    public var B(getB, never): Bool; function getB() { return checkKey("B"); }
    public var C(getC, never): Bool; function getC() { return checkKey("C"); }
    public var D(getD, never): Bool; function getD() { return checkKey("D"); }
    public var E(getE, never): Bool; function getE() { return checkKey("E"); }
    public var F(getF, never): Bool; function getF() { return checkKey("F"); }
    public var G(getG, never): Bool; function getG() { return checkKey("G"); }
    public var H(getH, never): Bool; function getH() { return checkKey("H"); }
    public var I(getI, never): Bool; function getI() { return checkKey("I"); }
    public var J(getJ, never): Bool; function getJ() { return checkKey("J"); }
    public var K(getK, never): Bool; function getK() { return checkKey("K"); }
    public var L(getL, never): Bool; function getL() { return checkKey("L"); }
    public var M(getM, never): Bool; function getM() { return checkKey("M"); }
    public var N(getN, never): Bool; function getN() { return checkKey("N"); }
    public var O(getO, never): Bool; function getO() { return checkKey("O"); }
    public var P(getP, never): Bool; function getP() { return checkKey("P"); }
    public var Q(getQ, never): Bool; function getQ() { return checkKey("Q"); }
    public var R(getR, never): Bool; function getR() { return checkKey("R"); }
    public var S(getS, never): Bool; function getS() { return checkKey("S"); }
    public var T(getT, never): Bool; function getT() { return checkKey("T"); }
    public var U(getU, never): Bool; function getU() { return checkKey("U"); }
    public var V(getV, never): Bool; function getV() { return checkKey("V"); }
    public var W(getW, never): Bool; function getW() { return checkKey("W"); }
    public var X(getX, never): Bool; function getX() { return checkKey("X"); }
    public var Y(getY, never): Bool; function getY() { return checkKey("Y"); }
    public var Z(getZ, never): Bool; function getZ() { return checkKey("Z"); }

    public var Enter(getEnter, never): Bool; function getEnter() { return checkKey("Enter"); }
    public var Space(getSpace, never): Bool; function getSpace() { return checkKey("Space"); }
    public var Left(getLeft, never): Bool;   function getLeft()  { return checkKey("Left"); }
    public var Up(getUp, never): Bool;       function getUp()    { return checkKey("Up"); }
    public var Right(getRight, never): Bool; function getRight() { return checkKey("Right"); }
    public var Down(getDown, never): Bool;   function getDown()  { return checkKey("Down"); }

    //TODO: Replace with charCode
    static var codeToKey: IntHash<String> = keysToKeyCodes();
    var type : Int;
    var similarType : Int;
    static var keyStates: SuperObjectHash<String, KeyState>;

    function new(type: Int) {
        this.type = type;
        if(this.type == KeyState.KEYSTATE_DOWN) {
            this.similarType = KeyState.KEYSTATE_JUST_DOWN;
        } else if(this.type == KeyState.KEYSTATE_UP)  {
            this.similarType = KeyState.KEYSTATE_JUST_UP;
        } else {
            this.similarType = this.type;
        }
    }

    function checkKey(which : String) : Bool {
        var s:KeyState = keyStates.get(which.toUpperCase());
        return (s.state == type || s.state == similarType);
    }

    static function keysToKeyCodes() : IntHash<String> {
        var res: IntHash<String> = new IntHash();
        res.set(13, "Enter");
        res.set(32, "Space");
        res.set(37, "Left");
        res.set(38, "Up");
        res.set(39, "Right");
        res.set(40, "Down");

        // Add A - Z.
        for (k in 65...(65 + 26 + 1)) {
            res.set(k, String.fromCharCode(k));
        }

        return res;
    }

    static function _keyDown(event : KeyboardEvent) : Void {
        if (!codeToKey.exists(event.keyCode)) {
            trace("key " + event.keyCode + " not supported");
            return;
        }

        var keyName: String = codeToKey.get(event.keyCode).toUpperCase();
        var keystate : KeyState = keyStates.get(keyName);

        if(keystate.state != KeyState.KEYSTATE_JUST_DOWN && keystate.state != KeyState.KEYSTATE_DOWN)  {
            keystate.state = KeyState.KEYSTATE_JUST_DOWN;
        }
    }

    static function _keyUp(event : KeyboardEvent) : Void {
        if (!codeToKey.exists(event.keyCode)) {
            trace("key " + event.keyCode + " not supported");
            return;
        }

        var keyName: String = codeToKey.get(event.keyCode).toUpperCase();
        var keystate : KeyState = keyStates.get(keyName);

        if(keystate.state != KeyState.KEYSTATE_JUST_UP && keystate.state != KeyState.KEYSTATE_UP)  {
            keystate.state = KeyState.KEYSTATE_JUST_UP;
        }
    }

    // You should never have to call this function.
    // TODO: Move into Fathom, I guess.
    // TODO: should there be a container...which i construct..? I'm confused.
    static public function _initializeKeyInput() : Void {
        keyStates = new SuperObjectHash();
        Fathom.actualStage.addEventListener(KeyboardEvent.KEY_DOWN, _keyDown);
        Fathom.actualStage.addEventListener(KeyboardEvent.KEY_UP, _keyUp);

        for (f in Type.getInstanceFields(MagicKeyObject)) {
            if (f.startsWith("get") && !f.startsWith("get_")) {
                keyStates.set(f.substr(3).toUpperCase(), new KeyState());
            }
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
        for (k in keyStates.values()) {
            if(k.state == KeyState.KEYSTATE_JUST_UP)  {
                k.state = KeyState.KEYSTATE_UP;
            }
            if(k.state == KeyState.KEYSTATE_JUST_DOWN)  {
                k.state = KeyState.KEYSTATE_DOWN;
            }
        }
    }
}

//TODO: Can replace with enum.
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

