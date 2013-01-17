//import flash.filters.DropShadowFilter;
import Hooks;
import Util;
import starlingextensions.ColoredText;

class Text extends Entity {
    public var size(never, setSize) : Float;
    public var color(getColor, setColor) : UInt;
    public var text(getText, setText) : String;
    public var accentColor(getAccentColor, setAccentColor): UInt;

    var textField : ColoredText;
    var content : String;
    var typewriting : Bool;
    var typewriteTick : Void -> Void;

    public function new(content : String = "", textName : String = null) {
        typewriting = false;
        super(-10, -10);
        this.content = content;
        if(textName != null) textField.fontName = textName;
        textField = new ColoredText(200, 100, content);
        textField.fontSize = 16;
        textField.color = 0x000000;
        //textField.filters = [new DropShadowFilter(2.0, 45, 0, 1, 0, 0, 1)];
        //textField.antiAliasType = "advanced";
        text = content;
        textField.border = true;
        textField.hAlign = "left";
        textField.vAlign = "top";
        addChild(textField);
        // You need to set the width after you add the TextField - otherwise, it'll
        // be reset to 0.
        width = 200;
    }

    public function setAccentColor(c: Int): Int {
        return textField.accentColor = c;
    }

    public function getAccentColor(): Int {
        return textField.accentColor;
    }

    public function setSize(val : Float) : Float {
        textField.fontSize = val;
        return val;
    }

    public function setWidth(val : Float) : Float {
        textField.width = val;
        this.width = val;
        return val;
    }

    public function setHeight(val : Float) : Float {
        textField.height = val;
        this.height = val;
        return val;
    }

    public function setColor(val : UInt) : UInt {
        textField.color = val;
        return val;
    }

    public function getColor() : UInt {
        return textField.color;
    }

    /*
    //TODO
    public function advanceOnKeypress(key:int):Text {
      listen(Hooks.keyRecentlyDown(key, advanceText));

      return this;
    }
    */
    public function getText() : String {
        return textField.text;
    }

    // Interpolate the string by adding colors. Any words between *stars* are
    // colored red.
    public function setText(s : String) : String {
        return textField.text = s;
    }

    public function advanceText() : Void {
        if(typewriting)  {
            // TODO: Haven't done this yet.
            Util.assert(false);
        } else  {
            destroy();
        }

    }

    // The classic videogame-ish effect of showing only 1 character
    // of text at a time.
    public function typewrite() : Text {
        var counter : Int = 0;
        var id : Int = 0;
        var that : Text = this;
        typewriting = true;
        textField.text = "";
        this.typewriteTick = function() : Void {
            if(counter > that.content.length)  {
                textField.text = content;
                typewriting = false;
                that.unlisten(this.typewriteTick);
                return;
            }
            textField.text += that.content.charAt(counter);
            counter++;
        };

        listen(this.typewriteTick);
        return this;
    }

    override public function groups() : Set<String> {
        return super.groups().concat("no-camera", "non-blocking");
    }

    override public function clearMemory() : Void {
        textField = null;
        content = null;
        typewriteTick = null;
        super.clearMemory();
    }

}

