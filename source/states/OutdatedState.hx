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
 */
class OutdatedState extends MusicBeatState
{
	public static var curVersion:String = "0.1.3";
	public static var onlineVersion:String = "";

	var bg:FlxSprite;
	var titleText:FlxText;
	var versionText:FlxText;
	var descText:FlxText;
	var updateBtn:FlxText;
	var skipBtn:FlxText;
	var selectedOption:Int = 0; // 0 = Güncelle, 1 = Geç

	var optionTweenRunning:Bool = false;
	var initialized:Bool = false;

	override function create()
	{
		super.create();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(15, 15, 25));
		bg.alpha = 0;
		add(bg);

		var topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 5, FlxColor.fromRGB(255, 160, 40));
		add(topBar);

		var warnIcon = new FlxText(0, 60, FlxG.width, "⚠", 60);
		warnIcon.setFormat(Paths.font("vcr.ttf"), 60, FlxColor.fromRGB(255, 200, 50), CENTER);
		warnIcon.alpha = 0;
		add(warnIcon);

		titleText = new FlxText(0, 140, FlxG.width, "Güncelleme Mevcut!", 38);
		titleText.setFormat(Paths.font("vcr.ttf"), 38, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.fromRGB(120, 60, 0));
		titleText.alpha = 0;
		add(titleText);

		var versionStr:String = 'Mevcut Sürüm: v$curVersion  →  Yeni Sürüm: v$onlineVersion';
		versionText = new FlxText(0, 210, FlxG.width, versionStr, 20);
		versionText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.fromRGB(200, 200, 200), CENTER);
		versionText.alpha = 0;
		add(versionText);

		descText = new FlxText(0, 270, FlxG.width, 
			"Psych Engine Ultra için yeni bir güncelleme hazır!\n" +
			"Güncellemek ister misin?\n\n" +
			"Güncelleme otomatik olarak indirilip yüklenecek.\n" +
			"Tamamlandığında oyun yeniden başlayacak.",
			18);
		descText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.fromRGB(180, 180, 200), CENTER);
		descText.alpha = 0;
		add(descText);

		updateBtn = new FlxText(0, FlxG.height - 180, FlxG.width, "[ GÜNCELLE ]", 28);
		updateBtn.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.fromRGB(80, 200, 100), CENTER, FlxTextBorderStyle.SHADOW, FlxColor.fromRGB(0, 60, 20));
		updateBtn.alpha = 0;
		add(updateBtn);

		skipBtn = new FlxText(0, FlxG.height - 120, FlxG.width, "[ GEÇ - Eski Sürümle Devam Et ]", 20);
		skipBtn.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.fromRGB(180, 180, 180), CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		skipBtn.alpha = 0;
		add(skipBtn);

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

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!initialized)
			return;

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

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
				goToMainMenu();
			}
		}

		// ESC: Direkt geç
		if (controls.BACK #if android || FlxG.android.justReleased.BACK #end)
			goToMainMenu();
	}

	function changeSelection(dir:Int):Void
	{
		selectedOption = (selectedOption + dir + 2) % 2;
		FlxG.sound.play(Paths.sound('scrollMenu'));
		updateSelection();
	}

	function updateSelection():Void
	{
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
 *    public static var GITHUB_USER:String = "Samedcan1234";
 *    public static var GITHUB_REPO:String = "Psych-Engine-Ultra";
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
