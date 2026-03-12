package options;

import objects.Character;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var antialiasingOption:Int;
	var boyfriend:Character = null;
	public function new()
	{
		title = Language.getPhrase('graphics_menu', 'Grafik ve Performans');
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.finishCallback = function (name:String) boyfriend.dance();
		boyfriend.visible = false;

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Düsük Kalite', //Name
			'Aktif edilirse, bazı arka plan detaylarını devre dışı bırakır,\nyükleme sürelerini azaltır ve performansı artırır. ÖNERI: AÇIK', //Description
			'lowQuality', //Save data variable name
			BOOL); //Variable type
		addOption(option);

		var option:Option = new Option('Kenar Yumusatma',
			'Aktif edilmezse, kenar yumuşatmayı (anti-aliasing) devre dışı bırakır, daha keskin görüntüler pahasına performansı artırır. ÖNERI: KAPALI',
			'antialiasing',
			'BOOL');
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		antialiasingOption = optionsArray.length-1;

		var option:Option = new Option('Gölgeler', //Name
			"Aktif edilmezse, gölgelendiricileri devre dışı bırakır.\nBunlar bazı görsel efektler için kullanılır ve zayıf bilgisayarlar için işlemciyi yorabilir. ÖNERI: KAPALI", //Description
			'shaders',
			'BOOL');
		addOption(option);

		var option:Option = new Option('GPU Önbellekleme', //Name
		 	"Aktif edilirse, dokuları (textures) önbelleğe almak için GPU'nun kullanılmasına izin verir, böylece RAM kullanımını azaltır. Modlarınızdan herhangi biri sprite'ların (grafik öğelerinin) piksellerini değiştiriyorsa bunu açmayın.", //Description
		 	'cacheOnGPU',
			'BOOL');
		addOption(option);

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Kare hizi',
			"Baya Açıklayıcı, değilmi?",
			'framerate',
			INT);
		addOption(option);

		final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		option.minValue = 60;
		option.maxValue = 240;
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
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.data.antialiasing;
			}
		}
	}

	function onChangeFramerate()
	{
		if(ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate = ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.data.framerate;
			FlxG.updateFramerate = ClientPrefs.data.framerate;
		}
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		boyfriend.visible = (antialiasingOption == curSelected);
	}
}