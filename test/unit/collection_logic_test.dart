import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/collection/collection_logic.dart';
import 'package:kidsapp_treasurehunt/features/collection/models/collection_world.dart';

const _worlds = [
  CollectionWorld(
    sceneId: 'scene01',
    titleKey: 'k1',
    iconIds: ['apple', 'duck', 'star'],
  ),
  CollectionWorld(
    sceneId: 'scene02',
    titleKey: 'k2',
    iconIds: ['ball', 'flower'],
  ),
];

void main() {
  test('counts discovered against the total across all worlds', () {
    final p = collectionProgressOf(_worlds, {'scene01:apple', 'scene02:ball'});
    expect(p.found, 2);
    expect(p.total, 5);
    expect(p.isComplete, isFalse);
  });

  test('empty discovered => 0 found, not complete', () {
    final p = collectionProgressOf(_worlds, const {});
    expect(p.found, 0);
    expect(p.total, 5);
    expect(p.isComplete, isFalse);
  });

  test('all entries discovered => complete', () {
    final p = collectionProgressOf(_worlds, {
      'scene01:apple',
      'scene01:duck',
      'scene01:star',
      'scene02:ball',
      'scene02:flower',
    });
    expect(p.found, 5);
    expect(p.total, 5);
    expect(p.isComplete, isTrue);
  });

  test('unrelated discovered entries do not inflate the count', () {
    // 図鑑カタログに無いエントリ（別ワールドや過去データ）は数えない。
    final p = collectionProgressOf(_worlds, {'scene99:gem', 'scene01:apple'});
    expect(p.found, 1);
    expect(p.total, 5);
  });

  test('no worlds => not complete (guards div-by-zero feel)', () {
    final p = collectionProgressOf(const [], const {});
    expect(p.total, 0);
    expect(p.isComplete, isFalse);
  });
}
