import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_shape.dart';
import 'package:kidsapp_treasurehunt/features/settings/widgets/trail_preview.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// キッズ UX 基準の最小タップターゲット（dp）。
const double _kMinTapTarget = 60;

/// 色スウォッチ（円）の直径（dp）。
const double _kSwatchSize = 24;

/// ドロップダウン行のラベル列の幅（dp）。
const double _kDropdownLabelWidth = 56;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final localeController = ref.read(localeControllerProvider.notifier);
    final trail = ref.watch(trailSettingControllerProvider);
    final trailController = ref.read(trailSettingControllerProvider.notifier);
    final unlockedStyles = ref.watch(unlockedTrailStylesProvider);
    final lockedStyles = [
      for (final style in TrailStyle.values)
        if (!unlockedStyles.contains(style)) style,
    ];
    final trailShape = ref.watch(trailShapeControllerProvider);
    final shapeController = ref.read(trailShapeControllerProvider.notifier);
    final unlockedShapes = ref.watch(unlockedTrailShapesProvider);
    final lockedShapes = [
      for (final shape in TrailShape.values)
        if (!unlockedShapes.contains(shape)) shape,
    ];

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: Text(tr(localeCode, 'settings.title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr(localeCode, 'settings.language'),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              ChoiceChip(
                key: const ValueKey('lang.ja'),
                label: const Text('にほんご'),
                selected: localeCode == 'ja',
                onSelected: (_) => localeController.setLocale('ja'),
              ),
              ChoiceChip(
                key: const ValueKey('lang.en'),
                label: const Text('English'),
                selected: localeCode == 'en',
                onSelected: (_) => localeController.setLocale('en'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            tr(localeCode, 'settings.trailColor'),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 8),
          // スタイル選択（単色 / にじ3色 / にじフル）。
          // ロック中も🔒付きで見せる（選択は不可・煽らない）。
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final style in TrailStyle.values)
                _StyleChip(
                  style: style,
                  label: tr(localeCode, 'trailStyle.${style.id}'),
                  selected: trail.style == style,
                  locked: !unlockedStyles.contains(style),
                  onSelected: () => trailController.selectStyle(style),
                ),
            ],
          ),
          // ロック中スタイルのやさしい解放ヒント（読字に頼り切らず🔒も添える）。
          if (lockedStyles.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final style in lockedStyles)
              _LockedStyleHint(
                key: ValueKey('trailStyleLockedHint.${style.id}'),
                text: tr(localeCode, 'trailStyle.${style.id}.lockedHint'),
              ),
          ],
          const SizedBox(height: 12),
          // 選択スタイルに応じたサブフォームを 1 つだけ表示する。
          switch (trail.style) {
            TrailStyle.solid => _SolidColorPicker(
              localeCode: localeCode,
              selected: trail.solidColor,
              onSelected: trailController.selectSolid,
            ),
            TrailStyle.rainbow3 => _ThreeColorPicker(
              localeCode: localeCode,
              colors: trail.threeColors,
              onSelectedAt: trailController.selectThreeColorAt,
            ),
            TrailStyle.rainbowFull => _RainbowFullHint(localeCode: localeCode),
          },
          const SizedBox(height: 24),
          // なぞりの粒の「形」（コスメ・#4）。バッチ取得で解放する収集要素。
          Text(
            tr(localeCode, 'settings.trailShape'),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final shape in TrailShape.values)
                _ShapeChip(
                  shape: shape,
                  label: tr(localeCode, 'trailShape.${shape.id}'),
                  selected: trailShape == shape,
                  locked: !unlockedShapes.contains(shape),
                  onSelected: () => shapeController.select(shape),
                ),
            ],
          ),
          if (lockedShapes.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final shape in lockedShapes)
              _LockedStyleHint(
                key: ValueKey('trailShapeLockedHint.${shape.id}'),
                text: tr(localeCode, 'trailShape.${shape.id}.lockedHint'),
              ),
          ],
          const SizedBox(height: 16),
          // 試し描きキャンバス（#3）。選んだ色＋ブラシを実際になぞって確かめられる。
          const TrailPreview(),
        ],
      ),
    );
  }
}

/// トレイルスタイルの選択チップ。ロック中は🔒を出し、タップ不可にする。
class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.style,
    required this.label,
    required this.selected,
    required this.locked,
    required this.onSelected,
  });

  final TrailStyle style;
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    // キッズ UX 基準: 最小 60x60 dp のタップターゲットを保証する。
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: _kMinTapTarget,
        minHeight: _kMinTapTarget,
      ),
      child: ChoiceChip(
        key: ValueKey('trailStyle.${style.id}'),
        avatar: locked
            ? const Icon(Icons.lock_outline, size: 18, color: Colors.black54)
            : null,
        label: Text(label),
        selected: selected,
        // ロック中は onSelected:null で選択不可（失敗を罰しない＝無反応で十分）。
        onSelected: locked ? null : (_) => onSelected(),
      ),
    );
  }
}

/// トレイルの粒の「形」選択チップ（#4）。ロック中は🔒で選択不可。
class _ShapeChip extends StatelessWidget {
  const _ShapeChip({
    required this.shape,
    required this.label,
    required this.selected,
    required this.locked,
    required this.onSelected,
  });

  final TrailShape shape;
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onSelected;

  IconData get _icon => switch (shape) {
    TrailShape.circle => Icons.circle,
    TrailShape.star => Icons.star,
    TrailShape.heart => Icons.favorite,
    TrailShape.bubble => Icons.bubble_chart,
    TrailShape.flower => Icons.local_florist,
    TrailShape.neon => Icons.flare,
    TrailShape.ribbon => Icons.gesture,
    TrailShape.comet => Icons.mode_standby,
  };

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: _kMinTapTarget,
        minHeight: _kMinTapTarget,
      ),
      child: ChoiceChip(
        key: ValueKey('trailShape.${shape.id}'),
        avatar: Icon(
          locked ? Icons.lock_outline : _icon,
          size: 18,
          color: locked ? Colors.black54 : Colors.amber.shade700,
        ),
        label: Text(label),
        selected: selected,
        onSelected: locked ? null : (_) => onSelected(),
      ),
    );
  }
}

/// ロック中スタイルのやさしい解放ヒント（🔒 + 文言）。
class _LockedStyleHint extends StatelessWidget {
  const _LockedStyleHint({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

/// 単色トレイル色の選択（6 色チップ）。
class _SolidColorPicker extends StatelessWidget {
  const _SolidColorPicker({
    required this.localeCode,
    required this.selected,
    required this.onSelected,
  });

  final String localeCode;
  final TrailColorChoice selected;
  final ValueChanged<TrailColorChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final choice in TrailColorChoice.values)
          _TrailColorChip(
            choice: choice,
            label: tr(localeCode, 'trailColor.${choice.id}'),
            selected: selected == choice,
            onSelected: () => onSelected(choice),
          ),
      ],
    );
  }
}

/// なぞりトレイル色の選択チップ。スウォッチ + ラベルで読字に依存しない。
class _TrailColorChip extends StatelessWidget {
  const _TrailColorChip({
    required this.choice,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final TrailColorChoice choice;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    // キッズ UX 基準: 最小 60x60 dp のタップターゲットを保証する。
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: _kMinTapTarget,
        minHeight: _kMinTapTarget,
      ),
      child: ChoiceChip(
        key: ValueKey('trailColor.${choice.id}'),
        avatar: _ColorSwatch(color: choice.baseColor),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

/// にじ3色の選択（3 つのドロップダウン）。各位置を 6 色から選ぶ。重複可。
class _ThreeColorPicker extends StatelessWidget {
  const _ThreeColorPicker({
    required this.localeCode,
    required this.colors,
    required this.onSelectedAt,
  });

  final String localeCode;
  final List<TrailColorChoice> colors;

  /// (index, choice) で 3 色のうち index 番目を差し替える。
  final void Function(int index, TrailColorChoice choice) onSelectedAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(localeCode, 'trailColor.pick3'),
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ColorDropdown(
              slotIndex: i,
              label: tr(localeCode, 'trailColor.slot${i + 1}'),
              localeCode: localeCode,
              value: colors[i],
              onChanged: (choice) => onSelectedAt(i, choice),
            ),
          ),
      ],
    );
  }
}

/// 1 つの位置の色を選ぶドロップダウン（スウォッチ + 名前）。
class _ColorDropdown extends StatelessWidget {
  const _ColorDropdown({
    required this.slotIndex,
    required this.label,
    required this.localeCode,
    required this.value,
    required this.onChanged,
  });

  final int slotIndex;
  final String label;
  final String localeCode;
  final TrailColorChoice value;
  final ValueChanged<TrailColorChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: _kDropdownLabelWidth, child: Text(label)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: _kMinTapTarget),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<TrailColorChoice>(
              key: ValueKey('trail3.slot$slotIndex'),
              value: value,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              // タップターゲットを 60dp 以上に保つ。
              itemHeight: _kMinTapTarget,
              items: [
                for (final choice in TrailColorChoice.values)
                  DropdownMenuItem<TrailColorChoice>(
                    value: choice,
                    child: Row(
                      children: [
                        _ColorSwatch(color: choice.baseColor),
                        const SizedBox(width: 8),
                        Text(tr(localeCode, 'trailColor.${choice.id}')),
                      ],
                    ),
                  ),
              ],
              onChanged: (choice) {
                if (choice != null) onChanged(choice);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// にじフルの説明（追加設定なし）。
class _RainbowFullHint extends StatelessWidget {
  const _RainbowFullHint({required this.localeCode});

  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 虹を象徴する小さなグラデーション円。
        Container(
          width: _kSwatchSize,
          height: _kSwatchSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Color(0xFFFF0000),
                Color(0xFFFFFF00),
                Color(0xFF00FF00),
                Color(0xFF00FFFF),
                Color(0xFF0000FF),
                Color(0xFFFF00FF),
                Color(0xFFFF0000),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(tr(localeCode, 'trailStyle.rainbowFull.hint')),
      ],
    );
  }
}

/// 色スウォッチ（円 + 薄いフチ）。淡色でも背景に埋もれないよう枠を付ける。
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kSwatchSize,
      height: _kSwatchSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}
