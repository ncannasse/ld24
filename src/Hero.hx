using Common;

class Hero extends Entity {

	public var lock : Bool;
	public var dirX : Int;
	public var dirY : Int;
	public var sword : { dx : Int, dy : Int, pos : Float, speed : Float, mc : SPR };
	
	public function new(x,y) {
		super(Hero, x, y);
		dirY = 1;
	}

	function talk(n: { x:Int, y:Int } ) {
		if( Popup.has() )
			return;
		var p = Game.props;
		switch( n.x + "/" + n.y ) {
		case "51/64":
			if( p.npc == 1 ) {
				game.popup("Sorry I have nothing to say to you !", "that's what you get when talking to strangers");
				return;
			}
			if( p.quests[0] == 0 || (p.quests[0] == 1 && p.gold == 0) ) {
				game.popup("You want a <font color='#4040FF'>Quest</font> ?", "Bring me something shiny and I'll will help you");
				p.quests[0] = 1;
				return;
			}
			if( p.quests[0] == 1 )  {
				p.gold--;
				p.quests[0] = 2;
			}
			game.popup("Thank you for your <font color='#4040FF'>gold coin</font> !", "You can now open doors with keys !");
		default:
			trace("Unknown NPC @" + [n.x, n.y]);
		}
	}
	
	public function move(dx, dy) {
		dirX = dx;
		dirY = dy;
		var x = ix + dx;
		var y = iy + dy;
		if( game.world.collide(x, y) ) {
			switch( game.world.t[x][y] ) {
			case Door:
				if( Game.props.quests[0] == 2 && Game.props.keys > 0 ) {
					Game.props.keys--;
					game.world.remove(x, y);
					game.popup("Door <font color='#00ff00'>Opened</font>", Game.props.keys + " keys left");
				}
			default:
			}
			for( n in game.world.npcs )
				if( n.x == x && n.y == y )
					talk(n);
			return;
		}
		ix += dx;
		iy += dy;
		target = { x : ix, y : iy };
	}
	
	override function update(dt) {
		super.update(dt);
		if( sword != null )
			updateSword(dt);
	}
	
	override function endMove() {
		switch( game.world.t[ix][iy] ) {
		case SavePoint:
			if( Game.props.canSave )
				game.save();
		default:
		}
	}
	
	function updateSword(dt:Float) {
		sword.pos += dt * sword.speed;
		if( sword.pos >= 8 ) {
			sword.pos = 8 - (sword.pos - 8);
			sword.speed *= -1;
		}
		sword.mc.x = mc.x + 8 + (sword.pos - 1) * sword.dx;
		sword.mc.y = mc.y + 8 + (sword.pos - 1) * sword.dy + (sword.dx != 0 ? 2 : 0);
		
		var hitX = sword.mc.x + sword.dx * 10;
		var hitY = sword.mc.y + sword.dy * 10;
		
		var hx = Std.int(hitX / Const.SIZE);
		var hy = Std.int(hitY / Const.SIZE);
		switch( game.world.t[hx][hy] ) {
		case Bush:
			game.world.remove(hx, hy);
		default:
		}
		
		for( m in game.world.monsters )
			if( m.e != null ) {
				var dx = (m.e.x * Const.SIZE + 8) - hitX;
				var dy = (m.e.y * Const.SIZE + 7) - hitY;
				if( dx * dx + dy * dy < 8*8 ) {
					m.e.kill();
					m.e = null;
					break;
				}
			}
		
		if( sword.pos < 0 ) {
			sword.mc.remove();
			sword = null;
		}
	}
	
	public function attack() {
		var smc = new SPR();
		var bmp = new flash.display.Bitmap(Entity.sprites[Type.enumIndex(Entity.EKind.Sword)][0]);
		bmp.x = -8;
		bmp.y = -3;
		smc.addChild(bmp);
		smc.rotation = Math.atan2( -dirX, dirY) * 180 / Math.PI;
		game.dm.add(smc, Const.PLAN_ENTITY + (dirY < 0 ? -1 : 0));
		sword = { dx : dirX, dy : dirY, pos : 0., speed : 3., mc : smc };
		updateSword(0);
	}
	
	
}