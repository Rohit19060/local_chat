import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

class NetworkAnalyzer {
  static String? host, subnet;

  static Future<Socket?> discoverDevices(int port, {Duration timeout = const Duration(milliseconds: 40)}) async {
    if (port < 1 || port > 65535) {
      throw Exception('Incorrect port');
    }
    if (host != null) {
      try {
        return await Socket.connect(host, port, timeout: timeout);
      } on Exception catch (_) {
        debugPrint('Connection failed to $host');
      }
    }
    subnet = await getLocalSubnet();
    for (var i = 1; i < 256; i++) {
      final x = '$subnet.$i';
      try {
        final socket = await Socket.connect(x, port, timeout: timeout);
        host = x;
        return socket;
      } on Exception catch (_) {
        debugPrint('Connection failed to $x');
      }
    }
    return null;
  }

  static Future<String> getLocalSubnet() async {
    try {
      if (subnet != null) {
        return subnet!;
      }
      final ip = await getLocalIp();
      return ip.split('.').sublist(0, 3).join('.');
    } catch (e) {
      debugPrint('Error getting local subnet: $e');
      rethrow;
    }
  }
}

Future<String> getLocalIp() async {
  try {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    final supportedNetworks = ['wi-fi', 'wlan', 'ethernet'];
    for (final interface in interfaces) {
      var supported = false;
      for (final network in supportedNetworks) {
        if (interface.name.toLowerCase().contains(network)) {
          supported = true;
          break;
        }
      }
      if (supported) {
        return interface.addresses.first.address;
      }
    }
  } catch (e) {
    debugPrint('Error getting local IP: $e');
    rethrow;
  }
  throw Exception('No devices found');
}

// Error 23,24: Too many open files in system
// 13: Connection failed (OS Error: Permission denied)
// 49: Bind failed (OS Error: Can't assign requested address)
// 61: OS Error: Connection refused
// 64: Connection failed (OS Error: Host is down)
// 65: No route to host
// 101: Network is unreachable
// 111: Connection refused
// 113: No route to host
// <empty>: SocketException: Connection timed out
const errorCodes = [13, 49, 61, 64, 65, 101, 111, 113];
