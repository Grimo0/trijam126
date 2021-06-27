class Level extends dn.Process {
	var game(get, never) : Game; inline function get_game() return Game.ME;

	public var gridSize(get, never) : Int;
	inline function get_gridSize() return Const.GRID;

	public var cWid(get, never) : Int; inline function get_cWid() return Std.int(pxWid / Const.GRID);
	public var cHei(get, never) : Int; inline function get_cHei() return Std.int(pxHei / Const.GRID);
	public var pxWid(get, never) : Int; inline function get_pxWid() return game.pxWid;
	public var pxHei(get, never) : Int; inline function get_pxHei() return game.pxHei;

	public var bgCols = new Array<h2d.Bitmap>();

	public function new() {
		super(game);
		createRootInLayers(game.scroller, Const.GAME_SCROLLER_LEVEL);
	}

	public inline function isValid(cx, cy) return cx >= 0 && cx < cWid && cy >= 0 && cy < cHei;

	public inline function coordId(cx, cy) return cx + cy * cWid;

	public inline function hasCollision(cx, cy) : Bool
		return false; // TODO: collision with entities and obstacles

	public inline function getFloor(cx, cy) : Int
		return 0;

	override function init() {
		super.init();

		if (root != null)
			initLevel();
	}

	public function initLevel() {
		game.scroller.add(root, Const.GAME_SCROLLER_LEVEL);
		root.removeChildren();
		
		initBgCol();
	}

	public function initBgCol() {
		var nbCol = bgCols.length > 2 ? M.ceil(bgCols.length / 2) : bgCols.length;
		var nbRow = bgCols.length > 2 ? 2 : 1;
		var bgColW = M.ceil(pxWid / nbCol);
		var bgColH = M.ceil(pxHei / nbRow);
		var bgColX = 0.;
		var bgColY = 0.;
		var col = 0;
		for (c in bgCols) {
			c.width = bgColW;
			c.height = bgColH;
			c.x = bgColX;
			c.y = bgColY;
			if (col >= nbCol - 1) {
				col = 0;
				bgColX = 0;
				bgColY += bgColH;
			} else {
				col++;
				bgColX += bgColW;
			}
			root.addChildAt(c, Const.GAME_LEVEL_BG);
		}
	}

	override function onResize() {
		super.onResize();
		initBgCol();
	}
}
