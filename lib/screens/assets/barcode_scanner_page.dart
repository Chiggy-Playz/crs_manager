import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  List<String> results = [];
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 5, child: _buildQrView(context)),
          Expanded(
            flex: 5,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
              child: Column(
                children: <Widget>[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => controller!.pauseCamera(),
                          icon: const Icon(Icons.pause),
                          label: const Text("Pause"),
                        ),
                        SizedBox(width: 2.w),
                        FilledButton.icon(
                          onPressed: () => controller!.resumeCamera(),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Resume"),
                        ),
                        SizedBox(width: 2.w),
                        FilledButton.icon(
                          onPressed: () => setState(() {
                            results = [];
                          }),
                          icon: const Icon(Icons.delete),
                          label: const Text("Clear"),
                        ),
                        SizedBox(width: 2.w),
                        FilledButton.icon(
                            onPressed: () => controller!.flipCamera(),
                            icon: const Icon(Icons.flip_camera_android),
                            label: const Text("Flip Camera")),
                        SizedBox(width: 2.w),
                        FilledButton.icon(
                            onPressed: () => controller!.toggleFlash(),
                            icon: const Icon(Icons.flash_on),
                            label: const Text("Toggle Flash")),
                      ],
                    ),
                  ),
                  SizedBox(height: 1.h),
                  if (results.isEmpty)
                    const Center(child: Text("Nothing scanned yet"))
                  else
                    SizedBox(
                      height: 40.h,
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 2,
                            child: ListTile(
                              title: Text(results[index]),
                              onTap: () =>
                                  Navigator.of(context).pop(results[index]),
                            ),
                          );
                        },
                      ),
                    )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.red,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutWidth: 75.w,
        cutOutHeight: 10.h,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        if (!results.contains(scanData.code!)) {
          // context.showSnackBar(message: "Scanned ${scanData.code!}");
          results.add(scanData.code!);
        }
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
