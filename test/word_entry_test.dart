import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/word_entry.dart';

void main() {
  group('WordEntry legacy compatibility', () {
    test('still parses the legacy word table shape', () {
      final entry = WordEntry.fromMap(
        {
          'word': 'дом',
          'meanings': '房子',
          'type': '名词',
          'data': '{"性":"阳性"}',
        },
        tableName: 'ru_名词_table',
      );

      expect(entry.isCanonical, isFalse);
      expect(entry.word, 'дом');
      expect(entry.sheetName, '名词');
      expect(entry.details['性'], '阳性');
    });
  });

  group('WordEntry canonical model', () {
    test('preserves senses, matches, and morphology features', () {
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
        ],
        formCount: 46,
      );

      expect(entry.isCanonical, isTrue);
      expect(entry.lexemeId, 'verb:алуу');
      expect(entry.senses, hasLength(3));
      expect(entry.matchedForms, hasLength(1));
      expect(
        entry.matchedForms.single.features['negative'],
        isFalse,
      );
      expect(entry.formCount, 46);
    });

    test('canonical factory creates presentation data', () {
      final entry = WordEntry.canonical(
        lexemeId: 'noun:китеп',
        languageCode: 'ky',
        lemma: 'китеп',
        partOfSpeech: 'noun',
        meanings: '书',
        senses: const [
          DictionarySense(
            number: 1,
            glosses: ['书'],
          ),
        ],
        matchedForms: const [
          MorphologyAnalysis(
            form: 'китепте',
            canonicalKey: 'singular_locative',
            partOfSpeech: 'noun',
            features: {
              'number': 'sg',
              'possessive': null,
              'case': 'locative',
              'interrogative': false,
              'special': false,
            },
          ),
        ],
        formCount: 417,
        primaryMatch: 'form',
        matchTypes: const ['form'],
      );

      expect(entry.isCanonical, isTrue);
      expect(entry.sheetName, 'noun');
      expect(entry.word, 'китеп');
      expect(entry.meanings, '书');
      expect(
        entry.matchedForms.single.features['case'],
        'locative',
      );
      expect(
        entry.matchedForms.single.features['possessive'],
        isNull,
      );
    });

    test('detail copy can hold the complete morphology paradigm', () {
      const entry = WordEntry(
        word: 'айтуу',
        meanings: '说 / 告诉',
        type: 'verb',
        tableName: 'canonical_verb_table',
        details: {},
        lexemeId: 'verb:айтуу',
        languageCode: 'ky',
        senses: [],
        matchedForms: [],
        formCount: 46,
      );

      final detailEntry = entry.withMorphologyForms(
        const [
          MorphologyAnalysis(
            form: 'айтуу',
            canonicalKey: 'infinitive',
            partOfSpeech: 'verb',
            features: {
              'form_type': 'infinitive',
              'tense': null,
              'person': null,
              'negative': false,
            },
          ),
          MorphologyAnalysis(
            form: 'айттым',
            canonicalKey: 'past_men',
            partOfSpeech: 'verb',
            features: {
              'form_type': 'finite',
              'tense': 'past',
              'person': '1sg',
              'negative': false,
            },
          ),
        ],
      );

      expect(detailEntry.matchedForms, hasLength(2));
      expect(
        detailEntry.matchedForms.last.canonicalKey,
        'past_men',
      );
      expect(detailEntry.formCount, 46);
      expect(detailEntry.lexemeId, entry.lexemeId);
    });
  });
}
