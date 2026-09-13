import 'package:flutter/material.dart';

class UiStrings {
  final String languageCode;

  const UiStrings._(this.languageCode);

  factory UiStrings.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return UiStrings._(code);
  }

  String _pick(Map<String, String> values) {
    return values[languageCode] ?? values['en']!;
  }

  String get myLanguages => _pick({
        'zh': '我的语言',
        'en': 'My languages',
        'ms': 'Bahasa saya',
        'vi': 'Ngôn ngữ của tôi',
        'ru': 'Мои языки',
      });

  String itemCount(int count) => _pick({
        'zh': '$count 项',
        'en': '$count items',
        'ms': '$count item',
        'vi': '$count mục',
        'ru': '$count элементов',
      });

  String get failedToLoadData => _pick({
        'zh': '加载数据失败',
        'en': 'Failed to load data',
        'ms': 'Gagal memuatkan data',
        'vi': 'Không thể tải dữ liệu',
        'ru': 'Не удалось загрузить данные',
      });

  String get removeLanguage => _pick({
        'zh': '移除语言',
        'en': 'Remove language',
        'ms': 'Buang bahasa',
        'vi': 'Xóa ngôn ngữ',
        'ru': 'Удалить язык',
      });

  String confirmRemoveLanguage(String name) => _pick({
        'zh': '确定要从列表中移除“$name”吗？',
        'en': 'Remove "$name" from your list?',
        'ms': 'Buang "$name" daripada senarai anda?',
        'vi': 'Xóa "$name" khỏi danh sách?',
        'ru': 'Удалить «$name» из списка?',
      });

  String get cancel => _pick({
        'zh': '取消',
        'en': 'Cancel',
        'ms': 'Batal',
        'vi': 'Hủy',
        'ru': 'Отмена',
      });

  String get remove => _pick({
        'zh': '移除',
        'en': 'Remove',
        'ms': 'Buang',
        'vi': 'Xóa',
        'ru': 'Удалить',
      });

  String get removeFromHome => _pick({
        'zh': '从首页移除',
        'en': 'Remove from home',
        'ms': 'Buang dari halaman utama',
        'vi': 'Xóa khỏi trang chủ',
        'ru': 'Удалить с главной',
      });

  String get welcomeBack => _pick({
        'zh': '欢迎回来',
        'en': 'Welcome back',
        'ms': 'Selamat kembali',
        'vi': 'Chào mừng trở lại',
        'ru': 'С возвращением',
      });

  String get startBuildingLibrary => _pick({
        'zh': '从这里开始建立属于你的世界语言库。',
        'en': 'Start building your world language library here.',
        'ms': 'Mulakan membina perpustakaan bahasa dunia anda di sini.',
        'vi': 'Bắt đầu xây dựng thư viện ngôn ngữ thế giới của bạn tại đây.',
        'ru': 'Начните создавать свою библиотеку языков мира.',
      });

  String get continueExploring => _pick({
        'zh': '继续探索语言、文字与不同地区的表达方式。',
        'en': 'Continue exploring languages, scripts, and regional expressions.',
        'ms': 'Terus terokai bahasa, tulisan dan variasi serantau.',
        'vi': 'Tiếp tục khám phá ngôn ngữ, chữ viết và cách diễn đạt vùng miền.',
        'ru': 'Продолжайте изучать языки, письменности и региональные варианты.',
      });

  String get added => _pick({
        'zh': '已加入',
        'en': 'Added',
        'ms': 'Ditambah',
        'vi': 'Đã thêm',
        'ru': 'Добавлено',
      });

  String get countriesRegions => _pick({
        'zh': '国家地区',
        'en': 'Countries',
        'ms': 'Negara',
        'vi': 'Quốc gia',
        'ru': 'Страны',
      });

  String get dialectVariants => _pick({
        'zh': '方言变体',
        'en': 'Variants',
        'ms': 'Varian',
        'vi': 'Biến thể',
        'ru': 'Варианты',
      });

  String get exploreLanguageLibrary => _pick({
        'zh': '探索语言库',
        'en': 'Explore languages',
        'ms': 'Terokai bahasa',
        'vi': 'Khám phá ngôn ngữ',
        'ru': 'Изучить языки',
      });

  String get addMoreLanguages => _pick({
        'zh': '添加更多语言',
        'en': 'Add more languages',
        'ms': 'Tambah lagi bahasa',
        'vi': 'Thêm ngôn ngữ',
        'ru': 'Добавить языки',
      });

  String get noLanguagesYet => _pick({
        'zh': '还没有加入语言',
        'en': 'No languages added yet',
        'ms': 'Belum ada bahasa ditambah',
        'vi': 'Chưa thêm ngôn ngữ nào',
        'ru': 'Языки пока не добавлены',
      });

  String get noLanguagesYetDescription => _pick({
        'zh': '选择一个国家，再加入你正在学习或使用的语言。',
        'en': 'Choose a country, then add a language you are learning or using.',
        'ms': 'Pilih sebuah negara, kemudian tambah bahasa yang anda pelajari atau gunakan.',
        'vi': 'Chọn một quốc gia, sau đó thêm ngôn ngữ bạn đang học hoặc sử dụng.',
        'ru': 'Выберите страну, затем добавьте язык, который вы изучаете или используете.',
      });

  String get addFirstLanguage => _pick({
        'zh': '添加第一门语言',
        'en': 'Add your first language',
        'ms': 'Tambah bahasa pertama',
        'vi': 'Thêm ngôn ngữ đầu tiên',
        'ru': 'Добавить первый язык',
      });

  String get selectCountry => _pick({
        'zh': '选择国家',
        'en': 'Select country',
        'ms': 'Pilih negara',
        'vi': 'Chọn quốc gia',
        'ru': 'Выберите страну',
      });

  String get searchCountry => _pick({
        'zh': '搜索国家',
        'en': 'Search countries',
        'ms': 'Cari negara',
        'vi': 'Tìm quốc gia',
        'ru': 'Поиск страны',
      });

  String get countryNotFound => _pick({
        'zh': '没有找到这个国家',
        'en': 'No country found',
        'ms': 'Negara tidak ditemui',
        'vi': 'Không tìm thấy quốc gia',
        'ru': 'Страна не найдена',
      });

  String countryLanguages(String country) => _pick({
        'zh': '$country的语言',
        'en': 'Languages of $country',
        'ms': 'Bahasa di $country',
        'vi': 'Ngôn ngữ tại $country',
        'ru': 'Языки: $country',
      });

  String get noCountryLanguageData => _pick({
        'zh': '这个国家暂时没有语言资料',
        'en': 'No language data is available for this country yet',
        'ms': 'Belum ada data bahasa untuk negara ini',
        'vi': 'Chưa có dữ liệu ngôn ngữ cho quốc gia này',
        'ru': 'Для этой страны пока нет языковых данных',
      });

  String get languageDataMissing => _pick({
        'zh': '语言资料不存在',
        'en': 'Language data is unavailable',
        'ms': 'Data bahasa tidak tersedia',
        'vi': 'Không có dữ liệu ngôn ngữ',
        'ru': 'Данные языка отсутствуют',
      });

  String get selectLanguageOrDialect => _pick({
        'zh': '选择语言或方言',
        'en': 'Select language or variant',
        'ms': 'Pilih bahasa atau varian',
        'vi': 'Chọn ngôn ngữ hoặc biến thể',
        'ru': 'Выберите язык или вариант',
      });

  String allLanguage(String name) => _pick({
        'zh': '$name（全部）',
        'en': '$name (All)',
        'ms': '$name (Semua)',
        'vi': '$name (Tất cả)',
        'ru': '$name (Все)',
      });

  String get addToHome => _pick({
        'zh': '加入首页',
        'en': 'Add to home',
        'ms': 'Tambah ke halaman utama',
        'vi': 'Thêm vào trang chủ',
        'ru': 'Добавить на главную',
      });

  String get addedToHome => _pick({
        'zh': '已经加入首页',
        'en': 'Added to home',
        'ms': 'Ditambah ke halaman utama',
        'vi': 'Đã thêm vào trang chủ',
        'ru': 'Добавлено на главную',
      });

  String get alreadyOnHome => _pick({
        'zh': '首页中已经存在',
        'en': 'Already on the home screen',
        'ms': 'Sudah ada di halaman utama',
        'vi': 'Đã có trên trang chủ',
        'ru': 'Уже есть на главной',
      });

  String languageOverview(String language) => _pick({
        'zh': '$language 的语言资料入口。\n\n点击下面的模块查看字母表、词条、词缀规则、语法说明、日常短语和词形分析。',
        'en': 'Language resources for $language.\n\nUse the modules below to explore the alphabet, words, affixes, grammar, everyday phrases, and morphology.',
        'ms': 'Sumber bahasa untuk $language.\n\nGunakan modul di bawah untuk melihat abjad, perkataan, imbuhan, tatabahasa, frasa harian dan morfologi.',
        'vi': 'Tài nguyên ngôn ngữ cho $language.\n\nSử dụng các mục bên dưới để xem bảng chữ cái, từ vựng, phụ tố, ngữ pháp, cụm từ hằng ngày và hình thái học.',
        'ru': 'Языковые материалы для $language.\n\nИспользуйте разделы ниже для изучения алфавита, слов, аффиксов, грамматики, повседневных фраз и морфологии.',
      });

  String get alphabet => _pick({
        'zh': '字母表',
        'en': 'Alphabet',
        'ms': 'Abjad',
        'vi': 'Bảng chữ cái',
        'ru': 'Алфавит',
      });

  String get words => _pick({
        'zh': '单词',
        'en': 'Words',
        'ms': 'Perkataan',
        'vi': 'Từ vựng',
        'ru': 'Слова',
      });

  String get affixRules => _pick({
        'zh': '词缀规则',
        'en': 'Affixes',
        'ms': 'Imbuhan',
        'vi': 'Phụ tố',
        'ru': 'Аффиксы',
      });

  String get grammar => _pick({
        'zh': '语法说明',
        'en': 'Grammar',
        'ms': 'Tatabahasa',
        'vi': 'Ngữ pháp',
        'ru': 'Грамматика',
      });

  String get dailyPhrases => _pick({
        'zh': '日常短语',
        'en': 'Daily phrases',
        'ms': 'Frasa harian',
        'vi': 'Cụm từ hằng ngày',
        'ru': 'Повседневные фразы',
      });

  String get morphologyAnalysis => _pick({
        'zh': '词形分析',
        'en': 'Morphology',
        'ms': 'Morfologi',
        'vi': 'Hình thái học',
        'ru': 'Морфология',
      });
}
