
class DepthManager {

	var root : flash.display.DisplayObjectContainer;
	var plans : Array<flash.display.DisplayObject>;
	var baseChildren : Int;

	public function new(r) {
		root = r;
		baseChildren = root.numChildren;
		plans = new Array();
	}

	public function getMC() {
		return root;
	}
	
	/**
	 * get the whole plan displayobject
	 */
	public function getPlan( n ) {
		var pmc = plans[n];
		if( pmc != null )
			return pmc;
		pmc = new flash.display.Shape();
		pmc.visible = false;
		pmc.name = "Plan#"+n;
		root.addChildAt(pmc,getBottom(n));
		plans[n] = pmc;
		return pmc;
	}
	
	/**
	 * Get index of the lowest element in the plan
	 * @param	p	A plan id
	 */
	function getBottom( plan:Int ) : Int {
		var n = plan;
		while( --n >= 0 ) {
			var mc = plans[n];
			if( mc != null )
				return root.getChildIndex(mc)+1;
		}
		// we can't use numChildren since we don't want to insert
		// after the plans that have already been created
		// but we can't use 0 either since there might be library
		// objects that have been added to the clip
		return baseChildren;
	}

	function getMCPlan( mc : flash.display.DisplayObject ) {
		var idx = root.getChildIndex(mc);
		for( p in 0...plans.length ) {
			var mc = plans[p];
			if( mc != null && root.getChildIndex(mc) > idx )
				return p;
		}
		return 0;
	}

	#if dm_obfu
	
	/**
	 * @deprecated
	 */
	public inline function attach( inst : String, plan : Int ) {
		return attachObfu(untyped __unprotect__(inst),plan);
	}
	
	/**
	 * @deprecated
	 */
	public function attachObfu( inst : String, plan : Int ) {
		var mc = flash.Lib.attach(inst);
		root.addChildAt(mc,root.getChildIndex(getPlan(plan)));
		return mc;
	}

	#else
	
	/**
	 * Old school attach movie clip to plan
	 * @deprecated
	 */
	public function attach( inst : String, plan : Int ) {
		var mc = flash.Lib.attach(inst);
		root.addChildAt(mc,root.getChildIndex(getPlan(plan)));
		return mc;
	}

	#end
	
	/**
	 * Adds an empty movieclip in this plan
	 */
	public function empty( plan : Int ) {
		var mc = new flash.display.MovieClip();
		root.addChildAt(mc,root.getChildIndex(getPlan(plan)));
		return mc;
	}
	
	/**
	 * Add a movieclip to the plan's display list
	 */
	public function add<T>( _mc : T, plan : Int ) : T {
		var mc = flash.Lib.as(_mc,flash.display.DisplayObject);
		if( mc.parent != null ) mc.parent.removeChild(mc);
		root.addChildAt(mc,root.getChildIndex(getPlan(plan)));
		return _mc;
	}

	/**
	 * Put the clip at the highest depth
	 * @param	mc
	 */
	public function over( mc : flash.display.DisplayObject ) {
		var plan = getMCPlan(mc);
		// minus-one because it's removed before
		root.addChildAt(mc,root.getChildIndex(getPlan(plan))-1);
	}

	/**
	 * Put the clip at the lowest depth
	 * @param	mc
	 */
	public function under( mc : flash.display.DisplayObject ) {
		var plan = getMCPlan(mc);
		root.addChildAt(mc,getBottom(plan));
	}

	/**
	 * Y-Sorting of movieclips in a plan
	 */
	public function ysort( plan : Int ) {
		var y : Float = -99999999;
		var start = getBottom(plan);
		var last = root.getChildIndex(getPlan(plan));
		for( i in start...last ) {
			var mc = root.getChildAt(i);
			var mcy = mc.y;
			if( mcy >= y )
				y = mcy;
			else {
				var j = i - 1;
				while( j >= start ) {
					var mc2 = root.getChildAt(j);
					if( mc2.y <= mcy )
						break;
					j--;
				}
				root.addChildAt(mc,j+1);
			}
		}
	}
	
	/**
	 * Removes all clips in the plan
	 */
	public function clear( plan : Int ) {
		var pmc = getPlan(plan);
		var pos = getBottom(plan);
		var count = root.getChildIndex(pmc) - pos;
		while( count > 0 ) {
			root.removeChildAt(pos);
			count--;
		}
	}

	public function destroy( ) {

		while( root.numChildren > baseChildren ) {
			var mc = root.getChildAt(baseChildren);
			mc.parent.removeChild(mc);
		}
		plans = [];

	}


}
