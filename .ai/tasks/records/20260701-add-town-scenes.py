#!/usr/bin/env python3
"""Generate 4 new "town-like" scenes (scene14-17) as JSON.

Each scene: 8 distinct themed targets + 12 dummies + 8 hardDummies, all laid
out on a shared 6x6 grid with deterministic jitter (no overlap in any mode).
Decoy pool (8 icons) is cycled to fill 12 dummies + 8 hards.

Invariants (enforced by scene_consistency_test / scene_decoys_consistency_test):
  * per-scene target iconIds and decoy iconIds disjoint  (checked below)
  * all ids unique across targets + dummies + hardDummies
  * every iconId is a known icon
  * hardDummies non-empty; normal/hard have more decoys than easy
  * decoy scale in [0.4, 1.6]

Lives under .ai/ (not committed). Run from repo root:
  python3 .ai/tasks/records/20260701-add-town-scenes.py
"""
import json
import os
import random

HARD_SCALES = [0.7, 0.85, 1.0, 1.15, 1.3, 0.8, 1.2, 0.95]
LEFTS = [0.03, 0.194, 0.358, 0.522, 0.686, 0.85]
TOPS = [0.03, 0.184, 0.338, 0.492, 0.646, 0.80]

DUMMIES_N = 12
HARDS_N = 8

SCENES = {
    "scene14": {  # まち Town
        "targets": ["car", "bus", "house", "trafficlight",
                    "key", "bell", "backpack", "flag"],
        "decoys": ["lightbulb", "music", "gift", "umbrella",
                   "ball", "cat", "bird", "cloud"],
    },
    "scene15": {  # おかしのくに Candy
        "targets": ["cake", "cookie", "icecream", "pizza",
                    "gift", "apple", "heart", "balloon"],
        "decoys": ["flower", "sun", "music", "bell",
                   "umbrella", "kite", "cat", "bird"],
    },
    "scene16": {  # どうぶつえん Zoo
        "targets": ["fox", "rabbit", "owl", "penguin",
                    "hedgehog", "squirrel", "camel", "duck"],
        "decoys": ["bird", "cat", "snake", "bee",
                   "butterfly", "bug", "leaf", "acorn"],
    },
    "scene17": {  # ゆうえんち Park
        "targets": ["balloon", "kite", "gift", "ball",
                    "icecream", "music", "crown", "star"],
        "decoys": ["flag", "heart", "sun", "cake",
                   "cookie", "umbrella", "bell", "flower"],
    },
}


def grid_positions(n, seed):
    cells = [(l, t) for t in TOPS for l in LEFTS]
    rng = random.Random(seed)
    rng.shuffle(cells)
    out = []
    for (l, t) in cells[:n]:
        dx = rng.uniform(-0.012, 0.012)
        dy = rng.uniform(-0.006, 0.006)
        out.append((round(min(max(l + dx, 0.01), 0.88), 3),
                    round(min(max(t + dy, 0.01), 0.85), 3)))
    return out


def build(scene_id, idx, spec):
    targets_ic = spec["targets"]
    decoys_ic = spec["decoys"]
    assert len(targets_ic) == 8, scene_id
    assert len(decoys_ic) == 8, scene_id
    assert not (set(targets_ic) & set(decoys_ic)), f"overlap in {scene_id}"

    targets = [{"id": f"{ic}_1", "iconId": ic, "labelKey": f"target.{ic}"}
               for ic in targets_ic]
    dummies = [{"id": f"d_{decoys_ic[i % 8]}_{i}", "iconId": decoys_ic[i % 8]}
               for i in range(DUMMIES_N)]
    hards = [{"id": f"h_{decoys_ic[i % 8]}_{i}", "iconId": decoys_ic[i % 8],
              "scale": HARD_SCALES[i % len(HARD_SCALES)]}
             for i in range(HARDS_N)]

    items = targets + dummies + hards
    pos = grid_positions(len(items), seed=1400 + idx)
    for it, (l, t) in zip(items, pos):
        is_target = "labelKey" in it
        it["left"] = l
        it["top"] = t
        it["width"] = 0.11 if is_target else 0.10
        it["height"] = 0.13 if is_target else 0.12

    out = {
        "id": scene_id,
        "titleKey": f"scene.{scene_id}.title",
        "imageAsset": f"assets/scenes/{scene_id}.png",
        "targets": [{"id": t["id"], "iconId": t["iconId"],
                     "labelKey": t["labelKey"], "left": t["left"],
                     "top": t["top"], "width": t["width"],
                     "height": t["height"]} for t in targets],
        "dummies": [{"id": d["id"], "iconId": d["iconId"], "left": d["left"],
                     "top": d["top"], "width": d["width"],
                     "height": d["height"]} for d in dummies],
        "hardDummies": [{"id": h["id"], "iconId": h["iconId"], "left": h["left"],
                         "top": h["top"], "width": h["width"],
                         "height": h["height"], "scale": h["scale"]}
                        for h in hards],
    }
    # sanity: all ids unique
    ids = [x["id"] for x in out["targets"] + out["dummies"] + out["hardDummies"]]
    assert len(ids) == len(set(ids)), f"dup ids in {scene_id}"

    path = os.path.join("assets", "scenes", f"{scene_id}.json")
    with open(path, "w") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"wrote {path}: {len(out['targets'])} targets, "
          f"{len(out['dummies'])} dummies, {len(out['hardDummies'])} hards")


for i, (sid, spec) in enumerate(SCENES.items()):
    build(sid, i, spec)
