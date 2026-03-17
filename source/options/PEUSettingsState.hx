package options;

class PEUSettingsState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'P.E.U Ayarları';
		rpcTitle = 'P.E.T Ayarları Menüsünde';

		var option:Option = new Option(
			'P.E.T Filigrani',
			'Aktif edildiğinde, sol üstte tarafta Psych Engine Türkiye filigranı aktif hale gelir.',
			'petwatermark',
			'BOOL'
		);
		addOption(option);

		option = new Option(
			'P.E.U Yükleme Ekrani',
			'Aktif edildiğinde, P.E.U yükleme ekranlarını etkinleştirir, orjinal yükleme ekranı yerine P.E.U nun yükleme resimlerini kullanır.',
			'petloadingscreen',
			'BOOL'
		);
		addOption(option);

		option = new Option(
			'P.E.T Logo Stili:',
			'Filigrandaki logoyu seçin.',
			'petwatermarklogo',
			STRING,
			['V1', 'V2', 'V2U', 'V2UP', 'V3', 'ONLINE', 'UNL']
		);
		option.dependsOn = 'petwatermark';
		addOption(option);

		option = new Option(
			'P.E.T Yükleme Ekranı Stili:',
			'P.E.T.O nun Kullanacağı Yükleme ekranı Stilini seçin.',
			'petloadingscreenimage',
			STRING,
			['V1', 'V2', 'V2U', 'ONLINE']
		);
		option.dependsOn = 'petloadingscreen';
		addOption(option);
		
		option = new Option(
			'Introyu Kapat',
			'Aktif edildiğinde, Oyunun başlangıcında oynatılan Intro videosu devre-dışı bırakılır.',
			'disableIntroVideo',
			'BOOL'
		);
		addOption(option);

		option = new Option(
			'Menü Temasi:',
			'Menülerin Temasını seçin.',
			'menuTheme',
			STRING,
			['V3', 'Türkiye', 'Orjinal', 'V1']
		);
		addOption(option);

		super();
	}
}
