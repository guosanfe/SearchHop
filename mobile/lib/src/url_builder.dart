/// Pure URL construction: template + keyword -> search URL / app scheme.
/// Kept free of Flutter / IO so it can be unit-tested in isolation,
/// mirroring the desktop url_builder.py.
library;

const String queryPlaceholder = '{query}';

class MissingQueryPlaceholderError extends ArgumentError {
  MissingQueryPlaceholderError(String template)
      : super('URL 模板缺少 {query} 占位符：$template');
}

enum EncodeMode {
  /// Percent-encode the keyword, then substitute (default).
  query,

  /// Substitute the raw keyword into a nested JSON params value, then
  /// percent-encode the whole value (JD / SMZDM style templates).
  wholeParams,
}

String buildSearchUrl(
  String template,
  String query, {
  EncodeMode encodeMode = EncodeMode.query,
}) {
  if (!template.contains(queryPlaceholder)) {
    throw MissingQueryPlaceholderError(template);
  }
  switch (encodeMode) {
    case EncodeMode.query:
      return template.replaceAll(queryPlaceholder, Uri.encodeComponent(query));
    case EncodeMode.wholeParams:
      final raw = template.replaceAll(queryPlaceholder, query);
      final questionMark = raw.indexOf('?');
      if (questionMark < 0) return raw;
      final equals = raw.indexOf('=', questionMark);
      if (equals < 0) return raw;
      return raw.substring(0, equals + 1) +
          Uri.encodeComponent(raw.substring(equals + 1));
  }
}