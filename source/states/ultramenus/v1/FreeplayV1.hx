package states.ultramenus.v1;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
//import objects.MusicPlayer;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import openfl.utils.Assets;
import haxe.Json;

class FreeplayV1 extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
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

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	//var player:MusicPlayer;

	// ── YENİ UI DEĞİŞKENLERİ ────────────────────────────────────
	var gridBG:FlxBackdrop;
	var leftPanel:FlxSprite;
	var rightPanel:FlxSprite;
	var rightPanelBorder:FlxSprite;

	// Sağ panel - önizleme
	var previewBG:FlxSprite;
	var bigIcon:HealthIcon;
	var songTitleText:FlxText;
	var songTitleGlow:FlxSprite;
	var diffBadge:FlxSprite;
	var diffBadgeText:FlxText;
	var scorePanelBG:FlxSprite;
	var scorePanelLabel:FlxText;
	var scorePanelValue:FlxText;
	var ratingPanelBG:FlxSprite;
	var ratingPanelLabel:FlxText;
	var ratingPanelValue:FlxText;
	
	var isPlayingMusic:Bool = false;
	var isPaused:Bool = false;

	// Üst bar
	var topBar:FlxSprite;
	var topBarTitle:FlxText;
	var topBarSub:FlxText;

	// Partiküller
	var particles:Array<FlxSprite> = [];

	var ambientTime:Float = 0;

	// Tema renkleri
	static final BG_DARK:FlxColor    = 0xFF050508;
	static final PANEL_BG:FlxColor   = 0xCC0a0a12;
	static final ACCENT:FlxColor     = 0xFF8B5CF6;
	static final ACCENT2:FlxColor    = 0xFF4A90E2;
	static final WHITE:FlxColor      = 0xFFFFFFFF;
	static final GREY:FlxColor       = 0xFF888888;

	var stopMusicPlay:Bool = false;
	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	var holdTime:Float = 0;

	override function create()
	{
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() ThemeManager.switchToMainMenu()));
			return;
		}

		for (i in 0...WeekData.weeksList.length)
		{
			if(weekIsLocked(WeekData.weeksList[i])) continue;
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3) colors = [146, 113, 253];
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		// ── ARKA PLAN ────────────────────────────────────────────
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, BG_DARK);
		add(bg);

		// Renkli gradient overlay (şarkı rengine göre değişecek)
		var colorOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		colorOverlay.alpha = 0;
		add(colorOverlay);

		gridBG = new FlxBackdrop(FlxGridOverlay.createGrid(40, 40, 80, 80, true, 0x08FFFFFF, 0x0));
		gridBG.velocity.set(6, 6);
		add(gridBG);

		// Partiküller
		createParticles();

		// ── SOL PANEL ────────────────────────────────────────────
		leftPanel = FlxGradient.createGradientFlxSprite(
			420, FlxG.height,
			[0xEE050508, 0xDD050508],
			1, 0
		);
		add(leftPanel);

		var leftBorder = new FlxSprite(418, 0).makeGraphic(2, FlxG.height, ACCENT);
		leftBorder.alpha = 0.4;
		add(leftBorder);

		// ── SAĞ PANEL ────────────────────────────────────────────
		rightPanel = new FlxSprite(420, 0).makeGraphic(Std.int(FlxG.width - 420), FlxG.height, 0xFF000000);
		rightPanel.alpha = 0.3;
		add(rightPanel);

		// Sağ panel üst gradient
		var rightGrad = FlxGradient.createGradientFlxSprite(
			Std.int(FlxG.width - 420), Std.int(FlxG.height / 2),
			[0x44000000, 0x00000000],
			1, 90
		);
		rightGrad.x = 420;
		add(rightGrad);

		// ── ÜST BAR ──────────────────────────────────────────────
		topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 65, 0xDD000000);
		add(topBar);

		var topBarLine = new FlxSprite(0, 63).makeGraphic(FlxG.width, 2, ACCENT);
		topBarLine.alpha = 0.6;
		add(topBarLine);

		topBarTitle = new FlxText(20, 10, 0, "SERBEST OYUN", 30);
		topBarTitle.setFormat(Paths.font("vcr.ttf"), 30, WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		topBarTitle.borderSize = 2;
		add(topBarTitle);

		topBarSub = new FlxText(20, 43, 0, "Bir şarkı seç ve oyna!", 16);
		topBarSub.setFormat(Paths.font("vcr.ttf"), 16, ACCENT, LEFT);
		add(topBarSub);

		// ── ŞARKI LİSTESİ (SOL) ──────────────────────────────────
		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			grpSongs.add(songText);
			songText.scaleX = Math.min(1, 340 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;
			iconArray.push(icon);
			add(icon);
		}
		WeekData.setDirectoryFromWeek();

		// ── SAĞ PANEL - BÜYÜK İKON ───────────────────────────────
		// İkon arka plan dairesi
		previewBG = new FlxSprite(0, 0).makeGraphic(300, 300, ACCENT);
		previewBG.x = 420 + (FlxG.width - 420) / 2 - 150;
		previewBG.y = FlxG.height / 2 - 200;
		previewBG.alpha = 0.08;
		add(previewBG);

		bigIcon = new HealthIcon('bf');
		bigIcon.setGraphicSize(280, 280);
		bigIcon.updateHitbox();
		bigIcon.x = 420 + (FlxG.width - 420) / 2 - 140;
		bigIcon.y = FlxG.height / 2 - 195;
		bigIcon.antialiasing = ClientPrefs.data.antialiasing;
		add(bigIcon);

		// Şarkı adı (sağ panel alt)
		songTitleGlow = new FlxSprite(420, 0).makeGraphic(Std.int(FlxG.width - 420), 80, ACCENT);
		songTitleGlow.y = FlxG.height / 2 + 110;
		songTitleGlow.alpha = 0.08;
		add(songTitleGlow);

		songTitleText = new FlxText(430, 0, Std.int(FlxG.width - 440), "", 34);
		songTitleText.setFormat(Paths.font("vcr.ttf"), 34, WHITE, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		songTitleText.borderSize = 2;
		songTitleText.y = FlxG.height / 2 + 118;
		add(songTitleText);

		// Zorluk badge
		diffBadge = new FlxSprite(0, 0).makeGraphic(160, 36, ACCENT);
		diffBadge.screenCenter(X);
		diffBadge.x += 100;
		diffBadge.y = FlxG.height / 2 + 160;
		diffBadge.alpha = 0.85;
		add(diffBadge);

		diffBadgeText = new FlxText(diffBadge.x, diffBadge.y + 7, 160, "NORMAL", 18);
		diffBadgeText.setFormat(Paths.font("vcr.ttf"), 18, WHITE, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		diffBadgeText.borderSize = 1;
		add(diffBadgeText);

		// Skor paneli
		scorePanelBG = new FlxSprite(430, FlxG.height / 2 + 205).makeGraphic(Std.int((FlxG.width - 440) / 2 - 5), 70, PANEL_BG);
		add(scorePanelBG);

		var scoreLine = new FlxSprite(430, FlxG.height / 2 + 205).makeGraphic(Std.int((FlxG.width - 440) / 2 - 5), 3, ACCENT);
		scoreLine.alpha = 0.6;
		add(scoreLine);

		scorePanelLabel = new FlxText(440, FlxG.height / 2 + 212, 0, "🏆 EN İYİ SKOR", 14);
		scorePanelLabel.setFormat(Paths.font("vcr.ttf"), 14, ACCENT, LEFT);
		add(scorePanelLabel);

		scorePanelValue = new FlxText(440, FlxG.height / 2 + 232, Std.int((FlxG.width - 440) / 2 - 20), "0", 22);
		scorePanelValue.setFormat(Paths.font("vcr.ttf"), 22, WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		scorePanelValue.borderSize = 1;
		add(scorePanelValue);

		// Rating paneli
		var ratingX = 430 + Std.int((FlxG.width - 440) / 2) + 10;
		ratingPanelBG = new FlxSprite(ratingX, FlxG.height / 2 + 205).makeGraphic(Std.int((FlxG.width - 440) / 2 - 15), 70, PANEL_BG);
		add(ratingPanelBG);

		var ratingLine = new FlxSprite(ratingX, FlxG.height / 2 + 205).makeGraphic(Std.int((FlxG.width - 440) / 2 - 15), 3, ACCENT2);
		ratingLine.alpha = 0.6;
		add(ratingLine);

		ratingPanelLabel = new FlxText(ratingX + 10, FlxG.height / 2 + 212, 0, "🎯 DOĞRULUK", 14);
		ratingPanelLabel.setFormat(Paths.font("vcr.ttf"), 14, ACCENT2, LEFT);
		add(ratingPanelLabel);

		ratingPanelValue = new FlxText(ratingX + 10, FlxG.height / 2 + 232, Std.int((FlxG.width - 440) / 2 - 20), "N/A", 22);
		ratingPanelValue.setFormat(Paths.font("vcr.ttf"), 22, WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		ratingPanelValue.borderSize = 1;
		add(ratingPanelValue);

		// ── MISSING TEXT ─────────────────────────────────────────
		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		// ── ALT BAR ──────────────────────────────────────────────
		bottomBG = new FlxSprite(0, FlxG.height - 30).makeGraphic(FlxG.width, 30, 0xDD000000);
		add(bottomBG);

		var bottomLine = new FlxSprite(0, FlxG.height - 30).makeGraphic(FlxG.width, 2, ACCENT);
		bottomLine.alpha = 0.3;
		add(bottomLine);

		var leText:String = Language.getPhrase("freeplay_tip", "SPACE: Dinle   CTRL: Oyun Ayarları   RESET: Skoru Sıfırla   ◄►: Zorluk");
		bottomString = leText;
		bottomText = new FlxText(0, FlxG.height - 24, FlxG.width, leText, 14);
		bottomText.setFormat(Paths.font("vcr.ttf"), 14, GREY, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);

		// Versiyon
		var versionText = new FlxText(FlxG.width - 200, FlxG.height - 24, 190, "FREEPLAY V1 TEMA", 12);
		versionText.setFormat(Paths.font("vcr.ttf"), 12, 0xFF444444, RIGHT);
		add(versionText);

		// ── MUSİC PLAYER ─────────────────────────────────────────
		// Eski scoreBG/scoreText/diffText - artık kullanmıyoruz ama player için gerekli
		scoreText = new FlxText(0, -100, 0, "", 32); // Ekran dışında
		scoreBG = new FlxSprite(0, -100).makeGraphic(1, 1, FlxColor.BLACK);
		diffText = new FlxText(0, -100, 0, "", 24);
		add(scoreBG);
		add(diffText);
		add(scoreText);

		if(curSelected >= songs.length) curSelected = 0;
		intendedColor = songs[curSelected].color;
		lerpSelected = curSelected;
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		changeSelection();
		updateTexts();
		super.create();

		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);
	}

	function createParticles()
	{
		for (i in 0...20)
		{
			var p = new FlxSprite(
				FlxG.random.float(420, FlxG.width),
				FlxG.random.float(0, FlxG.height)
			);
			var size = Std.int(FlxG.random.float(1, 3));
			p.makeGraphic(size, size, i % 2 == 0 ? ACCENT : ACCENT2);
			p.alpha = FlxG.random.float(0.05, 0.2);
			p.velocity.y = FlxG.random.float(-15, -4);
			p.velocity.x = FlxG.random.float(-2, 2);
			add(p);
			particles.push(p);
		}
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
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	override function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1) return;

		ambientTime += elapsed;

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01) lerpRating = intendedRating;

		// Sağ panel panelleri güncelle
		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) ratingSplit.push('');
		while(ratingSplit[1].length < 2) ratingSplit[1] += '0';

		if (!isPlayingMusic)
		{
			scorePanelValue.text = Std.string(lerpScore);
			ratingPanelValue.text = ratingSplit.join('.') + '%';

			// Rating rengi
			var ratingVal = lerpRating * 100;
			if(ratingVal >= 95) ratingPanelValue.color = 0xFF10B981;
			else if(ratingVal >= 80) ratingPanelValue.color = 0xFFF59E0B;
			else if(ratingVal > 0) ratingPanelValue.color = 0xFFFF5555;
			else ratingPanelValue.color = GREY;

			// scoreText güncelle (player için)
			scoreText.text = Language.getPhrase('personal_best', 'PERSONAL BEST: {1} ({2}%)', [lerpScore, ratingSplit.join('.')]);
			positionHighscore();
		}

		// Partiküller
		for (p in particles)
			if (p.y < -5) { p.y = FlxG.height + 5; p.x = FlxG.random.float(420, FlxG.width); }

		// Büyük ikon nefes efekti
		if(bigIcon != null)
		{
			var breathe = 1 + Math.sin(ambientTime * 1.5) * 0.02;
			bigIcon.scale.set(breathe, breathe);
		}

		// previewBG pulse
		if(previewBG != null)
			previewBG.alpha = 0.06 + Math.sin(ambientTime * 2) * 0.03;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (!isPlayingMusic)
		{
			if(songs.length > 1)
			{
				if(FlxG.keys.justPressed.HOME) { curSelected = 0; changeSelection(); holdTime = 0; }
				else if(FlxG.keys.justPressed.END) { curSelected = songs.length - 1; changeSelection(); holdTime = 0; }

				if (controls.UI_UP_P)   { changeSelection(-shiftMult); holdTime = 0; }
				if (controls.UI_DOWN_P) { changeSelection(shiftMult);  holdTime = 0; }

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

			if (controls.UI_LEFT_P)       { changeDiff(-1); _updateSongLastDifficulty(); }
			else if (controls.UI_RIGHT_P) { changeDiff(1);  _updateSongLastDifficulty(); }
		}

		if (controls.BACK)
		{
			if (isPlayingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;
				isPlayingMusic = false;
				isPaused = false;
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else
			{
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				ThemeManager.switchToMainMenu();
			}
		}

		if(FlxG.keys.justPressed.CONTROL && !isPlayingMusic)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(FlxG.keys.justPressed.SPACE)
		{
			if(instPlaying != curSelected && !isPlayingMusic)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
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
							vocals.pause();
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
							opponentVocals.pause();
						}
						else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
					catch(e:Dynamic) { opponentVocals = FlxDestroyUtil.destroy(opponentVocals); }
				}

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
				FlxG.sound.music.pause();
				instPlaying = curSelected;
				isPlayingMusic = true;
				isPaused = false;
				FlxG.sound.music.play();
				if(vocals != null) vocals.play();
				if(opponentVocals != null) opponentVocals.play();
			}
			if(isPaused) {
				isPaused = false;
				FlxG.sound.music.resume();
				if(vocals != null) vocals.resume();
				if(opponentVocals != null) opponentVocals.resume();
			} else {
				isPaused = true;
				FlxG.sound.music.pause();
				if(vocals != null) vocals.pause();
				if(opponentVocals != null) opponentVocals.pause();
			}
		}
		else if (controls.ACCEPT && !isPlayingMusic)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

			try
			{
				Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			}
			catch(e:haxe.Exception)
			{
				trace('ERROR! ${e.message}');
				var errorStr:String = e.message;
				if(errorStr.contains('There is no TEXT asset with an ID of'))
					errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1);
				else errorStr += '\n\n' + e.stack;

				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				updateTexts(elapsed);
				super.update(elapsed);
				return;
			}

			@:privateAccess
			if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
			{
				trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
				Paths.freeGraphicsFromMemory();
			}
			LoadingState.prepareToSong();
			ThemeManager.loadAndSwitchToPlay();
			#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
			stopMusicPlay = true;
			destroyFreeplayVocals();
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		else if(controls.RESET && !isPlayingMusic)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		updateTexts(elapsed);
		super.update(elapsed);
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

	public static function destroyFreeplayVocals()
	{
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);
		if(opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	function changeDiff(change:Int = 0)
	{
		if (isPlayingMusic) return;

		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length - 1);
		#if !switch
		intendedScore  = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		var displayDiff:String = Difficulty.getString(curDifficulty);

		// Badge güncelle
		if(diffBadgeText != null)
			diffBadgeText.text = displayDiff.toUpperCase();

		// diffText güncelle (player için)
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + displayDiff.toUpperCase() + ' >';
		else
			diffText.text = displayDiff.toUpperCase();

		// Badge rengi zorluğa göre
		if(diffBadge != null)
		{
			var diffColor:FlxColor = switch(displayDiff.toLowerCase())
			{
				case 'easy':   0xFF10B981;
				case 'hard':   0xFFFF5555;
				case 'erect':  0xFFEC4899;
				default:       ACCENT;
			};
			FlxTween.color(diffBadge, 0.3, diffBadge.color, diffColor);
		}

		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (isPlayingMusic) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColor);
		}

		// Büyük ikonu güncelle
		if(bigIcon != null)
		{
			Mods.currentModDirectory = songs[curSelected].folder;
			bigIcon.changeIcon(songs[curSelected].songCharacter);
			bigIcon.setGraphicSize(280, 280);
			bigIcon.updateHitbox();
			bigIcon.x = 420 + (FlxG.width - 420) / 2 - 140;

			// İkon değişim animasyonu
			FlxTween.cancelTweensOf(bigIcon);
			bigIcon.alpha = 0;
			bigIcon.scale.set(0.8, 0.8);
			FlxTween.tween(bigIcon, {alpha: 1, "scale.x": 1, "scale.y": 1}, 0.3, {ease: FlxEase.backOut});
		}

		// Şarkı adını güncelle
		if(songTitleText != null)
		{
			FlxTween.cancelTweensOf(songTitleText);
			songTitleText.alpha = 0;
			songTitleText.text = songs[curSelected].songName;
			FlxTween.tween(songTitleText, {alpha: 1}, 0.3, {ease: FlxEase.quadOut});
		}

		// previewBG rengi
		if(previewBG != null)
			FlxTween.color(previewBG, 0.5, previewBG.color, newColor);

		for (num => item in grpSongs.members)
		{
			var icon:HealthIcon = iconArray[num];
			item.alpha = icon.alpha = (item.targetY == curSelected) ? 1 : 0.6;
		}

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

	inline private function _updateSongLastDifficulty()
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);

	private function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];

	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));

		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));

		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
	}

	override function beatHit()
	{
		super.beatHit();

		// Büyük ikon beat bump
		if(bigIcon != null)
		{
			FlxTween.cancelTweensOf(bigIcon.scale);
			bigIcon.scale.set(1.08, 1.08);
			FlxTween.tween(bigIcon.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.quadOut});
		}

		// Şarkı adı flash
		if(songTitleText != null)
		{
			FlxTween.cancelTweensOf(songTitleText);
			songTitleText.color = ACCENT;
			FlxTween.color(songTitleText, 0.3, ACCENT, WHITE);
		}
	}

	override function destroy():Void
	{
		super.destroy();
		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing && !stopMusicPlay)
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