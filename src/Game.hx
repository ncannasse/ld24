using Common;

typedef K = flash.ui.Keyboard;

class Game implements haxe.Public {
	
	var root : SPR;
	var world : World;
	var scroll : { x : Float, y : Float, mc : SPR, z : Float };
	var hero : Hero;
	
	public static var props = {
		zoom : 4,
	};
	
	function new(root) {
		this.root = root;
	}
	
	function init() {
		world = new World();
		world.draw();
		scroll = { x : (world.start.x + 0.5) * Const.SIZE, y : (world.start.y + 0.5) * Const.SIZE, mc : new SPR(), z : props.zoom };
		scroll.mc.x = -1000;
		scroll.mc.addChild(new flash.display.Bitmap(world.bmp));
		root.addChild(scroll.mc);
		
		for( c in world.chests ) {
			c.e = new Entity(Chest,c.x,c.y);
			c.e.update();
		}

		hero = new Hero(world.start.x, world.start.y);
		
		update();
		root.addEventListener(flash.events.Event.ENTER_FRAME, function(_) update());
	}
	
	function update() {
		var z = scroll.z;
		var tx = scroll.x - (root.stage.stageWidth / z) * 0.5;
		var ty = scroll.y - (root.stage.stageHeight / z) * 0.5;
		scroll.mc.x = -Std.int(tx * z);
		scroll.mc.y = -Std.int(ty * z);
		scroll.mc.scaleX = scroll.mc.scaleY = z;
		
		hero.update();
		if( hero.target == null ) {
			
			for( c in world.chests )
				if( c.e != null && c.x == hero.ix && c.y == hero.iy ) {
					c.e.remove();
					c.e = null;
				}
			
			if( (Key.isDown(K.UP) || Key.isDown("Z".code) || Key.isDown("W".code)) && !world.collide(hero.ix, hero.iy - 1) ) {
				hero.iy--;
				hero.target = { x : hero.ix, y : hero.iy };
			}
			if( (Key.isDown(K.DOWN) || Key.isDown("S".code)) && !world.collide(hero.ix, hero.iy+1) ) {
				hero.iy++;
				hero.target = { x : hero.ix, y : hero.iy };
			}
			if( (Key.isDown(K.LEFT) || Key.isDown("Q".code) || Key.isDown("A".code)) && !world.collide(hero.ix - 1, hero.iy) ) {
				hero.ix--;
				hero.target = { x : hero.ix, y : hero.iy };
			}
			if( (Key.isDown(K.RIGHT) || Key.isDown("D".code)) && !world.collide(hero.ix + 1, hero.iy) ) {
				hero.ix++;
				hero.target = { x : hero.ix, y : hero.iy };
			}
		}
	}
	
	public static var inst : Game;
	static function main() {
		Key.init();
		inst = new Game(flash.Lib.current);
		inst.init();
	}
	
}