import 'package:cis_crm/core/utils/html_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders an email body as styled HTML or plain text.
///
/// - Default: renders styled HTML using flutter_widget_from_html
/// - Toggle: user can switch to plain text view
/// - Safe: no JavaScript execution (Flutter HTML renderer only builds widgets)
class HtmlEmailView extends StatefulWidget {
  const HtmlEmailView({
    required this.body,
    this.initialMode = EmailViewMode.html,
    this.showToggle = true,
    this.textStyle,
    super.key,
  });

  final String body;
  final EmailViewMode initialMode;
  final bool showToggle;
  final TextStyle? textStyle;

  @override
  State<HtmlEmailView> createState() => _HtmlEmailViewState();
}

enum EmailViewMode { html, plainText }

class _HtmlEmailViewState extends State<HtmlEmailView> {
  late EmailViewMode _mode;

  @override
  void initState() {
    super.initState();
    // Auto-detect: if body doesn't contain HTML, default to plain text
    _mode = containsHtml(widget.body)
        ? widget.initialMode
        : EmailViewMode.plainText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHtml = containsHtml(widget.body);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle (only show if body actually has HTML)
        if (widget.showToggle && isHtml)
          Align(
            alignment: Alignment.centerRight,
            child: SegmentedButton<EmailViewMode>(
              segments: const [
                ButtonSegment(
                  value: EmailViewMode.html,
                  icon: Icon(Icons.article, size: 16),
                  label: Text('Styled'),
                ),
                ButtonSegment(
                  value: EmailViewMode.plainText,
                  icon: Icon(Icons.text_snippet, size: 16),
                  label: Text('Plain text'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() => _mode = v.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  theme.textTheme.labelSmall,
                ),
              ),
            ),
          ),
        if (widget.showToggle && isHtml) const SizedBox(height: 8),

        // Content
        if (_mode == EmailViewMode.html && isHtml)
          HtmlWidget(
            widget.body,
            textStyle: widget.textStyle ?? theme.textTheme.bodyMedium,
            onTapUrl: (url) async {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              return true;
            },
          )
        else
          SelectableText(
            renderEmailBody(widget.body),
            style: widget.textStyle ?? theme.textTheme.bodyMedium,
          ),
      ],
    );
  }
}
