import h3d.Matrix;
import h2d.Tile;
import mt.gx.Dice;
import D;
using T;

class G {
	public static var me : G;
	public var masterScene : h2d.Scene;
	public var postScene : h2d.Scene = new h2d.Scene();
	public var bbScene : h2d.Scene = new h2d.Scene();
	public var postRoot : h2d.Sprite = new h2d.Sprite();
	public var blackBands : h2d.Sprite = new h2d.Sprite();
	
	public var gameScene : h2d.OffscreenScene2D;
	public var gameRoot : h2d.Sprite;
	public var scaledRoot : h2d.Scene = new h2d.Scene();
	public var stopped = false;
	
	var d(get, null) : D; function get_d() return App.me.d;
	var tw(get, null) : mt.deepnight.Tweenie; inline function get_tw() return App.me.tweenie;
	
	public var sbCity : h2d.SpriteBatch;
	public var sbRocks : h2d.SpriteBatch;
	public var sbRoad : h2d.SpriteBatch;
	
	public var rocks:Array<h2d.Sprite>=[];
	
	public var curSpeed : Float = 1.0;
	public var curPos : Float = 0.0;
	
	public var road : Scroller;
	
	
	public var bg : Scroller;
	public var bgRocks : Scroller;
	public var bgSand : Scroller;
	
	public var bgBuildings : Scroller;
	
	public var sky : h2d.Bitmap;
	
	public var car : Car;
	public var zombies : Zombies;
	
	public var started = false;
	public var firstTime : Float = 0;
	public var startTime : Float = 0;
	public var nowTime : Float = 0;
	public var prevTime : Float = 0;
	public var dTime : Float = 0;
	
	public var curMidi : MidiStruct;
	
	public var partition : Partition;
	
	//public var firstBeat = false;
	public var score : Int = 0;
	public var progress : Float = 0;
	
	public var score1 : Int = 0;
	public var score2 : Int = 0;
	public var score3 : Int = 0;
	public var score4 : Int = 0;
	
	public var streak : Int = 0;
	public var multiplier : Int = 1;
	public var curLevel = 1;
	
	//public var progressCounter:h2d.Number;
	public var scoreText : h2d.Text;
	public var scoreCounter:h2d.Number;
	
	public var uiVisible = true;
	public var tempoTw : mt.deepnight.Tweenie;
	
	public var globalScale = 3;
	public var gameInstance = 0;

	public function new(?gs)  {
		me = this;
		masterScene = new h2d.Scene();
		
		if ( gs != null)
			globalScale = gs;
		h2d.Drawable.DEFAULT_FILTER = false;
		gameScene = new h2d.OffscreenScene2D(590 * globalScale, 250 * globalScale);
		gameRoot = new h2d.Sprite( gameScene );
		gameRoot.scaleX = gameRoot.scaleY = globalScale;
		
		gameScene.overlay = h2d.Tile.fromAssets("assets/scanLines.png");
		scaledRoot.scaleX = scaledRoot.scaleY = globalScale;
		
		tempoTw = new mt.deepnight.Tweenie();
		tempoTw.fps = C.FPS;
		
		haxe.Timer.delay( 
		resize, 1);
	}
	
	public function resize() {
		postRoot.detach();
		blackBands.detach();
		blackBands.disposeAllChildren();
		postScene.addChild( postRoot );
		bbScene.addChild( blackBands );
		
		var nw = mt.Metrics.w();
		var nh = mt.Metrics.h();
		
		var rs = Math.min( nh / C.H, nw / C.W );
		var rh, rw;
		rw = Math.round(rs * C.W);
		rh = Math.round(rs * C.H);
		gameScene.setWantedSize(Math.round(Math.max(rw,nw)),Math.round(Math.max(rh,nh)));
		gameScene.reset();
		gameRoot.setScale(rs);
		scaledRoot.setScale(rs);
		
		var diffHeight = nh - rh;
		var diffWidth = nw - rw;
		
		scaledRoot.y = gameRoot.y = (diffHeight * 0.5);
		scaledRoot.x = gameRoot.x = (diffWidth * 0.5);
		
		var borderH = diffHeight*0.5;
		var borderW = diffWidth*0.5;
		postRoot.x = borderW;
		postRoot.y = borderH;
		
		var t = h2d.Tile.fromColor(0xff000000);
		var b = new h2d.Bitmap( t, blackBands );
		b.setSize( nw, Math.ceil(borderH));
		
		var b = new h2d.Bitmap( t, blackBands );
		b.setSize( nw, Math.ceil(borderH));
		b.y = nh - borderH;
		
		var b = new h2d.Bitmap( t, blackBands );
		b.setSize( Math.ceil(borderW),nh);
		
		var b = new h2d.Bitmap( t, blackBands );
		b.setSize( Math.ceil(borderW), nh);
		b.x = nw - borderW;
		
		gameScene.overlay.setHeight( nh);
	}
	
	public inline function bps() return curMidi.bpm / 60;
	public inline function speed() return Scroller.GLB_SPEED;
	
	public function init() {
		masterScene.addPass( gameScene );
		masterScene.addPass( scaledRoot );
		masterScene.addPass( postScene );	
		masterScene.addPass( bbScene );	
		
		initBg();
		initCar();
		zombies = new Zombies(gameRoot);
		partition = new Partition( gameRoot );
		
		d.sndPrepareMusic1();
		d.sndPrepareMusic2();
		d.sndPrepareMusic3();
		
		d.sndPrepareMusic4();
		d.sndPrepareJingleStart();
		
		curMidi = d.music1Desc;
		
		partition.resetForSignature(curMidi.sig );
		
		var bs = [];
		
		#if debug
		var b = mt.gx.h2d.Proto.bt( 100, 50, "start",
		function() restart(curLevel), postRoot); bs.push(b);
		
		var b = mt.gx.h2d.Proto.bt( 100, 50, "launch",
		function() {
			partition.launchNote();
		}, postRoot); bs.push(b);
		b.x += 110;
		
		var b = mt.gx.h2d.Proto.bt( 80, 50, "level 2",
		function() {
			level2();
		}, postRoot);
		b.x += 200; bs.push(b);
		
		var b = mt.gx.h2d.Proto.bt( 80, 50, "level 3",
		function() {
			level3();
		}, postRoot);
		b.x += 300; bs.push(b);
		
		var b = mt.gx.h2d.Proto.bt( 80, 50, "level 4",
		function() {
			level4();
		}, postRoot);
		b.x += 400; bs.push(b);
		for ( b in bs ) b.y += 150;
		#end
		
		/*
		var pc = progressCounter = new h2d.Number(d.eightSmall,gameRoot);
		pc.x = C.W - 50;
		pc.y = 50;
		pc.trailingPercent = true;
		*/
		scoreText = new h2d.Text( d.eightSmall, gameRoot);
		scoreText.text = "SCORE";
		scoreText.x = 16;
		scoreText.textColor = 0x0;
		scoreText.dropShadow = ds;
		
		scoreCounter = new h2d.Number( d.eightSmall, gameRoot );
		scoreCounter.x = scoreText.x +scoreText.width + 4;
		scoreCounter.y = scoreText.y = 8;
		scoreCounter.nb = 0;
		ivory( scoreCounter );
		
		//haxe.Timer.delay( function() restart(curLevel) , 500 );
		
		partition.visible = false;
		car.visible = false;
		uiVisible = false;
		
		gameScene.colorCorrection = true;
		gameScene.sat = 0.55;
		
		var b = new h2d.Bitmap(h2d.Tile.fromColor(0xffffffff), postRoot);
		b.setSize(mt.Metrics.w(), mt.Metrics.h());
		
		haxe.Timer.delay(function(){
		tw.create( b , "alpha", 0, TEaseOut , 350 )
		.onEnd = b.dispose;
		haxe.Timer.delay(
			introMenu,100
		);
		},1);
		
		return this;
	}
	
	function introMenu() {
		var sp = new h2d.Bitmap( d.char.getTile("logo").centerRatio(), scaledRoot );
		sp.x = C.W * 0.5;
		sp.y = C.H * 0.35;
		
		sp.toFront();
		
		var spy = sp.y;
		sp.y =  - C.H * 1.5;
		tw.create( sp, "y", spy, TEaseOut, 1000);
		
		var localRoot = new h2d.Sprite( scaledRoot );
		var t = new h2d.Text( d.eightSmall,localRoot );
		t.text = "CLICK TO CONTINUE";
		t.letterSpacing = -1;
		t.x = C.W * 0.5 - t.textWidth * 0.5;
		t.y = C.H * 0.6;
		t.textColor = 0xff9358;
		ivory(t);
		var ty = t.y;
		t.y = C.H * 1.5;
		tw.create( t, "y", ty, TEaseOut, 1000);
		
		var m = D.music.MUSIC_INTRO();
		m.playLoop();
		var launch = new h2d.Interactive( mt.Metrics.w(), mt.Metrics.h(), postRoot);
		function doStart(e) {
			
			D.sfx.UI_CLIC().play();
			tw.create(gameScene, "sat", 1.0, TZigZag, 400);
			gameScene.colorCorrection = false;
			m.stop();
			sp.dispose();
			launch.dispose();
			localRoot.dispose();
			
			partition.visible = true;
			car.visible = true;
			uiVisible = true;
			
			level1();
		}
		launch.onClick = doStart;
		
		var spin = 0;
		launch.onSync = function() {
			if(spin > 12 ){
				t.alpha = 1.0 - t.alpha;
				spin = 0;
			}
			spin++;
		}
	}
	
	var ds = { dx:2.0, dy:2.0, color:0xd804a2d, alpha:1.0 };
	public inline function orange(txt:h2d.Text) {
		txt.textColor = 0xff9358;
		txt.dropShadow = ds;
	}
	
	public inline function ivory(txt:h2d.Text) {
		txt.textColor = 0xffe6b0;
		txt.dropShadow = ds;
	}
	
	var m = new Matrix();

	public function update() {
		var engine : h3d.Engine = h3d.Engine.getCurrent();
		
		postScene.checkEvents();
	
		if( ! App.me.paused ) {
			preUpdateGame();
			d.update();
			postUpdateGame();
		}
		engine.render(masterScene);
		engine.restoreOpenfl();
		
		//progressCounter.nb = Std.int(progress * 100);
		scoreCounter.nb = score;
		scoreText.visible = scoreCounter.visible = uiVisible;
		//progressCounter.visible = uiVisible;
	}
	
	public function makeCredits(sp){
		var credits = new h2d.Text(d.wendySmall,sp);
		credits.text = "Audio : Elmobo && Art : Gyhyom && Programming : Blackmagic";
		credits.x = mt.Metrics.w() * 0.5 - credits.textWidth * 0.5;
		credits.y = mt.Metrics.h()- credits.textHeight - 10;
		credits.textColor = 0xFFff8330;
		credits.dropShadow = ds;
	}
	
	public function initBg() {
		sky = new h2d.Bitmap(d.char.getTile("sky"), gameRoot);
		
		bg = new Scroller(600, 8, d.char.getTile("bg"), [], gameRoot);
		bg.speed = 0.5;
		bg.originY += 40;
		bg.init();
		
		bgRocks = new Scroller(600, 8, d.char.getTile("bgRocks"), [], gameRoot);
		bgRocks.speed = 2.0;
		bgRocks.originY += 65;
		bgRocks.init();
		
		bgSand = new Scroller(600, 8, d.char.getTile("bgSand"), [], gameRoot);
		bgSand.speed = 6.0;
		bgSand.originY += 100;
		bgSand.init();
		
		bgBuildings = new Scroller(146, 8, d.char.getTile("buildingA"), 
		["buildingA",
		"buildingB",
		"buildingC",
		"buildingD",
		"buildingE",
		].map( function(str) return d.char.getTile(str).centerRatio(0.5,1.0) ), gameRoot);
		bgBuildings.speed = 6.0;
		bgBuildings.originY += 120;
		bgBuildings.randomHide = true;
		bgBuildings.init();
		
		road = new Scroller(200, 8, d.char.tile, 
			[	d.char.getTile("roadA"),
				d.char.getTile("roadB"),
				d.char.getTile("roadC"),
				d.char.getTile("roadD")],
			gameRoot);
		road.speed = 6.0;
		road.originY += C.H >> 1;
		road.init();
	}
	
	public function initCar() {
		car = new Car( gameRoot );
	}
	
	public function bandeNoirIn() {
		
	}
	
	public function end() {
		car.invincible = true;
		
		d.stopAllMusic();
		D.sfx.JINGLE_END().play();
		
		partition.enablePulse = false;
		zombies.speed = 0;
		
		for ( i in 0...6)
			haxe.Timer.delay( function() {
				car.shootLeft();
				car.shootRight();
			},i * 100);
			
		tw.create(car, "bx", C.W * 1.5, 550);
		
		haxe.Timer.delay( function() {updateZombies = false; zombies.clear();}, 1500 );
		
		function afterExplode() {
			
			stopZombies();
			car.car.a.playAndLoop("carStop");
			
			var endScreen = new h2d.Sprite( gameRoot );
			var b = new h2d.Bitmap( h2d.Tile.fromColor( 0xcd000000 ).centerRatio(0.5, 0.5), endScreen );
			b.x = C.W * 0.5;
			b.y = 150;
			b.setSize( C.W, 10 );
			onSwooshIn();
			tw.create(b, "y", 		85, 400);
			tw.create(b, "height", 	110, 300);
			
			var localRoot = new h2d.Sprite( endScreen );
			var t = new h2d.Text( d.eightMedium,localRoot );
			t.text = "LEVEL " + curLevel + " COMPLETE";
			t.x = C.W * 0.5 - t.textWidth * 0.5;
			t.y = C.H * 0.2;
			t.letterSpacing = -1;
			t.textColor = 0xff9358;
			t.dropShadow = ds;
			
			localRoot.x -= C.W;
			tw.create(localRoot, "x", 0, TBurnOut,300);
			
			var localRoot2 = new h2d.Sprite( endScreen );
			var n = new h2d.Number(d.eightMediumPlus,localRoot2 );
			n.x = C.W * 0.25;
			n.y = C.H * 0.40 - n.textHeight * 0.5;
			n.letterSpacing = -1;
			n.textColor = 0xffe6b0;
			n.dropShadow = ds;
			
			var t = new h2d.Text( d.eightMediumPlus,localRoot2 );
			t.text = "POINTS";
			t.x = n.x + C.W * 0.25;
			t.y = C.H * 0.40 - t.textHeight * 0.5;
			t.letterSpacing = -1;
			t.textColor = 0xffe6b0;
			t.dropShadow = ds;
			
			localRoot2.x -= C.W;
			haxe.Timer.delay(function() tw.create(localRoot2, "x", 0, TBurnOut,300),100);
			
			n.nb = 0;
			tw.create(n, "nb", score, 1200);
			
			d.sfxPreload.get("SCORE").play();
			
			haxe.Timer.delay( function() {
				var tt = tw.create( localRoot, "x", C.W * 1.5, TBurnOut, 300 );
				haxe.Timer.delay(function(){
					var ttt = tw.create( localRoot2, "x", C.W * 1.5, TBurnOut, 300 );
					ttt.onEnd = function() {
						onSwooshOut();
						var tttt = tw.create(b, "scaleY", 0, TBurnIn, 200);
						tttt.onEnd = function(){
							endScreen.dispose();
							nextLevel();
						};
					}
				},100);
			},2400);
		}
		
		haxe.Timer.delay( afterExplode, 1500 );
	}
	
	public function nextLevel() {
		//trace("nextlevel");
		switch( curLevel) {
			case 1: level2();
			case 2: level3();
			case 3: level4();
			case 4: endGame();
		}
	}
	
	public function stopZombies() {
		started = false;
		zombies.clear();
		partition.enablePulse = false;
	}
	
	public function endGame() {
		car.invincible = true;
		
		d.stopAllMusic();
		D.sfx.JINGLE_END().play();
		
		partition.enablePulse = false;
		zombies.speed = 0;
		
		for ( i in 0...6)
			haxe.Timer.delay( function() {
				car.shootLeft();
				car.shootRight();
			},i * 100);
			
		tw.create(car, "bx", C.W * 1.5, 550);
		
		haxe.Timer.delay( function() {updateZombies = false; zombies.clear();}, 1500 );
		
		function afterExplode() {
			partition.visible = false;
			car.visible = false;
			uiVisible = false;	
			
			var goScreen = new h2d.Sprite(gameRoot);
			
			var b = new h2d.Bitmap( h2d.Tile.fromColor( 0xcd000000 ).centerRatio(0.5, 0.5), goScreen );
			b.x = C.W * 0.5;
			b.y = 150;
			b.setSize( C.W, 10 );
			onSwooshIn();
			tw.create(b, "y", 		100, 400);
			tw.create(b, "height", 	C.H * 1.5, 300);
			
			var localRoot = new h2d.Sprite( goScreen );
			var t = new h2d.Text( d.eightMedium,localRoot );
			t.text = "THE END";
			t.x = C.W * 0.5 - t.textWidth * 0.5;
			t.y = C.H * 0.2;
			t.letterSpacing = -1;
			t.textColor = 0xff9358;
			t.dropShadow = ds;
			
			localRoot.x -= C.W;
			tw.create(localRoot, "x", 0, TBurnOut, 300);
			
			var localRoot2 = new h2d.Sprite( goScreen );
			
			var n = new h2d.Text(d.eightSmall,localRoot2 );
			n.y = C.H * 0.40 - n.textHeight * 0.5;
			n.text = "SCORE "+score;
			n.letterSpacing = -1;
			n.textColor = 0xffe6b0;
			n.dropShadow = ds;
			n.x = C.W * 0.5 - n.textWidth * 0.5;
			
			var n = new h2d.Text(d.eightSmall,localRoot2 );
			n.y = C.H * 0.5 - n.textHeight * 0.5;
			n.text = "CLICK TO RESTART";
			n.letterSpacing = -1;
			n.textColor = 0xffe6b0;
			n.dropShadow = ds;
			n.x = C.W * 0.5 - n.textWidth*0.5;
			
			var n = new h2d.Text(d.eightSmall,localRoot2 );
			n.x = C.W * 0.25;
			n.y = C.H * 0.55 - n.textHeight * 0.5;
			n.text = "F1 / F2 / F3 / F4 to jump to level";
			n.letterSpacing = -1;
			n.textColor = 0xffe6b0;
			n.dropShadow = ds;
			n.x = C.W * 0.5 - n.textWidth * 0.5;
			
			var n = new h2d.Text(d.eightSmall,localRoot2 );
			n.text = "THANKS FOR PLAYING !!!\nIF YOU LIKED DOUBLE KICK HEROES SEND US YOUR LOVE ON \nTWITTER: blackmagic & gyhyom & elmobo";
			n.letterSpacing = -1;
			n.textColor = 0x88BDFF;
			n.dropShadow = ds;
			
			n.x = 30;
			n.y = C.H * 0.7;
			
			var goMask = new h2d.Interactive( mt.Metrics.w(), mt.Metrics.h(), postRoot);
			
			function f() {
				partition.visible = true;
				car.visible = true;
				uiVisible = true;	
			
				goScreen.dispose();
				goMask.dispose();
				isLoosing = false;
			}
			
			function onPress(f) {
				
				var tt = tw.create( localRoot, "x", C.W * 1.5, TBurnOut, 300 );
				haxe.Timer.delay(function(){
					var ttt = tw.create( localRoot2, "x", C.W * 1.5, TBurnOut, 300 );
					ttt.onEnd = function() {
						onSwooshOut();
						var tttt = tw.create(b, "scaleY", 0, TBurnIn, 200);
						tttt.onEnd = f;
					}
				},100);
			}
				
			goMask.onClick = function(e) {
				onPress( function() {
					f();
					restart(1);
				});
			};
			
			goMask.onSync = function() {
				if ( mt.flash.Key.isToggled(hxd.Key.F1)) onPress( function() { f(); level1();  } );
				if ( mt.flash.Key.isToggled(hxd.Key.F2)) onPress( function(){ f(); level2();  });
				if ( mt.flash.Key.isToggled(hxd.Key.F3)) onPress( function(){ f(); level3();  });
				if ( mt.flash.Key.isToggled(hxd.Key.F4)) onPress( function(){ f(); level4();  });
			}
		}
		haxe.Timer.delay( afterExplode, 800 );
		
	}
	
	public function onStart() {
		gameInstance++;
		d.sndPlayJingleStart();
		
		car.by = Car.BASE_BY;
		car.bx = - C.W;
		car.car.a.playAndLoop("carStop");
		var tt = tw.create(car, "bx", Car.BASE_BX, 600);
		///tt.onEnd = function(){
			d.stopAllMusic();
			started = true;
			nowTime = 0;
			startTime = hxd.Timer.oldTime;
			car.reset();
			progress = 0;
			score = 0;
			streak = 0;
			multiplier = 1;
			zombies.speed = 1;
			updateZombies=true;
		//};
	}
	
	public function afterStart() {
		var startScreen = new h2d.Sprite( gameRoot );
		var b = new h2d.Bitmap( h2d.Tile.fromColor( 0xcd000000 ).centerRatio(0.5, 0.5), startScreen );
		b.x = C.W * 0.5;
		b.y = 150;
		b.setSize( C.W, 10 );
		onSwooshIn();
		tw.create(b, "y", 		85, 400);
		tw.create(b, "height", 	110, 300);
		
		var localRoot = new h2d.Sprite( startScreen );
		var t = new h2d.Text( d.eightMedium,localRoot );
		t.text = "LEVEL " + curLevel;
		t.x = C.W * 0.5 - t.textWidth * 0.5;
		t.y = C.H * 0.2;
		t.letterSpacing = -1;
		t.textColor = 0xff9358;
		t.dropShadow = ds;
		
		localRoot.x -= C.W;
		tw.create(localRoot, "x", 0, TBurnOut,300);
		
		var localRoot2 = new h2d.Sprite( startScreen );
		var t = new h2d.Text( curLevel==2?d.eightSmall:d.eightMedium,localRoot2 );
		t.text = switch(curLevel) {
			default:"ERROR";
			case 1: "PLANET ERROR";
			case 2: "WERE GONNA ROCK YOUR SOCKS OFF";
			case 3: "DESTROY AND RACE AND GROOVE";
			case 4: "WE ARE THE DEV S";
		};
		t.x = C.W * 0.5 - t.textWidth * 0.5;
		t.y = C.H * 0.40 - t.textHeight * 0.5;
		t.textColor = 0xffe6b0;
		t.dropShadow = ds;
		
		localRoot2.x -= C.W;
		haxe.Timer.delay(function() tw.create(localRoot2, "x", 0, TBurnOut,300),100);
		haxe.Timer.delay( function() {
			var tt = tw.create( localRoot, "x", C.W * 1.5, TBurnOut, 300 );
			haxe.Timer.delay(function(){
				var ttt = tw.create( localRoot2, "x", C.W * 1.5, TBurnOut, 300 );
				ttt.onEnd = function() {
					onSwooshOut();
					var tttt = tw.create(b, "scaleY", 0, TBurnIn, 200);
				}
			},100);
		},1500);
	}
	
	public function restart(lvl) {
		switch(lvl) {
			case 1:level1();
			case 2:level2();
			case 3:level3();
			case 4:level4();
		}
	}
	
	inline function startBeat() {
		haxe.Timer.delay( function() {
			partition.enablePulse = true;
			car.car.a.playAndLoop( "carPlay" );
			car.invincible = false;
		},2400);
	}
	
	var showTuto = true;
	
	public function level1() {
		curLevel = 1;
		
		function doStart(){
			onStart();
			
			d.sndPlayMusic1();
			zombies.setLevel(1);
			
			curMidi = d.music1Desc;
			partition.resetForSignature(curMidi.sig );
			
			startBeat();
			afterStart();
		}
		
		if ( showTuto ) {
			curMidi = d.music1Desc;
			partition.resetForSignature(curMidi.sig );
			
			onPause(true);
			updateZombies = false;
			doShowTuto(doStart);
		}
		else 
			doStart();
	}
	
	public function level2() {
		curLevel=2;
		onStart();
		
		d.sndPlayMusic2();
		zombies.setLevel(2);
		
		curMidi = d.music2Desc;
		partition.resetForSignature(curMidi.sig );
		
		startBeat();
		afterStart();
	}
	
	public function level3() {
		curLevel=3;
		onStart();
		
		d.sndPlayMusic3();
		zombies.setLevel(3);
		
		curMidi = d.music3Desc;
		partition.resetForSignature( curMidi.sig );
		
		startBeat();
		afterStart();
	}
	
	public function level4() {
		curLevel=4;
		onStart();
		
		d.sndPlayMusic4();
		zombies.setLevel(4);
		
		curMidi = d.music4Desc;
		partition.resetForSignature( curMidi.sig );
		
		startBeat();
		afterStart();
	}
	
	var pausePos : Float = -1.0;
	public function onPause(onOff) {
		car.onPause(onOff);
		
		var mus:mt.flash.Sfx=
		switch( curLevel) {
			default: throw "assert";
			case 1:d.music1;
			case 2:d.music2;
			case 3:d.music3;
			case 4:d.music4;
		};
		
		if ( onOff ) {
			if ( mus != null && mus.curPlay!=null ){
					pausePos = mus.curPlay.position;
					mus.curPlay.stop();
					//trace("pos:" + pausePos);
				//}
				//else trace("no curPlay");
			}
			else 
				pausePos = -1.0;
			//else trace("no music");
		}
		
		if ( !onOff ) {
			if ( pausePos >= 0 ) 
				mus.curPlay = mus.sound.play(pausePos);
			pausePos = -1.0;
		}
	}
	
	public var isBeat 	: Bool;
	public var isNote 	: Bool;
	public var isQuarter : Bool;
	
	function updateTempo() {
		isNote = isQuarter = isBeat = false;
		prevTime = nowTime;//in sec
		nowTime = (hxd.Timer.oldTime - startTime); //in sec
		//trace( prevTime +" -> " + nowTime ); 
		
		var prevBeat = prevTime * bps() + C.LookAhead;
		var nowBeat = nowTime * bps() + C.LookAhead;
		
		var pb = Std.int( prevBeat );
		var nb = Std.int( nowBeat );
		//trace("b " + pb + " -> " + nb);
		
		var prevQuarter = prevBeat * curMidi.sig;
		var nowQuarter = nowBeat * curMidi.sig;
		
		var pq = Std.int( prevQuarter );
		var nq = Std.int( nowQuarter );
		//trace("q " + pq + " -> " + nq);
		
		//tick per beat
		var prevTick = prevBeat * curMidi.midi.division;  // in midi frames
		var lastTick = nowBeat * curMidi.midi.division;  // in midi frames
		
		var s = Std.int(prevTick);
		var e = Std.int(lastTick) + 1;
		
		var n = null;
		function seekNote(ti, i, m : TE ) {
			if ( m.message.status == cast com.newgonzo.midi.messages.MessageStatus.NOTE_ON )
				n = m;
			
			if ( m.time != 0 && Std.is( m.message, com.newgonzo.midi.file.messages.EndTrackMessage) ) {
				var mm : com.newgonzo.midi.file.messages.EndTrackMessage = cast m.message;
				if ( mm.type == cast com.newgonzo.midi.file.messages.MetaEventMessageType.END_OF_TRACK) {
					var gi = gameInstance;
					haxe.Timer.delay( function() {
						if ( car.life > 0 && !car.invincible && gi == gameInstance){
							end();
						}
					}, 6000 );
				}
			}
		}
		
		d.getMessageRange(curMidi.midi,s, e, seekNote);
		
		if( n != null){
			//time should play ? 
			var o_tb =  n.time / curMidi.midi.division;
			var o_ts = (o_tb-C.LookAhead) / bps();
			//trace(prevTime+" " + o_ts + " " + nowTime );
		}
			
		if ( pb != nb ) {
			if ( n != null) {
				onNote();
				isNote = true;
			}
			else{ 
				onBeat();
			}
			isBeat = true;
			progress = lastTick / curMidi.durTick;
		}
		else if ( pq != nq ) {
			if ( n != null) {
				onNote();
				isNote = true;
			}
			else{
				onQuarter();
			}
			isQuarter = true;
		}
		
		
	}
	
	function onQuarter() {
		partition.launchQuarter();
	}
	
	function onBeat() {
		partition.launchStrong();
	}
	
	function onNote() {
		partition.launchNote();
	}
	
	var leftIsDown = 0;
	var rightIsDown = 0;
	
	var updateZombies = true;
	
	public function preUpdateGame() {
		if ( started && updateZombies) 
			updateTempo();
		else 
			dTime = 1.0 / C.FPS;
			
		curPos += curSpeed * dTime;
			
		road.update(dTime);
		bg.update(dTime);
		bgRocks.update(dTime);
		bgSand.update(dTime);
		bgBuildings.update(dTime);
		car.update( dTime );
		
		if ( updateZombies ) {
			zombies.speed = 1;
			#if	debug
			if ( mt.flash.Key.isDown(hxd.Key.SPACE)) {
				zombies.speed = 20;
			}
			#end
			zombies.update( dTime );
			tempoTw.update( Lib.dt2Frame( dTime ));
		}
		
		/*
		if ( mt.flash.Key.isToggled(hxd.Key.C)) {
			zombies.clear();
		}
		
		if ( mt.flash.Key.isToggled(hxd.Key.Z)) {
			zombies.spawnZombieBase();
		}
		
		if ( mt.flash.Key.isToggled(hxd.Key.E)) {
			for( i in 0...6)
				zombies.spawnZombieBase();
		}
		
		if ( mt.flash.Key.isToggled(hxd.Key.R)) {
			for( i in 0...3)
				zombies.spawnZombieHigh();
		}
		
		if ( mt.flash.Key.isToggled(hxd.Key.T)) {
			for( i in 0...3)
				zombies.spawnZombieLow();
		}
		
		if ( mt.flash.Key.isToggled(hxd.Key.G)) {
			var z = zombies.spawnZombiePack();
			for( zz in z ) {
				zz.cs(Nope);
				zz.x += 100;
			}
		}
		*/
		/*
		if ( mt.flash.Key.isToggled(hxd.Key.U)) {
			car.hit();
		}
		
		if ( mt.flash.Key.isToggled(hxd.Key.I)) {
			car.heal();
		}
		
		if ( mt.flash.Key.isToggled(hxd.Key.L)) {
			car.shootLeft();
		}
		
		if ( mt.flash.Key.isToggled(hxd.Key.M)) {
			car.shootRight();
		}
		
		if ( mt.flash.Key.isToggled(hxd.Key.LEFT)) {
			car.tryShootLeft();
		}
		
		if ( mt.flash.Key.isToggled(hxd.Key.RIGHT)) {
			car.tryShootRight();
		}
		*/
		
		#if debug
		
		if ( mt.flash.Key.isToggled(hxd.Key.R)) {
			for( i in 0...3)
				zombies.spawnZombieHigh();
		}
		
		if ( mt.flash.Key.isToggled(hxd.Key.T)) {
			for( i in 0...3)
				zombies.spawnZombieLow();
		}
		
		if ( mt.flash.Key.isToggled(hxd.Key.NUMBER_0)) 	partition.onMultiplier( 3 );
		if ( mt.flash.Key.isToggled(hxd.Key.NUMBER_1)) 	partition.onMultiplier( 4 );
		if ( mt.flash.Key.isToggled(hxd.Key.NUMBER_2)) 	partition.onMultiplier( 5 );
		if ( mt.flash.Key.isToggled(hxd.Key.NUMBER_3)) 	partition.onMultiplier( 6 );
		if ( mt.flash.Key.isToggled(hxd.Key.NUMBER_4)) 	partition.onMultiplier( 8 );
		if ( mt.flash.Key.isToggled(hxd.Key.NUMBER_5)) 	partition.onMultiplier( 10);
		
		//if ( mt.flash.Key.isToggled(hxd.Key.C)) 	{ car.gunType = GTCanon; car.forceGun = true;}
		//if ( mt.flash.Key.isToggled(hxd.Key.G)) 	{ car.gunType = GTGun; car.forceGun = true;}
		//if ( mt.flash.Key.isToggled(hxd.Key.S)) 	{ car.gunType = GTShotgun; car.forceGun = true; }
		
		
		//if ( mt.flash.Key.isToggled(hxd.Key.V)) 	end();
		//if ( mt.flash.Key.isToggled(hxd.Key.L)) 	loose();
		//if ( mt.flash.Key.isToggled(hxd.Key.E)) 	endGame();
		/*
		if ( mt.flash.Key.isToggled(hxd.Key.K)) {
			trace("before");
			trace("ww:"+gameScene.wantedWidth);
			trace("wh:"+gameScene.wantedHeight);
			trace(gameScene.targetRatioW);
			trace(gameScene.targetRatioH);
			if( gameScene.s2d != null){
				trace("s2dw:"+gameScene.s2d.width);
				trace("s2dh:"+gameScene.s2d.height);
			}
			gameScene.deferScene = ! gameScene.deferScene;
			gameScene.reset();
			trace("after");
			trace("ww:"+gameScene.wantedWidth);
			trace("wh:"+gameScene.wantedHeight);
			trace(gameScene.targetRatioW);
			trace(gameScene.targetRatioH);
			if( gameScene.s2d != null){
				trace("s2dw:"+gameScene.s2d.width);
				trace("s2dh:"+gameScene.s2d.height);
			}
		}*/
		
		
		#end
		
		if ( mt.flash.Key.isToggled(hxd.Key.ESCAPE) && !car.invincible) {
			restart(curLevel);
		}
		
		#if debug
		if (	mt.flash.Key.isDown(hxd.Key.M) ) {
			car.shootLeft();
		}
		
		if (	mt.flash.Key.isDown(hxd.Key.L) ) {
			car.shootRight();
		}
		#end
		
		if (  (	mt.flash.Key.isDown(hxd.Key.LEFT)
		||		mt.flash.Key.isDown(hxd.Key.Q)
		||		mt.flash.Key.isDown(hxd.Key.DOWN)
		||		mt.flash.Key.isDown(hxd.Key.A))) {
			leftIsDown++;
		}
		else leftIsDown = 0;
		
		if (  	mt.flash.Key.isDown(hxd.Key.RIGHT)
		||		mt.flash.Key.isDown(hxd.Key.UP)
		||		mt.flash.Key.isDown(hxd.Key.D)) {
			rightIsDown++;
		}
		else rightIsDown = 0;
		
		if ( leftIsDown == 1 )
			car.tryShootLeft();
			
		if ( rightIsDown == 1 )
			car.tryShootRight();
			
		/*
		if ( mt.flash.Key.isToggled(hxd.Key.F1)) level1();  
		if ( mt.flash.Key.isToggled(hxd.Key.F2)) level2();  
		if ( mt.flash.Key.isToggled(hxd.Key.F3)) level3();  
		if ( mt.flash.Key.isToggled(hxd.Key.F4)) level4();  
		*/
	}
	
	public function postUpdateGame() {
		if( updateZombies )
			partition.update();
	}
	
	public function doShowTuto(f) {
		var tutoScreen = new h2d.Sprite(gameRoot);
			
		var b = new h2d.Bitmap( h2d.Tile.fromColor( 0xcd000000 ).centerRatio(0.5, 0.5), tutoScreen );
		b.x = C.W * 0.5;
		b.y = 150;
		b.setSize( C.W, 10 );
		onSwooshIn();
		tw.create(b, "y", 		100, 400);
		var o = tw.create(b, "height", 	130, 300);
		
		o.onEnd = function(){
		var bb = new h2d.Bitmap( d.char.getTile("tuto").centerRatio(), tutoScreen);
		bb.x = C.W * 0.5;
		bb.y = 100;
		new mt.heaps.fx.Spawn(bb,0.1, true);
		};
		
		var i = new h2d.Interactive( 1, 1, b);
		i.onSync = function() {
			if ( 	mt.flash.Key.isToggled(hxd.Key.LEFT)
			||		mt.flash.Key.isToggled(hxd.Key.RIGHT)
			||		mt.flash.Key.isToggled(hxd.Key.Z)
			||		mt.flash.Key.isToggled(hxd.Key.Q)
			||		mt.flash.Key.isToggled(hxd.Key.S)
			||		mt.flash.Key.isToggled(hxd.Key.D) ){
				
				var v = new mt.heaps.fx.Vanish( tutoScreen, true);
				v.onFinish = tutoScreen.dispose;
				//car.shootLeft();
				//car.shootRight();
				//leave tuto screen
				d.sfxPreload.get("GUN3").play();
				
				haxe.Timer.delay( function() {
					onPause(false);
					updateZombies = true;
				},50);
				
				haxe.Timer.delay( function() {
					d.sfxPreload.get("ANNOUNCE_AWESOME").play();
				},100);
				
				haxe.Timer.delay( function() {
					f();
				},150);
			}
		};
	}
	
	function onSwooshIn() {
		d.sfxPreload.get("SWOOSH_IN").play();
	}
	function onSwooshOut() {
		d.sfxPreload.get("SWOOSH_OUT").play();
	}
	
	public function fxExplosion(x,y) {
		var fx = new mt.deepnight.slb.HSpriteBE( car.sb, d.char, "fxExplosion");
		fx.setCenterRatio();
		fx.a.play("fxExplosion");
		fx.a.killAfterPlay();
		fx.a.setCurrentAnimSpeed( 0.33 );
		fx.x = x + Dice.rollF( -10,10);
		fx.y = y + Dice.rollF( -10,10);
		d.sfxPreload.get("EXPLOSION").play();
		fx.scale( Dice.rollF( 0.4, 0.6));
	}
	
	var isLoosing = false;
	public function loose() {
		
		onSwooshIn();
		car.invincible = true;
		//zombies.setLevel(0);
		//updateZombies();
		partition.clear();
		d.stopAllMusic();
		
		if ( isLoosing ) return;
		isLoosing = true;
		
		zombies.speed = -2;
		
		var o = tw.create( car, "bx", - C.W, 1200 );
		o.onUpdate = function() {
			if ( Dice.percent(50) ) {
				var fx = new mt.deepnight.slb.HSpriteBE( car.sb, d.char, "fxExplosion");
				fx.setCenterRatio(0.5,0.5);
				fx.a.play("fxExplosion");
				fx.a.killAfterPlay();
				fx.a.setCurrentAnimSpeed( 0.33 );
				fx.x = car.cacheBounds.randomX() + Dice.rollF( -5,5);
				fx.y = car.cacheBounds.randomY()+ Dice.rollF( -5,5);
				d.sfxPreload.get("EXPLOSION").play();
			}
		}
		o.onEnd = function() {
			updateZombies = false;
		}
		d.stopAllMusic();
		haxe.Timer.delay( function() {
			D.sfx.JINGLE_GAMEOVER().play();
		},400);
		
		haxe.Timer.delay( function() {
			
			zombies.clear();
			onSwooshIn();
			var goScreen = new h2d.Sprite(gameRoot);
			
			var b = new h2d.Bitmap( h2d.Tile.fromColor( 0xcd000000 ).centerRatio(0.5, 0.5), goScreen );
			b.x = C.W * 0.5;
			b.y = 150;
			b.setSize( C.W, 10 );
			onSwooshIn();
			tw.create(b, "y", 		100, 400);
			tw.create(b, "height", 	130, 300);
			
			var localRoot = new h2d.Sprite( goScreen );
			var t = new h2d.Text( d.eightMedium,localRoot );
			t.text = "GAME OVER";
			t.x = C.W * 0.5 - t.textWidth * 0.5;
			t.y = C.H * 0.2;
			t.letterSpacing = -1;
			t.textColor = 0xff9358;
			t.dropShadow = ds;
			
			localRoot.x -= C.W;
			tw.create(localRoot, "x", 0, TBurnOut, 300);
			
			var localRoot2 = new h2d.Sprite( goScreen );
			
			var n = new h2d.Text(d.eightSmall,localRoot2 );
			n.y = C.H * 0.40 - n.textHeight * 0.5;
			n.text = "SCORE "+score;
			n.letterSpacing = -1;
			n.textColor = 0xffe6b0;
			n.dropShadow = ds;
			n.x = C.W * 0.5 - n.textWidth * 0.5;
			
			var n = new h2d.Text(d.eightSmall,localRoot2 );
			n.y = C.H * 0.5 - n.textHeight * 0.5;
			n.text = "CLICK TO RESTART";
			n.letterSpacing = -1;
			n.textColor = 0xffe6b0;
			n.dropShadow = ds;
			n.x = C.W * 0.5 - n.textWidth*0.5;
			
			var n = new h2d.Text(d.eightSmall,localRoot2 );
			n.x = C.W * 0.25;
			n.y = C.H * 0.55 - n.textHeight * 0.5;
			n.text = "F1 / F2 / F3 / F4 to jump to level";
			n.letterSpacing = -1;
			n.textColor = 0xffe6b0;
			n.dropShadow = ds;
			n.x = C.W * 0.5 - n.textWidth*0.5;
			
			var goMask = new h2d.Interactive( mt.Metrics.w(), mt.Metrics.h(), postRoot);
			
			function f() {
				goScreen.dispose();
				goMask.dispose();
				isLoosing = false;
			}
			
			function onPress(f) {
				goMask.visible = false;
				var tt = tw.create( localRoot, "x", C.W * 1.5, TBurnOut, 300 );
				haxe.Timer.delay(function(){
					var ttt = tw.create( localRoot2, "x", C.W * 1.5, TBurnOut, 300 );
					ttt.onEnd = function() {
						onSwooshOut();
						var tttt = tw.create(b, "scaleY", 0, TBurnIn, 200);
						tttt.onEnd = function(){
							f();
						};
					}
				},100);
			}
				
			goMask.onClick = function(e) {
				goMask.visible = false;
				onPress( function() {
					f();
					restart(curLevel);
				});
			};
			
			goMask.onSync = function() {
				
				if ( mt.flash.Key.isToggled(hxd.Key.F1)) onPress( function(){ f(); level1();  } );
				if ( mt.flash.Key.isToggled(hxd.Key.F2)) onPress( function(){ f(); level2();  });
				if ( mt.flash.Key.isToggled(hxd.Key.F3)) onPress( function(){ f(); level3();  });
				if ( mt.flash.Key.isToggled(hxd.Key.F4)) onPress( function(){ f(); level4();  });
			}
		},1300);
	}
	
	public function onMiss() {
		//d.sfxKick00.play();
		partition.triggerMiss(C.W - 30, partition.baseline);
		streak = 0;
		multiplier = 1;
	}
	
	public function onSuccess() {
		
	}
	
	public function scoreZombi(zt:Zombies.ZType) {
		var base = 5;
		switch(zt) {
			default:
			case Girl:base++;
			case Armor:base+=3;
			case Boss:base+=5;
		}
		score += base * multiplier;
	}
	
	public function scorePerfect() 
	{
		score += 5 * multiplier;
	}
	
	public function scoreGood() 
	{
		score += 3 * multiplier;
	}
	
}