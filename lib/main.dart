import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'message_list.dart';
import 'methods.dart';
import 'network_analyzer.dart';
import 'note_client.dart';
import 'note_server.dart';

final navigatorKey = GlobalKey<NavigatorState>();
void main() {
  runZonedGuarded(() {
    runApp(const MyApp());
    FlutterError.onError = (errorDetails) async {
      log('Flutter Error: ${errorDetails.exceptionAsString()}');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      log('Platform Error', error: error, stackTrace: stack);
      return true;
    };
  }, (error, stack) {
    log('Something went wrong!', error: error, stackTrace: stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: const NoteSharingApp(),
        navigatorKey: navigatorKey,
        theme: ThemeData(
          primaryColor: Colors.blue,
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
              foregroundColor: Colors.black,
            ),
          ),
          indicatorColor: Colors.blue,
          progressIndicatorTheme: const ProgressIndicatorThemeData(color: Colors.blue),
        ),
      );
}

class NoteSharingApp extends StatefulWidget {
  const NoteSharingApp({super.key});

  @override
  State<NoteSharingApp> createState() => _NoteSharingAppState();
}

class _NoteSharingAppState extends State<NoteSharingApp> {
  late NoteClient client;
  late NoteServer server;
  final _noteController = TextEditingController();
  bool isServer = false, isServerRunning = false, isConnectedToServer = false, _isLoading = false;
  int port = 39847;
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    client = NoteClient(addMessage);
    server = NoteServer(addMessage);
  }

  @override
  void dispose() {
    if (isServer) {
      server.stopServer();
    } else {
      client.disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(isServer ? 'Server' : 'Client'),
          actions: [
            if (isServerRunning)
              IconButton(
                key: const Key('stopServer'),
                iconSize: 35,
                icon: const Icon(Icons.stop),
                onPressed: stopServer,
              )
            else if (isConnectedToServer)
              IconButton(
                key: const Key('disconnectFromServer'),
                iconSize: 35,
                icon: const Icon(Icons.stop),
                onPressed: disconnectFromServer,
              ),
            IconButton(
              key: const Key('toggleServer'),
              iconSize: 35,
              icon: isServer ? const Icon(Icons.computer) : const Icon(Icons.dns_outlined),
              onPressed: () => setState(() => isServer = !isServer),
            ),
            IconButton(
              key: const Key('clearMessages'),
              iconSize: 35,
              icon: const Icon(Icons.delete),
              onPressed: () {
                showToast('Cleared');
                messages.clear();
                setState(() {});
              },
            )
          ],
        ),
        body: Column(
          children: [
            if (isServer && !isServerRunning)
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: _isLoading ? () {} : startAsServer,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _isLoading ? 68 : 150,
                  height: 65,
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Start Server',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            if (!isServer && !isConnectedToServer)
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: _isLoading ? () {} : connectToServer,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _isLoading ? 68 : 200,
                  height: 65,
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Connect to Server',
                          style: TextStyle(fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                ),
              ),
            MessageList(messages: messages, isServer: isServer),
            Container(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      controller: _noteController,
                      onChanged: (_) => setState(() {}),
                      onEditingComplete: sendNote,
                      cursorColor: Colors.white,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Theme.of(context).primaryColor.withOpacity(0.9),
                        contentPadding: const EdgeInsets.only(left: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  IconButton(
                    color: Theme.of(context).primaryColor,
                    iconSize: 30,
                    onPressed: _noteController.text.isNotEmpty ? sendNote : null,
                    icon: const Icon(Icons.send_rounded),
                  )
                ],
              ),
            ),
          ],
        ),
      );

  void addMessage(String message) {
    messages.insert(0, message);
    setState(() {});
  }

  Future<void> startAsServer() async {
    try {
      await server.startServer(port);
      isServerRunning = true;
      setState(() {});
    } on Exception catch (e) {
      if (mounted) {
        showToast('Error in starting server: $e');
      }
    }
  }

  Future<void> stopServer() async {
    setState(() => _isLoading = true);
    await server.stopServer();
    isServerRunning = false;
    _isLoading = false;
    setState(() {});
  }

  void disconnectFromServer() {
    client.disconnect();
    isConnectedToServer = false;
    setState(() {});
  }

  Future<void> connectToServer() async {
    if (_isLoading) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final socket = await NetworkAnalyzer.discoverDevices(port);
      if (socket != null && mounted) {
        showToast('Connected To ${socket.address.address}');
        await client.startListener(socket);
        setState(() {});
        isConnectedToServer = true;
      } else if (mounted) {
        showToast('No devices found');
      }
    } on Exception catch (e) {
      if (mounted) {
        showToast('Error: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void sendNoteAsClient(String note) {
    client.sendNote(note);
  }

  void sendNoteAsServer(String note) {
    server.broadcastNote(note);
  }

  void sendNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty) {
      return;
    }
    if (isServer) {
      sendNoteAsServer(text);
    } else {
      sendNoteAsClient(text);
    }
    _noteController.clear();
  }
}
