package;

import openfl.events.KeyboardEvent;
import flixel.input.gamepad.FlxGamepad;
import openfl.Lib;
#if FEATURE_LUAMODCHART
import llua.Lua;
#end
import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
#if mobileC
import ui.FlxVirtualPad;
import flixel.FlxCamera;
#end

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	public static var FUCKINGDONTDOITVLCMEDIAPLAYERISWEARTOGOD:Bool = false;

	public static var goToOptions:Bool = false;
	public static var goBack:Bool = false;

	var menuItems:Array<String> = ['Resume', 'Restart Song', 'Options', 'Exit to menu'];
	var curSelected:Int = 0;

	public static var playingPause:Bool = false;

	var pauseMusic:FlxSound;

	var perSongOffset:FlxText;

	var offsetChanged:Bool = false;
	var startOffset:Float = PlayState.songOffset;

	var bg:FlxSprite;

	#if mobileC
	var virtualpad:FlxVirtualPad;
	#end

	public function new()
	{
		super();
		if (FlxG.sound.music.playing)
			FlxG.sound.music.pause();

		for (i in FlxG.sound.list)
		{
			if (i.playing && i.ID != 9000)
				i.pause();
		}

		if (!playingPause)
		{
			playingPause = true;
			pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast', "shared"), true, true);
			pauseMusic.volume = 0;
			pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
			pauseMusic.ID = 9000;

			FlxG.sound.list.add(pauseMusic);
		}
		else
		{
			for (i in FlxG.sound.list)
			{
				if (i.ID == 9000) // jankiest static variable
					pauseMusic = i;
			}
		}

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.songName;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.difficultyFromInt(PlayState.storyDifficulty).toUpperCase();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);
		perSongOffset = new FlxText(5, FlxG.height - 18, 0, "Hello chat", 12);
		perSongOffset.scrollFactor.set();
		perSongOffset.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		#if FEATURE_FILESYSTEM
		add(perSongOffset);
		#end

		for (i in 0...menuItems.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		changeSelection();

		bg.alpha = 0.6;
		FlxTween.globalManager.active = false;

		cameras = [PlayState.instance.camHUD];

		#if mobileC
		virtualpad = new FlxVirtualPad(UP_DOWN, A);
		virtualpad.alpha = 0.75;
		add(virtualpad);
		var camcontrol = new FlxCamera();
		FlxG.cameras.add(camcontrol);
		camcontrol.bgColor.alpha = 0;
		virtualpad.cameras = [camcontrol];
		#end
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		if (FlxG.sound.music.playing)
			FlxG.sound.music.pause();

		for (i in FlxG.sound.list)
		{
			if (i.playing && i.ID != 9000)
				i.pause();
		}

		if (bg.alpha > 0.6)
			bg.alpha = 0.6;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		var upPcontroller:Bool = false;
		var downPcontroller:Bool = false;
		var leftPcontroller:Bool = false;
		var rightPcontroller:Bool = false;
		var oldOffset:Float = 0;

		if (gamepad != null && KeyBinds.gamepad)
		{
			upPcontroller = gamepad.justPressed.DPAD_UP;
			downPcontroller = gamepad.justPressed.DPAD_DOWN;
			leftPcontroller = gamepad.justPressed.DPAD_LEFT;
			rightPcontroller = gamepad.justPressed.DPAD_RIGHT;
		}

		var songPath = 'assets/data/songs/${PlayState.SONG.songId}/';

		#if FEATURE_STEPMANIA
		if (PlayState.isSM && !PlayState.isStoryMode)
			songPath = PlayState.pathToSm;
		#end

		if (controls.UP_P || upPcontroller #if android || virtualpad.buttonUp.justPressed #end)
		{
			changeSelection(-1);
		}
		else if (controls.DOWN_P || downPcontroller #if android || virtualpad.buttonDown.justPressed #end)
		{
			changeSelection(1);
		}

		if ((controls.ACCEPT #if android || virtualpad.buttonA.justPressed #end) && !FlxG.keys.pressed.ALT)
		{
			var daSelected:String = menuItems[curSelected];

			switch (daSelected)
			{
				case "Resume":
					FlxTween.globalManager.active = true;
					close();
				case "Restart Song":
					FlxTween.globalManager.active = true;
					PlayState.startTime = 0;
					PlayState.stageTesting = false;
					switchState(new PlayState());
				case "Options":
					goToOptions = true;
					close();
				case "Exit to menu":
					FUCKINGDONTDOITVLCMEDIAPLAYERISWEARTOGOD = true;
					FlxTween.globalManager.active = true;
					PlayState.startTime = 0;
					if (PlayState.loadRep)
					{
						FlxG.save.data.botplay = false;
						FlxG.save.data.scrollSpeed = 1;
						FlxG.save.data.downscroll = false;
					}
					PlayState.loadRep = false;
					PlayState.stageTesting = false;
					#if FEATURE_LUAMODCHART
					if (PlayState.luaModchart != null)
					{
						PlayState.luaModchart.die();
						PlayState.luaModchart = null;
					}
					#end
					if (FlxG.save.data.fpsCap > 340)
						(cast(Lib.current.getChildAt(0), Main)).setFPSCap(120);

					PlayState.instance.clean();

					FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, PlayState.instance.handleInput);
					FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, PlayState.instance.releaseInput);
					if (PlayState.instance.coolingVideo != null)
					{
						Debug.logTrace("removing cooling video");
						PlayState.instance.remove(PlayState.instance.coolingVideo);
						PlayState.instance.coolingVideo.destroy();
						// PlayState.instance.coolingVideo.bitmap.kill();
						PlayState.instance.coolingVideo.bitmap.stop();
						PlayState.instance.coolingVideo.bitmap.visible = false;
						PlayState.instance.coolingVideo.bitmap.dispose();
					}
					if (PlayState.isStoryMode)
					{
						GameplayCustomizeState.freeplayBf = 'bf';
						GameplayCustomizeState.freeplayDad = 'dad';
						GameplayCustomizeState.freeplayGf = 'gf';
						GameplayCustomizeState.freeplayNoteStyle = 'normal';
						GameplayCustomizeState.freeplayStage = 'stage';
						GameplayCustomizeState.freeplaySong = 'bopeebo';
						GameplayCustomizeState.freeplayWeek = 1;
						PlayState.instance.switchState(new HexStoryMenu(HexMenuState.loadHexMenu("story-menu")));
					}
					else
						PlayState.instance.switchState(new HexMainMenu(HexMenuState.loadHexMenu("main-menu")));
			}
		}

		if (FlxG.keys.justPressed.J)
		{
			// for reference later!
			// PlayerSettings.player1.controls.replaceBinding(Control.LEFT, Keys, FlxKey.J, null);
		}
	}

	override function destroy()
	{
		if (!goToOptions)
		{
			Debug.logTrace("destroying music for pauseeta");
			pauseMusic.destroy();
			playingPause = false;
		}

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}
