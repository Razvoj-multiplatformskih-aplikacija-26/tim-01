import 'package:http/http.dart' as http;

http.Client platformHttpClient() => http.Client();

bool hadBrowserSession() => false;

void rememberBrowserSession(bool signedIn) {}
