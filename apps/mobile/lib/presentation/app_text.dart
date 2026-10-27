import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

String domainErrorMessage(DomainError error) => switch (error) {
  ReviewTitleTooShort(:final minimum) => 'Naslov mora da ima najmanje $minimum znakova.',
  ReviewTitleTooLong(:final maximum) => 'Naslov može da ima najviše $maximum znakova.',
  ReviewBodyTooShort(:final minimum) => 'Recenzija mora da ima najmanje $minimum znakova.',
  ReviewBodyTooLong(:final maximum) => 'Recenzija može da ima najviše $maximum znakova.',
  RatingOutOfRange() => 'Ocena mora biti od 1 do 5.',
  InvalidReviewTransition() => 'Ova promena stanja nije dozvoljena.',
  ReviewAlreadyReported() => 'Već ste prijavili ovu recenziju.',
  CannotReportOwnReview() => 'Ne možete prijaviti svoju recenziju.',
  ReviewActionNotAllowed() => 'Ova radnja trenutno nije dozvoljena.',
  ReviewNotFound() => 'Recenzija više nije dostupna.',
};

String reviewStatusLabel(ReviewStatus status) => switch (status) {
  ReviewPending() => 'Na proveri',
  ReviewPublished() => 'Objavljena',
  ReviewHidden() => 'Privremeno sakrivena',
  ReviewRejected() => 'Odbijena',
  ReviewArchived() => 'Arhivirana',
};

String reviewActionMessage(ReviewAction action) => switch (action) {
  ReviewAction.submitted => 'Recenzija je poslata na proveru.',
  ReviewAction.reported => 'Prijava je zabeležena.',
  ReviewAction.approved => 'Recenzija je objavljena.',
  ReviewAction.rejected => 'Recenzija je odbijena.',
  ReviewAction.republished => 'Recenzija je ponovo objavljena.',
  ReviewAction.archived => 'Recenzija je arhivirana.',
};
