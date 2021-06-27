package en;

import h2d.col.PixelsCollider;

enum EFace {
	HAPPY;
	NEUTRAL;
	SAD;
}

class Character extends Interactive {
	var id : String;
	var body : h2d.Bitmap;
	var faceSpr : HSprite;
	public var face = EFace.HAPPY;

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
}
