package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxTimer;
import flixel.util.FlxGradient;
import backend.MusicBeatState;

class QuantumSecretState extends MusicBeatState
{
	var titleText:FlxText;
	var secretText:FlxText;
	var instructionText:FlxText;
	var particleEmitter:FlxEmitter;
	var glowSprite:FlxSprite;
	
	var secretMessages:Array<String> = [
		"QUANTUM EDITION UNLOCKED!",
		"Gizli Kod: XQ-2025",
		"Gelistirici Modu Aktif!",
		"Easter Egg Bulundu!",
		"Sen Bir Efsanesin!"
	];
	
	var animTimer:Float = 0;

	override function create()
	{
		super.create();
		
		// Dark background with gradient
		var bg:FlxSprite = FlxGradient.createGradientFlxSprite(
			FlxG.width,
			FlxG.height,
			[0xFF000033, 0xFF330066, 0xFF000033],
			1, 90
		);
		add(bg);
		
		// Animated particles
		particleEmitter = new FlxEmitter(FlxG.width / 2, FlxG.height / 2, 100);
		
		for (i in 0...100)
		{
			var particle:FlxParticle = new FlxParticle();
			particle.makeGraphic(6, 6, FlxColor.PURPLE);
			particle.exists = false;
			particleEmitter.add(particle);
		}
		
		particleEmitter.launchMode = FlxEmitterMode.CIRCLE;
		particleEmitter.velocity.set(-200, -200, 200, 200);
		particleEmitter.lifespan.set(2, 4);
		particleEmitter.alpha.set(0.8, 1, 0, 0);
		particleEmitter.scale.set(1, 1.5, 0, 0);
		particleEmitter.start(false, 0.02);
		add(particleEmitter);
		
		// Center glow
		glowSprite = new FlxSprite(FlxG.width / 2 - 400, FlxG.height / 2 - 400);
		glowSprite.makeGraphic(800, 800, FlxColor.PURPLE);
		glowSprite.blend = ADD;
		glowSprite.alpha = 0.2;
		add(glowSprite);
		
		// Title
		titleText = new FlxText(0, 150, FlxG.width, "QUANTUM SECRET UNLOCKED");
		titleText.setFormat(Paths.font("vcr.ttf"), 52, FlxColor.PURPLE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 3;
		titleText.alpha = 0;
		add(titleText);
		
		FlxTween.tween(titleText, {alpha: 1}, 1, {ease: FlxEase.expoOut});
		
		// Secret message
		var randomMsg:String = secretMessages[Std.int(Math.random() * secretMessages.length)];
		secretText = new FlxText(0, FlxG.height / 2 - 50, FlxG.width, randomMsg);
		secretText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.PURPLE);
		secretText.borderSize = 2;
		secretText.alpha = 0;
		add(secretText);
		
		FlxTween.tween(secretText, {alpha: 1}, 1, {ease: FlxEase.expoOut, startDelay: 0.5});
		
		// Instructions
		instructionText = new FlxText(0, FlxG.height - 150, FlxG.width, 
			"Kombinasyon: Asagi, Asagi, Yukari, Yukari, Sol, Sag\n\nESC - Geri Don");
		instructionText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		instructionText.alpha = 0;
		add(instructionText);
		
		FlxTween.tween(instructionText, {alpha: 0.7}, 1, {ease: FlxEase.expoOut, startDelay: 1});
		
		// Camera effects
		FlxG.camera.flash(FlxColor.PURPLE, 1);
		FlxG.camera.shake(0.005, 1);
		
		// Play secret sound
		FlxG.sound.play(Paths.sound('secret'));
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		animTimer += elapsed;
		
		// Pulse effects
		titleText.scale.set(1 + Math.sin(animTimer * 3) * 0.05, 1 + Math.sin(animTimer * 3) * 0.05);
		glowSprite.alpha = 0.2 + Math.sin(animTimer * 2) * 0.1;
		glowSprite.angle += elapsed * 20;
		
		// Rainbow color shift
		var hue:Float = (animTimer * 50) % 360;
		secretText.color = FlxColor.fromHSB(hue, 0.8, 1);
		
		// Back to menu
		if (controls.BACK || controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function()
			{
				MusicBeatState.switchState(new MainMenuState());
			});
		}
	}
}