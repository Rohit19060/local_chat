import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({
    super.key,
    this.timeout = const Duration(milliseconds: 40),
    required this.port,
    required this.connectSocket,
  });
  final Duration timeout;
  final int port;
  final Future<void> Function(Socket socket) connectSocket;

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  final controller = MobileScannerController(useNewCameraSelector: true, formats: [BarcodeFormat.qrCode]);
  bool _isLoading = false, _isTorchOn = false;

  Future<void> scanQR(String qrData) async {
    if (qrData != 'null' && qrData != '' && !_isLoading) {
      if (qrData.isNotEmpty) {
        try {
          setState(() => _isLoading = true);
          // ignore: close_sinks
          final x = await Socket.connect(qrData, widget.port, timeout: widget.timeout);
          await widget.connectSocket(x);
          await HapticFeedback.vibrate();
          await SystemSound.play(SystemSoundType.click);
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } on Exception catch (_) {
          _isLoading = false;
          setState(() {});
          debugPrint('Connection failed to $qrData');
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller.stop();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Scan Server QR Code'),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.close),
            )
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (barcode) async {
                    if (barcode.barcodes.isEmpty) {
                      return;
                    }
                    final qrData = barcode.barcodes.first.displayValue ?? '';
                    await scanQR(qrData);
                  },
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.55,
                      height: MediaQuery.of(context).size.width * 0.55,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(height: 40),
                    InkWell(
                      onTap: () async {
                        await controller.toggleTorch();
                        _isTorchOn = !_isTorchOn;
                        setState(() {});
                      },
                      child: Container(
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: OvalBorder(side: BorderSide(color: Colors.blue)),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _isTorchOn ? Icons.flashlight_on_outlined : Icons.flashlight_off_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isLoading) const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      );
}
