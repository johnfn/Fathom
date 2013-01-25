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

  	stageWidth = Fathom.actualStage.stageWidth;
  	stageHeight = Fathom.actualStage.stageHeight;

  	// we just use this for width and height
  	var g: ReloadedGraphic = new ReloadedGraphic(url);

  	reloadedGraphics = [];

  	for (x in 0...Math.ceil(stageWidth / g.width)) {
	  	for (y in 0...Math.ceil(stageHeight / g.height)) {
	  		var bgTile: ReloadedGraphic = new ReloadedGraphic(url);
	  		reloadedGraphics.push(bgTile);
	  		bgTile.x = x * g.width;
	  		bgTile.y = y * g.height;

	  		addChild(bgTile);
	  	}
  	}
  }

  public override function update() {
  	for (g in reloadedGraphics) {
  		g.x += dx;
  		g.y += dy;

  		if (dx > 0 && g.x > stageWidth) {
  			g.x = (g.x % g.width) - g.width;
  		}
  	}
  }
}