package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.input.keyboard.FlxKey;

/**
 * Psych Engine Ultra - OutdatedState.hx
 *
 * Oyun açıldığında sürüm kontrolü yapılır.
 * Eğer güncelleme mevcutsa bu ekran gösterilir.
 *
 * Kullanıcıya 2 seçenek sunulur:
 *   [ENTER] → Güncelle  → UpdateState.hx açılır, güncelleme indirilir
 *   [ESC]   → Geç       → MainMenuState açılır (eski sürümle devam eder)
 *
 * Bu dosyayı projenizin source/states/ klasörüne koyun.
 * Mevcut OutdatedState.hx'in YERİNE GEÇİRİN.
 */
class OutdatedState extends MusicBeatState
{
	// =============================================
	// VERSİYON BİLGİLERİ
	// =============================================

	/**
	 * Mevcut oyun sürümü.
	 * Her güncellemede bu değeri artır!
	 * Örnek: "1.0.0" → "1.0.1" → "1.1.0"
	 */
	public static var curVersion:String = "1.0.4";

	/**
	 * GitHub'dan çekilen en son sürüm.
	 * Bu değer MainMenuState veya TitleState tarafından doldurulur.
	 * Doldurma kodu aşağıda açıklanmıştır.
	 */
	public static var onlineVersion:String = "";

	// =============================================
	// UI DEĞİŞKENLERİ
	// =============================================

	var bg:FlxSprite;
	var titleText:FlxText;
	var versionText:FlxText;
	var descText:FlxText;
	var updateBtn:FlxText;
	var skipBtn:FlxText;
	var selectedOption:Int = 0; // 0 = Güncelle, 1 = Geç

	var optionTweenRunning:Bool = false;
	var initialized:Bool = false;

	// =============================================
	// CREATE
	// =============================================

	override function create()
	{
		super.create();

		// Arka plan
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(15, 15, 25));
		bg.alpha = 0;
		add(bg);

		// Üst çizgi dekorasyonu
		var topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 5, FlxColor.fromRGB(255, 160, 40));
		add(topBar);

		// Uyarı ikonu metni
		var warnIcon = new FlxText(0, 60, FlxG.width, "⚠", 60);
		warnIcon.setFormat(Paths.font("vcr.ttf"), 60, FlxColor.fromRGB(255, 200, 50), CENTER);
		warnIcon.alpha = 0;
		add(warnIcon);

		// Başlık
		titleText = new FlxText(0, 140, FlxG.width, "Güncelleme Mevcut!", 38);
		titleText.setFormat(Paths.font("vcr.ttf"), 38, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.fromRGB(120, 60, 0));
		titleText.alpha = 0;
		add(titleText);

		// Sürüm bilgisi
		var versionStr:String = 'Mevcut Sürüm: v$curVersion  →  Yeni Sürüm: v$onlineVersion';
		versionText = new FlxText(0, 210, FlxG.width, versionStr, 20);
		versionText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.fromRGB(200, 200, 200), CENTER);
		versionText.alpha = 0;
		add(versionText);

		// Açıklama
		descText = new FlxText(0, 270, FlxG.width, 
			"Psych Engine Ultra için yeni bir güncelleme hazır!\n" +
			"Güncellemek ister misin?\n\n" +
			"Güncelleme otomatik olarak indirilip yüklenecek.\n" +
			"Tamamlandığında oyun yeniden başlayacak.",
			18);
		descText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.fromRGB(180, 180, 200), CENTER);
		descText.alpha = 0;
		add(descText);

		// Güncelle butonu
		updateBtn = new FlxText(0, FlxG.height - 180, FlxG.width, "[ GÜNCELLE ]", 28);
		updateBtn.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.fromRGB(80, 200, 100), CENTER, FlxTextBorderStyle.SHADOW, FlxColor.fromRGB(0, 60, 20));
		updateBtn.alpha = 0;
		add(updateBtn);

		// Geç butonu
		skipBtn = new FlxText(0, FlxG.height - 120, FlxG.width, "[ GEÇ - Eski Sürümle Devam Et ]", 20);
		skipBtn.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.fromRGB(180, 180, 180), CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		skipBtn.alpha = 0;
		add(skipBtn);

		// Klavye ipucu
		var hintText = new FlxText(0, FlxG.height - 50, FlxG.width, "↑↓ Seç    ENTER Onayla    ESC Geç", 14);
		hintText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.fromRGB(100, 100, 120), CENTER);
		add(hintText);

		// Giriş animasyonu
		FlxTween.tween(bg, {alpha: 1}, 0.4);
		FlxTween.tween(warnIcon, {alpha: 1}, 0.5, {startDelay: 0.1});
		FlxTween.tween(titleText, {alpha: 1}, 0.5, {startDelay: 0.2});
		FlxTween.tween(versionText, {alpha: 1}, 0.5, {startDelay: 0.3});
		FlxTween.tween(descText, {alpha: 1}, 0.5, {startDelay: 0.4});
		FlxTween.tween(updateBtn, {alpha: 1}, 0.5, {startDelay: 0.5});
		FlxTween.tween(skipBtn, {alpha: 1}, 0.5, {startDelay: 0.6, onComplete: function(_) {
			initialized = true;
			updateSelection();
		}});
	}

	// =============================================
	// UPDATE DÖNGÜSÜ
	// =============================================

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!initialized)
			return;

		// Yukarı / Aşağı navigasyon
		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		// ENTER: Seçilen seçeneği uygula
		if (controls.ACCEPT)
		{
			if (selectedOption == 0)
			{
				// Güncelle seçildi → UpdateState'e geç
				initialized = false; // Input'u dondur
				FlxTween.tween(bg, {alpha: 0}, 0.3, {onComplete: function(_) {
					FlxG.switchState(new UpdateState());
				}});
			}
			else
			{
				// Geç seçildi → Ana menüye geç
				goToMainMenu();
			}
		}

		// ESC: Direkt geç
		if (controls.BACK #if android || FlxG.android.justReleased.BACK #end)
			goToMainMenu();
	}

	// =============================================
	// YARDIMCI FONKSİYONLAR
	// =============================================

	function changeSelection(dir:Int):Void
	{
		selectedOption = (selectedOption + dir + 2) % 2;
		FlxG.sound.play(Paths.sound('scrollMenu'));
		updateSelection();
	}

	function updateSelection():Void
	{
		// Seçili olan parlar, seçili olmayan solar
		if (selectedOption == 0)
		{
			updateBtn.color = FlxColor.fromRGB(80, 255, 120);
			updateBtn.scale.set(1.05, 1.05);
			skipBtn.color = FlxColor.fromRGB(120, 120, 120);
			skipBtn.scale.set(1.0, 1.0);
		}
		else
		{
			updateBtn.color = FlxColor.fromRGB(60, 160, 80);
			updateBtn.scale.set(1.0, 1.0);
			skipBtn.color = FlxColor.WHITE;
			skipBtn.scale.set(1.05, 1.05);
		}
	}

	function goToMainMenu():Void
	{
		initialized = false;
		FlxTween.tween(bg, {alpha: 0}, 0.3, {onComplete: function(_) {
			FlxG.switchState(new MainMenuState());
		}});
	}
}

/*
 * =============================================
 * KURULUM TALİMATLARI
 * =============================================
 *
 * 1. Bu dosyayı: source/states/OutdatedState.hx olarak kaydet
 *    (mevcut OutdatedState.hx'in YERİNE GEÇİR)
 *
 * 2. UpdateState.hx → source/states/UpdateState.hx
 *
 * 3. UpdaterUtil.hx → source/states/UpdaterUtil.hx
 *
 * 4. UpdaterUtil.hx içindeki şu satırları doldur:
 *    public static var GITHUB_USER:String = "senin_kullanici_adin";
 *    public static var GITHUB_REPO:String = "psych-engine-ultra";
 *
 * 5. VERSİYON KONTROLÜ için TitleState.hx veya MainMenuState.hx'e şunu ekle:
 *
 *    // Oyun başlarken GitHub'dan sürüm kontrol et
 *    var http = new haxe.Http("https://api.github.com/repos/KULLANICIN/psych-engine-ultra/releases/latest");
 *    http.addHeader("User-Agent", "PsychEngineUltra");
 *    http.onData = function(data:String) {
 *        var json = haxe.Json.parse(data);
 *        var latestTag:String = json.tag_name;
 *        // "v" prefix'ini kaldır (örn: "v1.0.5" → "1.0.5")
 *        if (latestTag.charAt(0) == "v")
 *            latestTag = latestTag.substr(1);
 *        OutdatedState.onlineVersion = latestTag;
 *        if (latestTag != OutdatedState.curVersion)
 *            FlxG.switchState(new OutdatedState());
 *    };
 *    http.request(false);
 *
 * 6. GitHub Releases'a güncelleme yüklerken:
 *    - Windows için: GUNCELLEME-windows.zip adıyla yükle
 *    - Android için: GUNCELLEME-android.zip adıyla yükle
 *    - ZIP içeriği: Oyunun export edilmiş tüm dosyaları
 *    - Tag adı: "v1.0.5", "v1.1.0" gibi versiyon numarası
 *
 * 7. OutdatedState.curVersion'ı her güncellemede artırmayı unutma!
 * =============================================
 */
