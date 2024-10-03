import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

class QRCodeGeneratorScreen extends StatefulWidget {
  const QRCodeGeneratorScreen({
    super.key,
    required this.qrCodeData,
    this.size = 150,
    this.typeNumber = 1,
    this.errorCorrectLevel = QrErrorCorrectLevel.L,
  })  : assert(typeNumber >= 1 && typeNumber <= 40, 'typeNumber must be between 1 and 40'),
        assert(errorCorrectLevel >= 0 && errorCorrectLevel <= 3, 'errorCorrectLevel must be between 0 and 3');

  final String qrCodeData;
  final int size, typeNumber;
  final int errorCorrectLevel;

  @override
  State<QRCodeGeneratorScreen> createState() => _QRCodeGeneratorScreenState();
}

class _QRCodeGeneratorScreenState extends State<QRCodeGeneratorScreen> {
  Uint8List? _qrImage;

  @override
  void initState() {
    super.initState();
    generateQRCode();
  }

  Future<void> generateQRCode() async {
    final qrCode = QrCode(widget.typeNumber, widget.errorCorrectLevel)..addData(widget.qrCodeData);
    final qrImage = QrImage(qrCode);
    final image = img.Image(
      width: qrImage.moduleCount,
      height: qrImage.moduleCount,
    );

    for (var x = 0; x < qrImage.moduleCount; x++) {
      for (var y = 0; y < qrImage.moduleCount; y++) {
        final (r, g, b) = switch (qrImage.isDark(y, x)) {
          false => (0, 0, 0),
          true => (0, 200, 255),
        };
        image.setPixelRgb(x, y, r, g, b);
      }
    }
    final resized = img.copyResize(image, width: widget.size, height: widget.size);
    _qrImage = img.encodePng(resized);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Center(
          child: SizedBox(
        height: widget.size.toDouble(),
        width: widget.size.toDouble(),
        child: _qrImage != null ? Image.memory(_qrImage!) : const CircularProgressIndicator(),
      ));
}
