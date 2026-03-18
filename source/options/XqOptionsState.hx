package options;

class XqOptionsState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Xq Ayarlari';
		rpcTitle = 'Xq Ayarları';

		var option:Option = new Option(
			'Gizli Sarkilar',
			'Aktif edildiğinde.... Şey.',
			'secretsongs',
			'BOOL'
		);
		addOption(option);

		option = new Option(
			'Beta Özellikler',
			'Aktif edildiğinde, Beta Özellikleri Etkinleştirir. (ÖNERİLMEZ, SADECE TEST AMAÇLI KULLANIN)',
			'beta',
			'BOOL'
		);
		addOption(option);
		
		option = new Option(
			'Hile Menüsü',
			'Aktif edildiğinde, ... LAN. HİLECİ.',
			'hackmenu',
			'BOOL'
		);
		addOption(option);
		
		option = new Option(
			'Bilmem',
			'Aktif edildiğinde, her saniye %1 şans ile xq nun ifşa videoları oynar. (Çalış artık amk)',
			'idk',
			'BOOL'
		);
		addOption(option);

		super();
	}
}
