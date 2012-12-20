interface IPositionable {
	var x(getX, never) : Float;
	var y(getY, never) : Float;

	function getX() : Float;
	function getY() : Float;
	//function add(v:IPositionable):IPositionable;
	}

