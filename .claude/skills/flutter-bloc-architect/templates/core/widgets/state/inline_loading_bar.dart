import 'package:flutter/material.dart';

/// 3px linear progress at the top of the viewport.
///
/// Used during a refresh-in-place when previous data is still showing
/// below. Place inside a `Stack` over the page body.
class InlineLoadingBar extends StatelessWidget {
  const InlineLoadingBar({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: const SizedBox(
        height: 3,
        child: LinearProgressIndicator(),
      ),
    );
  }
}
