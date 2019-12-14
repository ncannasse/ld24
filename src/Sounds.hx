
class Sounds {

	static var sounds = new Map();

	public static function play( name : String ) {
		if( !Game.props.sounds )
			return;
		var s = sounds.get(name);
		if( s == null ) {
			s = hxd.Res.load("sfx/"+name.toLowerCase()+".wav").toSound();
			sounds.set(name, s);
		}
		s.play();
	}

}