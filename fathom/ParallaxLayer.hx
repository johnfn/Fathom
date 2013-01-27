package fathom;

import fathom.ReloadedGraphic;

using Lambda;

class ParallaxLayer extends Entity {
	var reloadedGraphics: Array<ReloadedGraphic>;
	var stageWidth: Int;
	var stageHeight: Int;

	public var dx: Int = -2;
	public var dy: Int = 0;

  var widthOfTiles: Float = 0;
  var heightOfTiles: Float = 0;

  public function new(url: String) {
  	super(0, 0);

  	stageWidth = Fathom.actualStage.stageWidth;
  	stageHeight = Fathom.actualStage.stageHeight;

  	// we just use this for width and height
  	var g: ReloadedGraphic = new ReloadedGraphic(url);

    var tilesWide: Int = Math.ceil(stageWidth / g.width) + 1;
    var tilesHigh: Int = Math.ceil(stageHeight / g.height) + 1;

  	reloadedGraphics = [];

  	for (x in 0...(tilesWide + 1)) {
	  	for (y in 0...(tilesHigh + 1)) {
	  		var bgTile: ReloadedGraphic = new ReloadedGraphic(url);
	  		reloadedGraphics.push(bgTile);
	  		bgTile.x = x * g.width;
	  		bgTile.y = y * g.height;

	  		addChild(bgTile);
	  	}
  	}

    widthOfTiles = g.width * tilesWide;
    heightOfTiles = g.height * tilesHigh;
  }

  public override function update() {
  	for (g in reloadedGraphics) {
  		g.x += dx;
  		g.y += dy;

  		if (dx > 0 && g.x > stageWidth) {
  			g.x -= widthOfTiles;
  		}

      if (dx < 0 && g.x + g.width < 0) {
        g.x += widthOfTiles;
      }
  	}
  }

  public override function groups():Set<String> {
    return super.groups().add("non-blocking");
  }
}