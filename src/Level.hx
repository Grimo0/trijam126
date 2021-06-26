class Level extends dn.Process {
	var game(get, never) : Game; inline function get_game() return Game.ME;

	public var gridSize(get, never) : Int;
	inline function get_gridSize() return Const.GRID;

	public var cWid(get, never) : Int; inline function get_cWid() return Std.int(pxWid / Const.GRID);
	public var cHei(get, never) : Int; inline function get_cHei() return Std.int(pxHei / Const.GRID);
	public var pxWid(get, never) : Int; inline function get_pxWid() return game.pxWid;
	public var pxHei(get, never) : Int; inline function get_pxHei() return game.pxHei;

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
	}
}
