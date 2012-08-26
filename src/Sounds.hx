
typedef S = flash.media.Sound;

@:sound("kill.wav")
class Kill extends S {
}

@:sound("walk.wav")
class Walk extends S {
}

@:sound("sword.wav")
class Sword extends S {
}

@:sound("notsure.wav")
class Chest extends S {
}

@:sound("pii.wav")
class Menu extends S {
}

@:sound("fireball.wav")
class Fireball extends S {
}

@:sound("world_remove.wav")
class Open extends S {
}

@:sound("save.wav")
class Save extends S {
}

@:sound("gameover.wav")
class GameOver extends S {
}

@:sound("firehit.wav")
class FireHit extends S {
}

@:sound("npc.wav")
class Npc extends S {
}

@:sound("princess.wav")
class Princess extends S {
}

@:sound("puzzle.wav")
class Puzzle extends S {
}

@:sound("levelup.wav")
class Levelup extends S {
}

@:sound("hit.wav")
class Hit extends S {
}

class Sounds {
	
	static var sounds = new Hash();
	
	public static function play( name : String ) {
		if( !Game.props.sounds )
			return;
		var s : S = sounds.get(name);
		if( s == null ) {
			var cl = Type.resolveClass(name.charAt(0).toUpperCase() + name.substr(1));
			if( cl == null ) throw "No sound " + name;
			s = Type.createInstance(cl, []);
			sounds.set(name, s);
		}
		s.play();
	}
	
}