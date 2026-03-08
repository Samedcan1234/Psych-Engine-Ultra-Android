package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.ui.FlxBar;
import flixel.addons.transition.FlxTransitionableState;
import lime.app.Application;

/**
 * Psych Engine Ultra - UpdateState.hx
 * 
 * Güncelleme indirme ve uygulama ekranı.
 * OutdatedState'den "Evet" butonuna basılınca bu state açılır.
 * 
 * Akış:
 *   1. Ekran açılır, "İndiriliyor..." mesajı gösterilir
 *   2. ZIP indirilir, progress bar güncellenir
 *   3. "Uygulanıyor..." aşamasına geçilir
 *   4. ZIP çıkarılır ve dosyalar oyunun üzerine yazılır
 *   5. "Tamamlandı! Oyun kapanıyor..." mesajı gösterilir
 *   6. Oyun kapanır, kullanıcı yeniden açar → yeni sürüm yüklenmiş olur
 */
class UpdateState extends MusicBeatState
{
	// =============================================
	// UI ELEMENTLERİ
	// =============================================

	/** Arka plan karartması */
	var bg:FlxSprite;

	/** Ana durum metni ("İndiriliyor...", "Uygulanıyor..." vb.) */
	var statusText:FlxText;

	/** Alt detay metni (dosya adı, hız, boyut vb.) */
	var detailText:FlxText;

	/** İlerleme çubuğu arka planı */
	var progressBarBG:FlxSprite;

	/** İlerleme çubuğu (FlxBar) */
	var progressBar:FlxBar;

	/** Yüzde metni */
	var percentText:FlxText;

	/** Logo veya ikon (opsiyonel) */
	var logo:FlxSprite;

	/** Hata mesajı butonu (hata varsa gözükür) */
	var retryText:FlxText;

	// =============================================
	// DURUM DEĞİŞKENLERİ
	// =============================================

	/** Mevcut aşama */
	var currentPhase:UpdatePhase = DOWNLOADING;

	/** İlerleme değeri (0.0 - 1.0) */
	var progressValue:Float = 0.0;

	/** Hata oluştu mu? */
	var hasError:Bool = false;

	/** İşlem tamamlandı mı? */
	var isComplete:Bool = false;

	/** Kapanma sayacı (tamamlandıktan sonra geri sayım) */
	var closeTimer:Float = 4.0;

	/** Geri sayım başladı mı? */
	var countdownStarted:Bool = false;

	/** Retry için kaç kere denendi */
	var retryCount:Int = 0;

	/** Maks retry sayısı */
	static final MAX_RETRY:Int = 3;

	// =============================================
	// CREATE
	// =============================================

	override function create()
	{
		super.create();

		// Müziği durdur
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		buildUI();
		startDownload();
	}

	// =============================================
	// UI OLUŞTURMA
	// =============================================

	function buildUI():Void
	{
		// Koyu arka plan
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(15, 15, 25));
		add(bg);

		// Üst dekorasyon çizgisi
		var topLine = new FlxSprite(0, 0).makeGraphic(FlxG.width, 4, FlxColor.fromRGB(100, 180, 255));
		add(topLine);

		// Alt dekorasyon çizgisi
		var bottomLine = new FlxSprite(0, FlxG.height - 4).makeGraphic(FlxG.width, 4, FlxColor.fromRGB(100, 180, 255));
		add(bottomLine);

		// Başlık
		var titleText = new FlxText(0, 40, FlxG.width, "Psych Engine Ultra", 36);
		titleText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.fromRGB(0, 80, 160));
		titleText.screenCenter(X);
		add(titleText);

		// Alt başlık
		var subtitleText = new FlxText(0, 90, FlxG.width, "Güncelleme Yükleniyor", 20);
		subtitleText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.fromRGB(180, 210, 255), CENTER);
		subtitleText.screenCenter(X);
		add(subtitleText);

		// Progress bar arka planı
		var barY:Float = FlxG.height / 2 - 20;
		var barW:Float = FlxG.width - 160;
		var barH:Float = 36;
		var barX:Float = 80;

		progressBarBG = new FlxSprite(barX - 3, barY - 3).makeGraphic(Std.int(barW + 6), Std.int(barH + 6), FlxColor.fromRGB(60, 60, 80));
		add(progressBarBG);

		// Progress bar (FlxBar ile)
		progressBar = new FlxBar(barX, barY, LEFT_TO_RIGHT, Std.int(barW), Std.int(barH), this, "progressValue", 0, 1);
		progressBar.createFilledBar(FlxColor.fromRGB(30, 30, 50), FlxColor.fromRGB(80, 160, 255));
		add(progressBar);

		// Yüzde metni
		percentText = new FlxText(0, barY + barH + 12, FlxG.width, "%0", 18);
		percentText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.fromRGB(150, 200, 255), CENTER);
		add(percentText);

		// Ana durum metni
		statusText = new FlxText(0, FlxG.height / 2 - 90, FlxG.width, "Bağlanıyor...", 22);
		statusText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		add(statusText);

		// Detay metni
		detailText = new FlxText(0, FlxG.height / 2 + 60, FlxG.width, "", 16);
		detailText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.fromRGB(160, 160, 180), CENTER);
		add(detailText);

		// Retry / hata metni (başta gizli)
		retryText = new FlxText(0, FlxG.height - 80, FlxG.width, "", 18);
		retryText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.fromRGB(255, 100, 100), CENTER);
		retryText.alpha = 0;
		add(retryText);

		// Alt bilgi
		var infoText = new FlxText(0, FlxG.height - 40, FlxG.width, "Güncelleme sırasında oyunu kapatmayın!", 14);
		infoText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.fromRGB(120, 120, 140), CENTER);
		add(infoText);
	}

	// =============================================
	// İNDİRME BAŞLAT
	// =============================================

	function startDownload():Void
	{
		currentPhase = DOWNLOADING;
		progressValue = 0.0;

		var url:String = UpdaterUtil.getDownloadURL();
		var platform:String = UpdaterUtil.isAndroid() ? "Android" : "Windows";

		setStatus('İndiriliyor... ($platform)');
		setDetail('URL: $url');

		UpdaterUtil.downloadUpdate(
			url,
			// İlerleme callback'i
			function(progress:Float, received:Int, total:Int)
			{
				progressValue = progress;
				var receivedStr = UpdaterUtil.formatBytes(received);
				var totalStr = total > 0 ? UpdaterUtil.formatBytes(total) : "?";
				setDetail('$receivedStr / $totalStr');
				percentText.text = "%" + Std.string(Math.floor(progress * 100));
			},
			// Tamamlandı callback'i
			function(zipPath:String)
			{
				setDetail('ZIP indirildi: $zipPath');
				progressValue = 1.0;
				percentText.text = "%100";

				// Kısa bekleme sonrası uygulama aşamasına geç
				new flixel.util.FlxTimer().start(0.8, function(_) {
					startApply(zipPath);
				});
			},
			// Hata callback'i
			function(error:String)
			{
				onError(error);
			}
		);
	}

	// =============================================
	// UYGULAMA BAŞLAT
	// =============================================

	function startApply(zipPath:String):Void
	{
		currentPhase = APPLYING;
		progressValue = 0.0;
		percentText.text = "%0";

		setStatus("Güncelleme Uygulanıyor...");
		setDetail("Dosyalar değiştiriliyor, lütfen bekleyin...");

		UpdaterUtil.applyUpdate(
			zipPath,
			// İlerleme callback'i
			function(progress:Float, fileName:String)
			{
				progressValue = progress;
				percentText.text = "%" + Std.string(Math.floor(progress * 100));

				// Uzun dosya adlarını kısalt
				var shortName = fileName.length > 50 ? "..." + fileName.substr(fileName.length - 47) : fileName;
				setDetail('Uygulanıyor: $shortName');
			},
			// Tamamlandı callback'i
			function()
			{
				onUpdateComplete();
			},
			// Hata callback'i
			function(error:String)
			{
				onError(error);
			}
		);
	}

	// =============================================
	// TAMAMLANMA
	// =============================================

	function onUpdateComplete():Void
	{
		currentPhase = COMPLETE;
		isComplete = true;
		progressValue = 1.0;
		percentText.text = "%100";

		// Progress bar'ı yeşile çevir
		progressBar.createFilledBar(FlxColor.fromRGB(20, 50, 20), FlxColor.fromRGB(60, 200, 80));

		setStatus("✓ Güncelleme Tamamlandı!");
		setDetail("Psych Engine Ultra başarıyla güncellendi.");

		// Geri sayım başlat
		countdownStarted = true;
		retryText.alpha = 1;
		retryText.color = FlxColor.fromRGB(100, 255, 120);
	}

	// =============================================
	// HATA YÖNETİMİ
	// =============================================

	function onError(error:String):Void
	{
		hasError = true;
		currentPhase = ERROR;

		// Progress bar'ı kırmızıya çevir
		progressBar.createFilledBar(FlxColor.fromRGB(50, 10, 10), FlxColor.fromRGB(220, 60, 60));

		setStatus("✗ Hata Oluştu!");
		setDetail(error.length > 80 ? error.substr(0, 77) + "..." : error);

		if (retryCount < MAX_RETRY)
		{
			retryText.text = '[ENTER] Tekrar Dene  ($retryCount/$MAX_RETRY)  |  [ESC] İptal Et';
		}
		else
		{
			retryText.text = 'Maksimum deneme sayısına ulaşıldı. [ESC] ile çıkın.';
		}

		FlxTween.tween(retryText, {alpha: 1}, 0.3);
	}

	// =============================================
	// UPDATE DÖNGÜSÜ
	// =============================================

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Tamamlandı geri sayımı
		if (countdownStarted && isComplete)
		{
			closeTimer -= elapsed;
			retryText.text = 'Oyun ${Std.string(Math.ceil(closeTimer))} saniye içinde kapanacak...';

			if (closeTimer <= 0)
			{
				retryText.text = "Kapanıyor...";
				countdownStarted = false;

				// Kısa bekle sonra kapat
				new flixel.util.FlxTimer().start(0.5, function(_) {
					UpdaterUtil.restartGame();
				});
			}
		}

		// Hata durumunda input kontrolü
		if (hasError && !isComplete)
		{
			// Tekrar dene
			if (FlxG.keys.justPressed.ENTER && retryCount < MAX_RETRY)
			{
				retryCount++;
				hasError = false;
				FlxTween.tween(retryText, {alpha: 0}, 0.2);
				startDownload();
			}

			// İptal et / geri dön
			if (FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justReleased.BACK #end)
			{
				FlxG.switchState(new MainMenuState());
			}
		}
	}

	// =============================================
	// YARDIMCI SETTER'LAR
	// =============================================

	/** Ana durum metnini ayarlar */
	function setStatus(msg:String):Void
	{
		statusText.text = msg;
	}

	/** Detay metnini ayarlar */
	function setDetail(msg:String):Void
	{
		detailText.text = msg;
	}
}

// =============================================
// ENUM: Güncelleme Aşamaları
// =============================================
enum UpdatePhase
{
	DOWNLOADING;
	APPLYING;
	COMPLETE;
	ERROR;
}
