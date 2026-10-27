import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_text.dart';

const currentMobileUser = UserId('mobile-user');

final class ReviewDetailScreen extends StatelessWidget {
  const ReviewDetailScreen({required this.reviewId, super.key});

  final String reviewId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalj recenzije')),
      body: BlocBuilder<ReviewBloc, ReviewState>(
        builder: (context, state) {
          if (state is! ReviewsReady) return const Center(child: CircularProgressIndicator());
          final review = _findReview(state.reviews, ReviewId(reviewId));
          if (review == null) return const Center(child: Text('Recenzija nije pronađena.'));
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
              if (review.status is ReviewPublished && review.authorId != currentMobileUser) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _confirmReport(context, review),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Prijavi sadržaj'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmReport(BuildContext context, Review review) async {
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
    context.read<ReviewBloc>().add(ReviewReported(id: review.id, reporterId: currentMobileUser));
  }

  Review? _findReview(List<Review> reviews, ReviewId id) {
    for (final review in reviews) {
      if (review.id == id) return review;
    }
    return null;
  }
}
