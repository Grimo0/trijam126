package en;

class Entity {
	public static var ALL : Array<Entity> = [];
	public static var GC : Array<Entity> = [];

	// Shorthands properties
	public var game(get, never) : Game;
	inline function get_game() return Game.ME;
	public var ftime(get, never) : Float;
	inline function get_ftime() return Game.ME.ftime;
	public var utmod(get, never) : Float;
	inline function get_utmod() return Game.ME.utmod;
	public var tmod(get, never) : Float;
	inline function get_tmod() return Game.ME.tmod;
	public var hud(get, never) : ui.Hud;
	inline function get_hud() return Game.ME.hud;

	// Main properties
	public var uid(default, null) : Int;

	public var destroyed(default, null) = false;

	public var cd : dn.Cooldown;
	public var ucd : dn.Cooldown;

	// Base coordinates
	public var cx = 0;
	public var cy = 0;
	public var xr = 0.5;
	public var yr = 0.5;
	public var hei(default, set) : Float = Const.GRID;
	inline function set_hei(v) {
		invalidateDebugBounds = true;
		return hei = v;
	}
	public var wid(default, set) : Float = Const.GRID;
	inline function set_wid(v) {
		invalidateDebugBounds = true;
		return wid = v;
	}

	/** Inner radius in pixels (ie. smallest value between width/height, then divided by 2) **/
	public var innerRadius(get, never) : Float;
	inline function get_innerRadius() return M.fmin(wid, hei) * 0.5;

	/** "Large" radius in pixels (ie. biggest value between width/height, then divided by 2) **/
	public var largeRadius(get, never) : Float;
	inline function get_largeRadius() return M.fmax(wid, hei) * 0.5;

	// Velocities
	public var dx = 0.;
	public var dy = 0.;
	public var bdx = 0.;
	public var bdy = 0.;
	public var dxTotal(get, never) : Float;
	inline function get_dxTotal() return dx + bdx;
	public var dyTotal(get, never) : Float;
	inline function get_dyTotal() return dy + bdy;

	public var frictX = 0.82;
	public var frictY = 0.82;
	public var bumpFrict = 0.93;

	// Display
	public var spr : HSprite;
	public var baseColor : h3d.Vector;
	public var blinkColor : h3d.Vector;
	public var colorMatrix : h3d.Matrix;
	public var sprScaleX = 1.0;
	public var sprScaleY = 1.0;
	public var sprSquashX = 1.0; // Sprite X squash & stretch scaling, which automatically comes back to 1 after a few frames
	public var sprSquashY = 1.0; // Sprite Y squash & stretch scaling, which automatically comes back to 1 after a few frames

	public var visible = true;

	public var pivotX(default, set) : Float = 0.5; // Defines X alignment of entity at its attach point (0 to 1.0)
	public var pivotY(default, set) : Float = 0.5; // Defines Y alignment of entity at its attach point (0 to 1.0)

	/** Entity attach X pixel coordinate **/
	public var attachX(get, never) : Float; inline function get_attachX() return (cx + xr) * Const.GRID;
	/** Entity attach Y pixel coordinate **/
	public var attachY(get, never) : Float; inline function get_attachY() return (cy + yr) * Const.GRID;

	// Coordinates getters, for easier gameplay coding
	public var left(get, never) : Float; inline function get_left() return attachX + (0 - pivotX) * wid;
	public var right(get, never) : Float; inline function get_right() return attachX + (1 - pivotX) * wid;
	public var top(get, never) : Float; inline function get_top() return attachY + (0 - pivotY) * hei;
	public var bottom(get, never) : Float; inline function get_bottom() return attachY + (1 - pivotY) * hei;
	public var centerX(get, never) : Float; inline function get_centerX() return attachX + (0.5 - pivotX) * wid;
	public var centerY(get, never) : Float; inline function get_centerY() return attachY + (0.5 - pivotY) * hei;
	public var prevFrameattachX : Float = -Const.INFINITE;
	public var prevFrameattachY : Float = -Const.INFINITE;

	var actions : Array<{id : String, cb : Void->Void, t : Float}> = [];

	// Debug
	var debugLabel : Null<h2d.Text>;
	var debugBounds : Null<h2d.Graphics>;
	var invalidateDebugBounds = false;

	public function new(?sprLib : SpriteLib, ?x : Int, ?y : Int) {
		uid = Const.NEXT_UNIQ;
		ALL.push(this);

		cd = new dn.Cooldown(Const.FPS);
		ucd = new dn.Cooldown(Const.FPS);

		if (x != null && y != null)
			setPosCell(x, y);

		spr = new HSprite(sprLib);
		game.level.root.add(spr, Const.GAME_LEVEL_ENTITIES);
		spr.colorAdd = new h3d.Vector();
		baseColor = new h3d.Vector();
		blinkColor = new h3d.Vector();
		spr.colorMatrix = colorMatrix = h3d.Matrix.I();
		spr.setCenterRatio(pivotX, pivotY);

		if (ui.Console.ME.hasFlag("bounds"))
			enableBounds();
	}

	function set_pivotX(v) {
		pivotX = M.fclamp(v, 0, 1);
		if (spr != null)
			spr.setCenterRatio(pivotX, pivotY);
		return pivotX;
	}

	function set_pivotY(v) {
		pivotY = M.fclamp(v, 0, 1);
		if (spr != null)
			spr.setCenterRatio(pivotX, pivotY);
		return pivotY;
	}

	/** Quickly set X/Y pivots. If Y is omitted, it will be equal to X. **/
	public function setPivots(x : Float, ?y : Float) {
		pivotX = x;
		pivotY = y != null ? y : x;
	}

	public inline function isAlive() {
		return !destroyed;
	}

	public function setPosCell(x : Int, y : Int) {
		cx = x;
		cy = y;
		xr = 0.5;
		yr = 0.5;
		onPosManuallyChanged();
	}

	public function setPosPixel(x : Float, y : Float) {
		cx = Std.int(x / Const.GRID);
		cy = Std.int(y / Const.GRID);
		xr = (x - cx * Const.GRID) / Const.GRID;
		yr = (y - cy * Const.GRID) / Const.GRID;
		onPosManuallyChanged();
	}

	function onPosManuallyChanged() {
		if (M.dist(attachX, attachY, prevFrameattachX, prevFrameattachY) > Const.GRID * 2) {
			prevFrameattachX = attachX;
			prevFrameattachY = attachY;
		}
	}

	public function bump(x : Float, y : Float) {
		bdx += x;
		bdy += y;
	}

	public function cancelVelocities() {
		dx = bdx = 0;
		dy = bdy = 0;
	}

	public function is<T : Entity>(c : Class<T>) return Std.isOfType(this, c);

	public function as<T : Entity>(c : Class<T>) : T return Std.downcast(this, c);

	public inline function dirTo(e : Entity) return e.centerX < centerX ? -1 : 1;

	public inline function getMoveAng() return Math.atan2(dyTotal, dxTotal);

	public inline function distEntity(e : Entity)
		return M.dist(cx + xr, cy + yr, e.cx + e.xr, e.cy + e.yr);

	public inline function distCell(tcx : Int, tcy : Int, ?txr = 0.5, ?tyr = 0.5)
		return M.dist(cx + xr, cy + yr, tcx + txr, tcy + tyr);

	public inline function distPx(e : Entity)
		return M.dist(attachX, attachY, e.attachX, e.attachY);

	public inline function distPxFree(x : Float, y : Float)
		return M.dist(attachX, attachY, x, y);

	public inline function destroy() {
		if (!destroyed) {
			destroyed = true;
			GC.push(this);
		}
	}

	public function dispose() {
		ALL.remove(this);

		baseColor = null;
		blinkColor = null;
		colorMatrix = null;

		spr.remove();
		spr = null;

		if (debugLabel != null) {
			debugLabel.remove();
			debugLabel = null;
		}

		if (debugBounds != null) {
			debugBounds.remove();
			debugBounds = null;
		}

		cd.destroy();
		cd = null;
	}

	public inline function debug(?v : Dynamic, ?c = 0xffffff) {
		#if debug
		if (v == null && debugLabel != null) {
			debugLabel.remove();
			debugLabel = null;
		}
		if (v != null) {
			if (debugLabel == null) {
				debugLabel = new h2d.Text(Assets.fontTiny);
				game.level.root.add(debugLabel, Const.GAME_LEVEL_TOP);
			}
			debugLabel.text = Std.string(v);
			debugLabel.textColor = c;
		}
		#end
	}

	public function disableBounds() {
		if (debugBounds != null) {
			debugBounds.remove();
			debugBounds = null;
		}
	}

	public function enableBounds() {
		if (debugBounds == null) {
			debugBounds = new h2d.Graphics();
			game.level.root.add(debugBounds, Const.GAME_LEVEL_TOP);
		}
		invalidateDebugBounds = true;
	}

	function renderBounds() {
		var c = Color.makeColorHsl((uid % 20) / 20, 1, 1);
		debugBounds.clear();

		// Bounds rect
		debugBounds.lineStyle(1, c, 0.5);
		debugBounds.drawRect(left - attachX, top - attachY, wid, hei);

		// Attach point
		debugBounds.lineStyle(0);
		debugBounds.beginFill(c, 0.8);
		debugBounds.drawRect(-1, -1, 3, 3);
		debugBounds.endFill();

		// Center
		debugBounds.lineStyle(1, c, 0.3);
		debugBounds.drawCircle(centerX - attachX, centerY - attachY, 3);
	}

	function chargeAction(id : String, sec : Float, cb : Void->Void) {
		if (isChargingAction(id))
			cancelAction(id);
		if (sec <= 0)
			cb();
		else
			actions.push({id: id, cb: cb, t: sec});
	}

	public function isChargingAction(?id : String) {
		if (id == null)
			return actions.length > 0;

		for (a in actions)
			if (a.id == id)
				return true;

		return false;
	}

	public function cancelAction(?id : String) {
		if (id == null)
			actions = [];
		else {
			var i = 0;
			while (i < actions.length) {
				if (actions[i].id == id)
					actions.splice(i, 1);
				else
					i++;
			}
		}
	}

	function updateActions() {
		var i = 0;
		while (i < actions.length) {
			var a = actions[i];
			a.t -= tmod / Const.FPS;
			if (a.t <= 0) {
				actions.splice(i, 1);
				if (isAlive())
					a.cb();
			} else
				i++;
		}
	}

	public function blink(c : UInt) {
		blinkColor.setColor(c);
		cd.setS("keepBlink", 0.06);
	}

	public function setSquashX(v : Float) {
		sprSquashX = v;
		sprSquashY = 2 - v;
	}

	public function setSquashY(v : Float) {
		sprSquashX = 2 - v;
		sprSquashY = v;
	}

	public function preUpdate() {
		ucd.update(utmod);
		cd.update(tmod);
		updateActions();
	}

	public function postUpdate() {
		spr.x = (cx + xr) * Const.GRID;
		spr.y = (cy + yr) * Const.GRID;
		spr.scaleX = sprScaleX * sprSquashX;
		spr.scaleY = sprScaleY * sprSquashY;
		spr.visible = visible;

		sprSquashX += (1 - sprSquashX) * 0.2;
		sprSquashY += (1 - sprSquashY) * 0.2;

		// Blink
		if (!cd.has("keepBlink")) {
			blinkColor.r *= Math.pow(0.60, tmod);
			blinkColor.g *= Math.pow(0.55, tmod);
			blinkColor.b *= Math.pow(0.50, tmod);
		}

		// Color adds
		spr.colorAdd.load(baseColor);
		spr.colorAdd.r += blinkColor.r;
		spr.colorAdd.g += blinkColor.g;
		spr.colorAdd.b += blinkColor.b;

		// Debug label
		if (debugLabel != null) {
			debugLabel.x = Std.int(attachX - debugLabel.textWidth * 0.5);
			debugLabel.y = Std.int(attachY + 1);
		}

		// Debug bounds
		if (debugBounds != null) {
			if (invalidateDebugBounds) {
				invalidateDebugBounds = false;
				renderBounds();
			}
			debugBounds.x = Std.int(attachX);
			debugBounds.y = Std.int(attachY);
		}
	}

	public function finalUpdate() {
		prevFrameattachX = attachX;
		prevFrameattachY = attachY;
	}

	public function fixedUpdate() {}

	public function update() {
		// X
		var steps = M.ceil(M.fabs(dxTotal * tmod));
		var step = dxTotal * tmod / steps;
		while (steps > 0) {
			xr += step;

			// [ TODO add X collisions checks here ]

			while (xr > 1) {
				xr--;
				cx++;
			}
			while (xr < 0) {
				xr++;
				cx--;
			}
			steps--;
		}
		dx *= Math.pow(frictX, tmod);
		bdx *= Math.pow(bumpFrict, tmod);
		if (M.fabs(dx) <= 0.0005 * tmod) dx = 0;
		if (M.fabs(bdx) <= 0.0005 * tmod) bdx = 0;

		// Y
		var steps = M.ceil(M.fabs(dyTotal * tmod));
		var step = dyTotal * tmod / steps;
		while (steps > 0) {
			yr += step;

			// [ TODO add Y collisions checks here ]

			while (yr > 1) {
				yr--;
				cy++;
			}
			while (yr < 0) {
				yr++;
				cy--;
			}
			steps--;
		}
		dy *= Math.pow(frictY, tmod);
		bdy *= Math.pow(bumpFrict, tmod);
		if (M.fabs(dy) <= 0.0005 * tmod) dy = 0;
		if (M.fabs(bdy) <= 0.0005 * tmod) bdy = 0;

		#if debug
		if (ui.Console.ME.hasFlag("bounds") && debugBounds == null)
			enableBounds();

		if (!ui.Console.ME.hasFlag("bounds") && debugBounds != null)
			disableBounds();
		#end
	}
}
