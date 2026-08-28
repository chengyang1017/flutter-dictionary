import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';

import '../data/dictionary_database.dart';
import '../models/word_entry.dart';
import 'word_detail_screen.dart';

class WordListScreen extends StatefulWidget {
  final LanguageConfig language;
  final LanguageVariantConfig? variant;

  const WordListScreen({
    super.key,
    required this.language,
    this.variant,
  });

  @override
  State<WordListScreen> createState() =>
      _WordListScreenState();
}

class _WordListScreenState
    extends State<WordListScreen> {
  final DictionaryDatabase _database =
      DictionaryDatabase();

  Timer? _searchTimer;

  List<WordEntry> _entries = const [];
  bool _isLoading = true;
  String? _error;
  String _keyword = '';
  String? _uiLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final uiLanguage =
        Localizations.localeOf(context)
            .languageCode;

    if (_uiLanguageCode != uiLanguage) {
      _uiLanguageCode = uiLanguage;
      _loadEntries();
    }
  }

  @override
  void didUpdateWidget(
    covariant WordListScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.language.code !=
        widget.language.code) {
      _loadEntries();
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _database.closeAll();
    super.dispose();
  }

  Future<void> _loadEntries({
    String? keyword,
  }) async {
    if (keyword != null) {
      _keyword = keyword;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries =
          await _database.getWords(
        languageCode:
            widget.language.code,
        queryLanguage:
            _uiLanguageCode ?? 'zh',
        keyword: _keyword,
        glossLanguage:
            _uiLanguageCode ?? 'zh',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _keyword = value;
    _searchTimer?.cancel();

    _searchTimer = Timer(
      const Duration(milliseconds: 300),
      () {
        _loadEntries();
      },
    );
  }

  Future<void> _openEntry(
    WordEntry entry,
  ) async {
    var detailEntry = entry;

    if (entry.isCanonical) {
      try {
        final forms =
            await _database.getGeneratedForms(
          languageCode:
              widget.language.code,
          entry: entry,
        );

        detailEntry =
            entry.withAllForms(forms);
      } catch (error) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              '读取词形变化失败：$error',
            ),
          ),
        );

        return;
      }
    }

    if (!mounted) {
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return WordDetailScreen(
            languageCode:
                widget.language.code,
            entry: detailEntry,
          );
        },
      ),
    );
  }

  String _displayName(
    BuildContext context,
  ) {
    final uiCode =
        Localizations.localeOf(context)
            .languageCode;

    return widget.variant?.nameOf(uiCode) ??
        widget.language.nameOf(uiCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_displayName(context)} · 单词',
        ),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        onChanged: _onSearchChanged,
        textInputAction:
            TextInputAction.search,
        decoration: const InputDecoration(
          hintText: '搜索原形、真实词形或释义',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                '加载词条失败\n$_error',
                textAlign:
                    TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadEntries,
                child: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return const Center(
        child: Text('没有找到词条'),
      );
    }

    return ListView.separated(
      itemCount: _entries.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildEntryTile(
          _entries[index],
        );
      },
    );
  }

  Widget _buildEntryTile(
    WordEntry entry,
  ) {
    final subtitleParts = <String>[];

    if (entry.isCanonical) {
      if (_isUseful(entry.type)) {
        subtitleParts.add(
          _partOfSpeechLabel(entry.type),
        );
      }

      if (_isUseful(entry.meanings)) {
        subtitleParts.add(
          entry.meanings,
        );
      }

      final matchLabel =
          _matchLabel(entry.primaryMatch);

      if (matchLabel != null) {
        subtitleParts.add(matchLabel);
      }
    } else {
      if (_isUseful(entry.sheetName)) {
        subtitleParts.add(
          entry.sheetName,
        );
      }

      if (_isUseful(entry.type)) {
        subtitleParts.add(entry.type);
      }

      if (_isUseful(entry.meanings)) {
        subtitleParts.add(
          entry.meanings,
        );
      }
    }

    return ListTile(
      title: Text(
        entry.word.isEmpty
            ? '未命名词条'
            : entry.word,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitleParts.isEmpty
          ? null
          : Text(
              subtitleParts.join(' · '),
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
            ),
      trailing: const Icon(
        Icons.chevron_right,
      ),
      onTap: () => _openEntry(entry),
    );
  }

  String _partOfSpeechLabel(
    String value,
  ) {
    switch (value) {
      case 'noun':
        return '名词';
      case 'verb':
        return '动词';
      default:
        return value;
    }
  }

  String? _matchLabel(
    String? value,
  ) {
    switch (value) {
      case 'lemma':
        return '原形命中';
      case 'form':
        return '词形命中';
      case 'gloss':
        return '释义命中';
      default:
        return null;
    }
  }

  bool _isUseful(String value) {
    final normalized =
        value.trim().toLowerCase();

    return normalized.isNotEmpty &&
        normalized != '未知' &&
        normalized != '未命名' &&
        normalized != 'nan' &&
        normalized != 'null';
  }
}
