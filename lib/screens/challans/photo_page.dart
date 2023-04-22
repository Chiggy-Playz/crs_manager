import 'dart:io';

import 'package:crs_manager/providers/drive.dart';
import 'package:crs_manager/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../../models/challan.dart';
import '../../utils/widgets.dart';

class PhotoPage extends StatefulWidget {
  const PhotoPage({
    super.key,
    required this.challan,
  });

  final Challan challan;

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  String _photoId = "";

  @override
  void initState() {
    super.initState();
    _photoId = widget.challan.photoId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: TransparentAppBar(
          title: const Text('Photo'),
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () async {
                Navigator.of(context).pop(_photoId);
              },
            )
          ],
        ),
        body: _photoId.isEmpty
            ? const Center(
                child: Text('No photo found\nUse the button to add one!'))
            : FutureBuilder<File>(
                future:
                    Provider.of<DriveHandler>(context).downloadFile(_photoId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return InteractiveViewer(child: Image.file(snapshot.data!));
                },
              ),
        floatingActionButton: SpeedDial(
          animatedIcon: AnimatedIcons.menu_close,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.camera_alt),
              label: 'Camera',
              onTap: () async {
                await _addPhoto(ImageSource.camera);
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.photo_library),
              label: 'Gallery',
              onTap: () => _addPhoto(ImageSource.gallery),
            ),
          ],
          child: Icon(_photoId.isEmpty ? Icons.add : Icons.edit),
        )
        // FloatingActionButton(
        //   onPressed: photoId.isEmpty ? _addPhoto : _editPhoto,
        //   child: Icon(photoId.isEmpty ? Icons.add : Icons.edit),
        // ),
        );
  }

  Future<void> _addPhoto(ImageSource imageSource) async {
    final ImagePicker picker = ImagePicker();

    // Pick an image.
    final XFile? image = await picker.pickImage(source: imageSource);

    if (!mounted) return;
    if (image == null) {
      context.showErrorSnackBar(message: "No image selected");
      return;
    }

    var data = await image.readAsBytes();
    if (!mounted) return;

    var driveHandler = Provider.of<DriveHandler>(context, listen: false);
    _photoId = (await driveHandler.uploadFile(
            "${widget.challan.session} ${widget.challan.number}", data))
        .id;
    setState(() {});
  }

  void _editPhoto() async {}
}
