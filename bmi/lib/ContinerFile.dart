import 'package:flutter/material.dart';

class RepeatContainer extends StatelessWidget {
  final Widget? cardWidget;
  final Color colors;  // this is passed from parent
  final VoidCallback? onPressed; // make optional callback

  const RepeatContainer({
    super.key,
    required this.colors,
    this.cardWidget,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors,  // use the passed color
          borderRadius: BorderRadius.circular(12),
        ),
        child: cardWidget ?? const SizedBox.shrink(),
      ),
    );
  }
}
