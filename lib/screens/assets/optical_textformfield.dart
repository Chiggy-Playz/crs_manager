import 'dart:io';

import 'package:crs_manager/screens/assets/text_recognizer_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'barcode_scanner_page.dart';

class OpticalTextFormField extends StatefulWidget {
  const OpticalTextFormField(
      {super.key,
      required this.labelText,
      required this.initialValue,
      this.keyboardType,
      this.validator,
      this.onSaved});

  final String labelText;
  final String initialValue;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Future<void> Function(String?)? onSaved;

  @override
  State<OpticalTextFormField> createState() => _OpticalTextFormFieldState();
}

class _OpticalTextFormFieldState extends State<OpticalTextFormField> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.text = widget.initialValue;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textFormField = TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
      ),
      validator: widget.validator,
      onSaved: widget.onSaved,
    );

    if (Platform.isWindows) {
      return textFormField;
    }

    return Row(
      children: [
        Expanded(child: textFormField),
        SizedBox(width: 2.w),
        PopupMenuButton<int>(
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 0,
              child: Text(
                "Scan barcode",
              ),
            ),
            PopupMenuItem(
              value: 1,
              child: Text(
                "Scan text from camera",
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: Text(
                "Scan text from image",
              ),
            ),
          ],
          icon: FloatingActionButton(
            onPressed: null,
            heroTag: "fab-camera-${widget.labelText}",
            child: const Icon(Icons.camera_alt),
          ),
          onSelected: (value) async {
            if (value == 0) {
              barcodeScanPressed();
              return;
            }

            textScanPressed(
                value == 1 ? ImageSource.camera : ImageSource.gallery);
          },
        )
      ],
    );
  }

  Future<void> barcodeScanPressed() async {
    var value = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const BarcodeScannerPage()));
    if (value == null) return;
    if (!mounted) return;
    await (widget.onSaved!(value));
    setState(() {
      controller.text = value;
    });
  }

  Future<void> textScanPressed(ImageSource source) async {
    XFile? image = await ImagePicker().pickImage(source: source);

    if (image == null) return;
    if (!mounted) return;

    String? value = await showModalBottomSheet(
      context: context,
      builder: (context) => TextRecognizerWidget(
        image: image,
      ),
    );

    if (value == null) return;
    if (!mounted) return;
    await (widget.onSaved!(value));
    setState(() {
      controller.text = value;
    });
  }
}
