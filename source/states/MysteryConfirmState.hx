package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class MysteryConfirmState extends MusicBeatState
{
	// Sorular
	var questions:Array<String> = [
		"Emin misin?",
		"Gerçekten mi?",
		"Ciddi misin?",
		"Pişman olmayacaksın, değil mi?",
		"Son kararın mı?",
		"Geri dönüş yok...\nDevam mı?",
		"Hâlâ devam mı?",
		"Korkmuyorsun, değil mi?",
		"Bu senin seçimin...\nEmin misin?",
		"...HAZIR MISIN?"
	];
	
	var currentQuestion:Int = 0;
	var selectedOption:Int = 0; // 0 = Evet, 1 = Hayır
	
	// UI Elemanları
	var questionText:FlxText;
	var yesButton:FlxText;
	var noButton:FlxText;
	var yesBox:FlxSprite;
	var noBox:FlxSprite;
	var progressText:FlxText;
	
	// Arka plan
	var bg:FlxSprite;
	var overlay:FlxSprite;
	var gridBG:FlxBackdrop;
	var staticNoise:FlxSprite;
	
	// Efekt değişkenleri
	var glitchTimer:Float = 0;
	var shakeIntensity:Float = 0.005;
	var eyeSprites:Array<FlxSprite> = [];
	
	// Partiküller
	var particles:Array<FlxSprite> = [];
	
	var canSelect:Bool = false;
	
	// Asset durumu kontrolü
	public static var fakeAssetsEnabled:Bool = false;
	static var saveFilePath:String = "./fake_assets_enabled.txt";
	
	override function create()
	{
		super.create();
		
		// Önceki durumu kontrol et
		checkFakeAssetsStatus();
		
		// Müziği durdur veya korkutucu müzik çal
		FlxG.sound.music.volume = 0.3;
		
		// Karanlık arka plan
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF0a0a0a);
		add(bg);
		
		// Kırmızı grid
		gridBG = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x11FF0000, 0x0));
		gridBG.velocity.set(-20, -20);
		gridBG.alpha = 0.3;
		add(gridBG);
		
		// Statik gürültü
		staticNoise = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		staticNoise.alpha = 0;
		add(staticNoise);
		
		// Karanlık overlay
		overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		overlay.alpha = 0.7;
		add(overlay);
		
		// Partiküller
		createParticles();
		
		// Gözler (rastgele görünecek)
		createEyes();
		
		// Soru metni
		questionText = new FlxText(0, 150, FlxG.width, "", 48);
		questionText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		questionText.borderSize = 4;
		questionText.alpha = 0;
		add(questionText);
		
		// İlerleme göstergesi
		progressText = new FlxText(0, 80, FlxG.width, "", 24);
		progressText.setFormat(Paths.font("vcr.ttf"), 24, 0xFF666666, CENTER);
		add(progressText);
		
		// EVET butonu
		yesBox = new FlxSprite(FlxG.width/2 - 200, 350).makeGraphic(150, 60, 0xFF1a1a1a);
		add(yesBox);
		
		yesButton = new FlxText(FlxG.width/2 - 200, 360, 150, "EVET", 32);
		yesButton.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.GREEN, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		yesButton.borderSize = 2;
		add(yesButton);
		
		// HAYIR butonu
		noBox = new FlxSprite(FlxG.width/2 + 50, 350).makeGraphic(150, 60, 0xFF1a1a1a);
		add(noBox);
		
		noButton = new FlxText(FlxG.width/2 + 50, 360, 150, "HAYIR", 32);
		noButton.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		noButton.borderSize = 2;
		add(noButton);
		
		// Başlangıç animasyonu
		FlxG.camera.fade(FlxColor.BLACK, 0.5, true, function() {
			showQuestion();
		});
	}
	
	function createParticles()
	{
		for(i in 0...30)
		{
			var p = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			p.makeGraphic(Std.int(FlxG.random.float(2, 5)), Std.int(FlxG.random.float(2, 5)), FlxColor.RED);
			p.alpha = FlxG.random.float(0.3, 0.7);
			p.velocity.y = FlxG.random.float(-30, -10);
			p.velocity.x = FlxG.random.float(-5, 5);
			add(p);
			particles.push(p);
		}
	}
	
	function createEyes()
	{
		for(i in 0...5)
		{
			var eye = new FlxSprite();
			if(Paths.fileExists('images/credits/mystery_eye.png', IMAGE))
				eye.loadGraphic(Paths.image('credits/mystery_eye'));
			else
				eye.makeGraphic(50, 50, FlxColor.RED);
			eye.alpha = 0;
			eye.setGraphicSize(30, 30);
			eye.updateHitbox();
			add(eye);
			eyeSprites.push(eye);
		}
	}
	
	function showQuestion()
	{
		canSelect = false;
		
		// Glitch efekti
		FlxG.camera.shake(0.01, 0.3);
		
		// Mevcut soru
		var qText = questions[currentQuestion];
		
		// Eğer fake assets aktifse, sorular "Kapatmak ister misin?" tarzında olsun
		if(fakeAssetsEnabled && currentQuestion == 0)
		{
			qText = "Geri dönmek mi istiyorsun?";
		}
		
		questionText.text = qText;
		questionText.alpha = 0;
		questionText.y = 180;
		
		// İlerleme
		progressText.text = '[ ${currentQuestion + 1} / ${questions.length} ]';
		
		// Animasyon
		FlxTween.tween(questionText, {alpha: 1, y: 150}, 0.5, {
			ease: FlxEase.quartOut,
			onComplete: function(twn:FlxTween) {
				canSelect = true;
			}
		});
		
		// Ses efekti
		FlxG.sound.play(Paths.sound('scrollMenu'));
		
		// Her soruda korku artsın
		shakeIntensity = 0.005 + (currentQuestion * 0.002);
		overlay.alpha = 0.7 - (currentQuestion * 0.03);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		// Glitch efektleri
		glitchTimer += elapsed;
		updateGlitchEffects(elapsed);
		
		// Partiküller
		for(p in particles)
		{
			if(p.y < -10)
			{
				p.y = FlxG.height + 10;
				p.x = FlxG.random.float(0, FlxG.width);
			}
		}
		
		if(!canSelect) return;
		
		// Kontroller
		if(controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			selectedOption = (selectedOption == 0) ? 1 : 0;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			updateSelection();
		}
		
		if(controls.ACCEPT)
		{
			selectOption();
		}
		
		if(controls.BACK)
		{
			// Hayır seçilmiş gibi davran
			selectedOption = 1;
			selectOption();
		}
	}
	
	function updateGlitchEffects(elapsed:Float)
	{
		// Statik gürültü
		if(glitchTimer > 0.05)
		{
			glitchTimer = 0;
			staticNoise.alpha = FlxG.random.float(0, 0.1);
		}
		
		// Rastgele shake
		if(FlxG.random.bool(2))
		{
			FlxG.camera.shake(shakeIntensity, 0.1);
		}
		
		// Gözlerin rastgele görünmesi
		for(eye in eyeSprites)
		{
			if(eye.alpha <= 0 && FlxG.random.bool(0.3))
			{
				eye.x = FlxG.random.float(50, FlxG.width - 50);
				eye.y = FlxG.random.float(50, FlxG.height - 50);
				eye.alpha = 0.5;
				FlxTween.tween(eye, {alpha: 0}, FlxG.random.float(0.5, 1.5));
			}
		}
		
		// Soru metnini titre
		if(questionText != null && canSelect)
		{
			questionText.x = FlxG.random.float(-2, 2);
			
			// Son sorularda daha yoğun efekt
			if(currentQuestion >= 7)
			{
				questionText.color = FlxG.random.bool(10) ? FlxColor.WHITE : FlxColor.RED;
			}
		}
	}
	
	function updateSelection()
	{
		if(selectedOption == 0)
		{
			// Evet seçili
			yesBox.color = FlxColor.GREEN;
			yesButton.color = FlxColor.WHITE;
			yesButton.scale.set(1.2, 1.2);
			
			noBox.color = 0xFF1a1a1a;
			noButton.color = FlxColor.RED;
			noButton.scale.set(1, 1);
		}
		else
		{
			// Hayır seçili
			noBox.color = FlxColor.RED;
			noButton.color = FlxColor.WHITE;
			noButton.scale.set(1.2, 1.2);
			
			yesBox.color = 0xFF1a1a1a;
			yesButton.color = FlxColor.GREEN;
			yesButton.scale.set(1, 1);
		}
	}
	
	function selectOption()
	{
		canSelect = false;
		
		if(selectedOption == 1) // HAYIR
		{
			// Ana menüye dön
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function() {
				MusicBeatState.switchState(new MainMenuState());
			});
		}
		else // EVET
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			
			currentQuestion++;
			
			if(currentQuestion >= questions.length)
			{
				// TÜM SORULAR TAMAMLANDI!
				triggerFinalAction();
			}
			else
			{
				// Sonraki soru
				FlxTween.tween(questionText, {alpha: 0, y: 120}, 0.3, {
					ease: FlxEase.quartIn,
					onComplete: function(twn:FlxTween) {
						showQuestion();
					}
				});
			}
		}
	}
	
	function triggerFinalAction()
	{
		canSelect = false;
		
		// Büyük glitch efekti
		FlxG.camera.shake(0.05, 1);
		FlxG.camera.flash(FlxColor.RED, 0.5);
		
		// Toggle fake assets
		fakeAssetsEnabled = !fakeAssetsEnabled;
		saveFakeAssetsStatus();
		
		// Swap assets
		swapAssets();
		
		// Mesaj göster
		var resultText = new FlxText(0, FlxG.height/2, FlxG.width, "", 36);
		resultText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		resultText.borderSize = 3;
		
		if(fakeAssetsEnabled)
		{
			resultText.text = "GERÇEK ARTIK GİZLİ...\n\nASSETLER DEĞİŞTİRİLDİ.";
			resultText.color = FlxColor.RED;
		}
		else
		{
			resultText.text = "GERÇEK GERİ DÖNDÜ...\n\nASSETLER NORMALE DÖNDÜRÜLDÜ.";
			resultText.color = FlxColor.GREEN;
		}
		
		resultText.alpha = 0;
		add(resultText);
		
		FlxTween.tween(resultText, {alpha: 1}, 0.5, {
			onComplete: function(twn:FlxTween) {
				new FlxTimer().start(3, function(tmr:FlxTimer) {
					FlxG.camera.fade(FlxColor.BLACK, 1, false, function() {
						// Oyunu yeniden başlat veya ana menüye dön
						MusicBeatState.switchState(new MainMenuState());
					});
				});
			}
		});
	}
	
	function checkFakeAssetsStatus()
	{
		#if sys
		if(FileSystem.exists(saveFilePath))
		{
			var content = File.getContent(saveFilePath);
			fakeAssetsEnabled = (content == "true");
		}
		#end
	}
	
	function saveFakeAssetsStatus()
	{
		#if sys
		File.saveContent(saveFilePath, fakeAssetsEnabled ? "true" : "false");
		#end
	}
	
	function swapAssets()
	{
		#if sys
		var assetsPath = "./assets";
		var fakeAssetsPath = "./assets/fakeassets";
		var backupPath = "./assets_backup";
		
		try
		{
			if(fakeAssetsEnabled)
			{
				// Normal -> Fake
				// Önce backup al
				if(!FileSystem.exists(backupPath) && FileSystem.exists(assetsPath))
				{
					// Assets'i yedekle (basit dosya kopyalama)
					trace("Assets yedekleniyor...");
					copyDirectory(assetsPath, backupPath);
				}
				
				// Fake assets'i ana assets'e kopyala
				if(FileSystem.exists(fakeAssetsPath))
				{
					trace("Fake assets uygulanıyor...");
					copyDirectory(fakeAssetsPath, assetsPath);
				}
			}
			else
			{
				// Fake -> Normal
				// Backup'ı geri yükle
				if(FileSystem.exists(backupPath))
				{
					trace("Normal assets geri yükleniyor...");
					copyDirectory(backupPath, assetsPath);
				}
			}
		}
		catch(e:Dynamic)
		{
			trace("Asset swap hatası: " + e);
		}
		#end
	}
	
	#if sys
	function copyDirectory(source:String, destination:String)
	{
		if(!FileSystem.exists(destination))
			FileSystem.createDirectory(destination);
		
		for(entry in FileSystem.readDirectory(source))
		{
			var sourcePath = source + "/" + entry;
			var destPath = destination + "/" + entry;
			
			if(FileSystem.isDirectory(sourcePath))
			{
				copyDirectory(sourcePath, destPath);
			}
			else
			{
				try
				{
					var content = File.getBytes(sourcePath);
					File.saveBytes(destPath, content);
				}
				catch(e:Dynamic)
				{
					trace("Dosya kopyalama hatası: " + entry);
				}
			}
		}
	}
	#end
}