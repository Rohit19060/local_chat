import 'dart:io';

import 'package:flutter/material.dart';

class NoteClient {
  NoteClient(this.addMessage);
  Socket? socket;
  late void Function(String) addMessage;

  Future<void> startListener(Socket s) async {
    try {
      socket = s;
      s.listen((data) {
        final receivedMessage = String.fromCharCodes(data).trim();
        addMessage('Server: $receivedMessage');
      });
    } on Exception catch (e) {
      debugPrint('Failed to connect: $e');
    }
  }

  void sendNote(String note) {
    addMessage('Me: $note');
    socket?.write('$note\n');
  }

  void disconnect() {
    socket?.destroy();
    socket = null;
    debugPrint('Disconnected from server');
  }
}
