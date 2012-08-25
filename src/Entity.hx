using Common;

@:bitmap("sprites.png")
class SpritesPNG extends BMP {
}

enum EKind {
	Hero;
	Chest;
	Monster;
	Sword;
	SavePoint;
}

class Entity
{
	
	static var sprites = Tiles.initTiles(new SpritesPNG(0, 0), 16);

	public var kind : EKind;
	public var x : Float;
	public var y : Float;
	public var ix : Int;
	public var iy : Int;
	public var speed : Float;
	
	public var target : { x : Float, y : Float };

	public var mc : SPR;
	var shade : SPR;
	
	public var animSpeed : Float;
	var bmp : flash.display.Bitmap;
	var frame : Float;
	var game : Game;
	
	public function new( kind, x, y ) {
		this.kind = kind;
		this.x = this.ix = x;
		this.y = this.iy = y;
		
		speed = 0.1;
		frame = Std.random(1000);
		animSpeed = 0.3;
		
		mc = new SPR();
		bmp = new flash.display.Bitmap();
		game = Game.inst;
		
		switch( kind ) {
		case Chest:
			shade = new SPR();
			shade.graphics.beginFill(0, 0.1);
			shade.graphics.drawRect(2, 12, 11, 6);
			game.dm.add(shade, Const.PLAN_SHADE);
		case SavePoint:
		default:
			shade = new SPR();
			shade.graphics.beginFill(0, 0.1);
			shade.graphics.drawEllipse(2, 11, 12, 8);
			game.dm.add(shade, Const.PLAN_SHADE);
		}
		
		mc.addChild(bmp);
		game.dm.add(mc, Const.PLAN_ENTITY);
	}
	
	function endMove() {
		
	}
	
	public function explode() {
		Part.explode(bmp.bitmapData, Std.int(mc.x), Std.int(mc.y));
	}
	
	function updatePos(dt:Float) {
		if( target == null ) return;
		var dx = target.x - x;
		var dy = target.y - y;
		var speed = speed * dt;
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
		if( x == target.x && y == target.y ) {
			endMove();
			target = null;
		}
	}
	
	public function remove() {
		if( mc != null )
			mc.parent.removeChild(mc);
		if( shade != null )
			shade.parent.removeChild(shade);
	}
	
	public function update(dt:Float) {
		updatePos(dt);
		
		mc.x = Std.int(x * Const.SIZE);
		mc.y = Std.int(y * Const.SIZE) - 2;
		
		if( shade != null ) {
			shade.x = mc.x;
			shade.y = mc.y;
		}
				
		if( frame >= 0 ) {
			var sl = sprites[Type.enumIndex(kind)];
			frame += animSpeed * Timer.tmod;
			var iframe = Std.int(frame) % sl.length;
			bmp.bitmapData = sl[iframe];
			if( sl.length == 0 )
				frame = -1;
		}
	}
	
}