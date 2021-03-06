
@:publicFields
class PartBE {
	var name : String;
	var g = DEFAULT_G;
	var tmod = 1.0;
	
	var vx = 0.;
	var vy = 0.;
	
	var ax = 0.;
	var ay = 0.;
	
	var life = 200.0;
	
	var ox:Float; 
	var oy:Float;
	
	var x(get, set):Float; 
	var y(get, set):Float; 
	
	var alpha(get, set):Float; 
	var killed = false;
	
	private var update : Array < Void->Void >;
	
	var sp : h2d.SpriteBatch.BatchElement;
	
	var data = 0;

	static var ALL = [];
	static var SAMPLES = 2;
	
	var sample : Null<Int>=null;
	
	public static var DEFAULT_BOUNDS = {
		var b = new h2d.col.Bounds(); 
		b.add4( 0, 0, 1000, 1000);
		b;
	}
	public static var DEFAULT_G = 0.0;
	
	public function new(sp,?name:String ) {
		this.sp = sp;
		x = sp.x;
		y = sp.y;
		update = [alive];
		vx = 0; vy = 0;
		ALL.push( this );
		this.name = name;
	}
	
	public function get_x() return sp.x;
	public function set_x(v) return sp.x = v;
	
	public function get_y() return sp.y;
	public function set_y(v) return sp.y = v;
	
	public function get_alpha() return sp.alpha;
	public function set_alpha(v) return sp.alpha = v;
	
	public dynamic function onKill(){};
	
	public function kill() {
		killed = true;
		onKill();
		sp.remove();
		ALL.remove(this);
	}
	
	public function add(bhv ) {
		update.push(bhv);
	}
	
	public function speed(){
		sp.x += vx * tmod;
		sp.y += vy * tmod;
	}
	
	public function delay(max,proc) {
		var n = 0;
		return function()
		{
			n++;
			if ( n >= max ) 
				proc();
		};
	}
	
	public function limit(lm, proc) {
		return function()
		{
			if ( lm >= life - lm)
				proc();
		};
	}
	
	public function once(max,proc) {
		var n = 0;
		return function()
		{
			n++;
			if ( n == max ) 
				proc();
		};
	}
	
	public function alive() {
		life-=tmod;
		if (life <= 0)
			kill();
	}
	
	public function frictSpeed(fr:Float) {
		return function() {
			var f = Math.pow( fr , 1.0 / tmod );
			vx *= f;
			vy *= f;
		}
	}
	
	public function frictAlpha(fr:Float) {
		return function() {
			var f = Math.pow( fr , 1.0 / tmod );
			alpha *= f;
		}
	}
	
	public function fadeScale(fr:Float) {
		return function(){
			if (sp.scaleX <= 0.001 )
				kill();
			else 
				sp.scaleX = sp.scaleY *= Math.pow( fr , 1.0 / tmod );
		}
	}
	
	public function fadeAlpha() {
		if (sp.alpha <= 0.001 )		kill();
		else 						sp.alpha *= 0.98;
	}
	
	public function bounds() {
		boundX(); boundY();
	}
	
	public function boundY() {
		if ( sp.y + sp.height > DEFAULT_BOUNDS.yMax || sp.y < DEFAULT_BOUNDS.yMin )
			kill();
	}
	
	public function boundX() {
		if ( sp.x + sp.width > DEFAULT_BOUNDS.xMax || sp.x < DEFAULT_BOUNDS.xMin )
			kill();
	}
	
	public function moveAng(a:Float, spd:Float) {
		vx = Math.cos(a)*spd;
		vy = Math.sin(a)*spd;
	}

	public function moveTo(x:Float,y:Float, spd:Float, ?acc=0.0) {
		var a = Math.atan2(y - this.y, x - this.x);
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		vx = ca*spd;
		vy = sa*spd;
		
		ax = ca*acc;
		ay = sa*acc;
		
		return 
		if ( Math.abs( acc )> 0.0 )
			function() { accel(); speed(); };
		else 
			speed;
	}
	
	public function track( p : Void->h2d.col.Point, spd:Float, ?acc:Float) {
		var pnt = p();
		var a = Math.atan2(pnt.y - y, pnt.x - x);
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		vx = ca * spd;
		vy = sa * spd;
		
		return function() {
			var pnt = p();
			var a = Math.atan2(pnt.y - y, pnt.x - x);
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			ax = ca * acc;
			ay = sa * acc;
			accel(); 
			speed();
		}
	}
	
	public function intersectCircle( x, y, ray , onKill ) {
		var d = new h2d.col.Point(x, y).sub( new h2d.col.Point(this.x, this.y ));
		life  = d.length() / getSpeed();
		
		var c = new h2d.col.Circle( x, y, ray);
		return function() {
			if ( c.distanceSq(new h2d.col.Point(this.x, this.y)) <= 0 ) {
				onKill();
				kill();
			}
		}
	}

	public function getSpeed() {
		return Math.sqrt(vy * vy + vx * vx);
	}
	
	public function getMoveAng() {
		return Math.atan2(vy,vx);
	}
	
	public function accel() {
		vx += ax * tmod;
		vy += ay * tmod;
	}
	
	public function gravity(){
		vy += g * tmod;
	}
	
	public function updateBhv(tm:Float) {
		if (sample == null)sample = SAMPLES;
		tmod = tm / sample;
		for ( i in 0...sample) {
			ox = x; oy = y;
			for ( u in update ) 
				if( !killed )
					u();
		}
	}
	
	public static function updateAll(tm) {
		var pos = ALL.length;
		while( (--pos) >= 0 )
			ALL[pos].updateBhv(tm);
	}
	
	public function toString() {
		return 'x:$x y:$y data:$data';
	}
}