import 'package:domain/domain.dart';

List<Review> createBackofficeDemoReviews() {
  final now = DateTime.utc(2026, 10, 18, 12);
  final titles = <String>[
    'Brzo stilizovanje bez prejake toplote',
    'Prijatniji je za svakodnevno sušenje',
    'Osvetljenje stvarno pomaže pri čišćenju',
    'Snažan, ali teži za duži rad',
    'Dobar izbor za veliku dnevnu sobu',
    'Praktičan za kuhinju i hodnik',
    'Potrebno je malo vežbe sa nastavcima',
    'Baterija je dovoljna za manji stan',
    'Nastavci se lako postavljaju i skidaju',
    'Praćenje kvaliteta vazduha je korisno',
  ];
  final statuses = <ReviewStatus>[
    ReviewPending(submittedAt: now.subtract(const Duration(hours: 1))),
    ReviewPending(submittedAt: now.subtract(const Duration(hours: 2))),
    ReviewPublished(publishedAt: now.subtract(const Duration(days: 2))),
    ReviewPublished(publishedAt: now.subtract(const Duration(days: 4))),
    ReviewHidden(hiddenAt: now.subtract(const Duration(hours: 4)), uniqueReportCount: 3),
    ReviewHidden(hiddenAt: now.subtract(const Duration(hours: 8)), uniqueReportCount: 4),
    ReviewRejected(rejectedAt: now.subtract(const Duration(days: 1)), reason: 'Sadržaj se ponavlja.'),
    ReviewRejected(rejectedAt: now.subtract(const Duration(days: 3)), reason: 'Potrebna je provera navoda.'),
    ReviewArchived(archivedAt: now.subtract(const Duration(days: 15))),
    ReviewArchived(archivedAt: now.subtract(const Duration(days: 25))),
  ];
  final devices = <String>['airwrap-id', 'supersonic-nural', 'v15-detect', 'gen5detect', 'purifier-big-quiet'];

  return [
    for (var index = 0; index < titles.length; index++)
      Review(
        id: ReviewId('review-${index + 1}'),
        deviceId: DeviceId(devices[index % devices.length]),
        authorId: UserId('user-${index + 1}'),
        title: ReviewTitle.parse(titles[index]).valueOrNull!,
        body: ReviewBody.parse(
          'Ovo je demo recenzija broj ${index + 1}. Sadrži dovoljno detalja da urednik proceni iskustvo korisnika.',
        ).valueOrNull!,
        rating: RatingValue.fromInt((index % 5) + 1).valueOrNull!,
        status: statuses[index],
        submittedAt: now.subtract(Duration(hours: index + 1)),
        reportedBy: statuses[index] is ReviewHidden
            ? const {UserId('reporter-1'), UserId('reporter-2'), UserId('reporter-3')}
            : const {},
      ),
  ];
}
