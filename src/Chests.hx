
enum ChestKind {
	CLeftCtrl;
	C2D;
	CScroll;
	CColor;
	CMonsters;
	CWeapon;
	CZoom;
	CAllowSave;
	CWeb;
	CNpc;
	CGoldCoin; // 10
	CKey;
	CFreeMove;
	CDiablo;
	CExit;
	CPorn;
	CSounds;
	CMusic;
	// misc
	CTitleScreen;
	CRightCtrl;
	CPushBlock;
	CDungeon;
	CDungeonKills;
	CPuzzle;
	CLevelUp;
	CFarming;
	CPrincess;
}

class Chests  {
	
	public static var t : Array<Dynamic> = [
		{ name : "Left Key", sub : "Always going right is boring !" },
		{ name : "2D Movement", sub : "Lucky ! You can't go anywhere else anyway" },
		[
			{ name : "Basic Scrolling", sub : "You want to see where you're heading, right ?" },
			{ name : "Smoother Scrolling", sub : "Will save you some headache" },
		],
		[
			{ name : "16 Colors Display", sub : "OMG ! Color !!" },
			{ name : "64 Colors Display", sub : "Mooorreee !! Coloooor !!" },
			{ name : "256 Colors Display", sub : "This is almost real graphics, no ?" },
			{ name : "True Colors Display", sub : "At last, RGB !" },
		],
		[
			{ name : "Monsters !", sub : "Be careful not to touch them !" },
			{ name : "Powerful Monsters", sub : "Make sure you have saved your game" },
		],
		[
			{ name : "Sword", sub : "Now you can kill the evil monsters, and cut bushes" },
		],
		[
			{ name : "VGA Resolution", sub : "Now it looks like some good-old game !" },
			{ name : "HD Resolution", sub : "Sorry, no 3D yet !" },
		],
		{ name : "Save Points", sub : "An evolution that changed gaming forever..." },
		[
			{ name : "Ad Banner", sub : "Developers have somehow to pay for their own food, no ?" },
			{ name : "Social Links", sub : "Share with your friends !" },
		],
		[
			{ name : "NPC", sub : "It's nice to be able to talk to someone !" },
			{ name : "Quest System", sub : "It's even better if NPC have some actual usefulness !" },
		],
		{ name : "Gold Coin", sub : "This is a shiny piece of gold !" },
		{ name : "Key", sub : "You found a key !!! What does it open ?" },
		{ name : "Free Movement", sub : "Looks like it's time for some action/adventure !" },
		{ name : "Diablo Mode", sub : "A life bar and some XP system !" },
		{ name : "Triforce", sub : "Dungeon cleared ! Time to go back to overworld !" },
		{ name : "P0rn Banner", sub : "Classic ads don't make enough money..." },
		{ name : "Sounds FX", sub : "The game looks much more alive this way" },
		{ name : "Music", sub : "Always good for better ambient" },
		// misc
		{ name : "Title Screen", sub : "There's always a starting point somewhere" },
		{ name : "Right Key", sub : "There seems to be some chest to open this way" },
		{ name : "Secret Block !", sub : "Ta-da-da-dam !" },
		{ name : "Dungeons", sub : "My passion : explore dark caves filled with hungry monsters" },
		{ name : "Killed-all-monsters", sub : "Good boy ! You get a bonus for this !" },
		{ name : "Puzzle Solved !", sub : "Real adventurers must be strong AND smart" },
		{ name : "Level Up !", sub : "You have reached level " },
		{ name : "Monster Farming !", sub : "What that ACTUALLY funny ?" },
		{ name : "Princess", sub : "Time to make new adventurers, maybe ?" },
	];
	
}