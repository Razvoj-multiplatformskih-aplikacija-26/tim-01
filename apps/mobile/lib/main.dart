import 'package:client_ui/client_ui.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'presentation/app_theme.dart';
import 'data/demo_reviews.dart';
import 'data/memory_review_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const demoEmpty = bool.fromEnvironment('KT1_DEMO_EMPTY');
  const demoDelayMs = int.fromEnvironment('KT1_DEMO_DELAY_MS', defaultValue: 350);
  const useMemory = bool.fromEnvironment('KT1_MEMORY_DEMO');
  if (!useMemory) {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080');
    runApp(
      ReviewSessionGate(
        mobile: true,
        apiBaseUrl: apiBaseUrl,
        theme: buildMobileTheme(),
        builder: (repository, viewer) => DeviceGuideMobileApp(repository: repository, viewer: viewer),
      ),
    );
    return;
  }
  final reviews = createDemoReviews();
  if (demoEmpty) reviews.clear();
  final repository = MemoryReviewRepository(reviews, latency: Duration(milliseconds: demoDelayMs));
  runApp(DeviceGuideMobileApp(repository: repository, failureController: repository));
}
