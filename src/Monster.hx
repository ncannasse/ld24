class Monster extends Entity {

	var wait : Float;
	var start : { x : Float, y : Float };
	var attack : Bool;
	public var generated : Bool;

	public function new(k, x,y) {
		super(k, x, y);
		wait = 10;
		switch( k ) {
		case Bat:
			speed = 0.05;
		case Knight:
			speed = 0.1;
		case Fireball:
			mc.alpha = 0.7;
		default:
			speed = 0.03;
		}
		start = { x : x, y : y };
	}

	override function endMove() {
		wait = (Math.random() + 0.2) * 10;
	}

	function endWait() {
	}

	public function deathHit() {
		switch( kind ) {
		case Knight:
			return mc.alpha > 0.3;
		default:
		}
		return true;

	}

	public function canHit() {
		switch( kind ) {
		case Knight:
			return mc.alpha > 0.8;
		case Fireball:
			return false;
		default:
		}
		return true;
	}

	override function update(dt:Float) {
		if( wait > 0 ) {
			wait -= dt;
			if( wait <= 0 )
				endWait();
		} else {
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
			case Knight:
				if( frame > 12 ) {
					mc.alpha -= dt * 0.03;
					if( mc.alpha <= 0 ) {
						frame = 0;
						wait = 20 + Math.random() * 10;
						mc.alpha = 1;
						attack = Std.random(3) != 0;
						var h = game.hero;
						do {
							ix = Std.int(this.x + (Math.random() - 0.5) * 6);
							iy = Std.int(this.y + (Math.random() - 0.5) * 6);
						} while( game.world.collide(ix, iy) || (ix - start.x) * (ix - start.x) + (iy - start.y) * (iy - start.y) > 36 || (ix - h.x) * (ix - h.x) + (iy - h.y) * (iy - h.y) < 2 );
						x = ix;
						y = iy;
						if( !game.world.collide(ix, iy + 1) )
							target = { x : ix, y : y + 1 };
					}
				}
				if( !attack && target == null ) {
					attack = true;
					var dx = game.hero.x - ix;
					var dy = game.hero.y - iy;
					if( dx*dx+dy*dy < 64 )
						Sounds.play("fireball");
					game.monsters.push(new Monster(Fireball, ix, iy));
				}
			case Fireball:
				y += dt * 0.1;
				if( game.world.collide(Std.int(x), Std.int(y)) ) {
					var dx = game.hero.x - x;
					var dy = game.hero.y - y;
					if( dx*dx+dy*dy < 64 )
						Sounds.play("fireHit");
					kill();
					return;
				}
			default:
			}
		}
		super.update(dt);
	}

	public function kill() {
		explode(10);
		remove();
		game.monsters.remove(this);
	}

}