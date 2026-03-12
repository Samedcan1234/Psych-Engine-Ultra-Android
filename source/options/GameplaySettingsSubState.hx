package options;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('gameplay_menu', 'Oynanis Ayarlari');
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Asagi Oklar', //Name
			'Aktif Edilirse, oyun-içi oklarınız, yukarıdan aşağıya alınır.', //Description
			'downScroll', //Save data variable name
			BOOL); //Variable type
		addOption(option);

		var option:Option = new Option('Orta Oklar',
			'Aktif Edilirse, oyun-içi oklarınız ortalanır.',
			'middleScroll',
			BOOL);
		addOption(option);

		var option:Option = new Option('Rakip Oklari',
			'Aktif Edilmezse, rakibin oyun-içi okları gizlenir.',
			'opponentStrums',
			BOOL);
		addOption(option);

		var option:Option = new Option('Hayalet Dokunma',
			"Aktif Edilirse, gelen ok olmadığı halde tuşlara basarsanız Iska sayılmaz.",
			'ghostTapping',
			BOOL);
		addOption(option);
		
		var option:Option = new Option('Otomatik Durdurma',
			"Aktif Edilirse, ekranınız odaklanmadığında oyun otomatik olarak duraklatılır.",
			'autoPause',
			BOOL);
		addOption(option);
		option.onChange = onChangeAutoPause;

		var option:Option = new Option('Reset Butonunu Kapat',
			"Aktif Edilirse, Sıfırla tuşuna basmak hiçbir şey yapmaz.",
			'noReset',
			BOOL);
		addOption(option);
		
		var option:Option = new Option('Eski Mod Destegi',
			"Aktif Edilirse, Psych 0.73 Modlarının Çoğunu Sorunsuz Bir Şekilde Oynayabilmenizi Sağlar. (BU AYAR BETA SÜRÜMÜNDE)",
			'oldModSupport',
			BOOL);
		addOption(option);
		
		var option:Option = new Option('Xq Bok Yesin',
			"Xq'nun Bok Yemesini sağlar, oyun sırasında xq harflerine basarak açılıp / kapatılabilir.",
			'oldModSupport',
			BOOL);
		addOption(option);
		
		var option:Option = new Option('Otomatik Ram Bosaltimi',
			"Kullanılmayan Assetlar (PNG / SES DOSYALARI VB.) 10 saniye içinde Ram Önbelleğinden Kaldırılır. Ram'i Düşük Cihazlar için Önerilir. (BU AYAR BETADA!)",
			'autoramopt',
			BOOL);
		addOption(option);

		var option:Option = new Option('Tek Nota Sürdürme',
			"Aktif Edilirse, Uzun Notaları kaçırırsanız basamazsınız ve tek bir Vuruş/Iska olarak sayılır. Eski Giriş Sistemini tercih ediyorsanız bu seçeneğin işaretini kaldırın.",
			'guitarHeroSustains',
			BOOL);
		addOption(option);

		var option:Option = new Option('Nota Sesi',
			'Notalara Bastığınızda "Tik!" sesi çıkarır.',
			'hitsoundVolume',
			PERCENT);
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;

		var option:Option = new Option('Derecelendirme Ofseti',
			'"Müq!" için ne kadar geç/erken vurmanız gerektiğini değiştirir. Daha yüksek değerler, daha geç vurmanız gerektiği anlamına gelir.',
			'ratingOffset',
			INT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option('Müq! Vurusu',
			'"Müq!" için sahip olduğunuz süreyi milisaniye cinsinden değiştirir.',
			'sickWindow',
			FLOAT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15.0;
		option.maxValue = 45.0;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Iyi Vurusu',
			'"İyi" derecesini elde etmek için sahip olduğunuz süreyi milisaniye cinsinden değiştirir.',
			'goodWindow',
			FLOAT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15.0;
		option.maxValue = 90.0;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Kötü Vurusu',
			'"Kötü" notu almak için sahip olduğunuz süreyi milisaniye cinsinden değiştirir.',
			'badWindow',
			FLOAT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15.0;
		option.maxValue = 135.0;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Güvenli Kareler',
			'Bir notayı erken veya geç çalmak için kaç kareye sahip olduğunuzu değiştirir.',
			'safeFrames',
			FLOAT);
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Ayarlari içe Aktar',
			'Bir funkin.sol dosyasını seçerek oyunun kayıt dosyasını değiştirebilirsiniz.',
			'importSaveFile',
			FILE);
		option.options = ['.sol'];
		addOption(option);
		option.onChange = onChangeImportSaveFile;

		super();
	}

	function onChangeImportSaveFile()
	{
		var filePath:String = ClientPrefs.data.importSaveFile;
		if(filePath == null || filePath == '') return;

		// Seçilen dosyayı oyun kayıt dosyası olarak kullan
		try
		{
			if(sys.FileSystem.exists(filePath) && filePath.endsWith('.sol'))
			{
				// Mevcut kayıt dosyasını yedekle
				var appDataPath:String = '';
				#if windows
				appDataPath = Sys.getEnv('APPDATA');
				#else
				appDataPath = Sys.getEnv('HOME');
				#end
				
				if(appDataPath != null && appDataPath != '')
				{
					var psychPath:String = appDataPath + '/Psych Engine';
					if(!sys.FileSystem.exists(psychPath))
						sys.FileSystem.createDirectory(psychPath);
					
					var targetPath:String = psychPath + '/funkin.sol';
					
					// Dosyayı kopyala
					var fileContent:String = sys.io.File.getContent(filePath);
					sys.io.File.saveContent(targetPath, fileContent);
					
					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
			}
		}
		catch(e:Dynamic)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			trace('İçe Aktar hatası: $e');
		}

		// Reset değeri (UI'de gösterilmez)
		ClientPrefs.data.importSaveFile = '';
	}

	function onChangeHitsoundVolume()
		FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);

	function onChangeAutoPause()
		FlxG.autoPause = ClientPrefs.data.autoPause;
}
