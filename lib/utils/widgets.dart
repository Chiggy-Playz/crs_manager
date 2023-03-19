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
