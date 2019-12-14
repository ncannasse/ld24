import hxd.Key;
import hxd.Key in K;

class BitmaskShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture : Sampler2D;
		@param var mask : Int;
		@param var delta : Float;

		function conv( v : Float ) : Float {
			var k = int(min( v * 255 + delta, 255 ) ) & mask;
			return float(k) / 320;
		}

		function fragment() {
			var pixel = texture.get(calculatedUV);
			pixelColor = pixel;
			pixelColor.rgb = vec3(conv(pixel.r),conv(pixel.g),conv(pixel.b));
			pixelColor.a = 1;
			if( delta == 0x30 ) {
				if( pixel.b > 0.5 )
					pixelColor.b = pixel.b;
				if( pixel.r > 0.5 && pixel.g > 0.5 )
					pixelColor.rg = vec2(0.5,0.5);
			}
		}
	}
}

class Game extends hxd.App {

	public var entities : Array<Entity>;
	public var monsters : Array<Monster>;
	public var dm : h2d.Layers;
	public var world : World;
	public var hero : Hero;

	public var spriteFrames : Array<Array<h2d.Tile>>;
	var scroll : { x : Float, y : Float, mc : h2d.Object, curZ : Float, tz : Float };
	var shake : { time : Float, power : Float };

	var circleSize : Float;
	var mask : h2d.Graphics;
	var realWorld : World;
	var generators : Array<{ x : Int, y : Int, time : Float }>;
	var curColor : { mask : Float, delta : Float, alpha : Float, rgb : Float, k : Float };
	var outputFilters : Array<h2d.filter.Filter>;
	var barsDelta : Float;
	var bars : h2d.Graphics;
	var deltaTest = 0;
	var uiBar : h2d.Graphics;
	var pixelFilter : h2d.Bitmap;

	static var has = {
		monsters : false,
		npc : false,
		savePoints : false,
	};

	static var DEF_PROPS = {
		zoom : 4,
		bars : true,
		left : false,
		scroll : 0,
		color : 0,
		life : 0,
		monsters : 0,
		weapons : 0,
		web : 0,
		nchests : 0,
		pos : { x : 21, y : 76 },
		canSave : false,
		chests : new Array<Int>(),
		rem : new Array<Int>(),
		npc : 0,
		keys : 0,
		gold : 0,
		quests : new Array<Int>(),
		freeMove : false,
		dungeon : false,
		dmkills : 0,
		puzzle : false,
		xp : -1,
		level : 1,
		porn : false,
		sounds : false,
		music : false,
	};

	public static var props = DEF_PROPS;

	override function init() {

		monsters = [];
		entities = [];
		barsDelta = 0.;

		spriteFrames = h2d.Tile.autoCut(hxd.Res.sprites.toBitmap(),16,16).tiles;

		world = new World(hxd.Res.world.getPixels());
		realWorld = world;

		for( r in props.rem )
			world.removed[r % World.SIZE][Std.int(r / World.SIZE)] = true;

		world.draw();
		scroll = { x : (props.pos.x + 0.5) * Const.SIZE, y : (props.pos.y + 0.5) * Const.SIZE, mc : new h2d.Object(), curZ : props.zoom, tz : 1. };
		scroll.mc.x = -1000;
		scroll.mc.addChild(world.root);
		dm = new h2d.Layers(scroll.mc);
		s2d.addChild(scroll.mc);
		initPixelFilter(props.zoom);

		var hchests = new Map();
		for( c in props.chests )
			hchests.set(c, true);
		for( c in world.chests )
			if( !hchests.exists(c.x + c.y * World.SIZE) ) {
				c.e = new Entity(Chest,c.x,c.y);
				c.e.update(0);
			}

		hero = new Hero(props.pos.x, props.pos.y);

		if( props.dungeon )
			initDungeon(true);

		if( props.chests.length == 0 )
			getChest(CRightCtrl, 0, 0);

		if( props.music )
			hxd.Res.music.play(true).position = 2;

		updateUI();
		updateWeb();
	}

	public function updateUI() {
		if( uiBar == null ) {
			uiBar = new h2d.Graphics();
			uiBar.x = 5;
			uiBar.y = 5;
			s2d.addChild(uiBar);
			uiBar.scaleX = uiBar.scaleY = 2;
		}
		var border = 0xF0F0F0;
		var bg = 0x606060;
		var g = uiBar;
		g.clear();
		if( props.life > 0 ) {
			g.beginFill(border);
			g.drawRect(0, 0, 104, 8);
			g.beginFill(bg);
			g.drawRect(2, 2, 100, 4);
			g.beginFill(0xC00000);
			g.drawRect(2, 2, props.life * 2, 4);
		}

		if( props.xp >= 0 ) {
			g.beginFill(border);
			g.drawRect(0, 12, 104, 8);
			g.beginFill(bg);
			g.drawRect(2, 14, 100, 4);
			g.beginFill(0x00C000);
			g.drawRect(2, 14, props.xp, 4);
		}
	}

	public function initDungeon(v) {
		props.dungeon = v;

		for( c in world.chests )
			if( c.e != null ) {
				c.e.remove();
				c.e = null;
			}
		scroll.mc.removeChild(world.root);

		if( v ) {
			world = new World(hxd.Res.dungeon.getPixels());
			for( r in props.rem ) {
				var y = Std.int(r / World.SIZE);
				if( y >= World.SIZE )
					world.removed[r % World.SIZE][y-World.SIZE] = true;
			}
		}
		else {
			world = realWorld;
		}
		scroll.mc.addChildAt(world.root,0);

		var hchests = new Map();
		for( c in props.chests )
			hchests.set(c, true);
		for( c in world.chests )
			if( !hchests.exists(c.x + (c.y + (v?World.SIZE:0)) * World.SIZE) ) {
				c.e = new Entity(Chest,c.x,c.y);
				c.e.update(0);
			}

		for( e in entities )
			e.remove();

		for( m in monsters )
			m.remove();

		entities = [];
		monsters = [];

		has.monsters = false;
		has.npc = false;
		has.savePoints = false;

		world.draw();
		scroll.x = hero.ix;
		scroll.y = hero.iy;
	}

	public function save() {
		props.pos.x = hero.ix;
		props.pos.y = hero.iy;
		if( !hxd.Save.save(props,"evo2") )
			return;
		Sounds.play("save");
		popup("Game <font color='#00ff00'>Saved</font>", "You are safe !");
	}

	function js( s : String ) {
		#if js
		trace(s);
		std.js.Syntax.code("eval({0})",s);
		#end
	}

	public function popup( text : String, subText : String = "", dialog = false ) {
		var mc = new Popup();
		mc.dialog = dialog;
		mc.addChild(makePanel(text, subText));
		mc.y = s2d.height;
		mc.targetY = s2d.height - Std.int(mc.getBounds().height) + 2;
		s2d.addChild(mc);
	}

	function makePanel( text : String, subText : String ) {
		var mc = new h2d.Graphics();
		mc.beginFill(0);
		mc.drawRect(0, 0, s2d.width, 40);
		var tf = makeField(text,18);
		tf.x = 4;
		tf.y = 1;
		mc.addChild(tf);
		var tf = makeField(subText, 12);
		tf.x = 6;
		tf.y = 23;
		mc.addChild(tf);
		return mc;
	}

	public static function makeField(text,size:Int) {
		var tf = new h2d.HtmlText(hxd.Res.load("fonts/font"+size+".fnt").to(hxd.res.BitmapFont).toFont());
		if( size == 18 ) tf.letterSpacing--;
		tf.text = text;
		return tf;
	}

	function initPixelFilter( k : Int ) {
		if( pixelFilter == null )
			pixelFilter = new h2d.Bitmap(h2d.Tile.fromTexture(new h3d.mat.Texture(s2d.width,s2d.height)),s2d);
		var p = hxd.Pixels.alloc(s2d.width,s2d.height,RGBA);
		for( x in 0...Std.int(s2d.width / k) )
			for( y in 0...Std.int(s2d.height / k) ) {
				var x = x * k, y = y * k;
				p.setPixel(x, y, 0x40000000);
				for( i in 1...k ) {
					p.setPixel(x + i, y, 0x20000000);
					p.setPixel(x, y + i, 0x20000000);
				}
			}
		pixelFilter.tile.getTexture().uploadPixels(p);
	}

	function doShake() {
		shake = { time : 10, power : 3 };
	}

	public function getChest( k : Chests.ChestKind, x : Int, y : Int ) {
		doShake();
		var sound = "chest";
		props.chests.push((y + (props.dungeon ? World.SIZE : 0)) * World.SIZE + x);
		var extra = "";
		var index : Null<Int> = null;
		switch( k ) {
		case CTitleScreen, CRightCtrl:
			// no fx
		case CLeftCtrl:
			props.left = true;
		case C2D:
			props.bars = false;
		case CScroll:
			index = props.scroll;
			props.scroll++;
		case CColor:
			index = props.color;
			props.color++;
		case CMonsters:
			index = props.monsters;
			props.monsters++;
		case CWeapon:
			index = props.weapons;
			props.weapons++;
		case CZoom:
			shake = null;
			index = 4 - props.zoom;
			props.zoom--;
		case CAllowSave:
			props.canSave = true;
		case CWeb:
			index = props.web;
			props.web++;
			updateWeb();
		case CNpc:
			index = props.npc;
			props.npc++;
		case CGoldCoin:
			props.gold++;
		case CKey:
			props.keys++;
		case CFreeMove:
			props.freeMove = true;
		case CPushBlock:
			// nothing
		case CDungeon:
			hero.teleport(26, 57);
			initDungeon(true);
		case CDungeonKills:
			world.remove(26, 23);
		case CPuzzle:
			props.puzzle = true;
			world.remove(42, 45);
		case CDiablo:
			props.life = 50;
			props.xp = 0;
			updateUI();
		case CLevelUp:
			sound = "levelup";
			props.xp = 0;
			props.level++;
			if( props.level == 10 ) {
				k = CFarming;
				props.xp = -1;
				for( m in monsters.copy() )
					if( m.generated )
						m.kill();
				world.remove(55, 14);
			} else
				extra = "<font color='#00ff00'>" + props.level + '</font> / 10';
			updateUI();
		case CFarming:
			// no
		case CExit:
			// nothing
		case CPrincess:
			win();
		case CPorn:
			props.porn = true;
			updateWeb();
		case CSounds:
			props.sounds = true;
		case CMusic:
			props.music = true;
			hxd.Res.music.play(true);
		}
		Sounds.play(sound);
		var t : Dynamic = Chests.t[Type.enumIndex(k)];
		if( t == null )
			throw "Missing text for " + k + " (" + Type.enumIndex(k) + ")";
		if( index != null )
			t = t[index];
		if( t == null )
			t = { name : "???", sub : "" };
		popup("You got <font color='#ff0000'>"+t.name+"</font>", t.sub+extra);
	}

	function win() {
		hero.lock = true;
		circleSize = 300.;
		mask = new h2d.Graphics(s2d);
		mask.x = s2d.width * 0.5;
		mask.y = s2d.height * 0.5;
		s2d.under(mask);
		update(0);
	}

	function gameOver() {
		if( hero.lock )
			return;
		hero.lock = true;
		hero.target = null;
		hero.moving = false;
		hero.explode();
		hero.remove();
		Sounds.play("gameOver");
		var mc = makePanel("Game <font color='#ff0000'>Over</font> !", "Press Esc to return to title screen");
		mc.y = Std.int((s2d.height - mc.getBounds().height) * 0.5);
		s2d.addChild(mc);
	}

	function updateWeb() {
		var parts = ["banner", "author", "social"];
		for( i in 0...parts.length )
			js("show('" + parts[i] + "'," + (i < props.web) + ")");
		if( props.porn )
			js("show('p0banner',true)");
	}

	override function update( _ ) {

		if( hero == null )
			return;


		switch( props.scroll ) {
		case 0:
			// no
		case 1:
			scroll.x = Std.int(hero.x) * Const.SIZE;
			scroll.y = Std.int(hero.y) * Const.SIZE;
		case 2:
			scroll.x = Std.int(hero.x * Const.SIZE);
			scroll.y = Std.int(hero.y * Const.SIZE);
		default:
		}

		var dt = hxd.Timer.tmod;

		if( circleSize > 200 ) {
			circleSize -= dt;
			mask.clear();
			mask.beginFill(0, 0.5);
			mask.drawCircle(0, 0, circleSize);
			if( circleSize <= 200 ) {
				var letters = "Congratulations !".split("");
				var colors = ["FF0000", "00FF00", "FFFFFF", "FFFF00", "FF00FF", "00FFFF"];
				var c = -1;
				for( i in 0...letters.length ) {
					var col;
					do {
						col = Std.random(colors.length);
					} while( col == c );
					c = col;
					letters[i] = "<font color='#" + colors[c] + "'>" + letters[i] + '</font>';
				}
				var p = makePanel(letters.join(""), "You completed the game !");
				p.y = 0;
				s2d.addChild(p);

				var dun = new World(hxd.Res.dungeon.getPixels());
				var gold = 0, total = 0;
				for( c in world.chests.concat(dun.chests) ) {
					switch( c.id ) {
					case CGoldCoin: gold++;
					default:
					}
					total++;
				}

				var p = makePanel("You found " + (props.gold + 1) + "/"+gold+" Gold Coins", "And opened "+(props.nchests+"/"+total)+" chests");
				p.y = 370;
				s2d.addChild(p);
			}
		}

		var tz = scroll.tz * props.zoom;
		var zooming = true;
		scroll.curZ = scroll.curZ * 0.8 + tz * 0.2;
		if( Math.abs(scroll.curZ - tz) < 0.1 ) {
			zooming = false;
			scroll.curZ = tz;
		}

		var z = scroll.curZ;
		var tx = scroll.x - (s2d.width / z) * 0.5;
		var ty = scroll.y - (s2d.height / z) * 0.5;
		var sx = Std.int(tx * z);
		var sy = Std.int(ty * z);
		if( !zooming ) {
			sx -= sx % props.zoom;
			sy -= sy % props.zoom;
		}
		scroll.mc.x = -sx;
		scroll.mc.y = -sy;
		scroll.mc.scaleX = scroll.mc.scaleY = z;

		hero.update(dt);

		Popup.updateAll(dt);
		Part.updateAll(dt);

		if( hero.target == null && !hero.lock ) {

			for( c in world.chests )
				if( c.e != null && c.x == hero.ix && c.y == hero.iy ) {
					c.e.remove();
					c.e = null;
					props.nchests++;
					getChest(c.id,c.x,c.y);
				}
			hero.moving = false;
			pad.axisDeadZone = 0.5;
			var mx = pad.xAxis, my = pad.yAxis;
			if( mx < 0 && !props.left )
				mx = 0;
			if( my != 0 && props.bars )
				my = 0;
			if( (Key.isDown(K.UP) || Key.isDown("Z".code) || Key.isDown("W".code)) && !props.bars )
				my = -1;
			if( hero.target == null && (Key.isDown(K.DOWN) || Key.isDown("S".code)) && !props.bars )
				my = 1;
			if( hero.target == null && (Key.isDown(K.LEFT) || Key.isDown("Q".code) || Key.isDown("A".code)) && props.left )
				mx = -1;
			if( hero.target == null && Key.isDown(K.RIGHT) || Key.isDown("D".code) )
				mx = 1;
			if( mx != 0 || my != 0 ) {
				var m = Math.sqrt(mx*mx+my*my);
				if( m > 1 ) {
					mx /= m;
					my /= m;
				}
				hero.move(mx,my,dt);
			}
		}

		var cfg = hxd.Pad.DEFAULT_CONFIG;
		if( hero.sword == null && !hero.lock ) {
			if( (Key.isDown(K.SPACE) || Key.isDown(K.ENTER) || Key.isDown("E".code) || pad.isPressed(cfg.X) || pad.isPressed(cfg.A)) && props.weapons > 0 )
				hero.attack();
		}

		if( Key.isPressed(27) || (pad.isPressed(cfg.start) && hero.lock) ) {
			if( !hero.lock )
				gameOver();
			else {
				dispose();
				new Title();
				return;
			}
		}

		// cheat code
		if( Key.isPressed("S".code) && Key.isDown(K.CTRL) )
			save();

		if( props.monsters > 0 ) {
			if( !has.monsters ) {
				has.monsters = true;
				for( m in world.monsters )
					monsters.push(new Monster(m.id, m.x, m.y));
				generators = [];
				for( w in world.getPos(MonsterGenerator) )
					generators.push( { x : w.x, y : w.y, time : 0. } );
			}
			for( m in monsters ) {
				m.update(dt);
				var dx = m.x - hero.x;
				var dy = m.y - hero.y;
				var d = Math.sqrt(dx * dx + dy * dy);
				if( d < 0.64 && m.deathHit() && hero.hitRecover <= 0 ) {
					props.life--;
					updateUI();
					if( props.life <= 0 )
						gameOver();
					else {
						hero.hitRecover = 30;
						Sounds.play("hit");
					}
				}
			}
		}

		if( props.canSave && !has.savePoints ) {
			has.savePoints = true;
			for( p in world.getPos(SavePoint) ) {
				var e = new Entity(SavePoint, p.x, p.y);
				e.mc.alpha = 0.3;
				e.y += 3 / Const.SIZE;
				entities.push(e);
			}
		}

		if( props.npc > 0 && !has.npc ) {
			has.npc = true;
			for( n in world.npcs ) {
				var e = new Entity(NPC, n.x, n.y);
				n.e = e;
				entities.push(n.e);
				world.t[n.x][n.y] = Lock;
			}
		}

		for( e in entities )
			e.update(dt);

		var old = curColor;
		var pixelAlpha = 1.0;
		switch( props.color ) {
		case 0:
			curColor = { delta : 0x40, mask : 0xC0, alpha : 1., rgb : 1., k : props.color };
		case 1:
			curColor = { delta : 0x30, mask : 0x80, alpha : 1., rgb : 0., k : props.color };
		case 2:
			curColor = { delta : 0x10, mask : 0xC0, alpha : .5, rgb : 0., k : props.color };
		case 3:
			curColor = { delta : 0x28, mask : 0xE0, alpha : .25, rgb : 0., k : props.color };
		default:
			curColor = { delta : 0, mask : 0xFF, alpha : 0., rgb : 0., k : props.color };
		}

		curColor = if( old == null ) curColor else {
			delta : old.delta * 0.8 + curColor.delta * 0.2,
			mask : old.mask * 0.8 + curColor.mask * 0.2,
			alpha : old.alpha * 0.8 + curColor.alpha * 0.2,
			rgb : old.rgb * 0.8 + curColor.rgb * 0.2,
			k : old.k * 0.8 + curColor.k * 0.2,
		};

		if( shake != null ) {
			var a = shake.time < 10 ? shake.time / 10 : 1;
			var tx = (Math.random() * 2 - 1) * shake.power * a;
			var ty = (Math.random() * 2 - 1) * shake.power * a;
			s2d.x = tx;
			s2d.y = ty;
			shake.time -= dt;
			if( shake.time < 0 ) {
				shake = null;
				s2d.x = s2d.y = 0;
			}
		}

		outputFilters = [];

		var delta = Std.int(curColor.delta);
		var mask = Math.ceil(curColor.mask);
		if( delta != 0 || mask != 0xFF )
			applyMask(delta, mask);

		if( curColor.rgb > 0.01 ) {
			var r = 155;
			var g = 198;
			var b = 15;
			var f = (0.25 / g) * curColor.rgb;
			var k = 1 - curColor.rgb;
			var m1 = h3d.Matrix.L([
				k + r*f, r*f, r*f, 0,
				g*f, k + g*f, g*f, 0,
				b*f, b*f, k + b*f, 0,
				0, 0, 0, 1
			]);
			m1.tx = 0/255 * curColor.rgb;
			m1.ty = 40/255 * curColor.rgb;
			m1.tz = -40/255 * curColor.rgb;
			m1.colorContrast(curColor.rgb*0.15);
			m1.colorSaturate(-curColor.rgb*0.2);
			var curFilter = new h2d.filter.ColorMatrix(m1);
			outputFilters.push(curFilter);
		}

		pixelFilter.alpha = curColor.alpha;
		pixelFilter.visible = curColor.alpha > 0.01;

		if( generators != null )
		for( g in generators ) {
			var dx = hero.x - g.x;
			var dy = hero.y - g.y;
			var d = dx * dx + dy * dy;
			if( d < 100 && props.xp >= 0 ) {
				g.time -= dt;
				if( g.time < 0 ) {
					var k = switch( Std.random(10) ) {
					case 3, 4, 5: Entity.EKind.Bat;
					case 0, 1, 2: Entity.EKind.Monster;
					case 6, 7: Entity.EKind.Knight;
					default: null;
					}
					if( k != null && monsters.length < 50 ) {
						var m = new Monster(k, g.x, g.y);
						m.generated = true;
						monsters.push(m);
					}
					g.time += 50;
				}
			}
		}

		var size = (Math.ceil(Const.SIZE * scroll.curZ) >> 1) + barsDelta;
		if( props.bars || size < s2d.height * 0.5  ) {
			var color = curColor.rgb == 0 ? 0xFF000000 : 0xFF143214;
			if( bars == null )
				bars = new h2d.Graphics(s2d);
			bars.clear();
			bars.beginFill(color);
			bars.drawRect(0, 0, s2d.width, (s2d.height >> 1) - size - 5);
			bars.drawRect(0, (s2d.height >> 1) + size - 5, s2d.width, s2d.height - (s2d.height >> 1) + size);
			if( !props.bars )
				barsDelta += 5 * dt;
		} else {
			if( bars != null ) {
				bars.remove();
				bars = null;
			}
		}

		if( this.mask != null )
			outputFilters.push(new h2d.filter.Mask(this.mask));

		dm.ysort(Const.PLAN_ENTITY);
		scroll.mc.filter = outputFilters.length == 0 ? null : outputFilters.length == 1 ? outputFilters[0] : new h2d.filter.Group(outputFilters);
	}

	var bitmaskFilter : h2d.filter.Shader<BitmaskShader>;
	function applyMask(delta, mask) {
		if( bitmaskFilter == null )
			bitmaskFilter = new h2d.filter.Shader(new BitmaskShader());
		outputFilters.push(bitmaskFilter);
		bitmaskFilter.shader.delta = delta;
		bitmaskFilter.shader.mask = mask;
	}

	override function dispose() {
		super.dispose();
		hxd.Res.music.stop();
	}

	public static var inst : Game;
	public static var pad : hxd.Pad = hxd.Pad.createDummy();

	static function copy<T>(v:T):T {
		return haxe.Unserializer.run(haxe.Serializer.run(v));
	}

	public static function startGame( load ) {
		props = copy(DEF_PROPS);
		if( load ) {
			props = hxd.Save.load(props,"evo2");
		}
		has.monsters = false;
		has.npc = false;
		has.savePoints = false;
		inst = new Game();
	}

	static function main() {
		#if hl
		hxd.Res.initLocal();
		#else
		hxd.Res.initEmbed();
		#end
		hxd.Pad.wait(function(p) pad = p);
		hxd.Timer.wantedFPS = 40;
		new Title();
	}

}