import 'package:characters/characters.dart';
import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class ReviewTitle {
  const ReviewTitle._(this.value);

  static const minimumLength = 5;
  static const maximumLength = 80;

  final String value;

  int get length => value.characters.length;

  static Result<ReviewTitle> parse(String input) {
    final value = input.trim();
    final length = value.characters.length;
    if (length < minimumLength) {
      return Failure(ReviewTitleTooShort(length: length, minimum: minimumLength));
    }
    if (length > maximumLength) {
      return Failure(ReviewTitleTooLong(length: length, maximum: maximumLength));
    }
    return Success(ReviewTitle._(value));
  }

  @override
  bool operator ==(Object other) => other is ReviewTitle && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

@immutable
final class ReviewBody {
  const ReviewBody._(this.value);

  static const minimumLength = 30;
  static const maximumLength = 1000;

  final String value;

  int get length => value.characters.length;

  static Result<ReviewBody> parse(String input) {
    final value = input.trim();
    final length = value.characters.length;
    if (length < minimumLength) {
      return Failure(ReviewBodyTooShort(length: length, minimum: minimumLength));
    }
    if (length > maximumLength) {
      return Failure(ReviewBodyTooLong(length: length, maximum: maximumLength));
    }
    return Success(ReviewBody._(value));
  }

  @override
  bool operator ==(Object other) => other is ReviewBody && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

@immutable
final class RatingValue {
  const RatingValue._(this.value);

  static const minimum = 1;
  static const maximum = 5;

  final int value;

  static Result<RatingValue> fromInt(int input) {
    if (input < minimum || input > maximum) return Failure(RatingOutOfRange(input));
    return Success(RatingValue._(input));
  }

  @override
  bool operator ==(Object other) => other is RatingValue && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
