package fathom;

import fathom.ReloadedGraphic;

using Lambda;

class ParallaxLayer extends Entity {
	var reloadedGraphics: Array<ReloadedGraphic>;
	var stageWidth: Int;
	var stageHeight: Int;

	public var dx: Int = 2;
	public var dy: Int = 0;

  public function new(url: String) {
  	super(0, 0);

  	reloadedGraphics = [new ReloadedGraphic(url)];
  }

  public override function update() {
  	// remove graphics completely out of the window
  	// ensure window is covered...somehow

  	for (g in reloadedGraphics) {
  		g.x += dx;
  		g.y += dy;
  	}

  	// Remove every graphic off the side of the screen
  	reloadedGraphics.filter(function(g: ReloadedGraphic): Bool {
  		if (g.x > stageWidth  || g.y > stageHeight) return false;
  		if (g.x + g.width < 0 || g.y + g.height < 0) return false;

  		return true;
  	});
  }
}

