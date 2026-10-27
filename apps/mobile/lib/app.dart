import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'presentation/app_theme.dart';
import 'router.dart';

final class DeviceGuideMobileApp extends StatefulWidget {
  const DeviceGuideMobileApp({required this.repository, required this.failureController, super.key});

  final ReviewRepository repository;
  final RequestFailureController failureController;

  @override
  State<DeviceGuideMobileApp> createState() => _DeviceGuideMobileAppState();
}

final class _DeviceGuideMobileAppState extends State<DeviceGuideMobileApp> {
  late final GoRouter _router = createMobileRouter();
  var _nextReviewNumber = 100;

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
        title: 'Vodič za uređaje',
        debugShowCheckedModeBanner: false,
        theme: buildMobileTheme(),
        routerConfig: _router,
      ),
    );
  }
}
