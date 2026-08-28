import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/word_entry.dart';
import 'package:flutter_application_1/screens/word_detail_screen.dart';

void main() {
  testWidgets(
    'canonical detail renders senses and every morphology analysis',
    (WidgetTester tester) async {
      const entry = WordEntry(
        word: 'алуу',
        meanings: '拿 / 得到 / 买',
        type: 'verb',
        tableName: 'canonical_verb_table',
        details: {},
        lexemeId: 'verb:алуу',
        languageCode: 'ky',
        primaryMatch: 'form',
        matchTypes: ['form'],
        senses: [
          DictionarySense(
            number: 1,
            glosses: ['拿'],
          ),
          DictionarySense(
            number: 2,
            glosses: ['得到'],
          ),
          DictionarySense(
            number: 3,
            glosses: ['买'],
          ),
        ],
        matchedForms: [
          MorphologyAnalysis(
            form: 'алдым',
            canonicalKey: 'past_men',
            partOfSpeech: 'verb',
            features: {
              'form_type': 'finite',
              'tense': 'past',
              'person': '1sg',
              'negative': false,
            },
          ),
          MorphologyAnalysis(
            form: 'алдым',
            canonicalKey: 'alternate_analysis',
            partOfSpeech: 'verb',
            features: {
              'form_type': 'finite',
              'tense': 'past',
              'person': '1sg',
              'negative': false,
            },
          ),
        ],
        formCount: 46,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: WordDetailScreen(
            languageCode: 'ky',
            entry: entry,
          ),
        ),
      );

      expect(find.text('алуу'), findsWidgets);
      expect(find.text('义项 1'), findsOneWidget);
      expect(find.text('拿'), findsWidgets);
      expect(find.text('past_men'), findsOneWidget);
      expect(
        find.text('alternate_analysis'),
        findsOneWidget,
      );
      expect(find.text('过去时'), findsWidgets);
      expect(
        find.text('第一人称单数'),
        findsWidgets,
      );
    },
  );
}
