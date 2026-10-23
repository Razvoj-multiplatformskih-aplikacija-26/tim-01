import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewTitle', () {
    test('accepts both boundaries', () {
      expect(ReviewTitle.parse('a' * 5).valueOrNull?.length, 5);
      expect(ReviewTitle.parse('a' * 80).valueOrNull?.length, 80);
    });

    test('rejects text outside the boundaries', () {
      expect(ReviewTitle.parse('a' * 4).errorOrNull, isA<ReviewTitleTooShort>());
      expect(ReviewTitle.parse('a' * 81).errorOrNull, isA<ReviewTitleTooLong>());
    });
  });

  group('ReviewBody', () {
    test('counts one emoji family as one character', () {
      final text = '👨‍👩‍👧' * 30;
      expect(ReviewBody.parse(text).valueOrNull?.length, 30);
    });
  });

  test('RatingValue accepts only one through five', () {
    expect(RatingValue.fromInt(1).isSuccess, isTrue);
    expect(RatingValue.fromInt(5).isSuccess, isTrue);
    expect(RatingValue.fromInt(0).errorOrNull, const RatingOutOfRange(0));
    expect(RatingValue.fromInt(6).errorOrNull, const RatingOutOfRange(6));
  });
}
