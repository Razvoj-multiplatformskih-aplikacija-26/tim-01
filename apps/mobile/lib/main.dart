import 'package:flutter/widgets.dart';

import 'app.dart';
import 'data/demo_reviews.dart';
import 'data/memory_review_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = MemoryReviewRepository(createDemoReviews());
  runApp(DeviceGuideMobileApp(repository: repository, failureController: repository));
}
