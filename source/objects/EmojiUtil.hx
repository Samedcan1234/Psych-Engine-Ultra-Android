package objects;

class EmojiUtil
{
    /**
     * Standart emoji seti için hazır JSON içeriği döndürür.
     * Bu string'i assets/images/emoji_atlas.json olarak kaydet.
     * 
     * Atlas sprite sheet düzeni:
     *   - Her emoji 32x32 piksel
     *   - Satır başına 16 emoji (toplam genişlik: 512px)
     *   - Tüm emojiler soldan sağa, yukarıdan aşağıya
     */
    public static function generateAtlasJson(emojis:Array<EmojiDef>, cols:Int = 16, size:Int = 32):String
    {
        var frames  = new StringBuf();
        var unicode = new StringBuf();
        var first   = true;

        for (i in 0...emojis.length)
        {
            var e   = emojis[i];
            var col = i % cols;
            var row = Std.int(i / cols);
            var x   = col * size;
            var y   = row * size;

            if (!first) { frames.add(",\n"); unicode.add(",\n"); }
            first = false;

            frames.add('    "${e.name}": {"x":$x,"y":$y,"w":$size,"h":$size}');
            unicode.add('    "${e.codePoint}": "${e.name}"');
        }

        return '{\n  "frames": {\n${frames.toString()}\n  },\n  "unicode_map": {\n${unicode.toString()}\n  }\n}';
    }

    /**
     * Psych Engine'de yaygın kullanılan emoji seti için hazır tanımlar.
     * Bu listeyi sprite sheet sıralarıyla eşleştir.
     */
    public static function defaultEmojiSet():Array<EmojiDef>
    {
        return [
            // Yüzler
            { name: "grinning",        codePoint: "1F600" },
            { name: "grin",            codePoint: "1F601" },
            { name: "joy",             codePoint: "1F602" },
            { name: "smiley",          codePoint: "1F603" },
            { name: "smile",           codePoint: "1F604" },
            { name: "sweat_smile",     codePoint: "1F605" },
            { name: "laughing",        codePoint: "1F606" },
            { name: "wink",            codePoint: "1F609" },
            { name: "blush",           codePoint: "1F60A" },
            { name: "yum",             codePoint: "1F60B" },
            { name: "sunglasses",      codePoint: "1F60E" },
            { name: "heart_eyes",      codePoint: "1F60D" },
            { name: "kissing",         codePoint: "1F617" },
            { name: "thinking",        codePoint: "1F914" },
            { name: "exploding_head",  codePoint: "1F92F" },
            { name: "flushed",         codePoint: "1F633" },
            { name: "sob",             codePoint: "1F62D" },
            { name: "angry",           codePoint: "1F620" },
            { name: "skull",           codePoint: "1F480" },
            { name: "ghost",           codePoint: "1F47B" },
            { name: "alien",           codePoint: "1F47D" },
            { name: "robot",           codePoint: "1F916" },
            { name: "poop",            codePoint: "1F4A9" },
            { name: "clown",           codePoint: "1F921" },

            // Eller & İnsanlar
            { name: "thumbsup",        codePoint: "1F44D" },
            { name: "thumbsdown",      codePoint: "1F44E" },
            { name: "clap",            codePoint: "1F44F" },
            { name: "wave",            codePoint: "1F44B" },
            { name: "ok_hand",         codePoint: "1F44C" },
            { name: "v",               codePoint: "270C"  },
            { name: "raised_hands",    codePoint: "1F64C" },
            { name: "pray",            codePoint: "1F64F" },

            // Müzik / Oyun
            { name: "musical_note",    codePoint: "1F3B5" },
            { name: "notes",           codePoint: "1F3B6" },
            { name: "microphone",      codePoint: "1F3A4" },
            { name: "headphones",      codePoint: "1F3A7" },
            { name: "guitar",          codePoint: "1F3B8" },
            { name: "drum",            codePoint: "1F941" },
            { name: "joystick",        codePoint: "1F579" },
            { name: "video_game",      codePoint: "1F3AE" },
            { name: "trophy",          codePoint: "1F3C6" },
            { name: "star",            codePoint: "2B50"  },
            { name: "sparkles",        codePoint: "2728"  },
            { name: "fire",            codePoint: "1F525" },
            { name: "boom",            codePoint: "1F4A5" },
            { name: "100",             codePoint: "1F4AF" },

            // Kalpler
            { name: "heart",           codePoint: "2764"  },
            { name: "orange_heart",    codePoint: "1F9E1" },
            { name: "yellow_heart",    codePoint: "1F49B" },
            { name: "green_heart",     codePoint: "1F49A" },
            { name: "blue_heart",      codePoint: "1F499" },
            { name: "purple_heart",    codePoint: "1F49C" },
            { name: "broken_heart",    codePoint: "1F494" },
            { name: "sparkling_heart", codePoint: "1F496" },

            // Semboller
            { name: "check",           codePoint: "2705"  },
            { name: "x",               codePoint: "274C"  },
            { name: "warning",         codePoint: "26A0"  },
            { name: "no_entry",        codePoint: "26D4"  },
            { name: "arrow_right",     codePoint: "27A1"  },
            { name: "arrow_left",      codePoint: "2B05"  },
            { name: "question",        codePoint: "2753"  },
            { name: "exclamation",     codePoint: "2757"  },
        ];
    }

    /**
     * Hızlı test: EmojiText'in bir metni doğru parse edip etmediğini
     * trace ile gösterir.
     */
    public static function debugParse(text:String):Void
    {
        trace('[EmojiUtil] Test metni: "$text"');
        var atlas = EmojiAtlas.instance;
        if (!atlas.isLoaded())
        {
            trace('[EmojiUtil] Atlas yüklü değil!');
            return;
        }

        var i = 0;
        var segment = 0;
        while (i < text.length)
        {
            var code = text.charCodeAt(i);
            if (code >= 0xD800 && code <= 0xDBFF && i + 1 < text.length)
            {
                var lo   = text.charCodeAt(i + 1);
                var full = ((code - 0xD800) << 10) + (lo - 0xDC00) + 0x10000;
                var hex  = StringTools.hex(full).toUpperCase();
                var has  = atlas.hasEmoji(hex);
                trace('  [$segment] EMOJI (4-byte) U+$hex → ${has ? "✔ bulundu" : "✘ atlas'ta yok"}');
                i += 2;
            }
            else
            {
                var hex = StringTools.hex(code).toUpperCase();
                var has = atlas.hasEmoji(hex);
                if (has)
                    trace('  [$segment] EMOJI U+$hex → ✔');
                else
                    trace('  [$segment] METIN char: "${text.charAt(i)}"');
                i++;
            }
            segment++;
        }
    }
}

typedef EmojiDef = { name:String, codePoint:String };
