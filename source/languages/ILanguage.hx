package languages;

/**
 * phrases     → çeviri stringleri (key: format_edilmiş, value: çeviri)
 * imageOverrides → image path değişimleri (key: orijinal path, value: dil-özel path)
 * langName    → görünen dil adı (ör: "Türkçe")
 * alphabetPath → image (default: null)
 */
 
 // SYSTEM BY SAMETGKTE
 
interface ILanguage
{
    public var langName:String;
    public var alphabetPath:Null<String>;
    public var phrases:Map<String, String>;
    public var imageOverrides:Map<String, String>;
}
