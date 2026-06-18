# 宝アイコン ビジュアル改善設計書

- 日付: 2026-06-18
- ステータス: 設計確定

---

## 1. 目的

シーン内の宝アイコンを「白い円板メダリオンに小さいアイコン」から
「色鮮やかな大アイコンそのもの」に刷新する。
タップエリアは視覚的アイコンに近いサイズに縮小し、誤タップを減らす。

---

## 2. 変更まとめ

| 項目 | 変更前 | 変更後 |
|------|--------|--------|
| タップ/配置 rect | `0.20×0.25`（scene01/02）/ `0.18×0.22`（scene03） | `0.13×0.16`（全シーン） |
| ダミー rect | `0.18×0.22` | `0.13×0.16` |
| 背景メダリオン | 白い円形 Container + ボーダー + 影 | **なし** |
| アイコン padding | `EdgeInsets.all(10)` | **なし**（rect を直接フィル） |
| 未発見アイコン色 | `Colors.brown.shade700` | **id ごとのビビッドカラー**（`targetColor(id)`） |
| 発見済みアイコン色 | `Colors.amber.shade700` | 同左（変更なし）+ `FoundBurst` |

---

## 3. ターゲット色テーブル（`targetColor`）

```dart
const Map<String, Color> _kTargetColors = {
  // 本物ターゲット
  'apple':   Color(0xFFE53935), // 赤
  'duck':    Color(0xFFFDD835), // 黄
  'star':    Color(0xFFFB8C00), // オレンジ
  'ball':    Color(0xFF1E88E5), // 青
  'flower':  Color(0xFFD81B60), // ピンク
  'heart':   Color(0xFFE91E63), // ピンク系赤
  // ダミー
  'leaf':     Color(0xFF43A047), // 緑
  'rabbit':   Color(0xFFAB47BC), // 紫
  'bug':      Color(0xFF00ACC1), // シアン
  'anchor':   Color(0xFF1565C0), // 濃青
  'swimmer':  Color(0xFF039BE5), // 水色
  'umbrella': Color(0xFFFF7043), // 珊瑚
  'car':      Color(0xFF546E7A), // ブルーグレー
  'key':      Color(0xFFFFB300), // 琥珀
};

Color targetColor(String id) =>
    _kTargetColors[id] ?? const Color(0xFF9E9E9E);
```

---

## 4. `_TargetView` 新仕様

```dart
class _TargetView extends StatelessWidget {
  const _TargetView({required this.icon, required this.color, required this.found});

  final IconData icon;
  final Color color;
  final bool found;

  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      FittedBox(
        fit: BoxFit.contain,
        child: Icon(icon, color: found ? Colors.amber.shade700 : color),
      ),
      if (found) const FoundBurst(),
    ],
  );
}
```

---

## 5. JSON rect 変更（全シーン・全ターゲット・全ダミー）

新サイズ: `"width": 0.13, "height": 0.16`（センター維持で縮小）

### scene01 ターゲット（センター維持）
| id | 旧 left/top | 新 left/top |
|----|------------|------------|
| apple | 0.07/0.12 | 0.105/0.16 |
| duck  | 0.57/0.27 | 0.605/0.315 |
| star  | 0.37/0.65 | 0.405/0.695 |

### scene02 ターゲット
| id     | 新 left/top |
|--------|------------|
| apple  | 0.125/0.195 |
| ball   | 0.625/0.235 |
| star   | 0.285/0.635 |
| flower | 0.705/0.655 |

### scene03 ターゲット
| id     | 新 left/top |
|--------|------------|
| apple  | 0.105/0.17  |
| duck   | 0.415/0.21  |
| star   | 0.725/0.19  |
| flower | 0.245/0.65  |
| heart  | 0.625/0.63  |

ダミーも同サイズに統一。センターは現行維持。

---

## 6. テスト方針

- `target_icons_test.dart`: `targetColor` の既知 id / 未知 id のテスト追加
- 既存 unit / widget テストが通ること（`bash scripts/check.sh` 全緑）
- ビジュアル確認は実機（iPad）で行う
