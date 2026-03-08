package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import flixel.util.FlxTimer;
import objects.VideoSprite;
import openfl.events.KeyboardEvent;
import shaders.SimpleWaveShader;

class CodeMenuState extends MusicBeatState
{
	var codeEntryActive:Bool = true;
	var typedCode:String = "";
	var codeBG:FlxSprite;
	var codePrompt:FlxText;
	var codeInputText:FlxText;
	var backText:FlxText;
	
	// Gizli kod listesi - kolay eklemek ve yönetmek için
	var secretCodes:Map<String, String> = [
		"aminogludublaj" => "ubey",           // Video dosyası adı
		"nexus" => "nexus",        // Video dosyası adı
		"debug" => "debug",          // Video dosyası adı
		"easter" => "easter",        // Video dosyası adı
		"surprise" => "surprise",    // Video dosyası adı
	];
	
	var musicWasStopped:Bool = false;
	var currentVideo:VideoSprite = null;
	var warp:FlxSprite;
	
	// Video skip sistemi
	var isVideoPlaying:Bool = false;
	var skipHoldTime:Float = 0;
	var skipRequiredTime:Float = 1.5;
	var skipLoadingCircle:FlxSprite;
	var skipText:FlxText;
	var spacePressed:Bool = false;

	override function create()
	{
		super.create();

		// Dark background
		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.scrollFactor.set();
		bg.alpha = 0.8;
		add(bg);

        // Wave shader background
        warp = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        warp.scrollFactor.set();
        warp.antialiasing = ClientPrefs.data.antialiasing;
        add(new SimpleWaveEffect(warp));
        add(warp);

		// Code entry UI
		codeBG = new FlxSprite(0, FlxG.height / 2 - 80).makeGraphic(FlxG.width, 160, 0xCC111111);
		codeBG.scrollFactor.set();
		add(codeBG);

		codePrompt = new FlxText(0, codeBG.y + 12, FlxG.width, "Gizli Kodu Girin:", 32);
		codePrompt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		codePrompt.scrollFactor.set();
		add(codePrompt);

		codeInputText = new FlxText(0, codeBG.y + 64, FlxG.width, typedCode, 40);
		codeInputText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.YELLOW, CENTER);
		codeInputText.scrollFactor.set();
		add(codeInputText);

		// Info text
		backText = new FlxText(0, FlxG.height - 40, FlxG.width, "ESC tuşu ile ana menüye geri dön");
		backText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		backText.scrollFactor.set();
		add(backText);

		// Müziği değiştir
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			FlxG.sound.music.stop();
		}
		FlxG.sound.playMusic(Paths.music('codeMenu'), 0.7);

		// Add keyboard event listener
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	function onKeyDown(event:KeyboardEvent)
	{
		if (!codeEntryActive)
		{
			// Video oynatılırken space'ı ignore et - update() da kontrol edilecek
			if (isVideoPlaying && event.keyCode == 32)
			{
				event.preventDefault();
				return;
			}
			return;
		}

		var char = event.charCode;
		var code = event.keyCode;

		// Regular text input (letters, numbers, space)
		if (char >= 32 && char <= 126)
		{
			typedCode += String.fromCharCode(char).toLowerCase();
			codeInputText.text = typedCode;
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		// Backspace (code 8)
		if (code == 8)
		{
			typedCode = if (typedCode.length > 0) typedCode.substr(0, typedCode.length - 1) else "";
			codeInputText.text = typedCode;
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		// Enter (code 13)
		if (code == 13)
		{
			submitCode();
		}

		// Escape (code 27)
		if (code == 27)
		{
			closeCodeEntry();
		}
	}

	override function destroy()
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		// Video oynatılırken space tuşu hold sistemi
		if (isVideoPlaying && currentVideo != null)
		{
			var spaceDown = FlxG.keys.pressed.SPACE;
			
			if (spaceDown && !spacePressed)
			{
				// Tuş ilk basıldığında
				spacePressed = true;
				skipHoldTime = 0;
				createSkipUI();
			}
			else if (spaceDown && spacePressed)
			{
				// Tuş tutulduğunda
				skipHoldTime += elapsed;
				updateSkipUI();
				
				// Yükleme tamamlandı
				if (skipHoldTime >= skipRequiredTime)
				{
					spacePressed = false;
					isVideoPlaying = false;
					destroySkipUI();
					stopVideo();
				}
			}
			else if (!spaceDown && spacePressed)
			{
				// Tuş bırakıldığında
				spacePressed = false;
				skipHoldTime = 0;
				destroySkipUI();
			}
		}
		
		super.update(elapsed);
	}

	function checkKeys()
	{
		// Bu fonksiyon artık kullanılmıyor
		// onKeyDown event listener'ı kulllanıyoruz
	}

	function submitCode()
	{
		var entered = typedCode.trim().toLowerCase();
		
		// Eğer kod yazılmamışsa hata göster
		if (entered.length == 0)
		{
			codeInputText.text = "Kodu Gir.";
			codeInputText.color = FlxColor.RED;
			FlxG.sound.play(Paths.sound('wrong'));
			new FlxTimer().start(1.5, function(timer:FlxTimer) {
				codeInputText.text = "";
			});
			return;
		}
		
		// Gizli kod listesinde arama yap
		if (secretCodes.exists(entered))
		{
			var videoName = secretCodes.get(entered);
			playSecretVideo(videoName);
		}
		else
		{
			// Bilinmeyen kod
			codeInputText.text = "Bilinmeyen Kod!";
			codeInputText.color = FlxColor.RED;
			FlxG.sound.play(Paths.sound('wrong'));
			new FlxTimer().start(1.5, function(timer:FlxTimer) {
				typedCode = "";
				codeInputText.text = "";
				codeInputText.color = FlxColor.WHITE;
			});
		}
	}

	function closeCodeEntry()
	{
		codeEntryActive = false;
		typedCode = "";
		// FlxG.sound.play(Paths.sound('cancelMenu'));
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			FlxG.sound.music.stop();
		}
		FlxG.sound.playMusic(Paths.music('freakymenu'), 0.7);
		
		MusicBeatState.switchState(new MainMenuState());
	}

	function playSecretVideo(videoName:String)
	{
		#if VIDEOS_ALLOWED
			codeEntryActive = false;
			isVideoPlaying = true;
			skipHoldTime = 0;
			
			// Müziği durdur
			if (FlxG.sound.music != null && FlxG.sound.music.playing)
			{
				FlxG.sound.music.stop();
				musicWasStopped = true;
			}
			
			var file:String = Paths.video(videoName);
			currentVideo = new VideoSprite(file, false, true, false);
			
			// Video bittiğinde callback
			currentVideo.finishCallback = function() {
				isVideoPlaying = false;
				destroySkipUI();
				stopVideo();
			};
			
			add(currentVideo);
			currentVideo.play();
		#else
			FlxG.log.warn('Video playback not available on this build.');
			FlxG.sound.play(Paths.sound('cancelMenu'));
			new FlxTimer().start(1.5, function(timer:FlxTimer) {
				returnToCodeMenu();
			});
		#end
	}

	function createSkipUI()
	{
		// Loading circle (sağ alt köşe)
		skipLoadingCircle = new FlxSprite(FlxG.width - 120, FlxG.height - 120);
		skipLoadingCircle.makeGraphic(100, 100, 0x00000000);
		skipLoadingCircle.scrollFactor.set();
		add(skipLoadingCircle);
		
		// Skip text (orta-aşağı)
		skipText = new FlxText(0, FlxG.height - 100, FlxG.width, "Geçmek için Basılı Tutun");
		skipText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		skipText.scrollFactor.set();
		skipText.alpha = 0;
		add(skipText);
	}

	function updateSkipUI()
	{
		if (skipLoadingCircle != null)
		{
			// Loading circle'ı progressle çiz
			var progress = skipHoldTime / skipRequiredTime;
			skipLoadingCircle.makeGraphic(100, 100, 0x00000000);
			
			// Circle border
			drawCircle(skipLoadingCircle, 50, 50, 45, FlxColor.WHITE, progress);
			
			// Inner fill
			if (progress > 0)
			{
				drawCircle(skipLoadingCircle, 50, 50, 40, FlxColor.LIME, progress);
			}
		}
		
		// Skip text'i aydınlat (fade in/out)
		if (skipText != null)
		{
			var alpha = Math.sin(skipHoldTime * 4) * 0.5 + 0.5;
			skipText.alpha = alpha;
		}
	}

	function drawCircle(sprite:FlxSprite, centerX:Int, centerY:Int, radius:Float, color:FlxColor, progress:Float)
	{
		// Basit circle çizimi (progress'e göre)
		var angle = 0.0;
		var segments = 30;
		var maxAngle = Math.PI * 2 * progress;
		
		while (angle < maxAngle)
		{
			var nextAngle = Math.min(angle + (Math.PI * 2 / segments), maxAngle);
			var x1 = Std.int(centerX + Math.cos(angle) * radius);
			var y1 = Std.int(centerY + Math.sin(angle) * radius);
			var x2 = Std.int(centerX + Math.cos(nextAngle) * radius);
			var y2 = Std.int(centerY + Math.sin(nextAngle) * radius);
			
			if (x1 >= 0 && x1 < sprite.width && y1 >= 0 && y1 < sprite.height)
			{
				sprite.pixels.setPixel32(x1, y1, color);
			}
			if (x2 >= 0 && x2 < sprite.width && y2 >= 0 && y2 < sprite.height)
			{
				sprite.pixels.setPixel32(x2, y2, color);
			}
			
			angle = nextAngle;
		}
		
		sprite.dirty = true;
	}

	function destroySkipUI()
	{
		if (skipLoadingCircle != null)
		{
			remove(skipLoadingCircle);
			skipLoadingCircle.destroy();
			skipLoadingCircle = null;
		}
		
		if (skipText != null)
		{
			remove(skipText);
			skipText.destroy();
			skipText = null;
		}
	}

	function stopVideo()
	{
		// Skip UI'ı kaldır
		destroySkipUI();
		
		// Video sprite'ı kaldır
		if (currentVideo != null)
		{
			if (FlxG.state != null && FlxG.state.members.contains(currentVideo))
				FlxG.state.remove(currentVideo);
			currentVideo.destroy();
			currentVideo = null;
		}
		
		isVideoPlaying = false;
		
		// CodeMenuState'e geri dön
		returnToCodeMenu();
	}

	function returnToCodeMenu()
	{
		// Müziği tekrar başlat
		if (musicWasStopped && FlxG.sound.music != null)
		{
			FlxG.sound.music.play();
			musicWasStopped = false;
		}
		
		// Kodu sil
		typedCode = "";
		codeInputText.text = "";
		codeInputText.color = FlxColor.YELLOW;
		
		// Yazı girişini tekrar aktif et
		codeEntryActive = true;
	}
}
