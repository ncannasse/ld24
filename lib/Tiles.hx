
class Tiles {

	
	public static function initTiles( tiles : flash.display.BitmapData, size : Int ) {
		var colorBG = tiles.getPixel32(tiles.width - 1, tiles.height - 1);
		var t = [];
		for( y in 0...Std.int(tiles.height/size) ) {
			t[y] = [];
			for( x in 0...Std.int(tiles.width/size) ) {
				var b = new flash.display.BitmapData(size, size, true, 0);
				b.copyPixels(tiles, new flash.geom.Rectangle(x * size, y * size, size, size), new flash.geom.Point(0, 0));
				if( isEmpty(b,colorBG) ) {
					b.dispose();
					break;
				}
				t[y].push(b);
			}
		}
		tiles.dispose();
		return t;
	}
	
	
	static function isEmpty( b : flash.display.BitmapData, bg : UInt ) {
		var empty = true;
		for( x in 0...b.width )
			for( y in 0...b.height ) {
				var color = b.getPixel32(x, y);
				if( color != bg )
					empty = false;
				if( Std.int(color) == 0xFFFF00FF )
					b.setPixel32(x, y, 0);
			}
		return empty;
	}
	
}