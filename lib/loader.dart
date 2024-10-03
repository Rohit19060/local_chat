import 'dart:async';

import 'package:flutter/material.dart';

import 'constants.dart';

class IconAnimation extends StatefulWidget {
  const IconAnimation({super.key});

  @override
  State<IconAnimation> createState() => _IconAnimationState();
}

class _IconAnimationState extends State<IconAnimation> {
  List<String> icons = ['wifi_1', 'wifi_2', 'wifi_3'];
  int currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      currentIndex = (currentIndex + 1) % icons.length;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 1),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: Image.asset(
          'assets/images/${icons[currentIndex]}.png',
          width: 100,
          height: 100,
          color: primaryColor,
        ),
      );
}
