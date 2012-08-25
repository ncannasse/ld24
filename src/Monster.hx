class Monster extends Entity {

	var wait : Float;
	
	public function new(x,y) {
		super(Monster, x, y);
		wait = 10;
		speed = 0.03;
	}
	
	override function endMove() {
		wait = (Math.random() + 0.2) * 10;
	}
	
	override function update(dt:Float) {
		if( wait > 0 )
			wait -= dt;
		else if( target == null ) {
			var dx = 0, dy = 0;
			switch( Std.random(10) ) {
			case 1: dx++;
			case 2: dx--;
			case 3: dy--;
			case 4: dy++;
			}
			if( (dx != 0 || dy != 0) && !game.world.collide(ix + dx, iy + dy) ) {
				ix += dx;
				iy += dy;
				target = { x : ix, y : iy };
			}
		}
		super.update(dt);
	}
	
}