package objects;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxRect;
import openfl.display.BitmapData;
import haxe.Json;

class EmojiAtlas
{
    // Singleton
    public static var instance(get, null):EmojiAtlas;
    static var _instance:EmojiAtlas;
    static function get_instance():EmojiAtlas
    {
        if (_instance == null)
            _instance = new EmojiAtlas();
        return _instance;
    }

    public var atlasBitmap:BitmapData;

    var unicodeToName:Map<String, String> = [];

    var frames:Map<String, FlxRect> = [];

    public var emojiSize:Int = 32;

    var loaded:Bool = false;

    public function new() {}

    public function load(atlasPath:String = "emoji_atlas", size:Int = 32):Void
    {
        if (loaded) return;

        emojiSize = size;

        // PNG yükle
        var bmpPath = Paths.image(atlasPath);
        var graphic  = FlxG.bitmap.add(bmpPath);
        if (graphic == null)
        {
            trace('[EmojiAtlas] HATA: Atlas bulunamadı → $bmpPath');
            return;
        }
        atlasBitmap = graphic.bitmap;

        // JSON yükle
		var jsonPath = Paths.getPath('images/$atlasPath.json', TEXT);
		var rawJson  = openfl.Assets.getText(jsonPath);
        if (rawJson == null)
        {
            trace('[EmojiAtlas] HATA: JSON bulunamadı → $jsonPath');
            return;
        }

        var data:Dynamic = Json.parse(rawJson);

        // Frame koordinatlarını oku
        for (name in Reflect.fields(data.frames))
        {
            var f:Dynamic = Reflect.field(data.frames, name);
            frames.set(name, new FlxRect(f.x, f.y, f.w, f.h));
        }

        // Unicode haritasını oku
        for (codePoint in Reflect.fields(data.unicode_map))
        {
            var frameName:String = Reflect.field(data.unicode_map, codePoint);
            unicodeToName.set(codePoint.toUpperCase(), frameName);
        }

        loaded = true;
        var emojiCount = 0; for (_ in frames.keys()) emojiCount++;
		trace('[EmojiAtlas] Yüklendi: $emojiCount emoji, ${emojiSize}px');
    }

    /**
     * Unicode code point'ten (örn: "1F600") BitmapData döndür.
     * Her çağrıda yeni BitmapData oluşturur — önbelleğe almak istersen sarabilirsin.
     */
    public function getEmojiByCodePoint(codePoint:String):BitmapData
    {
        var name = unicodeToName.get(codePoint.toUpperCase());
        if (name == null) return null;
        return getEmojiByName(name);
    }

    /**
     * Frame adından BitmapData döndür.
     */
    public function getEmojiByName(name:String):BitmapData
    {
        if (!loaded || atlasBitmap == null) return null;

        var rect = frames.get(name);
        if (rect == null) return null;

        var bmp = new BitmapData(Std.int(rect.width), Std.int(rect.height), true, 0x00000000);
        bmp.copyPixels(
            atlasBitmap,
            new openfl.geom.Rectangle(rect.x, rect.y, rect.width, rect.height),
            new openfl.geom.Point(0, 0)
        );
        return bmp;
    }

    /**
     * Verilen emoji string'i (tek karakter veya ZWJ sequence) için
     * en uygun code point'i döndürür.
     * Önce tam Unicode sequence'i dener, bulamazsa base emoji'ye düşer.
     */
    public function resolveEmoji(emojiChar:String):String
    {
        // Tüm kod noktalarını HEX string olarak birleştir (ZWJ desteği)
        var codes = [];
        var i = 0;
        while (i < emojiChar.length)
        {
            var code = emojiChar.charCodeAt(i);
            // Surrogate pair kontrolü (4-byte emoji)
            if (code >= 0xD800 && code <= 0xDBFF && i + 1 < emojiChar.length)
            {
                var lo = emojiChar.charCodeAt(i + 1);
                var full = ((code - 0xD800) << 10) + (lo - 0xDC00) + 0x10000;
                codes.push(StringTools.hex(full).toUpperCase());
                i += 2;
            }
            else
            {
                // Variation selector ve ZWJ'yi atla (200D, FE0F)
                if (code != 0x200D && code != 0xFE0F)
                    codes.push(StringTools.hex(code).toUpperCase());
                i++;
            }
        }

        // Önce tam sequence'i dene (ZWJ emoji için)
        var fullKey = codes.join("-");
        if (unicodeToName.exists(fullKey)) return fullKey;

        // Sadece ilk kod noktasını dene
        if (codes.length > 0 && unicodeToName.exists(codes[0])) return codes[0];

        return null;
    }

    public function hasEmoji(codePoint:String):Bool
    {
        return unicodeToName.exists(codePoint.toUpperCase());
    }

    public function isLoaded():Bool return loaded;
}
