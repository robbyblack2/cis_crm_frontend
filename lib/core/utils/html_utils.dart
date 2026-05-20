/// Strips HTML tags and decodes common HTML entities to produce
/// readable plain text from an HTML email body.
String stripHtmlTags(String html) {
  var result = html;

  // Remove entire <style>...</style> blocks (including content)
  result = result.replaceAll(
    RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false),
    '',
  );

  // Remove entire <script>...</script> blocks
  result = result.replaceAll(
    RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
    '',
  );

  // Remove entire <head>...</head> blocks
  result = result.replaceAll(
    RegExp(r'<head[^>]*>[\s\S]*?</head>', caseSensitive: false),
    '',
  );

  // Remove HTML comments <!-- ... -->
  result = result.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');

  // Remove CDATA sections
  result = result.replaceAll(RegExp(r'<!\[CDATA\[[\s\S]*?\]\]>'), '');

  // Replace <br>, <br/>, <br /> with newlines
  result = result.replaceAll(RegExp(r'<br\s*/?>'), '\n');

  // Replace </p>, </div>, </li>, </tr> with newlines
  result = result.replaceAll(RegExp(r'</(p|div|li|tr|h[1-6])>'), '\n');

  // Replace <li> with bullet
  result = result.replaceAll(RegExp(r'<li[^>]*>'), '  • ');

  // Strip all remaining HTML tags
  result = result.replaceAll(RegExp(r'<[^>]*>'), '');

  // Decode common HTML entities
  result = result
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll('&rsquo;', '\u2019')
      .replaceAll('&lsquo;', '\u2018')
      .replaceAll('&rdquo;', '\u201D')
      .replaceAll('&ldquo;', '\u201C')
      .replaceAll('&ndash;', '\u2013')
      .replaceAll('&mdash;', '\u2014')
      .replaceAll('&dagger;', '\u2020')
      .replaceAll('&bull;', '\u2022')
      .replaceAll('&hellip;', '\u2026')
      .replaceAll('&copy;', '\u00A9')
      .replaceAll('&reg;', '\u00AE')
      .replaceAll('&trade;', '\u2122');

  // Decode numeric HTML entities (&#NNN; and &#xHHH;)
  result = result.replaceAllMapped(
    RegExp(r'&#(\d+);'),
    (m) => String.fromCharCode(int.parse(m.group(1)!)),
  );
  result = result.replaceAllMapped(
    RegExp(r'&#x([0-9a-fA-F]+);'),
    (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
  );

  // Collapse multiple newlines into max 2
  result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  // Trim leading/trailing whitespace per line, remove blank lines
  result = result
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n')
      .trim();

  return result;
}

/// Returns true if the string appears to contain HTML markup.
bool containsHtml(String text) {
  return RegExp(r'<[a-zA-Z][\s\S]*>').hasMatch(text);
}

/// Renders email body text — strips HTML if detected.
String renderEmailBody(String body) {
  if (containsHtml(body)) {
    return stripHtmlTags(body);
  }
  return body;
}
