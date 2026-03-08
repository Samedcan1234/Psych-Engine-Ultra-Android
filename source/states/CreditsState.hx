package states;

import backend.Discord;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.util.FlxGradient;
import objects.AttachedSprite;
import states.ThanksCreditsState;
import states.MysteryConfirmState;
import flixel.effects.FlxFlicker;

class CreditsState extends MusicBeatState
{
	// ═══════════════════════════════════════════
	// VERİ DEĞİŞKENLERİ
	// ═══════════════════════════════════════════
	private var creditsStuff:Array<Array<String>> = [];
	var curSelected:Int     = 0;
	var curLinkSelected:Int = 0;
	var inLinkSelection:Bool = false;

	// ═══════════════════════════════════════════
	// ARKA PLAN & PANEL
	// ═══════════════════════════════════════════
	var bg:FlxSprite;
	var gridBG:FlxBackdrop;
	var rightSideCover:FlxSprite;
	var leftPanel:FlxSprite;
	var gradientOverlay:FlxSprite;

	// Ambient partiküller (gizemli partiküllerden AYRI)
	var ambientParticles:Array<FlxSprite> = [];

	// ═══════════════════════════════════════════
	// GİZEMLİ TEMA
	// ═══════════════════════════════════════════
	var mysteryOverlay:FlxSprite;
	var glitchTimer:Float   = 0;
	var isMysteryCredit:Bool = false;
	var staticNoise:FlxSprite;
	var eyeSprite:FlxSprite;
	var mysteryParticles:Array<FlxSprite> = [];
	var mysteryWarningText:FlxText;
	var warningAlpha:Float = 0;

	// ═══════════════════════════════════════════
	// SAĞ TARAF — Karakter Vitrini
	// ═══════════════════════════════════════════
	var charIcon:FlxSprite;
	var charIconGlow:FlxSprite;          // YENİ: ikon altı glow halkası
	var charName:Alphabet;
	var charRoleBox:FlxSprite;
	var charRole:FlxText;
	var charSectionLabel:FlxText;        // YENİ: sağ üstte section adı

	// ═══════════════════════════════════════════
	// SOL TARAF — İsim & Linkler
	// ═══════════════════════════════════════════
	var leftName:FlxText;
	var leftNameShadow:FlxText;
	var leftAccentLine:FlxSprite;        // YENİ: isim altı accent çizgisi

	// YENİ link struct tipi — accent şerit eklendi
	var linkContainers:Array<{
		name:String,
		container:FlxSprite,
		accentStripe:FlxSprite,
		icon:FlxSprite,
		text:FlxText,
		url:String
	}> = [];
	var activeLinkIndices:Array<Int> = [];

	var helpText:FlxText;
	var helpBg:FlxSprite;

	// ═══════════════════════════════════════════
	// ÜST BAR (YENİ)
	// ═══════════════════════════════════════════
	var topBar:FlxSprite;
	var topBarTitle:FlxText;
	var topBarSection:FlxText;           // Aktif section adını gösterir
	var topBarHint:FlxText;              // Kısayol ipuçları

	// ═══════════════════════════════════════════
	// PROGRESS BAR (YENİ)
	// ═══════════════════════════════════════════
	var progressBarBg:FlxSprite;
	var progressBar:FlxSprite;
	var progressText:FlxText;

	// ═══════════════════════════════════════════
	// ACCENT RENK SİSTEMİ (YENİ)
	// ═══════════════════════════════════════════
	var intendedColor:FlxColor;
	var currentAccentColor:FlxColor = FlxColor.WHITE;

	var currentLinks:Map<String, String> = [
		"youtube"    => "",
		"tiktok"     => "",
		"twitter"    => "",
		"github"     => "",
		"gamebanana" => "",
		"discord"    => ""
	];

	var SPLIT_X:Int = 520; // Sol panel biraz daraltıldı, sağa daha fazla alan

	// ═══════════════════════════════════════════════════════════════
	// CREATE
	// ═══════════════════════════════════════════════════════════════
	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Credits Menüsünde", null);
		#end

		persistentUpdate = true;

		// ── 1. Ana Arka Plan ────────────────────────────────────────
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		add(bg);

		// ── 2. Sağ Taraf Kapağı ─────────────────────────────────────
		rightSideCover = new FlxSprite(SPLIT_X, 0).makeGraphic(
			FlxG.width - SPLIT_X, FlxG.height, FlxColor.WHITE
		);
		rightSideCover.antialiasing = ClientPrefs.data.antialiasing;
		add(rightSideCover);

		// ── 3. Grid (daha ince, yavaş) ──────────────────────────────
		gridBG = new FlxBackdrop(FlxGridOverlay.createGrid(60, 60, 120, 120, true, 0x18FFFFFF, 0x0));
		gridBG.velocity.set(18, 18);
		gridBG.alpha = 0;
		FlxTween.tween(gridBG, {alpha: 1}, 1.2, {ease: FlxEase.quartOut});
		add(gridBG);

		// ── 4. Sol Gradient Overlay ─────────────────────────────────
		gradientOverlay = FlxGradient.createGradientFlxSprite(
			SPLIT_X, FlxG.height,
			[0x00000000, 0x44000000, 0x88000000],
			1, 0
		);
		add(gradientOverlay);

		// ── 5. Sol Panel (koyu cam efekti) ──────────────────────────
		leftPanel = new FlxSprite(0, 0).makeGraphic(SPLIT_X, FlxG.height, 0xFF0A0A0F);
		leftPanel.alpha = 0.82;
		// Giriş animasyonu: aşağıdan kayar
		leftPanel.y = FlxG.height;
		FlxTween.tween(leftPanel, {y: 0}, 0.55, {ease: FlxEase.quartOut});
		add(leftPanel);

		// Sol panel sağ kenar ince çizgisi
		var panelBorder = new FlxSprite(SPLIT_X - 2, 0).makeGraphic(2, FlxG.height, 0xFFFFFFFF);
		panelBorder.alpha = 0.12;
		add(panelBorder);

		// ── 6. Ambient Partiküller (YENİ) ───────────────────────────
		createAmbientParticles();

		// ── 7. Gizemli Tema Elemanları ───────────────────────────────
		staticNoise = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		staticNoise.alpha = 0;
		add(staticNoise);

		mysteryOverlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF1a0a0a);
		mysteryOverlay.alpha = 0;
		add(mysteryOverlay);

		eyeSprite = new FlxSprite(0, 0);
		if (Paths.fileExists('images/credits/mystery_eye.png', IMAGE))
			eyeSprite.loadGraphic(Paths.image('credits/mystery_eye'));
		else
			eyeSprite.makeGraphic(100, 100, FlxColor.RED);
		eyeSprite.alpha = 0;
		eyeSprite.screenCenter();
		add(eyeSprite);

		mysteryWarningText = new FlxText(0, FlxG.height - 150, FlxG.width, "", 20);
		mysteryWarningText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.RED, CENTER,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		mysteryWarningText.borderSize = 2;
		mysteryWarningText.alpha = 0;
		add(mysteryWarningText);

		// ── 8. Modları Yükle ─────────────────────────────────────────
		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled) pushModCreditsToList(mod);
		#end
		if (creditsStuff.length == 0) pushDefaultCredits();

		// ── 9. İkon Glow Halkası (YENİ) ─────────────────────────────
		charIconGlow = new FlxSprite(0, 0).makeGraphic(240, 240, FlxColor.TRANSPARENT);
		charIconGlow.alpha = 0.22;
		charIconGlow.antialiasing = ClientPrefs.data.antialiasing;
		add(charIconGlow);

		// ── 10. Karakter İkonu ───────────────────────────────────────
		charIcon = new FlxSprite(0, 0);
		charIcon.antialiasing = ClientPrefs.data.antialiasing;
		add(charIcon);

		// ── 11. Büyük Alphabet İsim (sağda) ─────────────────────────
		charName = new Alphabet(0, 0, "", true);
		charName.scaleX = 0.75;
		charName.scaleY = 0.75;
		add(charName);

		// ── 12. Rol Kutusu + Yazısı ──────────────────────────────────
		charRoleBox = FlxGradient.createGradientFlxSprite(
			FlxG.width - SPLIT_X, 130,
			[0x00000000, 0xBB000000, 0xEE000000],
			1, 90
		);
		charRoleBox.x = SPLIT_X;
		charRoleBox.y = FlxG.height - 130;
		add(charRoleBox);

		charRole = new FlxText(SPLIT_X + 20, FlxG.height - 90, (FlxG.width - SPLIT_X) - 40, "", 22);
		charRole.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		charRole.borderSize = 2.5;
		add(charRole);

		// ── 13. Section Etiketi — sağ üstte (YENİ) ──────────────────
		charSectionLabel = new FlxText(SPLIT_X + 16, 72, FlxG.width - SPLIT_X - 16, "— YAPIMCI —", 14);
		charSectionLabel.setFormat(Paths.font("vcr.ttf"), 14, 0xFFCCCCCC, RIGHT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		charSectionLabel.borderSize = 1.5;
		charSectionLabel.alpha = 0.7;
		add(charSectionLabel);

		// ── 14. Sol İsim Gölgesi ─────────────────────────────────────
		leftNameShadow = new FlxText(5, 93, SPLIT_X, "Name", 48);
		leftNameShadow.setFormat(Paths.font("vcr.ttf"), 48, 0xFF000000, CENTER,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		leftNameShadow.alpha = 0.28;
		add(leftNameShadow);

		// ── 15. Sol İsim ─────────────────────────────────────────────
		leftName = new FlxText(8, 88, SPLIT_X - 16, "Name", 48);
		leftName.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		leftName.borderSize = 3;
		add(leftName);

		// ── 16. Accent Çizgisi — isim altı (YENİ) ───────────────────
		leftAccentLine = new FlxSprite(20, 148).makeGraphic(SPLIT_X - 40, 3, FlxColor.WHITE);
		leftAccentLine.alpha = 0.6;
		add(leftAccentLine);

		// ── 17. Link Konteynerleri ───────────────────────────────────
		initializeLinkContainers();

		// ── 18. Üst Bar (YENİ) ──────────────────────────────────────
		topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 64, 0xFF06060F);
		topBar.alpha = 0.93;
		add(topBar);

		var topBarLine = new FlxSprite(0, 64).makeGraphic(FlxG.width, 2, FlxColor.WHITE);
		topBarLine.alpha = 0.1;
		add(topBarLine);

		topBarTitle = new FlxText(18, 10, 300, "✦  KREDİLER", 28);
		topBarTitle.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, LEFT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		topBarTitle.borderSize = 2;
		add(topBarTitle);

		topBarSection = new FlxText(0, 14, FlxG.width - 20, "", 18);
		topBarSection.setFormat(Paths.font("vcr.ttf"), 18, 0xFFAAAAAA, RIGHT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		topBarSection.borderSize = 1.5;
		add(topBarSection);

		topBarHint = new FlxText(0, 46, FlxG.width - 14, "[ CTRL ] Akış  •  [ ESC ] Geri  •  [ ENTER / ← ] Linkler", 11);
		topBarHint.setFormat(Paths.font("vcr.ttf"), 11, 0xFF666688, RIGHT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		topBarHint.borderSize = 1;
		add(topBarHint);

		// ── 19. Yardım Çubuğu ───────────────────────────────────────
		helpBg = new FlxSprite(0, FlxG.height - 58).makeGraphic(SPLIT_X, 58, 0x00000000);
		add(helpBg);

		// Alt gradient şeridi
		var helpGrad = FlxGradient.createGradientFlxSprite(
			SPLIT_X, 58,
			[0x00000000, 0xCC000000],
			1, 90
		);
		helpGrad.setPosition(0, FlxG.height - 58);
		add(helpGrad);

		helpText = new FlxText(8, FlxG.height - 48, SPLIT_X - 16,
			"▲ ▼  Seç   •   ENTER / ←  Linkler\nCTRL  Credits Akışını İzle", 13);
		helpText.setFormat(Paths.font("vcr.ttf"), 13, 0xFFBBBBBB, CENTER,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		helpText.borderSize = 1.5;
		add(helpText);

		// ── 20. Progress Bar (YENİ) ──────────────────────────────────
		progressBarBg = new FlxSprite(0, FlxG.height - 3).makeGraphic(SPLIT_X, 3, 0xFF111122);
		add(progressBarBg);

		progressBar = new FlxSprite(0, FlxG.height - 3).makeGraphic(SPLIT_X, 3, FlxColor.WHITE);
		add(progressBar);

		// ── 21. Gizemli Partiküller ──────────────────────────────────
		createMysteryParticles();

		changeSelection();
		super.create();
	}

	// ─────────────────────────────────────────────────────────────
	// Ambient Partiküller (YENİ — gizemli partiküllerden ayrı)
	// ─────────────────────────────────────────────────────────────
	function createAmbientParticles()
	{
		for (i in 0...25)
		{
			var size  = Std.int(FlxG.random.float(1, 3));
			var p     = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			p.makeGraphic(size, size, FlxColor.WHITE);
			p.alpha      = FlxG.random.float(0.03, 0.12);
			p.velocity.y = FlxG.random.float(-8, -2);
			p.velocity.x = FlxG.random.float(-3, 3);
			add(p);
			ambientParticles.push(p);
		}
	}

	// ─────────────────────────────────────────────────────────────
	// Gizemli Partiküller (orijinal — korundu)
	// ─────────────────────────────────────────────────────────────
	function createMysteryParticles()
	{
		for (i in 0...20)
		{
			var particle = new FlxSprite(
				FlxG.random.float(0, FlxG.width),
				FlxG.random.float(0, FlxG.height)
			);
			particle.makeGraphic(
				Std.int(FlxG.random.float(2, 6)),
				Std.int(FlxG.random.float(2, 6)),
				FlxColor.RED
			);
			particle.alpha     = 0;
			particle.velocity.y = FlxG.random.float(-50, -20);
			particle.velocity.x = FlxG.random.float(-10, 10);
			add(particle);
			mysteryParticles.push(particle);
		}
	}

	// ═══════════════════════════════════════════════════════════════
	// UPDATE
	// ═══════════════════════════════════════════════════════════════
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		// Gizemli efektler
		updateMysteryEffects(elapsed);

		// Accent renk yumuşak geçiş (YENİ)
		updateAccentColor(elapsed);

		// Ambient partikülleri geri dönüştür (YENİ)
		for (p in ambientParticles)
		{
			if (p.y < -5)
			{
				p.y = FlxG.height + 5;
				p.x = FlxG.random.float(0, FlxG.width);
			}
		}

		// Mouse Scroll
		#if desktop
		if (FlxG.mouse.wheel != 0)
		{
			if (!inLinkSelection)
				changeSelection(-FlxG.mouse.wheel);
			else
				changeLinkSelection(FlxG.mouse.wheel);
		}
		#end

		var upP    = controls.UI_UP_P;
		var downP  = controls.UI_DOWN_P;
		var leftP  = controls.UI_LEFT_P;
		var rightP = controls.UI_RIGHT_P;
		var accept = controls.ACCEPT;
		var back   = controls.BACK;

		// CTRL → Credits Akışı
		if (FlxG.keys.justPressed.CONTROL)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			MusicBeatState.switchState(new ThanksCreditsState());
			return;
		}

		if (back)
		{
			if (inLinkSelection)
			{
				toggleLinkSelection(false);
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
			return;
		}

		if (!inLinkSelection)
		{
			if (upP)   changeSelection(-1);
			if (downP) changeSelection(1);

			if ((leftP || accept) && !isHeader(curSelected))
			{
				var currentName = creditsStuff[curSelected][0].toLowerCase();
				if (currentName == "tumu")
				{
					triggerMysterySequence();
					return;
				}
				toggleLinkSelection(true);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
		}
		else
		{
			if (upP || downP) changeLinkSelection(1);

			if (rightP)
			{
				toggleLinkSelection(false);
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			if (accept)
			{
				var linkToOpen:String = getSelectedLinkUrl();
				if (linkToOpen != null && linkToOpen.length > 4)
					CoolUtil.browserLoad(linkToOpen);
				else
				{
					FlxG.camera.shake(0.005, 0.5);
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			}
		}
	}

	// ─────────────────────────────────────────────────────────────
	// Accent Renk Güncelleme (YENİ)
	// ─────────────────────────────────────────────────────────────
	function updateAccentColor(elapsed:Float)
	{
		currentAccentColor = FlxColor.interpolate(currentAccentColor, intendedColor, 0.06);

		// Top bar başlığı accent alır
		if (topBarTitle != null)
			topBarTitle.color = FlxColor.interpolate(topBarTitle.color, currentAccentColor, 0.08);

		// Accent çizgisi rengi
		if (leftAccentLine != null)
			leftAccentLine.color = currentAccentColor;

		// Glow halkası rengi
		if (charIconGlow != null)
			charIconGlow.color = currentAccentColor;

		// Progress bar rengi
		if (progressBar != null)
			progressBar.color = currentAccentColor;
	}

	// ─────────────────────────────────────────────────────────────
	// Gizemli Sekans (orijinal — korundu)
	// ─────────────────────────────────────────────────────────────
	function triggerMysterySequence()
	{
		FlxG.camera.shake(0.02, 0.5);

		if (Paths.fileExists('sounds/mystery_trigger.ogg', SOUND))
			FlxG.sound.play(Paths.sound('mystery_trigger'));
		else
			FlxG.sound.play(Paths.sound('confirmMenu'));

		FlxTween.tween(mysteryOverlay, {alpha: 1}, 0.5, {
			ease: FlxEase.quartIn,
			onComplete: function(twn:FlxTween) {
				MusicBeatState.switchState(new MysteryConfirmState());
			}
		});
	}

	// ─────────────────────────────────────────────────────────────
	// Gizemli Efektler Güncelleme (orijinal — korundu)
	// ─────────────────────────────────────────────────────────────
	function updateMysteryEffects(elapsed:Float)
	{
		var currentName = "";
		if (creditsStuff.length > 0 && curSelected < creditsStuff.length)
			currentName = creditsStuff[curSelected][0].toLowerCase();

		isMysteryCredit = (currentName == "tumu");

		if (isMysteryCredit)
		{
			glitchTimer += elapsed;

			mysteryOverlay.alpha = FlxMath.lerp(mysteryOverlay.alpha, 0.4, 0.05);

			if (glitchTimer > 0.1)
			{
				glitchTimer = 0;
				staticNoise.alpha = FlxG.random.float(0, 0.15);
				if (FlxG.random.bool(5)) FlxG.camera.shake(0.005, 0.1);
			}

			mysteryWarningText.text  = getRandomWarningText();
			mysteryWarningText.alpha = FlxMath.lerp(
				mysteryWarningText.alpha,
				0.7 + Math.sin(glitchTimer * 5) * 0.3,
				0.1
			);

			for (p in mysteryParticles)
			{
				p.alpha = FlxMath.lerp(p.alpha, 0.6, 0.05);
				if (p.y < -10)
				{
					p.y = FlxG.height + 10;
					p.x = FlxG.random.float(0, FlxG.width);
				}
			}

			if (FlxG.random.bool(0.5))
			{
				eyeSprite.alpha = 0.3;
				eyeSprite.x = FlxG.random.float(0, FlxG.width  - 100);
				eyeSprite.y = FlxG.random.float(0, FlxG.height - 100);
				FlxTween.tween(eyeSprite, {alpha: 0}, 0.5);
			}

			if (leftName != null)
			{
				leftName.x     = (SPLIT_X / 2) - (leftName.width / 2) + FlxG.random.float(-2, 2);
				leftName.color = FlxG.random.bool(10) ? FlxColor.RED : FlxColor.WHITE;
			}

			gridBG.color = FlxColor.interpolate(gridBG.color, 0xFF330000, 0.05);
		}
		else
		{
			mysteryOverlay.alpha      = FlxMath.lerp(mysteryOverlay.alpha,      0, 0.1);
			staticNoise.alpha         = FlxMath.lerp(staticNoise.alpha,         0, 0.1);
			mysteryWarningText.alpha  = FlxMath.lerp(mysteryWarningText.alpha,  0, 0.1);
			eyeSprite.alpha           = 0;

			for (p in mysteryParticles)
				p.alpha = FlxMath.lerp(p.alpha, 0, 0.1);

			gridBG.color = FlxColor.interpolate(gridBG.color, FlxColor.WHITE, 0.05);

			if (leftName != null)
				leftName.color = FlxColor.WHITE;
		}
	}

	function getRandomWarningText():String
	{
		var warnings = [
			"Bunu Yapmak İstediğinden Eminmisin?",
			"GERİ DÖNÜŞ YOK...",
			"DEVAM ET... EĞER CESARETİN VARSA...",
			"BİRİLERİ İZLİYOR...",
			"SEÇİMİNİ YAP...",
			"KARANLIK YAKLAŞIYOR...",
			"...",
			"ENTER'A BAS... EĞER HAZIRSAN..."
		];
		return warnings[Std.int(FlxG.random.float(0, warnings.length))];
	}

	// ─────────────────────────────────────────────────────────────
	// Beat Hit (orijinal + glow animasyonu eklendi)
	// ─────────────────────────────────────────────────────────────
	override function beatHit()
	{
		super.beatHit();

		if (charIcon != null)
		{
			charIcon.scale.set(1.1, 1.1);
			FlxTween.tween(charIcon.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.elasticOut});
		}

		// YENİ: glow halkası nabız atışı
		if (charIconGlow != null)
		{
			charIconGlow.alpha = 0.55;
			FlxTween.tween(charIconGlow, {alpha: 0.18}, 0.6, {ease: FlxEase.quartOut});
		}

		if (isMysteryCredit)
		{
			FlxG.camera.zoom = 1.02;
			FlxTween.tween(FlxG.camera, {zoom: 1}, 0.3, {ease: FlxEase.quartOut});
		}
	}

	// ═══════════════════════════════════════════════════════════════
	// changeSelection
	// ═══════════════════════════════════════════════════════════════
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;
		if (curSelected < 0) curSelected = creditsStuff.length - 1;
		if (curSelected >= creditsStuff.length) curSelected = 0;

		if (isHeader(curSelected))
		{
			changeSelection(change > 0 ? 1 : -1);
			return;
		}

		var data = creditsStuff[curSelected];

		// ── Sağ taraf isim ──────────────────────────────────────────
		charName.text = data[0];
		var centerRight = SPLIT_X + ((FlxG.width - SPLIT_X) / 2);
		charName.x = centerRight - (charName.width / 2);
		charName.y = FlxG.height * 0.56;

		// ── Sol taraf isim (adaptif font boyutu) ────────────────────
		var nameText  = data[0];
		var fontSize  = 48;
		if (nameText.length > 12)
		{
			fontSize = Std.int(48 * (12 / nameText.length));
			if (fontSize < 22) fontSize = 22;
		}

		leftName.text = nameText;
		leftName.size = fontSize;
		leftName.x   = (SPLIT_X / 2) - (leftName.width / 2);

		leftNameShadow.text = nameText;
		leftNameShadow.size = fontSize;
		leftNameShadow.x    = leftName.x + 3;
		leftNameShadow.y    = leftName.y + 3;

		// ── Accent çizgisi konumu ────────────────────────────────────
		if (leftAccentLine != null)
		{
			var lineW = Std.int(Math.min(nameText.length * 14 + 40, SPLIT_X - 40));
			leftAccentLine.makeGraphic(lineW, 3, FlxColor.WHITE);
			leftAccentLine.x = (SPLIT_X / 2) - (lineW / 2);
			leftAccentLine.y = leftName.y + fontSize + 6;
		}

		// ── Rol yazısı ───────────────────────────────────────────────
		charRole.text = data[2];

		// ── Section etiketi güncelle (YENİ) ─────────────────────────
		if (charSectionLabel != null)
		{
			// Bir önceki header'ı bul
			var sectionName = "";
			for (i in 0...curSelected)
			{
				if (creditsStuff[i].length <= 1 && creditsStuff[i][0] != null && creditsStuff[i][0].length > 0)
					sectionName = creditsStuff[i][0];
			}
			charSectionLabel.text = sectionName.length > 0 ? '— $sectionName —' : "— YAPIMCI —";

			// Top bar'da section göster
			if (topBarSection != null)
				topBarSection.text = sectionName.length > 0 ? sectionName : "";
		}

		// ── Ghost Icon Animasyonu (orijinal — korundu) ───────────────
		if (change != 0 && charIcon.graphic != null)
		{
			var ghostIcon = new FlxSprite(charIcon.x, charIcon.y);
			ghostIcon.loadGraphic(charIcon.graphic);
			ghostIcon.scale.copyFrom(charIcon.scale);
			ghostIcon.updateHitbox();
			ghostIcon.offset.copyFrom(charIcon.offset);
			ghostIcon.antialiasing = charIcon.antialiasing;
			ghostIcon.alpha = 1;
			insert(members.indexOf(charIcon), ghostIcon);

			var slideDistance = 100;
			var moveY = (change == 1) ? -slideDistance : slideDistance;
			FlxTween.tween(ghostIcon, {y: charIcon.y + moveY, alpha: 0}, 0.35, {
				ease: FlxEase.quartOut,
				onComplete: function(_) { ghostIcon.destroy(); }
			});
		}

		// ── Yeni İkon Yükle ──────────────────────────────────────────
		var iconName = data[1];
		var iconPath = 'credits/' + iconName;
		if (!Paths.fileExists('images/$iconPath.png', IMAGE))
			iconPath = 'credits/missing_icon';

		charIcon.loadGraphic(Paths.image(iconPath));

		var scl = 1.0;
		if (charIcon.width > 200) scl = 0.8;
		charIcon.setGraphicSize(Std.int(charIcon.width * 1.3 * scl));
		charIcon.updateHitbox();

		var targetY = (FlxG.height * 0.35) - (charIcon.height / 2);
		charIcon.x  = centerRight - (charIcon.width / 2);

		// Glow halkasını ikona hizala (YENİ)
		if (charIconGlow != null)
		{
			charIconGlow.setGraphicSize(Std.int(charIcon.width * 1.4), Std.int(charIcon.height * 1.4));
			charIconGlow.updateHitbox();
			charIconGlow.color = intendedColor;
			charIconGlow.x = charIcon.x - (charIconGlow.width  - charIcon.width)  / 2;
			charIconGlow.y = charIcon.y - (charIconGlow.height - charIcon.height) / 2;
		}

		if (change != 0)
		{
			FlxTween.cancelTweensOf(charIcon);
			charIcon.y     = targetY + (change == 1 ? 100 : -100);
			charIcon.alpha = 0;
			FlxTween.tween(charIcon, {y: targetY, alpha: 1}, 0.35, {ease: FlxEase.quartOut});
		}
		else
		{
			charIcon.y    = targetY;
			charIcon.alpha = 1;
		}

		// ── Renk Geçişi (orijinal — korundu) ────────────────────────
		var newColor:FlxColor = CoolUtil.colorFromString(data[4]);
		if (newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.cancelTweensOf(rightSideCover);
			FlxTween.color(bg,           0.8, bg.color,           intendedColor);
			FlxTween.color(rightSideCover, 0.8, rightSideCover.color, intendedColor);
		}

		parseAndCategorizeLinks(data[3]);
		updateLinkVisuals();
		updateProgressBar();
	}

	// ─────────────────────────────────────────────────────────────
	// Progress Bar Güncelleme (YENİ)
	// ─────────────────────────────────────────────────────────────
	function updateProgressBar()
	{
		if (progressBar == null || progressBarBg == null || creditsStuff.length == 0) return;

		// Sadece header olmayan kayıt sayısını hesapla
		var totalReal:Int = 0;
		var curReal:Int   = 0;
		for (i in 0...creditsStuff.length)
		{
			if (!isHeader(i))
			{
				totalReal++;
				if (i <= curSelected) curReal++;
			}
		}
		if (totalReal == 0) return;

		var fraction:Float = curReal / totalReal;
		var targetW:Float  = SPLIT_X * fraction;
		if (targetW < 1) targetW = 1;

		// makeGraphic YERINE scaleX kullan — tween güvenli
		FlxTween.cancelTweensOf(progressBar);
		progressBar.makeGraphic(SPLIT_X, 3, FlxColor.WHITE);
		progressBar.color  = currentAccentColor;
		progressBar.scale.x = targetW / SPLIT_X;

		// Ölçekleme sol noktadan başlasın diye offset ayarla
		progressBar.x      = 0;
	}

	// ═══════════════════════════════════════════════════════════════
	// Link Konteynerleri Başlatma
	// ═══════════════════════════════════════════════════════════════
	function initializeLinkContainers()
	{
		var linkData = [
			{name: "youtube",    imageName: "yt",         fallbackColor: 0xFFFF0000},
			{name: "tiktok",     imageName: "tt",         fallbackColor: 0xFF010101},
			{name: "twitter",    imageName: "twitter",    fallbackColor: 0xFF1DA1F2},
			{name: "discord",    imageName: "discord",    fallbackColor: 0xFF5865F2},
			{name: "github",     imageName: "github",     fallbackColor: 0xFF333333},
			{name: "gamebanana", imageName: "gamebanana", fallbackColor: 0xFFE1A000}
		];

		for (linkInfo in linkData)
		{
			// Ana konteyner — daha koyu gradyan
			var container = FlxGradient.createGradientFlxSprite(
				SPLIT_X - 24, 72,
				[0xCC0D0D18, 0xEE060610],
				1, 0
			);
			container.alpha = 0.9;
			add(container);

			// Sol kenar accent şerit (YENİ)
			var accentStripe = new FlxSprite(0, 0).makeGraphic(4, 72, linkInfo.fallbackColor);
			accentStripe.alpha = 0.85;
			add(accentStripe);

			// İkon
			var icon = new FlxSprite(0, 0);
			var iconPath = 'credits/${linkInfo.imageName}';
			if (Paths.fileExists('images/$iconPath.png', IMAGE))
				icon.loadGraphic(Paths.image(iconPath));
			else
				icon.makeGraphic(56, 56, linkInfo.fallbackColor);
			icon.setGraphicSize(56, 56);
			icon.updateHitbox();
			add(icon);

			// Metin
			var text = new FlxText(0, 0, SPLIT_X - 110, "@" + linkInfo.name, 26);
			text.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, LEFT,
				FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.borderSize = 1.8;
			add(text);

			linkContainers.push({
				name:         linkInfo.name,
				container:    container,
				accentStripe: accentStripe,
				icon:         icon,
				text:         text,
				url:          ""
			});
		}
	}

	// ─────────────────────────────────────────────────────────────
	// Link Görsellerini Güncelle
	// ─────────────────────────────────────────────────────────────
	function updateLinkVisuals()
	{
		if (linkContainers.length == 0) return;

		var selectedScale = 1.06;
		var normalScale   = 1.0;
		var marginX       = 12;
		var containerW    = SPLIT_X - 24;

		// Hepsini gizle
		for (lc in linkContainers)
		{
			lc.container.visible    = false;
			lc.accentStripe.visible = false;
			lc.icon.visible         = false;
			lc.text.visible         = false;
		}

		var yStart  = 162; // Accent çizgisinin altından başla
		var spacing = 80;

		for (idx in 0...activeLinkIndices.length)
		{
			var containerIdx = activeLinkIndices[idx];
			var lc           = linkContainers[containerIdx];
			var currentY     = yStart + (idx * spacing);

			lc.container.visible    = true;
			lc.accentStripe.visible = true;
			lc.icon.visible         = true;
			lc.text.visible         = true;

			lc.container.setPosition(marginX, currentY);
			lc.accentStripe.setPosition(marginX, currentY);
			lc.icon.setPosition(marginX + 10, currentY + 8);
			lc.text.setPosition(marginX + 74, currentY + 23);

			FlxTween.cancelTweensOf(lc.container.scale);
			FlxTween.cancelTweensOf(lc.container);
			FlxTween.cancelTweensOf(lc.icon);

			var isSelected = inLinkSelection && (idx == curLinkSelected);

			if (isSelected)
			{
				// Seçili: parlak, büyük, accent renkli şerit
				FlxTween.tween(lc.container, {alpha: 1.0}, 0.18);
				FlxTween.tween(lc.container.scale, {x: selectedScale, y: selectedScale}, 0.25,
					{ease: FlxEase.quartOut});
				FlxTween.tween(lc.icon, {alpha: 1.0}, 0.18);
				lc.accentStripe.color  = currentAccentColor;
				lc.accentStripe.alpha  = 1.0;
				lc.text.color          = FlxColor.WHITE;
			}
			else if (inLinkSelection)
			{
				// Pasif (link seçimindeyken diğerleri)
				FlxTween.tween(lc.container, {alpha: 0.38}, 0.18);
				FlxTween.tween(lc.container.scale, {x: normalScale, y: normalScale}, 0.25,
					{ease: FlxEase.quartOut});
				FlxTween.tween(lc.icon, {alpha: 0.45}, 0.18);
				lc.accentStripe.alpha = 0.3;
				lc.text.color         = 0xFF888888;
			}
			else
			{
				// Normal görünüm
				FlxTween.tween(lc.container, {alpha: 0.72}, 0.18);
				FlxTween.tween(lc.container.scale, {x: normalScale, y: normalScale}, 0.25,
					{ease: FlxEase.quartOut});
				FlxTween.tween(lc.icon, {alpha: 0.88}, 0.18);
				lc.accentStripe.alpha = 0.7;
				lc.text.color         = FlxColor.WHITE;
			}

			lc.text.text = extractHandle(lc.url, lc.name);
		}

		// Yardım metni güncelle
		if (inLinkSelection)
			helpText.text = "ENTER  Linki Aç   •   → / ESC  Geri\nCTRL  Credits Akışını İzle";
		else
			helpText.text = "▲ ▼  Seç   •   ENTER / ←  Linkler\nCTRL  Credits Akışını İzle";
	}

	// ═══════════════════════════════════════════════════════════════
	// Orijinal Fonksiyonlar — değiştirilmeden korundu
	// ═══════════════════════════════════════════════════════════════
	function parseAndCategorizeLinks(rawLinks:String)
	{
		for (link in linkContainers) link.url = "";
		activeLinkIndices = [];

		if (rawLinks == null || rawLinks.length == 0) return;

		for (linkUrl in rawLinks.split('|'))
		{
			if (linkUrl == null || linkUrl.length < 5) continue;
			var domain = extractDomainFromUrl(linkUrl);
			for (i in 0...linkContainers.length)
			{
				if (linkContainers[i].name == domain)
				{
					linkContainers[i].url = linkUrl;
					activeLinkIndices.push(i);
					break;
				}
			}
		}
		if (activeLinkIndices.length > 0) curLinkSelected = 0;
	}

	function extractDomainFromUrl(url:String):String
	{
		if (url.indexOf("youtube.com")  != -1 || url.indexOf("youtu.be")    != -1) return "youtube";
		if (url.indexOf("tiktok.com")   != -1)                                      return "tiktok";
		if (url.indexOf("twitter.com")  != -1 || url.indexOf("x.com")       != -1) return "twitter";
		if (url.indexOf("discord.gg")   != -1 || url.indexOf("discord.com") != -1) return "discord";
		if (url.indexOf("github.com")   != -1)                                      return "github";
		if (url.indexOf("gamebanana.com") != -1)                                    return "gamebanana";
		return "unknown";
	}

	function toggleLinkSelection(entering:Bool)
	{
		inLinkSelection = entering;
		if (entering && activeLinkIndices.length > 0) curLinkSelected = 0;
		updateLinkVisuals();
	}

	function changeLinkSelection(change:Int)
	{
		if (activeLinkIndices.length == 0) return;
		curLinkSelected += change;
		if (curLinkSelected >= activeLinkIndices.length) curLinkSelected = 0;
		if (curLinkSelected < 0) curLinkSelected = activeLinkIndices.length - 1;
		FlxG.sound.play(Paths.sound('scrollMenu'));
		updateLinkVisuals();
	}

	function getSelectedLinkUrl():String
	{
		if (activeLinkIndices.length == 0 || curLinkSelected >= activeLinkIndices.length) return "";
		return linkContainers[activeLinkIndices[curLinkSelected]].url;
	}

	function extractHandle(url:String, defaultName:String):String
	{
		if (url == null || url.length < 5) return "Link Yok";
		var parts  = url.split('/');
		var handle = parts[parts.length - 1];
		if (handle == "") handle = parts[parts.length - 2];
		return (handle.startsWith('@') ? "" : "@") + handle;
	}

	function isHeader(num:Int):Bool
	{
		return creditsStuff[num].length <= 1;
	}

	function pushDefaultCredits()
	{
		creditsStuff.push(['SametGkTe', 'gkte',
			'Psych Engine Türkiye Yapımcısı / Çevirmen / Kodlayıcı',
			'https://tiktok.com/@gktegameplay', '24ED13']);
		creditsStuff.push(['ShadowMario', 'gkte',
			'Main Programmer and Head of Psych Engine',
			'https://ko-fi.com/shadowmario', '24ED13']);
		creditsStuff.push(['tumU', 'gf', '.noitidE tumU',
			'https://tiktok.com/@lxzbs0', 'fe0725']);
	}

	#if MODS_ALLOWED
	function pushModCreditsToList(folder:String)
	{
		var creditsFile:String = Paths.mods(folder + '/data/credits.txt');
		#if TRANSLATIONS_ALLOWED
		var translatedCredits:String = Paths.mods(folder + '/data/credits-${ClientPrefs.data.language}.txt');
		#end

		if (#if TRANSLATIONS_ALLOWED
			(FileSystem.exists(translatedCredits) && (creditsFile = translatedCredits) == translatedCredits) ||
			#end FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for (i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if (arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
	}
	#end
}