import 'package:flutter/material.dart';

class TransparentAppBar extends AppBar {
  TransparentAppBar({Key? key, required Widget title, List<Widget>? actions})
      : super(
          key: key,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: title,
          actions: actions,
        );
}

PageRouteBuilder opaquePage(Widget page) => PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, _, __) => page,
    );

class SpacedRow extends StatelessWidget {
  const SpacedRow({super.key, required this.widget1, required this.widget2});

  final Widget widget1;
  final Widget widget2;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        widget1,
        const Spacer(),
        widget2,
      ],
    );
  }
}

TextStyle font(size) => TextStyle(fontSize: (size as int).toDouble());
