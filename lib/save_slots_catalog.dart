import 'package:flutter/material.dart';

/// セーブスロットの静的定義（固定 3 枠・固定アバター。実画像は後で差し替え）。
class SaveSlot {
  const SaveSlot(this.id, this.avatar);
  final String id;
  final IconData avatar;
}

const List<SaveSlot> kSaveSlots = [
  SaveSlot('slot1', Icons.pets),
  SaveSlot('slot2', Icons.cruelty_free),
  SaveSlot('slot3', Icons.flutter_dash),
];

/// フリーモード（全マップ解放モード）専用スロット id。
/// 3 つの実スロットとは進捗キーの名前空間が独立する（`progress.free.*`）。
const String kFreeModeSlotId = 'free';
