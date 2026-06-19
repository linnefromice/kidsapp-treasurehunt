/// セーブスロットの静的定義（固定 3 枠）。
///
/// アバターは固定アイコンをやめ、開始時に子どもが選んだ絵文字を
/// スロットごとに永続化して表示する（[kAvatarEmojis] から選択）。
class SaveSlot {
  const SaveSlot(this.id);
  final String id;
}

const List<SaveSlot> kSaveSlots = [
  SaveSlot('slot1'),
  SaveSlot('slot2'),
  SaveSlot('slot3'),
];

/// アバターとして選べる絵文字のホワイトリスト。
///
/// 5〜11 歳向けにキュレーションした安全な絵文字のみ（動物・顔・自然・乗り物）。
/// フル絵文字ピッカーは武器・国旗など不適切な絵文字も露出するため、
/// あえて固定リストから選ばせる（完全オフライン・依存追加なし）。
const List<String> kAvatarEmojis = [
  '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', //
  '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', //
  '🐷', '🐸', '🐵', '🐔', '🐧', '🐦', //
  '🦄', '🐝', '🦋', '🐢', '🐬', '🐙', //
  '⭐', '🌈', '🌸', '🍓', '🍎', '🚀', //
];

/// 旧データ（この機能以前に作られたスロット）にアバターが無い場合の既定値。
const String kDefaultAvatar = '⭐';

/// フリーモード（全マップ解放モード）専用スロット id。
/// 3 つの実スロットとは進捗キーの名前空間が独立する（`progress.free.*`）。
const String kFreeModeSlotId = 'free';
