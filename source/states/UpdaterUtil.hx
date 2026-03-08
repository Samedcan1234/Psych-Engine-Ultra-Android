package states;

import haxe.Http;
import haxe.io.Bytes;
import haxe.zip.Reader;
import haxe.zip.Entry;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import lime.app.Application;

/**
 * Psych Engine Ultra - UpdaterUtil.hx
 * Güncelleme sistemi için yardımcı fonksiyonlar.
 * Platform tespiti, indirme, ZIP Extract ve dosya değiştirme işlemlerini yapar.
 * 
 * Kullanım:
 *   - UpdaterUtil.getDownloadURL() → Platform'a göre doğru URL'yi döndürür
 *   - UpdaterUtil.downloadUpdate(url, onProgress, onComplete, onError) → ZIP indirir
 *   - UpdaterUtil.applyUpdate(zipPath, onProgress, onComplete, onError) → ZIP'i çıkarıp uygular
 * 
 * GitHub Releases URL formatı:
 *   https://github.com/KULLANICIN/psych-engine-ultra/releases/latest/download/GUNCELLEME-windows.zip
 *   https://github.com/KULLANICIN/psych-engine-ultra/releases/latest/download/GUNCELLEME-android.zip
 */
class UpdaterUtil
{
	// =============================================
	// AYARLAR - Buraya kendi bilgilerini gir!
	// =============================================

	/** GitHub kullanıcı adın */
	public static var GITHUB_USER:String = "KULLANICIN";

	/** GitHub repo adın */
	public static var GITHUB_REPO:String = "psych-engine-ultra";

	/** Windows için ZIP dosyasının adı (GitHub Releases'da yükleyeceğin isim) */
	public static var WINDOWS_ZIP_NAME:String = "GUNCELLEME-windows.zip";

	/** Android için ZIP dosyasının adı (GitHub Releases'da yükleyeceğin isim) */
	public static var ANDROID_ZIP_NAME:String = "GUNCELLEME-android.zip";

	/** İndirilen ZIP'in geçici olarak kaydedileceği dosya adı */
	public static var TEMP_ZIP_NAME:String = "update_temp.zip";

	/** ZIP çıkartılacak geçici klasör adı */
	public static var TEMP_EXTRACT_DIR:String = "update_extract_temp";

	// =============================================
	// PLATFORM TESPİTİ
	// =============================================

	/** Şu an Android'de mi çalışıyor? */
	public static function isAndroid():Bool
	{
		#if android
		return true;
		#else
		return false;
		#end
	}

	/** Şu an Windows'ta mı çalışıyor? */
	public static function isWindows():Bool
	{
		#if windows
		return true;
		#else
		return false;
		#end
	}

	/**
	 * Platform'a göre doğru indirme URL'sini döndürür.
	 * GitHub Releases'ın /latest/download/ endpointi her zaman
	 * EN SON SÜRÜMÜ İNDİR
	 */
	public static function getDownloadURL():String
	{
		var zipName:String = isAndroid() ? ANDROID_ZIP_NAME : WINDOWS_ZIP_NAME;
		return 'https://github.com/$GITHUB_USER/$GITHUB_REPO/releases/latest/download/$zipName';
	}

	/**
	 * GitHub API üzerinden en son sürüm tag'ini alır.
	 * Versiyon karşılaştırması için kullanılır.
	 */
	public static function getLatestVersionURL():String
	{
		return 'https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/releases/latest';
	}

	// =============================================
	// DOSYA YOLLARI
	// =============================================

	/** Geçici ZIP dosyasının tam yolu */
	public static function getTempZipPath():String
	{
		#if android
		// Android'de yazılabilir dizin
		return lime.system.System.applicationStorageDirectory + TEMP_ZIP_NAME;
		#else
		// PC'de oyunun yanındaki klasör
		return Sys.getCwd() + TEMP_ZIP_NAME;
		#end
	}

	/** Geçici çıkartma klasörünün tam yolu */
	public static function getTempExtractPath():String
	{
		#if android
		return lime.system.System.applicationStorageDirectory + TEMP_EXTRACT_DIR + "/";
		#else
		return Sys.getCwd() + TEMP_EXTRACT_DIR + "/";
		#end
	}

	/** Oyunun ana dizini (dosyalar buraya kopyalanacak) */
	public static function getGameDirectory():String
	{
		#if android
		return lime.system.System.applicationStorageDirectory;
		#else
		return Sys.getCwd();
		#end
	}

	// =============================================
	// İNDİRME
	// =============================================

	/**
	 * Güncelleme ZIP'ini indirir.
	 * @param url          İndirilecek URL
	 * @param onProgress   İlerleme callback'i (0.0 - 1.0 arası float, indirilen byte, toplam byte)
	 * @param onComplete   Tamamlandığında çağrılır (zipPath:String)
	 * @param onError      Hata durumunda çağrılır (errorMsg:String)
	 */
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

			// İndirme ilerlemesini takip et
			http.onBytes = function(bytes:Bytes)
			{
				receivedBytes += bytes.length;
				outputBytes.writeBytes(bytes, 0, bytes.length);

				if (totalBytes > 0)
					onProgress(receivedBytes / totalBytes, receivedBytes, totalBytes);
				else
					onProgress(0, receivedBytes, totalBytes);
			};

			http.onStatus = function(status:Int)
			{
				// Content-Length header'ından toplam boyutu al
				// (Bazı redirect'lerde çalışmayabilir, bu normal)
			};

			http.onError = function(error:String)
			{
				onError('İndirme hatası: $error');
			};

			http.onData = function(data:String)
			{
				// Bu callback bytes kullanıldığında tetiklenmez, güvenli geçebiliriz
			};

			// Header ekle (GitHub API için gerekli)
			http.addHeader("User-Agent", "PsychEngineUltra-Updater");

			// Asenkron indirme başlat
			#if sys
			// Senkron indirme (thread yoksa)
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

			// ZIP'i diske kaydet
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

	// =============================================
	// ZIP ÇIKARMA & UYGULAMA
	// =============================================

	/**
	 * İndirilen ZIP'i çıkarır ve oyun dosyalarının üzerine yazar.
	 * @param zipPath      ZIP dosyasının yolu
	 * @param onProgress   İlerleme callback'i (0.0 - 1.0, işlenen dosya adı)
	 * @param onComplete   Tamamlandığında çağrılır
	 * @param onError      Hata durumunda çağrılır
	 */
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

			// Geçici klasörü oluştur (varsa temizle)
			if (FileSystem.exists(extractDir))
				deleteDirectory(extractDir);
			FileSystem.createDirectory(extractDir);

			// ZIP'i oku
			var zipBytes:Bytes = File.getBytes(zipPath);
			var zipInput:haxe.io.BytesInput = new haxe.io.BytesInput(zipBytes);
			var entries:List<Entry> = Reader.readZip(zipInput);

			var totalEntries:Int = 0;
			var processedEntries:Int = 0;

			// Toplam dosya sayısını say
			for (entry in entries)
				totalEntries++;

			// Her dosyayı çıkar
			for (entry in entries)
			{
				var fileName:String = entry.fileName;
				var destPath:String = gameDir + fileName;

				onProgress(processedEntries / totalEntries, fileName);

				// Klasör girişini atla
				if (StringTools.endsWith(fileName, "/") || StringTools.endsWith(fileName, "\\"))
				{
					if (!FileSystem.exists(destPath))
						FileSystem.createDirectory(destPath);
					processedEntries++;
					continue;
				}

				// Hedef klasörü oluştur
				var destDir:String = destPath.substring(0, destPath.lastIndexOf("/"));
				if (destDir != "" && !FileSystem.exists(destDir))
					createDirectoryRecursive(destDir);

				// Dosyayı sıkıştırmadan çıkar
				var fileBytes:Bytes = null;

				if (entry.compressed)
					fileBytes = haxe.zip.Uncompress.run(entry.data);
				else
					fileBytes = entry.data;

				// Doğrudan oyun dizinine yaz (üzerine yazar)
				File.saveBytes(destPath, fileBytes);

				processedEntries++;
			}

			// Geçici ZIP dosyasını sil
			if (FileSystem.exists(zipPath))
				FileSystem.deleteFile(zipPath);

			// Geçici klasörü sil
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

	// =============================================
	// YARDIMCI FONKSİYONLAR
	// =============================================

	/** Klasörü tüm içeriğiyle siler */
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

	/** İç içe klasör oluşturur */
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

	/** Oyunu yeniden başlatır (güncelleme sonrası) */
	public static function restartGame():Void
	{
		#if windows
		// Windows: mevcut exe'yi yeniden başlat
		var exePath = Sys.programPath();
		new Process(exePath, []);
		lime.system.System.exit(0);
		#elseif android
		// Android: uygulamayı kapat (kullanıcı manuel açar)
		lime.system.System.exit(0);
		#else
		lime.system.System.exit(0);
		#end
	}

	/** Byte sayısını okunabilir formata çevirir (örn: 4.2 MB) */
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
