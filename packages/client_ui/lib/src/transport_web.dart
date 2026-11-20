import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

http.Client platformHttpClient() => BrowserClient()..withCredentials = true;

const _sessionMarker = 'device-guide-signed-in';

bool hadBrowserSession() {
  try {
    return web.window.localStorage.getItem(_sessionMarker) != null;
  } on Object {
    return false;
  }
}

void rememberBrowserSession(bool signedIn) {
  try {
    if (signedIn) {
      web.window.localStorage.setItem(_sessionMarker, 'true');
    } else {
      web.window.localStorage.removeItem(_sessionMarker);
    }
  } on Object {
    // Browser storage can be unavailable by user preference.
  }
}
