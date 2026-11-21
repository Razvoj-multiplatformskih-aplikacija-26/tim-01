import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/demo_devices.dart';
import 'app_text.dart';

final class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({this.editReviewId, super.key});

  final ReviewId? editReviewId;

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

final class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  DeviceId _deviceId = demoDevices.first.id;
  int? _rating = RatingValue.maximum;
  Review? _reviewToEdit;
  var _saving = false;
  String? _saveError;

  bool get _isEditing => widget.editReviewId != null;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewer = context.watch<ReviewViewer>();
    if (viewer.id == null || !canSubmitReview(viewer.role)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recenzija')),
        body: const Center(child: Text('Prijavite se da biste pisali recenzije.')),
      );
    }

    if (_isEditing && _reviewToEdit == null) {
      final state = context.watch<ReviewBloc>().state;
      if (state is ReviewsLoading || state is ReviewInitial) {
        return Scaffold(
          appBar: AppBar(title: const Text('Izmeni recenziju')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (state is ReviewsReady) {
        for (final review in state.reviews) {
          if (review.id != widget.editReviewId || !canEditOwnPendingReview(review, viewer.id, viewer.role)) continue;
          _reviewToEdit = review;
          _title.text = review.title.value;
          _body.text = review.body.value;
          _deviceId = review.deviceId;
          _rating = RatingValue.fromInt(review.rating.value).valueOrNull?.value;
          break;
        }
      }
      if (_reviewToEdit == null) {
        final message = state is ReviewsFailure
            ? domainErrorMessage(state.loadError ?? const ServerUnavailable())
            : 'Ova recenzija trenutno nije dostupna za izmenu.';
        return Scaffold(
          appBar: AppBar(title: const Text('Izmeni recenziju')),
          body: Center(child: Text(message)),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Izmeni recenziju' : 'Nova recenzija')),
      body: BlocListener<ReviewBloc, ReviewState>(
        listener: (context, state) {
          if (!_saving) return;
          final completedAction = _isEditing ? ReviewAction.edited : ReviewAction.submitted;
          if (state.lastAction == completedAction) {
            Navigator.pop(context);
            return;
          }
          final error = state.actionError;
          if (error == null) return;
          setState(() {
            _saving = false;
            _saveError = domainErrorMessage(error);
          });
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!_isEditing) ...[
                DropdownButtonFormField<DeviceId>(
                  initialValue: _deviceId,
                  decoration: const InputDecoration(labelText: 'Uređaj'),
                  items: [
                    for (final device in demoDevices) DropdownMenuItem(value: device.id, child: Text(device.name)),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _deviceId = value);
                        },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _title,
                readOnly: _saving,
                maxLength: ReviewTitle.maximumLength,
                decoration: const InputDecoration(labelText: 'Naslov'),
                validator: (value) => _messageFor(ReviewTitle.parse(value ?? '').errorOrNull),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _body,
                readOnly: _saving,
                minLines: 5,
                maxLines: 8,
                maxLength: ReviewBody.maximumLength,
                decoration: const InputDecoration(labelText: 'Iskustvo sa uređajem'),
                validator: (value) => _messageFor(ReviewBody.parse(value ?? '').errorOrNull),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _rating,
                decoration: const InputDecoration(labelText: 'Ocena'),
                validator: (rating) => rating == null ? 'Izaberite ocenu.' : null,
                items: [
                  for (var rating = RatingValue.minimum; rating <= RatingValue.maximum; rating++)
                    DropdownMenuItem(value: rating, child: Text('$rating od ${RatingValue.maximum}')),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _rating = value);
                      },
              ),
              const SizedBox(height: 24),
              if (_saveError case final message?) ...[
                Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: _saving ? null : () => _submit(viewer.id!),
                icon: const Icon(Icons.send_outlined),
                label: Text(_saving ? 'Čuvanje…' : (_isEditing ? 'Sačuvaj izmene' : 'Pošalji na proveru')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _messageFor(DomainError? error) => error == null ? null : domainErrorMessage(error);

  void _submit(UserId authorId) {
    final rating = _rating;
    if (!_formKey.currentState!.validate() || rating == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final bloc = context.read<ReviewBloc>();
    final editReviewId = widget.editReviewId;
    if (editReviewId != null) {
      bloc.add(ReviewEdited(id: editReviewId, title: _title.text, body: _body.text, rating: rating));
      return;
    }
    bloc.add(
      ReviewSubmitted(deviceId: _deviceId, authorId: authorId, title: _title.text, body: _body.text, rating: rating),
    );
  }
}
