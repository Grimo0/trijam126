class GameSave {
	public var flags = new Map<String, Int>();
	public var levelUID : Int;

	public function new() {}

	public function init() {
		levelUID = Assets.world.levels[0].uid;
		flags.set(Assets.world.levels[0].identifier, 1);
	}
}
