import "dart:io";

import "package:flutter/material.dart";
import "package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart";
import "package:image_picker/image_picker.dart";
import "package:path_provider/path_provider.dart";
import "package:responsive_sizer/responsive_sizer.dart";

class TextRecognizerWidget extends StatefulWidget {
  const TextRecognizerWidget({super.key, required this.image});

  final XFile image;

  @override
  State<TextRecognizerWidget> createState() => _TextRecognizerWidgetState();
}

class _TextRecognizerWidgetState extends State<TextRecognizerWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 2.h,
        horizontal: 2.w,
      ),
      child: FutureBuilder<List<String>>(
        future: getText(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Error"),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 2,
                child: ListTile(
                  title: Text(
                    snapshot.data![index],
                  ),
                  onTap: () => Navigator.pop(context, snapshot.data![index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<String>> getText() async {
    // Save to temp file
    String path = "${(await getApplicationDocumentsDirectory()).path}/temp.png";
    await widget.image.saveTo(path);

    // Scan text
    return await googleMlkitRecognizeText(path);
  }

  Future<List<String>> googleMlkitRecognizeText(tempPath) async {
    var textRecognizer = TextRecognizer();
    InputImage inputImage = InputImage.fromFilePath(tempPath);

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    await File(tempPath).delete();

    List<String> lines = [];

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        lines.add(line.text);
      }
    }

    return lines;
  }
}
