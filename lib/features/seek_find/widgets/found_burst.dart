import 'package:flutter/material.dart';

/// 発見した宝の位置に重ねる、拡大+フェードのキラッ演出。
class FoundBurst extends StatefulWidget {
  const FoundBurst({super.key});

  @override
  State<FoundBurst> createState() => _FoundBurstState();
}

class _FoundBurstState extends State<FoundBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.4,
        end: 1.2,
      ).animate(CurvedAnimation(parent: _c, curve: Curves.elasticOut)),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.9).animate(_c),
        child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 56),
      ),
    );
  }
}
