using Common;

class Part {

	var mc : flash.display.DisplayObject;
	var x : Float;
	var y : Float;
	var z : Float;
	public var vx : Float;
	public var vy : Float;
	public var vz : Float;
	public var time : Float;
	public var speed : Float;
	
	public function new(x, y, z, mc) {
		this.mc = mc;
		this.x = x;
		this.y = y;
		this.z = z;
		this.speed = 0.8;
		mc.x = x;
		mc.y = y - z;
		Game.inst.dm.add(mc, Const.PLAN_PART);
		vx = (Math.random() - 0.5) * 3;
		vy = (Math.random() - 0.5) * 3;
		vz = (Math.random() + 2) * 1.5;
		time = 50.;
		all.push(this);
	}
	
	public function update(dt:Float) {
		x += vx * speed;
		y += vy * speed;
		z += vz * speed;
		vz -= Math.pow(0.9, dt) * speed;
		if( z < 0 ) {
			z = -z;
			vz *= -0.5;
		}
		mc.x = x;
		mc.y = y - z;
		time -= dt;
		mc.alpha = time / 30;
		return time > 0;
	}
	
	public function remove() {
		mc.parent.removeChild(mc);
	}
	
	public static function explode( bmp : flash.display.BitmapData, px : Int, py : Int, proba = 100 ) {
		if( bmp == null )
			return;
		for( x in 0...bmp.width )
			for( y in 0...bmp.height ) {
				var c = bmp.getPixel32(x, y);
				if( c == 0 || Std.random(100) >= proba ) continue;
				var b = new flash.display.Bitmap(Part.getColorPixel(c));
				new Part(px + x, py + y, 0, b);
			}
	}
	
	static var all = new Array<Part>();
	static var PIXELS = new IntHash();
	public static function getColorPixel( c : Int ) {
		var p = PIXELS.get(c);
		if( p == null ) {
			p = new flash.display.BitmapData(1, 1, false, c);
			PIXELS.set(c, p);
		}
		return p;
	}
	
	public static function updateAll( dt ) {
		for( p in all.copy() )
			if( !p.update(dt) ) {
				p.remove();
				all.remove(p);
			}
	}
	
}