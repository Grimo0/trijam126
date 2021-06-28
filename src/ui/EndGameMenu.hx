package ui;

import en.Character;

class EndGameMenu extends Modal {
	public var game(get, never) : Game; inline function get_game() return Game.ME;

	var gameOver : Bool;

	public function new(gameOver : Bool, gameComplete = false) {
		super();

		this.gameOver = gameOver;

		root.alpha = 0;
		tw.createMs(root.alpha, 1, TType.TEaseOut, 500);

		// mask.remove();

		var notThem = new Array<Character>();
		for (character in game.chars) {
			if (!character.visible) notThem.push(character);
		}
		var charIdx = game.getRndCharIdx(notThem);

		var bg = new h2d.Bitmap(h2d.Tile.fromColor(@:privateAccess game.charColors[charIdx]), root);
		bg.width = 800;
		bg.height = 450;
		bg.x = (game.pxWid - bg.width) / 2;
		bg.y = (game.pxHei - bg.height) / 2;
		// bgBorder.filter = new h2d.filter.DropShadow(0, 0.785, 0x000000, 1., 100, 1.1, 1, true);

		var char = new Character('Char${charIdx + 1}', root);
		var cSize = char.getSize();
		var maxWidth = bg.width * 0.6;
		var maxHeight = bg.height * 0.6;
		if (cSize.width > maxWidth || cSize.height > maxHeight)
			char.setScale(M.fmin(maxWidth / cSize.width, maxHeight / cSize.height));
		cSize = char.getSize();
		char.x = bg.x + 0.8 * bg.width - cSize.width / 2;
		char.y = bg.y + (bg.height - cSize.height) / 2;

		var txt = new h2d.Text(Assets.fontLarge, root);
		txt.x = bg.x + bg.width * 0.05;
		txt.y = bg.y + bg.height * 0.25;
		txt.filter = new h2d.filter.DropShadow(0, 0.785, 0x000000, .7, 5, 1.1, 1, true);

		if (gameOver) {
			char.state = Sad;
			txt.text = Lang.t._('You have to be more cautious !\n\nClick to try again.');
		} else if (gameComplete) {
			char.state = Happy;
			txt.text = Lang.t._('Thanks for playing our game !\nIf you\'re able to, please contact your\nlocal blood donation center and help save lives\nClick to restart.');
		} else {
			char.state = Happy;
			txt.text = Lang.t._('Well done ! \nNow with more people !\nClick to start next level.');
		}

		var i = new h2d.Interactive(game.pxWid, game.pxHei, root);
		i.onClick = function(_) {
			close();
		};
	}

	override function onResize() {
		super.onResize();
		root.setScale(Const.SCALE);
	}

	override public function close() {
		// tw.createMs(root.alpha, 0, TType.TEaseOut, 500).end(() -> {
			if (!destroyed) {
				destroy();
				onClose();
			}
		// });
	}

	override function onClose() {
		game.resume();
	}

	override function update() {
		// super.update();
		/* if (ca.bPressed() || )
			game.resume(); */
	}
}
