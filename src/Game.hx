using Common;

class Game implements haxe.Public {
	
	var root : SPR;
	var view : SPR;
	var world : World;
	var realWorld : World;
	var worldBMP : flash.display.Bitmap;
	var scroll : { x : Float, y : Float, mc : SPR, curZ : Float, tz : Float };
	var hero : Hero;
	var output : BMP;
	var outputBMP : flash.display.Bitmap;
	var pixelFilter : BMP;
	var dm : DepthManager;
	
	var entities : Array<Entity>;
	var barsDelta : Float;
	var curColor : { mask : Float, delta : Float, alpha : Float, rgb : Float, k : Float };
	var shake : { time : Float, power : Float };
	var generators : Array<{ x : Int, y : Int, time : Float }>;
	var monsters : Array<Monster>;
	
	var saveObj : flash.net.SharedObject;
	var savedData : String;
	
	var uiBar : SPR;
	
	var music : flash.media.Sound;
	
	var circleSize : Float;
	var mask : SPR;
	
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
	
	function new(root) {
		this.root = root;
		saveObj = flash.net.SharedObject.getLocal("ld24save");
		try {
			savedData = saveObj.data.save;
			props = haxe.Unserializer.run(savedData);
			if( props.quests == null ) props.quests = [];
			if( props.rem == null ) props.rem = [];
		} catch( e : Dynamic ) {
			savedData = null;
		}
	}
	
	public function hasSave() {
		return savedData != null;
	}
	
	function init() {
		
		var purl = root.loaderInfo.url.split("/");
		purl.pop();
		var murl = purl.join("/") + "/music1.mp3";
		music = new flash.media.Sound(new flash.net.URLRequest(murl));
		
		monsters = [];
		entities = [];
		view = new SPR();
		barsDelta = 0.;
		output = new BMP(root.stage.stageWidth, root.stage.stageHeight);
		outputBMP = new flash.display.Bitmap(output);
		root.addChild(outputBMP);
		
		initPixelFilter(props.zoom);
		
		world = new World(new World.WorldPNG(0, 0));
		realWorld = world;
				
		for( r in props.rem )
			world.removed[r % World.SIZE][Std.int(r / World.SIZE)] = true;
		
		world.draw();
		scroll = { x : (props.pos.x + 0.5) * Const.SIZE, y : (props.pos.y + 0.5) * Const.SIZE, mc : new SPR(), curZ : props.zoom, tz : 1. };
		scroll.mc.x = -1000;
		worldBMP = new flash.display.Bitmap(world.bmp);
		scroll.mc.addChild(worldBMP);
		dm = new DepthManager(scroll.mc);
		view.addChild(scroll.mc);
		
		var hchests = new IntHash();
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
		
		update();
		
		if( props.chests.length == 0 )
			getChest(CRightCtrl, 0, 0);
			
		if( props.music )
			music.play(2, 99999);
			
		updateUI();
		updateWeb();
	}
	
	function updateUI() {
		if( uiBar == null ) {
			uiBar = new SPR();
			uiBar.x = 5;
			uiBar.y = 5;
			root.addChild(uiBar);
			uiBar.scaleX = uiBar.scaleY = 2;
		}
		var border = 0xF0F0F0;
		var bg = 0x606060;
		var g = uiBar.graphics;
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
	
	function initDungeon(v) {
		props.dungeon = v;
		
		
		for( c in world.chests )
			if( c.e != null ) {
				c.e.remove();
				c.e = null;
			}
		
		if( v ) {
			world = new World(new World.DungeonPNG(0, 0));
			for( r in props.rem ) {
				var y = Std.int(r / World.SIZE);
				if( y >= World.SIZE )
					world.removed[r % World.SIZE][y-World.SIZE] = true;
			}
		}
		else
			world = realWorld;
			
		var hchests = new IntHash();
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
		worldBMP.bitmapData = world.bmp;
		scroll.x = hero.ix;
		scroll.y = hero.iy;
	}
	
	function save() {
		props.pos.x = hero.ix;
		props.pos.y = hero.iy;
		var d = haxe.Serializer.run(props);
		if( savedData == d )
			return;
		Sounds.play("save");
		savedData = d;
		saveObj.setProperty("save",savedData);
		saveObj.flush();
		popup("Game <font color='#00ff00'>Saved</font>", "You are safe !");
	}
	
	function js( s : String ) {
		if( !flash.external.ExternalInterface.available )
			return;
		flash.external.ExternalInterface.call("eval", s);
	}
	
	function popup( text : String, subText : String = "", dialog = false ) {
		var mc = new Popup();
		mc.dialog = dialog;
		mc.addChild(makePanel(text, subText));
		mc.y = output.height;
		mc.targetY = output.height - mc.height;
		root.addChild(mc);
	}
	
	function makePanel( text : String, subText : String ) {
		var mc = new SPR();
		mc.graphics.beginFill(0);
		mc.graphics.drawRect(0, 0, output.width, 40);
		var tf = makeField(text);
		tf.x = tf.y = 3;
		mc.addChild(tf);
		var tf = makeField(subText, 14);
		tf.x = 3;
		tf.y = 22;
		mc.addChild(tf);
		return mc;
	}
	
	function makeField(text,size=20) {
		var tf = new TF();
		var fmt = tf.defaultTextFormat;
		fmt.font = "BmpFont";
		fmt.size = size;
		fmt.color = 0xFFFFFF;
		tf.defaultTextFormat = fmt;
		tf.embedFonts = true;
		tf.sharpness = 400;
		tf.gridFitType = flash.text.GridFitType.PIXEL;
		tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
		tf.selectable = tf.mouseEnabled = false;
		tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
		tf.width = 0;
		tf.height = 20;
		tf.htmlText = text;
		return tf;
	}
	
	
	function initPixelFilter( k : Int ) {
		if( pixelFilter != null )
			pixelFilter.fillRect(pixelFilter.rect, 0);
		else
			pixelFilter = new BMP(output.width, output.height, true, 0);
		for( x in 0...Std.int(output.width / k) )
			for( y in 0...Std.int(output.height / k) ) {
				var x = x * k, y = y * k;
				pixelFilter.setPixel32(x, y, 0x40000000);
				for( i in 1...k ) {
					pixelFilter.setPixel32(x + i, y, 0x20000000);
					pixelFilter.setPixel32(x, y + i, 0x20000000);
				}
			}
	}
	
	function doShake() {
		shake = { time : 10, power : 3 };
	}
	
	function getChest( k : Chests.ChestKind, x : Int, y : Int ) {
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
			music.play(0, 99999);
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
		mask = new SPR();
		mask.x = output.width / 2;
		mask.y = output.height / 2;
		root.addChild(mask);
		outputBMP.mask = mask;
		update();
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
		mc.y = Std.int((output.height - mc.height) * 0.5);
		root.addChild(mc);
	}
	
	function updateWeb() {
		var parts = ["banner", "author", "social"];
		for( i in 0...parts.length )
			js("show('" + parts[i] + "'," + (i < props.web) + ")");
		if( props.porn )
			js("show('p0banner',true)");
	}
	
	function update() {
		Timer.update();
		
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
		
		var dt = Timer.tmod;
				
		if( circleSize > 200 ) {
			circleSize -= dt;
			mask.graphics.clear();
			mask.graphics.beginFill(0, 0.5);
			mask.graphics.drawCircle(0, 0, circleSize);
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
				root.addChild(p);
				
				var dun = new World(new World.DungeonPNG(0, 0));
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
				root.addChild(p);
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
		var tx = scroll.x - (root.stage.stageWidth / z) * 0.5;
		var ty = scroll.y - (root.stage.stageHeight / z) * 0.5;
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
			if( (Key.isDown(K.UP) || Key.isDown("Z".code) || Key.isDown("W".code)) && !props.bars )
				hero.move(0, -1, dt);
			if( hero.target == null && (Key.isDown(K.DOWN) || Key.isDown("S".code)) && !props.bars )
				hero.move(0, 1, dt);
			if( hero.target == null && (Key.isDown(K.LEFT) || Key.isDown("Q".code) || Key.isDown("A".code)) && props.left )
				hero.move( -1, 0, dt);
			if( hero.target == null && Key.isDown(K.RIGHT) || Key.isDown("D".code) )
				hero.move(1, 0, dt);
		}
		
		if( hero.sword == null && !hero.lock ) {
			if( (Key.isDown(K.SPACE) || Key.isDown(K.ENTER) || Key.isDown("E".code)) && props.weapons > 0 )
				hero.attack();
		}
		
		if( Key.isToggled(27) ) {
			if( !hero.lock )
				gameOver();
			else {
				js("document.location.reload()");
			}
		}

		// cheat code
		if( Key.isToggled("S".code) && Key.isDown(K.CONTROL) )
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
				var d = dx * dx + dy * dy;
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
			curColor = { delta : 0x28, mask : 0xE0, alpha : .5, rgb : 0., k : props.color };
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
			var m = new flash.geom.Matrix();
			var a = shake.time < 10 ? shake.time / 10 : 1;
			m.tx = (Math.random() * 2 - 1) * shake.power * a;
			m.ty = (Math.random() * 2 - 1) * shake.power * a;
			output.draw(view, m);
			shake.time -= dt;
			if( shake.time < 0 )
				shake = null;
		} else
			output.draw(view);
		
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
			var curFilter = new flash.filters.ColorMatrixFilter([
				k + r*f, r*f, r*f, 0, 20 * curColor.rgb,
				g*f, k + g*f, g*f, 0, 50 * curColor.rgb,
				b*f, b*f, k + b*f, 0, 20 * curColor.rgb,
				0,0,0,1,0,
			]);
			output.applyFilter(output, output.rect, new flash.geom.Point(0, 0), curFilter);
		}
		
		if( curColor.alpha > 0.01 )
			output.draw(pixelFilter, null, new flash.geom.ColorTransform(1, 1, 1, curColor.alpha));
			
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
		if( props.bars || size < output.height * 0.5  ) {
			var color = curColor.rgb == 0 ? 0xFF000000 : 0xFF143214;
			output.fillRect(new flash.geom.Rectangle(0, 0, output.width, (output.height >> 1) - size), color);
			output.fillRect(new flash.geom.Rectangle(0, (output.height >> 1) + size, output.width, output.height - (output.height >> 1) + size ), color);
			if( !props.bars )
				barsDelta += 5 * dt;
		}
		
		dm.ysort(Const.PLAN_ENTITY);
	}
	
	function applyMask(delta, mask) {
		var bytes = output.getPixels(output.rect);
		flash.Memory.select(bytes);
		var p = 0;
		for( i in 0...output.width * output.height ) {
			var c = flash.Memory.getByte(p) + delta;
			if( c > 0xFF ) c = 0xFF;
			flash.Memory.setByte(p++, c & mask);
			var c = flash.Memory.getByte(p) + delta;
			if( c > 0xFF ) c = 0xFF;
			flash.Memory.setByte(p++, c & mask);
			var c = flash.Memory.getByte(p) + delta;
			if( c > 0xFF ) c = 0xFF;
			flash.Memory.setByte(p++, c & mask);
			p++;
		}
		bytes.position = 0;
		output.setPixels(output.rect,bytes);
	}
	
	public static var inst : Game;
	static function main() {
		inst = new Game(flash.Lib.current);
		inst.root.addEventListener(flash.events.Event.ENTER_FRAME, function(_) inst.update());
		var url = inst.root.loaderInfo.url;
		if( StringTools.startsWith(url, "http://evoland.shirogame.com/") || StringTools.startsWith(url, "http://evoland.shiro.fr/") || StringTools.startsWith(url, "file://") ) {
			Key.init();
			var title = new Title(inst);
		}
	}
	
}