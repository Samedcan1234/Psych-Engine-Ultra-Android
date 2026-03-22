package objects;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * Usage:
 *   var t = new EmojiText(100, 200, 400, "Test 🔥", 24);
 *   add(t);
 *   t.setText("Hello 💯");
 * 
 *   t.textColor  = FlxColor.WHITE;
 *   t.fontName   = "VCR OSD Mono";
 *   t.fontSize   = 32;
 *   t.rebuild();
 */
class EmojiText extends FlxSpriteGroup
{
    // --- Ortak ayarlar ---
    public var text(default, set):String = "";
    public var textColor:FlxColor       = FlxColor.WHITE;
    public var fontName:String          = "VCR OSD Mono";
    public var fontSize:Int             = 24;
    public var fieldWidth:Float         = 0;
    public var alignment:FlxTextAlign   = LEFT;
    public var bold:Bool                = false;
    public var emojiScale:Float         = 1.0;

    // Emoji boyutu (atlas'tan gelir, scale uygulanır)
    var _emojiSize:Int = 32;

    // İç parçalar
    var _parts:Array<Dynamic> = []; // {type:"text"|"emoji", value:String}

    // Otomatik yeniden oluştur
    var _dirty:Bool = false;

    public function new(x:Float = 0, y:Float = 0, fieldWidth:Float = 0, text:String = "", size:Int = 24)
    {
        super(x, y);
        this.fieldWidth = fieldWidth;
        this.fontSize   = size;

        // Atlas yüklü değilse yükle
        if (!EmojiAtlas.instance.isLoaded())
            EmojiAtlas.instance.load("emoji_atlas", 32);

        _emojiSize = EmojiAtlas.instance.emojiSize;

        if (text != "")
            setText(text);
    }

    function set_text(v:String):String
    {
        text   = v;
        _dirty = true;
        return v;
    }

    public function setText(v:String):Void
    {
        text   = v;
        _dirty = true;
        rebuild();
    }

    /**
     * Tüm sprite'ları temizle ve metni yeniden oluştur.
     */
    public function rebuild():Void
    {
        _dirty = false;
        clear();
        _parts = [];

        if (text == null || text.length == 0) return;

        _parts = _parseText(text);
        _renderParts();
    }

    /**
     * Metni metin/emoji parçalarına ayır.
     */
    function _parseText(input:String):Array<Dynamic>
    {
        var result:Array<Dynamic> = [];
        var buffer = new StringBuf();
        var i = 0;

        while (i < input.length)
        {
            var code = input.charCodeAt(i);
            var charLen = 1;

            // Surrogate pair → 4-byte emoji
            if (code >= 0xD800 && code <= 0xDBFF && i + 1 < input.length)
                charLen = 2;

            // Variation selector ve ZWJ dahil tüm emoji sequence'ini al
            var seqStart = i;
            var seqLen   = charLen;
            if (_isEmojiStart(code, input, i))
            {
                // ZWJ sequence toplama: sonraki karakteri ZWJ ise devam et
                var j = i + charLen;
                while (j < input.length)
                {
                    var nc = input.charCodeAt(j);
                    // FE0F (variation selector), 200D (ZWJ), veya modifier
                    if (nc == 0xFE0F || nc == 0x200D || (nc >= 0x1F3FB && nc <= 0x1F3FF))
                    {
                        seqLen += (nc >= 0xD800 && nc <= 0xDBFF) ? 2 : 1;
                        j = seqStart + seqLen;
                    }
                    else if (nc >= 0xD800 && nc <= 0xDBFF) // başka emoji
                    {
                        // ZWJ sonrasıysa ekle
                        if (input.charCodeAt(j - 1) == 0x200D)
                        {
                            seqLen += 2;
                            j = seqStart + seqLen;
                        }
                        else break;
                    }
                    else break;
                }

                var emojiStr = input.substr(seqStart, seqLen);
                var codePoint = EmojiAtlas.instance.resolveEmoji(emojiStr);

                if (codePoint != null)
                {
                    // Önceki metin buffer'ını kaydet
                    if (buffer.length > 0)
                    {
                        result.push({type: "text", value: buffer.toString()});
                        buffer = new StringBuf();
                    }
                    result.push({type: "emoji", value: codePoint});
                    i = seqStart + seqLen;
                    continue;
                }
            }

            // Normal karakter
            buffer.addChar(code);
            if (charLen == 2) buffer.addChar(input.charCodeAt(i + 1));
            i += charLen;
        }

        if (buffer.length > 0)
            result.push({type: "text", value: buffer.toString()});

        return result;
    }

    /**
     * Parçaları sprite olarak yerleştir.
     * Satır sonu ve fieldWidth'e göre wrap uygular.
     */
    function _renderParts():Void
    {
        var cursorX:Float = 0;
        var cursorY:Float = 0;
        var lineH:Float   = fontSize + 4;
        var scaledEmoji   = _emojiSize * emojiScale;

        // Satırı vertically ortala (metin ve emoji aynı hizada)
        var baselineOffset = (scaledEmoji - fontSize) * 0.5;
        if (baselineOffset < 0) baselineOffset = 0;

        for (part in _parts)
        {
            if (part.type == "text")
            {
                // Boşluklara göre kelime kelime yerleştir
                var words = (part.value : String).split(" ");
                for (wi in 0...words.length)
                {
                    var word = words[wi] + (wi < words.length - 1 ? " " : "");

                    // Geçici FlxText ile genişlik ölç
                    var probe = new FlxText(0, 0, 0, word, fontSize);
                    probe.font  = fontName;
                    probe.bold  = bold;
                    var wordW = probe.textField.textWidth + 2;
                    probe.destroy();

                    // Wrap
                    if (fieldWidth > 0 && cursorX + wordW > fieldWidth && cursorX > 0)
                    {
                        cursorX  = 0;
                        cursorY += lineH;
                    }

                    // Metin sprite
                    var t = new FlxText(cursorX, cursorY + baselineOffset, 0, word, fontSize);
                    t.font      = fontName;
                    t.color     = textColor;
                    t.bold      = bold;
                    t.alignment = alignment;
                    t.antialiasing = true;
                    add(t);

                    cursorX += wordW;
                }
            }
            else if (part.type == "emoji")
            {
                var bmp = EmojiAtlas.instance.getEmojiByCodePoint(part.value);
                if (bmp == null)
                {
                    // Atlas'ta yok → placeholder kutu çiz
                    bmp = _makePlaceholder();
                }

                // Wrap
                if (fieldWidth > 0 && cursorX + scaledEmoji > fieldWidth && cursorX > 0)
                {
                    cursorX  = 0;
                    cursorY += lineH;
                }

                var spr = new FlxSprite(cursorX, cursorY);
                spr.loadGraphic(bmp);
                spr.setGraphicSize(Std.int(scaledEmoji), Std.int(scaledEmoji));
                spr.updateHitbox();
                spr.antialiasing = true;
                add(spr);

                cursorX += scaledEmoji + 2;
            }
        }
    }

    /**
     * Atlas'ta olmayan emoji için gri placeholder kare.
     */
    function _makePlaceholder():BitmapData
    {
        var size = Std.int(_emojiSize * emojiScale);
        var bmp  = new BitmapData(size, size, true, 0x00000000);
        // Gri çerçeve
        for (px in 0...size)
        for (py in 0...size)
        {
            if (px == 0 || py == 0 || px == size - 1 || py == size - 1)
                bmp.setPixel32(px, py, 0xFF888888);
            else
                bmp.setPixel32(px, py, 0x33888888);
        }
        return bmp;
    }

    /**
     * Unicode code point'in emoji olup olmadığını hızlı kontrol et.
     * Surrogate pair girişini de destekler.
     */
    function _isEmojiStart(code:Int, str:String, idx:Int):Bool
    {
        // Surrogate pair → 4-byte Unicode
        if (code >= 0xD800 && code <= 0xDBFF && idx + 1 < str.length)
        {
            var lo   = str.charCodeAt(idx + 1);
            var full = ((code - 0xD800) << 10) + (lo - 0xDC00) + 0x10000;
            // Emoji aralıkları: Miscellaneous Symbols, Emoticons, Transport, etc.
            return (full >= 0x1F300 && full <= 0x1FAFF);
        }
        // BMP emoji aralıkları
        return (code >= 0x2600 && code <= 0x27FF)  // Misc Symbols
            || (code >= 0x2300 && code <= 0x23FF)  // Technical
            || (code == 0x00A9 || code == 0x00AE)  // © ®
            || (code >= 0x203C && code <= 0x2049)  // ‼ ⁉
            || (code >= 0x2122 && code <= 0x2139)  // ™ ℹ
            || (code >= 0x231A && code <= 0x231B)  // ⌚ ⌛
            || (code >= 0x25AA && code <= 0x25FE)  // Geometric
            || (code >= 0x2614 && code <= 0x2615)  // ☔ ☕
            || (code >= 0x2648 && code <= 0x2653)  // Zodiac
            || (code >= 0x267F && code <= 0x267F)  // ♿
            || (code >= 0x2702 && code <= 0x27B0); // Dingbats
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (_dirty) rebuild();
    }

    override function destroy():Void
    {
        _parts = null;
        super.destroy();
    }
}
