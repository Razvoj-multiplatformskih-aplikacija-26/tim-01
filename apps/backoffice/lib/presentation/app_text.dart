import 'package:domain/domain.dart';

String domainErrorMessage(DomainError error) => switch (error) {
  ReviewTitleTooShort() || ReviewTitleTooLong() => 'Naslov recenzije nije ispravan.',
  ReviewBodyTooShort() || ReviewBodyTooLong() => 'Tekst recenzije nije ispravan.',
  RatingOutOfRange() => 'Ocena mora biti od 1 do 5.',
  InvalidReviewTransition() => 'Ova promena stanja nije dozvoljena.',
  ReviewAlreadyReported() => 'Korisnik je već prijavio recenziju.',
  CannotReportOwnReview() => 'Autor ne može prijaviti svoju recenziju.',
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
