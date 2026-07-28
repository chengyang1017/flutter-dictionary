import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/lang_schema_service.dart';
import '../models/lang_schema.dart';
import '../models/word_entry.dart';

class WordDetailScreen
    extends StatelessWidget {
  final String languageCode;
  final WordEntry entry;

  const WordDetailScreen({
    super.key,
    required this.languageCode,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          entry.word.isEmpty
              ? '词条详情'
              : entry.word,
        ),
      ),
      body: FutureBuilder<
          DictionaryTypeSchema?>(
        future: LangSchemaService.instance
            .getTypeSchema(
          languageCode: languageCode,
          tableName: entry.tableName,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _buildError(
              snapshot.error,
            );
          }

          return _buildBody(
            context,
            snapshot.data,
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DictionaryTypeSchema? schema,
  ) {
    final visibleSections =
        _visibleSections(schema);

    final usedKeys = <String>{
      for (final section in visibleSections)
        ...section.keys,
    };

    final extraKeys = entry.details.keys
        .where(
          (key) =>
              !usedKeys.contains(key) &&
              _hasValue(
                entry.details[key],
              ),
        )
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        if (visibleSections.isEmpty)
          _buildFallbackSection(context)
        else
          ...visibleSections.map(
            (section) =>
                _buildSchemaSection(
              context,
              section,
            ),
          ),
        if (extraKeys.isNotEmpty)
          _buildValuesSection(
            context,
            title: '其他信息',
            keys: extraKeys,
          ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
  ) {
    final meta = <String>[
      if (_isUseful(entry.sheetName))
        entry.sheetName,
      if (_isUseful(entry.type))
        entry.type,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            entry.word.isEmpty
                ? '未命名词条'
                : entry.word,
            style: Theme.of(context)
                .textTheme
                .headlineMedium,
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(meta.join(' · ')),
          ],
          if (_isUseful(
            entry.meanings,
          )) ...[
            const SizedBox(height: 14),
            Text(
              entry.meanings,
              style: const TextStyle(
                fontSize: 17,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<DictionarySectionSchema>
      _visibleSections(
    DictionaryTypeSchema? schema,
  ) {
    if (schema == null) {
      return const [];
    }

    return schema.sections
        .where(
          (section) =>
              section.keys.any(
            (key) => _hasValue(
              entry.details[key],
            ),
          ),
        )
        .toList(growable: false);
  }

  Widget _buildSchemaSection(
    BuildContext context,
    DictionarySectionSchema section,
  ) {
    return _buildValuesSection(
      context,
      title: section.title ??
          entry.sheetName,
      keys: section.keys,
    );
  }

  Widget _buildFallbackSection(
    BuildContext context,
  ) {
    final keys = entry.details.keys
        .where(
          (key) => _hasValue(
            entry.details[key],
          ),
        )
        .toList(growable: false);

    if (keys.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '这个词条没有可显示的详细字段',
          ),
        ),
      );
    }

    return _buildValuesSection(
      context,
      title: entry.sheetName.isEmpty
          ? '详细信息'
          : entry.sheetName,
      keys: keys,
    );
  }

  Widget _buildValuesSection(
    BuildContext context, {
    required String title,
    required List<String> keys,
  }) {
    final visibleKeys = keys
        .where(
          (key) => _hasValue(
            entry.details[key],
          ),
        )
        .toList(growable: false);

    if (visibleKeys.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant,
          ),
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 12),
            ...visibleKeys.map(
              (key) => _buildValueRow(
                context,
                key,
                entry.details[key],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueRow(
    BuildContext context,
    String key,
    dynamic value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: Theme.of(context)
                .textTheme
                .labelLarge,
          ),
          const SizedBox(height: 4),
          SelectableText(
            _displayValue(value),
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '读取语言 Schema 失败\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  bool _hasValue(dynamic value) {
    if (value == null) {
      return false;
    }

    if (value is String) {
      final text =
          value.trim().toLowerCase();

      return text.isNotEmpty &&
          text != 'nan' &&
          text != 'null';
    }

    if (value is Iterable) {
      return value.isNotEmpty;
    }

    if (value is Map) {
      return value.isNotEmpty;
    }

    return true;
  }

  String _displayValue(dynamic value) {
    if (value is Map || value is List) {
      return const JsonEncoder.withIndent(
        '  ',
      ).convert(value);
    }

    return value.toString();
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
