import 'package:flutter/material.dart';
import 'package:final_project/utils/app_colors.dart';

class PulsingDots extends StatefulWidget {
  const PulsingDots({super.key});

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = AppColors.getTextPrimary(context);
    return SizedBox(
      height: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final begin = i * 0.2;
          final end = begin + 0.6;
          final anim = CurvedAnimation(
            parent: _controller,
            curve: Interval(begin, end, curve: Curves.easeInOut),
          );
          return Padding(
            padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
            child: FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: .8, end: 1.0).animate(anim),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
