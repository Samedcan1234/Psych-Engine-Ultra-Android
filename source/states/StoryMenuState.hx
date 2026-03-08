package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import flixel.group.FlxGroup;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.math.FlxMath;

import objects.MenuItem;
import objects.MenuCharacter;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import backend.StageData;

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	// ═══════════════════════════════════════════════════════
	// 🎮 ORIJINAL SİSTEM DEĞİŞKENLERİ (Korundu)
	// ═══════════════════════════════════════════════════════
	var scoreText:FlxText;
	private static var lastDifficultyName:String = '';
	var curDifficulty:Int = 1;
	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;
	private static var curWeek:Int = 0;
	var txtTracklist:FlxText;
	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var grpLocks:FlxTypedGroup<FlxSprite>;
	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var loadedWeeks:Array<WeekData> = [];
	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	// ═══════════════════════════════════════════════════════
	// 🌌 MODERN UI — ARKA PLAN
	// ═══════════════════════════════════════════════════════
	var bgBase:FlxSprite;
	var bgGradient:FlxSprite;
	var bgGradientDynamic:FlxSprite; // Haftaya göre renk değişir
	var gridBG:FlxBackdrop;
	var bgOrbs:Array<FlxSprite> = [];
	var floatingShapes:Array<FlxSprite> = [];
	var bgVignette:FlxSprite;

	// ═══════════════════════════════════════════════════════
	// 🔝 HEADER
	// ═══════════════════════════════════════════════════════
	var headerPanel:FlxSprite;
	var headerGlow:FlxSprite;
	var headerTitle:FlxText;
	var headerSubtitle:FlxText;
	var headerBreadcrumb:FlxText;

	// ═══════════════════════════════════════════════════════
	// 📋 SOL PANEL — HAFTA LİSTESİ
	// ═══════════════════════════════════════════════════════
	var leftPanel:FlxSprite;
	var leftPanelGlow:FlxSprite;
	var leftPanelBorder:FlxSprite;
	var weekListGroup:FlxTypedGroup<WeekCard>;
	var selectionBar:FlxSprite;
	var selectionBarGlow:FlxSprite;

	// ═══════════════════════════════════════════════════════
	// 🎭 ORTA ALAN — KARAKTER VİTRİNİ
	// ═══════════════════════════════════════════════════════
	var charPanel:FlxSprite;
	var charPanelGlow:FlxSprite;
	var charPanelBorder:FlxSprite;
	var charStageBG:FlxSprite; // Hafta arka planı buraya
	var charStageOverlay:FlxSprite;

	// ═══════════════════════════════════════════════════════
	// 📊 SAĞ PANEL — HAFTA BİLGİSİ
	// ═══════════════════════════════════════════════════════
	var infoPanel:FlxSprite;
	var infoPanelGlow:FlxSprite;
	var infoPanelBorder:FlxSprite;
	var weekNameText:FlxText;
	var weekNameGlow:FlxSprite;
	var scorePanel:FlxSprite;
	var scorePanelBorder:FlxSprite;
	var scoreValueText:FlxText;
	var scoreLabel:FlxText;
	var diffPanel:FlxSprite;
	var diffPanelGlow:FlxSprite;
	var tracklistPanel:FlxSprite;
	var tracklistTitle:FlxText;
	var tracklistLabel:FlxText;
	var lockedWarning:FlxSprite;
	var lockedWarningText:FlxText;

	// ═══════════════════════════════════════════════════════
	// 🎮 KONTROL İPUÇLARI
	// ═══════════════════════════════════════════════════════
	var controlHintsPanel:FlxSprite;
	var controlHintsText:FlxText;

	// ═══════════════════════════════════════════════════════
	// 🎨 ANİMASYON TİMERLARI
	// ═══════════════════════════════════════════════════════
	var animTimer:Float  = 0;
	var pulseTimer:Float = 0;
	var waveTimer:Float  = 0;
	var floatTimer:Float = 0;
	var glowTimer:Float  = 0;
	var cameraTween:FlxTween = null;

	// Tema renkleri (hafta index'ine göre)
	var weekColors:Array<FlxColor> = [
		0xFF4A90E2, 0xFF8B5CF6, 0xFF10B981,
		0xFFF59E0B, 0xFFEC4899, 0xFF00E5FF,
		0xFFFF6B35, 0xFF64748B
	];
	var currentWeekColor:FlxColor = 0xFF4A90E2;

	// Layout sabitleri
	static inline var HEADER_H:Int   = 100;
	static inline var LEFT_W:Int     = 300;
	static inline var CHAR_W:Int     = 540;
	static inline var RIGHT_W:Int    = 380;
	static inline var CARD_H:Int     = 76;
	static inline var CARD_GAP:Int   = 8;

	// ═══════════════════════════════════════════════════════
	// 🏗️ CREATE
	// ═══════════════════════════════════════════════════════
	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;
		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Hikaye Modu - XQ Edition", null);
		#end

		if (WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState(
				"NO WEEKS ADDED FOR STORY MODE\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())
			));
			return;
		}

		if (curWeek >= WeekData.weeksList.length) curWeek = 0;

		// ── Hafta verilerini yükle ────────────────────────────
		loadWeekData();

		// ── Arayüz oluştur ────────────────────────────────────
		createBackground();
		createHeader();
		createCharacterPanel();
		createLeftPanel();
		createInfoPanel();
		createDifficultySelectors();
		createControlHints();

		// ── İlk seçim ─────────────────────────────────────────
		currentWeekColor = weekColors[curWeek % weekColors.length];
		changeWeek();
		changeDifficulty();

		// ── Giriş animasyonu ──────────────────────────────────
		playEntranceAnimation();

		super.create();
	}

	// ═══════════════════════════════════════════════════════
	// 📦 VERİ YÜKLEME
	// ═══════════════════════════════════════════════════════
	function loadWeekData()
	{
		grpWeekText       = new FlxTypedGroup<MenuItem>();
		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		grpLocks          = new FlxTypedGroup<FlxSprite>();

		// bgSprite (orijinal hafta arka planı — karakter panelinde kullanılacak)
		bgSprite = new FlxSprite(LEFT_W, HEADER_H);
		bgSprite.alpha = 0;

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

		var num:Int = 0;
		var itemTargetY:Float = 0;
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
			if (!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				loadedWeeks.push(weekFile);
				WeekData.setDirectoryFromWeek(weekFile);

				// Orijinal MenuItem (gizlenmiş — hafta kartları için WeekCard kullanacağız)
				var weekThing:MenuItem = new MenuItem(0, 0, WeekData.weeksList[i]);
				weekThing.ID = num;
				weekThing.targetY = itemTargetY;
				itemTargetY += Math.max(weekThing.height, 110) + 10;
				weekThing.alpha = 0; // Gizli — WeekCard kullanıyoruz
				weekThing.visible = false;
				grpWeekText.add(weekThing);

				if (isLocked)
				{
					var lock:FlxSprite = new FlxSprite(0, 0);
					lock.antialiasing = ClientPrefs.data.antialiasing;
					lock.frames = ui_tex;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.ID = i;
					lock.alpha = 0;
					lock.visible = false;
					grpLocks.add(lock);
				}
				num++;
			}
		}

		// Karakterler
		WeekData.setDirectoryFromWeek(loadedWeeks[0]);
		var charArray:Array<String> = loadedWeeks[0].weekCharacters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((CHAR_W * 0.25) * (1 + char) - 60 + LEFT_W, charArray[char]);
			weekCharacterThing.y = HEADER_H + 60;
			grpWeekCharacters.add(weekCharacterThing);
		}
	}

	// ═══════════════════════════════════════════════════════
	// 🌌 ARKA PLAN
	// ═══════════════════════════════════════════════════════
	function createBackground()
	{
		bgBase = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF080812);
		bgBase.scrollFactor.set(0, 0);
		add(bgBase);

		bgGradient = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[0xFF1a1a2e, 0xFF16213e, 0xFF0a0f20, 0xFF080812],
			1, 135
		);
		bgGradient.scrollFactor.set(0, 0);
		bgGradient.alpha = 0.9;
		add(bgGradient);

		// Dinamik gradient (hafta rengine göre değişir)
		bgGradientDynamic = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[currentWeekColor, 0x00000000],
			1, 135
		);
		bgGradientDynamic.scrollFactor.set(0, 0);
		bgGradientDynamic.alpha = 0.12;
		bgGradientDynamic.blend = ADD;
		add(bgGradientDynamic);

		gridBG = new FlxBackdrop(FlxGridOverlay.createGrid(40, 40, 80, 80, true, 0x0AFFFFFF, 0x0));
		gridBG.velocity.set(8, 5);
		gridBG.alpha = 0.1;
		gridBG.scrollFactor.set(0, 0);
		add(gridBG);

		// bgOrbs (OptionsState tarzı)
		for (i in 0...8)
		{
			var orb = new FlxSprite(
				FlxG.random.float(LEFT_W, FlxG.width),
				FlxG.random.float(HEADER_H, FlxG.height - 50)
			);
			orb.makeGraphic(
				Std.int(70 + FlxG.random.float(0, 90)),
				Std.int(70 + FlxG.random.float(0, 90)),
				currentWeekColor
			);
			orb.blend = ADD;
			orb.alpha = 0.04 + FlxG.random.float(0, 0.04);
			orb.scrollFactor.set(0.02, 0.02);
			orb.ID = i;
			add(orb);
			bgOrbs.push(orb);
		}

		// Floating shapes
		for (i in 0...10)
		{
			var shape = new FlxSprite(
				FlxG.random.float(LEFT_W, FlxG.width),
				FlxG.random.float(HEADER_H, FlxG.height)
			);
			shape.makeGraphic(
				Std.int(12 + FlxG.random.float(0, 22)),
				Std.int(12 + FlxG.random.float(0, 22)),
				FlxColor.WHITE
			);
			shape.blend = ADD;
			shape.alpha = 0.04 + FlxG.random.float(0, 0.06);
			shape.scrollFactor.set(0.03 + FlxG.random.float(0, 0.04), 0.03 + FlxG.random.float(0, 0.04));
			shape.ID = i;
			add(shape);
			floatingShapes.push(shape);
		}

		bgVignette = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[0x00000000, 0x00000000, 0x55000000],
			1, 0, true
		);
		bgVignette.scrollFactor.set(0, 0);
		add(bgVignette);
	}

	// ═══════════════════════════════════════════════════════
	// 🔝 HEADER
	// ═══════════════════════════════════════════════════════
	function createHeader()
	{
		headerPanel = new FlxSprite(0, -HEADER_H).makeGraphic(FlxG.width, HEADER_H, 0xEE000000);
		headerPanel.scrollFactor.set(0, 0);
		add(headerPanel);

		headerGlow = new FlxSprite(0, HEADER_H - 4).makeGraphic(FlxG.width, 4, currentWeekColor);
		headerGlow.blend = ADD;
		headerGlow.alpha = 0.7;
		headerGlow.scrollFactor.set(0, 0);
		add(headerGlow);

		var titleIcon = new FlxText(30, 16, 50, "📖", 38);
		titleIcon.scrollFactor.set(0, 0);
		add(titleIcon);

		headerTitle = new FlxText(82, 16, FlxG.width - 300, "HİKAYE MODU", 40);
		headerTitle.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF001A40);
		headerTitle.borderSize = 3;
		headerTitle.scrollFactor.set(0, 0);
		headerTitle.alpha = 0;
		add(headerTitle);

		headerSubtitle = new FlxText(82, 60, FlxG.width - 300, "Tüm haftaları tamamla ve rakipleri alt et!", 17);
		headerSubtitle.setFormat(Paths.font("vcr.ttf"), 17, 0xFFBBBBBB, LEFT);
		headerSubtitle.scrollFactor.set(0, 0);
		headerSubtitle.alpha = 0;
		add(headerSubtitle);

		headerBreadcrumb = new FlxText(82, 82, FlxG.width - 300, "Ana Menü > Hikaye Modu", 12);
		headerBreadcrumb.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, LEFT);
		headerBreadcrumb.scrollFactor.set(0, 0);
		headerBreadcrumb.alpha = 0;
		add(headerBreadcrumb);

		// Skor (sağ üst header içinde)
		scoreLabel = new FlxText(FlxG.width - 320, 18, 300, "HAFTA SKORU", 14);
		scoreLabel.setFormat(Paths.font("vcr.ttf"), 14, 0xFF888888, RIGHT);
		scoreLabel.scrollFactor.set(0, 0);
		add(scoreLabel);

		scoreText = new FlxText(FlxG.width - 320, 36, 300, "0", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.borderSize = 2;
		scoreText.scrollFactor.set(0, 0);
		add(scoreText);
	}

	// ═══════════════════════════════════════════════════════
	// 🎭 KARAKTER PANELİ (Orta)
	// ═══════════════════════════════════════════════════════
	function createCharacterPanel()
	{
		// Sahne arka planı (bgSprite buraya bağlanacak)
		charPanelGlow = new FlxSprite(LEFT_W - 4, HEADER_H - 4).makeGraphic(CHAR_W + 8, FlxG.height - HEADER_H + 4, currentWeekColor);
		charPanelGlow.alpha = 0.07;
		charPanelGlow.scrollFactor.set(0, 0);
		add(charPanelGlow);

		charPanel = FlxGradient.createGradientFlxSprite(
			CHAR_W, FlxG.height - HEADER_H,
			[0xBB0a0f1a, 0xCC050810],
			1, 0
		);
		charPanel.x = LEFT_W;
		charPanel.y = HEADER_H;
		charPanel.scrollFactor.set(0, 0);
		add(charPanel);

		// Hafta arka planı
		add(bgSprite);

		// Karakter alanı üstüne gradient overlay
		charStageOverlay = FlxGradient.createGradientFlxSprite(
			CHAR_W, FlxG.height - HEADER_H,
			[0x00000000, 0x00000000, 0x88000000],
			1, 90
		);
		charStageOverlay.x = LEFT_W;
		charStageOverlay.y = HEADER_H;
		charStageOverlay.scrollFactor.set(0, 0);
		add(charStageOverlay);

		// Sol ve sağ kenar çizgileri
		charPanelBorder = new FlxSprite(LEFT_W - 3, HEADER_H).makeGraphic(3, FlxG.height - HEADER_H, currentWeekColor);
		charPanelBorder.alpha = 0.5;
		charPanelBorder.scrollFactor.set(0, 0);
		add(charPanelBorder);

		var charRightBorder = new FlxSprite(LEFT_W + CHAR_W, HEADER_H).makeGraphic(3, FlxG.height - HEADER_H, currentWeekColor);
		charRightBorder.alpha = 0.3;
		charRightBorder.scrollFactor.set(0, 0);
		add(charRightBorder);

		// Karakterler
		add(grpWeekCharacters);

		// Kilit uyarısı
		lockedWarning = new FlxSprite(LEFT_W + 20, HEADER_H + 20).makeGraphic(CHAR_W - 40, 48, 0xAAFF4444);
		lockedWarning.scrollFactor.set(0, 0);
		lockedWarning.visible = false;
		add(lockedWarning);

		lockedWarningText = new FlxText(LEFT_W + 20, HEADER_H + 28, CHAR_W - 40, "🔒 Bu hafta kilitli! Önceki haftayı tamamla.", 18);
		lockedWarningText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER);
		lockedWarningText.scrollFactor.set(0, 0);
		lockedWarningText.visible = false;
		add(lockedWarningText);
	}

	// ═══════════════════════════════════════════════════════
	// 📋 SOL PANEL — HAFTA KARTLARI
	// ═══════════════════════════════════════════════════════
	function createLeftPanel()
	{
		leftPanelGlow = new FlxSprite(0, HEADER_H).makeGraphic(LEFT_W + 4, FlxG.height - HEADER_H, currentWeekColor);
		leftPanelGlow.alpha = 0.08;
		leftPanelGlow.scrollFactor.set(0, 0);
		add(leftPanelGlow);

		leftPanel = FlxGradient.createGradientFlxSprite(
			LEFT_W, FlxG.height - HEADER_H,
			[0xDD0a0a12, 0xEE050508, 0xFF020204],
			1, 0
		);
		leftPanel.y = HEADER_H;
		leftPanel.scrollFactor.set(0, 0);
		add(leftPanel);

		leftPanelBorder = new FlxSprite(LEFT_W - 3, HEADER_H).makeGraphic(3, FlxG.height - HEADER_H, currentWeekColor);
		leftPanelBorder.alpha = 0.5;
		leftPanelBorder.scrollFactor.set(0, 0);
		add(leftPanelBorder);

		// Hafta listesi başlık
		var listLabel = new FlxText(12, HEADER_H + 10, LEFT_W - 20, "HAFTALAR", 14);
		listLabel.setFormat(Paths.font("vcr.ttf"), 14, currentWeekColor, LEFT);
		listLabel.scrollFactor.set(0, 0);
		add(listLabel);

		var listLabelLine = new FlxSprite(12, HEADER_H + 28).makeGraphic(LEFT_W - 24, 2, currentWeekColor);
		listLabelLine.alpha = 0.3;
		listLabelLine.scrollFactor.set(0, 0);
		add(listLabelLine);

		// Seçim vurgusu
		selectionBarGlow = new FlxSprite(0, HEADER_H + 36).makeGraphic(LEFT_W, CARD_H + CARD_GAP, currentWeekColor);
		selectionBarGlow.alpha = 0.08;
		selectionBarGlow.scrollFactor.set(0, 1);
		add(selectionBarGlow);

		selectionBar = new FlxSprite(0, HEADER_H + 38).makeGraphic(4, CARD_H - 4, currentWeekColor);
		selectionBar.scrollFactor.set(0, 1);
		add(selectionBar);

		// Hafta kartları
		weekListGroup = new FlxTypedGroup<WeekCard>();
		add(weekListGroup);

		for (i in 0...loadedWeeks.length)
		{
			var isLocked = weekIsLocked(loadedWeeks[i].fileName);
			var card = new WeekCard(8, HEADER_H + 36 + i * (CARD_H + CARD_GAP), loadedWeeks[i], i, isLocked, weekColors[i % weekColors.length]);
			card.scrollFactor.set(0, 1);
			card.alpha = 0;
			weekListGroup.add(card);
		}

		add(grpWeekText);
		add(grpLocks);
	}

	// ═══════════════════════════════════════════════════════
	// 📊 SAĞ PANEL — BİLGİ
	// ═══════════════════════════════════════════════════════
	function createInfoPanel()
	{
		var rx:Float = LEFT_W + CHAR_W + 3;
		var panelW:Float = FlxG.width - rx - 10;

		infoPanelGlow = new FlxSprite(rx - 2, HEADER_H - 2).makeGraphic(Std.int(panelW + 4), FlxG.height - HEADER_H + 2, currentWeekColor);
		infoPanelGlow.alpha = 0.06;
		infoPanelGlow.scrollFactor.set(0, 0);
		add(infoPanelGlow);

		infoPanel = FlxGradient.createGradientFlxSprite(
			Std.int(panelW), FlxG.height - HEADER_H,
			[0xCC0a0a12, 0xDD050508],
			1, 0
		);
		infoPanel.x = rx;
		infoPanel.y = HEADER_H;
		infoPanel.scrollFactor.set(0, 0);
		add(infoPanel);

		infoPanelBorder = new FlxSprite(rx, HEADER_H).makeGraphic(Std.int(panelW), 3, currentWeekColor);
		infoPanelBorder.alpha = 0.6;
		infoPanelBorder.scrollFactor.set(0, 0);
		add(infoPanelBorder);

		// Hafta adı
		weekNameGlow = new FlxSprite(rx + 8, HEADER_H + 18).makeGraphic(Std.int(panelW - 16), 52, currentWeekColor);
		weekNameGlow.alpha = 0.1;
		weekNameGlow.scrollFactor.set(0, 0);
		add(weekNameGlow);

		txtWeekTitle = new FlxText(rx + 12, HEADER_H + 24, panelW - 24, "", 24);
		txtWeekTitle.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txtWeekTitle.borderSize = 2;
		txtWeekTitle.scrollFactor.set(0, 0);
		add(txtWeekTitle);

		// Şarkı listesi paneli
		tracklistPanel = new FlxSprite(rx + 8, HEADER_H + 82).makeGraphic(Std.int(panelW - 16), 200, 0xAA000000);
		tracklistPanel.scrollFactor.set(0, 0);
		add(tracklistPanel);

		var tracklistBorder = new FlxSprite(rx + 8, HEADER_H + 82).makeGraphic(Std.int(panelW - 16), 3, currentWeekColor);
		tracklistBorder.alpha = 0.4;
		tracklistBorder.scrollFactor.set(0, 0);
		add(tracklistBorder);

		tracklistLabel = new FlxText(rx + 14, HEADER_H + 88, panelW - 28, "🎵 ŞARKILAR", 14);
		tracklistLabel.setFormat(Paths.font("vcr.ttf"), 14, currentWeekColor, LEFT);
		tracklistLabel.scrollFactor.set(0, 0);
		add(tracklistLabel);

		txtTracklist = new FlxText(rx + 14, HEADER_H + 112, panelW - 28, "", 18);
		txtTracklist.setFormat(Paths.font("vcr.ttf"), 18, 0xFFDDDDDD, LEFT);
		txtTracklist.scrollFactor.set(0, 0);
		add(txtTracklist);

		// Zorluk paneli (aşağıda)
		diffPanel = new FlxSprite(rx + 8, FlxG.height - 155).makeGraphic(Std.int(panelW - 16), 95, 0xAA000000);
		diffPanel.scrollFactor.set(0, 0);
		add(diffPanel);

		diffPanelGlow = new FlxSprite(rx + 8, FlxG.height - 155).makeGraphic(Std.int(panelW - 16), 3, currentWeekColor);
		diffPanelGlow.alpha = 0.5;
		diffPanelGlow.scrollFactor.set(0, 0);
		add(diffPanelGlow);

		var diffLabel = new FlxText(rx + 14, FlxG.height - 150, panelW - 28, "⚡ ZORLUK", 14);
		diffLabel.setFormat(Paths.font("vcr.ttf"), 14, currentWeekColor, LEFT);
		diffLabel.scrollFactor.set(0, 0);
		add(diffLabel);
	}

	// ═══════════════════════════════════════════════════════
	// ⚡ ZORLUK SEÇİCİ (Orijinal sistem — yeni pozisyon)
	// ═══════════════════════════════════════════════════════
	function createDifficultySelectors()
	{
		var rx:Float = LEFT_W + CHAR_W + 3;
		var panelW:Float = FlxG.width - rx - 10;

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		// Sol ok — zorluk paneli içinde
		leftArrow = new FlxSprite(rx + 14, FlxG.height - 120);
		leftArrow.antialiasing = ClientPrefs.data.antialiasing;
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		leftArrow.scale.set(0.7, 0.7);
		leftArrow.updateHitbox();
		difficultySelectors.add(leftArrow);

		Difficulty.resetList();
		if (lastDifficultyName == '') lastDifficultyName = Difficulty.getDefault();
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		sprDifficulty = new FlxSprite(0, leftArrow.y + 2);
		sprDifficulty.antialiasing = ClientPrefs.data.antialiasing;
		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(rx + panelW - 50, leftArrow.y);
		rightArrow.antialiasing = ClientPrefs.data.antialiasing;
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.scale.set(0.7, 0.7);
		rightArrow.updateHitbox();
		difficultySelectors.add(rightArrow);
	}

	// ═══════════════════════════════════════════════════════
	// 🎮 KONTROL İPUÇLARI
	// ═══════════════════════════════════════════════════════
	function createControlHints()
	{
		controlHintsPanel = new FlxSprite(0, FlxG.height - 28).makeGraphic(LEFT_W, 28, 0xAA000000);
		controlHintsPanel.scrollFactor.set(0, 0);
		add(controlHintsPanel);

		controlHintsText = new FlxText(0, FlxG.height - 22, LEFT_W, "↑↓:Seç  ◄►:Zorluk  ENTER:Oyna", 11);
		controlHintsText.setFormat(Paths.font("vcr.ttf"), 11, 0xFF888888, CENTER);
		controlHintsText.scrollFactor.set(0, 0);
		add(controlHintsText);

		var hintsRight = new FlxText(LEFT_W + CHAR_W + 10, FlxG.height - 22, RIGHT_W - 20, "CTRL:Ayarlar  DEL:Skor Sıfırla", 11);
		hintsRight.setFormat(Paths.font("vcr.ttf"), 11, 0xFF666666, CENTER);
		hintsRight.scrollFactor.set(0, 0);
		add(hintsRight);
	}

	// ═══════════════════════════════════════════════════════
	// 🎬 GİRİŞ ANİMASYONU
	// ═══════════════════════════════════════════════════════
	function playEntranceAnimation()
	{
		// Header aşağı
		FlxTween.tween(headerPanel, {y: 0}, 0.75, {ease: FlxEase.expoOut, startDelay: 0.05});
		FlxTween.tween(headerGlow, {y: HEADER_H - 4}, 0.75, {ease: FlxEase.expoOut, startDelay: 0.05});
		FlxTween.tween(headerTitle, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.3});
		FlxTween.tween(headerSubtitle, {alpha: 0.85}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.4});
		FlxTween.tween(headerBreadcrumb, {alpha: 0.7}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.5});

		// Sol panel soldan
		leftPanel.x = -LEFT_W;
		leftPanelGlow.x = -LEFT_W;
		leftPanelBorder.x = -10;
		FlxTween.tween(leftPanel, {x: 0}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.1});
		FlxTween.tween(leftPanelGlow, {x: 0}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.1});
		FlxTween.tween(leftPanelBorder, {x: LEFT_W - 3}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.15});

		// Hafta kartları stagger
		for (i in 0...weekListGroup.members.length)
		{
			var card = weekListGroup.members[i];
			FlxTween.tween(card, {alpha: i == curWeek ? 1 : 0.6}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.3 + i * 0.05});
		}

		// Sağ panel sağdan
		infoPanel.x = FlxG.width;
		infoPanelGlow.x = FlxG.width;
		infoPanelBorder.x = FlxG.width;
		var rx:Float = LEFT_W + CHAR_W + 3;
		FlxTween.tween(infoPanel, {x: rx}, 0.75, {ease: FlxEase.expoOut, startDelay: 0.2});
		FlxTween.tween(infoPanelGlow, {x: rx - 2}, 0.75, {ease: FlxEase.expoOut, startDelay: 0.2});
		FlxTween.tween(infoPanelBorder, {x: rx}, 0.75, {ease: FlxEase.expoOut, startDelay: 0.25});

		// Orta karakter paneli yukarıdan
		charPanel.y = HEADER_H - 50;
		charPanel.alpha = 0;
		FlxTween.tween(charPanel, {y: HEADER_H, alpha: 0.9}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.15});

		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);
	}

	// ═══════════════════════════════════════════════════════
	// 🔄 UPDATE
	// ═══════════════════════════════════════════════════════
	override function update(elapsed:Float)
	{
		if (WeekData.weeksList.length < 1)
		{
			if (controls.BACK && !movedBack && !selectedWeek)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				movedBack = true;
				MusicBeatState.switchState(new MainMenuState());
			}
			super.update(elapsed);
			return;
		}

		// ── Skor lerp ────────────────────────────────────────
		if (intendedScore != lerpScore)
		{
			lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 30)));
			if (Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;
			scoreText.text = formatScore(lerpScore);
		}

		// ── Animasyon timerları ───────────────────────────────
		animTimer  += elapsed;
		pulseTimer += elapsed;
		waveTimer  += elapsed * 2;
		floatTimer += elapsed * 1.5;
		glowTimer  += elapsed * 3;

		// ── Orb animasyonları ─────────────────────────────────
		for (i in 0...bgOrbs.length)
		{
			var orb = bgOrbs[i];
			orb.x += Math.sin(animTimer * 0.5 + i * 0.8) * 0.4;
			orb.y += Math.cos(animTimer * 0.4 + i * 0.8) * 0.3;
			orb.alpha = 0.04 + Math.sin(animTimer * 2 + i) * 0.02;
			orb.angle += elapsed * (3 + i * 2);
		}

		// ── Floating shapes ───────────────────────────────────
		for (i in 0...floatingShapes.length)
		{
			var shape = floatingShapes[i];
			shape.y += Math.sin(floatTimer * 0.8 + i * 0.5) * 0.25;
			shape.x += Math.cos(floatTimer * 0.6 + i * 0.5) * 0.18;
			shape.alpha = 0.04 + Math.sin(floatTimer * 2 + i) * 0.025;
			shape.angle += elapsed * (6 + i);
		}

		// ── Header glow pulse ─────────────────────────────────
		if (headerGlow != null)
			headerGlow.alpha = 0.5 + Math.sin(waveTimer) * 0.2;

		// ── Seçim çubuğu pulse ────────────────────────────────
		if (selectionBarGlow != null)
			selectionBarGlow.alpha = 0.06 + Math.sin(glowTimer) * 0.03;

		// ── Input ─────────────────────────────────────────────
		if (!movedBack && !selectedWeek)
		{
			var changeDiff:Bool = false;

			if (controls.UI_UP_P)   { changeWeek(-1); FlxG.sound.play(Paths.sound('scrollMenu')); changeDiff = true; }
			if (controls.UI_DOWN_P) { changeWeek(1);  FlxG.sound.play(Paths.sound('scrollMenu')); changeDiff = true; }

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				changeWeek(-FlxG.mouse.wheel);
				changeDifficulty();
			}

			if (controls.UI_RIGHT) rightArrow.animation.play('press');
			else rightArrow.animation.play('idle');

			if (controls.UI_LEFT) leftArrow.animation.play('press');
			else leftArrow.animation.play('idle');

			if (controls.UI_RIGHT_P)      changeDifficulty(1);
			else if (controls.UI_LEFT_P)  changeDifficulty(-1);
			else if (changeDiff)          changeDifficulty();

			if (FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
			}
			else if (controls.RESET)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
			}
			else if (controls.ACCEPT)
				selectWeek();
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;

			// Çıkış animasyonu
			FlxTween.tween(leftPanel, {x: -LEFT_W}, 0.4, {ease: FlxEase.backIn});
			FlxTween.tween(headerPanel, {y: -HEADER_H}, 0.4, {ease: FlxEase.backIn});
			FlxTween.tween(infoPanel, {x: FlxG.width + 50}, 0.4, {ease: FlxEase.backIn, startDelay: 0.04});

			new flixel.util.FlxTimer().start(0.45, function(_) {
				MusicBeatState.switchState(new MainMenuState());
			});
		}

		super.update(elapsed);

		// ── Hafta listesi pozisyon lerp (orijinal sistem) ─────
		var offY:Float = grpWeekText.members[curWeek] != null ? grpWeekText.members[curWeek].targetY : 0;
		for (num => item in grpWeekText.members)
			item.y = FlxMath.lerp(item.targetY - offY + 480, item.y, Math.exp(-elapsed * 10.2));

		for (num => lock in grpLocks.members)
		{
			if (grpWeekText.members[lock.ID] != null)
				lock.y = grpWeekText.members[lock.ID].y + grpWeekText.members[lock.ID].height / 2 - lock.height / 2;
		}

		// ── WeekCard kamera kaydırma ──────────────────────────
		updateWeekListScroll(elapsed);
	}

	function updateWeekListScroll(elapsed:Float)
	{
		if (weekListGroup.members.length == 0) return;
		var selectedCard = weekListGroup.members[curWeek];
		if (selectedCard == null) return;

		var targetScrollY = Math.max(0, selectedCard.y - (FlxG.height / 2) + CARD_H / 2 - HEADER_H);
		if (cameraTween != null) cameraTween.cancel();
		cameraTween = FlxTween.num(FlxG.camera.scroll.y, targetScrollY, 0.3, {ease: FlxEase.quartOut}, function(v:Float) {
			FlxG.camera.scroll.y = v;
		});
	}

	// ═══════════════════════════════════════════════════════
	// 🎮 HAFTA SEÇİMİ (Orijinal sistem korundu)
	// ═══════════════════════════════════════════════════════
	function selectWeek()
	{
		if (!weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
			for (i in 0...leWeek.length) songArray.push(leWeek[i][0]);

			try
			{
				PlayState.storyPlaylist  = songArray;
				PlayState.isStoryMode    = true;
				selectedWeek             = true;

				var diffic = Difficulty.getFilePath(curDifficulty);
				if (diffic == null) diffic = '';

				PlayState.storyDifficulty = curDifficulty;
				Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
				PlayState.campaignScore  = 0;
				PlayState.campaignMisses = 0;
			}
			catch (e:Dynamic)
			{
				trace('ERROR! $e');
				return;
			}

			if (!stopspamming)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				FlxG.camera.flash(0x33FFFFFF, 0.3);

				if (curWeek < weekListGroup.members.length)
				{
					var card = weekListGroup.members[curWeek];
					FlxTween.tween(card, {alpha: 0, "scale.x": 1.08, "scale.y": 1.08}, 0.4, {ease: FlxEase.quartIn});
				}

				for (char in grpWeekCharacters.members)
				{
					if (char.character != '' && char.hasConfirmAnimation)
						char.animation.play('confirm');
				}
				stopspamming = true;
			}

			var directory = StageData.forceNextDirectory;
			LoadingState.loadNextDirectory();
			StageData.forceNextDirectory = directory;

			@:privateAccess
			if (PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
			{
				trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
				Paths.freeGraphicsFromMemory();
			}
			LoadingState.prepareToSong();
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
				LoadingState.loadAndSwitchState(new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			});

			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		else
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.camera.shake(0.008, 0.25);
		}
	}

	// ═══════════════════════════════════════════════════════
	// ⚡ ZORLUK DEĞİŞTİRME (Orijinal sistem korundu)
	// ═══════════════════════════════════════════════════════
	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;
		if (curDifficulty < 0) curDifficulty = Difficulty.list.length - 1;
		if (curDifficulty >= Difficulty.list.length) curDifficulty = 0;

		WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

		var diff:String = Difficulty.getString(curDifficulty, false);
		var newImage:FlxGraphic = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));

		if (sprDifficulty.graphic != newImage)
		{
			sprDifficulty.loadGraphic(newImage);

			// Zorluk sprite'ını ok'lar arasında ortala
			var rx:Float = LEFT_W + CHAR_W + 3;
			var panelW:Float = FlxG.width - rx - 10;
			sprDifficulty.x = rx + 14 + leftArrow.width + 8;
			sprDifficulty.x += (panelW - 40 - leftArrow.width - rightArrow.width - 16 - sprDifficulty.width) / 2;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - sprDifficulty.height + leftArrow.height / 2 + sprDifficulty.height / 2 - 4;

			FlxTween.cancelTweensOf(sprDifficulty);
			FlxTween.tween(sprDifficulty, {y: sprDifficulty.y + 6, alpha: 1}, 0.1);
		}
		lastDifficultyName = diff;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	// ═══════════════════════════════════════════════════════
	// 📅 HAFTA DEĞİŞTİRME
	// ═══════════════════════════════════════════════════════
	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;
		if (curWeek >= loadedWeeks.length) curWeek = 0;
		if (curWeek < 0) curWeek = loadedWeeks.length - 1;

		var leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);
		currentWeekColor = weekColors[curWeek % weekColors.length];

		// ── Hafta adı ──────────────────────────────────────
		var leName:String = Language.getPhrase('storyname_${leWeek.fileName}', leWeek.storyName);
		txtWeekTitle.text = leName.toUpperCase();

		// ── Hafta arka planı ───────────────────────────────
		bgSprite.visible = true;
		var assetName:String = leWeek.weekBackground;
		if (assetName == null || assetName.length < 1)
		{
			bgSprite.visible = false;
		}
		else
		{
			bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
			bgSprite.setGraphicSize(CHAR_W, Std.int(FlxG.height - HEADER_H));
			bgSprite.updateHitbox();
			bgSprite.x = LEFT_W;
			bgSprite.y = HEADER_H;
			bgSprite.alpha = 0.55;
		}

		// ── Kilit durumu ───────────────────────────────────
		var unlocked:Bool = !weekIsLocked(leWeek.fileName);
		difficultySelectors.visible = unlocked;
		lockedWarning.visible     = !unlocked;
		lockedWarningText.visible = !unlocked;

		// ── Hafta kartları highlight ───────────────────────
		for (i in 0...weekListGroup.members.length)
		{
			var card = weekListGroup.members[i];
			if (card == null) continue;
			if (i == curWeek)
			{
				FlxTween.cancelTweensOf(card);
				FlxTween.tween(card, {alpha: 1}, 0.2, {ease: FlxEase.quadOut});
				FlxTween.tween(card.scale, {x: 1.02, y: 1.02}, 0.2, {ease: FlxEase.quadOut});
				card.accentBar.color = currentWeekColor;
				card.accentBar.alpha = 1;
			}
			else
			{
				FlxTween.cancelTweensOf(card);
				FlxTween.tween(card, {alpha: 0.55}, 0.2, {ease: FlxEase.quadOut});
				FlxTween.tween(card.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.quadOut});
				card.accentBar.alpha = 0;
			}
		}

		// ── Seçim çubuğu ──────────────────────────────────
		var targetBarY = HEADER_H + 38 + curWeek * (CARD_H + CARD_GAP);
		FlxTween.cancelTweensOf(selectionBar);
		FlxTween.cancelTweensOf(selectionBarGlow);
		FlxTween.tween(selectionBar, {y: targetBarY, color: currentWeekColor}, 0.25, {ease: FlxEase.expoOut});
		FlxTween.tween(selectionBarGlow, {y: targetBarY - 2, color: currentWeekColor}, 0.25, {ease: FlxEase.expoOut});

		// ── Tema rengi geçişi ─────────────────────────────
		updateThemeColor();

		PlayState.storyWeek = curWeek;

		Difficulty.loadFromWeek();
		difficultySelectors.visible = unlocked;

		if (Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		var newPos:Int = Difficulty.list.indexOf(lastDifficultyName);
		if (newPos > -1) curDifficulty = newPos;

		updateText();
	}

	function updateThemeColor()
	{
		// Dinamik arka plan rengi geçişi (OptionsState changeSelection tarzı)
		var newGradient = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[currentWeekColor, 0x00000000],
			1, 135
		);
		newGradient.scrollFactor.set(0, 0);
		newGradient.blend = ADD;
		newGradient.alpha = 0;

		var oldGradient = bgGradientDynamic;
		insert(members.indexOf(bgGradientDynamic), newGradient);

		FlxTween.tween(oldGradient, {alpha: 0}, 0.5, {
			onComplete: function(_) { remove(oldGradient); }
		});
		FlxTween.tween(newGradient, {alpha: 0.12}, 0.5);
		bgGradientDynamic = newGradient;

		// Orb renkleri
		for (orb in bgOrbs) orb.color = currentWeekColor;

		// Header glow rengi
		if (headerGlow != null) FlxTween.color(headerGlow, 0.4, headerGlow.color, currentWeekColor);
	}

	function updateText()
	{
		var weekArray:Array<String> = loadedWeeks[curWeek].weekCharacters;
		for (i in 0...grpWeekCharacters.length)
			grpWeekCharacters.members[i].changeCharacter(weekArray[i]);

		var leWeek:WeekData = loadedWeeks[curWeek];
		var stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length)
			stringThing.push(leWeek.songs[i][0]);

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
			txtTracklist.text += stringThing[i].toUpperCase() + '\n';

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	// ═══════════════════════════════════════════════════════
	// 🛠️ YARDIMCI FONKSIYONLAR
	// ═══════════════════════════════════════════════════════
	override function closeSubState()
	{
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0
			&& (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function formatScore(score:Int):String
	{
		var str = Std.string(score);
		var result = "";
		var count = 0;
		for (i in 0...str.length)
		{
			if (count > 0 && count % 3 == 0) result = "." + result;
			result = str.charAt(str.length - 1 - i) + result;
			count++;
		}
		return result;
	}
}

// ═══════════════════════════════════════════════════════════
// 📦 HAFTA KARTI (Sol panel öğesi)
// ═══════════════════════════════════════════════════════════
class WeekCard extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var accentBar:FlxSprite;
	public var nameText:FlxText;
	public var songCountText:FlxText;
	public var lockIcon:FlxText;
	public var completedBadge:FlxSprite;
	public var completedText:FlxText;

	public function new(x:Float, y:Float, weekData:WeekData, index:Int, locked:Bool, accentColor:FlxColor)
	{
		super(x, y);

		// Arka plan
		bg = FlxGradient.createGradientFlxSprite(284, 72, [0xCC0a0a18, 0xBB050510], 1, 0);
		bg.alpha = 0.4;
		add(bg);

		// Numara şeridi (sol üst köşe)
		var numBg = new FlxSprite(0, 0).makeGraphic(28, 72, accentColor);
		numBg.alpha = 0.18;
		add(numBg);

		var numText = new FlxText(0, 22, 28, Std.string(index + 1), 22);
		numText.setFormat(Paths.font("vcr.ttf"), 22, accentColor, CENTER);
		add(numText);

		// Sol kenar vurgu
		accentBar = new FlxSprite(0, 4).makeGraphic(4, 64, accentColor);
		accentBar.alpha = 0;
		add(accentBar);

		// Alt border
		var bottomLine = new FlxSprite(4, 70).makeGraphic(280, 2, 0x22FFFFFF);
		add(bottomLine);

		// Hafta adı
		var displayName = Language.getPhrase('storyname_${weekData.fileName}', weekData.storyName).toUpperCase();
		nameText = new FlxText(36, 12, 200, displayName, 19);
		nameText.setFormat(Paths.font("vcr.ttf"), 19, locked ? 0xFF888888 : FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nameText.borderSize = 1.5;
		add(nameText);

		// Şarkı sayısı
		var songCount = weekData.songs.length;
		songCountText = new FlxText(36, 42, 160, '🎵 $songCount şarkı', 13);
		songCountText.setFormat(Paths.font("vcr.ttf"), 13, locked ? 0xFF555555 : 0xFF888888, LEFT);
		add(songCountText);

		// Kilit ikonu
		if (locked)
		{
			lockIcon = new FlxText(248, 22, 30, "🔒", 22);
			add(lockIcon);
		}

		// Tamamlandı rozeti
		if (StoryMenuState.weekCompleted.exists(weekData.fileName) && StoryMenuState.weekCompleted.get(weekData.fileName))
		{
			completedBadge = new FlxSprite(210, 8).makeGraphic(66, 20, 0xFF10B981);
			completedBadge.alpha = 0.9;
			add(completedBadge);

			completedText = new FlxText(211, 11, 64, "✓ BİTİRDİN", 11);
			completedText.setFormat(Paths.font("vcr.ttf"), 11, FlxColor.WHITE, CENTER);
			add(completedText);
		}
	}
}
