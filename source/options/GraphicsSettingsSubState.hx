package options;

import objects.Character;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var antialiasingOption:Int;
	var boyfriend:Character = null;

	public function new()
	{
		title    = Language.getPhrase('graphics_menu',    'Graphics & Performance');
		rpcTitle = 'Graphics Settings Menu';

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.finishCallback = function(name:String) boyfriend.dance();
		boyfriend.visible = false;

		var option:Option = new Option(
			Language.getPhrase('graphics_low_quality',      'Düşük Kalite'),
			Language.getPhrase('graphics_low_quality_desc', 'Aktif edilirse, bazı arka plan detaylarını devre dışı bırakır,\nyükleme sürelerini azaltır ve performansı artırır. ÖNERI: AÇIK'),
			'lowQuality',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('graphics_antialiasing',      'Kenar Yumuşatma'),
			Language.getPhrase('graphics_antialiasing_desc', 'Aktif edilmezse, kenar yumuşatmayı devre dışı bırakır, daha keskin görüntüler pahasına performansı artırır. ÖNERI: KAPALI'),
			'antialiasing',
			'BOOL');
		option.onChange = onChangeAntiAliasing;
		addOption(option);
		antialiasingOption = optionsArray.length - 1;

		var option:Option = new Option(
			Language.getPhrase('graphics_shaders',      'Gölgeler'),
			Language.getPhrase('graphics_shaders_desc', 'Aktif edilmezse, gölgelendiricileri devre dışı bırakır.\nBunlar bazı görsel efektler için kullanılır ve zayıf bilgisayarlar için işlemciyi yorabilir. ÖNERI: KAPALI'),
			'shaders',
			'BOOL');
		addOption(option);

		var option:Option = new Option(
			Language.getPhrase('graphics_gpu_cache',      'GPU Önbellekleme'),
			Language.getPhrase('graphics_gpu_cache_desc', 'Aktif edilirse, dokuları önbelleğe almak için GPU kullanılır, böylece RAM kullanımını azaltır. Modlarınız sprite piksellerini değiştiriyorsa bunu açmayın.'),
			'cacheOnGPU',
			'BOOL');
		addOption(option);

		#if !html5
		var option:Option = new Option(
			Language.getPhrase('graphics_framerate',      'Kare Hızı'),
			Language.getPhrase('graphics_framerate_desc', 'Baya Açıklayıcı, değilmi?'),
			'framerate',
			INT);
		addOption(option);
		final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		option.minValue    = 60;
		option.maxValue    = 240;
		option.defaultValue = Std.int(FlxMath.bound(refreshRate, option.minValue, option.maxValue));
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		#end

		super();
		insert(1, boyfriend);
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:FlxSprite = cast sprite;
			if (sprite != null && (sprite is FlxSprite) && !(sprite is FlxText))
				sprite.antialiasing = ClientPrefs.data.antialiasing;
		}
	}

	function onChangeFramerate()
	{
		if (ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate   = ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate   = ClientPrefs.data.framerate;
			FlxG.updateFramerate = ClientPrefs.data.framerate;
		}
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		boyfriend.visible = (antialiasingOption == curSelected);
	}
}
