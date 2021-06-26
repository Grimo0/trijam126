import en.Entity;

class Camera extends dn.Process {
	var game(get, never) : Game; inline function get_game() return Game.ME;

	/** Camera focus coord in level pixels. This is the raw camera location: the displayed camera location might be clamped to level bounds. **/
	public var focus : LPoint;

	var target : Null<Entity>;

	/** Width of viewport in level pixels **/
	public var pxWid(get, never) : Int;
	function get_pxWid() return M.ceil(game.w() / Const.SCALE);

	/** Height of viewport in level pixels **/
	public var pxHei(get, never) : Int;
	function get_pxHei() return M.ceil(game.h() / Const.SCALE);

	public var frict = 0.89;
	public var bumpFrict = 0.75;
	public var targetS = 0.006;
	public var targetDeadZone = 5;

	var dx : Float;
	var dy : Float;
	var bumpOffX = 0.;
	var bumpOffY = 0.;

	var shakePower = 1.0;

	/** If TRUE (default), the camera will try to stay inside level bounds. It cannot be done if level is smaller than actual viewport. In such case, the camera will be centered. **/
	public var clampToLevelBounds = true;

	/** Left camera bound in level pixels **/
	public var left(get, never) : Int;
	inline function get_left() return M.imax(M.floor(focus.levelX - pxWid * 0.5), clampToLevelBounds ? 0 : -Const.INFINITE);

	/** Right camera bound in level pixels **/
	public var right(get, never) : Int;
	inline function get_right() return left + pxWid - 1;

	/** Upper camera bound in level pixels **/
	public var top(get, never) : Int;
	inline function get_top() return M.imax(M.floor(focus.levelY - pxHei * 0.5), clampToLevelBounds ? 0 : -Const.INFINITE);

	/** Lower camera bound in level pixels **/
	public var bottom(get, never) : Int;
	inline function get_bottom() return top + pxHei - 1;

	public function new() {
		super(game);
		focus = LPoint.fromCase(0, 0);
		dx = dy = 0;
		apply();
	}

	@:keep
	override function toString() {
		return 'Camera@${focus.levelX},${focus.levelY}';
	}

	public function trackTarget(e : Entity, immediate : Bool) {
		target = e;
		if (immediate)
			recenter();
	}

	public inline function stopTracking() {
		target = null;
	}

	public function recenter() {
		if (target != null) {
			focus.levelX = target.centerX;
			focus.levelY = target.centerY;
		}
	}

	public inline function scrollerToGlobalX(v : Float) return v * game.scroller.scaleX + game.scroller.x;

	public inline function scrollerToGlobalY(v : Float) return v * game.scroller.scaleY + game.scroller.y;

	public function shakeS(t : Float, ?pow = 1.0) {
		cd.setS("shaking", t, false);
		shakePower = pow;
	}

	public inline function bumpAng(a, dist) {
		bumpOffX += Math.cos(a) * dist;
		bumpOffY += Math.sin(a) * dist;
	}

	public inline function bump(x, y) {
		bumpOffX += x;
		bumpOffY += y;
	}

	/** Apply camera values to Game scroller **/
	function apply() {
		var level = game.level;
		var scroller = game.scroller;

		// Update scroller
		if (!clampToLevelBounds || pxWid < level.pxWid)
			scroller.x = -focus.levelX + pxWid * 0.5;
		else
			scroller.x = pxWid * 0.5 - level.pxWid * 0.5;

		if (!clampToLevelBounds || pxHei < level.pxHei)
			scroller.y = -focus.levelY + pxHei * 0.5;
		else
			scroller.y = pxHei * 0.5 - level.pxHei * 0.5;

		// Clamp
		if (clampToLevelBounds) {
			if (pxWid < level.pxWid)
				scroller.x = M.fclamp(scroller.x, pxWid - level.pxWid, 0);
			if (pxHei < level.pxHei)
				scroller.y = M.fclamp(scroller.y, pxHei - level.pxHei, 0);
		}

		// Bumps friction
		bumpOffX *= Math.pow(bumpFrict, tmod);
		bumpOffY *= Math.pow(bumpFrict, tmod);

		// Bump
		scroller.x += bumpOffX;
		scroller.y += bumpOffY;

		// Shakes
		if (cd.has("shaking")) {
			scroller.x += Math.cos(ftime * 1.1) * 2.5 * shakePower * cd.getRatio("shaking");
			scroller.y += Math.sin(0.3 + ftime * 1.7) * 2.5 * shakePower * cd.getRatio("shaking");
		}

		// Scaling
		scroller.x *= Const.SCALE;
		scroller.y *= Const.SCALE;

		// Rounding
		scroller.x = M.round(scroller.x);
		scroller.y = M.round(scroller.y);
	}

	override function update() {
		super.update();

		// Follow target entity
		if (target != null) {
			var tx = target.centerX;
			var ty = target.centerY;

			var d = focus.distPx(tx, ty);
			if (d >= targetDeadZone) {
				var a = focus.angTo(tx, ty);
				dx += Math.cos(a) * (d - targetDeadZone) * targetS * tmod;
				dy += Math.sin(a) * (d - targetDeadZone) * targetS * tmod;
			}
		}

		focus.levelX += dx * tmod;
		dx *= Math.pow(frict, tmod);

		focus.levelY += dy * tmod;
		dy *= Math.pow(frict, tmod);
	}

	override function postUpdate() {
		super.postUpdate();

		if (!ui.Console.ME.hasFlag("scroll"))
			apply();
	}
}
