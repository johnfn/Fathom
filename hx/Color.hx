import Util;

class Color {

	public var r : Int;
	public var g : Int;
	public var b : Int;
	public var a : Int;

	public function new(r : Int = 0, g : Int = 0, b : Int = 0, a : Int = 255) {
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}

	function zeroPad(str : String, padLength : Int = 2) : String {
		while(str.length < padLength) {
			str = "0" + str;
		}

		return str;
	}

	public function toString() : String {
		return "#" + zeroPad(StringTools.hex(r)) + zeroPad(StringTools.hex(g)) + zeroPad(StringTools.hex(b));
	}

	static public function fromInt(hex : Int) : Color {
		var r : Int = ((hex & 0xFF0000) >> 16);
		var g : Int = ((hex & 0x00FF00) >> 8);
		var b : Int = ((hex & 0x0000FF));
		return new Color(r, g, b);
	}

	public function read(s : String) : Color {
		s = s.substring(1);
		r = Std.parseInt("0x" + s.substring(0, 2));
		g = Std.parseInt("0x" + s.substring(2, 4));
		b = Std.parseInt("0x" + s.substring(4, 6));
		return this;
	}

	public function eq(c : Color) : Bool {
		return r == c.r && g == c.g && b == c.b && a == c.a;
	}

	public function toInt() : UInt {
		return Std.parseInt("0x" + toString().substring(1));
	}

	public function randomizeRed(low : Int = 0, high : Int = 255) : Color {
		r = Util.randRange(low, high);
		return this;
	}

	public function randomizeGreen(low : Int = 0, high : Int = 255) : Color {
		g = Util.randRange(low, high);
		return this;
	}

	public function randomizeBlue(low : Int = 0, high : Int = 255) : Color {
		b = Util.randRange(low, high);
		return this;
	}

}

