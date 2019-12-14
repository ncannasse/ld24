
enum EKind {
	NPC;
	Chest;
	Monster;
	Sword;
	SavePoint;
	Cursor;
	Hero;
	HeroUp;
	Bat;
	Knight;
	Fireball;
}

class Entity {

	public var kind : EKind;
	public var x : Float;
	public var y : Float;
	public var ix : Int;
	public var iy : Int;
	public var speed : Float;

	public var target : { x : Float, y : Float };

	public var mc : h2d.Object;
	var shade : h2d.Graphics;

	public var animSpeed : Float;
	var bmp : h2d.Bitmap;
	var frame : Float;
	var game : Game;
	var bounds : { x : Int, y : Int, w : Int, h : Int };
	var iframe : Int;

	public function new( kind, x, y ) {
		this.kind = kind;
		this.x = this.ix = x;
		this.y = this.iy = y;

		speed = 0.1;
		frame = Std.random(1000);
		animSpeed = 0.3;

		bounds = { x : 4, w : 8, y : 8, h : 8 };

		mc = new h2d.Object();
		bmp = new h2d.Bitmap();
		game = Game.inst;

		switch( kind ) {
		case Chest:
			shade = new h2d.Graphics();
			shade.beginFill(0, 0.1);
			shade.drawRect(2, 12, 11, 6);
			game.dm.add(shade, Const.PLAN_SHADE);
		case SavePoint:
		case NPC:
			animSpeed = 0;
			frame = 0;
			if( iy == 31 && ix == 59 )
				frame = 1;
		default:
			shade = new h2d.Graphics();
			shade.beginFill(0, 0.1);
			shade.drawEllipse(7, 14, 6, 4);
			game.dm.add(shade, Const.PLAN_SHADE);
		}

		mc.addChild(bmp);
		game.dm.add(mc, Const.PLAN_ENTITY);
	}

	function endMove() {

	}

	public function teleport(tx, ty) {
		x = ix = tx;
		y = iy = ty;
	}

	public function explode( p = 100 ) {
		Part.explode(bmp.tile, Std.int(mc.x), Std.int(mc.y), p);
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
			ix = Std.int(x);
			iy = Std.int(y);
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
			shade.x = mc.x + 0.5;
			shade.y = mc.y + 0.5;
		}

		if( frame >= 0 ) {
			var sl = game.spriteFrames[Type.enumIndex(kind)];
			frame += animSpeed * hxd.Timer.tmod;
			iframe = Std.int(frame) % sl.length;
			bmp.tile = sl[iframe];
			if( sl.length == 0 )
				frame = -1;
		}
	}

}