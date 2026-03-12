package objects;

#if android
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import mobile.backend.StorageUtil;

/**
 * Android için oyun içi dosya tarayıcısı.
 * StorageUtil üzerinden erişilebilen dizinleri tarar,
 * bulunan dosyaları liste olarak gösterir.
 */
class AndroidFileBrowser extends MusicBeatSubstate
{
	public var onFileSelected:String->Void;
	public var onCancel:Void->Void;

	var fileExtension:String;

	var bg:FlxSprite;
	var topBar:FlxSprite;
	var titleTxt:FlxText;
	var infoTxt:FlxText;
	var listGroup:FlxTypedGroup<FlxText>;
	var scrollBg:FlxSprite;

	var files:Array<String> = [];
	var curSelected:Int = 0;

	// Taranacak dizinler
	var searchDirs:Array<String> = [];

	public function new(fileExtension:String = '.sol')
	{
		super();
		this.fileExtension = fileExtension;

		// StorageUtil'den dizinleri al
		searchDirs = [
			StorageUtil.getExternalStorageDirectory(),           // /sdcard/.PsychEngine/
			StorageUtil.getStorageDirectory(),                   // app-specific external
			'/sdcard/Download/',
			'/sdcard/Documents/',
			'/storage/emulated/0/Download/',
			'/storage/emulated/0/Documents/',
		];

		buildUI();
		scanFiles();
		refreshList();
	}

	function buildUI()
	{
		// Karartma
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xCC000000);
		bg.scrollFactor.set();
		bg.alpha = 0;
		add(bg);
		FlxTween.tween(bg, {alpha: 1}, 0.3, {ease: FlxEase.quartOut});

		// Üst bar
		topBar = new FlxSprite(0, -80).makeGraphic(FlxG.width, 80, 0xFF111111);
		topBar.scrollFactor.set();
		add(topBar);
		FlxTween.tween(topBar, {y: 0}, 0.4, {ease: FlxEase.expoOut});

		titleTxt = new FlxText(0, 15, FlxG.width, 'Dosya Seç (*$fileExtension)', 32);
		titleTxt.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
		titleTxt.scrollFactor.set();
		add(titleTxt);

		infoTxt = new FlxText(0, FlxG.height - 45, FlxG.width, 'YUKARI/AŞAĞI = Gezin  |  ENTER = Seç  |  ESC = İptal', 22);
		infoTxt.setFormat(Paths.font('vcr.ttf'), 22, 0xFFAAAAAA, CENTER);
		infoTxt.scrollFactor.set();
		add(infoTxt);

		// Liste alanı arka planı
		scrollBg = new FlxSprite(30, 90).makeGraphic(FlxG.width - 60, FlxG.height - 150, 0x88000000);
		scrollBg.scrollFactor.set();
		add(scrollBg);

		listGroup = new FlxTypedGroup<FlxText>();
		add(listGroup);
	}

	function scanFiles()
	{
		files = [];
		#if sys
		for (dir in searchDirs)
		{
			try
			{
				if (!sys.FileSystem.exists(dir) || !sys.FileSystem.isDirectory(dir))
					continue;
				scanDirectory(dir, 0);
			}
			catch (e:Dynamic)
			{
				trace('AndroidFileBrowser: Dizin tarama hatası ($dir): $e');
			}
		}
		#end
		trace('AndroidFileBrowser: ${files.length} dosya bulundu.');
	}

	#if sys
	function scanDirectory(path:String, depth:Int)
	{
		if (depth > 2) return; // Çok derin tarama yapma
		try
		{
			var entries = sys.FileSystem.readDirectory(path);
			for (entry in entries)
			{
				var fullPath = haxe.io.Path.addTrailingSlash(path) + entry;
				if (sys.FileSystem.isDirectory(fullPath))
					scanDirectory(fullPath, depth + 1);
				else if (entry.toLowerCase().endsWith(fileExtension.toLowerCase()))
					files.push(fullPath);
			}
		}
		catch (e:Dynamic)
		{
			trace('AndroidFileBrowser: Alt dizin hatası ($path): $e');
		}
	}
	#end

	function refreshList()
	{
		// Eski metinleri temizle
		listGroup.clear();

		if (files.length == 0)
		{
			var noFile = new FlxText(0, FlxG.height / 2 - 20, FlxG.width,
				'$fileExtension dosyası bulunamadı.\nŞu dizinler tarandı:\n' + searchDirs.join('\n'), 22);
			noFile.setFormat(Paths.font('vcr.ttf'), 22, 0xFFFF6666, CENTER);
			noFile.scrollFactor.set();
			listGroup.add(noFile);
			return;
		}

		var visibleCount:Int = 8; // Ekranda gösterilecek satır
		var startY:Float = 100;
		var rowH:Float = 60;

		var startIdx = Std.int(Math.max(0, curSelected - Std.int(visibleCount / 2)));
		var endIdx = Std.int(Math.min(files.length, startIdx + visibleCount));

		for (i in startIdx...endIdx)
		{
			var shortName = haxe.io.Path.withoutDirectory(files[i]);
			var row = new FlxText(50, startY + (i - startIdx) * rowH, FlxG.width - 100, shortName, 26);
			row.setFormat(Paths.font('vcr.ttf'), 26,
				i == curSelected ? FlxColor.WHITE : 0xFF888888,
				LEFT);
			row.scrollFactor.set();
			if (i == curSelected)
			{
				// Seçili satır vurgusu
				var highlight = new FlxSprite(30, row.y - 5).makeGraphic(FlxG.width - 60, 50, 0x44FFFFFF);
				highlight.scrollFactor.set();
				listGroup.add(highlight);
			}
			listGroup.add(row);
		}

		// Sayaç
		var counter = new FlxText(0, FlxG.height - 80, FlxG.width, '${curSelected + 1} / ${files.length}', 22);
		counter.setFormat(Paths.font('vcr.ttf'), 22, 0xFFAAAAAA, CENTER);
		counter.scrollFactor.set();
		listGroup.add(counter);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (files.length > 0)
		{
			if (controls.UI_UP_P)
			{
				curSelected = FlxMath.wrap(curSelected - 1, 0, files.length - 1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				refreshList();
			}
			if (controls.UI_DOWN_P)
			{
				curSelected = FlxMath.wrap(curSelected + 1, 0, files.length - 1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				refreshList();
			}
			if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				var selected = files[curSelected];
				closeWithAnimation(function() {
					if (onFileSelected != null) onFileSelected(selected);
				});
				return;
			}
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			closeWithAnimation(function() {
				if (onCancel != null) onCancel();
			});
		}
	}

	function closeWithAnimation(callback:Void->Void)
	{
		FlxTween.tween(bg, {alpha: 0}, 0.25, {ease: FlxEase.quartIn});
		FlxTween.tween(topBar, {y: -80}, 0.25, {ease: FlxEase.backIn, onComplete: function(_) {
			close();
			callback();
		}});
	}
}
#end
