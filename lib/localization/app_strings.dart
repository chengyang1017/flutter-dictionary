import 'package:flutter/material.dart';

class AppStrings {
  final String languageCode;

  const AppStrings._(this.languageCode);

  factory AppStrings.of(BuildContext context) {
    return AppStrings.forLanguageCode(
      Localizations.localeOf(context).languageCode,
    );
  }

  factory AppStrings.forLanguageCode(String languageCode) {
    final normalized = languageCode
            .trim()
            .toLowerCase()
            .split(RegExp('[-_]'))
            .first;

    return AppStrings._(normalized);
  }

  String _pick(Map<String, String> values) {
    return values[languageCode] ?? values['en']!;
  }

  String get interfaceLanguage => _pick({
        'zh': '界面语言',
        'en': 'Interface language',
        'ms': 'Bahasa antara muka',
        'vi': 'Ngôn ngữ giao diện',
        'ru': 'Язык интерфейса',
      });

  String get followSystem => _pick({
        'zh': '跟随系统',
        'en': 'Follow system',
        'ms': 'Ikut sistem',
        'vi': 'Theo hệ thống',
        'ru': 'Как в системе',
      });

  String get addLanguage => _pick({
        'zh': '添加语言',
        'en': 'Add language',
        'ms': 'Tambah bahasa',
        'vi': 'Thêm ngôn ngữ',
        'ru': 'Добавить язык',
      });

  String get settings => _pick({
        'zh': '设置',
        'en': 'Settings',
        'ms': 'Tetapan',
        'vi': 'Cài đặt',
        'ru': 'Настройки',
      });

  String get words => _pick({
        'zh': '单词',
        'en': 'Words',
        'ms': 'Perkataan',
        'vi': 'Từ vựng',
        'ru': 'Слова',
      });

  String get searchHint => _pick({
        'zh': '搜索原形、真实词形或释义',
        'en': 'Search lemma, inflected form, or meaning',
        'ms': 'Cari kata dasar, bentuk kata atau makna',
        'vi': 'Tìm từ gốc, dạng biến đổi hoặc nghĩa',
        'ru': 'Поиск по лемме, словоформе или значению',
      });

  String get failedToLoadEntries => _pick({
        'zh': '加载词条失败',
        'en': 'Failed to load entries',
        'ms': 'Gagal memuatkan entri',
        'vi': 'Không thể tải mục từ',
        'ru': 'Не удалось загрузить словарные статьи',
      });

  String get retry => _pick({
        'zh': '重新加载',
        'en': 'Retry',
        'ms': 'Cuba lagi',
        'vi': 'Thử lại',
        'ru': 'Повторить',
      });

  String get noEntries => _pick({
        'zh': '没有找到词条',
        'en': 'No entries found',
        'ms': 'Tiada entri ditemui',
        'vi': 'Không tìm thấy mục từ',
        'ru': 'Статьи не найдены',
      });

  String get unnamedEntry => _pick({
        'zh': '未命名词条',
        'en': 'Unnamed entry',
        'ms': 'Entri tanpa nama',
        'vi': 'Mục từ chưa đặt tên',
        'ru': 'Безымянная статья',
      });

  String get noun => _pick({
        'zh': '名词',
        'en': 'Noun',
        'ms': 'Kata nama',
        'vi': 'Danh từ',
        'ru': 'Существительное',
      });

  String get verb => _pick({
        'zh': '动词',
        'en': 'Verb',
        'ms': 'Kata kerja',
        'vi': 'Động từ',
        'ru': 'Глагол',
      });

  String get lemmaMatch => _pick({
        'zh': '原形命中',
        'en': 'Lemma match',
        'ms': 'Padanan kata dasar',
        'vi': 'Khớp từ gốc',
        'ru': 'Совпадение по лемме',
      });

  String get formMatch => _pick({
        'zh': '词形命中',
        'en': 'Form match',
        'ms': 'Padanan bentuk',
        'vi': 'Khớp dạng từ',
        'ru': 'Совпадение по форме',
      });

  String get glossMatch => _pick({
        'zh': '释义命中',
        'en': 'Meaning match',
        'ms': 'Padanan makna',
        'vi': 'Khớp nghĩa',
        'ru': 'Совпадение по значению',
      });

  String get failedToLoadForms => _pick({
        'zh': '读取词形变化失败',
        'en': 'Failed to load inflected forms',
        'ms': 'Gagal memuatkan bentuk kata',
        'vi': 'Không thể tải các dạng từ',
        'ru': 'Не удалось загрузить словоформы',
      });

  String get entryDetails => _pick({
    'zh': '词条详情',
    'en': 'Entry details',
    'ms': 'Butiran entri',
    'vi': 'Chi tiết mục từ',
    'ru': 'Словарная статья',
  });

  String get senses => _pick({
    'zh': '义项',
    'en': 'Senses',
    'ms': 'Makna',
    'vi': 'Nghĩa',
    'ru': 'Значения',
  });

  String get noGloss => _pick({
    'zh': '暂无释义',
    'en': 'No meaning available',
    'ms': 'Tiada makna tersedia',
    'vi': 'Chưa có nghĩa',
    'ru': 'Нет доступного значения',
  });

  String senseNumber(int number) => _pick({
    'zh': '义项 $number',
    'en': 'Sense $number',
    'ms': 'Makna $number',
    'vi': 'Nghĩa $number',
    'ru': 'Значение $number',
  });

  String get searchMatches => _pick({
    'zh': '搜索命中',
    'en': 'Search match',
    'ms': 'Padanan carian',
    'vi': 'Kết quả khớp',
    'ru': 'Совпадение поиска',
  });

  String searchedFor(String value) => _pick({
    'zh': '你搜索：$value',
    'en': 'You searched: $value',
    'ms': 'Anda mencari: $value',
    'vi': 'Bạn đã tìm: $value',
    'ru': 'Вы искали: $value',
  });

  String lemmaValue(String value) => _pick({
    'zh': '原形：$value',
    'en': 'Lemma: $value',
    'ms': 'Kata dasar: $value',
    'vi': 'Từ gốc: $value',
    'ru': 'Лемма: $value',
  });

  String fullParadigm(int count) => _pick({
    'zh': '完整词形变化 · $count',
    'en': 'Full paradigm · $count',
    'ms': 'Paradigma penuh · $count',
    'vi': 'Toàn bộ biến đổi từ · $count',
    'ru': 'Полная парадигма · $count',
  });

  String formsCount(int count) => _pick({
    'zh': '$count 个词形',
    'en': '$count forms',
    'ms': '$count bentuk',
    'vi': '$count dạng từ',
    'ru': '$count форм',
  });

  String get entryInformation => _pick({
    'zh': '词条信息',
    'en': 'Entry information',
    'ms': 'Maklumat entri',
    'vi': 'Thông tin mục từ',
    'ru': 'Информация о статье',
  });

  String get partOfSpeech => _pick({
    'zh': '词类',
    'en': 'Part of speech',
    'ms': 'Golongan kata',
    'vi': 'Từ loại',
    'ru': 'Часть речи',
  });

  String get language => _pick({
    'zh': '语言',
    'en': 'Language',
    'ms': 'Bahasa',
    'vi': 'Ngôn ngữ',
    'ru': 'Язык',
  });

  String get generatedForms => _pick({
    'zh': '已生成词形',
    'en': 'Generated forms',
    'ms': 'Bentuk dijana',
    'vi': 'Dạng từ đã tạo',
    'ru': 'Сгенерированные формы',
  });

  String get matchMethod => _pick({
    'zh': '命中方式',
    'en': 'Match type',
    'ms': 'Jenis padanan',
    'vi': 'Kiểu khớp',
    'ru': 'Тип совпадения',
  });

  String get otherInformation => _pick({
    'zh': '其他信息',
    'en': 'Other information',
    'ms': 'Maklumat lain',
    'vi': 'Thông tin khác',
    'ru': 'Другая информация',
  });

  String get noDetailedFields => _pick({
    'zh': '这个词条没有可显示的详细字段',
    'en': 'This entry has no additional details to display',
    'ms': 'Entri ini tiada butiran tambahan untuk dipaparkan',
    'vi': 'Mục từ này không có thông tin chi tiết để hiển thị',
    'ru': 'У этой статьи нет дополнительных данных для отображения',
  });

  String get details => _pick({
    'zh': '详细信息',
    'en': 'Details',
    'ms': 'Butiran',
    'vi': 'Chi tiết',
    'ru': 'Подробности',
  });

  String schemaLoadFailed(Object? error) => _pick({
    'zh': '读取语言 Schema 失败\n$error',
    'en': 'Failed to load language schema\n$error',
    'ms': 'Gagal memuatkan skema bahasa\n$error',
    'vi': 'Không thể tải lược đồ ngôn ngữ\n$error',
    'ru': 'Не удалось загрузить языковую схему\n$error',
  });

  String partOfSpeechLabel(String value) {
    switch (value) {
      case 'noun':
        return noun;
      case 'verb':
        return verb;
      default:
        return value;
    }
  }

  String matchTypeLabel(String value) {
    switch (value) {
      case 'lemma':
        return lemmaMatch;
      case 'form':
        return formMatch;
      case 'gloss':
        return glossMatch;
      default:
        return value;
    }
  }

  String morphologyGroupLabel(String key) {
    final labels = <String, Map<String, String>>{
      'singular': {
        'zh': '单数',
        'en': 'Singular',
        'ms': 'Tunggal',
        'vi': 'Số ít',
        'ru': 'Единственное число',
      },
      'plural': {
        'zh': '复数',
        'en': 'Plural',
        'ms': 'Jamak',
        'vi': 'Số nhiều',
        'ru': 'Множественное число',
      },
      'possessive': {
        'zh': '所属',
        'en': 'Possessive',
        'ms': 'Pemilikan',
        'vi': 'Sở hữu',
        'ru': 'Притяжательность',
      },
      'case': {
        'zh': '格',
        'en': 'Case',
        'ms': 'Kasus',
        'vi': 'Cách',
        'ru': 'Падеж',
      },
      'interrogative': {
        'zh': '疑问',
        'en': 'Interrogative',
        'ms': 'Interogatif',
        'vi': 'Nghi vấn',
        'ru': 'Вопросительная форма',
      },
      'special': {
        'zh': '特殊形',
        'en': 'Special forms',
        'ms': 'Bentuk khas',
        'vi': 'Dạng đặc biệt',
        'ru': 'Особые формы',
      },
      'infinitive': {
        'zh': '不定式',
        'en': 'Infinitive',
        'ms': 'Infinitif',
        'vi': 'Động từ nguyên mẫu',
        'ru': 'Инфинитив',
      },
      'past': {
        'zh': '过去时',
        'en': 'Past tense',
        'ms': 'Kala lampau',
        'vi': 'Thì quá khứ',
        'ru': 'Прошедшее время',
      },
      'present': {
        'zh': '现在时',
        'en': 'Present tense',
        'ms': 'Kala kini',
        'vi': 'Thì hiện tại',
        'ru': 'Настоящее время',
      },
      'future': {
        'zh': '将来时',
        'en': 'Future tense',
        'ms': 'Kala hadapan',
        'vi': 'Thì tương lai',
        'ru': 'Будущее время',
      },
      'person': {
        'zh': '人称',
        'en': 'Person',
        'ms': 'Persona',
        'vi': 'Ngôi',
        'ru': 'Лицо',
      },
      'negative': {
        'zh': '否定',
        'en': 'Negative',
        'ms': 'Negatif',
        'vi': 'Phủ định',
        'ru': 'Отрицание',
      },
      'other': {
        'zh': '其他',
        'en': 'Other',
        'ms': 'Lain-lain',
        'vi': 'Khác',
        'ru': 'Другое',
      },
    };

    final values = labels[key];
    return values == null ? key : values[languageCode] ?? values['en']!;
  }

  String featureLabel(String key) {
    final labels = <String, Map<String, String>>{
      'form_type': {
        'zh': '形态类型',
        'en': 'Form type',
        'ms': 'Jenis bentuk',
        'vi': 'Kiểu hình thái',
        'ru': 'Тип формы',
      },
      'tense': {
        'zh': '时态',
        'en': 'Tense',
        'ms': 'Kala',
        'vi': 'Thì',
        'ru': 'Время',
      },
      'person': {
        'zh': '人称',
        'en': 'Person',
        'ms': 'Persona',
        'vi': 'Ngôi',
        'ru': 'Лицо',
      },
      'negative': {
        'zh': '否定',
        'en': 'Negative',
        'ms': 'Negatif',
        'vi': 'Phủ định',
        'ru': 'Отрицание',
      },
      'number': {
        'zh': '数',
        'en': 'Number',
        'ms': 'Bilangan',
        'vi': 'Số',
        'ru': 'Число',
      },
      'possessive': {
        'zh': '所属',
        'en': 'Possessive',
        'ms': 'Pemilikan',
        'vi': 'Sở hữu',
        'ru': 'Притяжательность',
      },
      'case': {
        'zh': '格',
        'en': 'Case',
        'ms': 'Kasus',
        'vi': 'Cách',
        'ru': 'Падеж',
      },
      'interrogative': {
        'zh': '疑问',
        'en': 'Interrogative',
        'ms': 'Interogatif',
        'vi': 'Nghi vấn',
        'ru': 'Вопросительность',
      },
      'special': {
        'zh': '特殊形',
        'en': 'Special',
        'ms': 'Khas',
        'vi': 'Đặc biệt',
        'ru': 'Особая форма',
      },
    };

    final values = labels[key];
    return values == null ? key : values[languageCode] ?? values['en']!;
  }

  String featureValue(String key, dynamic value) {
    if (value is bool) {
      return value
          ? _pick({'zh': '是', 'en': 'Yes', 'ms': 'Ya', 'vi': 'Có', 'ru': 'Да'})
          : _pick({
              'zh': '否',
              'en': 'No',
              'ms': 'Tidak',
              'vi': 'Không',
              'ru': 'Нет',
            });
    }

    final text = value?.toString() ?? '';

    if (key == 'tense') {
      return morphologyGroupLabel(text);
    }
    if (key == 'number') {
      return morphologyGroupLabel(
        text == 'sg'
            ? 'singular'
            : text == 'pl'
            ? 'plural'
            : text,
      );
    }
    if (key == 'person' || key == 'possessive') {
      return _personValue(text);
    }
    if (key == 'case') {
      return _caseValue(text);
    }
    if (key == 'form_type') {
      return _formTypeValue(text);
    }
    return text;
  }

  String _personValue(String value) {
    final labels = <String, Map<String, String>>{
      '1sg': {
        'zh': '第一人称单数',
        'en': 'First person singular',
        'ms': 'Orang pertama tunggal',
        'vi': 'Ngôi thứ nhất số ít',
        'ru': 'Первое лицо, единственное число',
      },
      '2sg': {
        'zh': '第二人称单数',
        'en': 'Second person singular',
        'ms': 'Orang kedua tunggal',
        'vi': 'Ngôi thứ hai số ít',
        'ru': 'Второе лицо, единственное число',
      },
      '2sg_polite': {
        'zh': '第二人称单数敬称',
        'en': 'Second person singular polite',
        'ms': 'Orang kedua tunggal sopan',
        'vi': 'Ngôi thứ hai số ít lịch sự',
        'ru': 'Второе лицо, единственное число, вежливое',
      },
      '3sg': {
        'zh': '第三人称单数',
        'en': 'Third person singular',
        'ms': 'Orang ketiga tunggal',
        'vi': 'Ngôi thứ ba số ít',
        'ru': 'Третье лицо, единственное число',
      },
      '1pl': {
        'zh': '第一人称复数',
        'en': 'First person plural',
        'ms': 'Orang pertama jamak',
        'vi': 'Ngôi thứ nhất số nhiều',
        'ru': 'Первое лицо, множественное число',
      },
      '2pl': {
        'zh': '第二人称复数',
        'en': 'Second person plural',
        'ms': 'Orang kedua jamak',
        'vi': 'Ngôi thứ hai số nhiều',
        'ru': 'Второе лицо, множественное число',
      },
      '2pl_polite': {
        'zh': '第二人称复数敬称',
        'en': 'Second person plural polite',
        'ms': 'Orang kedua jamak sopan',
        'vi': 'Ngôi thứ hai số nhiều lịch sự',
        'ru': 'Второе лицо, множественное число, вежливое',
      },
      '3pl': {
        'zh': '第三人称复数',
        'en': 'Third person plural',
        'ms': 'Orang ketiga jamak',
        'vi': 'Ngôi thứ ba số nhiều',
        'ru': 'Третье лицо, множественное число',
      },
    };
    final values = labels[value];
    return values == null ? value : values[languageCode] ?? values['en']!;
  }

  String _caseValue(String value) {
    final labels = <String, Map<String, String>>{
      'nominative': {
        'zh': '主格',
        'en': 'Nominative',
        'ms': 'Kasus nominatif',
        'vi': 'Chủ cách',
        'ru': 'Именительный падеж',
      },
      'genitive': {
        'zh': '领属格',
        'en': 'Genitive',
        'ms': 'Kasus genitif',
        'vi': 'Sở hữu cách',
        'ru': 'Родительный падеж',
      },
      'dative': {
        'zh': '向格',
        'en': 'Dative',
        'ms': 'Kasus datif',
        'vi': 'Tặng cách',
        'ru': 'Дательный падеж',
      },
      'accusative': {
        'zh': '宾格',
        'en': 'Accusative',
        'ms': 'Kasus akusatif',
        'vi': 'Đối cách',
        'ru': 'Винительный падеж',
      },
      'locative': {
        'zh': '位格',
        'en': 'Locative',
        'ms': 'Kasus lokatif',
        'vi': 'Vị cách',
        'ru': 'Местный падеж',
      },
      'ablative': {
        'zh': '从格',
        'en': 'Ablative',
        'ms': 'Kasus ablatif',
        'vi': 'Xuất cách',
        'ru': 'Исходный падеж',
      },
      'instrumental': {
        'zh': '工具格',
        'en': 'Instrumental',
        'ms': 'Kasus instrumental',
        'vi': 'Công cụ cách',
        'ru': 'Творительный падеж',
      },
      'comparative': {
        'zh': '比较格',
        'en': 'Comparative',
        'ms': 'Kasus perbandingan',
        'vi': 'So sánh cách',
        'ru': 'Сравнительная форма',
      },
      'caritive': {
        'zh': '缺失格',
        'en': 'Caritive',
        'ms': 'Kasus karitif',
        'vi': 'Khuyết cách',
        'ru': 'Каритив',
      },
      'locative_modifier': {
        'zh': '位格修饰形',
        'en': 'Locative modifier',
        'ms': 'Pengubah lokatif',
        'vi': 'Dạng bổ nghĩa vị cách',
        'ru': 'Локативная определительная форма',
      },
    };
    final values = labels[value];
    return values == null ? value : values[languageCode] ?? values['en']!;
  }

  String _formTypeValue(String value) {
    final labels = <String, Map<String, String>>{
      'finite': {
        'zh': '限定动词',
        'en': 'Finite verb',
        'ms': 'Kata kerja finit',
        'vi': 'Động từ hữu hạn',
        'ru': 'Личная форма глагола',
      },
      'infinitive': {
        'zh': '不定式',
        'en': 'Infinitive',
        'ms': 'Infinitif',
        'vi': 'Động từ nguyên mẫu',
        'ru': 'Инфинитив',
      },
      'stem': {
        'zh': '词干',
        'en': 'Stem',
        'ms': 'Pangkal kata',
        'vi': 'Thân từ',
        'ru': 'Основа',
      },
      'converb_p': {
        'zh': '副动词',
        'en': 'Converb',
        'ms': 'Konverb',
        'vi': 'Phó động từ',
        'ru': 'Деепричастная форма',
      },
      'imperative': {
        'zh': '祈使式',
        'en': 'Imperative',
        'ms': 'Imperatif',
        'vi': 'Mệnh lệnh thức',
        'ru': 'Повелительное наклонение',
      },
    };
    final values = labels[value];
    return values == null ? value : values[languageCode] ?? values['en']!;
  }

  String languageName(String code) {
    switch (code) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      case 'ms':
        return 'Bahasa Melayu';
      case 'vi':
        return 'Tiếng Việt';
      case 'ru':
        return 'Русский';
      default:
        return code;
    }
  }
}
