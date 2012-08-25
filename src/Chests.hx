
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
	CGoldCoin;
	CKey;
	// misc
	CTitleScreen;
	CRightCtrl;
}

class Chests  {
	
	public static var t : Array<Dynamic> = [
		{ name : "Left Key", sub : "Always right is boring !" },
		{ name : "2D Movement", sub : "You can't go anywhere else anyway" },
		[
			{ name : "Basic Scrolling", sub : "You want to see where you're heading, right ?" },
			{ name : "Smoother Scrolling", sub : "Will save you some headache" },
		],
		[
			{ name : "64 Colors Display", sub : "OMG ! Color !!" },
			{ name : "128 Colors Display", sub : "Mooorreee !! Coloooor !!" },
			{ name : "512 Colors Display", sub : "This is almost real graphics, no ?" },
			{ name : "True Colors Display", sub : "At last, RGB !" },
		],
		[
			{ name : "Monsters !", sub : "Be careful not to touch them !" },
		],
		[
			{ name : "Sword", sub : "Now you can kill the evil monsters" },
		],
		[
			{ name : "VGA Resolution", sub : "Now that looks like some old PC game !" },
		],
		{ name : "Save Points", sub : "An evolutation that changed gaming forever..." },
		[
			{ name : "Ad Banner", sub : "Developers have somehow to pay for their own food, no ?" },
			{ name : "P0rn Banner", sub : "Classic ads don't make enough money..." },
			{ name : "Social Links", sub : "Share with your friends !" },
		],
		[
			{ name : "NPC", sub : "It's nice to be able to talk to someone !" },
			{ name : "Quest System", sub : "It's even better if NPC have some actual usefulness !" },
		],
		{ name : "Gold Coin", sub : "This is a shiny piece of gold !" },
		{ name : "Key", sub : "You found a key !!! What does it open ?" },
		// misc
		{ name : "Title Screen", sub : "There's always a starting point somewhere" },
		{ name : "Right Key", sub : "There seems to be some chest to open this way" },
	];
	
}