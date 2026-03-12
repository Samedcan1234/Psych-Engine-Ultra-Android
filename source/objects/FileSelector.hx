package objects;

class FileSelector extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var copyAlpha:Bool = true;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var selectedPath:String = '';
	public var optionID:Int = 0;

	public function new(x:Float = 0, y:Float = 0, ?selectedPath:String = '')
	{
		super(x, y);

		this.selectedPath = selectedPath;
		loadGraphic(Paths.image('ultra/file'));
		
		antialiasing = ClientPrefs.data.antialiasing;
		setGraphicSize(Std.int(0.75 * width));
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		if (sprTracker != null)
		{
			setPosition(sprTracker.x - 105 + offsetX, sprTracker.y + 30 + offsetY);
			if(copyAlpha)
			{
				alpha = sprTracker.alpha;
			}
		}
		super.update(elapsed);
	}
}
