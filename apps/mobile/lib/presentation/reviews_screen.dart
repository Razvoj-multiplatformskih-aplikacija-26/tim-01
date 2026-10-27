import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app_text.dart';
import 'review_card.dart';

final class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recenzije'),
        actions: [
          IconButton(
            tooltip: 'Izazovi grešku sledećeg zahteva',
            onPressed: () => context.read<ReviewBloc>().add(const ReviewFailureDemoRequested()),
            icon: const Icon(Icons.bug_report_outlined),
          ),
          IconButton(
            tooltip: 'Osveži',
            onPressed: () => context.read<ReviewBloc>().add(const ReviewsRequested()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<ReviewBloc, ReviewState>(
        listener: (context, state) {
          String? message;
          if (state is ReviewsReady) {
            if (state.actionError != null) {
              message = domainErrorMessage(state.actionError!);
            } else if (state.lastAction != null) {
              message = reviewActionMessage(state.lastAction!);
            }
          } else if (state is ReviewActionFailure) {
            message = domainErrorMessage(state.error);
          }
          if (message == null) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) => switch (state) {
          ReviewInitial() || ReviewsLoading() => const Center(child: CircularProgressIndicator()),
          ReviewsFailure() => _FailureView(onRetry: () => context.read<ReviewBloc>().add(const ReviewsRequested())),
          ReviewsEmpty() => const Center(child: Text('Još nema recenzija.')),
          ReviewActionFailure() => _FailureView(
            onRetry: () => context.read<ReviewBloc>().add(const ReviewsRequested()),
          ),
          ReviewsReady(:final reviews) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('Demo sadrži najmanje deset zapisa i svako stanje recenzije.'),
                );
              }
              final review = reviews[index - 1];
              return ReviewCard(
                key: ValueKey(review.id.value),
                review: review,
                onTap: () => context.push('/reviews/${review.id.value}'),
              );
            },
          ),
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reviews/new'),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Nova recenzija'),
      ),
    );
  }
}

final class _FailureView extends StatelessWidget {
  const _FailureView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('Podaci trenutno ne mogu da se učitaju.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Pokušaj ponovo')),
          ],
        ),
      ),
    );
  }
}
