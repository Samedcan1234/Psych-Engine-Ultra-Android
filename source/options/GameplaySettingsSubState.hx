package options;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title    = Language.getPhrase('gameplay_menu',    'Gameplay');
		rpcTitle = 'Gameplay Settings Menu';

		var option:Option = new Option(
			Language.getPhrase('gameplay_downscroll',      'Aşağı Oklar'),
			Language.getPhrase('gameplay_downscroll_desc', 'Aktif Edilirse, oyun-içi oklarınız, yukarıdan aşağıya alınır.'),
			'downScroll',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('gameplay_middlescroll',      'Orta Oklar'),
			Language.getPhrase('gameplay_middlescroll_desc', 'Aktif Edilirse, oyun-içi oklarınız ortalanır.'),
			'middleScroll',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('gameplay_opponent_strums',      'Rakip Okları'),
			Language.getPhrase('gameplay_opponent_strums_desc', 'Aktif Edilmezse, rakibin oyun-içi okları gizlenir.'),
			'opponentStrums',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('gameplay_ghost_tapping',      'Hayalet Dokunma'),
			Language.getPhrase('gameplay_ghost_tapping_desc', 'Aktif Edilirse, gelen ok olmadığı halde tuşlara basarsanız Iska sayılmaz.'),
			'ghostTapping',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('gameplay_auto_pause',      'Otomatik Durdurma'),
			Language.getPhrase('gameplay_auto_pause_desc', 'Aktif Edilirse, ekranınız odaklanmadığında oyun otomatik olarak duraklatılır.'),
			'autoPause',
			BOOL);
		addOption(option);
		option.onChange = onChangeAutoPause;

		var option:Option = new Option(
			Language.getPhrase('gameplay_no_reset',      'Reset Butonunu Kapat'),
			Language.getPhrase('gameplay_no_reset_desc', 'Aktif Edilirse, Sıfırla tuşuna basmak hiçbir şey yapmaz.'),
			'noReset',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('gameplay_old_mod_support',      'Eski Mod Desteği'),
			Language.getPhrase('gameplay_old_mod_support_desc', 'Aktif Edilirse, Psych 0.73 Modlarının Çoğunu Sorunsuz Bir Şekilde Oynayabilmenizi Sağlar. (BU AYAR BETA SÜRÜMÜNDE)'),
			'oldModSupport',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('gameplay_auto_ram',      'Otomatik RAM Boşaltımı'),
			Language.getPhrase('gameplay_auto_ram_desc', 'Kullanılmayan Assetlar 10 saniye içinde Ram Önbelleğinden Kaldırılır. Ram\'i Düşük Cihazlar için Önerilir. (BU AYAR BETADA!)'),
			'autoramopt',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('gameplay_sustains',      'Tek Nota Sürdürme'),
			Language.getPhrase('gameplay_sustains_desc', 'Aktif Edilirse, Uzun Notaları kaçırırsanız basamazsınız ve tek bir Vuruş/Iska olarak sayılır.'),
			'guitarHeroSustains',
			BOOL);
		addOption(option);
		
		var option:Option = new Option(
			Language.getPhrase('gameplay_familygame',      'Aile Dostu Oyun'),
			Language.getPhrase('gameplay_familygame_desc', 'Dublajlanan Sesler ve Videolar Kaba ve Sövüş içermez, Dublajlarda Küfür istemiyorsanız bunu aktifleştirin (DUBLAJLAR YAKINDA)'),
			'familyGame',
			BOOL);
		addOption(option);
		
		var option:Option = new Option(
			Language.getPhrase('gameplay_serverconnect',      'Server Connection'),
			Language.getPhrase('gameplay_serverconnect_desc', 'if enabled, your connection to the server will be disconnected, and your scores will not be sent to the server.'),
			'serverConnection',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('gameplay_hitsound',      'Nota Sesi'),
			Language.getPhrase('gameplay_hitsound_desc', 'Notalara Bastığınızda "Tik!" sesi çıkarır.'),
			'hitsoundVolume',
			PERCENT);
		addOption(option);
		option.scrollSpeed  = 1.6;
		option.minValue     = 0.0;
		option.maxValue     = 1;
		option.changeValue  = 0.1;
		option.decimals     = 1;
		option.onChange     = onChangeHitsoundVolume;

		var option:Option = new Option(
			Language.getPhrase('gameplay_rating_offset',      'Derecelendirme Ofseti'),
			Language.getPhrase('gameplay_rating_offset_desc', '"Müq!" için ne kadar geç/erken vurmanız gerektiğini değiştirir. Daha yüksek değerler, daha geç vurmanız gerektiği anlamına gelir.'),
			'ratingOffset',
			INT);
		option.displayFormat = '%vms';
		option.scrollSpeed   = 20;
		option.minValue      = -30;
		option.maxValue      = 30;
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('gameplay_sick_window',      'Müq! Vuruşu'),
			Language.getPhrase('gameplay_sick_window_desc', '"Müq!" için sahip olduğunuz süreyi milisaniye cinsinden değiştirir.'),
			'sickWindow',
			FLOAT);
		option.displayFormat = '%vms';
		option.scrollSpeed   = 15;
		option.minValue      = 15.0;
		option.maxValue      = 45.0;
		option.changeValue   = 0.1;
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('gameplay_good_window',      'İyi Vuruşu'),
			Language.getPhrase('gameplay_good_window_desc', '"İyi" derecesini elde etmek için sahip olduğunuz süreyi milisaniye cinsinden değiştirir.'),
			'goodWindow',
			FLOAT);
		option.displayFormat = '%vms';
		option.scrollSpeed   = 30;
		option.minValue      = 15.0;
		option.maxValue      = 90.0;
		option.changeValue   = 0.1;
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('gameplay_bad_window',      'Kötü Vuruşu'),
			Language.getPhrase('gameplay_bad_window_desc', '"Kötü" notu almak için sahip olduğunuz süreyi milisaniye cinsinden değiştirir.'),
			'badWindow',
			FLOAT);
		option.displayFormat = '%vms';
		option.scrollSpeed   = 60;
		option.minValue      = 15.0;
		option.maxValue      = 135.0;
		option.changeValue   = 0.1;
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('gameplay_safe_frames',      'Güvenli Kareler'),
			Language.getPhrase('gameplay_safe_frames_desc', 'Bir notayı erken veya geç çalmak için kaç kareye sahip olduğunuzu değiştirir.'),
			'safeFrames',
			FLOAT);
		option.scrollSpeed = 5;
		option.minValue    = 2;
		option.maxValue    = 10;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('gameplay_import_save',      'Ayarları İçe Aktar'),
			Language.getPhrase('gameplay_import_save_desc', 'Bir funkin.sol dosyasını seçerek oyunun kayıt dosyasını değiştirebilirsiniz.'),
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
		if (filePath == null || filePath == '') return;

		try
		{
			if (sys.FileSystem.exists(filePath) && filePath.endsWith('.sol'))
			{
				var appDataPath:String = '';
				#if windows
				appDataPath = Sys.getEnv('APPDATA');
				#else
				appDataPath = Sys.getEnv('HOME');
				#end

				if (appDataPath != null && appDataPath != '')
				{
					var psychPath:String = appDataPath + '/Psych Engine';
					if (!sys.FileSystem.exists(psychPath))
						sys.FileSystem.createDirectory(psychPath);

					var targetPath:String = psychPath + '/funkin.sol';
					var fileContent:String = sys.io.File.getContent(filePath);
					sys.io.File.saveContent(targetPath, fileContent);
					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
			}
		}
		catch (e:Dynamic)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			trace('İçe Aktar hatası: $e');
		}

		ClientPrefs.data.importSaveFile = '';
	}

	function onChangeHitsoundVolume()
		FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);

	function onChangeAutoPause()
		FlxG.autoPause = ClientPrefs.data.autoPause;
}
