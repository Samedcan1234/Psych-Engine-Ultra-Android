package options;

import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;
import objects.Alphabet;

class VisualsSettingsSubState extends BaseOptionsMenu
{
	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var splashes:FlxTypedGroup<NoteSplash>;
	var noteY:Float = 90;

	public function new()
	{
		title    = Language.getPhrase('visuals_menu',    'Interface & Visuals');
		rpcTitle = 'Visuals Settings Menu';

		notes   = new FlxTypedGroup<StrumNote>();
		splashes = new FlxTypedGroup<NoteSplash>();

		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = new StrumNote(370 + (560 / Note.colArray.length) * i, -200, i, 0);
			changeNoteSkin(note);
			notes.add(note);

			var splash:NoteSplash = new NoteSplash(0, 0, NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix());
			splash.inEditor  = true;
			splash.babyArrow = note;
			splash.ID        = i;
			splash.kill();
			splashes.add(splash);
		}

		// Nota kostümü
		var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		if (noteSkins.length > 0)
		{
			if (!noteSkins.contains(ClientPrefs.data.noteSkin))
				ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin;

			noteSkins.insert(0, ClientPrefs.defaultData.noteSkin);

			var option:Option = new Option(
				Language.getPhrase('visuals_note_skin',      'Nota Kostümleri:'),
				Language.getPhrase('visuals_note_skin_desc', 'Tercih ettiğiniz Nota Kostümü varyasyonunu seçin.'),
				'noteSkin',
				STRING,
				noteSkins);
			addOption(option);
			option.onChange = onChangeNoteSkin;
			noteOptionID = optionsArray.length - 1;
		}

		// Nota efekti
		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
		if (noteSplashes.length > 0)
		{
			if (!noteSplashes.contains(ClientPrefs.data.splashSkin))
				ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin;

			noteSplashes.insert(0, ClientPrefs.defaultData.splashSkin);

			var option:Option = new Option(
				Language.getPhrase('visuals_splash_skin',      'Nota Efekti:'),
				Language.getPhrase('visuals_splash_skin_desc', 'Tercih ettiğiniz Nota Efektini seçin veya kapatın.'),
				'splashSkin',
				STRING,
				noteSplashes);
			addOption(option);
			option.onChange = onChangeSplashSkin;
		}

		var option:Option = new Option(
			Language.getPhrase('visuals_splash_alpha',      'Nota Efekt Şeffaflığı'),
			Language.getPhrase('visuals_splash_alpha_desc', 'Nota Sıçramaları Efektleri ne kadar şeffaf olmalıdır?\n%0 ayarı bunu devre dışı bırakır.'),
			'splashAlpha',
			PERCENT);
		option.scrollSpeed  = 1.6;
		option.minValue     = 0.0;
		option.maxValue     = 1;
		option.changeValue  = 0.1;
		option.decimals     = 1;
		addOption(option);
		option.onChange = playNoteSplashes;

		var option:Option = new Option(
			Language.getPhrase('visuals_hide_hud',      'Arayüzü Gizle'),
			Language.getPhrase('visuals_hide_hud_desc', 'Aktif edilirse, ekran göstergelerinin (HUD) çoğunu gizler.'),
			'hideHud',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('visuals_time_bar',      'Zaman Barı:'),
			Language.getPhrase('visuals_time_bar_desc', 'Zaman Çubuğu neyi göstermelidir?'),
			'timeBarType',
			STRING,
			[
				Language.getPhrase('visuals_time_remaining', 'Kalan Süre'),
				Language.getPhrase('visuals_time_elapsed',   'Geçen Süre'),
				Language.getPhrase('visuals_time_songname',  'Şarkı Adı'),
				Language.getPhrase('visuals_time_disabled',  'Kapalı')
			]);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('visuals_flashing',      'Yanıp / Sönen Işıklar'),
			Language.getPhrase('visuals_flashing_desc', 'Yanıp sönen ışıklara karşı hassassanız bu seçeneğin işaretini kaldırın!'),
			'flashing',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('visuals_cam_zooms',      'Kamera Zoomları'),
			Language.getPhrase('visuals_cam_zooms_desc', 'Aktif Edilmezse, kamera vuruşta yakınlaştırma yapmaz.'),
			'camZooms',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('visuals_score_zoom',      'Skor Yakınlaştırması'),
			Language.getPhrase('visuals_score_zoom_desc', 'Aktif Edilmezse, her nota vuruşunda skor metninin yakınlaşmasını devre dışı bırakır.'),
			'scoreZoom',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('visuals_health_alpha',      'Can Bar Opaklığı'),
			Language.getPhrase('visuals_health_alpha_desc', 'Can Çubuğu ve Simgeler Ne Kadar Şeffaf Olmalı.'),
			'healthBarAlpha',
			PERCENT);
		option.scrollSpeed  = 1.6;
		option.minValue     = 0.0;
		option.maxValue     = 1;
		option.changeValue  = 0.1;
		option.decimals     = 1;
		addOption(option);

		#if !mobile
		var option:Option = new Option(
			Language.getPhrase('visuals_fps_counter',      'FPS Sayacı'),
			Language.getPhrase('visuals_fps_counter_desc', 'Aktif edilmezse, FPS Sayacını gizler.'),
			'showFPS',
			BOOL);
		addOption(option);
		option.onChange = onChangeFPSCounter;
		#end

		var option:Option = new Option(
			Language.getPhrase('visuals_pause_music',      'Durdurma Ekranı Müziği:'),
			Language.getPhrase('visuals_pause_music_desc', 'Durdurma Ekranı İçin Hangi Şarkıyı Tercih Edersin?'),
			'pauseMusic',
			STRING,
			['Hiçbiri', 'Tea Time', 'Breakfast', 'Breakfast (Pico)']);
		addOption(option);
		option.onChange = onChangePauseMusic;

		#if CHECK_FOR_UPDATES
		var option:Option = new Option(
			Language.getPhrase('visuals_check_updates',      'Güncellemeleri Kontrol Et'),
			Language.getPhrase('visuals_check_updates_desc', 'Aktif edilirse, oyunu başlattığınızda güncellemeleri kontrol eder.'),
			'checkForUpdates',
			BOOL);
		addOption(option);
		#end

		#if DISCORD_ALLOWED
		var option:Option = new Option(
			Language.getPhrase('visuals_discord_rpc',      'Discord Durumu'),
			Language.getPhrase('visuals_discord_rpc_desc', 'Aktif edilmezse, kazara veri sızıntılarını önlemek için Discord\'daki Oynuyor Durumundan Uygulamayı gizler.'),
			'discordRPC',
			BOOL);
		addOption(option);
		#end

		var option:Option = new Option(
			Language.getPhrase('visuals_combo_stacking',      'Kombo Stoklama'),
			Language.getPhrase('visuals_combo_stacking_desc', 'Aktif edilmezse, Dereceler ve Kombo üst üste gelmez, sistem belleğinden tasarruf sağlar ve okunması kolaylaşır.'),
			'comboStacking',
			BOOL);
		addOption(option);

		super();
		add(notes);
		add(splashes);
	}

	var notesShown:Bool = false;
	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);

		switch (curOption.variable)
		{
			case 'noteSkin', 'splashSkin', 'splashAlpha':
				if (!notesShown)
				{
					for (note in notes.members)
					{
						FlxTween.cancelTweensOf(note);
						FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
					}
				}
				notesShown = true;
				if (curOption.variable.startsWith('splash') && Math.abs(notes.members[0].y - noteY) < 25)
					playNoteSplashes();

			default:
				if (notesShown)
				{
					for (note in notes.members)
					{
						FlxTween.cancelTweensOf(note);
						FlxTween.tween(note, {y: -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
					}
				}
				notesShown = false;
		}
	}

	var changedMusic:Bool = false;

	function onChangePauseMusic()
	{
		if (ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));

		changedMusic = true;
	}

	function onChangeNoteSkin()
	{
		notes.forEachAlive(function(note:StrumNote) {
			changeNoteSkin(note);
			note.centerOffsets();
			note.centerOrigin();
		});
	}

	function changeNoteSkin(note:StrumNote)
	{
		var skin:String = Note.defaultNoteSkin;
		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if (Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;
		note.texture = skin;
		note.reloadNote();
		note.playAnim('static');
	}

	function onChangeSplashSkin()
	{
		var skin:String = NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix();
		for (splash in splashes)
			splash.loadSplash(skin);
		playNoteSplashes();
	}

	function playNoteSplashes()
	{
		var rand:Int = 0;
		if (splashes.members[0] != null && splashes.members[0].maxAnims > 1)
			rand = FlxG.random.int(0, splashes.members[0].maxAnims - 1);

		for (splash in splashes)
		{
			splash.revive();
			splash.spawnSplashNote(0, 0, splash.ID, null, false);
			if (splash.maxAnims > 1)
				splash.noteData = splash.noteData % Note.colArray.length + (rand * Note.colArray.length);

			var anim:String = splash.playDefaultAnim();
			var conf = splash.config.animations.get(anim);
			var offsets:Array<Float> = [0, 0];
			var minFps:Int = 22;
			var maxFps:Int = 26;

			if (conf != null)
			{
				offsets = conf.offsets;
				minFps  = conf.fps[0]; if (minFps < 0) minFps = 0;
				maxFps  = conf.fps[1]; if (maxFps < 0) maxFps = 0;
			}

			splash.offset.set(10, 10);
			if (offsets != null)
			{
				splash.offset.x += offsets[0];
				splash.offset.y += offsets[1];
			}

			if (splash.animation.curAnim != null)
				splash.animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
		}
	}

	override function destroy()
	{
		if (changedMusic && !OptionsState.onPlayState)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 1, true);
		Note.globalRgbShaders = [];
		super.destroy();
	}

	#if !mobile
	function onChangeFPSCounter()
	{
		if (Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.data.showFPS;
	}
	#end
}
