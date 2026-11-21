import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app_text.dart';

final class ReviewDetailScreen extends StatelessWidget {
  const ReviewDetailScreen({required this.reviewId, super.key});

  final String reviewId;

  @override
  Widget build(BuildContext context) {
    final viewer = context.watch<ReviewViewer>();
    final bloc = context.read<ReviewBloc>();
    return Scaffold(
      appBar: AppBar(title: const Text('Detalj recenzije')),
      body: BlocBuilder<ReviewBloc, ReviewState>(
        builder: (context, state) {
          if (state is ReviewInitial || state is ReviewsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReviewsFailure || state is ReviewActionFailure) {
            final error = state.actionError ?? (state is ReviewsFailure ? state.loadError : null);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(domainErrorMessage(error ?? const ServerUnavailable())),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => bloc.add(const ReviewsRequested()),
                    child: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            );
          }
          if (state is! ReviewsReady) return const Center(child: Text('Recenzija više nije dostupna.'));
          final review = _findReview(state.reviews, ReviewId(reviewId));
          if (review == null) {
            return Center(
              child: Text(
                state.lastAction == ReviewAction.reported
                    ? 'Prijava je zabeležena. Recenzija više nije javno dostupna.'
                    : 'Recenzija više nije dostupna.',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(review.title.value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Status: ${reviewStatusLabel(review.status)}'),
              Text('Ocena: ${review.rating.value}/5'),
              const Divider(height: 32),
              Text(review.body.value, style: Theme.of(context).textTheme.bodyLarge),
              if (review.status case ReviewHidden(:final uniqueReportCount)) ...[
                const SizedBox(height: 20),
                Text('Recenzija je privremeno sakrivena posle $uniqueReportCount različite prijave.'),
              ],
              if (canReportReview(review, viewer.id, viewer.role)) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _confirmReport(context, review.id, viewer.id!),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Prijavi sadržaj'),
                ),
              ],
              if (bloc.canEditReviews && canEditOwnPendingReview(review, viewer.id, viewer.role)) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.push('/reviews/${review.id.value}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Izmeni recenziju'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmReport(BuildContext context, ReviewId id, UserId reporterId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: const Text('Prijaviti recenziju?'),
        content: const Text('Urednik će proveriti sadržaj prijave.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Prijavi')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<ReviewBloc>().add(ReviewReported(id: id, reporterId: reporterId));
  }

  Review? _findReview(List<Review> reviews, ReviewId id) {
    for (final review in reviews) {
      if (review.id == id) return review;
    }
    return null;
  }
}
