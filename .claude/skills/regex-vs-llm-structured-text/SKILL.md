---
name: regex-vs-llm-structured-text
description: Decision framework for choosing between regex and LLM when parsing structured text — start with regex, add LLM only for low-confidence edge cases.
origin: ECC
---

# Regex vs LLM for Structured Text Parsing

構造化テキスト（クイズ、フォーム、請求書、ドキュメント）を解析するための実用的な判断フレームワークです。重要な洞察: 正規表現がケースの95-98%を安価かつ決定的に処理します。高価な LLM 呼び出しは残りのエッジケースに限定します。

## 起動条件

- 繰り返しパターンを持つ構造化テキストの解析（問題、フォーム、テーブル）
- テキスト抽出に正規表現と LLM のどちらを使用するかの判断
- 両方のアプローチを組み合わせたハイブリッドパイプラインの構築
- テキスト処理におけるコスト/精度のトレードオフの最適化

## 判断フレームワーク

```
Is the text format consistent and repeating?
├── Yes (>90% follows a pattern) → Start with Regex
│   ├── Regex handles 95%+ → Done, no LLM needed
│   └── Regex handles <95% → Add LLM for edge cases only
└── No (free-form, highly variable) → Use LLM directly
```

## アーキテクチャパターン

```
Source Text
    │
    ▼
[Regex Parser] ─── 構造を抽出（95-98% の精度）
    │
    ▼
[Text Cleaner] ─── ノイズを除去（マーカー、ページ番号、アーティファクト）
    │
    ▼
[Confidence Scorer] ─── 低信頼度の抽出にフラグを立てる
    │
    ├── 高信頼度（≥0.95） → 直接出力
    │
    └── 低信頼度（<0.95） → [LLM Validator] → 出力
```

## 実装

### 1. Regex パーサー（大部分を処理）

```python
import re
from dataclasses import dataclass

@dataclass(frozen=True)
class ParsedItem:
    id: str
    text: str
    choices: tuple[str, ...]
    answer: str
    confidence: float = 1.0

def parse_structured_text(content: str) -> list[ParsedItem]:
    """正規表現パターンを使用して構造化テキストを解析します。"""
    pattern = re.compile(
        r"(?P<id>\d+)\.\s*(?P<text>.+?)\n"
        r"(?P<choices>(?:[A-D]\..+?\n)+)"
        r"Answer:\s*(?P<answer>[A-D])",
        re.MULTILINE | re.DOTALL,
    )
    items = []
    for match in pattern.finditer(content):
        choices = tuple(
            c.strip() for c in re.findall(r"[A-D]\.\s*(.+)", match.group("choices"))
        )
        items.append(ParsedItem(
            id=match.group("id"),
            text=match.group("text").strip(),
            choices=choices,
            answer=match.group("answer"),
        ))
    return items
```

### 2. 信頼度スコアリング

LLM レビューが必要な可能性のあるアイテムにフラグを立てます:

```python
@dataclass(frozen=True)
class ConfidenceFlag:
    item_id: str
    score: float
    reasons: tuple[str, ...]

def score_confidence(item: ParsedItem) -> ConfidenceFlag:
    """抽出の信頼度をスコアリングし、問題にフラグを立てます。"""
    reasons = []
    score = 1.0

    if len(item.choices) < 3:
        reasons.append("few_choices")
        score -= 0.3

    if not item.answer:
        reasons.append("missing_answer")
        score -= 0.5

    if len(item.text) < 10:
        reasons.append("short_text")
        score -= 0.2

    return ConfidenceFlag(
        item_id=item.id,
        score=max(0.0, score),
        reasons=tuple(reasons),
    )

def identify_low_confidence(
    items: list[ParsedItem],
    threshold: float = 0.95,
) -> list[ConfidenceFlag]:
    """信頼度閾値を下回るアイテムを返します。"""
    flags = [score_confidence(item) for item in items]
    return [f for f in flags if f.score < threshold]
```

### 3. LLM バリデーター（エッジケースのみ）

```python
def validate_with_llm(
    item: ParsedItem,
    original_text: str,
    client,
) -> ParsedItem:
    """LLM を使用して低信頼度の抽出を修正します。"""
    response = client.messages.create(
        model="claude-haiku-4-5-20251001",  # バリデーションに最も安価なモデル
        max_tokens=500,
        messages=[{
            "role": "user",
            "content": (
                f"Extract the question, choices, and answer from this text.\n\n"
                f"Text: {original_text}\n\n"
                f"Current extraction: {item}\n\n"
                f"Return corrected JSON if needed, or 'CORRECT' if accurate."
            ),
        }],
    )
    # LLM レスポンスを解析して修正されたアイテムを返す...
    return corrected_item
```

### 4. ハイブリッドパイプライン

```python
def process_document(
    content: str,
    *,
    llm_client=None,
    confidence_threshold: float = 0.95,
) -> list[ParsedItem]:
    """完全パイプライン: 正規表現 -> 信頼度チェック -> エッジケースに LLM。"""
    # ステップ 1: 正規表現抽出（95-98% を処理）
    items = parse_structured_text(content)

    # ステップ 2: 信頼度スコアリング
    low_confidence = identify_low_confidence(items, confidence_threshold)

    if not low_confidence or llm_client is None:
        return items

    # ステップ 3: LLM バリデーション（フラグ付きアイテムのみ）
    low_conf_ids = {f.item_id for f in low_confidence}
    result = []
    for item in items:
        if item.id in low_conf_ids:
            result.append(validate_with_llm(item, content, llm_client))
        else:
            result.append(item)

    return result
```

## 実運用メトリクス

本番クイズ解析パイプライン（410アイテム）の結果:

| メトリクス | 値 |
|-----------|-----|
| 正規表現成功率 | 98.0% |
| 低信頼度アイテム | 8 (2.0%) |
| 必要な LLM 呼び出し | 約5 |
| 全 LLM 比のコスト削減 | 約95% |
| テストカバレッジ | 93% |

## ベストプラクティス

- **正規表現から始める** — 不完全な正規表現でも改善のベースラインを提供します
- **信頼度スコアリングを使用**して、LLM の助けが必要なものをプログラム的に特定します
- **最も安価な LLM を使用**してバリデーションします（Haiku クラスのモデルで十分です）
- **解析済みアイテムを変更しない** — クリーニング/バリデーションステップからは新しいインスタンスを返します
- **TDD はパーサーに有効** — まず既知のパターンのテストを書き、次にエッジケースを書きます
- **メトリクスを記録**して（正規表現成功率、LLM 呼び出し数）パイプラインの健全性を追跡します

## 避けるべきアンチパターン

- 正規表現がケースの95%以上を処理できるのに、すべてのテキストを LLM に送る（高コストで低速）
- 自由形式で変動性の高いテキストに正規表現を使用する（LLM の方が適している）
- 信頼度スコアリングをスキップして、正規表現が「うまくいく」ことを期待する
- クリーニング/バリデーションステップ中に解析済みオブジェクトを変更する
- エッジケースをテストしない（不正な入力、欠落フィールド、エンコーディングの問題）

## 使用タイミング

- クイズ/試験問題の解析
- フォームデータの抽出
- 請求書/領収書の処理
- ドキュメント構造の解析（ヘッダー、セクション、テーブル）
- コストが重要な、繰り返しパターンを持つ構造化テキスト全般
