package fathom;

class Mode {
  public var modes: Array<Int>;

  public function new() {
  	modes = [0];
  }

  public var currentMode(getCurrentMode, never) : Int;

  public function getCurrentMode() : Int {
      return modes[modes.length - 1];
  }

  // TODO this stuff should go in Mode.as
  public function pushMode(mode : Int) : Void {
      modes.push(mode);
  }

  public function popMode() : Void {
      modes.pop();
  }

  public function replaceMode(mode : Int) : Void {
      modes[modes.length - 1] = mode;
  }
}