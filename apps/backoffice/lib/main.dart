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
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');
    runApp(
      ReviewSessionGate(
        mobile: false,
        apiBaseUrl: apiBaseUrl,
        theme: buildBackofficeTheme(),
        builder: (repository, viewer) => DeviceGuideBackofficeApp(repository: repository),
      ),
    );
    return;
  }
  final reviews = createBackofficeDemoReviews();
  if (demoEmpty) reviews.clear();
  final repository = MemoryReviewRepository(reviews, latency: Duration(milliseconds: demoDelayMs));
  runApp(DeviceGuideBackofficeApp(repository: repository, failureController: repository));
}
