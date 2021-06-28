import ui.EndGameMenu;
import en.Character;
import en.Entity;
import dn.Process;

class Game extends Process {
	public static var ME : Game;

	public static var sav : GameSave = new GameSave();

	/** Game controller (pad or keyboard) **/
	public var ca : dn.heaps.Controller.ControllerAccess;

	/** Particles **/
	public var fx : Fx;

	/** Basic viewport control **/
	public var camera : Camera;

	/** Container of all visual game objects. Ths wrapper is moved around by Camera. **/
	public var scroller : h2d.Layers;

	/** Level data **/
	public var level : Level;

	/** UI **/
	public var hud : ui.Hud;

	public var locked(default, set) = false;
	public function set_locked(l) {
		if (l)
			ca.lock();
		else
			ca.unlock();
		return locked = l;
	}

	public var pxWid(get, never) : Int;
	function get_pxWid() return M.ceil(w() / Const.SCALE);

	public var pxHei(get, never) : Int;
	function get_pxHei() return M.ceil(h() / Const.SCALE);

	public var curGameSpeed(default, null) = 1.0;
	var slowMos : Map<String, {id : String, t : Float, f : Float}> = new Map();

	var flags : Map<String, Int> = new Map();

	public var chars : Array<Character> = new Array();
	final charColors = [0x61ad52, 0xff0076, 0xffd700, 0x07a0da, 0xb60c25, 0xb8e5ff, 0x8507da, 0xb700ff];
	public var giver : Character;
	public var receiver : Character;
	public var syringe : Syringe;

	var difficulty(default, set) = 0;
	public function set_difficulty(d) {
		if (d != difficulty) {
			if (d > chars.length) d = chars.length;
			for (i in d...difficulty)
				level.bgCols[i].remove();
			level.bgCols.resize(d);
			for (i in difficulty...d)
				level.bgCols[i] = new h2d.Bitmap(h2d.Tile.fromColor(0xffffff));
			level.initBgCol();
		}
		return difficulty = d;
	}

	public function new() {
		super(Main.ME);
		ME = this;

		flags = sav.flags.copy();
		ca = Main.ME.controller.createAccess("game");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);

		createRootInLayers(Main.ME.root, Const.MAIN_LAYER_GAME);

		scroller = new h2d.Layers();
		root.add(scroller, Const.GAME_SCROLLER);

		camera = new Camera();
		camera.frict = 0.1;
		camera.targetS = 0.1;
		level = new Level();
		fx = new Fx();
		hud = new ui.Hud();

		for (i in 1...9)
			chars.push(new Character('Char$i'));

		// hxd.System.setNativeCursor(Custom(new hxd.Cursor.CustomCursor([hxd.Res.textures.fxCircle0.toBitmap()], 0, 0, 0)));
		syringe = new Syringe();
		syringe.visible = false;
		root.addChildAt(syringe, Const.GAME_CURSOR);

		function onCursorMove(event : hxd.Event) {
			if (isPaused()) return;
			if (syringe.state != null) {
				if (event.kind == ERelease)
					syringe.state = null;
				return;
			}
			if (event.kind != EMove || syringe.state != null) return;

			var cursorSize = syringe.getSize();
			syringe.x = event.relX;
			syringe.y = event.relY - cursorSize.height / 2;
			if (syringe.scaleX < 0 && syringe.x <  1.5 * cursorSize.width)
				syringe.scaleX = -syringe.scaleX;
			else if (syringe.scaleX > 0 && syringe.x > pxWid -  1.5 * cursorSize.width)
				syringe.scaleX = -syringe.scaleX;
		}
		hxd.Window.getInstance().addEventTarget(onCursorMove);

		// Hide Cursor
		hxd.System.setCursor = (c) -> {
			if (!syringe.visible || ui.Modal.hasAny()) {
				hxd.System.setNativeCursor(Default);
			} else {
				hxd.System.setNativeCursor(Hide);
			}
		};

		root.alpha = 0;
		start();
		tw.createS(root.alpha, 1, #if debug 0 #else 1 #end);
	}

	public static function load() {
		sav = hxd.Save.load(sav, 'save/game');
	}

	public function save() {
		sav.flags = flags.copy();

		hxd.Save.save(sav, 'save/game');
	}

	public inline function setFlag(k : String, ?v = 1) flags.set(k, v);

	public inline function unsetFlag(k : String) flags.remove(k);

	public inline function hasFlag(k : String) return getFlag(k) != 0;

	public inline function getFlag(k : String) {
		var f = flags.get(k);
		return f != null ? f : 0;
	}

	public function getRndCharIdx(?notThem : Array<Character>) {
		if (notThem == null)
			return M.rand(chars.length);

		var rnd = M.rand(chars.length - notThem.length);
		var i = 0;
		while (i <= rnd) {
			for (nC in notThem) {
				if (chars[i] == nC) {
					rnd++;
					break;
				}
			}
			i++;
		}
		return rnd;
	}

	public function isComplete() : Bool {
		for (c in chars) {
			if (!c.visible) continue;
			if (c.state == Sad) return false;
		}
		return true;
	}

	public inline function checkComplete() {
		if (isComplete()) success();
	}

	function start() {
		locked = false;

		difficulty = 2;
		syringe.reset();

		scroller.removeChildren();

		level.init();

		for (c in chars) {
			c.visible = false;
			level.root.add(c, Const.GAME_LEVEL_ENTITIES);
		}

		transition();

		resume();
		Process.resizeAll();
	}

	function startDonation() {
		var notThem = new Array<Character>();
		for (c in chars) {
			c.visible = false;
			c.setScale(1);
		}
		giver = null;
		receiver = null;

		var nbReceiver = Std.int(difficulty / 2);
		var nbGiver = difficulty - nbReceiver;
		var charScales = 1.;
		var maxWidth = level.bgCols[0].width - 40;
		var maxHeight = level.bgCols[0].height - 40;
		for (i in 0...difficulty) {
			var bgCol = level.bgCols[i];

			var idx = getRndCharIdx(notThem);
			var c = chars[idx];
			var cSize = c.getSize();
			if (cSize.width > maxWidth || cSize.height > maxHeight) {
				charScales = M.fmin(maxWidth / cSize.width, maxHeight / cSize.height);
				c.setScale(charScales);
			}
			c.x = bgCol.x + (bgCol.width - cSize.width * c.scaleX) / 2;
			c.y = bgCol.y + (bgCol.height - cSize.height * c.scaleX) / 2;
			c.visible = true;
			notThem.push(c);

			if (M.rand(nbReceiver + nbGiver) < nbReceiver) {
				c.state = Sad;
				nbReceiver--;
			} else {
				c.state = Happy;
				nbGiver--;
			}

			bgCol.color.setColor(0xff << 24 | charColors[idx]);
		}
		syringe.setScale(charScales);
	}

	public function gameOver() {
		locked = true;
		new ui.EndGameMenu(true);
		delayer.addF(start, 1);
	}

	public function success() {
		locked = true;
		if (difficulty == chars.length) {
			new ui.EndGameMenu(false, true);
			delayer.addF(start, 1);
		} else {
			new ui.EndGameMenu(false);
			delayer.addF(() -> {
				transition(() -> difficulty += 2);
			}, 1);
		}
	}

	public function transition(event : String = null, ?onDone : Void->Void) {
		locked = true;

		Main.ME.tw.createS(root.alpha, 0, #if debug 0 #else .3 #end).onEnd = function() {
			if (onDone != null)
				onDone();

			startDonation();
			locked = false;
			Main.ME.tw.createS(root.alpha, 1, #if debug 0 #else .3 #end);
		}
	}

	/** CDB file changed on disk**/
	public function onCdbReload() {}

	/** Window/app resize event **/
	override function onResize() {
		super.onResize();
		scroller.setScale(Const.SCALE);
	}

	override function onDispose() {
		super.onDispose();

		fx.destroy();
		for (e in Entity.ALL)
			e.destroy();
		gc();
	}

	/** Garbage collect any Entity marked for destruction **/
	function gc() {
		if (Entity.GC == null || Entity.GC.length == 0)
			return;

		for (e in Entity.GC)
			e.dispose();
		Entity.GC = [];
	}

	public function addSlowMo(id : String, sec : Float, speedFactor = 0.3) {
		if (slowMos.exists(id)) {
			var s = slowMos.get(id);
			s.f = speedFactor;
			s.t = M.fmax(s.t, sec);
		} else
			slowMos.set(id, {id: id, t: sec, f: speedFactor});
	}

	function updateSlowMos() {
		// Timeout active slow-mos
		for (s in slowMos) {
			s.t -= utmod * 1 / Const.FPS;
			if (s.t <= 0)
				slowMos.remove(s.id);
		}

		// Update game speed
		var targetGameSpeed = 1.0;
		for (s in slowMos)
			targetGameSpeed *= s.f;
		curGameSpeed += (targetGameSpeed - curGameSpeed) * (targetGameSpeed > curGameSpeed ? 0.2 : 0.6);

		if (M.fabs(curGameSpeed - targetGameSpeed) <= 0.001)
			curGameSpeed = targetGameSpeed;
	}

	public inline function stopFrame() {
		ucd.setS("stopFrame", 0.2);
	}

	override function preUpdate() {
		super.preUpdate();

		for (e in Entity.ALL)
			if (!e.destroyed)
				e.preUpdate();
	}

	/** Main loop but limited to 30fps (so it might not be called during some frames) **/
	override function fixedUpdate() {
		super.fixedUpdate();

		for (e in Entity.ALL)
			if (!e.destroyed)
				e.fixedUpdate();
	}

	/** Main loop **/
	override function update() {
		super.update();

		for (e in Entity.ALL)
			if (!e.destroyed)
				e.update();

		#if debug
		if (Main.ME.debug) {
			updateImGui();
		}
		#end

		if (!ui.Console.ME.isActive() && !ui.Modal.hasAny()) {
			#if hl
			// Exit
			if (ca.isPressed(START)) {
				if (cd.hasSetS("exitWarn", 3))
					return Main.ME.startMainMenu();
			}
			#end

			// Restart
			if (ca.selectPressed())
				Main.ME.startGame();
		}
	}

	#if debug
	function updateImGui() {
		var natArray = new hl.NativeArray<Single>(1);

		natArray[0] = Const.MAX_CELLS_PER_WIDTH;
		if (ImGui.sliderFloat('Const.MAX_CELLS_PER_WIDTH', natArray, -1, 100, '%.0f')) {
			Const.MAX_CELLS_PER_WIDTH = Std.int(natArray[0]);
			scroller.setScale(Const.SCALE);
		}

		natArray[0] = difficulty;
		if (ImGui.sliderFloat('Difficulty', natArray, 2, chars.length, '%.0f')) {
			difficulty = Std.int(natArray[0]);
			startDonation();
		}

		ImGui.alignTextToFramePadding();
		ImGui.text('Scroller');
		ImGui.sameLine(0, 5);
		ImGui.pushItemWidth(ImGui.getColumnWidth() / 4);
		natArray[0] = scroller.x;
		if (ImGui.sliderFloat('##x', natArray, 0, pxWid, 'x %.0f'))
			scroller.x = natArray[0];
		ImGui.sameLine(0, 2);
		natArray[0] = scroller.y;
		if (ImGui.sliderFloat('##y', natArray, 0, pxHei, 'y %.0f'))
			scroller.y = natArray[0];
		ImGui.sameLine(0, 2);
		natArray[0] = scroller.scaleX;
		if (ImGui.sliderFloat('##scalex', natArray, 0, 2, 'sX %.2f'))
			scroller.scaleX = natArray[0];
		ImGui.sameLine(0, 2);
		natArray[0] = scroller.scaleY;
		if (ImGui.sliderFloat('##scaley', natArray, 0, 2, 'sY %.2f'))
			scroller.scaleY = natArray[0];
		ImGui.popItemWidth();
	}
	#end

	override function postUpdate() {
		super.postUpdate();

		for (e in Entity.ALL)
			if (!e.destroyed)
				e.postUpdate();
		for (e in Entity.ALL)
			if (!e.destroyed)
				e.finalUpdate();
		gc();

		// Update slow-motions
		updateSlowMos();
		setTimeMultiplier((0.2 + 0.8 * curGameSpeed) * (ucd.has("stopFrame") ? 0.3 : 1));
	}
}
