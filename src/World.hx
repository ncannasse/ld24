using Common;

@:bitmap("world.png") class WorldPNG extends BMP {
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
}

class World {
	
	public static inline var SIZE = 98;
	
	public var t : Array<Array<Block>>;
	public var start : { x : Int, y : Int };
	public var monsters : Array<{ x : Int, y : Int, e : Entity }>;
	public var chests : Array<{ id : Chests.ChestKind, x : Int, y : Int, e : Entity }>;
	
	public var bmp : BMP;
	public var tiles : Array<Array<BMP>>;
	public var removed : Array<Array<Bool>>;
	
	var rnd : Rand;
	var shadeM : flash.geom.Matrix;
	var shadeSPR : SPR;
	var pt : flash.geom.Point;
	var p0 : flash.geom.Point;
	var details : Bool;
	
	public function new() {
		t = [];
		monsters = [];
		chests = [];
		removed = [];
		var bmp = new WorldPNG(0,0);
		for( x in 0...SIZE ) {
			t[x] = [];
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
		shadeSPR = new SPR();
		shadeSPR.graphics.beginFill(0xFF000000, 0.15);
		shadeSPR.graphics.drawEllipse(1, 10, 14, 8);
	}
	
	function initTiles() {
		tiles = Tiles.initTiles(new TilesPNG(0, 0), Const.SIZE);
	}
	
	public function collide(x, y) {
		if( x < 0 || y < 0 || x >= SIZE || y >= SIZE )
			return true;
		return switch( t[x][y] ) {
		case Dark, Tree, Water, Bush, RiverBank: true;
		case BridgeUD, BridgeLR: false;
		case Field, Detail: false;
		}
	}
	
	function getSoil(x, y) {
		if( x < 0 || y < 0 || x >= SIZE || y >= SIZE )
			return Field;
		var b = t[x][y];
		return switch( b ) {
		case Dark, Tree, Bush:
			Field;
		case BridgeLR, BridgeUD:
			Water;
		case Water, Field, RiverBank, Detail:
			b;
		};
	}
	
	public function draw() {
		bmp.fillRect(bmp.rect, 0xFF000000);
		rnd = new Rand(42);
		details = false;
		for( x in 0...SIZE )
			for( y in 0...SIZE ) {
				var b = getSoil(x,y);
				putBlock(x, y, b);
				switch( b ) {
				case Water:
					switch( t[x][y - 1] ) {
					case Water, BridgeLR:
					default:
						putSingle(x, y, RiverBank, 0);
					}
					if( getSoil(x+1,y) != Water )
						putSingle(x, y, RiverBank, 1);
					if( getSoil(x-1,y) != Water )
						putSingle(x, y, RiverBank, 2);
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
				case Tree, Bush:
					putBlock(x, y, b, rnd.random(5) - 2, -rnd.random(3), true, true);
				case Dark:
					if( rnd.random(3) == 0 )
						putBlock(x, y, Tree, rnd.random(5) - 2, rnd.random(2), true, true);
				case BridgeLR, BridgeUD:
					putBlock(x, y, b);
				default:
				}
			}
	}
	
	function putSingle(x, y, b:Block, k : Int ) {
		var tl = tiles[Type.enumIndex(b) - 1];
		if( tl == null || tl.length == 0 ) throw "Not tile for " + b;
		put(x * Const.SIZE, y * Const.SIZE, tl[k%tl.length]);
	}

	function putBlock(x, y, b:Block, dx = 0, dy = 0, shade = false, mrnd = false ) {
		var tx = x * Const.SIZE + dx;
		var ty = y * Const.SIZE + dy;
		if( shade ) {
			shadeM.tx = tx;
			shadeM.ty = ty;
			bmp.draw(shadeSPR, shadeM);
		}
		var tl = tiles[Type.enumIndex(b) - 1];
		var t = tl[min(rnd.random(tl.length), mrnd?rnd.random(tl.length):99)];
		if( t == null || tl.length == 0 ) throw "Not tile for " + b;
		if( !details || !removed[x][y] )
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
		case 0xFFFFFF:
			start = { x : x, y : y };
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
			monsters.push( { x:x, y:y, e:null } );
			return Field;
		default:
			if( col & 0xFFFF00 == 0xFFFF00 ) {
				chests.push( { x:x, y:y, e : null, id : Type.createEnumIndex(Chests.ChestKind,col & 0xFF) } );
				return Field;
			}
			throw "Unknown color 0x" + StringTools.hex(col, 6)+" at ("+x+","+y+")";
		}
	}
	
	
}