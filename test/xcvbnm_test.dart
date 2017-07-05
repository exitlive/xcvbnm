library xcvbnm.xcvbnm_test;

import 'package:test/test.dart';
import 'package:xcvbnm/xcvbnm.dart';
import 'package:xcvbnm/src/feedback.dart';

void main() {
  var xcvbnm = new Xcvbnm();

  group('xcvbnm', () {
    test('test foo', () async {
      var result = xcvbnm.estimate('foo');
      expect(result, isNotNull);
    });
    test('test passwords', () async {
      // Just validate this again some sample passwords
      var testPasswords = [
        r'zxcvbn',
        r'qwER43@!',
        r'Tr0ub4dour&3',
        r'correcthorsebatterystaple',
        r'coRrecth0rseba++ery9.23.2007staple$',
        r'D0g..................',
        r'abcdefghijk987654321',
        r'neverforget13/3/1997',
        r'1qaz2wsx3edc',
        r'temppass22',
        r'briansmith',
        r'briansmith4mayor',
        r'password1',
        r'viking',
        r'thx1138',
        r'ScoRpi0ns',
        r'do you know',
        r'ryanhunter2000',
        r'rianhunter2000',
        r'asdfghju7654rewq',
        r'AOEUIDHG&*()LS_',
        r'12345678',
        r'defghi6789',
        r'rosebud',
        r'Rosebud',
        r'ROSEBUD',
        r'rosebuD',
        r'ros3bud99',
        r'r0s3bud99',
        r'R0$38uD99',
        r'verlineVANDERMARK',
        r'eheuczkqyq',
        r'rWibMFACxAUGZmxhVncy',
        r'Ba9ZyWABu99[BK#6MBgbH88Tofv)vs$w',
      ];

      for (String password in testPasswords) {
        var result = xcvbnm.estimate(password);
        expect(result, isNotNull);
      }
    });
  });
  group('feedback', () {
    test('general suggestion', () async {
      var result = xcvbnm.estimate('foo');
      expect(result.feedback, Feedback.generalSuggestion);
    });
    test('spatial single turn', () async {
      var result = xcvbnm.estimate('qwertyuiop[');
      expect(result.feedback, Feedback.spatialSingleTurnSuggestion);
    });
    test('spatial multi turn', () async {
      var result = xcvbnm.estimate('asdfgfdsa');
      expect(result.feedback, Feedback.spatialMultiTurnSuggestion);
    });
    test('repeating single char', () async {
      var result = xcvbnm.estimate('aaaa');
      expect(result.feedback, Feedback.repeatSingleCharSuggestion);
    });
    test('repeating muli char', () async {
      var result = xcvbnm.estimate('abuabuabu');
      expect(result.feedback, Feedback.repeatMultiCharSuggestion);
    });
    test('sequence', () async {
      var result = xcvbnm.estimate('8765432');
      expect(result.feedback, Feedback.sequenceSuggestion);
    });
    test('recent year', () async {
      var year = new DateTime.now().year;
      var result = xcvbnm.estimate('itIs$year');
      expect(result.feedback, Feedback.recentYearSuggestion);
    });
    test('date', () async {
      var result = xcvbnm.estimate('4101980');
      expect(result.feedback, Feedback.dateSuggestion);
    });
    test('top10', () async {
      var result = xcvbnm.estimate('password');
      expect(result.feedback, Feedback.top10PasswordSuggestion);
    });
    test('top100', () async {
      var result = xcvbnm.estimate('love');
      expect(result.feedback, Feedback.top100PasswordSuggestion);
    });
    test('common', () async {
      var result = xcvbnm.estimate('zxcvbnm');
      expect(result.feedback, Feedback.commonPasswordSuggestion);
    });
    test('english', () async {
      var result = xcvbnm.estimate('procrastination');
      expect(result.feedback, Feedback.englishWordSuggestion);
    });
    test('name', () async {
      var result = xcvbnm.estimate('DonaldDrumpf');
      expect(result.feedback, Feedback.nameSuggestion);
    });
  });
}
