import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/features/badges/badge_service.dart';
import 'package:kidsapp_treasurehunt/features/badges/models/badge.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/dummy_item.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/rare_treasure.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_ambient_variant.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_interaction.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/treasure_category.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/scene_background.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/scene_covers.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/scene_decoys.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/celebration_overlay.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/clear_overlay.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/collection_bar.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/hint_glow.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/interaction_toggle.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/miss_bubble.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/quest_banner.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/target_view.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/treasure_glyph.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/trail_sparkle.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/save_slots_catalog.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// 操作が無いまま何秒経過したら未発見の宝を 1 つヒント点滅させるか
/// （アイドル時のみ。タップ/なぞりのたびにカウントはリセットされ、急かさない）。
const Duration _kHintIdleDelay = Duration(seconds: 8);

/// 上部ストリップ（お題バナー / 操作トグル）の予約高さ。クリアで中身が消えても
/// この高さを常に確保し、シーン領域が縦にズレないようにする。
const double _kTopStripHeight = 80.0;

/// なぞりキラキラを生成する最小移動距離（px）。これ未満の移動では粒を足さず、
/// 粒の密集（描画負荷とちらつき）を抑える。
const double _kTrailSpawnMinDistance = 18.0;

/// 同時に保持するなぞりキラキラの上限。超えたら最古から捨てる
/// （連続ドラッグでも生存ウィジェット数を一定に保つ安全弁）。
const int _kTrailMaxParticles = 24;

/// 正規化 Rect（0.0–1.0）をシーンの実ピクセルへ変換した [Positioned] を作る。
/// 宝とダミーで共通の配置ロジック。[rect] は呼び出し側で
/// [scaledTreasureRect] 済みの矩形を渡す（拡大不要なときのみ素の正規化 Rect）。
Positioned _positioned(Rect rect, Size sceneSize, {required Widget child}) {
  return Positioned(
    left: rect.left * sceneSize.width,
    top: rect.top * sceneSize.height,
    width: rect.width * sceneSize.width,
    height: rect.height * sceneSize.height,
    child: child,
  );
}

class SeekFindScreen extends ConsumerWidget {
  const SeekFindScreen({
    super.key,
    required this.sceneId,
    this.mode = GameMode.easy,
  });

  final String sceneId;
  final GameMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sceneAsync = ref.watch(sceneProvider(sceneId));
    // 3 モードとも最初から選べるため、URL のモードをそのまま採用する
    // （難易度はおとり量・探索エリアの広さ・点滅で表現し、宝の数は不変）。
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/'))),
      body: sceneAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error: $e')),
        // key にシーン id ＋モードを含め、万一 _SceneView が同じ位置で別シーン/
        // モードに差し替わっても State（_scene の 1 回シャッフル等）が確実に
        // 作り直されるようにする（将来 PageView 等で再利用される場合の保険）。
        data: (scene) => _SceneView(
          key: ValueKey('${scene.id}-${mode.name}'),
          scene: scene,
          mode: mode,
        ),
      ),
    );
  }
}

class _SceneView extends ConsumerStatefulWidget {
  const _SceneView({super.key, required this.scene, required this.mode});

  final SceneDef scene;
  final GameMode mode;

  @override
  ConsumerState<_SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends ConsumerState<_SceneView>
    with TickerProviderStateMixin {
  /// 実際に描画するシーン。クリア済みの再訪やフリーモードでは入場時に配置を
  /// シャッフルして「毎回ちがう場所」にする（C1）。初回（未クリア）は安定配置のまま。
  late final SceneDef _scene = _maybeShuffleOnReplay();

  /// 季節/時間バリアント（C3）。再訪/フリーで抽選、初回は normal（素のまま）。
  late final SceneAmbientVariant _ambient = _isReplay()
      ? pickAmbientVariant(math.Random())
      : SceneAmbientVariant.normal;

  bool _completed = false;

  /// 発見したレア宝の icon id（非 null の間、専用リビール演出を最前面に出す）。
  String? _rareReveal;

  /// クリアで新規取得した称号バッチ id のキュー（先頭から 1 つずつ祝福する）。
  final List<String> _badgeQueue = [];

  final List<({Offset position, Key key})> _missBubbles = [];

  /// 連続発見（連鎖）数。発見で +1、空振りで 0 に戻す（A5）。
  /// 罰しない: 途切れても減点・不快音は出さず、静かにリセットするだけ。
  int _streak = 0;

  /// 宝 id → 発見時のバースト派手さ。連鎖（A5）と「最後の 1 個」（B6）を反映。
  final Map<String, double> _burstIntensity = {};

  /// なぞった指先に追従するキラキラ粒子（Easy のみ）。MissBubble と同じく
  /// リストで管理し、各粒は時間経過で自己消滅する。
  final List<({Offset position, Key key, Color color})> _trailSparkles = [];

  /// 直近にキラキラを生成した位置。null は「このなぞりの最初の 1 粒」を表す。
  Offset? _lastTrailSpawn;

  /// 生成済み粒の通し番号。色解決の particleIndex に渡す（にじ拡張の種）。
  int _trailSeq = 0;

  final math.Random _random = math.Random();
  Timer? _hintTimer;
  Timer? _hintClearTimer;
  String? _hintingId;

  /// ハードモードの宝点滅を駆動する共有クロック（0.0–1.0 を周期反復）。
  /// 通常モードでは生成せず null のまま（点滅なし）。
  AnimationController? _blinkClock;

  /// 未発見アイテムのアイドル揺れを駆動する共有クロック（全モード共通・低速反復）。
  /// 1 本のクロックを全アイテムで共有し、位相だけずらして同期を外す。
  late final AnimationController _idleClock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();

  /// 発見状態のキー。モード間で発見が混ざらないようモードごとに名前空間化する
  /// （Easy はレガシー互換のため素の sceneId）。これは画面セッション内の
  /// インメモリ状態（`foundControllerProvider`）専用で、永続キーとは別物。
  /// `foundControllerProvider` は autoDispose のため画面を離れると破棄され、
  /// Easy↔Normal を行き来しても Easy の素の sceneId が Normal の値を引かない。
  // 発見状態キーはルートの安定アイデンティティ（widget.scene.id）に紐づける。
  // _scene は配置シャッフル後の表示用で id は不変だが、ここで _scene を使うと
  // 「発見状態の名前空間」と「シャッフル表示」が不要に結合するため使わない。
  String get _foundKey => switch (widget.mode) {
    GameMode.easy => widget.scene.id,
    GameMode.normal => '${widget.scene.id}#normal',
    GameMode.hard => '${widget.scene.id}#hard',
  };

  /// Normal / Hard はビューポートより大きい探索エリア（パン必須）。
  bool get _isLargeArea => widget.mode != GameMode.easy;

  /// 大エリアでの 1 本指ドラッグの用途（地図を動かす / なぞって探す）。
  /// 既定は [SceneInteraction.move]: まず地図を見渡せて、タップ発見は常に可能。
  /// Easy ではトグルを出さず、常になぞり（[dragBehaviorFor] が吸収）。
  SceneInteraction _interaction = SceneInteraction.move;

  /// 再訪（クリア済み）またはフリーモードなら配置をシャッフルし、初回は
  /// 作者の安定配置のまま返す（C1）。入場ごとに新しい乱数 → 毎回ちがう配置。
  /// 再訪（クリア済み）またはフリーモードか。配置シャッフル(C1)・おとり抽選(C2)・
  /// 季節バリアント(C3)・レア宝(C4) はすべて「再訪/フリーのときだけ」発動し、
  /// 初回（未クリア）は作者の安定配置・素の見た目のままにする。
  bool _isReplay() {
    final activeSlot = ref.read(activeSlotProvider);
    if (activeSlot == null) {
      return false; // スロット未選択（通常起こらない）
    }
    if (activeSlot == kFreeModeSlotId) {
      return true;
    }
    return ref
        .read(progressRepositoryProvider)
        .isCleared(widget.mode, widget.scene.id);
  }

  SceneDef _maybeShuffleOnReplay() {
    final replay = _isReplay();
    final hard = widget.mode == GameMode.hard;
    final random = math.Random();
    var scene = widget.scene;
    // 配置スキャッタ(C1+ジッター)。Hard は初回から、Easy/Normal はリプレイで適用し
    // 「規則正しさ」を崩す（要望[1]）。初回 Easy/Normal は作者の安定配置を維持。
    if (replay || hard) {
      scene = scene.withShuffledPositions(random);
    }
    // おとり抽選(C2) は再訪/フリーのみ（初回の見た目は変えない）。
    if (replay) {
      scene = scene.withReseededDecoyIcons(
        random,
        sourcePool: decoyPoolFor(widget.scene.id),
      );
    }
    // 低確率レア宝(C4) は全エントリで常時ロール（初回プレイ含む・要望[1]）。
    // 出れば必ず見つけられる位置（ダミー枠を借用）で no-fail。毎回必ずは出さない。
    if (random.nextDouble() < kRareTreasureChance) {
      scene = scene.withRareTreasure(pickRare(random), random);
    }
    // テーマ別カバー(A1 箱隠し)を常時適用し、出現率を底上げ（要望[2][3]）。
    // ステージのイメージに合う複数種から各ターゲットへ確率で被せる。
    scene = scene.withThemedCovers(
      coversForScene(widget.scene.id),
      random,
      kThemedCoverChance,
    );
    return scene;
  }

  @override
  void initState() {
    super.initState();
    if (widget.mode == GameMode.hard) {
      _blinkClock = AnimationController(
        vsync: this,
        duration: kBlinkCyclePeriod,
      )..repeat();
    }
    _scheduleHint();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _hintClearTimer?.cancel();
    _blinkClock?.dispose();
    _idleClock.dispose();
    super.dispose();
  }

  /// ハードモードでこの宝（[index] 番目）を点滅させるか。
  /// 未発見かつヒント中でないこと、さらに未発見が 2 つ以上あることが条件。
  /// 残り 1 つになったら点滅を止めて常時表示＋常時押せるようにし、「待たないと
  /// 何も押せない」時間帯を作らない（手詰まり防止）。描画と当たり判定の双方が
  /// この同じ条件を参照することで「見えている＝押せる」を保つ。
  bool _isBlinking(int index, Set<String> found, int unfoundCount) {
    if (_blinkClock == null || unfoundCount <= 1) {
      return false;
    }
    final t = _scene.targets[index];
    return !found.contains(t.id) && t.id != _hintingId;
  }

  /// ハード点滅で「今まさに消えている」未発見ターゲットの id 集合。
  /// 通常モード（クロック無し）や、ヒント中の宝（強制可視）、残り 1 つの宝
  /// （[_isBlinking] が false）は含めない。
  Set<String> _hiddenTargetIds(Set<String> found) {
    final clock = _blinkClock?.value;
    if (clock == null) {
      return const {};
    }
    final targets = _scene.targets;
    final unfoundCount = targets.where((t) => !found.contains(t.id)).length;
    final hidden = <String>{};
    for (var i = 0; i < targets.length; i++) {
      final t = targets[i];
      if (!_isBlinking(i, found, unfoundCount)) {
        continue;
      }
      final opacity = treasureBlinkOpacity(
        slot: i,
        count: targets.length,
        clock: clock,
      );
      if (opacity < kBlinkVisibleThreshold) {
        hidden.add(t.id);
      }
    }
    return hidden;
  }

  /// アイドル計測を仕切り直す。タップ/なぞりのたびに呼ばれ、操作中はヒントを出さない。
  void _scheduleHint() {
    _hintTimer?.cancel();
    _hintTimer = Timer(_kHintIdleDelay, _showHint);
  }

  void _showHint() {
    if (!mounted || _completed || _hintingId != null) {
      return;
    }
    final found = ref.read(foundControllerProvider(_foundKey));
    final id = pickHintTargetId(
      targets: _scene.targets,
      foundIds: found,
      random: _random,
    );
    if (id == null) {
      return; // 全て発見済み: 再スケジュールせず自然に停止
    }
    setState(() => _hintingId = id);
    _hintClearTimer?.cancel();
    _hintClearTimer = Timer(kHintGlowDuration, () {
      if (mounted) {
        setState(() => _hintingId = null);
        _scheduleHint(); // 光が消えたら、次のアイドル待ちを再開
      }
    });
  }

  void _addMissBubble(Offset position) {
    final key = UniqueKey();
    setState(() {
      _missBubbles.add((position: position, key: key));
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _missBubbles.removeWhere((b) => b.key == key);
        });
      }
    });
  }

  /// その座標が「おとり」の上か（#6 つつき反応の判定）。
  bool _pokedDecoy(Offset localPosition, Size sceneSize) {
    final normalized = Offset(
      localPosition.dx / sceneSize.width,
      localPosition.dy / sceneSize.height,
    );
    for (final d in decoysForMode(_scene, widget.mode)) {
      if (scaledTreasureRect(
        d.normalizedRect,
        itemScale: d.scale,
      ).contains(normalized)) {
        return true;
      }
    }
    return false;
  }

  /// おとりを「つついた」位置に、ごほうびのきらめきを 1 つ出す（#6）。
  void _addPokeSparkle(Offset position) {
    final key = UniqueKey();
    setState(() {
      _trailSparkles.add((
        position: position,
        key: key,
        color: Colors.amber.shade400,
      ));
      if (_trailSparkles.length > _kTrailMaxParticles) {
        _trailSparkles.removeAt(0);
      }
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _trailSparkles.removeWhere((s) => s.key == key));
      }
    });
  }

  /// なぞり位置に追従するキラキラ粒子を 1 つ生成する（Easy のなぞり中のみ呼ぶ）。
  /// 直近生成位置から [_kTrailSpawnMinDistance] 未満なら間引いて密集を防ぐ。
  void _handlePanTrail(Offset position) {
    final last = _lastTrailSpawn;
    if (last != null && (position - last).distance < _kTrailSpawnMinDistance) {
      return;
    }
    _lastTrailSpawn = position;
    final setting = ref.read(trailSettingControllerProvider);
    final color = resolveTrailColor(setting, particleIndex: _trailSeq);
    _trailSeq++;
    final key = UniqueKey();
    setState(() {
      _trailSparkles.add((position: position, key: key, color: color));
      // 上限を超えたら最古を捨てる（生存ウィジェット数の上限を保証）。
      if (_trailSparkles.length > _kTrailMaxParticles) {
        _trailSparkles.removeAt(0);
      }
    });
    unawaited(
      Future.delayed(const Duration(milliseconds: 550), () {
        if (mounted) {
          setState(() => _trailSparkles.removeWhere((s) => s.key == key));
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final found = ref.watch(foundControllerProvider(_foundKey));
    final unfoundCount = scene.targets
        .where((t) => !found.contains(t.id))
        .length;
    // お題発見（A3）: 今さがすカテゴリ（ソフトガイド・無ければ非表示）。
    final questCategory = nextQuestCategory(scene.targets, found);
    final questTarget = nextQuestTarget(scene.targets, found);

    // 完了は「画面上の全宝（レア宝 C4 を含む _scene.targets）を見つけたら」。
    // レアは出れば必ず見つけられる位置にあり、完了に含めることで確実に図鑑へ
    // 記録される。レアは `cleared || isFree` のときだけ出るので、取り逃しても
    // クリア済みフラグは維持され（un-clear しない）進行・100% 判定にも影響しない。
    ref.listen(foundControllerProvider(_foundKey), (previous, next) {
      final wasComplete = (previous?.length ?? 0) >= scene.targets.length;
      final nowComplete = next.length >= scene.targets.length;
      if (!wasComplete && nowComplete) {
        unawaited(_handleComplete(scene.id));
      }
    });

    return Stack(
      children: [
        Column(
          children: [
            // シーン外の上部ストリップ（1 段にまとめる）: お題発見（A3）の
            // 「○○ を さがそう」ガイドと、大エリアの「うごかす / さがす」トグル。
            // Wrap で横並び＋反流させ、縦の圧迫と（重ねた場合の）タップ吸収を避ける。
            // Stack に重ねないのはピル下のターゲットへのタップ吸収を防ぐため。
            // 高さは常に [_kTopStripHeight] を確保する。中身（お題/トグル）が
            // クリアや発見で出入りしても、シーン領域が縦にズレないようにするため。
            SizedBox(
              height: _kTopStripHeight,
              child:
                  (!_completed &&
                      ((questCategory != null && questTarget != null) ||
                          _isLargeArea))
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (questCategory != null && questTarget != null)
                            QuestBanner(
                              key: const ValueKey('quest-banner'),
                              iconId: questTarget.iconId,
                              category: questCategory,
                              localeCode: localeCode,
                            ),
                          if (_isLargeArea)
                            InteractionToggle(
                              interaction: _interaction,
                              localeCode: localeCode,
                              onChanged: (i) =>
                                  setState(() => _interaction = i),
                            ),
                        ],
                      ),
                    )
                  : null,
            ),
            Expanded(child: _buildSceneArea(found, unfoundCount)),
            CollectionBar(targets: scene.targets, foundIds: found),
          ],
        ),
        if (_completed)
          ClearOverlay(localeCode: localeCode, onBack: () => context.go('/')),
        // レア宝のリビール（A-2）。クリアと同時でも最前面で先に祝福する。
        if (_rareReveal != null)
          CelebrationOverlay(
            icon: TreasureGlyph(iconId: _rareReveal!, found: true),
            title: tr(localeCode, 'rare.found'),
            subtitle: tr(localeCode, 'rare.${_rareReveal!.substring(5)}'),
            onDismiss: () => setState(() => _rareReveal = null),
          ),
        // 称号バッチ取得の祝福（B-3）。キュー先頭を 1 つずつ。最前面。
        if (_badgeQueue.isNotEmpty)
          CelebrationOverlay(
            key: ValueKey('badge.${_badgeQueue.first}'),
            icon: SvgPicture.asset(
              badgeSvgAsset(kBadgeById[_badgeQueue.first]!.iconId),
            ),
            title: tr(localeCode, 'badge.earned'),
            subtitle: tr(localeCode, kBadgeById[_badgeQueue.first]!.labelKey),
            onDismiss: () => setState(() => _badgeQueue.removeAt(0)),
          ),
      ],
    );
  }

  /// シーン本体（ジェスチャ + 背景 + おとり/宝 + 演出オーバーレイ）を組む。
  /// ビューポートより広い論理キャンバスを敷き、Normal/Hard では
  /// [InteractiveViewer] でパン/拡大できるようにする。タップ発見は常に有効。
  Widget _buildSceneArea(Set<String> found, int unfoundCount) {
    final scene = _scene;
    // なぞり/つつきのきらめきの形（コスメ・#4）。
    final trailShape = ref.watch(trailShapeControllerProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        // Normal / Hard はビューポートより広い論理キャンバスにして、
        // パンで表示部分をずらさないと全体が見えないようにする。
        final sceneSize = _isLargeArea
            ? Size(
                viewport.width * kLargeAreaFactor,
                viewport.height * kLargeAreaFactor,
              )
            : viewport;
        final decoys = decoysForMode(scene, widget.mode);
        // ドラッグの割り当て（パン or なぞり）。タップ発見は別途常に有効。
        final drag = dragBehaviorFor(widget.mode, _interaction);
        final content = GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Easy は押した瞬間に発見（パン競合が無いので onTapDown）。
          // 大エリアは onTapUp（タップ確定時のみ）にして、地図パンの
          // 指タッチで誤発見しないようにする（Bug B: ずらしと発見の分離）。
          onTapDown: _isLargeArea
              ? null
              : (d) => _handleHit(d.localPosition, sceneSize),
          onTapUp: _isLargeArea
              ? (d) => _handleHit(d.localPosition, sceneSize)
              : null,
          // なぞって探す。なぞり中はミスバブルを出さず、代わりに色付き
          // キラキラを追従させる。大エリアでは「さがす」モードのみ有効。
          onPanStart: drag.traceEnabled
              ? (d) {
                  _lastTrailSpawn = null; // 新しいなぞりの開始
                  // にじは各なぞりを先頭の色相から始める（境界の肥大も防ぐ）。
                  _trailSeq = 0;
                  _handleHit(d.localPosition, sceneSize, allowMiss: false);
                  _handlePanTrail(d.localPosition);
                }
              : null,
          onPanUpdate: drag.traceEnabled
              ? (d) {
                  _handleHit(d.localPosition, sceneSize, allowMiss: false);
                  _handlePanTrail(d.localPosition);
                }
              : null,
          child: SizedBox(
            width: sceneSize.width,
            height: sceneSize.height,
            child: Stack(
              key: const ValueKey('scene-content'),
              fit: StackFit.expand,
              children: [
                sceneBackground(scene.id),
                // 季節/時間バリアント（C3）: 背景の上・宝の下に半透明
                // ティントを 1 枚。IgnorePointer でタップを邪魔しない。
                if (_ambient.tint != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(color: _ambient.tint!),
                    ),
                  ),
                for (var i = 0; i < decoys.length; i++)
                  _positioned(
                    scaledTreasureRect(
                      decoys[i].normalizedRect,
                      itemScale: decoys[i].scale,
                    ),
                    sceneSize,
                    // Hard ではおとりも点滅させる（ヒット判定外なので
                    // 見た目の不透明度のみ。宝とは別カウントで位相を
                    // ずらし、全部が同時に消えないようにする）。
                    child: _buildDecoy(decoys[i], i, decoys.length),
                  ),
                for (var i = 0; i < scene.targets.length; i++)
                  _buildTarget(i, sceneSize, found, unfoundCount),
                for (final b in _missBubbles)
                  MissBubble(key: b.key, position: b.position),
                for (final s in _trailSparkles)
                  TrailSparkle(
                    key: s.key,
                    position: s.position,
                    color: s.color,
                    shape: trailShape,
                  ),
              ],
            ),
          ),
        );
        if (!_isLargeArea) {
          return content;
        }
        // 「うごかす」= 1 本指パン＋ピンチ拡大。「なぞる」= パン/拡大とも
        // 無効にして単一指のなぞりに専念させる（2 本指がなぞり開始と競合して
        // 誤発見するのを防ぐ）。拡大率は move で設定した値が保持される。
        return InteractiveViewer(
          constrained: false,
          minScale: 1.0,
          maxScale: kLargeAreaMaxScale,
          panEnabled: drag.panEnabled,
          scaleEnabled: drag.panEnabled,
          child: content,
        );
      },
    );
  }

  /// 1 つの宝を配置する。ハードモードで [_isBlinking] が真の宝だけ点滅させる。
  Widget _buildTarget(
    int index,
    Size sceneSize,
    Set<String> found,
    int unfoundCount,
  ) {
    final t = _scene.targets[index];
    final clock = _blinkClock;
    final blinking = _isBlinking(index, found, unfoundCount);
    final view = TargetView(
      key: ValueKey(t.id),
      iconId: t.iconId,
      found: found.contains(t.id),
      hinting: _hintingId == t.id,
      burstIntensity: _burstIntensity[t.id] ?? 1.0,
      coverIconId: t.coverIconId,
      // 点滅中は揺らさない（動きの重複を避ける）。それ以外はアイドル揺れ。
      idleClock: blinking ? null : _idleClock,
      idlePhase: _idlePhaseFor(t.id),
    );
    return _positioned(
      scaledTreasureRect(t.normalizedRect),
      sceneSize,
      child: clock == null || !blinking
          ? view
          : BlinkingTarget(
              clock: clock,
              slot: index,
              count: _scene.targets.length,
              child: view,
            ),
    );
  }

  /// おとり 1 つの見た目。Hard（[_blinkClock] が非 null）ではおとりも点滅させる。
  /// おとりはヒット判定の対象外なので、当たり判定（[_hiddenTargetIds]）には
  /// 影響しない（消えていても元々押せない）。位相は [slot]/[count] でずらす。
  Widget _buildDecoy(DummyItem decoy, int slot, int count) {
    final clock = _blinkClock;
    final view = TargetView(
      iconId: decoy.iconId,
      found: false,
      // Hard は点滅させるのでアイドル揺れは無し。Easy/Normal は静止でなく微揺れ。
      idleClock: clock == null ? _idleClock : null,
      idlePhase: _idlePhaseFor(decoy.id),
    );
    if (clock == null) {
      return view; // Easy/Normal: おとりは点滅せずアイドル揺れのみ
    }
    return BlinkingTarget(clock: clock, slot: slot, count: count, child: view);
  }

  /// アイテム id から安定したアイドル位相（0..1）を作る。これで全アイテムが
  /// 同期して揺れず、ばらけて「生きている」見え方になる。
  double _idlePhaseFor(String id) => (id.hashCode & 0x7fffffff) % 1000 / 1000.0;

  Future<void> _handleComplete(String sceneId) async {
    if (_completed) return; // 二重発火ガード（連続通知でも完了処理は一度だけ）
    // await をまたいで ref を触らないよう、必要な依存は先に読み出しておく
    // （途中で破棄されても disposed-ref で落ちない）。
    final progress = ref.read(progressRepositoryProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final audio = ref.read(audioServiceProvider);
    await completeScene(progress, widget.mode, sceneId);
    // 難易度を全クリアしたらトレイルスタイルを解放する（端末ぜんたい・sticky）。
    await syncTrailUnlocks(progress, settings);
    await audio.playComplete();
    if (!mounted) return; // 完了演出の前に画面が破棄されていたら何もしない
    // 解放状態を即時反映（設定画面を開き直さなくても新スタイルが使える）。
    ref.invalidate(unlockedTrailStylesProvider);
    _hintTimer?.cancel();
    _blinkClock?.stop(); // 完了後は点滅を止める（全て発見済みなので不要）
    setState(() => _completed = true);
    // 称号バッチ(B-3): クリアで満たした条件を評価し、新規取得を祝福キューへ積む。
    unawaited(
      evaluateAndGrantBadges(ref)
          .then((newly) {
            if (!mounted || newly.isEmpty) return;
            setState(() {
              _badgeQueue.addAll(
                kBadgeCatalog
                    .where((b) => newly.contains(b.id))
                    .map((b) => b.id),
              );
            });
          })
          .catchError((Object e) {
            debugPrint('badge eval failed: $e');
          }),
    );
  }

  /// [allowMiss] が false のとき（なぞり中）はミスバブルを出さない。
  /// なぞりの視覚フィードバックは色付きキラキラ（[_handlePanTrail]）が担うため。
  void _handleHit(
    Offset localPosition,
    Size sceneSize, {
    bool allowMiss = true,
  }) {
    _scheduleHint(); // 操作があった = アイドルではない。ヒント待ちをリセット
    final scene = _scene;
    final found = ref.read(foundControllerProvider(_foundKey));
    final hidden = _hiddenTargetIds(found);
    final hitId = findHitTargetId(
      scenePoint: localPosition,
      sceneSize: sceneSize,
      targets: scene.targets,
      foundIds: found,
      hiddenIds: hidden,
    );
    if (hitId == null) {
      // 消失中の宝の上をタップしたときは無反応（罰なし）。
      final onHidden = isPointOnHiddenTarget(
        scenePoint: localPosition,
        sceneSize: sceneSize,
        targets: scene.targets,
        hiddenIds: hidden,
      );
      if (allowMiss && !onHidden) {
        if (_pokedDecoy(localPosition, sceneSize)) {
          // #6 イースターエッグ: おとりを「つつく」と、罰でなく ちいさなきらめき＋
          // 触覚で反応する。世界が反応する楽しさ。連鎖は崩さない（中立な遊び）。
          _addPokeSparkle(localPosition);
          HapticFeedback.selectionClick();
        } else {
          // 空の場所だけミスバブル。タップの空振りでのみ連鎖が途切れる。
          // 静かにリセットするだけで、減点・不快音・×は出さない（no-fail 厳守）。
          _addMissBubble(localPosition);
          _streak = 0;
        }
      }
      return;
    }
    // 連鎖を伸ばし、発見バーストの派手さを決める（A5）。最後の 1 個なら
    // 連鎖上限より豪華な「グランドフィナーレ」にする（B6）。
    _streak++;
    final foundCountAfter = found.length + 1;
    final isFinalFind = foundCountAfter >= scene.targets.length;
    final intensity = isFinalFind
        ? kGrandFinaleBurstIntensity
        : comboBurstScale(_streak);
    // 重要: FoundBurst は intensity を生成時に固定するため、markFound による
    // 再構築で burst が初めて現れる「前」に派手さを記録しておく（順序を逆にすると
    // 既定の 1.0 で構築され、後から変えても走行中のバーストは変わらない）。
    // markFound が foundControllerProvider を更新して再構築を起こすので setState 不要。
    _burstIntensity[hitId] = intensity;
    ref.read(foundControllerProvider(_foundKey).notifier).markFound(hitId);
    HapticFeedback.lightImpact();
    ref.read(audioServiceProvider).playFound();
    // 図鑑（コレクション）に永続記録する（ワールド×アイコン・モード非依存）。
    // sceneId はルートの安定 id を使う（_foundKey と同じ方針）。発見演出は既に
    // 出ているので fire-and-forget だが、書き込み失敗は握り潰さずログする。
    final hitIcon = scene.targets.firstWhere((t) => t.id == hitId).iconId;
    unawaited(
      ref
          .read(collectionRepositoryProvider)
          .record(widget.scene.id, hitIcon)
          .catchError((Object e) {
            debugPrint('collection record failed: $e');
            return false;
          }),
    );
    // レア宝(A-2): 専用リビール演出を最前面に出す（climax）。
    if (isRareIcon(hitIcon)) {
      setState(() => _rareReveal = hitIcon);
    }
  }
}
