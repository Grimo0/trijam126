class Level extends dn.Process {
	var game(get, never) : Game; inline function get_game() return Game.ME;

	public var currLevel(default, set) : LDtkMap.LDtkMap_Level;
	public function set_currLevel(l : LDtkMap.LDtkMap_Level) {
		currLevel = l;
		Const.GRID = gridSize;
		initLevel();
		return currLevel;
	}

	public var gridSize(get, never) : Int;
	inline function get_gridSize() return currLevel.l_Floor.gridSize;

	public var cWid(get, never) : Int; inline function get_cWid() return currLevel.l_Floor.cWid;
	public var cHei(get, never) : Int; inline function get_cHei() return currLevel.l_Floor.cHei;
	public var pxWid(get, never) : Int; inline function get_pxWid() return currLevel.pxWid;
	public var pxHei(get, never) : Int; inline function get_pxHei() return currLevel.pxHei;

	public function new() {
		super(game);
		createRootInLayers(game.scroller, Const.GAME_SCROLLER_LEVEL);
	}

	public inline function isValid(cx, cy) return cx >= 0 && cx < cWid && cy >= 0 && cy < cHei;

	public inline function coordId(cx, cy) return cx + cy * cWid;

	public inline function hasCollision(cx, cy) : Bool
		return false; // TODO: collision with entities and obstacles

	public inline function getFloor(cx, cy) : Int
		return currLevel.l_Floor.getInt(cx, cy);

	override function init() {
		super.init();

		if (root != null)
			initLevel();
	}

	public function initLevel() {
		game.scroller.add(root, Const.GAME_SCROLLER_LEVEL);
		root.removeChildren();

		// Get level background image
		if (currLevel.hasBgImage()) {
			var background = currLevel.getBgBitmap();
			root.add(background, Const.GAME_LEVEL_BG);
		}
		
		// TODO Level loading & rendering
	}

	override function onResize() {
		if (currLevel == null)
			return;
		super.onResize();
	}

	public function render() {}

	override function postUpdate() {
		super.postUpdate();

		render();
	}
}
