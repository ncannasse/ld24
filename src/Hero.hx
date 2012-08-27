using Common;

class Hero extends Entity {

	public var lock : Bool;
	public var dirX : Int;
	public var dirY : Int;
	public var sword : { dx : Int, dy : Int, pos : Float, speed : Float, mc : SPR };
	public var moving : Bool;
	public var push : Float;
	public var hitRecover : Float;
	var puzzle : Array<{x:Int,y:Int,s:SPR}>;
	var sound : Bool;
	
	public function new(x,y) {
		super(Hero, x, y);
		dirY = 1;
		hitRecover = 0;
	}

	function talk(n: { x:Int, y:Int } ) {
		if( Popup.hasDialog() )
			return;
		var p = Game.props;
		switch( n.x + "/" + n.y ) {
		case "51/62":
			Sounds.play("npc");
			if( p.npc == 1 ) {
				game.popup("Sorry I have nothing to say to you !", "that's what you get when talking to strangers",true);
				return;
			}
			if( p.quests[0] == 0 || (p.quests[0] == 1 && p.gold == 0) ) {
				game.popup("You want a <font color='#4040FF'>Quest</font> ?", "Bring me something shiny and I'll will help you",true);
				p.quests[0] = 1;
				return;
			}
			if( p.quests[0] == 1 )  {
				p.gold--;
				p.quests[0] = 2;
			}
			game.popup("Thank you for your <font color='#4040FF'>gold coin</font> !", "You can now open doors with keys !",true);
		case "59/31":
			if( p.quests[1] == 0 ) {
				p.quests[1] = 1;
				Sounds.play("princess");
				game.getChest(CPrincess, 0, 0);
			}
		case "53/47":
			Sounds.play("npc");
			game.popup("I love fishing", "What about you ?", true);
		case "38/61":
			Sounds.play("npc");
			game.popup("Check our company website <font color='#4040FF'>ShiroGames.com</font>", "What ? In-game advertising ? No way !", true);
		case "57/38":
			Sounds.play("npc");
			game.popup("If you talk to the princess, that will be game ending", "I am married as well, I know what I'm talking about !", true);
		case "41/72":
			Sounds.play("npc");
			game.popup("If you can't find your way, try to push some rock to open the path", "Yes I know, this is quite a classic trick...", true);
		default:
			trace("Unknown NPC @" + [n.x, n.y]);
		}
	}
	
	function collide(x, y) {
		if( !game.world.collide(x, y) )
			return false;
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
		return true;
	}
	
	public function move(dx, dy, dt:Float) {
		dirX = dx;
		dirY = dy;
		
		if( Game.props.freeMove ) {
			
			var s = speed * dt;
			
			var px1 = Std.int((x * Const.SIZE + bounds.x) / Const.SIZE  + dx * s);
			var px2 = Std.int((x * Const.SIZE + bounds.x + bounds.w - 1) / Const.SIZE  + dx * s);
			var py1 = Std.int((y * Const.SIZE + bounds.y) / Const.SIZE  + dy * s);
			var py2 = Std.int((y * Const.SIZE + bounds.y + bounds.h - 1) / Const.SIZE  + dy * s);
			
			if( collide(px1, py1) || collide(px2, py1) || collide(px1, py2) || collide(px2, py2) ) {
				push += dt;
				if( push > 25 ) {
					push = 0;
					if( dirY == 1 && px1 == 64 && py2 == 58 ) {
						game.world.remove(64, 58);
						game.world.remove(64, 61);
						game.getChest(CPushBlock, 0, 0);
					}
				}
				return;
			}
			push = 0;
			
			this.x += dx * s;
			this.y += dy * s;
			
			var nx = Std.int(this.x + (bounds.x + bounds.w * 0.5) / Const.SIZE);
			var ny = Std.int(this.y + (bounds.y + bounds.h * 0.5) / Const.SIZE);
			if( nx != ix || ny != iy ) {
				ix = nx;
				iy = ny;
				endMove();
			}
			
			moving = true;
				
		} else {
		
			var x = ix + dx;
			var y = iy + dy;
			if( collide(x, y) )
				return;
			target = { x : x, y : y };
		}
	}
	
	override function update(dt) {
		if( target == null && !moving )
			frame = 0;
		else if( iframe%2 == 0 ) {
			if( !sound ) {
				sound = true;
				Sounds.play("walk");
			}
		} else
			sound = false;
		
		if( dirY < 0 ) kind = HeroUp else kind = Hero;
		super.update(dt);
		if( hitRecover > 0 ) {
			hitRecover -= dt;
			mc.alpha = Math.abs(Math.sin(hitRecover));
			if( hitRecover <= 0 )
				mc.alpha = 1;
		}
		if( sword != null )
			updateSword(dt);
	}
	
	function cleanPuzzle() {
		if( puzzle != null ) {
			for( p in puzzle )
				p.s.remove();
			puzzle = null;
		}
	}
	
	override function endMove() {
		switch( game.world.t[ix][iy] ) {
		case SavePoint:
			if( Game.props.canSave )
				game.save();
		case Dungeon:
			game.getChest(CDungeon, 0, 0);
		case DungeonPuzzle:
			if( Game.props.puzzle )
				return;
			if( puzzle == null ) puzzle = [];
			for( p in puzzle )
				if( p.x == ix && p.y == iy ) {
					cleanPuzzle();
					puzzle = [];
					break;
				}
				
			var s = new SPR();
			s.graphics.beginFill(0xFFFFFF, 0.5);
			s.graphics.drawRect(0, 0, Const.SIZE, Const.SIZE);
			s.x = ix * Const.SIZE;
			s.y = iy * Const.SIZE;
			game.dm.add(s, Const.PLAN_BG);
			puzzle.push( { x:ix, y:iy, s:s } );
			Sounds.play("puzzle");
			if( puzzle.length == 13 ) {
				cleanPuzzle();
				game.getChest(CPuzzle, 0, 0);
			}
		case DungeonExit:
			if( y > 24.9 ) {
				teleport(59, 43);
				game.initDungeon(false);
				game.world.remove(59, 44);
			} else
				iy = 24;
		default:
			cleanPuzzle();
			
			if( ix == 26 && iy == 42 && Game.props.dungeon )
				game.world.remove(26, 40);
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
		
		var props = Game.props;
		for( m in game.monsters ) {
			var dx = (m.x * Const.SIZE + 8) - hitX;
			var dy = (m.y * Const.SIZE + 7) - hitY;
			if( dx * dx + dy * dy < 8 * 8 && m.canHit() ) {
				m.kill();
				Sounds.play("kill");
				if( props.dungeon ) {
					props.dmkills++;
					if( props.dmkills == 7 )
						game.getChest(CDungeonKills, 0, 0);
				}
				if( props.xp >= 0 ) {
					props.xp += 10;
					game.updateUI();
					if( props.xp >= 100 )
						game.getChest(CLevelUp, 0, 0);
				}
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
		Sounds.play("sword");
	}
	
}