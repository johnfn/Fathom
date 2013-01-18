//import flash.filters.DropShadowFilter;
import Hooks;
import Util;
#if flash
import starlingextensions.TextField;
#else
import nme.text.TextField;
#end

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
    public var color(getColor, setColor) : Int;
    public var text(getText, setText) : String;
    public var accentColor(getAccentColor, setAccentColor): Int;

    var textField : TextField;
    var typewriting : Bool;
    var typewriteTick : Void -> Void;
    var _accentColor: Int = 0xff0000;

    var normalTextFormat: TextFormat;

    var pairs: Array<ColorSegment>;

    public function new(content : String = "", fontName : String = "Arial") {
        typewriting = false;
        super(-10, -10);
        pairs = [];

        var color: Int = 0xff0000;
#if flash
        textField = new TextField(200, 100, "");
        textField.fontName = fontName;
        textField.fontSize = 16;
        textField.color = color;
        textField.border = true;
        textField.hAlign = "left";
        textField.vAlign = "top";
        textField.textFormatCallback = formatText;
#else
        textField = new TextField();
        textField.selectable = false;
        textField.width = 200;
        textField.height = 100;

        var textFormat : TextFormat = new TextFormat();

        textFormat.font = fontName;
        textFormat.size = 16;
        textFormat.align = flash.text.TextFormatAlign.LEFT;
        textFormat.color = color;

        textField.defaultTextFormat = textFormat;
#end
        text = content;
        addChild(textField);

        //textField.filters = [new DropShadowFilter(2.0, 45, 0, 1, 0, 0, 1)];
        //textField.antiAliasType = "advanced";

        // You need to set the width after you add the TextField - otherwise, it'll
        // be reset to 0.
        width = 200;
    }

    public function setAccentColor(c: Int): Int {
        _accentColor = c;
#if !flash
        formatText(textField, textField.defaultTextFormat);
#end

        return c;
    }

    public function getAccentColor(): Int {
        return _accentColor;
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

    public function setColor(val : Int) : Int {
#if flash
        textField.color = val;
#else
        trace(textField.textColor);
        textField.defaultTextFormat.color = val;
        formatText(textField, textField.defaultTextFormat);
#end

        return val;
    }

    public function getColor() : Int {
#if flash
        return textField.color;
#else
        return textField.textColor;
#end
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
        var isDefaultAccentColor: Bool = true;
        var currentColor: Int = accentColor;
        // This regex either matches a *, a **, or something like {255, 255, 0}.
        var e: EReg = ~/\*{1,2}|\{([0-9]+)[\s]*,[\s]*([0-9]+)[\s]*,[\s]*([0-9]+)\}/;
        var currentPair: ColorSegment = { start: -1, end: -1, color: currentColor, accentDefault: isDefaultAccentColor };

        var resultText: String;
        var loc: Int = 0;
        var ignoreNextStar: Bool = false;

        pairs = [];

        resultText = e.customReplace(value, function(r: EReg): String {
            var replacement: String = "";

            loc += e.matchedPos().pos;

            if (r.matched(0) == "*") {
                if (currentPair.start == -1) {
                    currentPair.start = loc;
                } else {
                    currentPair.end = loc;
                    pairs.push(currentPair);
                    currentPair = { start: -1, end: -1, color: currentColor, accentDefault: isDefaultAccentColor };
                }

                replacement = "";
            } else if (r.matched(0) == "**") {
                replacement = "*";
            } else {
                currentColor = new Color(Std.parseInt(r.matched(1))
                                       , Std.parseInt(r.matched(2))
                                       , Std.parseInt(r.matched(3))).toInt();
                currentPair.color = currentColor;
                isDefaultAccentColor = false;
                currentPair.accentDefault = false;
                replacement = "";
            }

            return replacement;
        });

        textField.text = resultText;

        // In the case of Flash, formatText is called inside the render function of
        // TextField.

#if !flash
        formatText(textField, textField.defaultTextFormat);
#end

        return resultText;
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
        //TODO - I got rid of content

        /*
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
        */

        return this;
    }

    override public function groups() : Set<String> {
        return super.groups().concat("no-camera", "non-blocking");
    }

    override public function clearMemory() : Void {
        textField = null;
        typewriteTick = null;
        super.clearMemory();
    }

}
