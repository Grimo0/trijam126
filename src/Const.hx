class Const {
	public static inline var FPS = 30;
	public static inline var FIXED_FPS = 30;
	public static inline var INFINITE = 999999;
	public static var SCALE_AUTO_CWID(default, set) = -1; // -1 to disable auto-scaling on width
	static inline function set_SCALE_AUTO_CWID(s) {
		SCALE_AUTO_CWID = s;
		update_SCALE();
		return SCALE_AUTO_CWID;
	}
	public static var SCALE_AUTO_CHEI(default, set) = -1; // -1 to disable auto-scaling on height
	static inline function set_SCALE_AUTO_CHEI(s) {
		SCALE_AUTO_CHEI = s;
		update_SCALE();
		return SCALE_AUTO_CHEI;
	}
	public static var SCALE = 1.0; // ignored if auto-scaling
	public static var UI_SCALE = 1.0; // ignored if auto-scaling

	public static var GRID(default, set) = 64.;
	static inline function set_GRID(s) {
		GRID = s;
		update_SCALE();
		return GRID;
	}
	public static var MAX_CELLS_PER_WIDTH(default, set) = -1;
	static inline function set_MAX_CELLS_PER_WIDTH(s) {
		MAX_CELLS_PER_WIDTH = s;
		update_SCALE();
		return MAX_CELLS_PER_WIDTH;
	}
	public static var MAX_CELLS_PER_HEIGHT(default, set) = 8;
	static inline function set_MAX_CELLS_PER_HEIGHT(s) {
		MAX_CELLS_PER_HEIGHT = s;
		update_SCALE();
		return MAX_CELLS_PER_HEIGHT;
	}

	/** Viewport scaling **/
	static public function update_SCALE() {
		if (MAX_CELLS_PER_WIDTH > 0)
			SCALE = dn.heaps.Scaler.getViewportWidth() / (MAX_CELLS_PER_WIDTH * GRID);
		else if (MAX_CELLS_PER_HEIGHT > 0)
			SCALE = dn.heaps.Scaler.getViewportHeight() / (MAX_CELLS_PER_HEIGHT * GRID);
		else if (SCALE_AUTO_CWID > 0)
			SCALE = M.ceil(dn.heaps.Scaler.getViewportWidth() / SCALE_AUTO_CWID);
		else if (SCALE_AUTO_CHEI > 0)
			SCALE = M.ceil(dn.heaps.Scaler.getViewportHeight() / SCALE_AUTO_CHEI);
		else
			// can be replaced with another way to determine the game scaling
			SCALE = dn.heaps.Scaler.bestFit_i(1280, 720);
	}

	/** Specific scaling for top UI elements **/
	static public function update_UI_SCALE() {
		// can be replaced with another way to determine the UI scaling
		UI_SCALE = SCALE;
	}

	/** Unique value generator **/
	public static var NEXT_UNIQ(get, never) : Int; static inline function get_NEXT_UNIQ() return _uniq++;
	static var _uniq = 0;

	/** Game layers indexes **/
	static var _inc = 0;
	public static var MAIN_LAYER_GAME = _inc++;
	public static var MAIN_LAYER_UI = _inc++;

	public static var GAME_SCROLLER = _inc = 0;
	public static var GAME_DEBUG = _inc++;
	public static var GAME_CINEMATIC = _inc++;

	public static var GAME_SCROLLER_LEVEL = _inc = 0;
	public static var GAME_SCROLLER_FX_BG = _inc++;
	public static var GAME_SCROLLER_FX_FRONT = _inc++;

	public static var GAME_LEVEL_BG = _inc = 0;
	public static var GAME_LEVEL_FLOOR = _inc++;
	public static var GAME_LEVEL_ENTITIES = _inc++;
	public static var GAME_LEVEL_CEILING = _inc++;
	public static var GAME_LEVEL_TOP = _inc++;
}
