import '../config/app_config.dart';

/// Resolves media URLs returned by the backend (which may be relative,
/// e.g. `/posts/uploads/abc.png`) into absolute URLs.
String resolveUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  return '${AppConfig.baseUrl}$url';
}
