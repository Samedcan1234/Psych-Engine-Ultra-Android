package states;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import objects.Alphabet;
import flixel.input.keyboard.FlxKey;
import backend.Achievements;
import backend.WeekData;
import backend.Highscore;
import backend.ThemeManager;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.util.FlxTimer;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import backend.Song; 
import objects.HealthIcon;
import flixel.addons.ui.FlxInputText;
import flixel.ui.FlxBar;
import DateTools;
import states.PlayState;
import states.LoadingState;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0.4';
	public static var curSelected:Int = 0;
	
	var menuItems:FlxTypedGroup<FlxSpriteGroup>;
	var optionShit:Array<String> = [
		'hikaye_modu',
		'serbest_oyun',
		'guncelleme',
		#if MODS_ALLOWED 'modlar', #end
		#if ACHIEVEMENTS_ALLOWED 'basarimlar', #end
		'yapimcilar',
		'ayarlar'
	];

	// --- MODERN UI DEĞİŞKENLERİ ---
	var scanline:FlxBackdrop;
	var vignette:FlxSprite;
	var sideBar:FlxSprite;
	var sideBarGlow:FlxSprite;
	var menuCards:FlxTypedGroup<FlxSpriteGroup>;
	var cardGlows:Array<FlxSprite> = [];
	var cardIcons:Array<FlxSprite> = [];
	var cardTitles:Array<FlxText> = [];
	var systemStatusText:FlxText;
	var mouseCursor:FlxSprite;
	
	// Oyuncu İsmi Sistemi Değişkenleri
	var needsPlayerName:Bool = false;
	var nameInputBox:FlxInputText;
	var nameInputBG:FlxSprite;
	var nameInputTitle:FlxText;
	var nameInputHint:FlxText;
	var nameInputButton:FlxSprite;
	var nameInputButtonText:FlxText;
	var nameInputOverlay:FlxSprite;
	var isChangelogOpen:Bool = false;
	var changelogBG:FlxSprite;
	var changelogLogo:FlxSprite;
	var changelogTextTitle:FlxText;
	var changelogTextNotes:FlxText;
	var changelogHint:FlxText;
	var bumpIntensity:Float = 0;
	
	var adminPanel:AdminPanel;
	var bgLayer1:FlxSprite;
	var bgLayer2:FlxSprite;
	var bgLayer3:FlxSprite;
	var gradientOverlay:FlxSprite;
	var gridBG:FlxBackdrop;
	var particles:Array<FlxSprite> = [];
	var glowParticles:Array<FlxSprite> = [];
	var floatingOrbs:Array<FlxSprite> = [];
	var topBar:FlxSprite;
	var topBarGlow:FlxSprite;
	var topBarLine:FlxSprite;
	var bottomBar:FlxSprite;
	var bottomBarGlow:FlxSprite;
	var bottomLine:FlxSprite;
	var selectionGlow:FlxSprite;
	var descriptionTitle:FlxText;
	var descriptionText:FlxText;
	
	// Profil Sistemi Değişkenleri
	var profilePanel:FlxSprite;
	var profilePanelGlow:FlxSprite;
	var profileName:FlxText;
	var profileIcon:HealthIcon;
	var profileLevel:FlxText;
	var profileXPBar:FlxBar;
	var profileXPText:FlxText;
	var profileRank:FlxText;
	var profileRankIcon:FlxText;
	
	// İstatislik Sistemi Değişkenleri
	var statsPanel:FlxSprite;
	var statsPanelGlow:FlxSprite; 
	var statsTotalScore:FlxText;
	var statsSongsPlayed:FlxText;
	var statsPlayTime:FlxText;
	var statsAccuracy:FlxText;
	var statsPerfects:FlxText; 
	
	// İkon Değişkenleri
	var scoreIcon:FlxText;
	var songsIcon:FlxText;
	var timeIcon:FlxText;
	var accIcon:FlxText;
	
	// Diğer Değişkenler
	var clockText:FlxText;
	var dateText:FlxText;
	var greetingText:FlxText;
	var lastPlayedPanel:FlxSprite;
	var lastPlayedSong:FlxText;
	var lastPlayedScore:FlxText;
	var lastPlayedDifficulty:FlxText;
	var quickPlayButton:FlxSprite;
	var quickPlayText:FlxText;
	var quickPlayGlow:FlxSprite;
	var newsPanel:FlxSprite;
	var newsTitle:FlxText;
	var newsText:FlxText;
	var newsIndex:Int = 0;
	var newsTimer:Float = 0;
	var versionText:FlxText;
	var engineLogo:FlxText;
	var engineLogoGlow:FlxSprite;
	
	var currentTheme:FlxColor = 0xFF4A90E2;
	var themeColors:Array<FlxColor> = [0xFF4A90E2, 0xFF8B5CF6, 0xFF10B981, 0xFFF59E0B, 0xFFEC4899, 0xFF64748B];
	var ambientPulse:Float = 0;
	var breathingEffect:Float = 0;
	var selectedSomethin:Bool = false;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var cheatSequence:Array<Int> = [];
	var cheatPattern:Array<Int> = [0, 3, 3, 2];
	var cheatLastInputTime:Float = 0;
	var cheatTimeout:Float = 1.5;
	var prevUp:Bool = false;
	var prevRight:Bool = false;
	var prevLeft:Bool = false;

	var menuColorMap:Map<String, FlxColor> = [
		'hikaye_modu' => 0xFF4A90E2,
		'serbest_oyun' => 0xFF00E5FF,
		'guncelleme' => 0xFF8B5CF6,
		'modlar' => 0xFF10B981,
		'basarimlar' => 0xFF00E5FF,
		'yapimcilar' => 0xFF10B981,
		'ayarlar' => 0xFF64748B
	];
	
	var menuIconMap:Map<String, String> = [
		'hikaye_modu' => "⭐",
		'serbest_oyun' => "�",
		'guncelleme' => "�",
		'modlar' => "🧬",
		'basarimlar' => "💎",
		'yapimcilar' => "�️",
		'ayarlar' => "🛡️"
	];

	var menuDescriptions:Map<String, String> = [
		'hikaye_modu' => "Ana hikayeyi yaşa ve rakiplerini alt et!\nEpik bir macera seni bekliyor.",
		'serbest_oyun' => "Tüm şarkılar senin emrinde!\nPratik yap, rekorlar kır.",
		'guncelleme' => "P.E.T XQ Edition yenilikleri!\nSürüm notlarını incele.",
		'modlar' => "Topluluk modlarını keşfet!\nSınırsız içerik dünyası.",
		'basarimlar' => "Kazandığın tüm başarılar!\nKoleksiyonunu tamamla.",
		'yapimcilar' => "Muhteşem ekibimiz!\nBu projeyi hazırlayanlar.",
		'ayarlar' => "Oyunu kişiselleştir!\nHer şey kontrolünde."
	];
	
	var menuTitles:Map<String, String> = [
		'hikaye_modu' => "HİKAYE MODU",
		'serbest_oyun' => "SERBEST OYUN",
		'guncelleme' => "GÜNCELLEME GÜNLÜĞÜ",
		'modlar' => "MOD MERKEZİ",
		'basarimlar' => "BAŞARILAR",
		'yapimcilar' => "YAPIMCILAR",
		'ayarlar' => "AYARLAR"
	];
	
	var newsItems:Array<String> = [
		"🎉 Yeni güncelleme yayınlandı! Yeni özellikler eklendi. Güncelleme Kayıtlarından Bakın!",
		" Psych Engine Türkiye Çok İyiii :D",
		"🏆 Haftalık turnuva başladı! Katılmayı unutmayın.",
		"💡 Discord Sunucumuza Katılmayı Unutmayın",
		"🔥 Bide Şu Kodları Yaparken Ellerim Yanmasa!"
	];

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Ana Menüde - XQ Edition", null);
		#end

		persistentUpdate = persistentDraw = true;

		// İsim Kontrol
		if(FlxG.save.data.playerName == null || FlxG.save.data.playerName == "")
		{
			// Oyuncu İsmi Girilmediyse İste
			needsPlayerName = true;
		}

		// --- ARKA PLAN KATMANLARI ---
		bgLayer1 = new FlxSprite().makeGraphic(Std.int(FlxG.width * 1.5), Std.int(FlxG.height * 1.5), 0xFF05050a);
		bgLayer1.screenCenter();
		add(bgLayer1);
		
		gridBG = new FlxBackdrop(FlxGridOverlay.createGrid(60, 60, 120, 120, true, 0x08FFFFFF, 0x0));
		gridBG.velocity.set(15, 15);
		gridBG.alpha = 0.2;
		add(gridBG);
		
		bgLayer2 = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bgLayer2.antialiasing = ClientPrefs.data.antialiasing;
		bgLayer2.setGraphicSize(Std.int(FlxG.width * 1.3));
		bgLayer2.updateHitbox();
		bgLayer2.screenCenter();
		bgLayer2.alpha = 0.4;
		bgLayer2.color = currentTheme;
		add(bgLayer2);

		scanline = new FlxBackdrop(null, Y, 0, 2);
		scanline.makeGraphic(FlxG.width, 4, 0x11FFFFFF);
		scanline.velocity.y = 40;
		add(scanline);
		
		vignette = new FlxSprite().loadGraphic(Paths.image('vignette'));
		vignette.setGraphicSize(FlxG.width, FlxG.height);
		vignette.updateHitbox();
		vignette.alpha = 0.6;
		add(vignette);

		createParticles();
		createFloatingOrbs();

		// --- MODERN ÜST PANEL (GLASSMORFİZM) ---
		topBarGlow = new FlxSprite(0, 0).makeGraphic(FlxG.width, 85, currentTheme);
		topBarGlow.alpha = 0.15;
		add(topBarGlow);
		
		topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 80, 0x99000000);
		add(topBar);
		
		topBarLine = new FlxSprite(0, 78).makeGraphic(FlxG.width, 2, currentTheme);
		topBarLine.alpha = 0.8;
		add(topBarLine);
		
		engineLogo = new FlxText(30, 15, 0, "PSYCH ENGİNE ULTRA", 36);
		engineLogo.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		engineLogo.borderSize = 2;
		add(engineLogo);
		
		systemStatusText = new FlxText(30, 52, 0, "TÜRKİYE EDİTİON", 14);
		systemStatusText.setFormat(Paths.font("vcr.ttf"), 14, currentTheme, LEFT);
		add(systemStatusText);
		
		clockText = new FlxText(FlxG.width - 200, 18, 180, "", 28);
		clockText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, RIGHT);
		add(clockText);
		
		dateText = new FlxText(FlxG.width - 200, 48, 180, "", 14);
		dateText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFBBBBBB, RIGHT);
		add(dateText);
		
		greetingText = new FlxText(FlxG.width - 450, 30, 240, "", 18);
		greetingText.setFormat(Paths.font("vcr.ttf"), 18, currentTheme, RIGHT);
		add(greetingText);
		updateTimeAndGreeting();

		// --- ANA MENÜ KARTLARI (MODERN DİZİLİM) ---
		menuCards = new FlxTypedGroup<FlxSpriteGroup>();
		add(menuCards);

		for (i in 0...optionShit.length)
		{
			var card = new FlxSpriteGroup();
			
			var bg = new FlxSprite(0, 0).makeGraphic(200, 280, 0xAA000000);
			card.add(bg);
			
			var border = new FlxSprite(-2, -2).makeGraphic(204, 284, currentTheme);
			border.alpha = 0.5;
			card.add(border);
			
			var glow = new FlxSprite(-10, -10).makeGraphic(220, 300, currentTheme);
			glow.alpha = 0;
			card.add(glow);
			cardGlows.push(glow);
			
			// Görsel İkonlar
			var iconName:String = optionShit[i];
			if(iconName == 'guncelleme') iconName = 'guncelleme_kayitlari';
			if(iconName == 'basarimlar') iconName = 'basarilar';
			
			var icon = new FlxSprite(40, 30); // Merkeze hizalandı (200 - 120) / 2 = 40
			try {
				icon.loadGraphic(Paths.image('ultra/mainmenu/' + iconName));
			} catch(e:Dynamic) {
				// Eğer ikon bulunamazsa boş bir kare oluştur (çökmesin)
				icon.makeGraphic(100, 100, FlxColor.WHITE);
			}
			icon.setGraphicSize(120, 120);
			icon.updateHitbox();
			card.add(icon);
			cardIcons.push(icon);
			
			var title = new FlxText(10, 180, 180, menuTitles.get(optionShit[i]), 24);
			title.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
			card.add(title);
			cardTitles.push(title);
			
			var decoLine = new FlxSprite(20, 170).makeGraphic(160, 2, currentTheme);
			card.add(decoLine);

			card.ID = i;
			card.screenCenter(Y);
			card.x = FlxG.width + 200; // Ekran dışından başlat
			menuCards.add(card);
		}

		// --- SAĞ PANEL (BİLGİ) ---
		var descBG = new FlxSprite(FlxG.width - 420, 100).makeGraphic(400, 150, 0xAA000000);
		add(descBG);
		
		var descLine = new FlxSprite(FlxG.width - 420, 100).makeGraphic(400, 3, currentTheme);
		add(descLine);
		
		descriptionTitle = new FlxText(FlxG.width - 400, 115, 360, "", 32);
		descriptionTitle.setFormat(Paths.font("vcr.ttf"), 32, currentTheme, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		add(descriptionTitle);
		
		descriptionText = new FlxText(FlxG.width - 400, 160, 360, "", 18);
		descriptionText.setFormat(Paths.font("vcr.ttf"), 18, 0xFFDDDDDD, LEFT);
		add(descriptionText);

		// --- PROFİL WIDGET ---
		profilePanelGlow = new FlxSprite(28, 108).makeGraphic(244, 154, 0xFF10B981);
		profilePanelGlow.alpha = 0.1;
		add(profilePanelGlow);
		
		profilePanel = new FlxSprite(30, 110).makeGraphic(240, 150, 0xCC000000);
		add(profilePanel);
		
		var profBorder = new FlxSprite(30, 110).makeGraphic(240, 2, 0xFF10B981);
		add(profBorder);
		
		profileIcon = new HealthIcon('bf');
		profileIcon.setGraphicSize(50, 50);
		profileIcon.updateHitbox();
		profileIcon.setPosition(45, 130); // Pozisyon ayarlandı
		add(profileIcon);
		
		profileName = new FlxText(105, 135, 150, "" + FlxG.save.data.playerName, 22); // İkonun sağına çekildi
		profileName.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, LEFT);
		add(profileName);
		
		profileRankIcon = new FlxText(105, 165, 30, "🥇", 16);
		add(profileRankIcon);
		
		profileRank = new FlxText(130, 167, 100, "ROOKIE", 14);
		profileRank.setFormat(Paths.font("vcr.ttf"), 14, 0xFFFFD700, LEFT);
		add(profileRank);
		
		profileLevel = new FlxText(105, 185, 150, "Level: 1", 14);
		profileLevel.setFormat(Paths.font("vcr.ttf"), 14, 0xFF888888, LEFT);
		add(profileLevel);
		
		profileXPBar = new FlxBar(45, 215, LEFT_TO_RIGHT, 210, 8, null, "", 0, 100, true);
		profileXPBar.createFilledBar(0xFF222222, 0xFF10B981, true, 0xFF000000);
		add(profileXPBar);
		
		profileXPText = new FlxText(45, 228, 210, "XP: 0%", 12);
		profileXPText.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, CENTER);
		add(profileXPText);

		// --- İSTATİSTİK WIDGET ---
		statsPanelGlow = new FlxSprite(28, 278).makeGraphic(244, 164, 0xFFF59E0B);
		statsPanelGlow.alpha = 0.1;
		add(statsPanelGlow);
		
		statsPanel = new FlxSprite(30, 280).makeGraphic(240, 160, 0xCC000000);
		add(statsPanel);
		
		var statsBorder = new FlxSprite(30, 280).makeGraphic(240, 2, 0xFFF59E0B);
		add(statsBorder);
		
		statsTotalScore = new FlxText(50, 300, 200, "SCORE: 0", 18);
		statsTotalScore.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
		add(statsTotalScore);
		
		statsSongsPlayed = new FlxText(50, 330, 200, "SONGS: 0", 16);
		statsSongsPlayed.setFormat(Paths.font("vcr.ttf"), 16, 0xFFCCCCCC, LEFT);
		add(statsSongsPlayed);
		
		statsAccuracy = new FlxText(50, 360, 200, "ACC: 0%", 16);
		statsAccuracy.setFormat(Paths.font("vcr.ttf"), 16, 0xFF10B981, LEFT);
		add(statsAccuracy);
		
		statsPerfects = new FlxText(50, 390, 200, "FC: 0", 16);
		statsPerfects.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFD700, LEFT);
		add(statsPerfects);
		
		statsPlayTime = new FlxText(50, 420, 200, "TIME: 0", 14);
		statsPlayTime.setFormat(Paths.font("vcr.ttf"), 14, 0xFF888888, LEFT);
		add(statsPlayTime);
		
		loadStats();

		// --- SON OYNANAN WIDGET ---
		lastPlayedPanel = new FlxSprite(30, 460).makeGraphic(240, 120, 0xCC000000);
		add(lastPlayedPanel);
		
		var lastBorder = new FlxSprite(30, 460).makeGraphic(240, 2, 0xFF8B5CF6);
		add(lastBorder);
		
		lastPlayedSong = new FlxText(45, 475, 210, "NOT PLAYED", 18);
		lastPlayedSong.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
		add(lastPlayedSong);
		
		lastPlayedDifficulty = new FlxText(45, 505, 210, "HARD", 14);
		lastPlayedDifficulty.setFormat(Paths.font("vcr.ttf"), 14, 0xFFFF5555, LEFT);
		add(lastPlayedDifficulty);
		
		lastPlayedScore = new FlxText(45, 520, 210, "Score: 0", 12);
		lastPlayedScore.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, LEFT);
		add(lastPlayedScore);
		
		quickPlayButton = new FlxSprite(45, 535).makeGraphic(210, 35, 0xFF8B5CF6);
		add(quickPlayButton);
		
		quickPlayText = new FlxText(45, 542, 210, "REPLAY", 16);
		quickPlayText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		add(quickPlayText);
		
		quickPlayGlow = new FlxSprite(43, 533).makeGraphic(214, 39, 0xFF8B5CF6);
		quickPlayGlow.alpha = 0;
		add(quickPlayGlow);
		
		loadLastPlayed();

		// --- HABERLER VE ALT BAR ---
		newsPanel = new FlxSprite(0, FlxG.height - 110).makeGraphic(FlxG.width, 40, 0x66000000);
		add(newsPanel);
		
		newsTitle = new FlxText(20, FlxG.height - 100, 100, "DUYURU:", 16);
		newsTitle.setFormat(Paths.font("vcr.ttf"), 16, currentTheme, LEFT);
		add(newsTitle);
		
		newsText = new FlxText(130, FlxG.height - 100, FlxG.width - 150, newsItems[0], 16);
		newsText.setFormat(Paths.font("vcr.ttf"), 16, 0xFFEEEEEE, LEFT);
		add(newsText);

		bottomBarGlow = new FlxSprite(0, FlxG.height - 70).makeGraphic(FlxG.width, 75, currentTheme);
		bottomBarGlow.alpha = 0.1;
		add(bottomBarGlow);
		
		bottomBar = new FlxSprite(0, FlxG.height - 70).makeGraphic(FlxG.width, 70, 0xCC000000);
		add(bottomBar);
		
		bottomLine = new FlxSprite(0, FlxG.height - 70).makeGraphic(FlxG.width, 2, currentTheme);
		add(bottomLine);
		
		versionText = new FlxText(FlxG.width - 300, FlxG.height - 45, 280, "PSYCH XQ V3 | " + psychEngineVersion, 16);
		versionText.setFormat(Paths.font("vcr.ttf"), 16, 0xFF888888, RIGHT);
		add(versionText);

		// KAMERA AYARLARI
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		
		camFollow.screenCenter();
		camFollowPos.screenCenter();
		FlxG.camera.follow(camFollowPos, null, 1);

		changeItem();
		
		adminPanel = new AdminPanel();
		add(adminPanel); 
		
		if(needsPlayerName)
			createNameInputScreen();
		else
			FlxG.camera.fade(FlxColor.BLACK, 0.5, true);
		
		super.create();
	}
	
	override function beatHit()
	{
		super.beatHit();
		if (adminPanel != null)
			adminPanel.onBeat();
		
		if(isChangelogOpen && changelogLogo != null)
		{
			var bumpSize = 0.7 + bumpIntensity; 
			changelogLogo.scale.set(bumpSize, bumpSize);
			
			FlxTween.cancelTweensOf(changelogLogo.scale);
			FlxTween.tween(changelogLogo.scale, {x: 0.7, y: 0.7}, 0.3, {ease: FlxEase.quadOut});
		}
	}
	
	function openChangelog()
	{
		isChangelogOpen = true;
		
		// Siyah BG
		changelogBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		changelogBG.alpha = 0;
		changelogBG.scrollFactor.set();
		add(changelogBG);
		
		// 2. PET (assets/shared/images/pet/petlogo.png)
		changelogLogo = new FlxSprite().loadGraphic(Paths.image('pet/petlogo'));
		changelogLogo.antialiasing = ClientPrefs.data.antialiasing;
		changelogLogo.setGraphicSize(Std.int(changelogLogo.width * 0.04)); 
		changelogLogo.updateHitbox();
		changelogLogo.screenCenter(X);
		changelogLogo.y = 30; 
		changelogLogo.alpha = 0;
		changelogLogo.scrollFactor.set();
		add(changelogLogo);
		
		// 3. Sürüm
		changelogTextTitle = new FlxText(0, changelogLogo.y + changelogLogo.height + 20, FlxG.width, "P.E.T - XQ EDITION V3", 32);
		changelogTextTitle.setFormat(Paths.font("vcr.ttf"), 32, 0xFF00E5FF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		changelogTextTitle.screenCenter(X);
		changelogTextTitle.alpha = 0;
		changelogTextTitle.scrollFactor.set();
		add(changelogTextTitle);

		// 4. Güncelleme Yazıları
		var notes = "\n- Arayüz Yenilendi!\n- Profil Sistemi Güncellendi\n- Menü Temaları Eklendi, V1 ve Türkiye. Ayarlar > P.E.T Ayarları'ndan Ayarlanabilir!.\n- 'Mod Desteği Optimize Edildi. Artık Şarkılar Daha Hızlı Yükleniyor.\n- Sürüm, P.E Ultra'nın Temeline Alındı! 0.5\n- Birazcık Bugfix.\n \n- ŞUANKİ SÜRÜM: XQ EDİTİON V3 First-Release\n Durum: Güncel Sürüm\n \nBazı Güncellemeleri Önizleyebilmek için SametGkTe'yi Takipte Kalın!";
		
		changelogTextNotes = new FlxText(0, changelogTextTitle.y + 40, FlxG.width - 200, notes, 22);
		changelogTextNotes.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER);
		changelogTextNotes.screenCenter(X);
		changelogTextNotes.alpha = 0;
		changelogTextNotes.scrollFactor.set();
		add(changelogTextNotes);
		
		// 5. İpucu
		changelogHint = new FlxText(0, FlxG.height - 40, FlxG.width, "Kapatmak için ESC veya ENTER'a basın", 18);
		changelogHint.setFormat(Paths.font("vcr.ttf"), 18, 0xFF888888, CENTER);
		changelogHint.alpha = 0;
		changelogHint.scrollFactor.set();
		add(changelogHint);
		
		FlxTween.tween(changelogBG, {alpha: 0.90}, 0.4);
		FlxTween.tween(changelogLogo, {alpha: 1, y: 50}, 0.5, {ease: FlxEase.backOut, startDelay: 0.1});
		FlxTween.tween(changelogTextTitle, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.2});
		FlxTween.tween(changelogTextNotes, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.3});
		FlxTween.tween(changelogHint, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.4});
	}

	function closeChangelog()
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));
		
		FlxTween.tween(changelogBG, {alpha: 0}, 0.3);
		FlxTween.tween(changelogLogo, {alpha: 0, "scale.x": 0.5, "scale.y": 0.5}, 0.3);
		FlxTween.tween(changelogTextTitle, {alpha: 0}, 0.3);
		FlxTween.tween(changelogTextNotes, {alpha: 0}, 0.3);
		FlxTween.tween(changelogHint, {alpha: 0}, 0.3, {
			onComplete: function(t:FlxTween) {
				remove(changelogBG);
				remove(changelogLogo);
				remove(changelogTextTitle);
				remove(changelogTextNotes);
				remove(changelogHint);
				
				changelogBG.destroy();
				changelogLogo.destroy();
				changelogTextTitle.destroy();
				changelogTextNotes.destroy();
				changelogHint.destroy();
				
				isChangelogOpen = false;
				selectedSomethin = false; 
			}
		});
	}
	
	// İsim Sistemi Oluşum
	function createNameInputScreen()
	{
		// Karartma overlay
		nameInputOverlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xDD000000);
		nameInputOverlay.alpha = 0;
		add(nameInputOverlay);
		
		FlxTween.tween(nameInputOverlay, {alpha: 1}, 0.5);
		
		// Ana İsim
		nameInputBG = new FlxSprite(0, 0).makeGraphic(600, 400, 0xFF0a0a12);
		nameInputBG.screenCenter();
		nameInputBG.y -= 50;
		nameInputBG.alpha = 0;
		nameInputBG.scale.set(0.8, 0.8);
		add(nameInputBG);
		
		var borderGlow = new FlxSprite(nameInputBG.x - 5, nameInputBG.y - 5).makeGraphic(610, 410, currentTheme);
		borderGlow.alpha = 0;
		add(borderGlow);
		
		FlxTween.tween(borderGlow, {alpha: 0.3}, 0.6, {ease: FlxEase.quadOut, startDelay: 0.2});
		FlxTween.tween(nameInputBG, {alpha: 1, "scale.x": 1, "scale.y": 1}, 0.6, {ease: FlxEase.backOut, startDelay: 0.2});
		
		// Başlık
		nameInputTitle = new FlxText(nameInputBG.x, nameInputBG.y + 40, 600, "HOŞGELDİN. XQ..!", 42);
		nameInputTitle.setFormat(Paths.font("vcr.ttf"), 42, currentTheme, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		nameInputTitle.borderSize = 3;
		nameInputTitle.alpha = 0;
		add(nameInputTitle);
		
		FlxTween.tween(nameInputTitle, {alpha: 1, y: nameInputTitle.y + 10}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.4});
		
		// Açıklama metni
		var descText = new FlxText(nameInputBG.x + 50, nameInputBG.y + 110, 500, 
			"Psych Engine Türkiye'ye hoş geldin!\nLütfen oyuncu ismini gir:", 18);
		descText.setFormat(Paths.font("vcr.ttf"), 18, 0xFFCCCCCC, CENTER);
		descText.alpha = 0;
		add(descText);
		
		FlxTween.tween(descText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.5});
		
		// Input box background
		var inputBoxBG = new FlxSprite(nameInputBG.x + 100, nameInputBG.y + 180).makeGraphic(400, 60, 0xFF1a1a25);
		inputBoxBG.alpha = 0;
		add(inputBoxBG);
		
		var inputBoxBorder = new FlxSprite(nameInputBG.x + 100, nameInputBG.y + 180).makeGraphic(400, 60, currentTheme);
		inputBoxBorder.alpha = 0;
		add(inputBoxBorder);
		
		FlxTween.tween(inputBoxBG, {alpha: 1}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.6});
		FlxTween.tween(inputBoxBorder, {alpha: 0.4}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.6});
		
		// Input text box
		nameInputBox = new FlxInputText(nameInputBG.x + 110, nameInputBG.y + 193, 380, "", 28);
		nameInputBox.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER);
		nameInputBox.backgroundColor = 0x00000000;
		nameInputBox.maxLength = 12;
		nameInputBox.alpha = 0;
		add(nameInputBox);
		
		FlxTween.tween(nameInputBox, {alpha: 1}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.7, onComplete: function(t:FlxTween) {
			nameInputBox.hasFocus = true;
		}});
		
		// İpucu
		nameInputHint = new FlxText(nameInputBG.x + 100, nameInputBG.y + 250, 400, 
			"3-12 karakter arası olmalı", 14);
		nameInputHint.setFormat(Paths.font("vcr.ttf"), 14, 0xFF888888, CENTER);
		nameInputHint.alpha = 0;
		add(nameInputHint);
		
		FlxTween.tween(nameInputHint, {alpha: 1}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.8});
		
		// Devam butonu glow
		var buttonGlow = new FlxSprite(nameInputBG.x + 198, nameInputBG.y + 298).makeGraphic(204, 54, currentTheme);
		buttonGlow.alpha = 0;
		add(buttonGlow);
		
		FlxTween.tween(buttonGlow, {alpha: 0.2}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.9});
		
		// Devam butonu
		nameInputButton = new FlxSprite(nameInputBG.x + 200, nameInputBG.y + 300).makeGraphic(200, 50, currentTheme);
		nameInputButton.alpha = 0;
		add(nameInputButton);
		
		FlxTween.tween(nameInputButton, {alpha: 1}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.9});
		
		nameInputButtonText = new FlxText(nameInputBG.x + 200, nameInputBG.y + 313, 200, "DEVAM ET", 22);
		nameInputButtonText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		nameInputButtonText.borderSize = 2;
		nameInputButtonText.alpha = 0;
		add(nameInputButtonText);
		
		FlxTween.tween(nameInputButtonText, {alpha: 1}, 0.4, {ease: FlxEase.quadOut, startDelay: 1.0});
		
		// Ses efekti
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
	}
	
	function submitPlayerName()
	{
		var name = nameInputBox.text.trim();
		
		if(name.length < 3)
		{
			// Hata animasyonu
			FlxG.camera.shake(0.01, 0.2);
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
			
			nameInputHint.text = "İsim çok kısa! (min. 3 karakter)";
			nameInputHint.color = 0xFFFF5555;
			
			FlxTween.cancelTweensOf(nameInputBox);
			FlxTween.tween(nameInputBox, {x: nameInputBox.x + 10}, 0.05, {
				ease: FlxEase.quadInOut,
				onComplete: function(t:FlxTween) {
					FlxTween.tween(nameInputBox, {x: nameInputBox.x - 20}, 0.05, {
						ease: FlxEase.quadInOut,
						onComplete: function(t:FlxTween) {
							FlxTween.tween(nameInputBox, {x: nameInputBox.x + 10}, 0.05, {ease: FlxEase.quadInOut});
						}
					});
				}
			});
			return;
		}
		
		// İsmi kaydet
		FlxG.save.data.playerName = name;
		FlxG.save.flush();
		
		FlxG.sound.play(Paths.sound('confirmMenu'));
		
		// Başarılı
		nameInputHint.text = "Hoş geldin, " + name + "!";
		nameInputHint.color = 0xFF10B981;
		
		FlxTween.tween(nameInputOverlay, {alpha: 0}, 0.5, {ease: FlxEase.quadIn, startDelay: 0.5});
		FlxTween.tween(nameInputBG, {alpha: 0, "scale.x": 0.8, "scale.y": 0.8}, 0.5, {ease: FlxEase.backIn, startDelay: 0.5});
		FlxTween.tween(nameInputTitle, {alpha: 0, y: nameInputTitle.y - 20}, 0.4, {ease: FlxEase.quadIn, startDelay: 0.5});
		FlxTween.tween(nameInputBox, {alpha: 0}, 0.4, {ease: FlxEase.quadIn, startDelay: 0.5});
		FlxTween.tween(nameInputButton, {alpha: 0}, 0.4, {ease: FlxEase.quadIn, startDelay: 0.5});
		FlxTween.tween(nameInputButtonText, {alpha: 0}, 0.4, {ease: FlxEase.quadIn, startDelay: 0.5});
		FlxTween.tween(nameInputHint, {alpha: 0}, 0.4, {ease: FlxEase.quadIn, startDelay: 0.6, onComplete: function(t:FlxTween) {
			needsPlayerName = false;
			profileName.text = name;
			
			FlxG.camera.fade(FlxColor.BLACK, 0.5, true);
		}});
	}
	
	function createParticles()
	{
		for(i in 0...40)
		{
			var p = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			var size = Std.int(FlxG.random.float(1, 4));
			p.makeGraphic(size, size, FlxColor.WHITE);
			p.alpha = FlxG.random.float(0.1, 0.4);
			p.velocity.y = FlxG.random.float(-15, -5);
			p.velocity.x = FlxG.random.float(-3, 3);
			add(p);
			particles.push(p);
		}
	}
	
	function createFloatingOrbs()
	{
		for(i in 0...8)
		{
			var orb = new FlxSprite(FlxG.random.float(400, FlxG.width - 50), FlxG.random.float(100, FlxG.height - 100));
			orb.makeGraphic(Std.int(FlxG.random.float(20, 40)), Std.int(FlxG.random.float(20, 40)), currentTheme);
			orb.alpha = FlxG.random.float(0.05, 0.15);
			add(orb);
			floatingOrbs.push(orb);
		}
	}
	
	function loadStats()
	{
		var totalScore:Int = 0;
		var songsPlayed:Int = 0;
		var totalAccuracy:Float = 0;
		var fcCount:Int = 0;
		
		// Tüm şarkıları tara
		for(week in WeekData.weeksList)
		{
			var weekData = WeekData.weeksLoaded.get(week);
			if(weekData == null) continue;
			
			for(song in weekData.songs)
			{
				for(diff in 0...3) // Easy, Normal, Hard
				{
					var score = Highscore.getScore(song[0], diff);
					if(score > 0)
					{
						totalScore += score;
						songsPlayed++;
						
						// Accuracy hesapla (eğer kaydedilmişse)
						var acc = Highscore.getRating(song[0], diff);
						if(acc > 0) totalAccuracy += acc;
						
						// FC kontrolü
						if(Highscore.getRating(song[0], diff) >= 100)
							fcCount++;
					}
				}
			}
		}
		
		// Kayıtlı istatistikleri güncelle
		FlxG.save.data.totalScore = totalScore;
		FlxG.save.data.songsPlayed = songsPlayed;
		FlxG.save.data.fcCount = fcCount;
		FlxG.save.flush();
		
		// UI'ı güncelle
		statsTotalScore.text = formatNumber(totalScore);
		statsSongsPlayed.text = songsPlayed + " şarkı";
		
		var avgAcc = songsPlayed > 0 ? totalAccuracy / songsPlayed : 0;
		statsAccuracy.text = "%" + FlxMath.roundDecimal(avgAcc, 2);
		
		// Renk kodlaması
		if(avgAcc >= 95)
			statsAccuracy.color = 0xFF10B981; // Yeşil
		else if(avgAcc >= 85)
			statsAccuracy.color = 0xFFF59E0B; // Sarı
		else
			statsAccuracy.color = 0xFFFF5555; // Kırmızı
		
		statsPerfects.text = "FC: " + fcCount;
		
		// Oyun süresi (basit hesaplama: her şarkı ~3 dakika)
		var totalMinutes = songsPlayed * 3;
		var hours = Math.floor(totalMinutes / 60);
		var minutes = totalMinutes % 60;
		
		if(hours > 0)
			statsPlayTime.text = hours + " saat " + minutes + " dk";
		else
			statsPlayTime.text = minutes + " dakika";
		
		var level = Math.floor(totalScore / 50000) + 1;
		profileLevel.text = "Seviye: " + level;
		
		var xpProgress = (totalScore % 50000) / 50000 * 100;
		profileXPBar.value = xpProgress;
		profileXPText.text = Std.int(xpProgress) + "% → Lv." + (level + 1);
		
		// Rank sistemi
		updatePlayerRank(totalScore);
	}
	
	function updatePlayerRank(score:Int)
	{
		if(score >= 1000000)
		{
			profileRank.text = "ELMAS";
			profileRank.color = 0xFFB9F2FF;
			profileRankIcon.text = "💎";
		}
		else if(score >= 500000)
		{
			profileRank.text = "PLATİN";
			profileRank.color = 0xFFE5E4E2;
			profileRankIcon.text = "⭐";
		}
		else if(score >= 250000)
		{
			profileRank.text = "ALTIN";
			profileRank.color = 0xFFFFD700;
			profileRankIcon.text = "🥇";
		}
		else if(score >= 100000)
		{
			profileRank.text = "GÜMÜŞ";
			profileRank.color = 0xFFC0C0C0;
			profileRankIcon.text = "🥈";
		}
		else
		{
			profileRank.text = "BRONZ";
			profileRank.color = 0xFFCD7F32;
			profileRankIcon.text = "🥉";
		}
	}
	
	function loadLastPlayed()
	{
		// Kayıtlı bir şarkı var mı kontrol et
		if(FlxG.save.data.lastPlayedSong != null && FlxG.save.data.lastPlayedSong != "")
		{
			lastPlayedSong.text = FlxG.save.data.lastPlayedSong;
			
			if(FlxG.save.data.lastPlayedScore != null)
				lastPlayedScore.text = "Skor: " + formatNumber(FlxG.save.data.lastPlayedScore);
			
			if(FlxG.save.data.lastPlayedDifficulty != null)
			{
				var diff:Int = FlxG.save.data.lastPlayedDifficulty;
				var diffNames = ["EASY", "NORMAL", "HARD"];
				var diffColors = [0xFF10B981, 0xFFF59E0B, 0xFFFF5555];
				
				// Eğer özel bir zorluk seviyesi oynandıysa çökmemesi için güvenlik kontrolü
				if(diff >= 0 && diff < diffNames.length) {
					lastPlayedDifficulty.text = diffNames[diff];
					lastPlayedDifficulty.color = diffColors[diff];
				} else {
					lastPlayedDifficulty.text = "CUSTOM";
					lastPlayedDifficulty.color = 0xFF8B5CF6;
				}
			}
		}
		else
		{
			// Daha önce oynanmamışsa
			lastPlayedSong.text = "Henüz oynanmadı";
			lastPlayedDifficulty.text = "-";
			lastPlayedScore.text = "Biraz Oyun Vakti!";
			
			quickPlayText.text = "YOK";
			quickPlayText.color = 0xFF555555;
			quickPlayButton.color = 0xFF222222;
		}
	}
	
	function playLastSong()
	{
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));

		var songName:String = FlxG.save.data.lastPlayedSong;
		var difficulty:Int = FlxG.save.data.lastPlayedDifficulty != null ? FlxG.save.data.lastPlayedDifficulty : 1;

		var songPath = Paths.formatToSongPath(songName);
		
		var pooped:String = Highscore.formatSong(songPath, difficulty);

		try 
		{
			// Şarkı datasını yükle
			PlayState.SONG = Song.loadFromJson(pooped, songPath);
			PlayState.isStoryMode = false; // Serbest oyun modundaymış gibi aç
			PlayState.storyDifficulty = difficulty;

			// Oyna butonuna titreme (flicker) efekti ver ve sahneye geç
			FlxFlicker.flicker(quickPlayButton, 1, 0.06, true, false, function(flick:FlxFlicker)
			{
				LoadingState.loadAndSwitchState(new PlayState());
			});

			// Diğer UI elemanlarını animasyonla ekran dışına at
			FlxTween.tween(lastPlayedPanel, {x: FlxG.width + 500}, 0.5, {ease: FlxEase.backIn});
			FlxTween.tween(profilePanel, {x: FlxG.width + 500}, 0.5, {ease: FlxEase.backIn});
			FlxTween.tween(statsPanel, {x: FlxG.width + 500}, 0.5, {ease: FlxEase.backIn});
		} 
		catch(e:Dynamic) 
		{
			// Eğer şarkı modu silinmişse veya JSON bulunamazsa çökmesin
			trace('HATA: Şarkı yüklenemedi! ' + e);
			selectedSomethin = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			
			lastPlayedSong.text = "ŞARKI BULUNAMADI!";
			lastPlayedSong.color = 0xFFFF5555;
		}
	}
	
	function formatNumber(num:Int):String
	{
		var str = Std.string(num);
		var result = "";
		var count = 0;
		for(i in 0...str.length)
		{
			if(count > 0 && count % 3 == 0)
				result = "." + result;
			result = str.charAt(str.length - 1 - i) + result;
			count++;
		}
		return result;
	}
	
	function updateTimeAndGreeting()
	{
		var now = Date.now();
		var hour = now.getHours();
		var minute = now.getMinutes();
		
		clockText.text = StringTools.lpad(Std.string(hour), "0", 2) + ":" + StringTools.lpad(Std.string(minute), "0", 2);
		
		var days = ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"];
		var months = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"];
		dateText.text = days[now.getDay()] + ", " + now.getDate() + " " + months[now.getMonth()];
		
		// Karşılama mesajı (isimle birlikte)
		var greeting = "";
		if(hour >= 5 && hour < 12)
			greeting = "Günaydın";
		else if(hour >= 12 && hour < 18)
			greeting = "İyi günler";
		else if(hour >= 18 && hour < 22)
			greeting = "İyi akşamlar";
		else
			greeting = "İyi geceler";
		
		if(FlxG.save.data.playerName != null)
			greetingText.text = greeting + ", " + FlxG.save.data.playerName + "!";
		else
			greetingText.text = greeting + "!";
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.F2)
		{
			if (adminPanel.isOpen)
				adminPanel.closePanel();
			else
				adminPanel.openPanel();
		}
		
		if (adminPanel.isOpen)
		{
			adminPanel.handleInput(controls);
			adminPanel.handleUpdate(elapsed);
			if (controls.BACK)
				adminPanel.closePanel();
			return; 
		}
		
		ambientPulse += elapsed;
		breathingEffect += elapsed * 2;

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * elapsed;

		var lerpVal:Float = FlxMath.bound(elapsed * 9, 0, 1);
		camFollowPos.setPosition(
			FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal),
			FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
		);
		
		updateParticles(elapsed);
		updateNews(elapsed);
		
		if(Math.floor(ambientPulse) % 30 == 0 && Math.floor(ambientPulse) > 0)
			updateTimeAndGreeting();
		
		if(needsPlayerName)
		{
			if(FlxG.keys.justPressed.ENTER) submitPlayerName();
			
			if(FlxG.mouse.overlaps(nameInputButton)) {
				nameInputButton.scale.set(1.05, 1.05);
				nameInputButtonText.scale.set(1.05, 1.05);
			} else {
				nameInputButton.scale.set(1, 1);
				nameInputButtonText.scale.set(1, 1);
			}
			return; 
		}

		if (isChangelogOpen)
		{
			if (controls.BACK || controls.ACCEPT) closeChangelog();
			return; 
		}

		if (!selectedSomethin)
		{
			handleCheats(elapsed);

			if (controls.UI_LEFT_P) changeItem(-1);
			if (controls.UI_RIGHT_P) changeItem(1);
			
			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				selectEntry();
			}
			else if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			
			if (FlxG.save.data.lastPlayedSong != null && FlxG.save.data.lastPlayedSong != "")
			{
				if (FlxG.mouse.overlaps(quickPlayButton))
				{
					quickPlayGlow.alpha = 0.6 + Math.sin(breathingEffect * 4) * 0.4;
					quickPlayButton.scale.set(1.05, 1.05);
					if (FlxG.mouse.justPressed) playLastSong();
				}
				else
				{
					quickPlayGlow.alpha = 0;
					quickPlayButton.scale.set(1, 1);
				}
			}
		}

		updateCardPositions(elapsed, lerpVal);
		updateParallax(elapsed, lerpVal);
		updateFloatingOrbs(elapsed);
		
		if(profilePanelGlow != null) profilePanelGlow.alpha = 0.1 + Math.sin(ambientPulse * 2) * 0.05;
		if(statsPanelGlow != null) statsPanelGlow.alpha = 0.1 + Math.sin(ambientPulse * 2 + 1) * 0.05;
		if(topBarGlow != null) topBarGlow.alpha = 0.15 + Math.sin(ambientPulse) * 0.05;
		if(bottomBarGlow != null) bottomBarGlow.alpha = 0.1 + Math.sin(ambientPulse + 2) * 0.05;
	}

	function updateCardPositions(elapsed:Float, lerpVal:Float)
	{
		var centerX = FlxG.width / 2;
		var spacing = 240;
		
		menuCards.forEach(function(card:FlxSpriteGroup)
		{
			var targetX = centerX - 100 + (card.ID - curSelected) * spacing;
			var targetY = FlxG.height / 2 - 140;
			
			// Seçili kartı biraz öne çıkar ve büyüt
			if(card.ID == curSelected)
			{
				targetY -= 20;
				card.scale.set(FlxMath.lerp(card.scale.x, 1.1, lerpVal), FlxMath.lerp(card.scale.y, 1.1, lerpVal));
				card.alpha = FlxMath.lerp(card.alpha, 1, lerpVal);
				cardGlows[card.ID].alpha = 0.3 + Math.sin(breathingEffect * 2) * 0.1;
			}
			else
			{
				card.scale.set(FlxMath.lerp(card.scale.x, 0.9, lerpVal), FlxMath.lerp(card.scale.y, 0.9, lerpVal));
				card.alpha = FlxMath.lerp(card.alpha, 0.4, lerpVal);
				cardGlows[card.ID].alpha = 0;
			}
			
			card.x = FlxMath.lerp(card.x, targetX, lerpVal);
			card.y = FlxMath.lerp(card.y, targetY, lerpVal);
		});
	}
	
	function updateParallax(elapsed:Float, lerpVal:Float)
	{
		var mouseOffsetX = (FlxG.mouse.screenX - FlxG.width / 2) / FlxG.width;
		var mouseOffsetY = (FlxG.mouse.screenY - FlxG.height / 2) / FlxG.height;
		
		bgLayer1.x = FlxMath.lerp(bgLayer1.x, -100 - mouseOffsetX * 30, lerpVal);
		bgLayer1.y = FlxMath.lerp(bgLayer1.y, -100 - mouseOffsetY * 30, lerpVal);
		
		bgLayer2.x = FlxMath.lerp(bgLayer2.x, -50 - mouseOffsetX * 60, lerpVal);
		bgLayer2.y = FlxMath.lerp(bgLayer2.y, -50 - mouseOffsetY * 60, lerpVal);
	}
	
	function updateParticles(elapsed:Float)
	{
		for(p in particles)
		{
			if(p.y < -10)
			{
				p.y = FlxG.height + 10;
				p.x = FlxG.random.float(0, FlxG.width);
			}
			p.alpha = 0.1 + Math.sin(ambientPulse + p.x * 0.01) * 0.1;
		}
	}
	
	function updateNews(elapsed:Float)
	{
		newsTimer += elapsed;
		if(newsTimer > 5)
		{
			newsTimer = 0;
			newsIndex = (newsIndex + 1) % newsItems.length;
			
			FlxTween.tween(newsText, {alpha: 0}, 0.3, {
				onComplete: function(twn:FlxTween) {
					newsText.text = newsItems[newsIndex];
					FlxTween.tween(newsText, {alpha: 1}, 0.3);
				}
			});
		}
	}

	function updateFloatingOrbs(elapsed:Float)
	{
		for(i in 0...floatingOrbs.length)
		{
			var orb = floatingOrbs[i];
			orb.y += Math.sin(ambientPulse + i) * 0.5;
			orb.x += Math.cos(ambientPulse * 0.5 + i) * 0.3;
			orb.alpha = 0.05 + Math.sin(ambientPulse + i * 0.5) * 0.05;
			
			if(orb.x < -100) orb.x = FlxG.width + 100;
			if(orb.x > FlxG.width + 100) orb.x = -100;
			if(orb.y < -100) orb.y = FlxG.height + 100;
			if(orb.y > FlxG.height + 100) orb.y = -100;
		}
	}
	
	function changeItem(change:Int = 0)
	{
		curSelected += change;
		if (curSelected >= optionShit.length) curSelected = 0;
		if (curSelected < 0) curSelected = optionShit.length - 1;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var choice:String = optionShit[curSelected];
		var newColor:FlxColor = menuColorMap.exists(choice) ? menuColorMap.get(choice) : 0xFF333333;
		
		currentTheme = newColor;
		
		FlxTween.color(bgLayer2, 0.5, bgLayer2.color, newColor);
		FlxTween.color(topBarLine, 0.3, topBarLine.color, newColor);
		FlxTween.color(topBarGlow, 0.3, topBarGlow.color, newColor);
		FlxTween.color(bottomLine, 0.3, bottomLine.color, newColor);
		FlxTween.color(descriptionTitle, 0.3, descriptionTitle.color, newColor);
		
		descriptionTitle.text = menuTitles.get(choice);
		descriptionText.text = menuDescriptions.get(choice);
		
		descriptionText.alpha = 0;
		descriptionText.y = 170;
		FlxTween.tween(descriptionText, {alpha: 1, y: 160}, 0.3, {ease: FlxEase.quadOut});
		
		// Cam follow update
		camFollow.x = FlxG.width / 2 + (curSelected - (optionShit.length / 2)) * 50;
	}

	function selectEntry()
	{
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		
		if (optionShit[curSelected] == 'guncelleme')
		{
			openChangelog();
			return; 
		}

		menuCards.forEach(function(card:FlxSpriteGroup)
		{
			if (curSelected != card.ID)
			{
				FlxTween.tween(card, {alpha: 0, y: FlxG.height + 200}, 0.6, {ease: FlxEase.backIn});
			}
			else
			{
				FlxFlicker.flicker(card, 1, 0.06, false, false, function(flick:FlxFlicker)
				{
					var daChoice:String = optionShit[curSelected];
					switch (daChoice)
					{
						case 'hikaye_modu':  ThemeManager.switchToStoryMenu();
						case 'serbest_oyun': ThemeManager.switchToFreeplay();
						case 'basarimlar':   ThemeManager.switchToAchievements();
						case 'yapimcilar':   ThemeManager.switchToCredits();
						case 'ayarlar':      ThemeManager.switchToOptions();
						#if MODS_ALLOWED
						case 'modlar':       ThemeManager.switchToMods();
						#end
					}
				});
			}
		});

		// UI çıkış animasyonları
		FlxTween.tween(topBar, {y: -100}, 0.5, {ease: FlxEase.backIn});
		FlxTween.tween(bottomBar, {y: FlxG.height + 100}, 0.5, {ease: FlxEase.backIn});
		FlxTween.tween(profilePanel, {x: -300}, 0.5, {ease: FlxEase.backIn});
		FlxTween.tween(statsPanel, {x: -300}, 0.5, {ease: FlxEase.backIn, startDelay: 0.05});
		FlxTween.tween(lastPlayedPanel, {x: -300}, 0.5, {ease: FlxEase.backIn, startDelay: 0.1});
		FlxTween.tween(newsPanel, {y: FlxG.height + 100}, 0.5, {ease: FlxEase.backIn});
	}

	function handleCheats(elapsed:Float)
	{
		var upNow = controls.UI_UP_P;
		var rightNow = controls.UI_RIGHT_P;
		var leftNow = controls.UI_LEFT_P;

		if (upNow && !prevUp) { cheatSequence.push(0); cheatLastInputTime = 0; }
		if (rightNow && !prevRight) { cheatSequence.push(3); cheatLastInputTime = 0; }
		if (leftNow && !prevLeft) { cheatSequence.push(2); cheatLastInputTime = 0; }

		prevUp = upNow; prevRight = rightNow; prevLeft = leftNow;
		cheatLastInputTime += elapsed;
		if (cheatLastInputTime > cheatTimeout) cheatSequence = [];

		if (cheatSequence.length > cheatPattern.length) cheatSequence.shift();
		if (cheatSequence.toString() == cheatPattern.toString()) {
			selectedSomethin = true;
			FlxG.sound.play(Paths.sound('secret'));
			MusicBeatState.switchState(new CodeMenuState());
		}
	}
}