package options;

import backend.InputFormatter;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import objects.AttachedSprite;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;

class ControlsSubState extends MusicBeatSubstate
{
	var curSelected:Int = 0;
	var curAlt:Bool = false;
	var curCategory:Int = 0;

	// Kategori sistemi
	var categories:Array<String> = ['NOTES', 'UI', 'GENERAL', 'VOLUME', 'DEBUG'];
	var categoryColors:Map<String, FlxColor> = [
		'NOTES' => 0xFFFF6B6B,
		'UI' => 0xFF4ECDC4,
		'GENERAL' => 0xFFFFE66D,
		'VOLUME' => 0xFF95E1D3,
		'DEBUG' => 0xFFA8E6CF
	];

	//Show on gamepad - Display name - Save file key - Rebind display name - Category
	var options:Array<Dynamic> = [
		[true, 'NOTES'],
		[true, 'Left', 'note_left', 'Note Left', 'NOTES'],
		[true, 'Down', 'note_down', 'Note Down', 'NOTES'],
		[true, 'Up', 'note_up', 'Note Up', 'NOTES'],
		[true, 'Right', 'note_right', 'Note Right', 'NOTES'],
		[true],
		[true, 'UI'],
		[true, 'Left', 'ui_left', 'UI Left', 'UI'],
		[true, 'Down', 'ui_down', 'UI Down', 'UI'],
		[true, 'Up', 'ui_up', 'UI Up', 'UI'],
		[true, 'Right', 'ui_right', 'UI Right', 'UI'],
		[true],
		[true, 'Reset', 'reset', 'Reset', 'GENERAL'],
		[true, 'Accept', 'accept', 'Accept', 'GENERAL'],
		[true, 'Back', 'back', 'Back', 'GENERAL'],
		[true, 'Pause', 'pause', 'Pause', 'GENERAL'],
		[true, 'XQ Boku', 'xqboku', 'XQ Boku', 'GENERAL'],
		[false],
		[false, 'VOLUME'],
		[false, 'Mute', 'volume_mute', 'Volume Mute', 'VOLUME'],
		[false, 'Up', 'volume_up', 'Volume Up', 'VOLUME'],
		[false, 'Down', 'volume_down', 'Volume Down', 'VOLUME'],
		[false],
		[false, 'DEBUG'],
		[false, 'Key 1', 'debug_1', 'Debug Key #1', 'DEBUG'],
		[false, 'Key 2', 'debug_2', 'Debug Key #2', 'DEBUG']
	];

	var curOptions:Array<Int>;
	var curOptionsValid:Array<Int>;
	var categoryOptions:Map<String, Array<Int>> = new Map();
	static var defaultKey:String = 'Reset to Default Keys';

	var bg:FlxSprite;
	var categoryBg:FlxSprite;
	var grpDisplay:FlxTypedGroup<Alphabet>;
	var grpBlacks:FlxTypedGroup<AttachedSprite>;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpBinds:FlxTypedGroup<Alphabet>;
	var grpCategoryIcons:FlxTypedGroup<FlxSprite>;
	var selectSpr:AttachedSprite;
	var categorySelectSpr:AttachedSprite;

	var gamepadColor:FlxColor = 0xfffd7194;
	var keyboardColor:FlxColor = 0xff7192fd;
	var onKeyboardMode:Bool = true;
	
	var controllerSpr:FlxSprite;
	var modeIndicator:FlxText;
	
	// Profil sistemi
	var currentProfile:String = 'Default';
	var profileText:Alphabet;
	var profiles:Array<String> = ['Default', 'Wasd', 'Arrows', 'Custom1', 'Custom2'];

	var showCategoryMenu:Bool = false;
	var animationProgress:Float = 0;
	var lastInputTime:Float = 0;
	var inputCooldown:Float = 0.1;

	public function new()
	{
		super();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Controls Menu - Modernized", null);
		#end

		options.push([true]);
		options.push([true]);
		options.push([true, defaultKey]);

		// Arka plan
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = keyboardColor;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		add(bg);

		// Grid animasyon
		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		// Kategori arka planı
		categoryBg = new FlxSprite(0, 0).makeGraphic(200, FlxG.height, 0xFF1A1A2E);
		categoryBg.alpha = 0.9;
		add(categoryBg);

		grpDisplay = new FlxTypedGroup<Alphabet>();
		add(grpDisplay);
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		grpBlacks = new FlxTypedGroup<AttachedSprite>();
		add(grpBlacks);
		grpCategoryIcons = new FlxTypedGroup<FlxSprite>();
		add(grpCategoryIcons);

		selectSpr = new AttachedSprite();
		selectSpr.makeGraphic(250, 78, FlxColor.WHITE);
		selectSpr.copyAlpha = false;
		selectSpr.alpha = 0.75;
		add(selectSpr);

		categorySelectSpr = new AttachedSprite();
		categorySelectSpr.makeGraphic(190, 50, FlxColor.YELLOW);
		categorySelectSpr.copyAlpha = false;
		categorySelectSpr.alpha = 0.5;
		add(categorySelectSpr);

		grpBinds = new FlxTypedGroup<Alphabet>();
		add(grpBinds);

		// Controller göstergesi
		controllerSpr = new FlxSprite(50, 40).loadGraphic(Paths.image('controllertype'), true, 82, 60);
		controllerSpr.antialiasing = ClientPrefs.data.antialiasing;
		controllerSpr.animation.add('keyboard', [0], 1, false);
		controllerSpr.animation.add('gamepad', [1], 1, false);
		add(controllerSpr);

		// Başlık
		var titleText:Alphabet = new Alphabet(220, 20, 'CTRL', false);
		titleText.alignment = CENTERED;
		titleText.setScale(0.6);
		add(titleText);

		// Mod göstergesi
		modeIndicator = new FlxText(220, 60, 300, onKeyboardMode ? 'KEYBOARD MODE' : 'GAMEPAD MODE', 16);
		modeIndicator.alignment = CENTER;
		modeIndicator.color = onKeyboardMode ? keyboardColor : gamepadColor;
		add(modeIndicator);

		// Profil göstergesi
		profileText = new Alphabet(220, 90, 'Profile: $currentProfile', false);
		profileText.alignment = CENTERED;
		profileText.setScale(0.4);
		add(profileText);

		createCategoryTexts();
		createTexts();
	}

	function createCategoryTexts()
	{
		grpCategoryIcons.forEachAlive(function(icon:FlxSprite) icon.destroy());
		grpCategoryIcons.clear();

		for (i => category in categories)
		{
			var categoryText:Alphabet = new Alphabet(20, 150 + i * 60, category, false);
			categoryText.isMenuItem = true;
			categoryText.changeX = false;
			categoryText.setScale(0.5);
			categoryText.ID = i;
			categoryText.targetY = i;
			add(categoryText);
			grpCategoryIcons.add(categoryText);
		}
	}

	var lastID:Int = 0;
	function createTexts()
	{
		curOptions = [];
		curOptionsValid = [];
		categoryOptions.clear();

		grpDisplay.forEachAlive(function(text:Alphabet) text.destroy());
		grpBlacks.forEachAlive(function(black:AttachedSprite) black.destroy());
		grpOptions.forEachAlive(function(text:Alphabet) text.destroy());
		grpBinds.forEachAlive(function(text:Alphabet) text.destroy());

		grpDisplay.clear();
		grpBlacks.clear();
		grpOptions.clear();
		grpBinds.clear();

		var myID:Int = 0;

		for (i => option in options)
		{
			if(onKeyboardMode || option[0])
			{
				if(option.length > 1)
				{
					var isCentered:Bool = (option.length < 3);
					var isDefaultKey:Bool = (option[1] == defaultKey);
					var isDisplayKey:Bool = (isCentered && !isDefaultKey);

					var str:String = option[1];
					var keyStr:String = option[2];
					if(isDefaultKey) str = Language.getPhrase(str);

					var text:Alphabet = new Alphabet(475, 300, !isDisplayKey ? Language.getPhrase('key_$keyStr', str) : Language.getPhrase('keygroup_$str', str), !isDisplayKey);
					text.isMenuItem = true;
					text.changeX = false;
					text.distancePerItem.y = 60;
					text.targetY = myID;
					text.ID = myID;
					lastID = myID;

					if(!isDisplayKey)
					{
						text.alignment = RIGHT;
						grpOptions.add(text);
						curOptions.push(i);
						curOptionsValid.push(myID);

						// Kategoriye göre sakla
						if(option.length > 4)
						{
							var cat = option[4];
							if(!categoryOptions.exists(cat))
								categoryOptions.set(cat, []);
							categoryOptions.get(cat).push(curOptions.length - 1);
						}
					}
					else grpDisplay.add(text);

					if(isCentered) addCenteredText(text, option, myID);
					else addKeyText(text, option, myID);

					text.snapToPosition();
					text.y += FlxG.height * 2;
				}
				myID++;
			}
		}
		updateText();
	}

	function addCenteredText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		text.alignment = LEFT;
		text.screenCenter(X);
		text.x += 100;
		text.y -= 55;
		text.startPosition.y -= 55;
	}

	function addKeyText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		var keys:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option[2]);
		if(keys == null && onKeyboardMode)
			keys = ClientPrefs.defaultKeys.get(option[2]).copy();

		var gmpds:Array<Null<FlxGamepadInputID>> = ClientPrefs.gamepadBinds.get(option[2]);
		if(gmpds == null && !onKeyboardMode)
			gmpds = ClientPrefs.defaultButtons.get(option[2]).copy();

		for (n in 0...2)
		{
			var key:String = null;
			if(onKeyboardMode)
				key = InputFormatter.getKeyName((keys[n] != null) ? keys[n] : NONE);
			else
				key = InputFormatter.getGamepadName((gmpds[n] != null) ? gmpds[n] : NONE);

			var attach:Alphabet = new Alphabet(560 + n * 300, 248, key, false);
			attach.isMenuItem = true;
			attach.changeX = false;
			attach.distancePerItem.y = 60;
			attach.targetY = text.targetY;
			attach.ID = Math.floor(grpBinds.length / 2);
			attach.snapToPosition();
			attach.y += FlxG.height * 2;
			grpBinds.add(attach);

			playstationCheck(attach);
			attach.scaleX = Math.min(1, 230 / attach.width);

			// Siyah bar
			var black:AttachedSprite = new AttachedSprite();
			black.makeGraphic(250, 78, FlxColor.BLACK);
			black.alphaMult = 0.4;
			black.sprTracker = text;
			black.yAdd = -6;
			black.xAdd = 75 + n * 300;
			grpBlacks.add(black);
		}
	}

	function playstationCheck(alpha:Alphabet)
	{
		if(onKeyboardMode) return;

		var gamepad:FlxGamepad = FlxG.gamepads.firstActive;
		var model:FlxGamepadModel = gamepad != null ? gamepad.detectedModel : UNKNOWN;
		var letter = alpha.letters[0];

		if(model == PS4)
		{
			switch(alpha.text)
			{
				case '[', ']':
					letter.image = 'alphabet_playstation';
					letter.updateHitbox();
					letter.offset.x += 4;
					letter.offset.y -= 5;
			}
		}
	}

	function updateBind(num:Int, text:String)
	{
		var bind:Alphabet = grpBinds.members[num];
		var attach:Alphabet = new Alphabet(350 + (num % 2) * 300, 248, text, false);
		attach.isMenuItem = true;
		attach.changeX = false;
		attach.distancePerItem.y = 60;
		attach.targetY = bind.targetY;
		attach.ID = bind.ID;
		attach.x = bind.x;
		attach.y = bind.y;
		
		playstationCheck(attach);
		attach.scaleX = Math.min(1, 230 / attach.width);

		bind.kill();
		grpBinds.remove(bind);
		grpBinds.insert(num, attach);
		bind.destroy();
	}

	var binding:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;
	var timeForMoving:Float = 0.1;

	override function update(elapsed:Float)
	{
		if(timeForMoving > 0)
		{
			timeForMoving = Math.max(0, timeForMoving - elapsed);
			super.update(elapsed);
			return;
		}

		lastInputTime += elapsed;

		if(!binding)
		{
			// ESC tuşu - Çıkış
			if(FlxG.keys.justPressed.ESCAPE || FlxG.gamepads.anyJustPressed(B))
			{
				close();
				return;
			}

			// TAB tuşu - Kategoriler menüsü
			if(FlxG.keys.justPressed.TAB)
			{
				showCategoryMenu = !showCategoryMenu;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				return;
			}

			// CTRL tuşu - Mod değiştir
			if(FlxG.keys.justPressed.CONTROL || FlxG.gamepads.anyJustPressed(LEFT_SHOULDER) || FlxG.gamepads.anyJustPressed(RIGHT_SHOULDER))
			{
				swapMode();
				return;
			}

			// Kategori menüsü aktif mi?
			if(showCategoryMenu)
			{
				if((FlxG.keys.justPressed.UP || FlxG.gamepads.anyJustPressed(DPAD_UP)) && lastInputTime > inputCooldown)
				{
					curCategory = FlxMath.wrap(curCategory - 1, 0, categories.length - 1);
					lastInputTime = 0;
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else if((FlxG.keys.justPressed.DOWN || FlxG.gamepads.anyJustPressed(DPAD_DOWN)) && lastInputTime > inputCooldown)
				{
					curCategory = FlxMath.wrap(curCategory + 1, 0, categories.length - 1);
					lastInputTime = 0;
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else if((FlxG.keys.justPressed.RIGHT || FlxG.gamepads.anyJustPressed(DPAD_RIGHT)) && lastInputTime > inputCooldown)
				{
					showCategoryMenu = false;
					curSelected = 0;
					lastInputTime = 0;
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else if(FlxG.keys.justPressed.ENTER || FlxG.gamepads.anyJustPressed(A))
				{
					showCategoryMenu = false;
					curSelected = 0;
					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
			}
			else
			{
				// Sol/Sağ - Alternatif bind
				if(FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.gamepads.anyJustPressed(DPAD_LEFT) || FlxG.gamepads.anyJustPressed(DPAD_RIGHT) ||
					FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_LEFT) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_RIGHT))
					updateAlt(true);

				// Yukarı/Aşağı - Seçim değiştir
				if((FlxG.keys.justPressed.UP || FlxG.gamepads.anyJustPressed(DPAD_UP) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_UP)) && lastInputTime > inputCooldown)
				{
					updateText(-1);
					lastInputTime = 0;
				}
				else if((FlxG.keys.justPressed.DOWN || FlxG.gamepads.anyJustPressed(DPAD_DOWN) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_DOWN)) && lastInputTime > inputCooldown)
				{
					updateText(1);
					lastInputTime = 0;
				}

				// Enter - Bind değiştir veya Reset
				if(FlxG.keys.justPressed.ENTER || FlxG.gamepads.anyJustPressed(START) || FlxG.gamepads.anyJustPressed(A))
				{
					if(options[curOptions[curSelected]][1] != defaultKey)
					{
						startBinding();
					}
					else
					{
						// Reset to Default
						ClientPrefs.resetKeys(!onKeyboardMode);
						ClientPrefs.reloadVolumeKeys();
						var lastSel:Int = curSelected;
						createTexts();
						curSelected = lastSel;
						updateText();
						FlxG.sound.play(Paths.sound('cancelMenu'));
					}
				}

				// P tuşu - Profil değiştir
				if(FlxG.keys.justPressed.P && lastInputTime > inputCooldown)
				{
					switchProfile();
					lastInputTime = 0;
				}
			}

			// Kategori seçici animasyon
			if(showCategoryMenu)
			{
				categorySelectSpr.y = 150 + curCategory * 60;
				categorySelectSpr.visible = true;
			}
			else
			{
				categorySelectSpr.visible = false;
			}
		}
		else
		{
			handleBinding(elapsed);
		}

		super.update(elapsed);
	}

	function startBinding()
	{
		bindingBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		bindingBlack.scale.set(FlxG.width, FlxG.height);
		bindingBlack.updateHitbox();
		bindingBlack.alpha = 0;
		FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
		add(bindingBlack);

		bindingText = new Alphabet(FlxG.width / 2, 160, Language.getPhrase('controls_rebinding', 'Rebinding {1}', [options[curOptions[curSelected]][3]]), false);
		bindingText.alignment = CENTERED;
		add(bindingText);
		
		bindingText2 = new Alphabet(FlxG.width / 2, 340, Language.getPhrase('controls_rebinding2', 'Hold ESC to Cancel\nHold Backspace to Delete'), true);
		bindingText2.alignment = CENTERED;
		add(bindingText2);

		binding = true;
		holdingEsc = 0;
		ClientPrefs.toggleVolumeKeys(false);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function handleBinding(elapsed:Float)
	{
		var altNum:Int = curAlt ? 1 : 0;
		var curOption:Array<Dynamic> = options[curOptions[curSelected]];

		if(FlxG.keys.pressed.ESCAPE || FlxG.gamepads.anyPressed(B))
		{
			holdingEsc += elapsed;
			if(holdingEsc > 0.5)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else if (FlxG.keys.pressed.BACKSPACE || FlxG.gamepads.anyPressed(BACK))
		{
			holdingEsc += elapsed;
			if(holdingEsc > 0.5)
			{
				if (onKeyboardMode)
					ClientPrefs.keyBinds.get(curOption[2])[altNum] = NONE;
				else
					ClientPrefs.gamepadBinds.get(curOption[2])[altNum] = NONE;
				ClientPrefs.clearInvalidKeys(curOption[2]);
				updateBind(Math.floor(curSelected * 2) + altNum, onKeyboardMode ? InputFormatter.getKeyName(NONE) : InputFormatter.getGamepadName(NONE));
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else
		{
			holdingEsc = 0;
			var changed:Bool = false;
			var curKeys:Array<FlxKey> = ClientPrefs.keyBinds.get(curOption[2]);
			var curButtons:Array<FlxGamepadInputID> = ClientPrefs.gamepadBinds.get(curOption[2]);

			if(onKeyboardMode)
			{
				if(FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
				{
					var keyPressed:Int = FlxG.keys.firstJustPressed();
					var keyReleased:Int = FlxG.keys.firstJustReleased();
					if (keyPressed > -1 && keyPressed != FlxKey.ESCAPE && keyPressed != FlxKey.BACKSPACE)
					{
						curKeys[altNum] = keyPressed;
						changed = true;
					}
					else if (keyReleased > -1 && (keyReleased == FlxKey.ESCAPE || keyReleased == FlxKey.BACKSPACE))
					{
						curKeys[altNum] = keyReleased;
						changed = true;
					}
				}
			}
			else if(FlxG.gamepads.anyJustPressed(ANY) || FlxG.gamepads.anyJustPressed(LEFT_TRIGGER) || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER) || FlxG.gamepads.anyJustReleased(ANY))
			{
				var keyPressed:Null<FlxGamepadInputID> = NONE;
				var keyReleased:Null<FlxGamepadInputID> = NONE;
				if(FlxG.gamepads.anyJustPressed(LEFT_TRIGGER)) keyPressed = LEFT_TRIGGER;
				else if(FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER)) keyPressed = RIGHT_TRIGGER;
				else
				{
					for (i in 0...FlxG.gamepads.numActiveGamepads)
					{
						var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
						if(gamepad != null)
						{
							keyPressed = gamepad.firstJustPressedID();
							keyReleased = gamepad.firstJustReleasedID();

							if(keyPressed == null) keyPressed = NONE;
							if(keyReleased == null) keyReleased = NONE;
							if(keyPressed != NONE || keyReleased != NONE) break;
						}
					}
				}

				if (keyPressed != NONE && keyPressed != FlxGamepadInputID.BACK && keyPressed != FlxGamepadInputID.B)
				{
					curButtons[altNum] = keyPressed;
					changed = true;
				}
				else if (keyReleased != NONE && (keyReleased == FlxGamepadInputID.BACK || keyReleased == FlxGamepadInputID.B))
				{
					curButtons[altNum] = keyReleased;
					changed = true;
				}
			}

			if(changed)
			{
				if (onKeyboardMode)
				{
					if(curKeys[altNum] == curKeys[1 - altNum])
						curKeys[1 - altNum] = FlxKey.NONE;
				}
				else
				{
					if(curButtons[altNum] == curButtons[1 - altNum])
						curButtons[1 - altNum] = FlxGamepadInputID.NONE;
				}

				var option:String = options[curOptions[curSelected]][2];
				ClientPrefs.clearInvalidKeys(option);
				for (n in 0...2)
				{
					var key:String = null;
					if(onKeyboardMode)
					{
						var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option);
						key = InputFormatter.getKeyName(savKey[n] != null ? savKey[n] : NONE);
					}
					else
					{
						var savKey:Array<Null<FlxGamepadInputID>> = ClientPrefs.gamepadBinds.get(option);
						key = InputFormatter.getGamepadName(savKey[n] != null ? savKey[n] : NONE);
					}
					updateBind(Math.floor(curSelected * 2) + n, key);
				}
				FlxG.sound.play(Paths.sound('confirmMenu'));
				closeBinding();
			}
		}
	}

	function closeBinding()
	{
		binding = false;
		bindingBlack.destroy();
		remove(bindingBlack);
		bindingText.destroy();
		remove(bindingText);
		bindingText2.destroy();
		remove(bindingText2);
		ClientPrefs.reloadVolumeKeys();
	}

	function switchProfile()
	{
		var currentIndex = profiles.indexOf(currentProfile);
		var nextIndex = (currentIndex + 1) % profiles.length;
		currentProfile = profiles[nextIndex];
		
		profileText.text = 'Profile: $currentProfile';
		FlxG.sound.play(Paths.sound('confirmMenu'));
		
		// Profil kaydını yükle (gelecekte impl edilebilir)
		trace('Switched to profile: $currentProfile');
	}

	function updateText(?change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, curOptions.length - 1);

		var num:Int = curOptionsValid[curSelected];
		var addNum:Int = 0;
		if(num < 3) addNum = 3 - num;
		else if(num > lastID - 4) addNum = (lastID - 4) - num;

		grpDisplay.forEachAlive(function(item:Alphabet) {
			item.targetY = item.ID - num - addNum;
		});

		grpOptions.forEachAlive(function(item:Alphabet)
		{
			item.targetY = item.ID - num - addNum;
			item.alpha = (item.ID - num == 0) ? 1 : 0.6;
		});

		grpBinds.forEachAlive(function(item:Alphabet)
		{
			var parent:Alphabet = grpOptions.members[item.ID];
			item.targetY = parent.targetY;
			item.alpha = parent.alpha;
		});

		updateAlt();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function swapMode()
	{
		FlxTween.cancelTweensOf(bg);
		FlxTween.color(bg, 0.5, bg.color, onKeyboardMode ? gamepadColor : keyboardColor, {ease: FlxEase.linear});
		onKeyboardMode = !onKeyboardMode;
		modeIndicator.text = onKeyboardMode ? 'KEYBOARD MODE' : 'GAMEPAD MODE';
		modeIndicator.color = onKeyboardMode ? keyboardColor : gamepadColor;

		curSelected = 0;
		curAlt = false;
		controllerSpr.animation.play(onKeyboardMode ? 'keyboard' : 'gamepad');
		createTexts();
		FlxG.sound.play(Paths.sound('confirmMenu'));
	}

	function updateAlt(?doSwap:Bool = false)
	{
		if(doSwap)
		{
			curAlt = !curAlt;
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		selectSpr.sprTracker = grpBlacks.members[Math.floor(curSelected * 2) + (curAlt ? 1 : 0)];
		selectSpr.visible = (selectSpr.sprTracker != null);
	}
}