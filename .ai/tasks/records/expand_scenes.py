#!/usr/bin/env python3
"""One-off content generator: increase each scene's volume.

Targets -> 8, dummies -> 12, hardDummies -> 8 per scene.

Invariants kept (enforced by test/unit/scene_consistency_test.dart &
scene_decoys_consistency_test.dart):
  * per-scene target iconIds and decoy iconIds are disjoint
  * all ids unique across targets + dummies + hardDummies
  * every iconId is a known icon (target_icons.dart)
  * hardDummies non-empty; normal/hard have more decoys than easy
  * decoy scale in [0.4, 1.6]

Layout: all items placed on a 6x6 grid (distinct cells) with small
deterministic jitter -> guaranteed no overlap, full-screen spread.

Lives under .ai/ (not committed). Run from repo root:
  python3 .ai/tasks/records/expand_scenes.py
"""
import json
import glob
import os
import random

TARGETS_N = 8
DUMMIES_N = 12
HARDS_N = 8

# Order used to pick decoys; target-capable icons last so they are still
# available as decoys in scenes where they are not targets.
ICON_ORDER = [
    "leaf", "car", "gem", "rabbit", "umbrella", "music", "bug", "key",
    "cake", "cat", "cloud", "gift", "anchor", "cookie", "moon", "swimmer",
    "bell", "pizza", "kite", "lightbulb", "fire", "sailboat", "crown",
    "icecream", "apple", "duck", "star", "ball", "flower", "heart",
]

LEFTS = [0.03, 0.194, 0.358, 0.522, 0.686, 0.85]
TOPS = [0.03, 0.184, 0.338, 0.492, 0.646, 0.80]
HARD_SCALES = [0.7, 0.85, 1.0, 1.15, 1.3, 0.8, 1.2, 0.95]


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


def build_scene(path, idx):
    data = json.load(open(path))
    existing_targets = data.get("targets", [])

    # Preserve target types (ordered unique) and their labelKeys.
    target_types = []
    label_of = {}
    for t in existing_targets:
        ic = t["iconId"]
        if ic not in label_of:
            target_types.append(ic)
            label_of[ic] = t.get("labelKey", f"target.{ic}")
    if not target_types:  # safety; every scene has targets today
        target_types = ["star"]
        label_of["star"] = "target.star"

    # 8 targets: round-robin across the scene's existing target types.
    targets = []
    counts = {ic: 0 for ic in target_types}
    for i in range(TARGETS_N):
        ic = target_types[i % len(target_types)]
        counts[ic] += 1
        targets.append({"id": f"{ic}_{counts[ic]}", "iconId": ic,
                        "labelKey": label_of[ic]})

    # Decoy pool = known icons minus this scene's target icons, rotated per
    # scene for variety.
    pool = [ic for ic in ICON_ORDER if ic not in set(target_types)]
    rot = (idx * 3) % len(pool)
    pool = pool[rot:] + pool[:rot]

    dummies = [{"id": f"d_{ic}", "iconId": ic} for ic in pool[:DUMMIES_N]]
    hard_src = pool[DUMMIES_N:DUMMIES_N + HARDS_N]
    hards = [{"id": f"h_{ic}", "iconId": ic,
              "scale": HARD_SCALES[i % len(HARD_SCALES)]}
             for i, ic in enumerate(hard_src)]

    # Lay everything out on one shared grid (no overlap in any mode).
    items = targets + dummies + hards
    pos = grid_positions(len(items), seed=1000 + idx)
    for it, (l, t) in zip(items, pos):
        is_target = "labelKey" in it
        it["left"] = l
        it["top"] = t
        it["width"] = 0.11 if is_target else 0.10
        it["height"] = 0.13 if is_target else 0.12

    out = {
        "id": data["id"],
        "titleKey": data["titleKey"],
        "imageAsset": data["imageAsset"],
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
    json.dump(out, open(path, "w"), ensure_ascii=False, indent=2)
    open(path, "a").write("\n")
    return out


def rects_overlap(a, b):
    ax, ay, aw, ah = a["left"], a["top"], a["width"], a["height"]
    bx, by, bw, bh = b["left"], b["top"], b["width"], b["height"]
    return not (ax + aw <= bx or bx + bw <= ax or
                ay + ah <= by or by + bh <= ay)


def validate(scene):
    # No overlap among the full set (hard) and among easy set (targets+dummies).
    full = scene["targets"] + scene["dummies"] + scene["hardDummies"]
    easy = scene["targets"] + scene["dummies"]
    for group, name in ((full, "hard"), (easy, "easy")):
        for i in range(len(group)):
            for j in range(i + 1, len(group)):
                if rects_overlap(group[i], group[j]):
                    return f"OVERLAP[{name}] {group[i]['id']} vs {group[j]['id']}"
    tset = {t["iconId"] for t in scene["targets"]}
    dset = {d["iconId"] for d in scene["dummies"] + scene["hardDummies"]}
    if tset & dset:
        return f"ICON CLASH {tset & dset}"
    ids = [x["id"] for x in full]
    if len(ids) != len(set(ids)):
        return "DUP IDS"
    return None


def main():
    files = sorted(glob.glob("assets/scenes/scene*.json"))
    for idx, f in enumerate(files):
        scene = build_scene(f, idx)
        err = validate(scene)
        status = err or "ok"
        print(f"{os.path.basename(f)}: T={len(scene['targets'])} "
              f"D={len(scene['dummies'])} H={len(scene['hardDummies'])} {status}")
        if err:
            raise SystemExit(f"VALIDATION FAILED in {f}: {err}")


if __name__ == "__main__":
    main()
