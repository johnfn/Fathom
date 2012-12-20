package {
  public class Tile extends Entity {
    private var type:int;
    private const SIZE:int = C.size;

    function Tile(x:int=0, y:int=0, type:int=0) {
      super(x, y, SIZE, SIZE);
    }
  }
}
