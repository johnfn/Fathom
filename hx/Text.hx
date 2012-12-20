import flash.filters.DropShadowFilter;
import flash.text.TextField;
import flash.text.TextFormat;
import Hooks;
import Util;

class Text extends Entity {
	public var size(never, setSize) : Float;
	public var color(getColor, setColor) : UInt;
	public var text(getText, setText) : String;

	var textField : TextField;
	var content : String;
	var typewriting : Bool;
	var typewriteTick : Void -> Void;
	var normalTextFormat : TextFormat;
	var redTextFormat : TextFormat;
	function new(content : String = "", textName : String = null) {
		content = "";
		typewriting = false;
		normalTextFormat = new TextFormat();
		redTextFormat = new TextFormat();
		super(0, 0);
		this.content = content;
		if(textName != null)
			normalTextFormat.font = textName;
		normalTextFormat.size = 16;
		normalTextFormat.color = 0xFFFFFF;
		if(textName != null)
			redTextFormat.font = textName;
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
	}

	public function setSize(val : Float) : Float {
		normalTextFormat.size = val;
		redTextFormat.size = val;
		textField.defaultTextFormat = normalTextFormat;
		return val;
	}

	override public function setWidth(val : Float) : Float {
		textField.width = val;
		super.width = val;
		return val;
	}

	override public function setHeight(val : Float) : Float {
		textField.height = val;
		super.height = val;
		return val;
	}

	public function setColor(val : UInt) : UInt {
		textField.textColor = val;
		return val;
	}

	public function getColor() : UInt {
		return textField.textColor;
	}

	/*
    //TODO
    public function advanceOnKeypress(key:int):Text {
      listen(Hooks.keyRecentlyDown(key, advanceText));

      return this;
    }
    */	public function getText() : String {
		return textField.text;
	}

	// Interpolate the string by adding colors. Any words between *stars* are
		// colored red.
		public function setText(s : String) : String {
		var pairs : Array<Dynamic> = [];
		var currentPair : Array<Dynamic> = [];
		var idx : Int = 0;
		var resultString : String = "";
		var i : Int;
		i = 0;
		while(i < s.length) {
			idx++;
			if(s.charAt(i) == "*")  {
				idx--;
				currentPair.push(idx);
			}

			else  {
				resultString += s.charAt(i);
			}

			if(currentPair.length == 2)  {
				pairs.push(currentPair);
				currentPair = [];
			}
			i++;
		}
		textField.text = resultString;
		i = 0;
		while(i < pairs.length) {
			textField.setTextFormat(redTextFormat, pairs[i][0], pairs[i][1]);
			i++;
		}
		return s;
	}

	public function advanceText() : Void {
		if(typewriting)  {
			// TODO: Haven't done this yet.
			Util.assert(false);
		}

		else  {
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
			textField.appendText(that.content.charAt(counter));
			counter++;
		}
;
		listen(this.typewriteTick);
		return this;
	}

	override public function groups() : Set {
		return super.groups().concat("no-camera", "non-blocking");
	}

	override public function clearMemory() : Void {
		textField = null;
		content = null;
		typewriteTick = null;
		super.clearMemory();
	}

}

