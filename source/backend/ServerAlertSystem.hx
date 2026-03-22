package backend;

import haxe.Json;
import haxe.Http;
import objects.AlertMgr;
import flixel.FlxG;

class ServerAlertSystem
{
    static final ALERTS_URL:String = "https://sametgkte.github.io/alerts.json";
    static final CHECK_INTERVAL_MINUTES:Float = 5;

    static var _initialized:Bool  = false;
    static var _checkTimer:Float  = 0;
    static var _checking:Bool     = false;

    static var _seenIds:Array<String> = [];

    public static function init():Void
    {
		trace('[ServerAlert] init() çağrıldı, _initialized=$_initialized'); // ← ekle
		if (_initialized) return;
		_initialized = true;

        // Daha önce görülen ID'leri yükle
        if (FlxG.save.data.seenAlertIds != null)
            _seenIds = FlxG.save.data.seenAlertIds;
        check();
    }

    public static function update(elapsed:Float):Void
    {
        if (!_initialized || CHECK_INTERVAL_MINUTES <= 0) return;

        _checkTimer += elapsed;
        if (_checkTimer >= CHECK_INTERVAL_MINUTES * 60)
        {
            _checkTimer = 0;
            check();
        }
    }
	
	public static function check():Void
	{
		if (_checking) return;
		_checking = true;
		
		trace('[ServerAlert] İstek başlatılıyor: $ALERTS_URL');
		
		var http = new haxe.Http(ALERTS_URL);

		http.onData = function(data:String)
		{
			_checking = false;
			trace('[ServerAlert] VERİ GELDİ: ' + data.substr(0, 100));
			// ... geri kalan kod
		};

		http.onError = function(msg:String)
		{
			_checking = false;
			trace('[ServerAlert] HATA: ' + msg);
		};

		http.onStatus = function(status:Int)
		{
			trace('[ServerAlert] HTTP STATUS: ' + status);
		};

		try {
			http.request(false); // senkron dene
			trace('[ServerAlert] İstek tamamlandı');
		} catch(e:Dynamic) {
			trace('[ServerAlert] EXCEPTION: ' + e);
			_checking = false;
		}
	}
	
    static function _markSeen(id:String):Void
    {
        if (_seenIds.contains(id)) return;
        _seenIds.push(id);
        FlxG.save.data.seenAlertIds = _seenIds;
        FlxG.save.flush();
    }
	
    public static function resetAlert(id:String):Void
    {
        _seenIds.remove(id);
        FlxG.save.data.seenAlertIds = _seenIds;
        FlxG.save.flush();
    }

    public static function resetAll():Void
    {
        _seenIds = [];
        FlxG.save.data.seenAlertIds = _seenIds;
        FlxG.save.flush();
        trace('[ServerAlert] Tüm alertler sıfırlandı.');
    }
	
    static function _parseColor(colorStr:String):Int
    {
        return switch (colorStr.toLowerCase())
        {
            case "info":    AlertMsg.COLOR_INFO;
            case "success": AlertMsg.COLOR_SUCCESS;
            case "warning": AlertMsg.COLOR_WARNING;
            case "error":   AlertMsg.COLOR_ERROR;
            default:
                try Std.parseInt(colorStr)
                catch (_) AlertMsg.COLOR_INFO;
        };
    }
}
