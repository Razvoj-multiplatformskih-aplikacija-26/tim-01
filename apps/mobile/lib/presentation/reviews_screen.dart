import 'package:blocs/blocs.dart';
import 'package:client_ui/client_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app_text.dart';
import 'review_card.dart';

final class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewer = context.watch<ReviewViewer>();
    final bloc = context.read<ReviewBloc>();
    final demo = bloc.canSimulateFailure;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recenzije'),
        actions: [
          if (demo)
            IconButton(
              tooltip: 'Izazovi grešku sledećeg zahteva',
              onPressed: () => bloc.add(const ReviewFailureDemoRequested()),
              icon: const Icon(Icons.bug_report_outlined),
            ),
          IconButton(
            tooltip: 'Osveži',
            onPressed: () => bloc.add(const ReviewsRequested()),
            icon: const Icon(Icons.refresh),
          ),
          const SessionMenuButton(),
        ],
      ),
      body: BlocConsumer<ReviewBloc, ReviewState>(
        listener: (context, state) {
          final message = switch ((state.actionError, state.lastAction)) {
            (final error?, _) => domainErrorMessage(error),
            (_, final action?) => reviewActionMessage(action),
            _ => null,
          };
          if (message == null) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) => switch (state) {
          ReviewInitial() || ReviewsLoading() => const Center(child: CircularProgressIndicator()),
          ReviewsFailure(:final loadError) => _FailureView(
            onRetry: () => bloc.add(const ReviewsRequested()),
            message: loadError == null ? null : domainErrorMessage(loadError),
          ),
          ReviewsEmpty() => const Center(child: Text('Još nema recenzija.')),
          ReviewActionFailure() => _FailureView(onRetry: () => bloc.add(const ReviewsRequested())),
          ReviewsReady(:final reviews) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length + (demo ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (demo && index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('Demo sadrži najmanje deset zapisa i svako stanje recenzije.'),
                );
              }
              final review = reviews[demo ? index - 1 : index];
              return ReviewCard(
                key: ValueKey(review.id.value),
                review: review,
                onTap: () => context.push('/reviews/${review.id.value}'),
              );
            },
          ),
        },
      ),
      floatingActionButton: viewer.id != null && canSubmitReview(viewer.role)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/reviews/new'),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Nova recenzija'),
            )
          : null,
    );
  }
}

final class _FailureView extends StatelessWidget {
  const _FailureView({required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

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
            Text(message ?? 'Podaci trenutno ne mogu da se učitaju.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Pokušaj ponovo')),
          ],
        ),
      ),
    );
  }
}
