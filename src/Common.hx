
typedef SPR = flash.display.Sprite;
typedef BMP = flash.display.BitmapData;

typedef TF = flash.text.TextField;

class Const implements haxe.Public {

	static inline var SIZE = 16;

	static inline var PLAN_SHADE = 1;
	
	static inline var PLAN_ENTITY = 3;
	static inline var PLAN_PART = 4;
	
}

class Tools {
	public static function remove( i : flash.display.DisplayObject ) {
		if( i != null && i.parent != null ) i.parent.removeChild(i);
	}
}
