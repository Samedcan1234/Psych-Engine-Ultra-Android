package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import flixel.input.keyboard.FlxKey;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import flixel.addons.display.FlxBackdrop;

class ThanksCreditsState extends MusicBeatState
{
	var creditsData:Array<Array<String>> = [];
	var creditItems:FlxTypedGroup<CreditItem>;
	var scrollSpeed:Float = 50; // Kaydırma hızı (piksel/saniye)
	
	var blackBG:FlxSprite;
	var endImage:FlxSprite; // Sonda gösterilecek resim
	var endImageShown:Bool = false;
	
	var skipText:FlxText;
	var canSkip:Bool = true;

	override function create()
	{
		super.create();
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Credits Akışını İzliyor", null);
		#end

		// Siyah Arka Plan
		blackBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(blackBG);

		creditItems = new FlxTypedGroup<CreditItem>();
		add(creditItems);

		// Credits verilerini yükle
		loadCreditsData();
		
		// Credits öğelerini oluştur
		createCreditItems();

		// Skip Metni
		skipText = new FlxText(0, FlxG.height - 40, FlxG.width, "ESC ile çık | ENTER ile hızlandır", 20);
		skipText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		skipText.scrollFactor.set();
		skipText.alpha = 0.7;
		add(skipText);

		// YENİ: Son resmi SADECE RESİM OLARAK hazırla
		endImage = new FlxSprite();
		var endImagePath = 'credits/thanks'; // assets/images/credits/thanks.png
		
		if(Paths.fileExists('images/$endImagePath.png', IMAGE))
		{
			endImage.loadGraphic(Paths.image(endImagePath));
		}
		else
		{
			// Eğer resim yoksa varsayılan placeholder oluştur
			trace("WARNING: credits/thanks.png bulunamadı! Lütfen ekleyin.");
			endImage.makeGraphic(1000, 600, 0xFF1a1a1a);
			
			// Uyarı metni ekle (sadece geliştirme aşamasında görmek için)
			var warningText = new FlxText(0, 0, 1000, "LÜTFEN\nassets/images/credits/thanks.png\nEKLEYİN", 48);
			warningText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			warningText.borderSize = 3;
			warningText.screenCenter();
			warningText.scrollFactor.set();
			warningText.alpha = 0;
			add(warningText);
			
			// Uyarı metnini de fade in yap
			FlxTween.tween(warningText, {alpha: 1}, 1.5, {ease: FlxEase.quartInOut, startDelay: 1});
		}
		
		// Aspect ratio koruyarak boyutlandır
		var maxWidth = FlxG.width * 0.85;
		var maxHeight = FlxG.height * 0.7;
		
		if(endImage.width > maxWidth || endImage.height > maxHeight)
		{
			var scaleX = maxWidth / endImage.width;
			var scaleY = maxHeight / endImage.height;
			var finalScale = Math.min(scaleX, scaleY);
			
			endImage.scale.set(finalScale, finalScale);
			endImage.updateHitbox();
		}
		
		endImage.screenCenter();
		endImage.alpha = 0;
		endImage.scrollFactor.set();
		endImage.antialiasing = ClientPrefs.data.antialiasing;
		add(endImage);

		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);
	}

	function loadCreditsData()
	{
		// CreditsState'deki aynı veriyi kullan
		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled)
		{
			var creditsFile:String = Paths.mods(mod + '/data/credits.txt');
			#if TRANSLATIONS_ALLOWED
			var translatedCredits:String = Paths.mods(mod + '/data/credits-${ClientPrefs.data.language}.txt');
			#end

			if (#if TRANSLATIONS_ALLOWED (sys.FileSystem.exists(translatedCredits) && (creditsFile = translatedCredits) == translatedCredits) || #end sys.FileSystem.exists(creditsFile))
			{
				var firstarray:Array<String> = sys.io.File.getContent(creditsFile).split('\n');
				for(i in firstarray)
				{
					var arr:Array<String> = i.replace('\\n', '\n').split("::");
					if(arr.length >= 5)
					{
						creditsData.push(arr);
					}
				}
			}
		}
		#end

		if(creditsData.length == 0)
		{
			// Varsayılan credits
			pushDefaultCreditsData();
		}
	}

	function pushDefaultCreditsData()
	{
		// Sadece kişileri ekle (header'sız)
		creditsData.push(['SametGkTe', 'gkte', 'Psych Engine Türkiye Yapımcısı / Çevirmen / Kodlayıcı', 'https://tiktok.com/@gktegameplay', '24ED13']);
		creditsData.push(['Nexus', 'nexusbotu', 'Yardımcı / Çevirmen', 'https://tiktok.com/@nexus00.3', '24ED13']);
		creditsData.push(['Nixamic', 'shucks', 'Beta Kullanıcısı', 'https://tiktok.com/@nixamic_amz', 'C96116']);
		creditsData.push(['XQZ64', 'tabi', 'Beta Kullanıcısı', 'https://tiktok.com/@xqz248', '3B3734']);
		creditsData.push(['Feyza', 'fey', 'Beta Kullanıcısı', 'https://tiktok.com/@feyzawashere', 'B01E1E']);
		creditsData.push(['Umut', 'bf2', 'Beta Kullanıcısı', 'https://tiktok.com/@lxbs0', '2472B3']);
		creditsData.push(['Mert', 'matt', 'Beta Kullanıcısı', 'https://tiktok.com/@fnf_oynuyom_real', '41464A']);
		creditsData.push(['Ömer FK', 'bob', 'Beta Kullanıcısı', 'https://tiktok.com/@0mbi_efendi23', '211E1E']);
		creditsData.push(['mvoreZz', 'bulut', 'Beta Kullanıcısı', 'https://tiktok.com/@mvorezz', 'BF179A']);
		creditsData.push(['Syran', 'bf', 'Beta Kullanıcısı', 'https://tiktok.com/@syran_moon', '2472B3']);
		creditsData.push(['ProMusas', 'bf', 'Beta Kullanıcısı', 'https://tiktok.com/@fnf_gamer4231', '2472B3']);
		creditsData.push(['Mortis Meain', 'bf', 'Beta Kullanıcısı', 'https://tiktok.com/@bs_editorx', '2472B3']);
		creditsData.push(['Ardaa', 'sarv', 'Beta Kullanıcısı', 'https://tiktok.com/@ardaa.fnf', 'B51F95']);
		creditsData.push(['MuratGkTe', 'darnell', 'Beta Kullanıcısı', 'https://tiktok.com/@metal1_1sonic', '6A1FB5']);
		creditsData.push(['RiasFNF', 'bf', 'Beta Kullanıcısı', 'https://tiktok.com/@baki.1223', '2472B3']);
		creditsData.push(['ilovepico', 'bf', 'Beta Kullanıcısı', 'https://tiktok.com/@browhyiamlovefnf', '2472B3']);
		creditsData.push(['BilalGkTe', 'nonsense', 'Beta Kullanıcısı', 'https://tiktok.com/@gktegameplay1', '1FB1CC']);
		creditsData.push(['Slasher', 'bf', 'Beta Kullanıcısı', 'https://tiktok.com/@chikenjokey0', '2472B3']);
		creditsData.push(['Balc', 'whitty', 'Beta Kullanıcısı', 'https://tiktok.com/@balc_tr', '302B30']);
		creditsData.push(['Ozna', 'matt', 'Beta Kullanıcısı', 'https://tiktok.com/@ozan.can623', '41464A']);
		creditsData.push(['Shadow Mario', 'shadowmario', 'Main Programmer of Psych Engine', 'https://twitter.com/Shadow_Mario_', '444444']);
		creditsData.push(['Riveren', 'riveren', 'Main Artist/Animator of Psych Engine', 'https://twitter.com/riverennn', 'B42F71']);
		creditsData.push(['ninjamuffin99', 'ninjamuffin99', "Programmer of Friday Night Funkin'", 'https://twitter.com/ninja_muffin99', 'CF2D2D']);
		creditsData.push(['PhantomArcade', 'phantomarcade', "Animator of Friday Night Funkin'", 'https://twitter.com/PhantomArcade3K', 'FADC45']);
		creditsData.push(['evilsk8r', 'evilsk8r', "Artist of Friday Night Funkin'", 'https://twitter.com/evilsk8r', '5ABD4B']);
		creditsData.push(['kawaisprite', 'kawaisprite', "Composer of Friday Night Funkin'", 'https://twitter.com/kawaisprite', '378FC7']);
	}

	function createCreditItems()
	{
		var startY:Float = FlxG.height + 150; // Ekranın daha altından başla
		var spacing:Float = 400; // YENİ: Çok daha geniş boşluk (280'den 400'e)

		for(i in 0...creditsData.length)
		{
			var data = creditsData[i];
			
			// Header kontrolü
			if(data.length <= 1) continue;

			var item = new CreditItem(data[0], data[1], data[2]);
			item.y = startY + (i * spacing);
			item.screenCenter(X);
			creditItems.add(item);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var speed = scrollSpeed;
		
		// ENTER basılı tutulursa hızlan
		if(FlxG.keys.pressed.ENTER)
		{
			speed *= 3;
			skipText.text = "⚡ HIZLANDIRILIYOR! ⚡";
		}
		else
		{
			skipText.text = "ESC ile çık | ENTER ile hızlandır";
		}

		// Credits'leri yukarı kaydır
		if(!endImageShown)
		{
			creditItems.forEach(function(item:CreditItem) {
				item.y -= speed * elapsed;
				
				// YENİ: Ekran merkezine yakınlığa göre renk fade efekti
				updateCreditItemColor(item);
			});

			// En son öğe ekranın üstünden çıktıysa end image göster
			if(creditItems.length > 0)
			{
				var lastItem = creditItems.members[creditItems.members.length - 1];
				if(lastItem != null && lastItem.y + lastItem.height < -150)
				{
					showEndImage();
				}
			}
		}

		// ESC ile çık
		if(FlxG.keys.justPressed.ESCAPE && canSkip)
		{
			exitCredits();
		}
	}

	// YENİ: Credits öğelerinin rengini ekran pozisyonuna göre ayarla
	function updateCreditItemColor(item:CreditItem)
	{
		var centerY = FlxG.height / 2;
		var itemCenterY = item.y + (item.height / 2);
		
		// Ekran merkezinden uzaklık
		var distance = Math.abs(itemCenterY - centerY);
		var maxDistance = FlxG.height * 0.6; // Fade mesafesi
		
		// Alpha hesaplama (merkeze yaklaştıkça 1, uzaklaştıkça 0)
		var alpha = 1 - (distance / maxDistance);
		if(alpha < 0) alpha = 0;
		if(alpha > 1) alpha = 1;
		
		// Yumuşak geçiş için ease
		alpha = FlxEase.quadInOut(alpha);
		
		// Tüm öğelere alpha uygula
		item.alpha = alpha;
	}

	function showEndImage()
	{
		if(endImageShown) return;
		
		endImageShown = true;
		
		// Fade in efekti
		FlxTween.tween(endImage, {alpha: 1}, 2.0, { // 1.5'ten 2.0'a (daha yavaş)
			ease: FlxEase.quartInOut,
			onComplete: function(twn:FlxTween) {
				// 5 saniye bekle, sonra ana menüye dön
				new FlxTimer().start(5, function(tmr:FlxTimer) {
					exitCredits();
				});
			}
		});
	}

	function exitCredits()
	{
		canSkip = false;
		FlxG.camera.fade(FlxColor.BLACK, 0.8, false, function() {
			MusicBeatState.switchState(new MainMenuState());
		});
	}
}

// Credits öğesi sınıfı (İYİLEŞTİRİLMİŞ)
class CreditItem extends FlxSpriteGroup
{
	var icon:FlxSprite;
	var nameText:FlxText;
	var roleText:FlxText;

	public function new(name:String, iconName:String, role:String)
	{
		super();

		// İkon
		icon = new FlxSprite();
		var iconPath = 'credits/' + iconName;
		if(!Paths.fileExists('images/$iconPath.png', IMAGE)) 
			iconPath = 'credits/missing_icon';
		
		icon.loadGraphic(Paths.image(iconPath));
		
		// Aspect ratio koruyarak boyutlandırma
		var targetSize = 200; // 180'den 200'e (biraz daha büyük)
		var scale:Float = 1.0;
		
		// En büyük kenarı bul
		if(icon.width > icon.height)
		{
			scale = targetSize / icon.width;
		}
		else
		{
			scale = targetSize / icon.height;
		}
		
		icon.scale.set(scale, scale);
		icon.updateHitbox();
		icon.antialiasing = ClientPrefs.data.antialiasing;
		add(icon);

		// İsim
		nameText = new FlxText(0, icon.y + icon.height + 30, FlxG.width, name, 56); // Font 52'den 56'ya
		nameText.setFormat(Paths.font("vcr.ttf"), 56, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nameText.borderSize = 4;
		add(nameText);

		// Rol
		roleText = new FlxText(0, nameText.y + 70, FlxG.width, role, 36); // Font 34'ten 36'ya
		roleText.setFormat(Paths.font("vcr.ttf"), 36, 0xFFCCCCCC, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		roleText.borderSize = 2.8;
		add(roleText);

		// İkonu merkeze al
		icon.x = (FlxG.width / 2) - (icon.width / 2);
	}
}