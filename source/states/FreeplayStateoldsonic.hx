package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import openfl.utils.Assets;

import haxe.Json;

import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxGradient;
import flixel.tweens.FlxEase;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.util.FlxTimer;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];
	var allSongs:Array<SongMetadata> = [];

	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	// Music control
	var musicPlaying:Bool = false;
	var musicPaused:Bool = false;
	
	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	// ═══════════════════════════════════════════════════════════════
	// SONIC.EXE STYLE - MERKEZ KUTUCUK SİSTEMİ
	// ═══════════════════════════════════════════════════════════════
	
	// Ana Kutucuk (Merkez)
	var mainBox:FlxSprite;
	var mainBoxBorder:FlxSprite;
	var mainBoxGlow:FlxSprite;
	var mainIcon:HealthIcon;
	var mainSongName:FlxText;
	var mainSongNumber:FlxText;
	
	// Kutucuk boyutları
	var BOX_SIZE:Int = 350;
	
	// Mystery Effects
	var staticNoise:FlxSprite;
	var darkOverlay:FlxSprite;
	var redVignette:FlxSprite;
	var gridBG:FlxBackdrop;
	var bloodDrips:Array<FlxSprite> = [];
	var eyeSprites:Array<FlxSprite> = [];
	var glitchTimer:Float = 0;
	var mysteryParticles:Array<FlxSprite> = [];
	
	// Ambient effects
	var ambientPulse:Float = 0;
	var isGlitching:Bool = false;
	
	// Yan oklar (navigasyon göstergesi)
	var leftArrow:FlxText;
	var rightArrow:FlxText;
	
	// Category System
	var categoryText:FlxText;
	var curCategory:String = 'Tümü';
	var favorites:Array<String> = [];
	var hiddenSongs:Array<String> = [];
	var categories:Array<String> = ['Tümü', 'Favoriler', 'Gizli'];
	var curCategoryIndex:Int = 0;
	
	// Title
	var titleText:FlxText;
	var titleGlow:FlxSprite;

	override function create()
	{
		super.create();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Karanlık Menüde...", null);
		#end

		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("HAFTA BULUNAMADI",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		// Load Saved Data
		if (FlxG.save.data.favorites != null) favorites = FlxG.save.data.favorites;
		if (FlxG.save.data.hiddenSongs != null) hiddenSongs = FlxG.save.data.hiddenSongs;

		// Load songs
		for (i in 0...WeekData.weeksList.length)
		{
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			WeekData.setDirectoryFromWeek(leWeek);
			
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
					colors = [100, 20, 20];
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		allSongs = songs.copy();
		songs = [];

		// ═══════════════════════════════════════════════════════════════
		// SONIC.EXE STYLE BACKGROUND
		// ═══════════════════════════════════════════════════════════════
		
		// Pure black background
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF050505);
		add(bg);
		
		// Dark red grid (Sonic.exe style)
		gridBG = new FlxBackdrop(FlxGridOverlay.createGrid(60, 60, 120, 120, true, 0x15FF0000, 0x0));
		gridBG.velocity.set(-15, 15);
		gridBG.alpha = 0.3;
		add(gridBG);
		
		// Blood drip effect
		createBloodDrips();
		
		// Dark gradient overlay
		darkOverlay = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[0x00000000, 0x33000000, 0x66000000, 0x99000000],
			1, 90
		);
		add(darkOverlay);
		
		// Red vignette
		redVignette = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
		createVignetteEffect();
		add(redVignette);
		
		// Static noise overlay
		staticNoise = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		staticNoise.alpha = 0;
		add(staticNoise);
		
		// Mystery particles
		createMysteryParticles();
		
		// Create floating eyes
		createEyeSprites();

		// ═══════════════════════════════════════════════════════════════
		// TITLE AREA
		// ═══════════════════════════════════════════════════════════════
		
		titleGlow = new FlxSprite(0, 0).makeGraphic(FlxG.width, 80, 0xFF1a0000);
		titleGlow.alpha = 0.9;
		add(titleGlow);
		
		titleText = new FlxText(0, 15, FlxG.width, "S E Ç İ M İ N İ   Y A P", 42);
		titleText.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 4;
		add(titleText);
		
		categoryText = new FlxText(0, 55, FlxG.width, "[ TÜMÜ ]", 18);
		categoryText.setFormat(Paths.font("vcr.ttf"), 18, 0xFF666666, CENTER);
		add(categoryText);

		// ═══════════════════════════════════════════════════════════════
		// MERKEZ KUTUCUK SİSTEMİ (SONIC.EXE STYLE)
		// ═══════════════════════════════════════════════════════════════
		
		var centerX = FlxG.width / 2;
		var centerY = FlxG.height / 2 - 20;
		
		// Kutucuk Glow (arkadaki parıltı)
		mainBoxGlow = new FlxSprite(centerX - BOX_SIZE/2 - 15, centerY - BOX_SIZE/2 - 15);
		mainBoxGlow.makeGraphic(BOX_SIZE + 30, BOX_SIZE + 30, 0xFF660000);
		mainBoxGlow.alpha = 0.5;
		add(mainBoxGlow);
		
		// Kutucuk Border (dış çerçeve)
		mainBoxBorder = new FlxSprite(centerX - BOX_SIZE/2 - 8, centerY - BOX_SIZE/2 - 8);
		mainBoxBorder.makeGraphic(BOX_SIZE + 16, BOX_SIZE + 16, 0xFFAA0000);
		add(mainBoxBorder);
		
		// Ana Kutucuk
		mainBox = new FlxSprite(centerX - BOX_SIZE/2, centerY - BOX_SIZE/2);
		mainBox.makeGraphic(BOX_SIZE, BOX_SIZE, 0xFF0a0a0a);
		add(mainBox);
		
		// İkon (kutucuğun üst kısmında)
		mainIcon = new HealthIcon('face');
		mainIcon.setGraphicSize(180, 180);
		mainIcon.updateHitbox();
		mainIcon.x = centerX - 90;
		mainIcon.y = centerY - BOX_SIZE/2 + 40;
		add(mainIcon);
		
		// Şarkı Numarası
		mainSongNumber = new FlxText(0, centerY + 30, FlxG.width, "1 / 1", 22);
		mainSongNumber.setFormat(Paths.font("vcr.ttf"), 22, 0xFF666666, CENTER);
		add(mainSongNumber);
		
		// Şarkı Adı (ikonun altında)
		mainSongName = new FlxText(centerX - BOX_SIZE/2 + 10, centerY + 60, BOX_SIZE - 20, "???", 32);
		mainSongName.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		mainSongName.borderSize = 3;
		add(mainSongName);
		
		// Navigasyon Okları
		leftArrow = new FlxText(centerX - BOX_SIZE/2 - 80, centerY - 30, 60, "◄", 60);
		leftArrow.setFormat(Paths.font("vcr.ttf"), 60, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		leftArrow.borderSize = 3;
		add(leftArrow);
		
		rightArrow = new FlxText(centerX + BOX_SIZE/2 + 20, centerY - 30, 60, "►", 60);
		rightArrow.setFormat(Paths.font("vcr.ttf"), 60, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		rightArrow.borderSize = 3;
		add(rightArrow);
		
		WeekData.setDirectoryFromWeek();

		// ═══════════════════════════════════════════════════════════════
		// SAĞ PANEL - Skor Bilgisi
		// ═══════════════════════════════════════════════════════════════
		
		var panelX = FlxG.width - 280;
		var panelY = FlxG.height / 2 - 100;
		
		var scorePanel = new FlxSprite(panelX, panelY).makeGraphic(260, 200, 0xAA0a0a0a);
		add(scorePanel);
		
		var scorePanelBorder = new FlxSprite(panelX - 3, panelY - 3).makeGraphic(266, 206, 0xFF660000);
		add(scorePanelBorder);
		
		var scorePanelInner = new FlxSprite(panelX, panelY).makeGraphic(260, 200, 0xCC0a0a0a);
		add(scorePanelInner);

		scoreText = new FlxText(panelX + 10, panelY + 20, 240, "SKOR: 0", 20);
		scoreText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER);
		add(scoreText);

		diffText = new FlxText(panelX + 10, panelY + 80, 240, "NORMAL", 28);
		diffText.setFormat(Paths.font("vcr.ttf"), 28, 0xFFFF4444, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		diffText.borderSize = 2;
		add(diffText);
		
		var hintText = new FlxText(panelX + 10, panelY + 140, 240, "← → ZORLUK\nSPACE DİNLE", 16);
		hintText.setFormat(Paths.font("vcr.ttf"), 16, 0xFF666666, CENTER);
		add(hintText);

		// Missing text
		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		// ═══════════════════════════════════════════════════════════════
		// BOTTOM BAR
		// ═══════════════════════════════════════════════════════════════
		
		bottomBG = new FlxSprite(0, FlxG.height - 50).makeGraphic(FlxG.width, 50, 0xDD0a0000);
		add(bottomBG);
		
		var controlsText = new FlxText(0, FlxG.height - 45, FlxG.width, 
			"↑↓: SEÇ  |  ENTER: BAŞLAT  |  F: FAVORİ  |  ALT: KATEGORİ  |  ESC: GERİ", 14);
		controlsText.setFormat(Paths.font("vcr.ttf"), 14, 0xFF666666, CENTER);
		add(controlsText);
		
		bottomText = new FlxText(0, FlxG.height - 25, FlxG.width, "K A R A N L I K   S E N İ   B E K L İ Y O R . . .", 16);
		bottomText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		bottomText.borderSize = 2;
		add(bottomText);
		
		// Şarkı listesini güncelle
		updateList();

		if(curSelected >= songs.length) curSelected = 0;
		intendedColor = 0xFF1a0000;
		lerpSelected = curSelected;

		changeSelection();
		
		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);

		super.create();
	}

	// ═══════════════════════════════════════════════════════════════
	// MYSTERY EFFECT FUNCTIONS
	// ═══════════════════════════════════════════════════════════════
	
	function createBloodDrips()
	{
		for(i in 0...15)
		{
			var drip = new FlxSprite(FlxG.random.float(0, FlxG.width), -FlxG.random.float(50, 200));
			drip.makeGraphic(Std.int(FlxG.random.float(2, 6)), Std.int(FlxG.random.float(30, 100)), 0xCC990000);
			drip.velocity.y = FlxG.random.float(20, 50);
			drip.alpha = FlxG.random.float(0.3, 0.7);
			add(drip);
			bloodDrips.push(drip);
		}
	}
	
	function createVignetteEffect()
	{
		var vignetteOverlay = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[0x00000000, 0x33330000, 0x66110000],
			1, -45
		);
		redVignette.stamp(vignetteOverlay);
		redVignette.alpha = 0.5;
	}
	
	function createMysteryParticles()
	{
		for(i in 0...25)
		{
			var p = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			var size = Std.int(FlxG.random.float(2, 5));
			p.makeGraphic(size, size, FlxG.random.bool(50) ? 0xFFFF0000 : 0xFF330000);
			p.alpha = FlxG.random.float(0.2, 0.6);
			p.velocity.y = FlxG.random.float(-20, -5);
			p.velocity.x = FlxG.random.float(-5, 5);
			add(p);
			mysteryParticles.push(p);
		}
	}
	
	function createEyeSprites()
	{
		for(i in 0...3)
		{
			var eye = new FlxSprite();
			if(Paths.fileExists('images/freeplay/evil_eye.png', IMAGE))
				eye.loadGraphic(Paths.image('freeplay/evil_eye'));
			else
				eye.makeGraphic(40, 40, FlxColor.RED);
			eye.alpha = 0;
			eye.setGraphicSize(30, 30);
			eye.updateHitbox();
			add(eye);
			eyeSprites.push(eye);
		}
	}
	
	function triggerGlitch(duration:Float = 0.2)
	{
		isGlitching = true;
		FlxG.camera.shake(0.01, duration);
		
		new FlxTimer().start(duration, function(tmr:FlxTimer) {
			isGlitching = false;
		});
	}

	// ═══════════════════════════════════════════════════════════════
	// LIST UPDATE
	// ═══════════════════════════════════════════════════════════════

	function updateList()
	{
		songs = [];

		for (i in 0...allSongs.length)
		{
			var meta = allSongs[i];
			var name = meta.songName;
			
			var matchCat = false;

			if (curCategory == 'Tümü') {
				matchCat = !hiddenSongs.contains(name);
			} else if (curCategory == 'Favoriler') {
				matchCat = favorites.contains(name);
			} else if (curCategory == 'Gizli') {
				matchCat = hiddenSongs.contains(name);
			}

			if (matchCat) {
				songs.push(meta);
			}
		}
		
		if (curSelected >= songs.length) curSelected = 0;
		changeSelection(0, false);
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && 
			(!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	var holdTime:Float = 0;
	var stopMusicPlay:Bool = false;

	override function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1)
			return;

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		// Score lerping
		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01) lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) ratingSplit.push('');
		while(ratingSplit[1].length < 2) ratingSplit[1] += '0';

		updateMysteryEffects(elapsed);
		updateBoxEffects(elapsed);

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (!musicPlaying)
		{
			// Category Switch
			if (FlxG.keys.justPressed.ALT) {
				curCategoryIndex++;
				if (curCategoryIndex >= categories.length) curCategoryIndex = 0;
				curCategory = categories[curCategoryIndex];
				categoryText.text = "[ " + curCategory.toUpperCase() + " ]";
				
				FlxTween.cancelTweensOf(categoryText.scale);
				categoryText.scale.set(1.3, 1.3);
				FlxTween.tween(categoryText.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.elasticOut});
				
				triggerGlitch(0.1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				updateList();
			}

			// Favorite Toggle
			if (FlxG.keys.justPressed.F && songs.length > 0) {
				var song = songs[curSelected].songName;
				if (favorites.contains(song)) {
					favorites.remove(song);
					mainSongName.color = FlxColor.WHITE;
				} else {
					favorites.push(song);
					mainSongName.color = 0xFFFFD700;
					triggerGlitch(0.1);
				}
				FlxG.save.data.favorites = favorites;
				FlxG.save.flush();
				FlxG.sound.play(Paths.sound('confirmMenu'));
				
				if (curCategory == 'Favoriler') updateList();
			}

			// Hidden Toggle
			if (FlxG.keys.justPressed.T && songs.length > 0) {
				var song = songs[curSelected].songName;
				if (hiddenSongs.contains(song)) {
					hiddenSongs.remove(song);
				} else {
					hiddenSongs.push(song);
				}
				FlxG.save.data.hiddenSongs = hiddenSongs;
				FlxG.save.flush();
				
				FlxG.sound.play(Paths.sound('cancelMenu'));
				triggerGlitch(0.2);
				updateList();
			}

			scoreText.text = 'SKOR: $lerpScore\nDOĞRULUK: ${ratingSplit.join('.')}%';
			
			if(songs.length > 0)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;	
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
				}
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}

				if(FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}

			if (controls.UI_LEFT_P)
			{
				changeDiff(-1);
				_updateSongLastDifficulty();
			}
			else if (controls.UI_RIGHT_P)
			{
				changeDiff(1);
				_updateSongLastDifficulty();
			}
		}

		if (controls.BACK)
		{
			if (musicPlaying)
			{
				if(FlxG.sound.music != null) FlxG.sound.music.stop();
				destroyFreeplayVocals();
				instPlaying = -1;
				musicPlaying = false;
				musicPaused = false;

				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else 
			{
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.camera.fade(FlxColor.BLACK, 0.3, false, function() {
					MusicBeatState.switchState(new MainMenuState());
				});
			}
		}

		if(FlxG.keys.justPressed.CONTROL && !musicPlaying)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(FlxG.keys.justPressed.SPACE)
		{
			if(songs.length == 0) return;

			if(instPlaying != curSelected && !musicPlaying)
			{
				destroyFreeplayVocals();
				if(FlxG.sound.music != null) FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				
				try {
					Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				} catch(e:Dynamic) {
					trace("Song load error: " + e);
					return;
				}
				
				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound();
					try
					{
						var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
						if(loadedVocals == null) loadedVocals = Paths.voices(PlayState.SONG.song);
						
						if(loadedVocals != null && loadedVocals.length > 0)
						{
							vocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(vocals);
							vocals.persist = vocals.looped = true;
							vocals.volume = 0.8;
							vocals.play();
						}
						else vocals = FlxDestroyUtil.destroy(vocals);
					}
					catch(e:Dynamic) { vocals = FlxDestroyUtil.destroy(vocals); }
					
					opponentVocals = new FlxSound();
					try
					{
						var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');
						
						if(loadedVocals != null && loadedVocals.length > 0)
						{
							opponentVocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(opponentVocals);
							opponentVocals.persist = opponentVocals.looped = true;
							opponentVocals.volume = 0.8;
							opponentVocals.play();
						}
						else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
					catch(e:Dynamic) { opponentVocals = FlxDestroyUtil.destroy(opponentVocals); }
				}

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
				instPlaying = curSelected;
				musicPlaying = true;
				musicPaused = false;
			}
			else if (instPlaying == curSelected && musicPlaying)
			{
				if(musicPaused)
				{
					if(FlxG.sound.music != null) FlxG.sound.music.resume();
					if(vocals != null) vocals.resume();
					if(opponentVocals != null) opponentVocals.resume();
					musicPaused = false;
				}
				else
				{
					if(FlxG.sound.music != null) FlxG.sound.music.pause();
					if(vocals != null) vocals.pause();
					if(opponentVocals != null) opponentVocals.pause();
					musicPaused = true;
				}
			}
		}
		else if (controls.ACCEPT && !musicPlaying)
		{
			if(songs.length == 0) return;

			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

			try
			{
				Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
				
				triggerGlitch(0.5);
				FlxG.camera.flash(FlxColor.RED, 0.3);
				
				new FlxTimer().start(0.3, function(tmr:FlxTimer) {
					FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function() {
						@:privateAccess
						if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
						{
							Paths.freeGraphicsFromMemory();
						}
						LoadingState.prepareToSong();
						LoadingState.loadAndSwitchState(new PlayState());
						#if !SHOW_LOADING_SCREEN 
						if(FlxG.sound.music != null) FlxG.sound.music.stop(); 
						#end
						stopMusicPlay = true;
						destroyFreeplayVocals();
					});
				});
			}
			catch(e:haxe.Exception)
			{
				var errorStr:String = e.message;
				if(errorStr.contains('There is no TEXT asset with an ID of')) 
					errorStr = 'Dosya bulunamadı: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1);
				else errorStr += '\n\n' + e.stack;

				missingText.text = 'CHART YÜKLENIRKEN HATA:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				triggerGlitch(0.3);

				super.update(elapsed);
				return;
			}

			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		else if(controls.RESET && !musicPlaying)
		{
			if(songs.length == 0) return;
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		super.update(elapsed);
	}
	
	// ═══════════════════════════════════════════════════════════════
	// BOX EFFECTS (Pulse, glow animasyonları)
	// ═══════════════════════════════════════════════════════════════
	
	function updateBoxEffects(elapsed:Float)
	{
		// Kutucuk pulse efekti
		var pulse = 0.8 + Math.sin(ambientPulse * 2) * 0.2;
		mainBoxGlow.alpha = pulse * 0.5;
		
		// Border renk değişimi
		var borderPulse = 0.6 + Math.sin(ambientPulse * 3) * 0.4;
		mainBoxBorder.alpha = borderPulse;
		
		// Ok animasyonları
		leftArrow.alpha = 0.5 + Math.sin(ambientPulse * 4) * 0.5;
		rightArrow.alpha = 0.5 + Math.sin(ambientPulse * 4 + 3.14) * 0.5;
		
		// Ok pozisyon animasyonu
		leftArrow.x = (FlxG.width / 2) - BOX_SIZE/2 - 80 + Math.sin(ambientPulse * 3) * 5;
		rightArrow.x = (FlxG.width / 2) + BOX_SIZE/2 + 20 - Math.sin(ambientPulse * 3) * 5;
	}
	
	// ═══════════════════════════════════════════════════════════════
	// MYSTERY EFFECTS UPDATE
	// ═══════════════════════════════════════════════════════════════
	
	function updateMysteryEffects(elapsed:Float)
	{
		glitchTimer += elapsed;
		ambientPulse += elapsed * 2;
		
		// Blood drips
		for(drip in bloodDrips)
		{
			if(drip.y > FlxG.height + 50)
			{
				drip.y = -FlxG.random.float(50, 200);
				drip.x = FlxG.random.float(0, FlxG.width);
				drip.velocity.y = FlxG.random.float(20, 50);
			}
		}
		
		// Particles
		for(p in mysteryParticles)
		{
			if(p.y < -20)
			{
				p.y = FlxG.height + 20;
				p.x = FlxG.random.float(0, FlxG.width);
			}
			p.alpha = 0.3 + Math.sin(ambientPulse + p.x * 0.01) * 0.2;
		}
		
		// Static noise
		if(glitchTimer > 0.05)
		{
			glitchTimer = 0;
			staticNoise.alpha = FlxG.random.float(0, 0.05);
			
			if(FlxG.random.bool(0.5))
			{
				var eye = eyeSprites[FlxG.random.int(0, eyeSprites.length - 1)];
				if(eye.alpha <= 0)
				{
					eye.x = FlxG.random.float(50, FlxG.width - 100);
					eye.y = FlxG.random.float(100, FlxG.height - 100);
					eye.alpha = 0.4;
					FlxTween.tween(eye, {alpha: 0}, 0.8);
				}
			}
		}
		
		// Title pulse
		titleText.alpha = 0.8 + Math.sin(ambientPulse * 0.5) * 0.2;
		titleText.x = Math.sin(ambientPulse * 0.3) * 2;
		
		// Random glitch
		if(FlxG.random.bool(0.2) && !isGlitching)
		{
			triggerGlitch(0.05);
		}
		
		// Bottom text
		if(FlxG.random.bool(0.5))
		{
			var bottomTexts = [
				"K A R A N L I K   S E N İ   B E K L İ Y O R . . .",
				"S E Ç İ M İ N İ   Y A P . . .",
				"O Y N A . . .",
				". . . . . . . . ."
			];
			bottomText.text = bottomTexts[FlxG.random.int(0, bottomTexts.length - 1)];
		}
	}
	
	function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end
			return character.vocals_file;
		}
		catch (e:Dynamic) {}
		return null;
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);

		if(opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	function changeDiff(change:Int = 0)
	{
		if (musicPlaying || songs.length == 0)
			return;

		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);
		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		var displayDiff:String = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '◄ ' + displayDiff.toUpperCase() + ' ►';
		else
			diffText.text = displayDiff.toUpperCase();

		missingText.visible = false;
		missingTextBG.visible = false;
		
		triggerGlitch(0.05);
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (musicPlaying || songs.length == 0)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length-1);
		_updateSongLastDifficulty();
		
		if(playSound) 
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			if(FlxG.random.bool(20)) triggerGlitch(0.05);
		}

		// Ana kutucuğu güncelle
		updateMainBox();

		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}
	
	function updateMainBox()
	{
		if(songs.length == 0)
		{
			mainSongName.text = "ŞARKI YOK";
			mainSongNumber.text = "0 / 0";
			return;
		}
		
		var song = songs[curSelected];
		
		// İkonu güncelle
		Mods.currentModDirectory = song.folder;
		
		// Eski ikonu kaldır ve yenisini ekle
		if(mainIcon != null)
		{
			remove(mainIcon);
			mainIcon.destroy();
		}
		
		mainIcon = new HealthIcon(song.songCharacter);
		mainIcon.setGraphicSize(180, 180);
		mainIcon.updateHitbox();
		mainIcon.x = FlxG.width / 2 - 90;
		mainIcon.y = FlxG.height / 2 - 20 - BOX_SIZE/2 + 40;
		add(mainIcon);
		
		// İkon animasyonu
		mainIcon.scale.set(0.5, 0.5);
		FlxTween.tween(mainIcon.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});
		
		// Şarkı adını güncelle
		mainSongName.text = song.songName;
		
		// Favori kontrolü
		if(favorites.contains(song.songName))
		{
			mainSongName.color = 0xFFFFD700;
		}
		else
		{
			mainSongName.color = FlxColor.WHITE;
		}
		
		// Şarkı numarasını güncelle
		mainSongNumber.text = '${curSelected + 1} / ${songs.length}';
		
		// Kutucuk animasyonu
		FlxTween.cancelTweensOf(mainBox.scale);
		mainBox.scale.set(0.95, 0.95);
		FlxTween.tween(mainBox.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.backOut});
		
		// Border animasyonu
		FlxTween.cancelTweensOf(mainBoxBorder.scale);
		mainBoxBorder.scale.set(0.95, 0.95);
		FlxTween.tween(mainBoxBorder.scale, {x: 1, y: 1}, 0.25, {ease: FlxEase.backOut});
	}

	inline private function _updateSongLastDifficulty()
	{
		if (songs.length > 0)
			songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);
	}

	override function destroy():Void
	{
		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (FlxG.sound.music != null && !FlxG.sound.music.playing && !stopMusicPlay)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}	
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}