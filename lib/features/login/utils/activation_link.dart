/// Parser URL aktivasi yang dikirim backend.
///
/// Format sebenarnya dari `POST /auth/nakes` / create patient:
/// `sitara://activate?token={raw_token}`
class ActivationLink {
  const ActivationLink._();

  static const String scheme = 'sitara';
  static const String host = 'activate';
  static const String tokenQueryKey = 'token';

  /// Mengambil token dari URI. Null bila bukan link aktivasi SITARA.
  static String? tokenFrom(Uri uri) {
    if (uri.scheme.toLowerCase() != scheme) return null;

    final String hostOrPath = uri.host.toLowerCase();
    final String path = uri.path.toLowerCase().replaceAll('/', '');
    final bool isActivate = hostOrPath == host || path == host;
    if (!isActivate) return null;

    final String? token = uri.queryParameters[tokenQueryKey]?.trim();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  static String maskToken(String token) {
    if (token.length < 8) return '********';
    return '${token.substring(0, 3)}...${token.substring(token.length - 3)}';
  }
}
