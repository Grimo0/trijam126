package en;

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
		body.x = -body.tile.dx;
		body.y = -body.tile.dy;

		faceSpr = new HSprite(Assets.entities, '${id}face', this);
		faceSpr.x = -body.tile.dx;
		faceSpr.y = -body.tile.dy;
		
		this.width = body.tile.width;
		this.height = body.tile.height;
	}
}