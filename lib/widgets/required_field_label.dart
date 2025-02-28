import 'package:flutter/material.dart';

class RequiredFieldLabel extends StatelessWidget {
  final String label;
  final TextStyle? style;

  const RequiredFieldLabel({
    Key? key,
    required this.label,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle defaultStyle = style ?? Theme.of(context).textTheme.titleMedium!;
    return RichText(
      text: TextSpan(
        text: label,
        style: defaultStyle,
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
}
