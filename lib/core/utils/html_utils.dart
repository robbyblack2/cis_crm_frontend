/// Strips HTML tags and decodes common HTML entities to produce
/// readable plain text from an HTML email body.
String stripHtmlTags(String html) {
  // Replace <br>, <br/>, <br /> with newlines
  var result = html.replaceAll(RegExp(r'<br\s*/?>'), '\n');

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
      .replaceAll('&#160;', ' ');

  // Collapse multiple newlines into max 2
  result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  // Trim leading/trailing whitespace per line
  result = result
      .split('\n')
      .map((line) => line.trim())
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
