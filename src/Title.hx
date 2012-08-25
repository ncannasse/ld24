using Common;

@:bitmap("title.png") class TitlePNG extends BMP {
}

@:bitmap("title2.png") class Title2PNG extends BMP {
}

@:bitmap("title3.png") class Title3PNG extends BMP {
}

class Title {

	var game : Game;
	var root : SPR;
	var cursor : SPR;
	var load : Bool;
	var time : Float;
	var layer2 : flash.display.Bitmap;
	var layer3 : flash.display.Bitmap;
	
	public function new( game : Game ) {
		time = 0;
		this.game = game;
		root = new SPR();
		root.scaleX = root.scaleY = 2;
		game.root.addChild(root);
		
		root.addEventListener(flash.events.MouseEvent.CLICK, function(_) start());
		
		var curMouse = root.mouseY < 140;
		root.addEventListener(flash.events.MouseEvent.MOUSE_MOVE, function(_) {
			var k = root.mouseY < 140;
			if( curMouse != k && game.hasSave() ) {
				load = !k;
				curMouse = k;
			}
		});
		
		var bmp = new flash.display.Bitmap(new TitlePNG(0, 0));
		root.addChild(bmp);
		
		layer2 = new flash.display.Bitmap(new Title2PNG(0, 0, true, 0));
		layer2.bitmapData.floodFill(0, 0, 0);
		root.addChild(layer2);

		layer3 = new flash.display.Bitmap(new Title3PNG(0, 0, true, 0));
		layer3.bitmapData.floodFill(0, 0, 0);
		root.addChild(layer3);
		
		var start = game.makeField("Start", 15);
		start.x = 120;
		start.y = 120;
		root.addChild(start);
		
		var cont = game.makeField("Continue", 15);
		cont.x = 120;
		cont.y = 140;
		if( !game.hasSave() )
			cont.textColor = 0x808080;
		root.addChild(cont);
		
		var quote = game.makeField("A short story of adventure video games evolution", 10);
		quote.textColor = 0xD8CB55;
		quote.x = 15;
		quote.y = 80;
		root.addChild(quote);
		
		var copy = game.makeField("(C)1986-2012 NCA", 12);
		copy.x = 190;
		copy.y = 188;
		root.addChild(copy);
		
		load = game.hasSave();
		cursor = new SPR();
		cursor.addChild(new flash.display.Bitmap(Entity.sprites[Type.enumIndex(Entity.EKind.Cursor)][0]));
		root.addChild(cursor);
		root.addEventListener(flash.events.Event.ENTER_FRAME, update);
		Key.init();
		update(null);
	}
	
	function update(_) {
		for( k in [K.DOWN, K.UP, "Z".code, "W".code, "S".code] )
			if( Key.isToggled(k) && game.hasSave() )
				load = !load;
		time += 0.2;
		
		var d2 = time * 2;
		if( d2 > 50 ) d2 = 50 - Math.abs(Math.sin((time - 25) * 0.2) * 2.5);
		layer2.y = 100 - d2 * 2;
		layer2.x = 25 - d2 * 0.5;
		
		layer3.y = Math.sin(time * 0.1) * 10;
		
		cursor.x = 105 + Math.sin(time) * 2;
		cursor.y = 120 + (load ? 20 : 0);
		for( k in ["E".code, K.ENTER, K.SPACE] )
			if( Key.isToggled(k) || Game.props.debug ) {
				start();
				return;
			}
	}
	
	function start() {
		if( !load )
			Game.props = Game.PROPS[0];
		root.removeEventListener(flash.events.Event.ENTER_FRAME,update);
		root.remove();
		game.init();
	}
	
}