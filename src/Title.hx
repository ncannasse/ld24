import hxd.Key in K;

class Title extends hxd.App {

	var cursor : h2d.Bitmap;
	var load : Null<Bool>;
	var time : Float;
	var layer2 : h2d.Bitmap;
	var layer3 : h2d.Bitmap;
	var started : Bool;

	var hasSave : Bool;

	// js click required for sound support
	static var NEED_CLICK = #if js true #else false #end;

	override function init() {
		time = 0;
		var bg = new h2d.Object(s2d);
		bg.scale(2);

		var bmp = new h2d.Bitmap(hxd.Res.title.toTile(),bg);
		layer2 = new h2d.Bitmap(hxd.Res.title2.toTile(),bg);
		layer3 = new h2d.Bitmap(hxd.Res.title3.toTile(),bg);
		layer2.colorKey = hxd.Res.title2.getPixels().getPixel(0,0);
		layer3.colorKey = hxd.Res.title3.getPixels().getPixel(0,0);

		var quote = Game.makeField("A short story of adventure video games evolution", 12);
		quote.textColor = 0xD8CB55;
		quote.x = Std.int((s2d.width - quote.textWidth) * 0.5);
		quote.y = 170;
		s2d.addChild(quote);

		if( NEED_CLICK ) {
			NEED_CLICK = false;
			var tf = Game.makeField("Click to start", 18);
			tf.x = Std.int(s2d.width - tf.textWidth) >> 1;
			tf.y = 300;
			s2d.addChild(tf);
			layer2.y = 1000;

			var int = new h2d.Interactive(s2d.width, s2d.height, s2d);
			int.onClick = function(_) {
				tf.remove();
				int.remove();
				show();
			}
			return;
		}
		show();
	}

	function show() {
		var copy = Game.makeField("(C)1986-2012 ncannasse", 12);
		copy.x = s2d.width - copy.textWidth - 5;
		copy.y = s2d.height - 20;
		s2d.addChild(copy);


		var start = Game.makeField("Start", 18);
		start.x = 250;
		start.y = 220;
		s2d.addChild(start);

		hasSave = hxd.Save.load(null,"evo2") != null;

		var cont = Game.makeField("Continue", 18);
		cont.x = 250;
		cont.y = 250;
		if( !hasSave )
			cont.textColor = 0x808080;
		s2d.addChild(cont);

		load = hasSave;
		cursor = new h2d.Bitmap(hxd.Res.sprites.toTile().sub(0,5 * 16,16,16), s2d);
		cursor.scale(2);
		cursor.colorKey = 0xFFFF00FF;
	}

	override function update(_) {
		if( load == null )
			return;

		Game.pad.axisDeadZone = 0.8;
		var sw = Game.pad.yAxis != 0 && (Game.pad.yAxis < 0) == load;
		for( k in [K.DOWN, K.UP, "Z".code, "W".code, "S".code] )
			if( hxd.Key.isPressed(k) )
				sw = true;
		if( sw && hasSave ) {
			hxd.Res.sfx.menu.play();
			load = !load;
		}
		time += 0.2;

		var d2 = time * 2;
		if( d2 > 50 ) d2 = 50 - Math.abs(Math.sin((time - 25) * 0.2) * 2.5);
		layer2.y = 100 - d2 * 2;
		layer2.x = 25 - d2 * 0.5;

		layer3.y = Math.sin(time * 0.1) * 10;

		cursor.x = 220 + Math.sin(time) * 2;
		cursor.y = 210 + (load ? 30 : 0);
		var cfg = hxd.Pad.DEFAULT_CONFIG;
		for( k in ["E".code, K.ENTER, K.SPACE] )
			if( hxd.Key.isPressed(k) || Game.pad.isPressed(cfg.A) || Game.pad.isPressed(cfg.X) ) {
				haxe.Timer.delay(start,10);
				return;
			}
	}

	function start() {
		if( started )
			return;
		started = true;
		dispose();
		Game.startGame(load);
	}

}