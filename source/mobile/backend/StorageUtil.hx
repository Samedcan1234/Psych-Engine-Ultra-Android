package mobile.backend;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if android
import lime.system.JNI;
#end

class StorageUtil
{
    #if sys
    private static var errorLog:Array<String> = [];
    private static var debugMode:Bool = false;
    private static var _cachedModsDir:String = null;

    public static var onModPathSelected:Null<String->Void> = null;

    public static function getStorageDirectory():String
    {
        var path:String = #if android haxe.io.Path.addTrailingSlash(AndroidContext.getExternalFilesDir())
                          #elseif ios lime.system.System.documentsDirectory
                          #else Sys.getCwd() #end;
        return path;
    }

    #if android
    public static function getExternalStorageDirectory():String
        return '/sdcard/.PsychEngineUltra/';
    #end

    public static function getModsDirectory():String
    {
        if (_cachedModsDir != null) return _cachedModsDir;

        #if sys
        var custom:String = ClientPrefs.data.modsPath;
        if (custom != null && custom.trim().length > 0 && FileSystem.exists(custom))
        {
            _cachedModsDir = haxe.io.Path.addTrailingSlash(custom);
            return _cachedModsDir;
        }
        #end

        #if android
        _cachedModsDir = getExternalStorageDirectory() + 'mods/';
        #elseif ios
        _cachedModsDir = haxe.io.Path.addTrailingSlash(lime.system.System.documentsDirectory) + 'mods/';
        #else
        _cachedModsDir = Sys.getCwd() + 'mods/';
        #end

        return _cachedModsDir;
    }

    public static function openFolderPicker():Void
    {
        #if android
        _openAndroidFolderPicker();
        #elseif ios
        _openIOSFolderPicker();
        #elseif windows
        _openWindowsFolderPicker();
        #elseif mac
        _openMacFolderPicker();
        #elseif linux
        _openLinuxFolderPicker();
        #end
    }
	public static function openFilePicker(extension:String = '', onSelected:String->Void):Void
	{
		#if windows
		_openWindowsFilePicker(extension, onSelected);
		#elseif mac
		_openMacFilePicker(extension, onSelected);
		#elseif linux
		_openLinuxFilePicker(extension, onSelected);
		#else
		trace('[StorageUtil] Bu platform için dosya seçici desteklenmiyor.');
		#end
	}

	#if windows
	private static function _openWindowsFilePicker(extension:String, onSelected:String->Void):Void
	{
		#if sys
		sys.thread.Thread.create(function()
		{
			try
			{
				var psPath:String = null;
				var candidates:Array<String> = [
					'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
					'C:\\Windows\\SysWOW64\\WindowsPowerShell\\v1.0\\powershell.exe',
					'C:\\Program Files\\PowerShell\\7\\pwsh.exe',
					'C:\\Program Files (x86)\\PowerShell\\7\\pwsh.exe'
				];
				for (c in candidates)
					if (sys.FileSystem.exists(c)) { psPath = c; break; }

				if (psPath == null)
				{
					lime.app.Application.current.window.alert('PowerShell bulunamadı!', 'HATA');
					return;
				}

				var filterStr:String = extension != ''
					? 'Dosya (*' + extension + ')|*' + extension + '|Tum Dosyalar (*.*)|*.*'
					: 'Tum Dosyalar (*.*)|*.*';

				var script:String =
					'Add-Type -AssemblyName System.Windows.Forms;' +
					'$$f = New-Object System.Windows.Forms.OpenFileDialog;' +
					'$$f.Title = "Dosya Sec";' +
					'$$f.Filter = "' + filterStr + '";' +
					'$$form = New-Object System.Windows.Forms.Form;' +
					'$$form.TopMost = $$true;' +
					'if ($$f.ShowDialog($$form) -eq [System.Windows.Forms.DialogResult]::OK) { Write-Output $$f.FileName } else { Write-Output "" }';

				var process = new sys.io.Process(psPath, ['-NoProfile', '-NonInteractive', '-Command', script]);
				var result:String = process.stdout.readAll().toString().trim();
				process.close();

				if (result != null && result.length > 0)
				{
					// Ana thread'e geri dön
					lime.app.Application.current.onUpdate.add(function(_)
					{
						lime.app.Application.current.onUpdate.remove(null);
						onSelected(result);
					});
				}
			}
			catch (e:Dynamic) {}
		});
		#end
	}
	#end
	
	#if mac
	private static function _openMacFilePicker(extension:String, onSelected:String->Void):Void
	{
		#if sys
		sys.thread.Thread.create(function()
		{
			try
			{
				var filterStr:String = extension != ''
					? 'of type {"' + extension.replace('.', '') + '"}'
					: '';

				var script:String = 'choose file ' + filterStr + ' with prompt "Dosya Seç:"';

				var process = new sys.io.Process('osascript', ['-e', script]);
				var result:String = process.stdout.readAll().toString().trim();
				process.close();

				if (result == null || result.length == 0) return;

				// alias -> POSIX path dönüşümü
				var posixProcess = new sys.io.Process('osascript', [
					'-e', 'POSIX path of ("' + result + '" as alias)'
				]);
				var posixPath:String = posixProcess.stdout.readAll().toString().trim();
				posixProcess.close();

				if (posixPath != null && posixPath.length > 0)
				{
					lime.app.Application.current.onUpdate.add(function(_)
					{
						lime.app.Application.current.onUpdate.remove(null);
						onSelected(posixPath);
					});
				}
			}
			catch (e:Dynamic) {}
		});
		#end
	}
	#end
	
	#if linux
	private static function _openLinuxFilePicker(extension:String, onSelected:String->Void):Void
	{
		#if sys
		sys.thread.Thread.create(function()
		{
			try
			{
				var cmd:String = _linuxPickerCommand();
				if (cmd == null)
				{
					trace('[StorageUtil] Dosya seçici için zenity veya kdialog yüklü olmalı!');
					return;
				}

				var args:Array<String>;
				if (cmd == 'zenity')
				{
					args = ['--file-selection', '--title=Dosya Seç'];
					if (extension != '')
						args.push('--file-filter=Dosya (*' + extension + ')|*' + extension);
				}
				else
				{
					// kdialog
					args = ['--getopenfilename', Sys.getCwd()];
					if (extension != '')
						args.push('*' + extension);
				}

				var process = new sys.io.Process(cmd, args);
				var result:String = process.stdout.readAll().toString().trim();
				process.close();

				if (result != null && result.length > 0)
				{
					lime.app.Application.current.onUpdate.add(function(_)
					{
						lime.app.Application.current.onUpdate.remove(null);
						onSelected(result);
					});
				}
			}
			catch (e:Dynamic) {}
		});
		#end
	}
	#end

    #if windows
    private static function _openWindowsFolderPicker():Void
    {
        #if sys
        try
        {
            var currentPath:String = (ClientPrefs.data.modsPath != null && ClientPrefs.data.modsPath.length > 0)
                ? ClientPrefs.data.modsPath
                : Sys.getCwd() + 'mods';

            currentPath = currentPath.split('\\').join('\\\\');

            var script:String =
                'Add-Type -AssemblyName System.Windows.Forms;' +
                '$$d = New-Object System.Windows.Forms.FolderBrowserDialog;' +
                '$$d.Description = "Mod klasorunu secin";' +
                '$$d.SelectedPath = "' + currentPath + '";' +
                '$$d.ShowNewFolderButton = $$true;' +
                '$$f = New-Object System.Windows.Forms.Form;' +
                '$$f.TopMost = $$true;' +
                'if ($$d.ShowDialog($$f) -eq [System.Windows.Forms.DialogResult]::OK) { Write-Output $$d.SelectedPath }';

            var psPath:String = _findPowerShell();
            if (psPath == null)
            {
                showError('PowerShell bulunamadı!\nManuel olarak mod klasörünüzü belirtin.');
                return;
            }

            var process = new sys.io.Process(psPath, ['-NoProfile', '-NonInteractive', '-Command', script]);
            var result:String = process.stdout.readAll().toString().trim();
            process.close();

            if (result != null && result.length > 0)
                _onFolderSelected(result);
        }
        catch (e:Dynamic)
        {
            showError('Klasör seçici açılamadı!\n${e}');
        }
        #end
    }

    private static function _findPowerShell():String
    {
        #if sys
        var candidates:Array<String> = [
            'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
            'C:\\Windows\\SysWOW64\\WindowsPowerShell\\v1.0\\powershell.exe',
            'C:\\Program Files\\PowerShell\\7\\pwsh.exe',
            'C:\\Program Files (x86)\\PowerShell\\7\\pwsh.exe',
            'powershell.exe',
            'pwsh.exe'
        ];

        for (candidate in candidates)
        {
            try
            {
                if (candidate.contains('\\') && sys.FileSystem.exists(candidate))
                    return candidate;

                var p = new sys.io.Process('where', [candidate]);
                var out = p.stdout.readAll().toString().trim();
                p.close();
                if (out.length > 0)
                    return out.split('\n')[0].trim();
            }
            catch (_:Dynamic) {}
        }
        #end
        return null;
    }
    #end

    #if mac
    private static function _openMacFolderPicker():Void
    {
        #if sys
        try
        {
            var currentPath:String = (ClientPrefs.data.modsPath != null && ClientPrefs.data.modsPath.length > 0)
                ? ClientPrefs.data.modsPath
                : Sys.getCwd() + 'mods';

            var script:String = 'choose folder with prompt "Mod klasörünü seçin:" default location POSIX file "' + currentPath + '"';
            var process = new sys.io.Process('osascript', ['-e', script]);
            var result:String = process.stdout.readAll().toString().trim();
            process.close();

            if (result != null && result.length > 0)
            {
                var posixProcess = new sys.io.Process('osascript', [
                    '-e', 'POSIX path of ("' + result + '" as alias)'
                ]);
                var posixPath:String = posixProcess.stdout.readAll().toString().trim();
                posixProcess.close();

                if (posixPath != null && posixPath.length > 0)
                    _onFolderSelected(posixPath);
            }
        }
        catch (e:Dynamic)
        {
            showError('Klasör seçici açılamadı!\n${e}');
        }
        #end
    }
    #end

    #if linux
    private static function _openLinuxFolderPicker():Void
    {
        #if sys
        var cmd:String = _linuxPickerCommand();
        if (cmd == null)
        {
            showError('Klasör seçici için zenity veya kdialog yüklü olmalı!\nsudo apt install zenity');
            return;
        }

        try
        {
            var currentPath:String = (ClientPrefs.data.modsPath != null && ClientPrefs.data.modsPath.length > 0)
                ? ClientPrefs.data.modsPath
                : Sys.getCwd() + 'mods';

            var args:Array<String>;
            if (cmd == 'zenity')
                args = ['--file-selection', '--directory', '--title=Mod Klasörünü Seç', '--filename=' + currentPath + '/'];
            else
                args = ['--getexistingdirectory', currentPath];

            var process = new sys.io.Process(cmd, args);
            var result:String = process.stdout.readAll().toString().trim();
            process.close();

            if (result != null && result.length > 0)
                _onFolderSelected(result);
        }
        catch (e:Dynamic)
        {
            showError('Klasör seçici açılamadı!\n${e}');
        }
        #end
    }

    private static function _linuxPickerCommand():String
    {
        #if sys
        try
        {
            var p = new sys.io.Process('which', ['zenity']);
            var out = p.stdout.readAll().toString().trim();
            p.close();
            if (out.length > 0) return 'zenity';
        }
        catch (_:Dynamic) {}

        try
        {
            var p = new sys.io.Process('which', ['kdialog']);
            var out = p.stdout.readAll().toString().trim();
            p.close();
            if (out.length > 0) return 'kdialog';
        }
        catch (_:Dynamic) {}
        #end
        return null;
    }
    #end

    public static function resetModsDirectory():Void
    {
        _cachedModsDir = null;
        ClientPrefs.data.modsPath = '';
        ClientPrefs.saveSettings();
    }

    public static function _onFolderSelected(rawPath:String):Void
    {
        if (rawPath == null || rawPath.trim().length == 0)
            return;

        var cleanPath:String = #if android _resolveAndroidUri(rawPath) #else rawPath #end;

        if (!FileSystem.exists(cleanPath))
        {
            try { FileSystem.createDirectory(cleanPath); }
            catch (e:Dynamic)
            {
                showError('Seçilen klasör oluşturulamadı!\n$cleanPath');
                return;
            }
        }

        _cachedModsDir = null;
        ClientPrefs.data.modsPath = cleanPath;
        ClientPrefs.saveSettings();

        if (onModPathSelected != null)
            onModPathSelected(cleanPath);
    }

    #if android
    private static function _openAndroidFolderPicker():Void
    {
        try
        {
            var openPicker = JNI.createStaticMethod(
                'com/psychengineultra/StorageBridge',
                'openFolderPicker',
                '()V'
            );
            openPicker();
        }
        catch (e:Dynamic)
        {
            _showManualPathDialog();
        }
    }

    private static function _resolveAndroidUri(uri:String):String
    {
        if (uri.startsWith('content://'))
        {
            var parts = uri.split(':');
            if (parts.length >= 2)
            {
                var subPath = parts[parts.length - 1];
                subPath = StringTools.urlDecode(subPath);
                return '/sdcard/' + subPath.split('%2F').join('/');
            }
        }
        return uri;
    }
    #end

    #if ios
    private static function _openIOSFolderPicker():Void
    {
        try
        {
            _showManualPathDialog();
        }
        catch (e:Dynamic)
        {
            _showManualPathDialog();
        }
    }
    #end

    private static function _showManualPathDialog():Void
    {
        var defaultPath:String = #if android getExternalStorageDirectory() + 'mods' #else 'mods' #end;
        var current:String = (ClientPrefs.data.modsPath != null && ClientPrefs.data.modsPath.length > 0)
            ? ClientPrefs.data.modsPath
            : defaultPath;

        CoolUtil.showPopUp(
            'Mod klasörü yolu:\n$current\n\nDeğiştirmek için lütfen aşağıdaki yolu kullanın:\n$defaultPath',
            'Mod Klasörü'
        );
    }

    public static function saveContent(fileName:String, fileData:String, ?alert:Bool = true):Bool
    {
        if (fileName == null || fileName.length == 0)
        {
            if (alert) showError('Geçersiz dosya adı!');
            return false;
        }

        if (fileData == null)
        {
            if (alert) showError('Kaydedilecek veri bulunamadı!');
            return false;
        }

        final folder:String = #if android getExternalStorageDirectory() #else Sys.getCwd() #end + 'saves/';

        try
        {
            if (!createDirectoryIfNotExists(folder))
            {
                if (alert) showError(Language.getPhrase('folder_create_fail', 'Kayıt klasörü oluşturulamadı!'));
                return false;
            }

            var fullPath:String = folder + fileName;

            if (FileSystem.exists(fullPath))
            {
                try { backupFile(fullPath); }
                catch (e:Dynamic) {}
            }

            File.saveContent(fullPath, fileData);

            if (!FileSystem.exists(fullPath))
            {
                if (alert) showError('Dosya kaydetme doğrulaması başarısız!');
                return false;
            }

            var fileSize:Int = FileSystem.stat(fullPath).size;
            if (fileSize == 0)
            {
                if (alert) showError('Dosya boş kaydedildi!');
                return false;
            }

            if (alert)
                showSuccess(Language.getPhrase('file_save_success', '{1} başarıyla kaydedildi.', [fileName]));

            return true;
        }
        catch (e:Dynamic)
        {
            if (alert)
                showError(Language.getPhrase('file_save_fail', '{1} kaydetme başarısız.\n({2})', [fileName, e]));
            return false;
        }
    }

    public static function loadContent(fileName:String, ?alert:Bool = true):String
    {
        if (fileName == null || fileName.length == 0)
        {
            if (alert) showError('Geçersiz dosya adı!');
            return null;
        }

        final folder:String = #if android getExternalStorageDirectory() #else Sys.getCwd() #end + 'saves/';
        var fullPath:String = folder + fileName;

        try
        {
            if (!FileSystem.exists(fullPath))
            {
                if (alert) showError(Language.getPhrase('file_not_found', '{1} bulunamadı!', [fileName]));
                return null;
            }

            if (FileSystem.stat(fullPath).size == 0)
            {
                if (alert) showError(Language.getPhrase('file_empty', '{1} dosyası boş!', [fileName]));
                return null;
            }

            return File.getContent(fullPath);
        }
        catch (e:Dynamic)
        {
            if (alert)
                showError(Language.getPhrase('file_load_fail', '{1} okunamadı.\n({2})', [fileName, e]));
            return null;
        }
    }

    public static function fileExists(fileName:String, ?inSavesFolder:Bool = true):Bool
    {
        try
        {
            var fullPath:String = inSavesFolder
                ? (#if android getExternalStorageDirectory() #else Sys.getCwd() #end + 'saves/' + fileName)
                : fileName;
            return FileSystem.exists(fullPath);
        }
        catch (e:Dynamic)
        {
            return false;
        }
    }

    public static function deleteFile(fileName:String, ?alert:Bool = true):Bool
    {
        if (fileName == null || fileName.length == 0)
            return false;

        final folder:String = #if android getExternalStorageDirectory() #else Sys.getCwd() #end + 'saves/';
        var fullPath:String = folder + fileName;

        try
        {
            if (!FileSystem.exists(fullPath))
            {
                if (alert) showError(Language.getPhrase('file_not_found', '{1} bulunamadı!', [fileName]));
                return false;
            }

            try { backupFile(fullPath); }
            catch (e:Dynamic) {}

            FileSystem.deleteFile(fullPath);

            if (FileSystem.exists(fullPath))
            {
                if (alert) showError('Dosya silme başarısız!');
                return false;
            }

            if (alert) showSuccess(Language.getPhrase('file_delete_success', '{1} silindi.', [fileName]));
            return true;
        }
        catch (e:Dynamic)
        {
            if (alert)
                showError(Language.getPhrase('file_delete_fail', '{1} silinemedi.\n({2})', [fileName, e]));
            return false;
        }
    }

    public static function copyFile(source:String, destination:String, ?alert:Bool = true):Bool
    {
        try
        {
            if (!FileSystem.exists(source))
            {
                if (alert) showError('Kaynak dosya bulunamadı!');
                return false;
            }

            var content:String = File.getContent(source);
            File.saveContent(destination, content);

            if (!FileSystem.exists(destination))
                return false;

            return true;
        }
        catch (e:Dynamic)
        {
            if (alert) showError('Dosya kopyalanamadı!\n${e}');
            return false;
        }
    }

    public static function createDirectoryIfNotExists(path:String):Bool
    {
        try
        {
            if (!FileSystem.exists(path))
            {
                FileSystem.createDirectory(path);
                if (!FileSystem.exists(path))
                    return false;
            }
            return true;
        }
        catch (e:Dynamic)
        {
            return false;
        }
    }

    private static function backupFile(filePath:String):Void
    {
        if (!FileSystem.exists(filePath)) return;
        File.saveContent(filePath + '.backup', File.getContent(filePath));
    }

    private static function showError(message:String):Void
        CoolUtil.showPopUp(message, Language.getPhrase('mobile_error', 'HATA!'));

    private static function showSuccess(message:String):Void
        CoolUtil.showPopUp(message, Language.getPhrase('mobile_success', 'Başarılı!'));

    public static function getErrorLogs():Array<String>
        return errorLog.copy();

    public static function clearErrorLogs():Void
    {
        errorLog = [];
        try
        {
            var logPath:String = getStorageDirectory() + 'storage_errors.log';
            if (FileSystem.exists(logPath)) FileSystem.deleteFile(logPath);
        }
        catch (e:Dynamic) {}
    }

    public static function setDebugMode(enabled:Bool):Void
        debugMode = enabled;

    #if android
    public static function checkPermissions():Bool
    {
        try
        {
            var hasPermissions:Bool = false;

            if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
            {
                hasPermissions = AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_MEDIA_IMAGES')
                    || AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_MEDIA_VIDEO')
                    || AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_MEDIA_AUDIO');
            }
            else
            {
                hasPermissions = AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE');
            }

            return hasPermissions;
        }
        catch (e:Dynamic)
        {
            return false;
        }
    }

    public static function requestPermissions():Void
    {
        try
        {
            if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
                AndroidPermissions.requestPermissions(['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO', 'READ_MEDIA_VISUAL_USER_SELECTED']);
            else
                AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);

            if (!AndroidEnvironment.isExternalStorageManager())
                AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');

            var permissionGranted:Bool = (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
                ? AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_MEDIA_IMAGES')
                : AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE');

            if (!permissionGranted)
            {
                CoolUtil.showPopUp(
                    Language.getPhrase('permissions_message',
                        'İzinleri kabul ettiyseniz, her şey yolunda demektir!\n' +
                        'Kabul etmediyseniz, Oyun Açılmayacaktır!\n' +
                        'Lütfen Uygulamanın izinler bölümünden tüm izinleri verin.'),
                    Language.getPhrase('mobile_notice', 'DİKKAT!')
                );
            }

            var storageDir:String = getStorageDirectory();
            if (!FileSystem.exists(storageDir))
            {
                FileSystem.createDirectory(storageDir);
                if (!FileSystem.exists(storageDir))
                    throw 'Ana dizin oluşturulamadı!';
            }

            var defaultModsDir:String = getExternalStorageDirectory() + 'mods';
            if (!FileSystem.exists(defaultModsDir))
            {
                FileSystem.createDirectory(defaultModsDir);
                if (!FileSystem.exists(defaultModsDir))
                    throw 'Mods dizini oluşturulamadı!';
            }

            try
            {
                var savesDir:String = getExternalStorageDirectory() + 'saves';
                if (!FileSystem.exists(savesDir))
                    FileSystem.createDirectory(savesDir);
            }
            catch (e:Dynamic) {}
        }
        catch (e:Dynamic)
        {
            CoolUtil.showPopUp(
                Language.getPhrase('create_directory_error',
                    'Dizin Oluşturulamadı! Lütfen Şuraya Klasör Oluşturun\n{1}\nHata: {2}',
                    [getStorageDirectory(), e]),
                Language.getPhrase('mobile_error', 'HATA!')
            );
            lime.system.System.exit(1);
        }
    }

    public static function getStorageInfo():String
    {
        try
        {
            var info:String = '=== Depolama Bilgisi ===\n';
            info += 'Ana Dizin: ${getStorageDirectory()}\n';
            info += 'Harici Dizin: ${getExternalStorageDirectory()}\n';
            info += 'Mod Dizini: ${getModsDirectory()}\n';
            info += 'Özel Mod Yolu: ${ClientPrefs.data.modsPath}\n';
            info += 'İzinler: ${checkPermissions() ? "TAMAM" : "EKSİK"}\n';
            info += 'Android SDK: ${AndroidVersion.SDK_INT}\n';
            info += 'Storage Manager: ${AndroidEnvironment.isExternalStorageManager() ? "AKTİF" : "İNAKTİF"}\n';
            info += '\nDizin Durumu:\n';
            info += '- Ana: ${FileSystem.exists(getStorageDirectory()) ? "VAR" : "YOK"}\n';
            info += '- Mods: ${FileSystem.exists(getModsDirectory()) ? "VAR" : "YOK"}\n';
            info += '- Saves: ${FileSystem.exists(getExternalStorageDirectory() + "saves") ? "VAR" : "YOK"}\n';
            return info;
        }
        catch (e:Dynamic) { return 'Bilgi alınamadı: ${e}'; }
    }
    #end
    #end
}
