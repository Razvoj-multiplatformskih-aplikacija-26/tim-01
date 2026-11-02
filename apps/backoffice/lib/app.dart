import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'presentation/app_theme.dart';
import 'router.dart';

final class DeviceGuideBackofficeApp extends StatefulWidget {
  const DeviceGuideBackofficeApp({required this.repository, required this.failureController, super.key});

  final ReviewRepository repository;
  final RequestFailureController failureController;

  @override
  State<DeviceGuideBackofficeApp> createState() => _DeviceGuideBackofficeAppState();
}

final class _DeviceGuideBackofficeAppState extends State<DeviceGuideBackofficeApp> {
  late final GoRouter _router = createBackofficeRouter();
  var _nextReviewNumber = 500;

  ReviewId _nextReviewId() => ReviewId('review-${_nextReviewNumber++}');

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReviewBloc(
        repository: widget.repository,
        failureController: widget.failureController,
        idGenerator: _nextReviewId,
        clock: DateTime.now,
      )..add(const ReviewsRequested()),
      child: MaterialApp.router(
        title: 'Vodič za uređaje Backoffice',
        debugShowCheckedModeBanner: false,
        theme: buildBackofficeTheme(),
        routerConfig: _router,
      ),
    );
  }
}
