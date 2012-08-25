using Common;

@:bitmap("title.png") class TitlePNG extends BMP {
}

class Title {

	var game : Game;
	var root : SPR;
	var cursor : SPR;
	var load : Bool;
	var time : Float;
	
	public function new( game : Game ) {
		time = 0;
		this.game = game;
		root = new SPR();
		root.scaleX = root.scaleY = 2;
		game.root.addChild(root);
		
		var bmp = new flash.display.Bitmap(new TitlePNG(0, 0));
		root.addChild(bmp);
		
		var start = game.makeField("Start", 15);
		start.x = 120;
		start.y = 100;
		root.addChild(start);
		
		var cont = game.makeField("Continue", 15);
		cont.x = 120;
		cont.y = 120;
		if( !game.hasSave() )
			cont.textColor = 0x808080;
		root.addChild(cont);
		
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
			if( Key.isToggled(k) )
				load = !load;
		time += 0.2;
		cursor.x = 105 + Math.sin(time) * 2;
		cursor.y = 100 + (load ? 20 : 0);
		for( k in ["E".code, K.ENTER, K.SPACE] )
			if( Key.isToggled(k) || Game.props.debug ) {
				if( !load )
					Game.props = Game.PROPS[0];
				root.removeEventListener(flash.events.Event.ENTER_FRAME,update);
				root.remove();
				game.init();
				return;
			}
	}
	
}