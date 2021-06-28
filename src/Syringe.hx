import dn.heaps.Sfx;
import en.Character.EState;
import h2d.RenderContext;

enum ESyringe {
	Filling;
	Giving;
}

@:allow(Game, en.Character)
class Syringe extends h2d.Object {
	var game(get, never) : Game; inline function get_game() return Game.ME;

	final fillTime = 1. / Const.FPS;
	final fillGoalMin = 0.55;
	final fillGoalMax = 0.65;
	final fillWidth = 120;

	var sfx : Sfx;

	var ratioBefore = 0.;
	var ratio(default, set) = 0.;
	public function set_ratio(r : Float) {
		fill.scaleX = fillWidth * r;
		handle.x = fill.width * fill.scaleX;
		return ratio = r;
	}
	var state(default, set) : ESyringe;
	public function set_state(s : ESyringe) {
		if (sfx != null){
			sfx.stop();
			sfx = null;
		}

		if (s == null) {
			if (state == Filling) {
				if (ratio > fillGoalMax) {
					game.giver.state = Sad;
					game.gameOver();
				} else {
					if (ratio < fillGoalMin)
						ratio = 0;
					else
						game.giver.state = EState.createByIndex(game.giver.state.getIndex() + 1);
				}
			} else if (state == Giving) {
				if (ratio <= 0) {
					game.receiver.state = Happy;
					game.giver = null;
					game.receiver = null;
					game.checkComplete();
				} else {
					ratio = ratioBefore;
				}
			}			
		} else if (s == Filling) {
			sfx = Assets.SLIB.SyringeFill(1);
		} else if (s == Giving) {
			ratioBefore = ratio;
			sfx = Assets.SLIB.SyringeEmpty(1);
		}
		return state = s;
	}

	var fill : h2d.Bitmap;
	var handle : h2d.Bitmap;

	public function new() {
		super();

		var back = Assets.ui.getBitmap('Syringeback', this);
		fill = new h2d.Bitmap(h2d.Tile.fromColor(0xffbc0f0f, 1, 1), this);
		fill.x = 97;
		fill.y = 4; 
		fill.width = 1;
		fill.height = 50;
		handle = Assets.ui.getBitmap('Syringehandle', this);
		var front = Assets.ui.getBitmap('Syringefront', this);
	}

	public function reset() {
		ratio = 0;
		state = null;
	}

	override function draw(ctx:RenderContext) {
		super.draw(ctx);

		if (state == null) return;
		switch state {
			case Filling:
				ratio += fillTime * game.tmod;
				if (ratio >= 1) {
					ratio = 1;
					state = null;
				}

			case Giving:
				ratio -= fillTime * game.tmod;
				if (ratio <= 0) {
					ratio = 0;
					state = null;
				}
		}
	}
}