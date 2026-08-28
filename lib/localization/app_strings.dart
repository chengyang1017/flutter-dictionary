import 'package:flutter/material.dart';

class AppStrings {
  final String languageCode;

  const AppStrings._(
    this.languageCode,
  );

  factory AppStrings.of(
    BuildContext context,
  ) {
    return AppStrings.forLanguageCode(
      Localizations.localeOf(context)
          .languageCode,
    );
  }

  factory AppStrings.forLanguageCode(
    String languageCode,
  ) {
    final normalized =
        languageCode
            .trim()
            .toLowerCase()
            .split(RegExp('[-_]'))
            .first;

    return AppStrings._(normalized);
  }

  String _pick(
    Map<String, String> values,
  ) {
    return values[languageCode] ??
        values['en']!;
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

  String languageName(
    String code,
  ) {
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
