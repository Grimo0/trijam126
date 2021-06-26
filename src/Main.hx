import ui.MainMenu;
import hxd.Key;

class Main extends dn.Process {
	public static var ME : Main;

	/** Used to create "Access" instances that allow controller checks (keyboard or gamepad) **/
	public var controller : dn.heaps.Controller;

	/** Controller Access created for Main & Boot **/
	public var ca : dn.heaps.Controller.ControllerAccess;

	public var debug = false;

	public function new(s : h2d.Scene) {
		super();
		ME = this;

		createRoot(s);

		// Engine settings
		hxd.Timer.wantedFPS = Const.FPS;
		engine.backgroundColor = 0xff << 24 | 0x000000;
		#if (hl && !debug)
		engine.fullScreen = true;
		#end

		#if hl
		sys.FileSystem.createDirectory('save');
		#end

		// Assets & data init
		hxd.snd.Manager.get(); // force sound manager init on startup instead of first sound play
		Assets.init();
		new ui.Console(Assets.fontTiny, s);
		Lang.init("en");

		// Game controller & default key bindings
		controller = new dn.heaps.Controller(s);
		ca = controller.createAccess("main");
		controller.bind(AXIS_LEFT_X_NEG, Key.LEFT, Key.Q, Key.A);
		controller.bind(AXIS_LEFT_X_POS, Key.RIGHT, Key.D);
		controller.bind(AXIS_LEFT_Y_POS, Key.UP, Key.Z);
		controller.bind(AXIS_LEFT_Y_NEG, Key.DOWN, Key.S);
		controller.bind(X, Key.F);
		controller.bind(Y, Key.C);
		controller.bind(A, Key.E);
		controller.bind(B, Key.SPACE);
		controller.bind(SELECT, Key.R);
		controller.bind(START, Key.ESCAPE);

		// Focus helper (process that suspend the game when the focus is lost)
		// new GameFocusHelper();

		// Options loading
		new Options();
		Options.ME.load();

		Game.sav.init();
		Game.load();

		// Start
		hxd.Timer.skip();
		delayer.addF(startMainMenu, 1);

		#if debug
		debug = true;
		#end
	}

	public function startMainMenu() {
		killAllChildrenProcesses();

		if (MainMenu.ME != null) {
			MainMenu.ME.destroy();
			delayer.addF(function() {
				new MainMenu();
			}, 1);
		} else
			new MainMenu();
	}

	/** Start game process **/
	public function startGame() {
		killAllChildrenProcesses();
		
		if (Game.ME != null) {
			Game.ME.destroy();
			delayer.addF(function() {
				new Game();
			}, 1);
		} else
			new Game();
	}

	override function update() {
		super.update();

		#if debug
		if (debug) {
			updateImGui();
		}
		#end
	}

	#if debug
	function updateImGui() {
		final halfBtnSize : ImVec2 = {x: ImGui.getColumnWidth() / 2 - 5, y: ImGui.getTextLineHeightWithSpacing()};
		final tierBtnSize : ImVec2 = {x: ImGui.getColumnWidth() / 3 - 5, y: ImGui.getTextLineHeightWithSpacing()};
		final strongColor : ImVec4 = {x: .67, y: .78, z: 1., w: 1.};

		if (ImGui.button('New game', halfBtnSize)) {
			hxd.Save.delete('save/game');
			Game.sav = new GameSave();
			delayer.addF(startGame, 1);
		}
		ImGui.separator();
		if (Options.ME != null && ImGui.treeNodeEx('Debug')) {
			ImGui.text("Draw calls:");
			ImGui.sameLine(0, 5);
			ImGui.textColored(strongColor, Std.string(engine.drawCalls));
			ImGui.text("Fps:");
			ImGui.sameLine(0, 5);
			ImGui.textColored(strongColor, Std.string(Std.int(engine.fps)));

			ImGui.treePop();
		}
		if (Options.ME != null && ImGui.treeNodeEx('Options')) {
			if (ImGui.button('Save', halfBtnSize))
				Options.ME.save();
			ImGui.sameLine(0, 5);
			if (ImGui.button('Load', halfBtnSize))
				Options.ME.load();
			
			ImGui.text("Interactive:");
			ImGui.sameLine(0, 2);
			if (ImGui.button('RenderBounds', tierBtnSize)) {
				Interactive.renderDebugBounds();
			}
			ImGui.sameLine(0, 2);
			if (ImGui.button('ClearBounds', tierBtnSize)) {
				Interactive.clearDebugBounds();
			}

			Options.ME.imGuiDebugFields();

			ImGui.treePop();
		}
		ImGui.separator();
	}
	#end

	#if debug
	var imguiCaptureMouse = false;
	#end
	override function postUpdate() {
		super.postUpdate();

		#if debug
		if (hxd.Key.isPressed(hxd.Key.F1)) {
			debug = !debug;
			if (!debug) {
				imguiCaptureMouse = false;
				controller.unlock();
			}
		}

		if (debug) {
			if (ImGui.wantCaptureMouse()) {
				if (!imguiCaptureMouse && !controller.isLocked()) {
					imguiCaptureMouse = true;
					controller.lock();
				}
			} else if (imguiCaptureMouse) {
				imguiCaptureMouse = false;
				controller.unlock();
			}
		}
		#end
	}
}
