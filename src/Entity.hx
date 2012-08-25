using Common;

@:bitmap("sprites.png")
class SpritesPNG extends BMP {
}

enum EKind {
	Hero;
	Chest;
}

class Entity
{
	
	static var sprites = Tiles.initTiles(new SpritesPNG(0, 0), 16);

	public var kind : EKind;
	public var x : Float;
	public var y : Float;
	public var ix : Int;
	public var iy : Int;
	public var mc : SPR;
	public var speed : Float;
	
	public var target : { x : Float, y : Float };
	
	var bmp : flash.display.Bitmap;
	var frame : Int;
	var game : Game;
	
	public function new( kind, x, y ) {
		this.kind = kind;
		this.x = this.ix = x;
		this.y = this.iy = y;
		
		speed = 0.1;
		
		mc = new SPR();
		bmp = new flash.display.Bitmap();
		
		switch( kind ) {
		case Chest:
		default:
			var shade = new SPR();
			shade.graphics.beginFill(0, 0.1);
			shade.graphics.drawEllipse(2, 11, 12, 8);
			mc.addChild(shade);
		}
		
		mc.addChild(bmp);
		game = Game.inst;
		game.scroll.mc.addChild(mc);
	}
	
	function updatePos() {
		if( target == null ) return;
		var dx = target.x - x;
		var dy = target.y - y;
		if( dx != 0 ) {
			if( Math.abs(dx) <= speed )
				x = target.x;
			else if( dx > 0 )
				x += speed;
			else
				x -= speed;
		}
		if( dy != 0 ) {
			if( Math.abs(dy) <= speed )
				y = target.y;
			else if( dy > 0 )
				y += speed;
			else
				y -= speed;
		}
		if( x == target.x && y == target.y )
			target = null;
	}
	
	public function remove() {
		game.scroll.mc.removeChild(mc);
	}
	
	public function update() {
		updatePos();
		
		mc.x = Std.int(x * Const.SIZE);
		mc.y = Std.int(y * Const.SIZE);
		frame++;
		var sl = sprites[Type.enumIndex(kind)];
		bmp.bitmapData = sl[frame % sl.length];
	}
	
}