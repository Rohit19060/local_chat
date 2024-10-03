import 'package:flutter/material.dart';

import 'constants.dart';
import 'loader.dart';

class ConnectButton extends StatefulWidget {
  const ConnectButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.icon,
  });
  final bool isLoading;
  final void Function()? onPressed;
  final IconData icon;

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _showShadow = true;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 20, end: 34).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInBack,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          onPressed: widget.isLoading ? null : widget.onPressed,
          child: GestureDetector(
            onPanStart: (details) => setState(() => _showShadow = false),
            onPanCancel: () => setState(() => _showShadow = true),
            onPanEnd: (details) => setState(() => _showShadow = true),
            onPanDown: (details) => setState(() => _showShadow = false),
            onPanUpdate: (details) => setState(() => _showShadow = false),
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) => Container(
                width: 200,
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: _showShadow || widget.isLoading
                      ? [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 200, 255, 1),
                            blurRadius: _glowAnimation.value,
                            spreadRadius: _glowAnimation.value / 2,
                          ),
                          BoxShadow(
                            color: const Color.fromRGBO(0, 200, 255, 1),
                            blurRadius: _glowAnimation.value * 2,
                            spreadRadius: _glowAnimation.value / 4,
                          ),
                          BoxShadow(
                            color: const Color.fromRGBO(0, 200, 255, 1),
                            blurRadius: _glowAnimation.value * 4,
                            spreadRadius: _glowAnimation.value / 8,
                          ),
                        ]
                      : [],
                ),
                child: widget.isLoading
                    ? const IconAnimation()
                    : Icon(
                        widget.icon,
                        color: const Color.fromRGBO(0, 200, 255, 1),
                        size: 80,
                      ),
              ),
            ),
          ),
        ),
      );
}

class NeonText extends StatelessWidget {
  const NeonText({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 200,
        height: 60,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.8),
              blurRadius: 20,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: primaryColor.withOpacity(0.6),
              blurRadius: 50,
              spreadRadius: 15,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Neon Button',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      );
}
