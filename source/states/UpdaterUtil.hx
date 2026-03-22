package states;

import haxe.Http;
import haxe.io.Bytes;
import haxe.zip.Reader;
import haxe.zip.Entry;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import lime.app.Application;

class UpdaterUtil
{
	public static var GITHUB_USER:String = "Samedcan1234";
	public static var GITHUB_REPO:String = "Psych-Engine-Ultra";
	public static var WINDOWS_ZIP_NAME:String = "GUNCELLEME-windows.zip";
	public static var ANDROID_ZIP_NAME:String = "GUNCELLEME-android.zip";
	public static var TEMP_ZIP_NAME:String = "update_temp.zip";
	public static var TEMP_EXTRACT_DIR:String = "update_extract_temp";

	public static function isAndroid():Bool
	{
		#if android
		return true;
		#else
		return false;
		#end
	}

	public static function isWindows():Bool
	{
		#if windows
		return true;
		#else
		return false;
		#end
	}

	public static function getDownloadURL():String
	{
		var zipName:String = isAndroid() ? ANDROID_ZIP_NAME : WINDOWS_ZIP_NAME;
		return 'https://github.com/$GITHUB_USER/$GITHUB_REPO/releases/latest/download/$zipName';
	}

	public static function getLatestVersionURL():String
	{
		return 'https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/releases/latest';
	}

	public static function getTempZipPath():String
	{
		#if android
		return lime.system.System.applicationStorageDirectory + TEMP_ZIP_NAME;
		#else
		return Sys.getCwd() + TEMP_ZIP_NAME;
		#end
	}

	public static function getTempExtractPath():String
	{
		#if android
		return lime.system.System.applicationStorageDirectory + TEMP_EXTRACT_DIR + "/";
		#else
		return Sys.getCwd() + TEMP_EXTRACT_DIR + "/";
		#end
	}

	public static function getGameDirectory():String
	{
		#if android
		return lime.system.System.applicationStorageDirectory;
		#else
		return Sys.getCwd();
		#end
	}

	public static function downloadUpdate(
		url:String,
		onProgress:Float->Int->Int->Void,
		onComplete:String->Void,
		onError:String->Void
	):Void
	{
		var zipPath:String = getTempZipPath();

		try
		{
			var http:Http = new Http(url);
			var totalBytes:Int = 0;
			var receivedBytes:Int = 0;
			var outputBytes:haxe.io.BytesOutput = new haxe.io.BytesOutput();

			http.onBytes = function(bytes:Bytes)
			{
				receivedBytes += bytes.length;
				outputBytes.writeBytes(bytes, 0, bytes.length);

				if (totalBytes > 0)
					onProgress(receivedBytes / totalBytes, receivedBytes, totalBytes);
				else
					onProgress(0, receivedBytes, totalBytes);
			};

			http.onStatus = function(status:Int) {};

			http.onError = function(error:String)
			{
				onError('İndirme hatası: $error');
			};

			http.onData = function(data:String) {};

			http.addHeader("User-Agent", "PsychEngineUltra-Updater");

			#if sys
			var req = new haxe.Http(url);
			req.addHeader("User-Agent", "PsychEngineUltra-Updater");

			var output = new haxe.io.BytesOutput();
			req.customRequest(false, output);

			var downloadedBytes = output.getBytes();

			if (downloadedBytes == null || downloadedBytes.length == 0)
			{
				onError("İndirilen dosya boş! URL'yi kontrol et.");
				return;
			}

			File.saveBytes(zipPath, downloadedBytes);
			onProgress(1.0, downloadedBytes.length, downloadedBytes.length);
			onComplete(zipPath);
			#end
		}
		catch (e:Dynamic)
		{
			onError('Beklenmeyen hata: $e');
		}
	}

	public static function applyUpdate(
		zipPath:String,
		onProgress:Float->String->Void,
		onComplete:Void->Void,
		onError:String->Void
	):Void
	{
		try
		{
			if (!FileSystem.exists(zipPath))
			{
				onError('ZIP dosyası bulunamadı: $zipPath');
				return;
			}

			var gameDir:String = getGameDirectory();
			var extractDir:String = getTempExtractPath();

			if (FileSystem.exists(extractDir))
				deleteDirectory(extractDir);
			FileSystem.createDirectory(extractDir);

			var zipBytes:Bytes = File.getBytes(zipPath);
			var zipInput:haxe.io.BytesInput = new haxe.io.BytesInput(zipBytes);
			var entries:List<Entry> = Reader.readZip(zipInput);

			var totalEntries:Int = 0;
			var processedEntries:Int = 0;

			for (entry in entries)
				totalEntries++;

			for (entry in entries)
			{
				var fileName:String = entry.fileName;
				var destPath:String = gameDir + fileName;

				onProgress(processedEntries / totalEntries, fileName);

				if (StringTools.endsWith(fileName, "/") || StringTools.endsWith(fileName, "\\"))
				{
					if (!FileSystem.exists(destPath))
						FileSystem.createDirectory(destPath);
					processedEntries++;
					continue;
				}

				var destDir:String = destPath.substring(0, destPath.lastIndexOf("/"));
				if (destDir != "" && !FileSystem.exists(destDir))
					createDirectoryRecursive(destDir);

				var fileBytes:Bytes = null;

				if (entry.compressed)
					fileBytes = haxe.zip.Uncompress.run(entry.data);
				else
					fileBytes = entry.data;

				File.saveBytes(destPath, fileBytes);

				processedEntries++;
			}

			if (FileSystem.exists(zipPath))
				FileSystem.deleteFile(zipPath);

			if (FileSystem.exists(extractDir))
				deleteDirectory(extractDir);

			onProgress(1.0, "Tamamlandı!");
			onComplete();
		}
		catch (e:Dynamic)
		{
			onError('ZIP uygulama hatası: $e');
		}
	}

	public static function deleteDirectory(path:String):Void
	{
		if (!FileSystem.exists(path))
			return;

		for (item in FileSystem.readDirectory(path))
		{
			var itemPath = path + "/" + item;
			if (FileSystem.isDirectory(itemPath))
				deleteDirectory(itemPath);
			else
				FileSystem.deleteFile(itemPath);
		}

		FileSystem.deleteDirectory(path);
	}

	public static function createDirectoryRecursive(path:String):Void
	{
		var parts = path.split("/");
		var current = "";

		for (part in parts)
		{
			if (part == "")
				continue;
			current += part + "/";
			if (!FileSystem.exists(current))
				FileSystem.createDirectory(current);
		}
	}

	public static function restartGame():Void
	{
		#if windows
		var exePath = Sys.programPath();
		new Process(exePath, []);
		lime.system.System.exit(0);
		#elseif android
		lime.system.System.exit(0);
		#else
		lime.system.System.exit(0);
		#end
	}

	public static function formatBytes(bytes:Int):String
	{
		if (bytes < 1024)
			return bytes + " B";
		else if (bytes < 1024 * 1024)
			return Std.string(Math.round(bytes / 1024 * 10) / 10) + " KB";
		else
			return Std.string(Math.round(bytes / (1024 * 1024) * 10) / 10) + " MB";
	}
}