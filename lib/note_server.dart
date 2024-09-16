import 'dart:developer';
import 'dart:io';

import 'network_analyzer.dart';

class NoteServer {
  NoteServer(this.addMessage);
  ServerSocket? serverSocket;
  List<Socket> clients = [];
  late void Function(String) addMessage;

  Future<void> startServer(int port) async {
    try {
      final localIp = await getLocalIp();
      log(localIp);
      serverSocket = await ServerSocket.bind(localIp, port, shared: true);
      addMessage('Server Ip: ${serverSocket?.address}');
      serverSocket!.listen((client) {
        if (clients.any((x) => x.remoteAddress.address == client.remoteAddress.address && x.remotePort == client.remotePort)) {
          log('Client already connected');
          return;
        }

        clients.add(client);
        log('Client connected: ${client.remoteAddress.address}:${client.remotePort}');

        client.listen(
          (data) {
            final receivedMessage = String.fromCharCodes(data).trim();
            log('Received note (${client.remoteAddress.address}): $receivedMessage');
            addMessage('Client(${client.remoteAddress.address}): $receivedMessage');

            for (final x in clients) {
              if (client != x) {
                x.write('$receivedMessage\n');
              }
            }
          },
          onDone: () {
            clients.removeWhere((x) => x == client);
            log('Client disconnected');
          },
          onError: (x) {
            log('Error in client connection', error: x);
          },
        );
      });
    } catch (e) {
      log('Error in starting server: $e');
      rethrow;
    }
  }

  Future<void> stopServer() async {
    await serverSocket?.close();
    serverSocket = null;
    log('Server stopped');
  }

  void broadcastNote(String note) {
    addMessage('Server: $note');
    for (final client in clients) {
      log('Broadcasting to ${client.address.address}');
      client.write('$note\n');
    }
  }

  void broadCastToClient(Socket? client, String note) {
    addMessage('Server: $note');
    client?.write('$note\n');
  }
}
