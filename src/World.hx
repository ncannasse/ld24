using Common;

@:bitmap("world.png") class WorldPNG extends BMP {
}

@:bitmap("dungeon.png") class DungeonPNG extends BMP {
}

@:bitmap("tiles.png") class TilesPNG extends BMP {
}

enum Block {
	Dark;
	Field;
	Tree;
	Water;
	BridgeUD;
	BridgeLR;
	Bush;
	RiverBank;
	Detail;
	Rock;
	SavePoint;
	Sand;
	SandBank;
	SandDetail;
	Cactus;
	Door;
	Dungeon;
	DungeonSoil;
	DungeonWall;
	DungeonStat;
	DungeonStairs;
	DungeonFakeWall;
	DungeonPuzzle;
	MonsterGenerator;
	FakeTree;
	DungeonExit;
	// extra
	DarkDungeon;
	Lock;
	Free;
	DungeonFakeDark;
}

class World {
	
	public static inline var SIZE = 98;
	
	public var t : Array<Array<Block>>;
	public var monsters : Array<{ x : Int, y : Int, id : Entity.EKind }>;
	public var chests : Array<{ id : Chests.ChestKind, x : Int, y : Int, e : Entity }>;
	public var npcs : Array < { x:Int, y:Int, e:Entity }>;
	
	public var bmp : BMP;
	public var tiles : Array<Array<BMP>>;
	public var removed : Array<Array<Bool>>;
	var removedBitmaps : Array<Array<BMP>>;
	
	var rnd : Rand;
	var shadeM : flash.geom.Matrix;
	var shadeSPR : Array<SPR>;
	var pt : flash.geom.Point;
	var p0 : flash.geom.Point;
	var details : Bool;
	
	public function new( bmp : BMP ) {
		t = [];
		monsters = [];
		chests = [];
		removed = [];
		npcs = [];
		removedBitmaps = [];
		for( x in 0...SIZE ) {
			t[x] = [];
			removedBitmaps[x] = [];
			removed[x] = [];
			for( y in 0...SIZE )
				t[x][y] = decodeColor(bmp, x, y);
		}
		bmp.dispose();
		initTiles();
		pt = new flash.geom.Point();
		p0 = new flash.geom.Point();
		this.bmp = new BMP(SIZE * Const.SIZE, SIZE * Const.SIZE, true, 0);
		shadeM = new flash.geom.Matrix();
		var s0 = new SPR();
		s0.graphics.beginFill(0xFF000000, 0.15);
		s0.graphics.drawEllipse(1, 10, 14, 8);
		var s1 = new SPR();
		s1.graphics.beginFill(0xFF000000, 0.15);
		s1.graphics.drawEllipse(2, 11, 6, 5);
		shadeSPR = [s0, s1];
	}
	
	function initTiles() {
		tiles = Tiles.initTiles(new TilesPNG(0, 0), Const.SIZE);
	}
	
	public function collide(x, y) {
		if( x < 0 || y < 0 || x >= SIZE || y >= SIZE )
			return true;
		if( removed[x][y] )
			return false;
		return switch( t[x][y] ) {
		case Dark, Tree, Water, Bush, Rock, Cactus, Lock, Door, DarkDungeon, DungeonWall, DungeonStat: true;
		case BridgeUD, BridgeLR, Dungeon, MonsterGenerator: false;
		case Field, SavePoint, Sand, Free, DungeonSoil, FakeTree: false;
		case SandBank, RiverBank, Detail, SandDetail, DungeonStairs, DungeonFakeWall, DungeonFakeDark, DungeonPuzzle, DungeonExit: false;
		}
	}
	
	function getSoil(x, y, rec=false) : Block {
		if( x < 0 || y < 0 || x >= SIZE || y >= SIZE )
			return Field;
		var b = t[x][y];
		return switch( b ) {
		case Dark, Tree, Bush, Rock, SavePoint, Cactus, Lock, Free, Door, Dungeon, FakeTree:
			if( rec ) return null;
			var cur : Block = null;
			var s = getSoil(x, y - 1, true);
			if( cur == null || (s != null && Type.enumIndex(s) < Type.enumIndex(cur)) ) cur = s;
			var s = getSoil(x, y + 1, true);
			if( cur == null || (s != null && Type.enumIndex(s) < Type.enumIndex(cur)) ) cur = s;
			var s = getSoil(x - 1, y, true);
			if( cur == null || (s != null && Type.enumIndex(s) < Type.enumIndex(cur)) ) cur = s;
			var s = getSoil(x + 1, y, true);
			if( cur == null || (s != null && Type.enumIndex(s) < Type.enumIndex(cur)) ) cur = s;
			if( cur == null ) cur = Field;
			cur;
		case BridgeLR, BridgeUD, Water:
			if( rec ) null else Water;
		case Field, Sand, DungeonSoil:
			b;
		case DungeonWall,DungeonStat,DungeonStairs,DungeonFakeWall,DungeonPuzzle,MonsterGenerator, DungeonExit:
			DungeonSoil;
		case Detail, RiverBank, SandBank, SandDetail:
			null;
		case DarkDungeon, DungeonFakeDark:
			null;
		};
	}
	
	public function remove(x, y) {
		if( removed[x][y] )
			return false;
		removed[x][y] = true;
		Game.props.rem.push(x + (y + (Game.props.dungeon?SIZE:0)) * SIZE);
		Sounds.play("open");
		draw();
		var b = removedBitmaps[x][y];
		if( b != null )
			Part.explode(b, x * Const.SIZE, y * Const.SIZE);
		return true;
	}
	
	public function getPos(b) {
		var pos = [];
		for( x in 0...SIZE )
			for( y in 0...SIZE )
				if( t[x][y] == b )
					pos.push( { x:x, y:y } );
		return pos;
	}
	
	public function draw() {
		var t0 = flash.Lib.getTimer();
		bmp.fillRect(bmp.rect, 0xFF000000);
		rnd = new Rand(42);
		details = false;
		for( x in 0...SIZE )
			for( y in 0...SIZE ) {
				var b = getSoil(x, y);
				if( b == null ) continue;
				putBlock(x, y, b);
				switch( b ) {
				case Water:
					switch( getSoil(x,y-1) ) {
					case Water:
					case Sand:
						putSingle(x, y, SandBank, 0);
					default:
						putSingle(x, y, RiverBank, 0);
					}
					var s;
					if( (s=getSoil(x+1,y)) != Water )
						putSingle(x, y, s == Sand ? SandBank : RiverBank, 1);
					if( (s=getSoil(x-1,y)) != Water )
						putSingle(x, y, s == Sand ? SandBank : RiverBank, 2);
				case Field:
					if( getSoil(x,y-1) == Sand )
						putSingle(x, y, SandBank, 0);
					if( getSoil(x+1,y) == Sand )
						putSingle(x, y, SandBank, 1);
					if( getSoil(x-1,y) == Sand )
						putSingle(x, y, SandBank, 2);
					if( getSoil(x,y+1) == Sand )
						putSingle(x, y, SandBank, 3);
				default:
				}
			}
		details = true;
		for( x in 0...SIZE )
			for( y in 0...SIZE ) {
				var b = t[x][y];
				switch( b ) {
				case Field:
					if( rnd.random(3) == 0 )
						putBlock(x, y, Detail, rnd.random(7) - 3, -rnd.random(4));
				case Sand:
					if( rnd.random(3) == 0 )
						putBlock(x, y, SandDetail, rnd.random(7) - 3, -rnd.random(4));
				case Tree:
					putBlock(x, y, b, rnd.random(5) - 2, -rnd.random(3), 0, true);
				case Rock, Bush:
					putBlock(x, y, b, rnd.random(5) - 2, -rnd.random(3), 0);
				case Cactus:
					putBlock(x, y, b, rnd.random(5) - 2, -rnd.random(3), 1);
				case Dark:
					if( rnd.random(3) == 0 )
						putBlock(x, y, Tree, rnd.random(5) - 2, rnd.random(2), 0, true);
				case DungeonExit:
					putBlock(x, y, DungeonStairs);
				case BridgeLR, BridgeUD, SavePoint, Door, Dungeon, DungeonStat,DungeonStairs, DungeonWall, DungeonFakeWall,DungeonPuzzle,MonsterGenerator,FakeTree:
					putBlock(x, y, b);
				default:
				}
			}
		//trace(flash.Lib.getTimer() - t0);
	}
	
	function putSingle(x, y, b:Block, k : Int ) {
		var tl = tiles[Type.enumIndex(b) - 1];
		if( tl == null || tl.length == 0 ) throw "Not tile for " + b;
		put(x * Const.SIZE, y * Const.SIZE, tl[k%tl.length]);
	}

	function putBlock(x, y, b:Block, dx = 0, dy = 0, shade = -1, mrnd = false ) {
		var tx = x * Const.SIZE + dx;
		var ty = y * Const.SIZE + dy;
		var rem = details && removed[x][y];
		if( shade >= 0 && !rem ) {
			shadeM.tx = tx;
			shadeM.ty = ty;
			bmp.draw(shadeSPR[shade], shadeM);
		}
		var tl = tiles[Type.enumIndex(b) - 1];
		var t = tl == null ? null : tl[min(rnd.random(tl.length), mrnd?rnd.random(tl.length):99)];
		if( t == null || tl.length == 0 ) throw "Not tile for " + b;
		if( details && rem )
			removedBitmaps[x][y] = t;
		else
			put(tx, ty, t);
	}
	
	inline function min(x:Int, y:Int) {
		return x < y ? x : y;
	}
	
	function put(x, y, b:BMP) {
		pt.x = x;
		pt.y = y;
		bmp.copyPixels(b, b.rect, pt, b, p0, true);
	}
	
	function decodeColor( bmp : BMP, x, y ) {
		var col = bmp.getPixel(x, y);
		switch( col ) {
		case 0, 0xDA02A7:
			return Dark;
		case 0x0F6D01:
			return Tree;
		case 0x64FD4D:
			return Field;
		case 0x65B4FB:
			return Water;
		case 0x792D01:
			return BridgeUD;
		case 0xE65400:
			return BridgeLR;
		case 0x1EDA02:
			return Bush;
		case 0xDA0205:
			monsters.push( { x:x, y:y, id : Monster } );
			return decodeColor(bmp, x, y - 1);
		case 0xFD2B2E:
			monsters.push( { x:x, y:y, id : Bat } );
			return decodeColor(bmp, x, y - 1);
		case 0x9E9E9E:
			return Rock;
		case 0x023ADA:
			return SavePoint;
		case 0xE8FD4D:
			return Sand;
		case 0x6FC418:
			return Cactus;
		case 0xFD4DD3:
			npcs.push( { x:x, y:y, e:null } );
			return Free;
		case 0xC49918:
			return Door;
		case 0x585F5C:
			return Dungeon;
		case 0x0E0B0E:
			return DarkDungeon;
		case 0x8A8A8A:
			return DungeonSoil;
		case 0xC5D8C6:
			return DungeonWall;
		case 0x4E7450:
			return DungeonStat;
		case 0xA66E6E:
			return DungeonStairs;
		case 0xA70204:
			monsters.push( { x:x, y:y, id : Knight } );
			return decodeColor(bmp, x, y - 1);
		case 0x92AFA7:
			return DungeonFakeWall;
		case 0x392D39:
			return DungeonFakeDark;
		case 0x4DFDBA:
			return DungeonPuzzle;
		case 0x973902:
			return MonsterGenerator;
		case 0x0F4D01:
			return FakeTree;
		case 0x9ABC9C:
			return DungeonExit;
		default:
			if( col & 0xFFFF00 == 0xFFFF00 ) {
				chests.push( { x:x, y:y, e : null, id : Type.createEnumIndex(Chests.ChestKind,col & 0xFF) } );
				return Field;
			}
			throw "Unknown color 0x" + StringTools.hex(col, 6)+" at ("+x+","+y+")";
		}
	}
	
	
}