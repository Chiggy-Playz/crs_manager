import 'dart:io';

import 'challan_widget.dart';
import '../../utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as cup;
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/challan.dart';
import '../../providers/database.dart';
import '../../utils/exceptions.dart';
import '../../utils/widgets.dart';
import 'get_pdf.dart';

class ChallanPageView extends StatefulWidget {
  const ChallanPageView(
      {super.key, required this.initialIndex, required this.challans});

  final int initialIndex;
  final List<Challan> challans;

  @override
  State<ChallanPageView> createState() => _ChallanPageViewState();
}

class _ChallanPageViewState extends State<ChallanPageView> {
  late PageController controller;
  late Challan _selectedChallan;
  var _keys = <GlobalKey<ChallanWidgetState>>[];

  @override
  void initState() {
    super.initState();
    _selectedChallan = widget.challans[widget.initialIndex];
    controller = PageController(initialPage: widget.initialIndex);
    _keys = List.generate(
      widget.challans.length,
      (index) => GlobalKey<ChallanWidgetState>(),
    );
    controller.addListener(controllerListener);
  }

  void controllerListener() {
    // page moving
    // check changes and show dialog box
    bool changesMade =
        _keys[controller.page!.round()].currentState!.changesMade();
    // If changes made and dialogbox not already opened
    if (changesMade && !(ModalRoute.of(context)?.isCurrent != true)) {
      controller.animateToPage(
        controller.page!.round(),
        duration: const Duration(milliseconds: 200),
        curve: Curves.bounceIn,
      );
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Unsaved changes"),
          content: const Text("You must save or discard the changes"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Ok"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(
        title: const Text("Edit Challan"),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.article),
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
            onSelected: (value) => viewPdf(value),
          ),
          InkWell(
            onLongPress: _selectedChallan.cancelled ? () {} : onCancelPressed,
            onTap: _selectedChallan.cancelled
                ? null
                : () => context.showSnackBar(message: "Hold to cancel challan"),
            child: cup.Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: controller,
        children: List.generate(
          widget.challans.length,
          (index) => ChallanWidget(
            key: _keys[index],
            challan: widget.challans[index],
          ),
        ),
        onPageChanged: (value) => _selectedChallan = widget.challans[value],
      ),
    );
  }

  void viewPdf(int pages) async {
    String path;

    try {
      path = await makePdf(_selectedChallan, pages);
    } on PermissionDenied {
      context.showErrorSnackBar(message: "Permission denied");
      return;
    } catch (e) {
      context.showErrorSnackBar(
          message: "Error occured while trying to create pdf");
      return;
    }
    await Future.delayed(const Duration(milliseconds: 50));
    if (!await File(path).exists()) {
      if (!mounted) return;
      // Should never happen, but here we are :husk:
      context.showErrorSnackBar(message: "File not found");
      return;
    }

    if (Platform.isAndroid) {
      await OpenFile.open(path);
    } else {
      // Else we're on windows, and we just rely on browsers being able to open pdfs
      Uri url = Uri.file(path, windows: true);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (!mounted) return;
        context.showErrorSnackBar(message: "Couldn't open file");
      }
    }
  }

  void onCancelPressed() async {
    var result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Challan?"),
        content: const Text("Are you sure you want to cancel this challan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (result == null || result == false) return;
    if (!mounted) return;

    // Confirm again, just to be REALLY sure
    var secondResult = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Challan?"),
        content:
            const Text("Are you REALLY sure you want to cancel this challan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (secondResult == true) {
      await Provider.of<DatabaseModel>(context, listen: false)
          .updateChallan(challan: _selectedChallan, cancelled: true);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }
}
