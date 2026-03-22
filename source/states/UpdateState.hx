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

class UpdateState extends MusicBeatState
{
	var bg:FlxSprite;
	var statusText:FlxText;
	var detailText:FlxText;
	var progressBarBG:FlxSprite;
	var progressBar:FlxBar;
	var percentText:FlxText;
	var logo:FlxSprite;
	var retryText:FlxText;

	var currentPhase:UpdatePhase = DOWNLOADING;
	var progressValue:Float = 0.0;
	var hasError:Bool = false;
	var isComplete:Bool = false;
	var closeTimer:Float = 4.0;
	var countdownStarted:Bool = false;
	var retryCount:Int = 0;
	static final MAX_RETRY:Int = 3;

	override function create()
	{
		super.create();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		buildUI();
		startDownload();
	}

	function buildUI():Void
	{
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(15, 15, 25));
		add(bg);

		var topLine = new FlxSprite(0, 0).makeGraphic(FlxG.width, 4, FlxColor.fromRGB(100, 180, 255));
		add(topLine);

		var bottomLine = new FlxSprite(0, FlxG.height - 4).makeGraphic(FlxG.width, 4, FlxColor.fromRGB(100, 180, 255));
		add(bottomLine);

		var titleText = new FlxText(0, 40, FlxG.width, "Psych Engine Ultra", 36);
		titleText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.fromRGB(0, 80, 160));
		titleText.screenCenter(X);
		add(titleText);

		var subtitleText = new FlxText(0, 90, FlxG.width, "Güncelleme Yükleniyor", 20);
		subtitleText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.fromRGB(180, 210, 255), CENTER);
		subtitleText.screenCenter(X);
		add(subtitleText);

		var barY:Float = FlxG.height / 2 - 20;
		var barW:Float = FlxG.width - 160;
		var barH:Float = 36;
		var barX:Float = 80;

		progressBarBG = new FlxSprite(barX - 3, barY - 3).makeGraphic(Std.int(barW + 6), Std.int(barH + 6), FlxColor.fromRGB(60, 60, 80));
		add(progressBarBG);

		progressBar = new FlxBar(barX, barY, LEFT_TO_RIGHT, Std.int(barW), Std.int(barH), this, "progressValue", 0, 1);
		progressBar.createFilledBar(FlxColor.fromRGB(30, 30, 50), FlxColor.fromRGB(80, 160, 255));
		add(progressBar);

		percentText = new FlxText(0, barY + barH + 12, FlxG.width, "%0", 18);
		percentText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.fromRGB(150, 200, 255), CENTER);
		add(percentText);

		statusText = new FlxText(0, FlxG.height / 2 - 90, FlxG.width, "Bağlanıyor...", 22);
		statusText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		add(statusText);

		detailText = new FlxText(0, FlxG.height / 2 + 60, FlxG.width, "", 16);
		detailText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.fromRGB(160, 160, 180), CENTER);
		add(detailText);

		retryText = new FlxText(0, FlxG.height - 80, FlxG.width, "", 18);
		retryText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.fromRGB(255, 100, 100), CENTER);
		retryText.alpha = 0;
		add(retryText);

		var infoText = new FlxText(0, FlxG.height - 40, FlxG.width, "Güncelleme sırasında oyunu kapatmayın!", 14);
		infoText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.fromRGB(120, 120, 140), CENTER);
		add(infoText);
	}

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
			function(progress:Float, received:Int, total:Int)
			{
				progressValue = progress;
				var receivedStr = UpdaterUtil.formatBytes(received);
				var totalStr = total > 0 ? UpdaterUtil.formatBytes(total) : "?";
				setDetail('$receivedStr / $totalStr');
				percentText.text = "%" + Std.string(Math.floor(progress * 100));
			},
			function(zipPath:String)
			{
				setDetail('ZIP indirildi: $zipPath');
				progressValue = 1.0;
				percentText.text = "%100";

				new flixel.util.FlxTimer().start(0.8, function(_) {
					startApply(zipPath);
				});
			},
			function(error:String)
			{
				onError(error);
			}
		);
	}

	function startApply(zipPath:String):Void
	{
		currentPhase = APPLYING;
		progressValue = 0.0;
		percentText.text = "%0";

		setStatus("Güncelleme Uygulanıyor...");
		setDetail("Dosyalar değiştiriliyor, lütfen bekleyin...");

		UpdaterUtil.applyUpdate(
			zipPath,
			function(progress:Float, fileName:String)
			{
				progressValue = progress;
				percentText.text = "%" + Std.string(Math.floor(progress * 100));

				var shortName = fileName.length > 50 ? "..." + fileName.substr(fileName.length - 47) : fileName;
				setDetail('Uygulanıyor: $shortName');
			},
			function()
			{
				onUpdateComplete();
			},
			function(error:String)
			{
				onError(error);
			}
		);
	}

	function onUpdateComplete():Void
	{
		currentPhase = COMPLETE;
		isComplete = true;
		progressValue = 1.0;
		percentText.text = "%100";

		progressBar.createFilledBar(FlxColor.fromRGB(20, 50, 20), FlxColor.fromRGB(60, 200, 80));

		setStatus("✓ Güncelleme Tamamlandı!");
		setDetail("Psych Engine Ultra başarıyla güncellendi.");

		countdownStarted = true;
		retryText.alpha = 1;
		retryText.color = FlxColor.fromRGB(100, 255, 120);
	}

	function onError(error:String):Void
	{
		hasError = true;
		currentPhase = ERROR;

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

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (countdownStarted && isComplete)
		{
			closeTimer -= elapsed;
			retryText.text = 'Oyun ${Std.string(Math.ceil(closeTimer))} saniye içinde kapanacak...';

			if (closeTimer <= 0)
			{
				retryText.text = "Kapanıyor...";
				countdownStarted = false;

				new flixel.util.FlxTimer().start(0.5, function(_) {
					UpdaterUtil.restartGame();
				});
			}
		}

		if (hasError && !isComplete)
		{
			if (FlxG.keys.justPressed.ENTER && retryCount < MAX_RETRY)
			{
				retryCount++;
				hasError = false;
				FlxTween.tween(retryText, {alpha: 0}, 0.2);
				startDownload();
			}

			if (FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justReleased.BACK #end)
			{
				FlxG.switchState(new MainMenuState());
			}
		}
	}

	function setStatus(msg:String):Void
	{
		statusText.text = msg;
	}

	function setDetail(msg:String):Void
	{
		detailText.text = msg;
	}
}

enum UpdatePhase
{
	DOWNLOADING;
	APPLYING;
	COMPLETE;
	ERROR;
}