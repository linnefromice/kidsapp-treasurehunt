import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// 宝の地図上のシーンノード（メダリオン）。クリア=金スタンプ、現在地=脈動グロー、
/// ロック=セピア＋錠前。タップで該当シーンへ。
class MapNode extends StatefulWidget {
  const MapNode({
    super.key,
    required this.entry,
    required this.localeCode,
    required this.unlocked,
    required this.cleared,
    required this.onTap,
  });

  final SceneCatalogEntry entry;
  final String localeCode;
  final bool unlocked;
  final bool cleared;
  final VoidCallback? onTap;

  @override
  State<MapNode> createState() => _MapNodeState();
}

class _MapNodeState extends State<MapNode> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  bool get _isCurrent => widget.unlocked && !widget.cleared;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (_isCurrent) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant MapNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isCurrent && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_isCurrent && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateKey = widget.cleared
        ? 'node-cleared.${widget.entry.id}'
        : widget.unlocked
        ? 'node-current.${widget.entry.id}'
        : 'node-locked.${widget.entry.id}';
    final color = widget.cleared
        ? Colors.amber.shade600
        : widget.unlocked
        ? Colors.orange.shade400
        : Colors.brown.shade300;

    // ロックは「未踏の地」らしくセピア寄せ（白地 → 褪せた羊皮紙色）にして
    // 自然に視線を外させる。Opacity レイヤを使わず色だけで表現（saveLayer 回避）。
    final fill = widget.unlocked ? Colors.white : const Color(0xFFEDE3D2);

    Widget medallion = Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(
            color: widget.unlocked ? Colors.black26 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        widget.entry.themeIcon,
        key: ValueKey(stateKey),
        color: color,
        size: 34,
      ),
    );

    if (_isCurrent) {
      medallion = ScaleTransition(
        scale: Tween<double>(
          begin: 1.0,
          end: 1.12,
        ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
        child: medallion,
      );
    }

    return GestureDetector(
      key: ValueKey('scene-node.${widget.entry.id}'),
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isCurrent) _GlowRing(pulse: _pulse),
                medallion,
                if (!widget.unlocked)
                  const Icon(Icons.lock, color: Colors.brown, size: 26),
                if (widget.cleared)
                  Positioned(
                    right: 2,
                    top: 2,
                    // クリアの「スタンプ」（B2）。少し傾けてポンと押した感を出す。
                    child: Transform.rotate(
                      angle: -0.22,
                      child: Container(
                        key: ValueKey('clear-stamp.${widget.entry.id}'),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(widget.localeCode, widget.entry.titleKey),
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 現在ノードの背後で呼吸する発光リング。`pulse` に同期して半径と濃さが揺れる。
class _GlowRing extends StatelessWidget {
  const _GlowRing({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = pulse.value;
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.25 + 0.35 * t),
                blurRadius: 12 + 10 * t,
                spreadRadius: 2 + 4 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
