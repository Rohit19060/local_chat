import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'connect_button.dart';
import 'constants.dart';
import 'message_list.dart';
import 'methods.dart';
import 'network_analyzer.dart';
import 'note_client.dart';
import 'note_server.dart';
import 'qr_code_generator.dart';
import 'qr_scanner.dart';

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
          primaryColor: primaryColor,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(foregroundColor: primaryColor),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(foregroundColor: Colors.black),
          ),
          indicatorColor: primaryColor,
          progressIndicatorTheme: const ProgressIndicatorThemeData(color: primaryColor),
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
  final _messageCtrl = TextEditingController();
  final _messageFocus = FocusNode();
  bool _isServer = false, _isConnected = false, _isLoading = false;
  int port = 39847;
  final _messages = <String>[];
  String _serverIp = '';

  @override
  void initState() {
    super.initState();
    client = NoteClient(addMessage);
    server = NoteServer(addMessage);
  }

  @override
  void dispose() {
    if (_isServer) {
      server.stopServer();
    } else {
      client.disconnect();
    }
    super.dispose();
  }

  void switchMode(bool x) {
    disconnect();
    _messages.clear();
    _isConnected = false;
    _isLoading = false;
    setState(() => _isServer = x);
  }

  void disconnect() {
    if (_isServer) {
      stopServer();
    } else {
      disconnectFromServer();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isServer && !_isConnected)
                    IconButton(
                      icon: const Icon(Icons.qr_code),
                      color: primaryColor,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QRScanner(
                            port: port,
                            connectSocket: connectToServer,
                          ),
                        ),
                      ),
                    ),
                  if (_isConnected && _serverIp.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.qr_code),
                      onPressed: () => showDialog<AlertDialog>(
                        context: context,
                        builder: (context) => AlertDialog(
                          elevation: 10,
                          shadowColor: primaryColor,
                          backgroundColor: Colors.black,
                          title: const Center(child: Text('Server QR', style: TextStyle(color: Colors.white, fontSize: 20))),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 20),
                              QRCodeGeneratorScreen(qrCodeData: _serverIp),
                              const SizedBox(height: 20),
                              Text(_serverIp, style: const TextStyle(color: Colors.white, fontSize: 20)),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close', style: TextStyle(color: Colors.blue)),
                            )
                          ],
                        ),
                      ),
                      color: primaryColor,
                    ),
                  if (_isConnected)
                    IconButton(
                      key: const Key('stopServer'),
                      iconSize: 35,
                      icon: const Icon(Icons.stop),
                      onPressed: disconnect,
                      color: primaryColor,
                    ),
                  if (_messages.isNotEmpty)
                    IconButton(
                      key: const Key('clearMessages'),
                      iconSize: 35,
                      icon: const Icon(Icons.delete),
                      color: primaryColor,
                      onPressed: () {
                        showToast('Cleared');
                        _messages.clear();
                        setState(() {});
                      },
                    )
                ],
              ),
            ),
            if (!_isConnected) ...[
              const SizedBox(height: 100),
              ConnectButton(
                icon: _isServer ? Icons.power_settings_new_rounded : Icons.computer_outlined,
                isLoading: _isLoading,
                onPressed: () {
                  _messages.clear();
                  if (_isServer) {
                    startServer();
                  } else {
                    connectToServer(null);
                  }
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Client',
                        style: TextStyle(color: primaryColor, fontSize: 20),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.computer_outlined,
                        color: primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Switch.adaptive(
                    thumbColor: WidgetStateProperty.all(primaryColor),
                    trackColor: WidgetStateProperty.all(primaryColor),
                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                    trackOutlineWidth: WidgetStateProperty.all(0),
                    thumbIcon: WidgetStateProperty.all(const Icon(Icons.check_circle, color: Colors.black)),
                    value: _isServer,
                    onChanged: switchMode,
                  ),
                  const SizedBox(width: 10),
                  const Row(
                    children: [
                      Icon(
                        Icons.power_settings_new_rounded,
                        color: primaryColor,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Server',
                        style: TextStyle(color: primaryColor, fontSize: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            if (_isConnected) ...[
              MessageList(messages: _messages, isServer: _isServer),
              Container(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                        controller: _messageCtrl,
                        focusNode: _messageFocus,
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
                      color: primaryColor,
                      iconSize: 30,
                      onPressed: _messageCtrl.text.isNotEmpty ? sendNote : null,
                      icon: const Icon(Icons.send_rounded),
                    )
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  void addMessage(String message) {
    _messages.insert(0, message);
    setState(() {});
  }

  Future<void> startServer() async {
    try {
      client.disconnect();
      _serverIp = await server.startServer(port);
      _isConnected = true;
      setState(() {});
    } on Exception catch (e) {
      if (mounted) {
        showToast('Error in starting server: $e');
      }
    }
  }

  Future<void> stopServer() async {
    _messages.clear();
    setState(() => _isLoading = true);
    await server.stopServer();
    _isConnected = false;
    _isLoading = false;
    setState(() {});
  }

  void disconnectFromServer() {
    _messages.clear();
    client.disconnect();
    _isConnected = false;
    _isLoading = false;
    setState(() {});
  }

  Future<void> connectToServer(Socket? socket) async {
    if (_isLoading) {
      return;
    }
    setState(() => _isLoading = true);
    await server.stopServer();
    try {
      socket ??= await NetworkAnalyzer.discoverDevices(port);
      if (socket != null && mounted) {
        showToast('Connected To ${socket.address.address}');
        await client.startListener(socket);
        _isConnected = true;
        _isLoading = false;
        setState(() {});
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
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) {
      return;
    }
    if (_isServer) {
      sendNoteAsServer(text);
    } else {
      sendNoteAsClient(text);
    }
    _messageCtrl.clear();
    _messageFocus.requestFocus();
  }
}
