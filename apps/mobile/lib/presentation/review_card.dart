import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'app_text.dart';

final class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.review, required this.onTap, super.key});

  final Review review;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(review.title.value, style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(width: 8),
                  _StatusLabel(status: review.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('★' * review.rating.value, semanticsLabel: 'Ocena ${review.rating.value} od 5'),
              const SizedBox(height: 8),
              Text(review.body.value, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final ReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (status) {
      ReviewPending() => colors.tertiaryContainer,
      ReviewPublished() => colors.primaryContainer,
      ReviewHidden() => colors.errorContainer,
      ReviewRejected() => colors.errorContainer,
      ReviewArchived() => colors.surfaceContainerHighest,
    };
    return Semantics(
      label: 'Status: ${reviewStatusLabel(status)}',
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(reviewStatusLabel(status), style: Theme.of(context).textTheme.labelMedium),
        ),
      ),
    );
  }
}
