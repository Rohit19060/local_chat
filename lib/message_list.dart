import 'package:flutter/material.dart';

import 'constants.dart';

class MessageList extends StatelessWidget {
  const MessageList({
    super.key,
    required this.messages,
    required this.isServer,
  });
  final List<String> messages;
  final bool isServer;

  @override
  Widget build(BuildContext context) => Expanded(
        child: ListView.builder(
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              var msg = messages[index];
              final itsMe = isServer ? msg.startsWith('Server: ') : msg.startsWith('Me: ');
              msg = msg.replaceAll('Server: ', '').replaceAll('Me: ', '');
              return Align(
                alignment: itsMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.65),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.8),
                        blurRadius: 2,
                        spreadRadius: 2,
                      ),
                    ],
                    color: itsMe ? const Color.fromARGB(255, 0, 0, 0) : Colors.blue,
                    borderRadius: itsMe
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                          )
                        : const BorderRadius.only(
                            bottomRight: Radius.circular(30),
                            topRight: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                          ),
                  ),
                  child: Text(
                    msg,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }),
      );
}
