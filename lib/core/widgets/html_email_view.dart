import 'package:cis_crm/core/utils/html_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders an email body as styled HTML or plain text.
///
/// Performance optimizations:
/// - Shows plain text immediately, defers heavy HTML parsing by one frame
/// - `containsHtml` computed once in `initState`, not per build
/// - `renderEmailBody` (17+ regex ops) cached after first call
/// - `RepaintBoundary` isolates expensive HTML rendering
/// - `HtmlWidget` keyed on body hash to avoid redundant re-parses
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
  late bool _isHtml;
  String? _plainTextCache;
  // Deferred rendering: show plain text first, switch to HTML after a frame.
  bool _htmlReady = false;

  @override
  void initState() {
    super.initState();
    _isHtml = containsHtml(widget.body);
    _mode = _isHtml ? widget.initialMode : EmailViewMode.plainText;
    if (_isHtml && _mode == EmailViewMode.html) {
      // Defer HTML widget build to the next frame so the UI doesn't freeze.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _htmlReady = true);
      });
    } else {
      _htmlReady = true;
    }
  }

  @override
  void didUpdateWidget(covariant HtmlEmailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.body != widget.body) {
      _isHtml = containsHtml(widget.body);
      _plainTextCache = null;
      _htmlReady = false;
      if (!_isHtml) {
        _mode = EmailViewMode.plainText;
        _htmlReady = true;
      } else {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _htmlReady = true);
        });
      }
    }
  }

  String get _plainText =>
      _plainTextCache ??= renderEmailBody(widget.body);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showHtml = _mode == EmailViewMode.html && _isHtml && _htmlReady;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showToggle && _isHtml)
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
              onSelectionChanged: (v) => setState(() {
                _mode = v.first;
                if (v.first == EmailViewMode.html && !_htmlReady) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _htmlReady = true);
                  });
                }
              }),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  theme.textTheme.labelSmall,
                ),
              ),
            ),
          ),
        if (widget.showToggle && _isHtml) const SizedBox(height: 8),
        RepaintBoundary(
          child: showHtml
              ? HtmlWidget(
                  widget.body,
                  key: ValueKey(widget.body.hashCode),
                  textStyle: widget.textStyle ?? theme.textTheme.bodyMedium,
                  onLoadingBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  onTapUrl: (url) async {
                    final uri = Uri.tryParse(url);
                    if (uri != null) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                    return true;
                  },
                )
              : SelectableText(
                  _plainText,
                  style: widget.textStyle ?? theme.textTheme.bodyMedium,
                ),
        ),
      ],
    );
  }
}
