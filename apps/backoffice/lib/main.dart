import 'package:flutter/widgets.dart';

import 'app.dart';
import 'data/demo_reviews.dart';
import 'data/memory_review_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const demoEmpty = bool.fromEnvironment('KT1_DEMO_EMPTY');
  const demoDelayMs = int.fromEnvironment('KT1_DEMO_DELAY_MS', defaultValue: 350);
  final reviews = createBackofficeDemoReviews();
  if (demoEmpty) reviews.clear();
  final repository = MemoryReviewRepository(reviews, latency: Duration(milliseconds: demoDelayMs));
  runApp(DeviceGuideBackofficeApp(repository: repository, failureController: repository));
}
