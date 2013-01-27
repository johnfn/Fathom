package fathom;

class Mode {
  public var modes: Array<Int>;

  public function new() {
  	modes = [0];
  }

  public var currentMode(getCurrentMode, never) : Int;

  function getCurrentMode() : Int {
      return modes[modes.length - 1];
  }

  public function push(mode: Int) : Void {
      modes.push(mode);
  }

  public function pop() : Void {
      modes.pop();
  }

  public function replace(mode: Int) : Void {
      modes[modes.length - 1] = mode;
  }
}