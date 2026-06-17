---
name: data-scraper-agent
description: Build a fully automated AI-powered data collection agent for any public source — job boards, prices, news, GitHub, sports, anything. Scrapes on a schedule, enriches data with a free LLM (Gemini Flash), stores results in Notion/Sheets/Supabase, and learns from user feedback. Runs 100% free on GitHub Actions. Use when the user wants to monitor, collect, or track any public data automatically.
origin: community
---

# Data Scraper Agent

あらゆる公開データソースに対応した、本番運用可能な AI 搭載データ収集エージェントを構築します。
スケジュールで実行し、無料の LLM で結果をエンリッチメントし、データベースに保存し、時間とともに改善されます。

**スタック: Python · Gemini Flash (無料) · GitHub Actions (無料) · Notion / Sheets / Supabase**

## 起動条件

- ユーザーが公開ウェブサイトや API のスクレイピングまたはモニタリングを希望する場合
- ユーザーが「...をチェックするボットを作って」「X をモニタリングして」「...からデータを集めて」と言った場合
- ユーザーがジョブ、価格、ニュース、リポジトリ、スポーツスコア、イベント、リスティングの追跡を希望する場合
- ユーザーがホスティング費用なしでデータ収集を自動化する方法を尋ねた場合
- ユーザーがユーザーの判断に基づいて賢くなるエージェントを希望する場合

## コアコンセプト

### 3つのレイヤー

すべてのデータスクレイパーエージェントには3つのレイヤーがあります：

```
COLLECT → ENRICH → STORE
  │           │        │
Scraper    AI (LLM)  Database
runs on    scores/   Notion /
schedule   summarises Sheets /
           & classifies Supabase
```

### 無料スタック

| レイヤー | ツール | 理由 |
|---|---|---|
| **スクレイピング** | `requests` + `BeautifulSoup` | コスト不要、公開サイトの80%をカバー |
| **JS レンダリングサイト** | `playwright`（無料） | HTML スクレイピングが失敗する場合 |
| **AI エンリッチメント** | Gemini Flash（REST API 経由） | 500リクエスト/日、1Mトークン/日 — 無料 |
| **ストレージ** | Notion API | 無料枠、レビュー用の優れた UI |
| **スケジュール** | GitHub Actions cron | パブリックリポジトリは無料 |
| **学習** | リポジトリ内の JSON フィードバックファイル | インフラ不要、git に永続化 |

### AI モデルフォールバックチェーン

クォータ枯渇時に Gemini モデル間で自動フォールバックするエージェントを構築します：

```
gemini-2.0-flash-lite (30 RPM) →
gemini-2.0-flash (15 RPM) →
gemini-2.5-flash (10 RPM) →
gemini-flash-lite-latest (fallback)
```

### バッチ API 呼び出しによる効率化

LLM をアイテムごとに1回呼び出さないでください。常にバッチ処理します：

```python
# BAD: 33アイテムに対して33回の API 呼び出し
for item in items:
    result = call_ai(item)  # 33 calls → hits rate limit

# GOOD: 33アイテムに対して7回の API 呼び出し（バッチサイズ5）
for batch in chunks(items, size=5):
    results = call_ai(batch)  # 7 calls → stays within free tier
```

---

## ワークフロー

### ステップ 1: ゴールの把握

ユーザーに以下を確認します：

1. **何を収集するか:** 「どのデータソースですか？URL / API / RSS / 公開エンドポイント？」
2. **何を抽出するか:** 「どのフィールドが重要ですか？タイトル、価格、URL、日付、スコア？」
3. **どこに保存するか:** 「結果をどこに保存しますか？Notion、Google Sheets、Supabase、ローカルファイル？」
4. **どうエンリッチメントするか:** 「AI に各アイテムのスコアリング、要約、分類、マッチングをさせたいですか？」
5. **頻度:** 「どのくらいの頻度で実行しますか？1時間ごと、毎日、毎週？」

プロンプトとなる一般的な例：
- 求人ボード → 履歴書との関連度をスコアリング
- 商品価格 → 値下げ時にアラート
- GitHub リポジトリ → 新しいリリースを要約
- ニュースフィード → トピック + センチメントで分類
- スポーツ結果 → トラッカーに統計を抽出
- イベントカレンダー → 興味で絞り込み

---

### ステップ 2: エージェントアーキテクチャの設計

ユーザー向けに以下のディレクトリ構造を生成します：

```
my-agent/
├── config.yaml              # ユーザーがカスタマイズ（キーワード、フィルター、設定）
├── profile/
│   └── context.md           # AI が使用するユーザーコンテキスト（履歴書、興味、基準）
├── scraper/
│   ├── __init__.py
│   ├── main.py              # オーケストレーター：スクレイプ → エンリッチ → ストア
│   ├── filters.py           # ルールベースのプレフィルター（高速、AI の前に実行）
│   └── sources/
│       ├── __init__.py
│       └── source_name.py   # データソースごとに1ファイル
├── ai/
│   ├── __init__.py
│   ├── client.py            # Gemini REST クライアント（モデルフォールバック付き）
│   ├── pipeline.py          # バッチ AI 分析
│   ├── jd_fetcher.py        # URL からフルコンテンツを取得（オプション）
│   └── memory.py            # ユーザーフィードバックから学習
├── storage/
│   ├── __init__.py
│   └── notion_sync.py       # または sheets_sync.py / supabase_sync.py
├── data/
│   └── feedback.json        # ユーザー判断履歴（自動更新）
├── .env.example
├── setup.py                 # 初回の DB/スキーマ作成
├── enrich_existing.py       # 既存行に AI スコアをバックフィル
├── requirements.txt
└── .github/
    └── workflows/
        └── scraper.yml      # GitHub Actions スケジュール
```

---

### ステップ 3: スクレイパーソースの構築

任意のデータソース用テンプレート：

```python
# scraper/sources/my_source.py
"""
[Source Name] — scrapes [what] from [where].
Method: [REST API / HTML scraping / RSS feed]
"""
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timezone
from scraper.filters import is_relevant

HEADERS = {
    "User-Agent": "Mozilla/5.0 (compatible; research-bot/1.0)",
}


def fetch() -> list[dict]:
    """
    Returns a list of items with consistent schema.
    Each item must have at minimum: name, url, date_found.
    """
    results = []

    # ---- REST API source ----
    resp = requests.get("https://api.example.com/items", headers=HEADERS, timeout=15)
    if resp.status_code == 200:
        for item in resp.json().get("results", []):
            if not is_relevant(item.get("title", "")):
                continue
            results.append(_normalise(item))

    return results


def _normalise(raw: dict) -> dict:
    """Convert raw API/HTML data to the standard schema."""
    return {
        "name": raw.get("title", ""),
        "url": raw.get("link", ""),
        "source": "MySource",
        "date_found": datetime.now(timezone.utc).date().isoformat(),
        # add domain-specific fields here
    }
```

**HTML スクレイピングパターン：**
```python
soup = BeautifulSoup(resp.text, "lxml")
for card in soup.select("[class*='listing']"):
    title = card.select_one("h2, h3").get_text(strip=True)
    link = card.select_one("a")["href"]
    if not link.startswith("http"):
        link = f"https://example.com{link}"
```

**RSS フィードパターン：**
```python
import xml.etree.ElementTree as ET
root = ET.fromstring(resp.text)
for item in root.findall(".//item"):
    title = item.findtext("title", "")
    link = item.findtext("link", "")
```

---

### ステップ 4: Gemini AI クライアントの構築

```python
# ai/client.py
import os, json, time, requests

_last_call = 0.0

MODEL_FALLBACK = [
    "gemini-2.0-flash-lite",
    "gemini-2.0-flash",
    "gemini-2.5-flash",
    "gemini-flash-lite-latest",
]


def generate(prompt: str, model: str = "", rate_limit: float = 7.0) -> dict:
    """Call Gemini with auto-fallback on 429. Returns parsed JSON or {}."""
    global _last_call

    api_key = os.environ.get("GEMINI_API_KEY", "")
    if not api_key:
        return {}

    elapsed = time.time() - _last_call
    if elapsed < rate_limit:
        time.sleep(rate_limit - elapsed)

    models = [model] + [m for m in MODEL_FALLBACK if m != model] if model else MODEL_FALLBACK
    _last_call = time.time()

    for m in models:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{m}:generateContent?key={api_key}"
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "responseMimeType": "application/json",
                "temperature": 0.3,
                "maxOutputTokens": 2048,
            },
        }
        try:
            resp = requests.post(url, json=payload, timeout=30)
            if resp.status_code == 200:
                return _parse(resp)
            if resp.status_code in (429, 404):
                time.sleep(1)
                continue
            return {}
        except requests.RequestException:
            return {}

    return {}


def _parse(resp) -> dict:
    try:
        text = (
            resp.json()
            .get("candidates", [{}])[0]
            .get("content", {})
            .get("parts", [{}])[0]
            .get("text", "")
            .strip()
        )
        if text.startswith("```"):
            text = text.split("\n", 1)[-1].rsplit("```", 1)[0]
        return json.loads(text)
    except (json.JSONDecodeError, KeyError):
        return {}
```

---

### ステップ 5: AI パイプラインの構築（バッチ処理）

```python
# ai/pipeline.py
import json
import yaml
from pathlib import Path
from ai.client import generate

def analyse_batch(items: list[dict], context: str = "", preference_prompt: str = "") -> list[dict]:
    """Analyse items in batches. Returns items enriched with AI fields."""
    config = yaml.safe_load((Path(__file__).parent.parent / "config.yaml").read_text())
    model = config.get("ai", {}).get("model", "gemini-2.5-flash")
    rate_limit = config.get("ai", {}).get("rate_limit_seconds", 7.0)
    min_score = config.get("ai", {}).get("min_score", 0)
    batch_size = config.get("ai", {}).get("batch_size", 5)

    batches = [items[i:i + batch_size] for i in range(0, len(items), batch_size)]
    print(f"  [AI] {len(items)} items → {len(batches)} API calls")

    enriched = []
    for i, batch in enumerate(batches):
        print(f"  [AI] Batch {i + 1}/{len(batches)}...")
        prompt = _build_prompt(batch, context, preference_prompt, config)
        result = generate(prompt, model=model, rate_limit=rate_limit)

        analyses = result.get("analyses", [])
        for j, item in enumerate(batch):
            ai = analyses[j] if j < len(analyses) else {}
            if ai:
                score = max(0, min(100, int(ai.get("score", 0))))
                if min_score and score < min_score:
                    continue
                enriched.append({**item, "ai_score": score, "ai_summary": ai.get("summary", ""), "ai_notes": ai.get("notes", "")})
            else:
                enriched.append(item)

    return enriched


def _build_prompt(batch, context, preference_prompt, config):
    priorities = config.get("priorities", [])
    items_text = "\n\n".join(
        f"Item {i+1}: {json.dumps({k: v for k, v in item.items() if not k.startswith('_')})}"
        for i, item in enumerate(batch)
    )

    return f"""Analyse these {len(batch)} items and return a JSON object.

# Items
{items_text}

# User Context
{context[:800] if context else "Not provided"}

# User Priorities
{chr(10).join(f"- {p}" for p in priorities)}

{preference_prompt}

# Instructions
Return: {{"analyses": [{{"score": <0-100>, "summary": "<2 sentences>", "notes": "<why this matches or doesn't>"}} for each item in order]}}
Be concise. Score 90+=excellent match, 70-89=good, 50-69=ok, <50=weak."""
```

---

### ステップ 6: フィードバック学習システムの構築

```python
# ai/memory.py
"""Learn from user decisions to improve future scoring."""
import json
from pathlib import Path

FEEDBACK_PATH = Path(__file__).parent.parent / "data" / "feedback.json"


def load_feedback() -> dict:
    if FEEDBACK_PATH.exists():
        try:
            return json.loads(FEEDBACK_PATH.read_text())
        except (json.JSONDecodeError, OSError):
            pass
    return {"positive": [], "negative": []}


def save_feedback(fb: dict):
    FEEDBACK_PATH.parent.mkdir(parents=True, exist_ok=True)
    FEEDBACK_PATH.write_text(json.dumps(fb, indent=2))


def build_preference_prompt(feedback: dict, max_examples: int = 15) -> str:
    """Convert feedback history into a prompt bias section."""
    lines = []
    if feedback.get("positive"):
        lines.append("# Items the user LIKED (positive signal):")
        for e in feedback["positive"][-max_examples:]:
            lines.append(f"- {e}")
    if feedback.get("negative"):
        lines.append("\n# Items the user SKIPPED/REJECTED (negative signal):")
        for e in feedback["negative"][-max_examples:]:
            lines.append(f"- {e}")
    if lines:
        lines.append("\nUse these patterns to bias scoring on new items.")
    return "\n".join(lines)
```

**ストレージレイヤーとの統合：** 各実行後に DB からポジティブ/ネガティブステータスのアイテムをクエリし、抽出したパターンで `save_feedback()` を呼び出します。

---

### ステップ 7: ストレージの構築（Notion の例）

```python
# storage/notion_sync.py
import os
from notion_client import Client
from notion_client.errors import APIResponseError

_client = None

def get_client():
    global _client
    if _client is None:
        _client = Client(auth=os.environ["NOTION_TOKEN"])
    return _client

def get_existing_urls(db_id: str) -> set[str]:
    """Fetch all URLs already stored — used for deduplication."""
    client, seen, cursor = get_client(), set(), None
    while True:
        resp = client.databases.query(database_id=db_id, page_size=100, **{"start_cursor": cursor} if cursor else {})
        for page in resp["results"]:
            url = page["properties"].get("URL", {}).get("url", "")
            if url: seen.add(url)
        if not resp["has_more"]: break
        cursor = resp["next_cursor"]
    return seen

def push_item(db_id: str, item: dict) -> bool:
    """Push one item to Notion. Returns True on success."""
    props = {
        "Name": {"title": [{"text": {"content": item.get("name", "")[:100]}}]},
        "URL": {"url": item.get("url")},
        "Source": {"select": {"name": item.get("source", "Unknown")}},
        "Date Found": {"date": {"start": item.get("date_found")}},
        "Status": {"select": {"name": "New"}},
    }
    # AI fields
    if item.get("ai_score") is not None:
        props["AI Score"] = {"number": item["ai_score"]}
    if item.get("ai_summary"):
        props["Summary"] = {"rich_text": [{"text": {"content": item["ai_summary"][:2000]}}]}
    if item.get("ai_notes"):
        props["Notes"] = {"rich_text": [{"text": {"content": item["ai_notes"][:2000]}}]}

    try:
        get_client().pages.create(parent={"database_id": db_id}, properties=props)
        return True
    except APIResponseError as e:
        print(f"[notion] Push failed: {e}")
        return False

def sync(db_id: str, items: list[dict]) -> tuple[int, int]:
    existing = get_existing_urls(db_id)
    added = skipped = 0
    for item in items:
        if item.get("url") in existing:
            skipped += 1; continue
        if push_item(db_id, item):
            added += 1; existing.add(item["url"])
        else:
            skipped += 1
    return added, skipped
```

---

### ステップ 8: main.py でのオーケストレーション

```python
# scraper/main.py
import os, sys, yaml
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

from scraper.sources import my_source          # add your sources

# NOTE: This example uses Notion. If storage.provider is "sheets" or "supabase",
# replace this import with storage.sheets_sync or storage.supabase_sync and update
# the env var and sync() call accordingly.
from storage.notion_sync import sync

SOURCES = [
    ("My Source", my_source.fetch),
]

def ai_enabled():
    return bool(os.environ.get("GEMINI_API_KEY"))

def main():
    config = yaml.safe_load((Path(__file__).parent.parent / "config.yaml").read_text())
    provider = config.get("storage", {}).get("provider", "notion")

    # Resolve the storage target identifier from env based on provider
    if provider == "notion":
        db_id = os.environ.get("NOTION_DATABASE_ID")
        if not db_id:
            print("ERROR: NOTION_DATABASE_ID not set"); sys.exit(1)
    else:
        # Extend here for sheets (SHEET_ID) or supabase (SUPABASE_TABLE) etc.
        print(f"ERROR: provider '{provider}' not yet wired in main.py"); sys.exit(1)

    config = yaml.safe_load((Path(__file__).parent.parent / "config.yaml").read_text())
    all_items = []

    for name, fetch_fn in SOURCES:
        try:
            items = fetch_fn()
            print(f"[{name}] {len(items)} items")
            all_items.extend(items)
        except Exception as e:
            print(f"[{name}] FAILED: {e}")

    # Deduplicate by URL
    seen, deduped = set(), []
    for item in all_items:
        if (url := item.get("url", "")) and url not in seen:
            seen.add(url); deduped.append(item)

    print(f"Unique items: {len(deduped)}")

    if ai_enabled() and deduped:
        from ai.memory import load_feedback, build_preference_prompt
        from ai.pipeline import analyse_batch

        # load_feedback() reads data/feedback.json written by your feedback sync script.
        # To keep it current, implement a separate feedback_sync.py that queries your
        # storage provider for items with positive/negative statuses and calls save_feedback().
        feedback = load_feedback()
        preference = build_preference_prompt(feedback)
        context_path = Path(__file__).parent.parent / "profile" / "context.md"
        context = context_path.read_text() if context_path.exists() else ""
        deduped = analyse_batch(deduped, context=context, preference_prompt=preference)
    else:
        print("[AI] Skipped — GEMINI_API_KEY not set")

    added, skipped = sync(db_id, deduped)
    print(f"Done — {added} new, {skipped} existing")

if __name__ == "__main__":
    main()
```

---

### ステップ 9: GitHub Actions ワークフロー

```yaml
# .github/workflows/scraper.yml
name: Data Scraper Agent

on:
  schedule:
    - cron: "0 */3 * * *"  # every 3 hours — adjust to your needs
  workflow_dispatch:        # allow manual trigger

permissions:
  contents: write   # required for the feedback-history commit step

jobs:
  scrape:
    runs-on: ubuntu-latest
    timeout-minutes: 20

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
          cache: "pip"

      - run: pip install -r requirements.txt

      # Uncomment if Playwright is enabled in requirements.txt
      # - name: Install Playwright browsers
      #   run: python -m playwright install chromium --with-deps

      - name: Run agent
        env:
          NOTION_TOKEN: ${{ secrets.NOTION_TOKEN }}
          NOTION_DATABASE_ID: ${{ secrets.NOTION_DATABASE_ID }}
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
        run: python -m scraper.main

      - name: Commit feedback history
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add data/feedback.json || true
          git diff --cached --quiet || git commit -m "chore: update feedback history"
          git push
```

---

### ステップ 10: config.yaml テンプレート

```yaml
# Customise this file — no code changes needed

# What to collect (pre-filter before AI)
filters:
  required_keywords: []      # item must contain at least one
  blocked_keywords: []       # item must not contain any

# Your priorities — AI uses these for scoring
priorities:
  - "example priority 1"
  - "example priority 2"

# Storage
storage:
  provider: "notion"         # notion | sheets | supabase | sqlite

# Feedback learning
feedback:
  positive_statuses: ["Saved", "Applied", "Interested"]
  negative_statuses: ["Skip", "Rejected", "Not relevant"]

# AI settings
ai:
  enabled: true
  model: "gemini-2.5-flash"
  min_score: 0               # filter out items below this score
  rate_limit_seconds: 7      # seconds between API calls
  batch_size: 5              # items per API call
```

---

## 一般的なスクレイピングパターン

### パターン 1: REST API（最も簡単）
```python
resp = requests.get(url, params={"q": query}, headers=HEADERS, timeout=15)
items = resp.json().get("results", [])
```

### パターン 2: HTML スクレイピング
```python
soup = BeautifulSoup(resp.text, "lxml")
for card in soup.select(".listing-card"):
    title = card.select_one("h2").get_text(strip=True)
    href = card.select_one("a")["href"]
```

### パターン 3: RSS フィード
```python
import xml.etree.ElementTree as ET
root = ET.fromstring(resp.text)
for item in root.findall(".//item"):
    title = item.findtext("title", "")
    link = item.findtext("link", "")
    pub_date = item.findtext("pubDate", "")
```

### パターン 4: ページネーション付き API
```python
page = 1
while True:
    resp = requests.get(url, params={"page": page, "limit": 50}, timeout=15)
    data = resp.json()
    items = data.get("results", [])
    if not items:
        break
    for item in items:
        results.append(_normalise(item))
    if not data.get("has_more"):
        break
    page += 1
```

### パターン 5: JS レンダリングページ（Playwright）
```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.goto(url)
    page.wait_for_selector(".listing")
    html = page.content()
    browser.close()

soup = BeautifulSoup(html, "lxml")
```

---

## 避けるべきアンチパターン

| アンチパターン | 問題 | 修正 |
|---|---|---|
| アイテムごとに1回の LLM 呼び出し | レートリミットに即座に到達 | 1回の呼び出しで5アイテムをバッチ処理 |
| コード内のハードコードされたキーワード | 再利用不可 | すべての設定を `config.yaml` に移動 |
| レートリミットなしのスクレイピング | IP ブロック | リクエスト間に `time.sleep(1)` を追加 |
| コード内にシークレットを保存 | セキュリティリスク | 常に `.env` + GitHub Secrets を使用 |
| 重複排除なし | 重複行が蓄積 | プッシュ前に常に URL をチェック |
| `robots.txt` の無視 | 法的/倫理的リスク | クロールルールを遵守、可能なら公開 API を使用 |
| `requests` での JS レンダリングサイト | 空のレスポンス | Playwright を使用するか、基盤となる API を探す |
| `maxOutputTokens` が低すぎる | JSON の切り詰め、パースエラー | バッチレスポンスには 2048 以上を使用 |

---

## 無料枠の制限リファレンス

| サービス | 無料制限 | 一般的な使用量 |
|---|---|---|
| Gemini Flash Lite | 30 RPM、1500 RPD | 3時間間隔で約56リクエスト/日 |
| Gemini 2.0 Flash | 15 RPM、1500 RPD | 良いフォールバック |
| Gemini 2.5 Flash | 10 RPM、500 RPD | 控えめに使用 |
| GitHub Actions | 無制限（パブリックリポジトリ） | 約20分/日 |
| Notion API | 無制限 | 約200書き込み/日 |
| Supabase | 500MB DB、2GB 転送 | ほとんどのエージェントに十分 |
| Google Sheets API | 300リクエスト/分 | 小規模エージェント向け |

---

## Requirements テンプレート

```
requests==2.31.0
beautifulsoup4==4.12.3
lxml==5.1.0
python-dotenv==1.0.1
pyyaml==6.0.2
notion-client==2.2.1   # if using Notion
# playwright==1.40.0   # uncomment for JS-rendered sites
```

---

## 品質チェックリスト

エージェントを完了とマークする前に：

- [ ] `config.yaml` がすべてのユーザー向け設定を制御 — ハードコードされた値なし
- [ ] `profile/context.md` が AI マッチング用のユーザー固有コンテキストを保持
- [ ] ストレージプッシュの前に URL による重複排除
- [ ] Gemini クライアントにモデルフォールバックチェーン（4モデル）
- [ ] バッチサイズ 5アイテム以下/API 呼び出し
- [ ] `maxOutputTokens` 2048 以上
- [ ] `.env` が `.gitignore` に含まれている
- [ ] オンボーディング用の `.env.example` が提供されている
- [ ] `setup.py` が初回実行時に DB スキーマを作成
- [ ] `enrich_existing.py` が既存行に AI スコアをバックフィル
- [ ] GitHub Actions ワークフローが各実行後に `feedback.json` をコミット
- [ ] README がカバー：5分以内のセットアップ、必要なシークレット、カスタマイズ方法

---

## 実際の使用例

```
"Hacker News の AI スタートアップ資金調達ニュースをモニタリングするエージェントを作って"
"3つの EC サイトから商品価格をスクレイピングし、値下げ時にアラートして"
"'llm' や 'agents' タグの新しい GitHub リポジトリを追跡して、それぞれ要約して"
"LinkedIn と Cutshort から Chief of Staff の求人を Notion に収集して"
"サブレディットで自社に言及する投稿をモニタリングし、センチメントを分類して"
"毎日 arXiv から自分が関心のあるトピックの新しい学術論文をスクレイピングして"
"スポーツの試合結果を追跡し、Google Sheets で順位表を維持して"
"不動産リスティングウォッチャーを作って — 1 Cr ルピー未満の新しい物件をアラートして"
```

---

## リファレンス実装

このアーキテクチャで構築された完全な動作エージェントは、4つ以上のソースをスクレイピングし、
Gemini 呼び出しをバッチ処理し、Notion に保存された Applied/Rejected の判断から学習し、
GitHub Actions で100%無料で実行されます。上記のステップ 1〜9 に従って独自のエージェントを構築してください。
