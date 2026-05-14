import 'package:flutter/material.dart';

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
