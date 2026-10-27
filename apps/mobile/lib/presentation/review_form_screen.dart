import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/demo_devices.dart';
import 'app_text.dart';
import 'review_detail_screen.dart';

final class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({super.key});

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

final class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  DeviceId _deviceId = demoDevices.first.id;
  int _rating = 5;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova recenzija')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<DeviceId>(
              initialValue: _deviceId,
              decoration: const InputDecoration(labelText: 'Uređaj'),
              items: [for (final device in demoDevices) DropdownMenuItem(value: device.id, child: Text(device.name))],
              onChanged: (value) {
                if (value != null) setState(() => _deviceId = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              maxLength: ReviewTitle.maximumLength,
              decoration: const InputDecoration(labelText: 'Naslov'),
              validator: (value) => _messageFor(ReviewTitle.parse(value ?? '').errorOrNull),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _body,
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
              items: [
                for (var rating = 1; rating <= 5; rating++)
                  DropdownMenuItem(value: rating, child: Text('$rating od 5')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _rating = value);
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Pošalji na proveru'),
            ),
          ],
        ),
      ),
    );
  }

  String? _messageFor(DomainError? error) => error == null ? null : domainErrorMessage(error);

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ReviewBloc>().add(
      ReviewSubmitted(
        deviceId: _deviceId,
        authorId: currentMobileUser,
        title: _title.text,
        body: _body.text,
        rating: _rating,
      ),
    );
    Navigator.pop(context);
  }
}
