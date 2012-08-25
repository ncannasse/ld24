using Common;

@:bitmap("world.png") class WorldPNG extends BMP {
}

@:bitmap("tiles.png") class TilesPNG extends BMP {
}

enum Block {
	Dark;
	Field;
	Tree;
}

class World {
	
	public static inline var SIZE = 98;
	
	public var t : Array<Array<Block>>;
	public var start : { x : Int, y : Int };
	public var chests : Array<{ id : Int, x : Int, y : Int, e : Entity }>;
	
	public var bmp : BMP;
	public var tiles : Array<Array<BMP>>;
	
	var rnd : Rand;
	var shadeM : flash.geom.Matrix;
	var shadeSPR : SPR;
	var pt : flash.geom.Point;
	var p0 : flash.geom.Point;
	
	public function new() {
		t = [];
		chests = [];
		var bmp = new WorldPNG(0,0);
		for( x in 0...SIZE ) {
			t[x] = [];
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
		case Dark, Tree: true;
		case Field : false;
		}
	}
	
	public function draw() {
		bmp.fillRect(bmp.rect, 0xFF000000);
		rnd = new Rand(42);
		for( x in 0...SIZE )
			for( y in 0...SIZE ) {
				var b = t[x][y];
				switch( b ) {
				case Dark:
					putBlock(x,y,Field);
				case Tree:
					putBlock(x,y,Field);
				default:
					putBlock(x,y,b);
				}
			}
		for( x in 0...SIZE )
			for( y in 0...SIZE ) {
				var b = t[x][y];
				switch( b ) {
				case Tree:
					putBlock(x, y, Tree, rnd.random(5) - 2, rnd.random(2), true, true);
				case Dark:
					if( rnd.random(3) == 0 )
						putBlock(x, y, Tree, rnd.random(5) - 2, rnd.random(2), true, true);
				default:
				}
			}
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
		put(tx, ty, tl[min(rnd.random(tl.length), mrnd?rnd.random(tl.length):99)]);
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
		default:
			if( col & 0xFFFF00 == 0xFFFF00 ) {
				chests.push( { x:x, y:y, e : null, id : col & 0xFF } );
				return Field;
			}
			throw "Unknown color 0x" + StringTools.hex(col, 6)+" at ("+x+","+y+")";
		}
	}
	
	
}