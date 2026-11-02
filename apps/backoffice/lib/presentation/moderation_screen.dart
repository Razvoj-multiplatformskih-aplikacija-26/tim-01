import 'dart:async';

import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_text.dart';

enum _StatusFilter { all, pending, published, hidden, rejected, archived }

final class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

final class _ModerationScreenState extends State<ModerationScreen> {
  var _query = '';
  var _filter = _StatusFilter.all;
  ReviewId? _selectedId;
  var _hasKeyboardFocus = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderacija recenzija'),
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
          DomainError? error;
          if (state is ReviewsReady) {
            error = state.actionError;
          } else if (state is ReviewActionFailure) {
            error = state.error;
          }
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(domainErrorMessage(error))));
          }
        },
        builder: (context, state) => switch (state) {
          ReviewInitial() || ReviewsLoading() => const Center(child: CircularProgressIndicator()),
          ReviewsFailure() => _FailureView(onRetry: () => context.read<ReviewBloc>().add(const ReviewsRequested())),
          ReviewsEmpty() => const Center(child: Text('Nema recenzija za obradu.')),
          ReviewActionFailure() => _FailureView(
            onRetry: () => context.read<ReviewBloc>().add(const ReviewsRequested()),
          ),
          ReviewsReady(:final reviews) => _buildReady(context, reviews),
        },
      ),
    );
  }

  Widget _buildReady(BuildContext context, List<Review> reviews) {
    final visible = _filterReviews(reviews);
    final selected = _selectedReview(visible);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Pretraži recenzije'),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              DropdownButton<_StatusFilter>(
                value: _filter,
                onChanged: (value) {
                  if (value != null) setState(() => _filter = value);
                },
                items: [
                  for (final filter in _StatusFilter.values)
                    DropdownMenuItem(value: filter, child: Text(_filterLabel(filter))),
                ],
              ),
              const Text('Prečice: ↑/↓ izbor, Ctrl+A odobri, Ctrl+R odbij'),
            ],
          ),
        ),
        Expanded(
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowDown): () => _moveSelection(context, 1),
              const SingleActivator(LogicalKeyboardKey.arrowUp): () => _moveSelection(context, -1),
              const SingleActivator(LogicalKeyboardKey.keyA, control: true): () => _approveSelected(context),
              const SingleActivator(LogicalKeyboardKey.keyR, control: true): () => unawaited(_rejectSelected(context)),
            },
            child: Focus(
              autofocus: true,
              onFocusChange: (value) => setState(() => _hasKeyboardFocus = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _hasKeyboardFocus ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 900) return _wideLayout(context, visible, selected);
                    return _narrowLayout(context, visible, selected);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wideLayout(BuildContext context, List<Review> reviews, Review? selected) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: reviews.isEmpty
                ? const Center(child: Text('Nema rezultata za izabrani filter.'))
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Naslov')),
                          DataColumn(label: Text('Uređaj')),
                          DataColumn(label: Text('Ocena')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: [
                          for (final review in reviews)
                            DataRow(
                              selected: review.id == selected?.id,
                              onSelectChanged: (_) => setState(() => _selectedId = review.id),
                              cells: [
                                DataCell(SizedBox(width: 260, child: Text(review.title.value))),
                                DataCell(Text(review.deviceId.value)),
                                DataCell(Text('${review.rating.value}/5')),
                                DataCell(Text(reviewStatusLabel(review.status))),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          const VerticalDivider(width: 1),
          SizedBox(
            width: 380,
            child: _DetailPanel(review: selected, actions: _actionsFor(context, selected)),
          ),
        ],
      ),
    );
  }

  Widget _narrowLayout(BuildContext context, List<Review> reviews, Review? selected) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: reviews.isEmpty
                ? const Center(child: Text('Nema rezultata za izabrani filter.'))
                : ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return ListTile(
                        selected: review.id == selected?.id,
                        title: Text(review.title.value),
                        subtitle: Text(reviewStatusLabel(review.status)),
                        trailing: Text('${review.rating.value}/5'),
                        onTap: () => setState(() => _selectedId = review.id),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Flexible(
            flex: 2,
            child: SingleChildScrollView(
              child: _DetailPanel(review: selected, actions: _actionsFor(context, selected)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _actionsFor(BuildContext context, Review? review) {
    if (review == null) return const [];
    return switch (review.status) {
      ReviewPending() => [
        FilledButton.icon(
          onPressed: () => context.read<ReviewBloc>().add(ReviewApproved(review.id)),
          icon: const Icon(Icons.check),
          label: const Text('Odobri'),
        ),
        OutlinedButton.icon(
          onPressed: () => unawaited(_reject(context, review)),
          icon: const Icon(Icons.close),
          label: const Text('Odbij'),
        ),
      ],
      ReviewHidden() => [
        FilledButton.icon(
          onPressed: () => context.read<ReviewBloc>().add(ReviewRepublished(review.id)),
          icon: const Icon(Icons.visibility),
          label: const Text('Ponovo objavi'),
        ),
        OutlinedButton.icon(
          onPressed: () => unawaited(_reject(context, review)),
          icon: const Icon(Icons.close),
          label: const Text('Odbij'),
        ),
      ],
      ReviewPublished() || ReviewRejected() => [
        OutlinedButton.icon(
          onPressed: () => unawaited(_archive(context, review)),
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Arhiviraj'),
        ),
      ],
      ReviewArchived() => const [],
    };
  }

  List<Review> _filterReviews(List<Review> reviews) {
    final query = _query.trim().toLowerCase();
    return [
      for (final review in reviews)
        if (_matchesFilter(review) &&
            (query.isEmpty ||
                review.title.value.toLowerCase().contains(query) ||
                review.body.value.toLowerCase().contains(query) ||
                review.deviceId.value.toLowerCase().contains(query)))
          review,
    ];
  }

  bool _matchesFilter(Review review) => switch (_filter) {
    _StatusFilter.all => true,
    _StatusFilter.pending => review.status is ReviewPending,
    _StatusFilter.published => review.status is ReviewPublished,
    _StatusFilter.hidden => review.status is ReviewHidden,
    _StatusFilter.rejected => review.status is ReviewRejected,
    _StatusFilter.archived => review.status is ReviewArchived,
  };

  Review? _selectedReview(List<Review> reviews) {
    for (final review in reviews) {
      if (review.id == _selectedId) return review;
    }
    return reviews.isEmpty ? null : reviews.first;
  }

  void _moveSelection(BuildContext context, int delta) {
    final state = context.read<ReviewBloc>().state;
    if (state is! ReviewsReady) return;
    final reviews = _filterReviews(state.reviews);
    if (reviews.isEmpty) return;
    final current = reviews.indexWhere((review) => review.id == _selectedId);
    final next = current < 0 ? 0 : (current + delta).clamp(0, reviews.length - 1).toInt();
    setState(() => _selectedId = reviews[next].id);
  }

  void _approveSelected(BuildContext context) {
    final review = _currentSelection(context);
    if (review?.status is ReviewPending) {
      context.read<ReviewBloc>().add(ReviewApproved(review!.id));
    } else if (review?.status is ReviewHidden) {
      context.read<ReviewBloc>().add(ReviewRepublished(review!.id));
    }
  }

  Future<void> _rejectSelected(BuildContext context) async {
    final review = _currentSelection(context);
    if (review == null) return;
    await _reject(context, review);
  }

  Review? _currentSelection(BuildContext context) {
    final state = context.read<ReviewBloc>().state;
    if (state is! ReviewsReady) return null;
    return _selectedReview(_filterReviews(state.reviews));
  }

  Future<void> _reject(BuildContext context, Review review) async {
    if (review.status is! ReviewPending && review.status is! ReviewHidden) return;
    final controller = TextEditingController();
    try {
      final reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Odbij recenziju'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Razlog'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Odustani')),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) Navigator.pop(dialogContext, text);
              },
              child: const Text('Odbij'),
            ),
          ],
        ),
      );
      if (reason == null || !context.mounted) return;
      context.read<ReviewBloc>().add(ReviewRejectedByEditor(id: review.id, reason: reason));
    } finally {
      controller.dispose();
    }
  }

  Future<void> _archive(BuildContext context, Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: const Text('Arhivirati recenziju?'),
        content: const Text('Arhivirana recenzija se više ne vraća u red za moderaciju.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Arhiviraj')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<ReviewBloc>().add(ReviewArchivedByEditor(review.id));
  }

  String _filterLabel(_StatusFilter filter) => switch (filter) {
    _StatusFilter.all => 'Sva stanja',
    _StatusFilter.pending => 'Na proveri',
    _StatusFilter.published => 'Objavljene',
    _StatusFilter.hidden => 'Sakrivene',
    _StatusFilter.rejected => 'Odbijene',
    _StatusFilter.archived => 'Arhivirane',
  };
}

final class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.review, required this.actions});

  final Review? review;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final review = this.review;
    if (review == null) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(24), child: Text('Izaberite recenziju.')),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(review.title.value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Status: ${reviewStatusLabel(review.status)}'),
          Text('Autor: ${review.authorId.value}'),
          Text('Uređaj: ${review.deviceId.value}'),
          Text('Ocena: ${review.rating.value}/5'),
          if (review.status case ReviewHidden(:final uniqueReportCount)) Text('Različitih prijava: $uniqueReportCount'),
          if (review.status case ReviewRejected(:final reason)) Text('Razlog odbijanja: $reason'),
          const Divider(height: 28),
          Text(review.body.value),
          if (actions.isNotEmpty) ...[const SizedBox(height: 24), Wrap(spacing: 10, runSpacing: 10, children: actions)],
        ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Podaci trenutno ne mogu da se učitaju.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Pokušaj ponovo')),
        ],
      ),
    );
  }
}
