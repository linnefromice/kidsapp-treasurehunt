#!/usr/bin/env python3
"""Generate 4 more town/daily-life scenes (scene18-21).

Same 6x6-grid layout as the previous batch. 8 distinct targets + 12 dummies
+ 8 hardDummies, decoy pool (8 icons) cycled. targets/decoys disjoint.

Run from repo root:
  python3 .ai/tasks/records/20260701-add-townlife-scenes-2.py
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
    "scene18": {  # まちのおしごと Town Helpers
        "targets": ["car", "bus", "trafficlight", "fire",
                    "shield", "key", "flag", "bell"],
        "decoys": ["house", "cloud", "sun", "balloon",
                   "lightbulb", "bird", "umbrella", "gift"],
    },
    "scene19": {  # みなと Harbor
        "targets": ["sailboat", "anchor", "fish", "crab",
                    "shell", "seahorse", "octopus", "bucket"],
        "decoys": ["bird", "cloud", "sun", "flag",
                   "starfish", "jellyfish", "umbrella", "gem"],
    },
    "scene20": {  # こどもべや Toy Room
        "targets": ["ball", "balloon", "car", "kite",
                    "gift", "backpack", "music", "bell"],
        "decoys": ["cat", "star", "heart", "lightbulb",
                   "key", "cloud", "flower", "crown"],
    },
    "scene21": {  # スーパー Supermarket
        "targets": ["apple", "fish", "banana", "bread",
                    "milk", "carrot", "egg", "cheese"],
        "decoys": ["cake", "pizza", "icecream", "gift",
                   "bucket", "balloon", "bell", "key"],
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
    tgt, dec = spec["targets"], spec["decoys"]
    assert len(tgt) == 8 and len(dec) == 8, scene_id
    assert not (set(tgt) & set(dec)), f"overlap in {scene_id}"

    targets = [{"id": f"{ic}_1", "iconId": ic, "labelKey": f"target.{ic}"}
               for ic in tgt]
    dummies = [{"id": f"d_{dec[i % 8]}_{i}", "iconId": dec[i % 8]}
               for i in range(DUMMIES_N)]
    hards = [{"id": f"h_{dec[i % 8]}_{i}", "iconId": dec[i % 8],
              "scale": HARD_SCALES[i % len(HARD_SCALES)]}
             for i in range(HARDS_N)]

    items = targets + dummies + hards
    pos = grid_positions(len(items), seed=1800 + idx)
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
    ids = [x["id"] for x in out["targets"] + out["dummies"] + out["hardDummies"]]
    assert len(ids) == len(set(ids)), f"dup ids in {scene_id}"

    path = os.path.join("assets", "scenes", f"{scene_id}.json")
    with open(path, "w") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"wrote {path}")


for i, (sid, spec) in enumerate(SCENES.items()):
    build(sid, i, spec)
