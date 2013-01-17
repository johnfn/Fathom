//import flash.filters.DropShadowFilter;
import Hooks;
import Util;
import starlingextensions.TextField;
import flash.text.TextFormat;

 typedef ColorSegment = {
   var start: Int;
   var end: Int;
   var color: Int;

   // Necessary so that if they then change the accent color, we
   // can retroactively update.
   var accentDefault: Bool;
 }

class Text extends Entity {
    public var size(never, setSize) : Float;
    public var color(getColor, setColor) : UInt;
    public var text(getText, setText) : String;
    public var accentColor(getAccentColor, setAccentColor): UInt;

    var textField : TextField;
    var content : String;
    var typewriting : Bool;
    var typewriteTick : Void -> Void;
    var _accentColor: Int = 0xff0000;

    var pairs: Array<ColorSegment>;

    public function new(content : String = "", textName : String = null) {
        typewriting = false;
        super(-10, -10);
        pairs = [];
        this.content = content;
        if(textName != null) textField.fontName = textName;
        textField = new TextField(200, 100, content);
        textField.fontSize = 16;
        textField.color = 0x000000;
        //textField.filters = [new DropShadowFilter(2.0, 45, 0, 1, 0, 0, 1)];
        //textField.antiAliasType = "advanced";
        text = content;
        textField.border = true;
        textField.hAlign = "left";
        textField.vAlign = "top";
        textField.textFormatCallback = formatText;
        addChild(textField);
        // You need to set the width after you add the TextField - otherwise, it'll
        // be reset to 0.
        width = 200;
    }

    public function setAccentColor(c: Int): Int {
        return _accentColor = c;
    }

    public function getAccentColor(): Int {
        return _accentColor;
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

    function formatText(textField: flash.text.TextField, textFormat: TextFormat): Void {
        for (pair in pairs) {
            textFormat.color = pair.color;
            if (pair.accentDefault) {
                textFormat.color = accentColor;
            }
            textField.setTextFormat(textFormat, pair.start, pair.end);
        }
    }

    public function getText() : String {
        return textField.text;
    }

    // Interpolate the string by adding colors.
    public function setText(value: String) : String {
        pairs = [];

        var isDefaultAccentColor: Bool = true;
        var currentColor: Int = accentColor;
        var r: EReg = ~/\*|\{([0-9]+)[\s]*,[\s]*([0-9]+)[\s]*,[\s]*([0-9]+)\}/;
        var currentPair: ColorSegment = { start: -1, end: -1, color: currentColor, accentDefault: isDefaultAccentColor };

        var resultText: String = value;

        while (r.match(resultText)) {
            var loc: Int = r.matchedPos().pos;

            if (r.matched(0) == "*") {
                if (currentPair.start == -1) {
                    currentPair.start = loc;
                } else {
                    currentPair.end = loc;
                    pairs.push(currentPair);
                    currentPair = { start: -1, end: -1, color: currentColor, accentDefault: isDefaultAccentColor };
                }
            } else {
                currentColor = new Color(Std.parseInt(r.matched(1))
                                       , Std.parseInt(r.matched(2))
                                       , Std.parseInt(r.matched(3))).toInt();
                currentPair.color = currentColor;
                isDefaultAccentColor = false;
                currentPair.accentDefault = false;
            }

            resultText = r.replace(resultText, "");
        }


        return textField.text = resultText;
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

