class Monster extends Entity {

	var wait : Float;
	var start : { x : Float, y : Float };
	
	public function new(k, x,y) {
		super(k, x, y);
		wait = 10;
		switch( k ) {
		case Bat:
			speed = 0.05;
		default:
			speed = 0.03;
		}
		start = { x : x, y : y };
	}
	
	override function endMove() {
		wait = (Math.random() + 0.2) * 10;
	}
	
	override function update(dt:Float) {
		if( wait > 0 )
			wait -= dt;
		else {
			switch( kind ) {
			case Monster:
				if( target == null ) {
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
			case Bat:
				if( target == null ) {
					var x, y;
					do {
						x = this.x + (Math.random() - 0.5) * 3;
						y = this.y + (Math.random() - 0.5) * 3;
					} while( (x - start.x) * (x - start.x) + (y - start.y) * (y - start.y) > 16 );
					target = { x : x, y : y };
				}
			default:
			}
		}
		super.update(dt);
	}
	
	public function kill() {
		explode();
		remove();
	}
	
}