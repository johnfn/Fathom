package {
  import flash.filters.DropShadowFilter;
  import flash.text.TextField;
  import flash.text.TextFormat;
  import flash.utils.setInterval;
  import flash.utils.clearInterval;

  import Hooks;
  import Util;
  import MagicArray;

  public class Text extends Entity {
    internal var textField:TextField;
    internal var content:String = "";

    private var typewriting:Boolean = false;
    private var typewriteTick:Function;

    private var normalTextFormat:TextFormat = new TextFormat();
    private var redTextFormat:TextFormat = new TextFormat();

    function Text(content:String = "", textName:String = null):void {
      super(0, 0);

      this.content = content;

      if (textName != null) normalTextFormat.font = textName;
      normalTextFormat.size = 16;
      normalTextFormat.color = 0xFFFFFF;

      if (textName != null) redTextFormat.font = textName;
      redTextFormat.size = 16;
      redTextFormat.color = 0xFF0000;

      textField = new TextField();
      textField.selectable = false;
      textField.wordWrap = true;
      textField.filters = [new DropShadowFilter(2.0, 45, 0, 1, 0, 0, 1)];
      textField.embedFonts = true;
      textField.defaultTextFormat = normalTextFormat;
      textField.antiAliasType = "advanced";
      textField.sharpness = 100;
      textField.thickness = 0;

      text = content;

      addChild(textField);

      // You need to set the width after you add the TextField - otherwise, it'll
      // be reset to 0.
      width = 200;
      //height = 200;
    }

    public function set size(val:Number):void {
      normalTextFormat.size = val;
      redTextFormat.size = val;

      textField.defaultTextFormat = normalTextFormat;
    }

    override public function set width(val:Number):void {
      textField.width = val;
      super.width = val;
    }

    override public function set height(val:Number):void {
      textField.height = val;
      super.height = val;
    }

    public function set color(val:uint):void {
      textField.textColor = val;
    }

    public function get color():uint {
      return textField.textColor;
    }

    /*
    //TODO
    public function advanceOnKeypress(key:int):Text {
      listen(Hooks.keyRecentlyDown(key, advanceText));

      return this;
    }
    */

    public function get text():String {
      return textField.text;
    }


    // Interpolate the string by adding colors. Any words between *stars* are
    // colored red.
    public function set text(s:String):void {
      var pairs:Array = [];
      var currentPair:Array = [];
      var idx:int = 0;
      var resultString:String = "";
      var i:int;

      for (i = 0; i < s.length; i++) {
        idx++;

        if (s.charAt(i) == "*") {
          idx--;
          currentPair.push(idx);
        } else {
          resultString += s.charAt(i);
        }

        if (currentPair.length == 2) {
          pairs.push(currentPair);
          currentPair = [];
        }
      }

      textField.text = resultString;

      for (i = 0; i < pairs.length; i++) {
        textField.setTextFormat(redTextFormat, pairs[i][0], pairs[i][1]);
      }
    }

    public function advanceText():void {
      if (typewriting) {
        // TODO: Haven't done this yet.
        Util.assert(false);
      } else {
        destroy();
      }
    }

    // The classic videogame-ish effect of showing only 1 character
    // of text at a time.
    public function typewrite():Text {
      var counter:int = 0;
      var id:int = 0;
      var that:Text = this;

      typewriting = true;
      textField.text = "";

      this.typewriteTick = function():void {
        if (counter > that.content.length) {
          textField.text = content;
          typewriting = false;

          that.unlisten(this.typewriteTick);
          return;
        }

        textField.appendText(that.content.charAt(counter));
        counter++;
      }

      listen(this.typewriteTick);

      return this;
    }

    override public function groups():Set {
      return super.groups().concat("no-camera", "non-blocking");
    }

    public override function clearMemory():void {
      textField = null;
      content = null;
      typewriteTick = null;

      super.clearMemory();
    }
  }
}
