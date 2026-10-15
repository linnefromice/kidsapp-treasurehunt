#!/usr/bin/env python3
"""A1 めくり露出: 各シーンの一部のターゲットに `cover`（かぶせもの）を付与する。

位置・id・iconId などは触らず、targets の一部に cover キーを足すだけ（surgical）。
covers は target_icons.dart に登録済みの 3 種を scene ごとに回す。
.ai 配下（非コミット）。リポジトリ root から: python3 .ai/tasks/records/add_covers.py
"""
import json
import glob
import os

COVERS = ["cover_leaves", "cover_snow", "cover_box"]
# 8 ターゲット中、この index にカバーを付ける（先頭は素のまま残す＝全部は隠さない）。
COVER_SLOTS = [2, 5]


def main():
    for idx, path in enumerate(sorted(glob.glob("assets/scenes/scene*.json"))):
        data = json.load(open(path))
        targets = data.get("targets", [])
        for k, slot in enumerate(COVER_SLOTS):
            if slot < len(targets):
                cover = COVERS[(idx + k) % len(COVERS)]
                targets[slot]["cover"] = cover
            # 既存の cover が別 slot に残らないよう、対象外からは消す（再実行の冪等性）。
        for i, t in enumerate(targets):
            if i not in COVER_SLOTS and "cover" in t:
                del t["cover"]
        json.dump(data, open(path, "w"), ensure_ascii=False, indent=2)
        open(path, "a").write("\n")
        covered = [t["id"] for t in targets if "cover" in t]
        print(f"{os.path.basename(path)}: covered={covered}")


if __name__ == "__main__":
    main()
