package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import backend.ClientPrefs;
import flixel.input.keyboard.FlxKey;

class AdminPanel extends FlxSpriteGroup
{
    // ═══════════════════════════════════════════════════════════════
    // DURUM
    // ═══════════════════════════════════════════════════════════════
    public var isOpen:Bool = false;
    var categories:Array<String> = ["SUNUCU", "HİLE", "KONSOL", "MODLAR", "OYUNCULAR", "AYARLAR"];
    var curCategory:Int = 0;

    // ─── Layout sabitleri ───────────────────────────────────────
    static inline var PANEL_W:Int   = 1020;
    static inline var PANEL_H:Int   = 620;
    static inline var PANEL_X:Float = (1280 - PANEL_W) / 2;
    static inline var PANEL_Y:Float = (720  - PANEL_H) / 2;
    static inline var LEFT_W:Int    = 240;
    static inline var RIGHT_X:Float = PANEL_X + LEFT_W + 22;
    static inline var RIGHT_W:Int   = PANEL_W - LEFT_W - 34;

    static inline var CONTENT_TOP:Float = PANEL_Y + 82;
    static inline var CONTENT_BOT:Float = PANEL_Y + PANEL_H - 60;
    static inline var VISIBLE_H:Float   = CONTENT_BOT - CONTENT_TOP;

    // ─── Tema renkleri (modern görünüm) ─────────────────────────
    static inline var COL_OVERLAY:Int        = 0xE6050610;
    static inline var COL_PANEL_BG:Int       = 0xF010101A;
    static inline var COL_PANEL_BORDER:Int   = 0xFF5EF2FF;
    static inline var COL_LEFT_BG_TOP:Int    = 0xFF080711;
    static inline var COL_LEFT_BG_BOTTOM:Int = 0xFF05040A;
    static inline var COL_DIVIDER:Int        = 0xFF1A94FF;
    static inline var COL_HEADER_BG:Int      = 0xFF050914;
    static inline var COL_HEADER_LINE:Int    = 0xFF1A94FF;
    static inline var COL_TEXT_DIM:Int       = 0xFF7C8FB5;
    static inline var COL_TEXT_ACCENT:Int    = 0xFF5EF2FF;
    static inline var COL_TEXT_MUTED:Int     = 0xFF4A5670;
    static inline var COL_CARD_BG:Int        = 0xFF0B0F1F;
    static inline var COL_CARD_BG_ALT:Int    = 0xFF0F1527;
    static inline var COL_SCROLL_TRACK:Int   = 0xFF101529;
    static inline var COL_SCROLL_THUMB:Int   = 0xFF5EF2FF;
    static inline var COL_DANGER:Int         = 0xFFFF4B6E;
    static inline var COL_DANGER_DARK:Int    = 0xFF5F1020;
    static inline var COL_PRIMARY:Int        = 0xFF2FD5FF;
    static inline var COL_PRIMARY_DARK:Int   = 0xFF083D66;
    static inline var COL_SUCCESS:Int        = 0xFF41E29C;
    static inline var COL_SUCCESS_DARK:Int   = 0xFF084627;
    static inline var COL_WARNING:Int        = 0xFFFFC857;
    static inline var COL_WARNING_DARK:Int   = 0xFF5C4613;

    // ─── Temel UI ──────────────────────────────────────────────
    var overlay:FlxSprite;
    var panelBorder:FlxSprite;
    var panelBG:FlxSprite;
    var catSelector:FlxSprite;
    var catTexts:Array<FlxText> = [];
    var catIcons:Array<FlxSprite> = [];
    var contentTitle:FlxText;
    var hintText:FlxText;
    var logo:FlxSprite;
    var welcomeText:FlxText;
    var subTitleText:FlxText;

    // ─── Sunucu ────────────────────────────────────────────────
    var serverGroup:FlxSpriteGroup;
    var serverLines:Array<FlxText>  = [];
    var serverScrollBar:FlxSprite;
    var serverScrollThumb:FlxSprite;
    var serverScrollOffset:Float    = 0;
    var serverMaxOffset:Float       = 0;
    var serverLineHeight:Float      = 26;
    var serverBanButton:FlxSprite;
    var serverBanText:FlxText;
    var serverRefreshButton:FlxSprite;
    var serverRefreshText:FlxText;

    var serverData:Array<String> = [
        "► Motor        : Psych Engine Türkiye",
        "► Sürüm        : XQ Edition V3",
        "► Temel        : Ultra-Pre 0.6",
        "► Durum        : Çevrimiçi",
        "► Ping         : 8 ms",
        "► Oyuncu Sayısı: 1",
        "► Mod Sayısı   : 5",
        "► Son Güncell. : 2026",
        "► Dil          : Türkçe",
        "► Platform     : Windows/Linux",
        "► Render       : OpenFL",
        "► HScript      : Aktif",
        "► Discord RPC  : Aktif",
        "► Ses Sürücüsü : OpenAL",
        "► Çözünürlük   : 1280x720"
    ];

    // ─── Hile ──────────────────────────────────────────────────
    var cheatGroup:FlxSpriteGroup;
    var cheatItemBGs:Array<FlxSprite>    = [];
    var cheatItemTexts:Array<FlxText>    = [];
    var cheatStatusTexts:Array<FlxText>  = [];
    var curCheat:Int = 0;

    var cheatKeys:Array<String> = [
        "Bot-Play",
        "No Miss",
        "Sonsuz Omur",
        "Hız x2",
        "Görünmez Not",
        "Oto Hit",
        "Sonsuz Skor"
    ];
    var cheatStates:Map<String,Bool>;

    // ─── Konsol ────────────────────────────────────────────────
    var consoleGroup:FlxSpriteGroup;
    var consoleLines:Array<String>      = [];
    var consoleLineTexts:Array<FlxText> = [];
    var maxConsoleLines:Int = 11;
    var consoleCursor:FlxText;
    var consoleInput:String = "";
    var consoleBlink:Float  = 0;

    // ─── Modlar ────────────────────────────────────────────────
    var modGroup:FlxSpriteGroup;
    var modLines:Array<FlxText>  = [];
    var modScrollBar:FlxSprite;
    var modScrollThumb:FlxSprite;
    var modScrollOffset:Float    = 0;
    var modMaxOffset:Float       = 0;
    var modLineHeight:Float      = 26;
    var modLoadButton:FlxSprite;
    var modLoadText:FlxText;
    var modUnloadButton:FlxSprite;
    var modUnloadText:FlxText;

    var modData:Array<String> = [
        "► Mod 1: Aktif",
        "► Mod 2: Pasif",
        "► Mod 3: Aktif",
        "► Mod 4: Pasif",
        "► Mod 5: Aktif"
    ];

    // ─── Oyuncular ─────────────────────────────────────────────
    var playerGroup:FlxSpriteGroup;
    var playerLines:Array<FlxText>  = [];
    var playerScrollBar:FlxSprite;
    var playerScrollThumb:FlxSprite;
    var playerScrollOffset:Float    = 0;
    var playerMaxOffset:Float       = 0;
    var playerLineHeight:Float      = 26;
    var playerKickButton:FlxSprite;
    var playerKickText:FlxText;

    var playerData:Array<String> = [
        "► Oyuncu 1: Çevrimiçi (Ping: 12ms)",
        "► Oyuncu 2: Çevrimdışı",
        "► Oyuncu 3: Çevrimiçi (Ping: 24ms)"
    ];

    // ─── Ayarlar ───────────────────────────────────────────────
    var settingsGroup:FlxSpriteGroup;
    var settingsLines:Array<FlxText>  = [];
    var settingsScrollBar:FlxSprite;
    var settingsScrollThumb:FlxSprite;
    var settingsScrollOffset:Float    = 0;
    var settingsMaxOffset:Float       = 0;
    var settingsLineHeight:Float      = 26;
    var settingsSaveButton:FlxSprite;
    var settingsSaveText:FlxText;

    var settingsData:Array<String> = [
        "► Güncelleme Kontrolü: Açık",
        "► Konsol Logları: Açık",
        "► Hile Uyarısı: Açık",
        "► Otomatik Kaydet: Açık"
    ];

    // ═══════════════════════════════════════════════════════════════
    // OLUŞTURMA
    // ═══════════════════════════════════════════════════════════════
    public function new()
    {
        super();
        scrollFactor.set(0, 0);

        cheatStates = [
            "Bot-Play"     => false,
            "No Miss"      => false,
            "Sonsuz Omur"  => false,
            "Hız x2"       => false,
            "Görünmez Not" => false,
            "Oto Hit"      => false,
            "Sonsuz Skor"  => false
        ];

        buildBase();
        buildLogo();
        buildCategoryList();
        buildServerPanel();
        buildCheatPanel();
        buildConsolePanel();
        buildModPanel();
        buildPlayerPanel();
        buildSettingsPanel();
        buildHint();

        FlxG.mouse.visible = true;

        this.y       = -FlxG.height;
        this.alpha   = 0;
        this.visible = false;
    }

    // ═══════════════════════════════════════════════════════════════
    // BASE
    // ═══════════════════════════════════════════════════════════════
    function buildBase()
    {
        overlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, COL_OVERLAY);
        overlay.alpha = 1;
        overlay.scrollFactor.set(0, 0);
        add(overlay);

        panelBorder = new FlxSprite(PANEL_X - 3, PANEL_Y - 3)
            .makeGraphic(PANEL_W + 6, PANEL_H + 6, COL_PANEL_BORDER);
        panelBorder.alpha = 0.95;
        panelBorder.scrollFactor.set(0, 0);
        add(panelBorder);

        panelBG = new FlxSprite(PANEL_X, PANEL_Y)
            .makeGraphic(PANEL_W, PANEL_H, COL_PANEL_BG);
        panelBG.scrollFactor.set(0, 0);
        add(panelBG);

        // Sol taraf için hafif degrade efekti
        var lsTop = new FlxSprite(PANEL_X, PANEL_Y)
            .makeGraphic(LEFT_W, Std.int(PANEL_H * 0.55), COL_LEFT_BG_TOP);
        lsTop.scrollFactor.set(0, 0);
        add(lsTop);

        var lsBottom = new FlxSprite(PANEL_X, PANEL_Y + Std.int(PANEL_H * 0.55))
            .makeGraphic(LEFT_W, Std.int(PANEL_H * 0.45), COL_LEFT_BG_BOTTOM);
        lsBottom.scrollFactor.set(0, 0);
        add(lsBottom);

        // İnce parlama çizgisi
        var lsGlow = new FlxSprite(PANEL_X + LEFT_W - 3, PANEL_Y)
            .makeGraphic(3, PANEL_H, COL_DIVIDER);
        lsGlow.alpha = 0.4;
        lsGlow.scrollFactor.set(0, 0);
        add(lsGlow);

        // Eski tek parça paneli kullanmıyoruz
        var ls = new FlxSprite(PANEL_X, PANEL_Y).makeGraphic(LEFT_W, PANEL_H, 0x00000000);
        ls.scrollFactor.set(0, 0);
        add(ls);

        var dv = new FlxSprite(PANEL_X + LEFT_W, PANEL_Y).makeGraphic(2, PANEL_H, COL_DIVIDER);
        dv.alpha = 0.8;
        dv.scrollFactor.set(0, 0);
        add(dv);

        var ts = new FlxSprite(PANEL_X + LEFT_W + 2, PANEL_Y)
            .makeGraphic(PANEL_W - LEFT_W - 2, 70, COL_HEADER_BG);
        ts.scrollFactor.set(0, 0);
        add(ts);

        var tl = new FlxSprite(PANEL_X + LEFT_W + 2, PANEL_Y + 62)
            .makeGraphic(PANEL_W - LEFT_W - 2, 2, COL_HEADER_LINE);
        tl.alpha = 0.6;
        tl.scrollFactor.set(0, 0);
        add(tl);

        contentTitle = new FlxText(RIGHT_X, PANEL_Y + 72, RIGHT_W, "", 18);
        contentTitle.setFormat(Paths.font("vcr.ttf"), 18, COL_TEXT_ACCENT, LEFT,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        contentTitle.borderSize = 2;
        contentTitle.scrollFactor.set(0, 0);
        add(contentTitle);
    }

    // ═══════════════════════════════════════════════════════════════
    // LOGO
    // ═══════════════════════════════════════════════════════════════
    function buildLogo()
    {
        // Sol üst köşe: kompakt logo + başlık alanı
        try {
            logo = new FlxSprite().loadGraphic(Paths.image('pet/petlogo'));
            logo.antialiasing = ClientPrefs.data.antialiasing;
            logo.setGraphicSize(80);
            logo.updateHitbox();
        } catch(e:Dynamic) {
            logo = new FlxSprite(0, 0).makeGraphic(80, 80, 0xFF1a1a2e);
        }
        logo.x = PANEL_X + LEFT_W + 18;
        logo.y = PANEL_Y + 10;
        logo.scrollFactor.set(0, 0);
        add(logo);

        welcomeText = new FlxText(logo.x + logo.width + 10, PANEL_Y + 10,
            PANEL_W - (logo.x + logo.width + 30), "ULTRA KONTROL MERKEZI", 20);
        welcomeText.setFormat(Paths.font("vcr.ttf"), 20, COL_TEXT_ACCENT, LEFT,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        welcomeText.borderSize = 2;
        welcomeText.scrollFactor.set(0, 0);
        add(welcomeText);

        subTitleText = new FlxText(logo.x + logo.width + 10, PANEL_Y + 36,
            PANEL_W - (logo.x + logo.width + 30), "Psych Engine Türkiye • Admin Paneli", 13);
        subTitleText.setFormat(Paths.font("vcr.ttf"), 13, COL_TEXT_MUTED, LEFT);
        subTitleText.scrollFactor.set(0, 0);
        add(subTitleText);
    }

    // ═══════════════════════════════════════════════════════════════
    // KATEGORI LİSTESİ
    // ═══════════════════════════════════════════════════════════════
    function buildCategoryList()
    {
        var catLabels = ["SUNUCU", "HİLE", "KONSOL", "MODLAR", "OYUNCULAR", "AYARLAR"];
        var catH      = 54;
        var startY    = PANEL_Y + 90;

        // Sol üst başlık
        var leftTitle = new FlxText(PANEL_X + 16, PANEL_Y + 20, LEFT_W - 32, "YÖNETİM SEKMELESI", 11);
        leftTitle.setFormat(Paths.font("vcr.ttf"), 11, COL_TEXT_MUTED, LEFT);
        leftTitle.scrollFactor.set(0, 0);
        add(leftTitle);

        catSelector = new FlxSprite(PANEL_X + 10, startY)
            .makeGraphic(LEFT_W - 20, catH - 8, COL_PRIMARY);
        catSelector.alpha = 0.18;
        catSelector.scrollFactor.set(0, 0);
        add(catSelector);

        for (i in 0...catLabels.length)
        {
            var txt = new FlxText(PANEL_X + 36, startY + i * catH + 17,
                LEFT_W - 40, catLabels[i], 15);
            txt.setFormat(Paths.font("vcr.ttf"), 15, COL_TEXT_DIM, LEFT);
            txt.scrollFactor.set(0, 0);
            add(txt);
            catTexts.push(txt);

            // İkon ekleme
            var icon = new FlxSprite(PANEL_X + 16, startY + i * catH + 14);
            icon.makeGraphic(12, 12, COL_PRIMARY);
            icon.scrollFactor.set(0, 0);
            add(icon);
            catIcons.push(icon);
        }

        var ver = new FlxText(PANEL_X + 5, PANEL_Y + PANEL_H - 30,
            LEFT_W - 10, "XQ Edition V3 • Ultra-Pre 0.6", 10);
        ver.setFormat(Paths.font("vcr.ttf"), 10, COL_TEXT_MUTED, CENTER);
        ver.scrollFactor.set(0, 0);
        add(ver);

        updateCategoryVisuals();
    }

    // ═══════════════════════════════════════════════════════════════
    // SUNUCU PANELİ
    // ═══════════════════════════════════════════════════════════════
    function buildServerPanel()
    {
        serverGroup = new FlxSpriteGroup();
        serverGroup.scrollFactor.set(0, 0);

        var bg = new FlxSprite(RIGHT_X, CONTENT_TOP)
            .makeGraphic(RIGHT_W - 18, Std.int(VISIBLE_H), COL_CARD_BG);
        bg.alpha = 0.95;
        bg.scrollFactor.set(0, 0);
        serverGroup.add(bg);

        for (i in 0...serverData.length)
        {
            var t = new FlxText(RIGHT_X + 10,
                CONTENT_TOP + 8 + i * serverLineHeight,
                RIGHT_W - 36, serverData[i], 15);
            t.setFormat(Paths.font("vcr.ttf"), 15, COL_TEXT_DIM, LEFT);
            t.scrollFactor.set(0, 0);
            serverGroup.add(t);
            serverLines.push(t);
        }

        var totalH      = serverData.length * serverLineHeight + 8;
        serverMaxOffset = Math.max(0, totalH - VISIBLE_H);

        // Scrollbar arka plan
        serverScrollBar = new FlxSprite(RIGHT_X + RIGHT_W - 14, CONTENT_TOP)
            .makeGraphic(10, Std.int(VISIBLE_H), COL_SCROLL_TRACK);
        serverScrollBar.scrollFactor.set(0, 0);
        serverGroup.add(serverScrollBar);

        // Scrollbar thumb
        var thumbH = Std.int(Math.max(30, VISIBLE_H * (VISIBLE_H / totalH)));
        serverScrollThumb = new FlxSprite(RIGHT_X + RIGHT_W - 14, CONTENT_TOP)
            .makeGraphic(10, thumbH, COL_SCROLL_THUMB);
        serverScrollThumb.alpha = 1;
        serverScrollThumb.scrollFactor.set(0, 0);
        serverGroup.add(serverScrollThumb);

        // Ban butonu
        serverBanButton = new FlxSprite(RIGHT_X, PANEL_Y + PANEL_H - 50)
            .makeGraphic(180, 38, COL_DANGER_DARK);
        serverBanButton.scrollFactor.set(0, 0);
        serverGroup.add(serverBanButton);

        serverBanText = new FlxText(RIGHT_X, PANEL_Y + PANEL_H - 44,
            180, "OYUNCU BANLA", 14);
        serverBanText.setFormat(Paths.font("vcr.ttf"), 14, COL_DANGER, CENTER);
        serverBanText.scrollFactor.set(0, 0);
        serverGroup.add(serverBanText);

        // Yenile butonu
        serverRefreshButton = new FlxSprite(RIGHT_X + 190, PANEL_Y + PANEL_H - 50)
            .makeGraphic(180, 38, COL_PRIMARY_DARK);
        serverRefreshButton.scrollFactor.set(0, 0);
        serverGroup.add(serverRefreshButton);

        serverRefreshText = new FlxText(RIGHT_X + 190, PANEL_Y + PANEL_H - 44,
            180, "SUNUCUYU YENILE", 14);
        serverRefreshText.setFormat(Paths.font("vcr.ttf"), 14, COL_PRIMARY, CENTER);
        serverRefreshText.scrollFactor.set(0, 0);
        serverGroup.add(serverRefreshText);

        add(serverGroup);
        updateServerScroll();
    }

    // ═══════════════════════════════════════════════════════════════
    // HİLE PANELİ
    // ═══════════════════════════════════════════════════════════════
    function buildCheatPanel()
    {
        cheatGroup = new FlxSpriteGroup();
        cheatGroup.scrollFactor.set(0, 0);

        var startY = CONTENT_TOP + 10;
        var itemH  = 46;

        for (i in 0...cheatKeys.length)
        {
            var bg = new FlxSprite(RIGHT_X, startY + i * itemH)
                .makeGraphic(RIGHT_W, itemH - 4, (i % 2 == 0) ? COL_CARD_BG : COL_CARD_BG_ALT);
            bg.scrollFactor.set(0, 0);
            cheatGroup.add(bg);
            cheatItemBGs.push(bg);

            var txt = new FlxText(RIGHT_X + 14, startY + i * itemH + 10,
                RIGHT_W - 110, cheatKeys[i], 16);
            txt.setFormat(Paths.font("vcr.ttf"), 16, COL_TEXT_DIM, LEFT);
            txt.scrollFactor.set(0, 0);
            cheatGroup.add(txt);
            cheatItemTexts.push(txt);

            var status = new FlxText(RIGHT_X + RIGHT_W - 90, startY + i * itemH + 10,
                80, "KAPALI", 14);
            status.setFormat(Paths.font("vcr.ttf"), 14, COL_TEXT_MUTED, RIGHT);
            status.scrollFactor.set(0, 0);
            cheatGroup.add(status);
            cheatStatusTexts.push(status);
        }

        add(cheatGroup);
        updateCheatVisuals();
    }

    // ═══════════════════════════════════════════════════════════════
    // KONSOL PANELİ
    // ═══════════════════════════════════════════════════════════════
    function buildConsolePanel()
    {
        consoleGroup = new FlxSpriteGroup();
        consoleGroup.scrollFactor.set(0, 0);

        var bg = new FlxSprite(RIGHT_X, CONTENT_TOP)
            .makeGraphic(RIGHT_W - 18, Std.int(VISIBLE_H - 44), COL_CARD_BG);
        bg.scrollFactor.set(0, 0);
        consoleGroup.add(bg);

        var inputBG = new FlxSprite(RIGHT_X, PANEL_Y + PANEL_H - 88)
            .makeGraphic(RIGHT_W, 36, COL_CARD_BG_ALT);
        inputBG.scrollFactor.set(0, 0);
        consoleGroup.add(inputBG);

        var inputBorder = new FlxSprite(RIGHT_X, PANEL_Y + PANEL_H - 88)
            .makeGraphic(RIGHT_W, 2, 0xFF00E5FF);
        inputBorder.alpha = 0.4;
        inputBorder.scrollFactor.set(0, 0);
        consoleGroup.add(inputBorder);

        var prompt = new FlxText(RIGHT_X + 8, PANEL_Y + PANEL_H - 80, 24, ">", 16);
        prompt.setFormat(Paths.font("vcr.ttf"), 16, COL_TEXT_ACCENT, LEFT);
        prompt.scrollFactor.set(0, 0);
        consoleGroup.add(prompt);

        consoleCursor = new FlxText(RIGHT_X + 28, PANEL_Y + PANEL_H - 80,
            RIGHT_W - 36, "", 16);
        consoleCursor.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
        consoleCursor.scrollFactor.set(0, 0);
        consoleGroup.add(consoleCursor);

        add(consoleGroup);

        logToConsole("Sistem haziı. 'yardım' yazarak komutları gör.");
        logToConsole("XQ Edition V3 yüklendi.");
		logToConsole("Hata Bulundu - UltraCodeState'");
    }

    function rebuildConsoleTexts()
    {
        for (t in consoleLineTexts)
            consoleGroup.remove(t, true);
        consoleLineTexts = [];

        var lineH:Float = 22;
        for (i in 0...consoleLines.length)
        {
            var t = new FlxText(RIGHT_X + 8, CONTENT_TOP + 4 + i * lineH,
                RIGHT_W - 16, consoleLines[i], 13);
            var isErr = consoleLines[i].indexOf("HATA") >= 0
                     || consoleLines[i].indexOf("bilinmiyor") >= 0;
            t.setFormat(Paths.font("vcr.ttf"), 13,
                isErr ? 0xFFFF5555 : 0xFFAAAAAA, LEFT);
            t.scrollFactor.set(0, 0);
            consoleGroup.add(t);
            consoleLineTexts.push(t);
        }
    }

    public function logToConsole(msg:String)
    {
        var now  = Date.now();
        var time = StringTools.lpad(Std.string(now.getHours()),   "0", 2) + ":"
                 + StringTools.lpad(Std.string(now.getMinutes()), "0", 2) + ":"
                 + StringTools.lpad(Std.string(now.getSeconds()), "0", 2);
        consoleLines.push("[" + time + "] " + msg);
        if (consoleLines.length > maxConsoleLines) consoleLines.shift();
        rebuildConsoleTexts();
    }

	function runConsoleCommand(cmd:String)
	{
		cmd = StringTools.trim(cmd);
		if (cmd == "") return;
		logToConsole("> " + cmd);

		if (cmd.startsWith("/ban "))
		{
			var playerName = cmd.substr(5);
			logToConsole("Oyuncu '" + playerName + "' banlandı!");
			return;
		}

		switch (cmd.toLowerCase())
		{
			case "help":
				logToConsole("Komutlar: help, clear, version, score, fps, quit, /ban [oyuncu]");
			case "clear":
				consoleLines = [];
				rebuildConsoleTexts();
			case "version":
				logToConsole("XQ Edition V4 | Ultra-Pre 0.6");
			case "score":
				var s = FlxG.save.data.totalScore != null
					? Std.string(FlxG.save.data.totalScore) : "0";
				logToConsole("Toplam skor: " + s);
			case "fps":
				logToConsole("FPS: " + Math.round(1 / FlxG.elapsed));
			case "quit":
				logToConsole("Kapatılıyor...");
				closePanel();
			default:
				logToConsole("HATA: '" + cmd + "' bilinmiyor. 'help' dene.");
		}
	}


	function handleConsoleKeys()
	{
		if (FlxG.keys.justPressed.BACKSPACE)
		{
			if (consoleInput.length > 0)
			{
				consoleInput = consoleInput.substring(0, consoleInput.length - 1);
				updateCursorText();
			}
			FlxG.keys.reset(); 
			return;
		}

		if (FlxG.keys.justPressed.ENTER) {
			runConsoleCommand(consoleInput);
			consoleInput = "";
			updateCursorText();
			return;
		}

		// Basılan ilk tuşu al ve karakter karşılığını ekle
		var firstKey = FlxG.keys.firstJustPressed();
		if (firstKey != -1) 
		{
			var char = keyToChar(firstKey, FlxG.keys.pressed.SHIFT);
			if (char != "" && consoleInput.length < 40)
			{
				consoleInput += char;
				updateCursorText();
			}
		}
	}



    function updateCursorText()
    {
        consoleCursor.text = consoleInput;
    }

	function keyToChar(key:FlxKey, shift:Bool):String
	{
		switch (key)
		{
			case FlxKey.SEVEN: return shift ? "/" : "7"; // Türkçe Q klavye: Shift + 7
			case FlxKey.SLASH | FlxKey.NUMPADSLASH: return "/"; // Numpad veya İngilizce düzen
			case FlxKey.SPACE: return " ";
			case FlxKey.MINUS: return shift ? "_" : "-";
			case FlxKey.PERIOD: return shift ? ":" : ".";
			case FlxKey.COMMA: return shift ? ";" : ",";
			case FlxKey.ONE: return shift ? "!" : "1";
			case FlxKey.TWO: return shift ? "@" : "2";
			case FlxKey.THREE: return shift ? "#" : "3";
			case FlxKey.FOUR: return shift ? "$" : "4";
			case FlxKey.FIVE: return shift ? "%" : "5";
			case FlxKey.SIX: return shift ? "^" : "6";
			case FlxKey.EIGHT: return shift ? "*" : "8";
			case FlxKey.NINE: return shift ? "(" : "9";
			case FlxKey.ZERO: return shift ? ")" : "0";
			default: 
				// Harfler için otomatik dönüşüm
				var id:Int = cast key;
				if (id >= 65 && id <= 90) {
					var char = String.fromCharCode(id);
					return shift ? char.toUpperCase() : char.toLowerCase();
				}
		}
		return "";
	}



    // ═══════════════════════════════════════════════════════════════
    // MOD PANELİ
    // ═══════════════════════════════════════════════════════════════
    function buildModPanel()
    {
        modGroup = new FlxSpriteGroup();
        modGroup.scrollFactor.set(0, 0);

        var bg = new FlxSprite(RIGHT_X, CONTENT_TOP)
            .makeGraphic(RIGHT_W - 18, Std.int(VISIBLE_H), COL_CARD_BG);
        bg.alpha = 0.95;
        bg.scrollFactor.set(0, 0);
        modGroup.add(bg);

        for (i in 0...modData.length)
        {
            var t = new FlxText(RIGHT_X + 10,
                CONTENT_TOP + 8 + i * modLineHeight,
                RIGHT_W - 36, modData[i], 15);
            t.setFormat(Paths.font("vcr.ttf"), 15, COL_TEXT_DIM, LEFT);
            t.scrollFactor.set(0, 0);
            modGroup.add(t);
            modLines.push(t);
        }

        var totalH      = modData.length * modLineHeight + 8;
        modMaxOffset = Math.max(0, totalH - VISIBLE_H);

        // Scrollbar arka plan
        modScrollBar = new FlxSprite(RIGHT_X + RIGHT_W - 14, CONTENT_TOP)
            .makeGraphic(10, Std.int(VISIBLE_H), COL_SCROLL_TRACK);
        modScrollBar.scrollFactor.set(0, 0);
        modGroup.add(modScrollBar);

        // Scrollbar thumb
        var thumbH = Std.int(Math.max(30, VISIBLE_H * (VISIBLE_H / totalH)));
        modScrollThumb = new FlxSprite(RIGHT_X + RIGHT_W - 14, CONTENT_TOP)
            .makeGraphic(10, thumbH, COL_SCROLL_THUMB);
        modScrollThumb.alpha = 1;
        modScrollThumb.scrollFactor.set(0, 0);
        modGroup.add(modScrollThumb);

        // Yükle butonu
        modLoadButton = new FlxSprite(RIGHT_X, PANEL_Y + PANEL_H - 50)
            .makeGraphic(180, 38, COL_SUCCESS_DARK);
        modLoadButton.scrollFactor.set(0, 0);
        modGroup.add(modLoadButton);

        modLoadText = new FlxText(RIGHT_X, PANEL_Y + PANEL_H - 44,
            180, "MOD YÜKLE", 14);
        modLoadText.setFormat(Paths.font("vcr.ttf"), 14, COL_SUCCESS, CENTER);
        modLoadText.scrollFactor.set(0, 0);
        modGroup.add(modLoadText);

        // Kaldır butonu
        modUnloadButton = new FlxSprite(RIGHT_X + 190, PANEL_Y + PANEL_H - 50)
            .makeGraphic(180, 38, COL_WARNING_DARK);
        modUnloadButton.scrollFactor.set(0, 0);
        modGroup.add(modUnloadButton);

        modUnloadText = new FlxText(RIGHT_X + 190, PANEL_Y + PANEL_H - 44,
            180, "MOD KALDIR", 14);
        modUnloadText.setFormat(Paths.font("vcr.ttf"), 14, COL_WARNING, CENTER);
        modUnloadText.scrollFactor.set(0, 0);
        modGroup.add(modUnloadText);

        add(modGroup);
        updateModScroll();
    }

    // ═══════════════════════════════════════════════════════════════
    // OYUNCU PANELİ
    // ═══════════════════════════════════════════════════════════════
    function buildPlayerPanel()
    {
        playerGroup = new FlxSpriteGroup();
        playerGroup.scrollFactor.set(0, 0);

        var bg = new FlxSprite(RIGHT_X, CONTENT_TOP)
            .makeGraphic(RIGHT_W - 18, Std.int(VISIBLE_H), COL_CARD_BG);
        bg.alpha = 0.95;
        bg.scrollFactor.set(0, 0);
        playerGroup.add(bg);

        for (i in 0...playerData.length)
        {
            var t = new FlxText(RIGHT_X + 10,
                CONTENT_TOP + 8 + i * playerLineHeight,
                RIGHT_W - 36, playerData[i], 15);
            t.setFormat(Paths.font("vcr.ttf"), 15, COL_TEXT_DIM, LEFT);
            t.scrollFactor.set(0, 0);
            playerGroup.add(t);
            playerLines.push(t);
        }

        var totalH      = playerData.length * playerLineHeight + 8;
        playerMaxOffset = Math.max(0, totalH - VISIBLE_H);

        // Scrollbar arka plan
        playerScrollBar = new FlxSprite(RIGHT_X + RIGHT_W - 14, CONTENT_TOP)
            .makeGraphic(10, Std.int(VISIBLE_H), COL_SCROLL_TRACK);
        playerScrollBar.scrollFactor.set(0, 0);
        playerGroup.add(playerScrollBar);

        // Scrollbar thumb
        var thumbH = Std.int(Math.max(30, VISIBLE_H * (VISIBLE_H / totalH)));
        playerScrollThumb = new FlxSprite(RIGHT_X + RIGHT_W - 14, CONTENT_TOP)
            .makeGraphic(10, thumbH, COL_SCROLL_THUMB);
        playerScrollThumb.alpha = 1;
        playerScrollThumb.scrollFactor.set(0, 0);
        playerGroup.add(playerScrollThumb);

        // At butonu
        playerKickButton = new FlxSprite(RIGHT_X, PANEL_Y + PANEL_H - 50)
            .makeGraphic(180, 38, COL_DANGER_DARK);
        playerKickButton.scrollFactor.set(0, 0);
        playerGroup.add(playerKickButton);

        playerKickText = new FlxText(RIGHT_X, PANEL_Y + PANEL_H - 44,
            180, "OYUNCUYU AT", 14);
        playerKickText.setFormat(Paths.font("vcr.ttf"), 14, COL_DANGER, CENTER);
        playerKickText.scrollFactor.set(0, 0);
        playerGroup.add(playerKickText);

        add(playerGroup);
        updatePlayerScroll();
    }

    // ═══════════════════════════════════════════════════════════════
    // AYARLAR PANELİ
    // ═══════════════════════════════════════════════════════════════
    function buildSettingsPanel()
    {
        settingsGroup = new FlxSpriteGroup();
        settingsGroup.scrollFactor.set(0, 0);

        var bg = new FlxSprite(RIGHT_X, CONTENT_TOP)
            .makeGraphic(RIGHT_W - 18, Std.int(VISIBLE_H), COL_CARD_BG);
        bg.alpha = 0.95;
        bg.scrollFactor.set(0, 0);
        settingsGroup.add(bg);

        for (i in 0...settingsData.length)
        {
            var t = new FlxText(RIGHT_X + 10,
                CONTENT_TOP + 8 + i * settingsLineHeight,
                RIGHT_W - 36, settingsData[i], 15);
            t.setFormat(Paths.font("vcr.ttf"), 15, COL_TEXT_DIM, LEFT);
            t.scrollFactor.set(0, 0);
            settingsGroup.add(t);
            settingsLines.push(t);
        }

        var totalH      = settingsData.length * settingsLineHeight + 8;
        settingsMaxOffset = Math.max(0, totalH - VISIBLE_H);

        // Scrollbar arka plan
        settingsScrollBar = new FlxSprite(RIGHT_X + RIGHT_W - 14, CONTENT_TOP)
            .makeGraphic(10, Std.int(VISIBLE_H), COL_SCROLL_TRACK);
        settingsScrollBar.scrollFactor.set(0, 0);
        settingsGroup.add(settingsScrollBar);

        // Scrollbar thumb
        var thumbH = Std.int(Math.max(30, VISIBLE_H * (VISIBLE_H / totalH)));
        settingsScrollThumb = new FlxSprite(RIGHT_X + RIGHT_W - 14, CONTENT_TOP)
            .makeGraphic(10, thumbH, COL_SCROLL_THUMB);
        settingsScrollThumb.alpha = 1;
        settingsScrollThumb.scrollFactor.set(0, 0);
        settingsGroup.add(settingsScrollThumb);

        // Kaydet butonu
        settingsSaveButton = new FlxSprite(RIGHT_X, PANEL_Y + PANEL_H - 50)
            .makeGraphic(180, 38, COL_SUCCESS_DARK);
        settingsSaveButton.scrollFactor.set(0, 0);
        settingsGroup.add(settingsSaveButton);

        settingsSaveText = new FlxText(RIGHT_X, PANEL_Y + PANEL_H - 44,
            180, "AYARLARI KAYDET", 14);
        settingsSaveText.setFormat(Paths.font("vcr.ttf"), 14, COL_SUCCESS, CENTER);
        settingsSaveText.scrollFactor.set(0, 0);
        settingsGroup.add(settingsSaveText);

        add(settingsGroup);
        updateSettingsScroll();
    }

    // ═══════════════════════════════════════════════════════════════
    // HINT
    // ═══════════════════════════════════════════════════════════════
    function buildHint()
    {
        hintText = new FlxText(PANEL_X, PANEL_Y + PANEL_H - 22, PANEL_W,
            "Klavye: UP/DOWN gezin • ENTER onayla • SHIFT+UP/DOWN kategori • F2/ESC paneli kapat | Fare: Sol menüden kategori sec, tekerlek ile listeleri kaydir",
            11);
        hintText.setFormat(Paths.font("vcr.ttf"), 11, COL_TEXT_MUTED, CENTER);
        hintText.scrollFactor.set(0, 0);
        add(hintText);
    }

    // ═══════════════════════════════════════════════════════════════
    // SCROLL
    // ═══════════════════════════════════════════════════════════════
    function scrollServer(delta:Float)
    {
        serverScrollOffset = FlxMath.bound(serverScrollOffset + delta, 0, serverMaxOffset);
        updateServerScroll();
    }

    function updateServerScroll()
    {
        for (i in 0...serverLines.length)
        {
            var t    = serverLines[i];
            var rawY = CONTENT_TOP + 4 + i * serverLineHeight - serverScrollOffset;
            t.y      = rawY;
            t.visible = (rawY + serverLineHeight > CONTENT_TOP) && (rawY < CONTENT_BOT);
        }

        if (serverMaxOffset > 0)
        {
            var ratio  = serverScrollOffset / serverMaxOffset;
            var trackH = VISIBLE_H - serverScrollThumb.height;
            serverScrollThumb.y = CONTENT_TOP + ratio * trackH;
        }
    }

    function updateModScroll()
    {
        for (i in 0...modLines.length)
        {
            var t    = modLines[i];
            var rawY = CONTENT_TOP + 4 + i * modLineHeight - modScrollOffset;
            t.y      = rawY;
            t.visible = (rawY + modLineHeight > CONTENT_TOP) && (rawY < CONTENT_BOT);
        }

        if (modMaxOffset > 0)
        {
            var ratio  = modScrollOffset / modMaxOffset;
            var trackH = VISIBLE_H - modScrollThumb.height;
            modScrollThumb.y = CONTENT_TOP + ratio * trackH;
        }
    }

    function updatePlayerScroll()
    {
        for (i in 0...playerLines.length)
        {
            var t    = playerLines[i];
            var rawY = CONTENT_TOP + 4 + i * playerLineHeight - playerScrollOffset;
            t.y      = rawY;
            t.visible = (rawY + playerLineHeight > CONTENT_TOP) && (rawY < CONTENT_BOT);
        }

        if (playerMaxOffset > 0)
        {
            var ratio  = playerScrollOffset / playerMaxOffset;
            var trackH = VISIBLE_H - playerScrollThumb.height;
            playerScrollThumb.y = CONTENT_TOP + ratio * trackH;
        }
    }

    function updateSettingsScroll()
    {
        for (i in 0...settingsLines.length)
        {
            var t    = settingsLines[i];
            var rawY = CONTENT_TOP + 4 + i * settingsLineHeight - settingsScrollOffset;
            t.y      = rawY;
            t.visible = (rawY + settingsLineHeight > CONTENT_TOP) && (rawY < CONTENT_BOT);
        }

        if (settingsMaxOffset > 0)
        {
            var ratio  = settingsScrollOffset / settingsMaxOffset;
            var trackH = VISIBLE_H - settingsScrollThumb.height;
            settingsScrollThumb.y = CONTENT_TOP + ratio * trackH;
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // KATEGORİ
    // ═══════════════════════════════════════════════════════════════
    function changeCategory(dir:Int)
    {
        curCategory = (curCategory + dir + categories.length) % categories.length;
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        showCategory(curCategory);
        updateCategoryVisuals();
    }

    function showCategory(idx:Int)
    {
        serverGroup.visible  = (idx == 0);
        cheatGroup.visible   = (idx == 1);
        consoleGroup.visible = (idx == 2);
        modGroup.visible     = (idx == 3);
        playerGroup.visible  = (idx == 4);
        settingsGroup.visible = (idx == 5);

        var titles = [
            "SUNUCU BILGISI  (yukari/asagi: scroll | fare: teker)",
            "HILE AYARLARI   (yukari/asagi: sec | ENTER: ac/kapat | SHIFT+yon: kategori)",
            "KONSOL          (yaz + ENTER)",
            "MOD YÖNETIMI     (yukari/asagi: scroll | fare: teker)",
            "OYUNCU LISTESI   (yukari/asagi: scroll | fare: teker)",
            "AYARLAR          (yukari/asagi: scroll | fare: teker)"
        ];
        contentTitle.text = titles[idx];

        if (idx == 0) updateServerScroll();
        if (idx == 3) updateModScroll();
        if (idx == 4) updatePlayerScroll();
        if (idx == 5) updateSettingsScroll();
    }

    function updateCategoryVisuals()
    {
        var catH   = 54;
        var startY = PANEL_Y + 90;
        FlxTween.cancelTweensOf(catSelector);
        FlxTween.tween(catSelector, {y: startY + curCategory * catH}, 0.18, {ease: FlxEase.quadOut});

        for (i in 0...catTexts.length)
        {
            var selected = (i == curCategory);
            catTexts[i].color = selected ? COL_TEXT_ACCENT : COL_TEXT_DIM;
            catTexts[i].size  = selected ? 16 : 14;
            catIcons[i].color = selected ? COL_PRIMARY : COL_TEXT_MUTED;
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // HİLE
    // ═══════════════════════════════════════════════════════════════
    function changeCheat(dir:Int)
    {
        curCheat = (curCheat + dir + cheatKeys.length) % cheatKeys.length;
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.35);
        updateCheatVisuals();
    }

    function toggleCurrentCheat()
    {
        var key = cheatKeys[curCheat];
        cheatStates[key] = !cheatStates[key];
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
        applyCheat(key, cheatStates[key]);
        updateCheatVisuals();
    }

    function applyCheat(key:String, active:Bool)
    {
        switch (key)
        {
            case "Bot-Play":
                if (PlayState.instance != null)
                    PlayState.instance.cpuControlled = active;
                logToConsole("Bot-Play -> " + (active ? "ACIK" : "KAPALI"));
            default:
                logToConsole(key + " -> " + (active ? "ACIK" : "KAPALI"));
        }
    }

    function updateCheatVisuals()
    {
        for (i in 0...cheatKeys.length)
        {
            var key = cheatKeys[i];
            var on  = cheatStates[key];
            var sel = (i == curCheat);

            cheatItemBGs[i].color    = sel ? (on ? 0xFF0a1f0a : 0xFF12082a) : 0xFF0d0d1a;
            cheatItemBGs[i].alpha    = sel ? 1.0 : 0.75;
            cheatItemTexts[i].color  = sel ? FlxColor.WHITE : 0xFF666688;
            cheatStatusTexts[i].text  = on  ? "ACIK"  : "KAPALI";
            cheatStatusTexts[i].color = on  ? 0xFF10B981 : 0xFF334455;
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // AÇMA / KAPAMA
    // ═══════════════════════════════════════════════════════════════
    public function openPanel()
    {
        if (isOpen) return;
        isOpen       = true;
        this.visible = true;
        this.y       = -FlxG.height;
        this.alpha   = 0;

        FlxG.mouse.visible = true;
        FlxTween.cancelTweensOf(this);
        FlxTween.tween(this, {y: 0, alpha: 1}, 0.45, {ease: FlxEase.backOut});
        logToConsole("Panel acildi.");
    }

    public function closePanel()
    {
        if (!isOpen) return;
        FlxTween.cancelTweensOf(this);
        FlxTween.tween(this, {y: -FlxG.height, alpha: 0}, 0.35, {
            ease: FlxEase.backIn,
            onComplete: function(_) {
                isOpen       = false;
                this.visible = false;
            }
        });
    }

    // ═══════════════════════════════════════════════════════════════
    // INPUT
    // ═══════════════════════════════════════════════════════════════
	public function handleInput(controls:backend.Controls)
	{
		if (!isOpen) return;

		// SHIFT + yön = her zaman kategori değiştir
		if (FlxG.keys.pressed.SHIFT)
		{
			if (controls.UI_UP_P)   changeCategory(-1);
			if (controls.UI_DOWN_P) changeCategory(1);
			return;
		}

		switch (curCategory)
		{
			case 0: // Sunucu — UP/DOWN scroll yapar
				if (controls.UI_UP_P)   scrollServer(-serverLineHeight);
				if (controls.UI_DOWN_P) scrollServer(serverLineHeight);

			case 1: // Hile — UP/DOWN hile seçer, ENTER toggle
				if (controls.UI_UP_P)   changeCheat(-1);
				if (controls.UI_DOWN_P) changeCheat(1);
				if (controls.ACCEPT)    toggleCurrentCheat();

			case 2: // Konsol — klavye girişi + ENTER çalıştır
				handleConsoleKeys();
				// Sadece ENTER tuşuna basıldığında komut çalışsın, Space'e basınca çalışmasın
				if (FlxG.keys.justPressed.ENTER)
				{
					runConsoleCommand(consoleInput);
					consoleInput = "";
					updateCursorText();
				}

			case 3: // Modlar — UP/DOWN scroll yapar
				if (controls.UI_UP_P)   modScrollOffset = FlxMath.bound(modScrollOffset - modLineHeight, 0, modMaxOffset);
				if (controls.UI_DOWN_P) modScrollOffset = FlxMath.bound(modScrollOffset + modLineHeight, 0, modMaxOffset);
				updateModScroll();

			case 4: // Oyuncular — UP/DOWN scroll yapar
				if (controls.UI_UP_P)   playerScrollOffset = FlxMath.bound(playerScrollOffset - playerLineHeight, 0, playerMaxOffset);
				if (controls.UI_DOWN_P) playerScrollOffset = FlxMath.bound(playerScrollOffset + playerLineHeight, 0, playerMaxOffset);
				updatePlayerScroll();

			case 5: // Ayarlar — UP/DOWN scroll yapar
				if (controls.UI_UP_P)   settingsScrollOffset = FlxMath.bound(settingsScrollOffset - settingsLineHeight, 0, settingsMaxOffset);
				if (controls.UI_DOWN_P) settingsScrollOffset = FlxMath.bound(settingsScrollOffset + settingsLineHeight, 0, settingsMaxOffset);
				updateSettingsScroll();
		}
	}



    public function handleUpdate(elapsed:Float)
    {
        if (!isOpen) return;

        // Mouse scroll (sunucu paneli)
        if (curCategory == 0 && FlxG.mouse.wheel != 0)
            scrollServer(-FlxG.mouse.wheel * serverLineHeight * 1.5);

        if (curCategory == 0)
            updateServerScroll();

        // Konsol imleç blink
        if (curCategory == 2)
        {
            consoleBlink += elapsed;
            if (consoleBlink > 0.5) consoleBlink = 0;
            consoleCursor.text = consoleInput + (consoleBlink < 0.25 ? "_" : "");
        }

        // Ban butonu hover
        if (curCategory == 0 && serverBanButton != null)
        {
            if (FlxG.mouse.overlaps(serverBanButton))
            {
                serverBanButton.color = COL_DANGER;
                serverBanButton.scale.set(1.04, 1.04);
                if (FlxG.mouse.justPressed)
                {
                    FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
                    logToConsole("HATA: Baglantiyi oyuncu yok, ban uygulanamadi.");
                    curCategory = 2;
                    showCategory(2);
                    updateCategoryVisuals();
                }
            }
            else
            {
                serverBanButton.color = COL_DANGER_DARK;
                serverBanButton.scale.set(1, 1);
            }
        }

        // Mouse ile kategori tıklama
        var catH   = 54;
        var startY = PANEL_Y + 90;
        for (i in 0...categories.length)
        {
            var ty = startY + i * catH;
            if (FlxG.mouse.x >= PANEL_X && FlxG.mouse.x <= PANEL_X + LEFT_W
            &&  FlxG.mouse.y >= ty       && FlxG.mouse.y <= ty + catH
            &&  FlxG.mouse.justPressed)
            {
                curCategory = i;
                showCategory(i);
                updateCategoryVisuals();
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // BEAT SYNC
    // ═══════════════════════════════════════════════════════════════
    public function onBeat()
    {
        if (!isOpen || logo == null) return;
        logo.scale.set(1.07, 1.07);
        FlxTween.cancelTweensOf(logo.scale);
        FlxTween.tween(logo.scale, {x: 1.0, y: 1.0}, 0.28, {ease: FlxEase.quadOut});
    }
}
