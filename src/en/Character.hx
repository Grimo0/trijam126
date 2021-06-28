package en;

import hxd.Event;
import h2d.col.PixelsCollider;

enum EState {
	Happy;
	Neutral;
	Sad;
}

@:access(Game)
class Character extends Interactive {
	var game(get, never) : Game; inline function get_game() return Game.ME;

	var id : String;
	var body : h2d.Bitmap;
	var faceSpr : HSprite;
	public var state(default, set) = EState.Happy;
	public function set_state(s : EState) {
		faceSpr.setFrame(s.getIndex());
		if (!game.locked) {
			switch s {
				case Happy: 
					if (Math.random() < 0.5)
						Assets.SLIB.Happy_1(.6);
					else
						Assets.SLIB.Happy_2(1);
				case Neutral: 
					Assets.SLIB.Neutral_2(1);
				case Sad: 
					if (Math.random() < 0.5)
						Assets.SLIB.Sad_1(.6);
					else
						Assets.SLIB.Sad_2(1);
			}
		}
		return state = s;
	}

	public function new(id : String, ?parent) {
		super(0, 0, parent);

		this.id = id;

		body = Assets.entities.getBitmap('${id}body', this);

		faceSpr = new HSprite(Assets.entities, '${id}face', this);

		var collData = Assets.entities.getTile('${id}col');
		var pxs = collData.getTexture().capturePixels().sub(
			Std.int(collData.x), Std.int(collData.y),
			Std.int(collData.width), Std.int(collData.height)
		);
		shapeX = -collData.dx;
		shapeY = -collData.dy;
		shape = new h2d.col.PixelsCollider(pxs);
	}

	override function onOver(e:Event) {
		if (game.syringe.ratio > 0) return;
		game.syringe.visible = false;
		if (game.syringe.ratio <= 0) {
			if (state != Happy) return;
			game.syringe.visible = true;
		} else if (state == Sad)
			game.syringe.visible = true;
	}

	override function onOut(e:Event) {
		if (game.syringe.visible && game.syringe.ratio <= 0)
			game.syringe.visible = false;
	}

	override function onPush(e:Event) {
		if (game.syringe.ratio <= 0) {
			if (state != Happy) return;
			game.syringe.state = Filling;
			game.giver = this;
		} else if (state == Sad) {
			game.syringe.state = Giving;
			game.receiver = this;
		}
	}
}
