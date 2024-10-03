import 'dart:developer';

import 'package:flutter/material.dart';

class QRCodeImageScreen extends StatelessWidget {
  const QRCodeImageScreen({
    super.key,
    required this.qrCodeData,
    this.size = 150,
  });
  final String qrCodeData;
  final double size;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          height: size,
          width: size,
          child: Image.network(
            'https://api.qrserver.com/v1/create-qr-code/?size=${size}x$size&data=$qrCodeData',
            errorBuilder: (context, error, stackTrace) {
              log('Image Loading error: ', error: error, stackTrace: stackTrace);
              return const Text('Failed to load QR code');
            },
          ),
        ),
      );
}
