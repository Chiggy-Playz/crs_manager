import '../../models/challan.dart';
import 'challan_page.dart';
import 'package:flutter/material.dart';

import '../../utils/widgets.dart';

class NewChallanPage extends StatefulWidget {
  const NewChallanPage({super.key, this.copyFromChallan});

  final Challan? copyFromChallan;

  @override
  State<NewChallanPage> createState() => _NewChallanPageState();
}

class _NewChallanPageState extends State<NewChallanPage> {
  final _key = GlobalKey<ChallanPageState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: TransparentAppBar(
          title: const Text("New Challan"),
          actions: [
            PopupMenuButton<int>(
              icon: const Icon(Icons.picture_as_pdf),
              itemBuilder: (context) => List.generate(
                3,
                (index) => PopupMenuItem(
                  value: index + 1,
                  child: Text("${index + 1} Page"),
                ),
              )..addAll(
                  [
                    const PopupMenuItem<int>(
                      value: 0,
                      child: Text("Unticked"),
                    )
                  ],
                ),
              onSelected: (value) => _key.currentState!.viewPdf(value),
            ),
          ],
        ),
        body: ChallanPage(
          key: _key,
          copyFromChallan: widget.copyFromChallan,
        ));
  }
}
