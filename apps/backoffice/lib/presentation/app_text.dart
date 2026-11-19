import 'package:domain/domain.dart';

String domainErrorMessage(DomainError error) => switch (error) {
  ReviewTitleTooShort(:final minimum) => 'Naslov mora da ima najmanje $minimum znakova.',
  ReviewTitleTooLong(:final maximum) => 'Naslov može da ima najviše $maximum znakova.',
  ReviewBodyTooShort(:final minimum) => 'Recenzija mora da ima najmanje $minimum znakova.',
  ReviewBodyTooLong(:final maximum) => 'Recenzija može da ima najviše $maximum znakova.',
  RatingOutOfRange(:final minimum, :final maximum) => 'Ocena mora biti od $minimum do $maximum.',
  InvalidReviewTransition() => 'Ova promena stanja nije dozvoljena.',
  ReviewAlreadyReported() => 'Već ste prijavili ovu recenziju.',
  CannotReportOwnReview() => 'Ne možete prijaviti svoju recenziju.',
  ReviewActionNotAllowed() => 'Ova radnja trenutno nije dozvoljena.',
  ReviewNotFound() => 'Recenzija više nije dostupna.',
  ForbiddenReviewAction() => 'Nemate pravo da izvršite ovu radnju.',
  SessionExpired() => 'Prijava je istekla. Prijavite se ponovo.',
  ServerUnavailable() => 'Server trenutno nije dostupan. Pokušajte ponovo.',
  UnknownServerError() => 'Došlo je do greške. Pokušajte ponovo.',
};

String reviewStatusLabel(ReviewStatus status) => switch (status) {
  ReviewPending() => 'Na proveri',
  ReviewPublished() => 'Objavljena',
  ReviewHidden() => 'Privremeno sakrivena',
  ReviewRejected() => 'Odbijena',
  ReviewArchived() => 'Arhivirana',
};
