import dn.heaps.slib.*;

class Assets {
	public static var fontPixel : h2d.Font;
	public static var fontTiny : h2d.Font;
	public static var fontSmall : h2d.Font;
	public static var fontMedium : h2d.Font;
	public static var fontLarge : h2d.Font;

	public static var placeholder : SpriteLib;
	public static var ui : SpriteLib;
	public static var fx : SpriteLib;
	public static var entities : SpriteLib;

	static var initDone = false;

	public static function init() {
		if (initDone)
			return;

		initDone = true;

		// -- Resources
		#if (hl && debug)
		hxd.Res.initLocal();
		#else
		hxd.Res.initEmbed();
		#end

		// -- Fonts
		fontPixel = hxd.Res.fonts.minecraftiaOutline.toFont();
		fontTiny = hxd.Res.fonts.barlow_condensed_medium_regular_9.toFont();
		fontSmall = hxd.Res.fonts.barlow_condensed_medium_regular_11.toFont();
		fontMedium = hxd.Res.fonts.barlow_condensed_medium_regular_17.toFont();
		fontLarge = hxd.Res.fonts.barlow_condensed_medium_regular_32.toFont();

		// -- Atlases
		placeholder = dn.heaps.assets.Atlas.load("atlas/placeholders.atlas");
		ui = dn.heaps.assets.Atlas.load("atlas/ui.atlas");
		fx = dn.heaps.assets.Atlas.load("atlas/fx.atlas");
		entities = dn.heaps.assets.Atlas.load("atlas/entities.atlas");
	}
}
