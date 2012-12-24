class Tile extends Entity {

    var type : Int;
    var SIZE : Int;
    function new(x : Int = 0, y : Int = 0, type : Int = 0) {
        SIZE = C.size;
        super(x, y, SIZE, SIZE);
    }

}

