import 'package:audioplayers/audioplayers.dart';

/// 効果音再生の抽象。テストでは [SilentAudioService] を注入する。
abstract class AudioService {
  Future<void> playFound();
  Future<void> playComplete();
}

/// audioplayers 実装。アセット欠落や再生失敗で UI を止めないよう握りつぶす。
class AudioPlayersService implements AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> _safePlay(String asset) async {
    try {
      await _player.play(AssetSource(asset));
    } catch (_) {
      // 失敗しても無視(プレースホルダ音源 / 未バンドル時)
    }
  }

  @override
  Future<void> playFound() => _safePlay('sfx/found.wav');

  @override
  Future<void> playComplete() => _safePlay('sfx/complete.wav');
}

/// テスト・無音環境用。
class SilentAudioService implements AudioService {
  @override
  Future<void> playFound() async {}

  @override
  Future<void> playComplete() async {}
}
