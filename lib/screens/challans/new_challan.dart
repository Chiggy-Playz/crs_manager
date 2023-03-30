import 'challan_widget.dart';
import 'package:flutter/material.dart';

import '../../utils/widgets.dart';

class NewChallanPage extends StatefulWidget {
  const NewChallanPage({super.key});

  @override
  State<NewChallanPage> createState() => _NewChallanPageState();
}

class _NewChallanPageState extends State<NewChallanPage> {
  final _key = GlobalKey<ChallanWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: TransparentAppBar(
          title: const Text("New Challan"),
          actions: [
            PopupMenuButton<int>(
              icon: const Icon(Icons.article),
              itemBuilder: (context) => List.generate(
                3,
                (index) => PopupMenuItem(
                  value: index + 1,
                  child: Text("${index + 1} Page"),
                ),
              ),
              onSelected: (value) => _key.currentState!.viewPdf(value),
            ),
          ],
        ),
        body: ChallanWidget(
          key: _key,
        ));
  }
}
