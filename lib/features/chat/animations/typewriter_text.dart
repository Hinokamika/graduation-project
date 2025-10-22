import 'package:flutter/material.dart';

// Lightweight typewriter text using a single AnimationController
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final Duration? maxDuration;
  final VoidCallback? onComplete;

  const TypewriterText(
    this.text, {
    super.key,
    this.textStyle,
    this.maxDuration,
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final total = widget.text.length.clamp(1, 1000);
    // Slower pace: ~200ms/char, capped 2000ms..5000ms
    final durationMs = (total * 200).clamp(2000, 5000);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      final total = widget.text.length.clamp(1, 1000);
      final durationMs = (total * 200).clamp(2000, 5000);
      _controller.duration = Duration(milliseconds: durationMs);
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final len = widget.text.length;
        final visible = (len * _controller.value).clamp(0, len).toInt();
        return Text(
          widget.text.substring(0, visible),
          style: widget.textStyle,
        );
      },
    );
  }
}

