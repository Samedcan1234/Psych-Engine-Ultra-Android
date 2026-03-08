package states;

import flixel.FlxSubState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.util.FlxGradient;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var isYes:Bool = true;
	var isInfo:Bool = false;
	var texts:FlxTypedSpriteGroup<FlxText>;
	var bg:FlxSprite;
	var panel:FlxSprite;
	var icon:FlxSprite;
	var buttonGroup:FlxSpriteGroup;
	var buttonSprites:Array<FlxSprite> = [];

	override function create()
	{
		super.create();
		
		// Ensure music is not playing during this state
		if(FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			FlxG.sound.music.stop();
		}

		// Gradient arka plan
		bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFF232946, 0xFF393D73, 0xFF232946], 1, 90);
		add(bg);

		// Ortalanmış yarı saydam panel (yuvarlatılmış köşe)
		panel = new FlxSprite((FlxG.width-700)/2, (FlxG.height-350)/2);
		panel.makeGraphic(700, 350, FlxColor.TRANSPARENT);
		drawRoundRect(panel, 0, 0, 700, 350, 32, FlxColor.fromRGB(30,30,40, 220));
		panel.alpha = 0.95;
		FlxTween.tween(panel, {alpha: 1}, 0.7, {ease: FlxEase.cubeOut});
		add(panel);

		// Uyarı simgesi: assets/shared/images/ultra/alert.png
		icon = new FlxSprite(panel.x+40, panel.y+40);
		icon.loadGraphic(Paths.image("ultra/alert"));
		icon.setGraphicSize(100, 100);
		icon.updateHitbox();
		icon.alpha = 0.8;
		// Hareket animasyonu kaldırıldı, ikon sabit duracak
		FlxTween.tween(icon, {alpha: 0.2}, 0.5, {type: FlxTween.PINGPONG, ease: FlxEase.sineInOut});
		add(icon);

		// Uyarı metni
		texts = new FlxTypedSpriteGroup<FlxText>();
		texts.alpha = 0.0;
		add(texts);

		var warnText:FlxText = new FlxText(panel.x+120, panel.y+40, 520,
			"Dikkat!\n\nBu oyun bazı yanıp sönen ışıklar içeriyor.\nOnları devre dışı bırakmak ister misin?");
		warnText.setFormat(Paths.font("vcr.ttf"), 30, FlxColor.WHITE, CENTER);
		warnText.alignment = CENTER;
		texts.add(warnText);

		// Butonlar için grup
		buttonGroup = new FlxSpriteGroup();
		add(buttonGroup);

		final keys = ["Evet", "Hayır"];
		for (i in 0...keys.length) {
			var btnW = 180;
			var btnH = 54;
			var btnX = panel.x + 140 + (i * (btnW+60));
			var btnY = panel.y + 220;
			var btn = new FlxSprite(btnX, btnY);
			btn.makeGraphic(btnW, btnH, FlxColor.TRANSPARENT);
			drawRoundRect(btn, 0, 0, btnW, btnH, 18, FlxColor.fromRGB(60,60,90, 255));
			btn.alpha = 0.7;
			btn.ID = i;
			buttonSprites.push(btn);
			buttonGroup.add(btn);

			var btnText = new FlxText(btnX, btnY+10, btnW, keys[i]);
			btnText.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, CENTER);
			buttonGroup.add(btnText);
		}

		FlxTween.tween(texts, {alpha: 1.0}, 0.5, {
			onComplete: (_) -> updateItems()
		});
	}

	override function update(elapsed:Float)
	{
		// CRITICAL: Update controls FIRST before using them
		super.update(elapsed);
		
		if(leftState) {
			return;
		}
		
		var back:Bool = controls.BACK;
		var changed:Bool = false;
		
		// Butonlar arasında gezinme
		if (controls.UI_LEFT_P) {
			if (!isYes) {
				isYes = true;
				changed = true;
			}
		}
		if (controls.UI_RIGHT_P) {
			if (isYes) {
				isYes = false;
				changed = true;
			}
		}
		
		if (changed) {
			FlxG.sound.play(Paths.sound("scrollMenu"), 0.7);
			updateItems();
		}
		
		if (controls.ACCEPT || back) {
			acceptSelection(back);
		}
		
		// Buton hover animasyonu
		for (i in 0...buttonSprites.length) {
			var btn = buttonSprites[i];
			var sel = (i == 0 && isYes) || (i == 1 && !isYes);
			btn.alpha = sel ? 1.0 : 0.7;
			btn.color = sel ? FlxColor.fromRGB(255, 200, 60) : FlxColor.fromRGB(60,60,90);
		}
	}

	function acceptSelection(isBack:Bool = false)
	{
		if(leftState) return;
		
		leftState = true;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		
		var fadeTime = 0.5;
		var fadeToBlack = function() {
			// Arka planı siyaha tweenle
			FlxTween.color(bg, fadeTime, bg.color, FlxColor.BLACK);
			// Diğer tüm objeleri kaybolmaya tweenle
			FlxTween.tween(panel, {alpha: 0}, fadeTime);
			FlxTween.tween(icon, {alpha: 0}, fadeTime);
			FlxTween.tween(buttonGroup, {alpha: 0}, fadeTime);
			FlxTween.tween(texts, {alpha: 0}, fadeTime, {
				onComplete: (_) -> MusicBeatState.switchState(new MainMenuState())
			});
		};
		
		if(!isBack) {
			ClientPrefs.data.flashing = !isYes;
			ClientPrefs.saveSettings();
			FlxG.sound.play(Paths.sound('confirmMenu'));
			final button = buttonSprites[isYes ? 0 : 1];
			FlxFlicker.flicker(button, 1, 0.1, false, true, function(flk:FlxFlicker) {
				new FlxTimer().start(0.5, function (tmr:FlxTimer) {
					fadeToBlack();
				});
			});
		} else {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			fadeToBlack();
		}
	}

	function changeButton(direction:Int)
	{
		if(leftState) return;
		
		if(direction > 0) {
			// Sağa git
			if (isYes) isYes = false;
		} else if(direction < 0) {
			// Sola git
			if (!isYes) isYes = true;
		}
		
		FlxG.sound.play(Paths.sound("scrollMenu"), 0.7);
		updateItems();
	}

	function updateItems() {
		// Buton metinlerinin alpha ve renklerini güncelle
		for (i in 0...buttonGroup.length) {
			var obj = buttonGroup.members[i];
			if (Std.isOfType(obj, FlxText)) {
				var idx = Math.floor(i/2);
				var sel = (idx == 0 && isYes) || (idx == 1 && !isYes);
				cast(obj, FlxText).alpha = sel ? 1.0 : 0.7;
				cast(obj, FlxText).color = sel ? FlxColor.YELLOW : FlxColor.WHITE;
			}
		}
	}

	// Yuvarlatılmış dikdörtgen çizimi (FlxSprite'a)
	function drawRoundRect(sprite:FlxSprite, x:Float, y:Float, w:Float, h:Float, radius:Float, color:Int) {
		#if (openfl && !flash)
		var gfx = new openfl.display.Shape();
		gfx.graphics.beginFill(color);
		gfx.graphics.drawRoundRect(x, y, w, h, radius*2, radius*2);
		gfx.graphics.endFill();
		var bd = new openfl.display.BitmapData(Math.ceil(w), Math.ceil(h), true, 0x0);
		bd.draw(gfx);
		sprite.pixels = bd;
		sprite.dirty = true;
		#end
	}
	
	override function destroy()
	{
		leftState = false;
		super.destroy();
	}
}