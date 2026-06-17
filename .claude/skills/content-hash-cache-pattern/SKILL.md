---
name: content-hash-cache-pattern
description: Cache expensive file processing results using SHA-256 content hashes — path-independent, auto-invalidating, with service layer separation.
origin: ECC
---

# Content-Hash File Cache Pattern

高コストなファイル処理結果（PDF パース、テキスト抽出、画像分析）を、SHA-256 コンテンツハッシュをキャッシュキーとして使用してキャッシュします。パスベースのキャッシュとは異なり、このアプローチはファイルの移動/リネームに対応でき、コンテンツが変更されると自動的に無効化されます。

## 起動条件

- ファイル処理パイプライン（PDF、画像、テキスト抽出）を構築する場合
- 処理コストが高く、同じファイルが繰り返し処理される場合
- `--cache/--no-cache` CLI オプションが必要な場合
- 既存の純粋関数を変更せずにキャッシュを追加したい場合

## コアパターン

### 1. Content-Hash Based Cache Key

ファイルのパスではなくコンテンツをキャッシュキーとして使用します：

```python
import hashlib
from pathlib import Path

_HASH_CHUNK_SIZE = 65536  # 64KB chunks for large files

def compute_file_hash(path: Path) -> str:
    """SHA-256 of file contents (chunked for large files)."""
    if not path.is_file():
        raise FileNotFoundError(f"File not found: {path}")
    sha256 = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            chunk = f.read(_HASH_CHUNK_SIZE)
            if not chunk:
                break
            sha256.update(chunk)
    return sha256.hexdigest()
```

**なぜコンテンツハッシュなのか？** ファイルのリネーム/移動 = キャッシュヒット。コンテンツの変更 = 自動無効化。インデックスファイルは不要です。

### 2. Frozen Dataclass for Cache Entry

```python
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class CacheEntry:
    file_hash: str
    source_path: str
    document: ExtractedDocument  # The cached result
```

### 3. File-Based Cache Storage

各キャッシュエントリは `{hash}.json` として保存されます — ハッシュによる O(1) ルックアップで、インデックスファイルは不要です。

```python
import json
from typing import Any

def write_cache(cache_dir: Path, entry: CacheEntry) -> None:
    cache_dir.mkdir(parents=True, exist_ok=True)
    cache_file = cache_dir / f"{entry.file_hash}.json"
    data = serialize_entry(entry)
    cache_file.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")

def read_cache(cache_dir: Path, file_hash: str) -> CacheEntry | None:
    cache_file = cache_dir / f"{file_hash}.json"
    if not cache_file.is_file():
        return None
    try:
        raw = cache_file.read_text(encoding="utf-8")
        data = json.loads(raw)
        return deserialize_entry(data)
    except (json.JSONDecodeError, ValueError, KeyError):
        return None  # Treat corruption as cache miss
```

### 4. Service Layer Wrapper (SRP)

処理関数は純粋に保ちます。キャッシュは別のサービスレイヤーとして追加します。

```python
def extract_with_cache(
    file_path: Path,
    *,
    cache_enabled: bool = True,
    cache_dir: Path = Path(".cache"),
) -> ExtractedDocument:
    """Service layer: cache check -> extraction -> cache write."""
    if not cache_enabled:
        return extract_text(file_path)  # Pure function, no cache knowledge

    file_hash = compute_file_hash(file_path)

    # Check cache
    cached = read_cache(cache_dir, file_hash)
    if cached is not None:
        logger.info("Cache hit: %s (hash=%s)", file_path.name, file_hash[:12])
        return cached.document

    # Cache miss -> extract -> store
    logger.info("Cache miss: %s (hash=%s)", file_path.name, file_hash[:12])
    doc = extract_text(file_path)
    entry = CacheEntry(file_hash=file_hash, source_path=str(file_path), document=doc)
    write_cache(cache_dir, entry)
    return doc
```

## 主要な設計判断

| 判断 | 根拠 |
|----------|-----------|
| SHA-256 コンテンツハッシュ | パス非依存、コンテンツ変更時に自動無効化 |
| `{hash}.json` ファイル命名 | O(1) ルックアップ、インデックスファイル不要 |
| サービスレイヤーラッパー | SRP：抽出処理は純粋に保ち、キャッシュは別の関心事 |
| 手動 JSON シリアライズ | frozen dataclass のシリアライズを完全に制御 |
| 破損時は `None` を返す | グレースフルデグラデーション、次回実行時に再処理 |
| `cache_dir.mkdir(parents=True)` | 初回書き込み時の遅延ディレクトリ作成 |

## ベストプラクティス

- **パスではなくコンテンツをハッシュする** — パスは変わりますが、コンテンツの同一性は変わりません
- **大きなファイルはチャンク処理でハッシュする** — ファイル全体をメモリに読み込まないようにします
- **処理関数は純粋に保つ** — キャッシュについて何も知らないようにします
- **キャッシュヒット/ミスをログに記録する** — デバッグ用にトランケートされたハッシュとともに記録します
- **破損をグレースフルに処理する** — 無効なキャッシュエントリはミスとして扱い、クラッシュさせないでください

## 避けるべきアンチパターン

```python
# BAD: パスベースのキャッシュ（ファイルの移動/リネームで壊れる）
cache = {"/path/to/file.pdf": result}

# BAD: 処理関数内にキャッシュロジックを追加（SRP 違反）
def extract_text(path, *, cache_enabled=False, cache_dir=None):
    if cache_enabled:  # この関数に2つの責務ができてしまう
        ...

# BAD: ネストされた frozen dataclass で dataclasses.asdict() を使用
# （複雑なネスト型で問題が発生する可能性がある）
data = dataclasses.asdict(entry)  # 代わりに手動シリアライズを使用
```

## 使用タイミング

- ファイル処理パイプライン（PDF パース、OCR、テキスト抽出、画像分析）
- `--cache/--no-cache` オプションの恩恵を受ける CLI ツール
- 同じファイルが実行ごとに出現するバッチ処理
- 既存の純粋関数を変更せずにキャッシュを追加する場合

## 使用しない場合

- 常に最新でなければならないデータ（リアルタイムフィード）
- キャッシュエントリが非常に大きくなる場合（代わりにストリーミングを検討）
- ファイルコンテンツ以外のパラメータに依存する結果（例：異なる抽出設定）
