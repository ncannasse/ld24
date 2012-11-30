using Common;

class Popup extends SPR {

	public var virtualY : Float;
	public var targetY : Float;
	public var startY : Float;
	public var speed : Float;
	public var wait : Float;
	public var dialog : Bool;
	
	static var all = new Array<Popup>();
	
	public function new() {
		super();
		speed = 4;
		wait = 0;
		all.push(this);
	}
	
	function update(dt:Float) {
		if( wait > 0 ) {
			wait -= dt;
			return true;
		}
		if( Math.isNaN(startY) ) {
			startY = y;
			virtualY = y;
		}
		virtualY -= dt * speed;
		if( virtualY < targetY ) {
			virtualY = targetY;
			wait = speed * 30;
			speed = -speed * 0.5;
		}
		y = Std.int(virtualY);
		if( virtualY > stage.stageHeight )
			return false;
		return true;
	}
	
	public static function hasDialog() {
		for( p in all )
			if( p.dialog )
				return true;
		return false;
	}
	
	public static function updateAll( dt ) {
		for( p in all.copy() )
			if( !p.update(dt) ) {
				p.parent.removeChild(p);
				all.remove(p);
			}
	}

}