#!/usr/bin/env python3
"""宝アイコン SVG（v4 スタイル）の決定論的ジェネレータ。

`assets/treasure_icons/` の **34 個の手続き生成アイコン**を出力する唯一の真実の源。
共通処理（発光オーラ・接地影・スパークル・ボリュームシェード）をここに集約し、
各アイコンは「本体形状」だけ定義することで 36 個の画風を完全に揃える。

注: `apple.svg` / `star.svg` は画風を定義した**手書きのシード**で、本スクリプトは
上書きしない（生成対象は残り 34 個）。アイコンを一括調整したいときは、共通処理
（`wrap` / `spark` 等）や個別の `body` を編集して再実行する:

    python3 tools/generate_treasure_icons.py

実行後は `flutter test`（ドリフト検出テスト含む）と実機ビルドで見た目を確認すること。
"""
import math, os
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "assets", "treasure_icons"))
os.makedirs(OUT, exist_ok=True)

def rgrad(i,cx,cy,r,stops):
    s="".join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o,c,a in stops)
    return f'<radialGradient id="{i}" cx="{cx}%" cy="{cy}%" r="{r}%">{s}</radialGradient>'
def lgrad(i,x1,y1,x2,y2,stops):
    s="".join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o,c,a in stops)
    return f'<linearGradient id="{i}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{s}</linearGradient>'
def spark(cx,cy,s,op=1.0):
    ir=0.18*s
    p=f"M{cx} {cy-s} L{cx+ir} {cy-ir} L{cx+s} {cy} L{cx+ir} {cy+ir} L{cx} {cy+s} L{cx-ir} {cy+ir} L{cx-s} {cy} L{cx-ir} {cy-ir} Z"
    return f'<path d="{p}" fill="#FFFFFF" opacity="{op}"/>'

def halo(color):
    return rgrad("halo",50,52,52,[(0,color,0.9),(0.55,color,0.4),(1,color,0)])

def wrap(slug, hc, defs, body, sparks, shadow=True, out=None):
    d = halo(color=hc)+"".join(defs)
    sh = '<ellipse cx="50" cy="92" rx="22" ry="4.5" fill="#000000" opacity="0.11"/>' if shadow else ""
    sp = "".join(spark(*s) for s in sparks)
    svg=(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">'
         f'<defs>{d}</defs>'
         f'<circle cx="50" cy="52" r="52" fill="url(#halo)"/>{sh}{body}{sp}</svg>')
    open(f"{out or OUT}/{slug}.svg","w").write(svg)

# ---- volume overlay helper (vertical bottom shade) ----
def volgrad(i, dark):
    return lgrad(i,0,0,0,1,[(0.42,dark,0),(1,dark,0.5)])

icons={}

# duck (creature, face) ---------------------------------------------------
icons["duck"]=dict(hc="#FFE066",
 defs=[rgrad("b",40,32,80,[(0,"#FFF3BF",1),(45,"#FFD43B",1),(100,"#E8A100",1)]),
       lgrad("beak",0,0,1,0,[(0,"#FFA94D",1),(1,"#E8590C",1)])],
 body=('<ellipse cx="45" cy="62" rx="26" ry="19" fill="url(#b)"/>'
       '<circle cx="65" cy="40" r="15" fill="url(#b)"/>'
       '<path d="M77 36 L93 41 L77 47 Z" fill="url(#beak)"/>'
       '<ellipse cx="35" cy="60" rx="12" ry="9" fill="#000000" opacity="0.06"/>'
       '<circle cx="68" cy="37" r="2.6" fill="#3B2B12"/>'
       '<circle cx="69" cy="36" r="0.9" fill="#FFF"/>'),
 sparks=[(33,46,6,0.95),(58,72,4,0.85)])

# ball (beach ball) -------------------------------------------------------
def ball_body():
    cx,cy,r=50,52,30
    cols=["#FF6B6B","#FFD43B","#51CF66","#4DABF7","#E599F7","#FF922B"]
    segs=[]
    pts=[]
    for k in range(6):
        a=math.radians(-90+60*k)
        pts.append((cx+r*math.cos(a),cy+r*math.sin(a)))
    for k in range(6):
        x1,y1=pts[k]; x2,y2=pts[(k+1)%6]
        segs.append(f'<path d="M{cx} {cy} L{x1:.1f} {y1:.1f} A{r} {r} 0 0 1 {x2:.1f} {y2:.1f} Z" fill="{cols[k]}"/>')
    base=f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#FFFFFF"/>'
    cap=f'<circle cx="{cx}" cy="{cy}" r="5.5" fill="#FFFFFF"/><circle cx="{cx}" cy="{cy}" r="5.5" fill="url(#v)"/>'
    vol=f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#v)"/>'
    sh=f'<ellipse cx="40" cy="42" rx="9" ry="12" fill="#FFFFFF" opacity="0.35"/>'
    return base+"".join(segs)+vol+sh+cap
icons["ball"]=dict(hc="#4DABF7",
 defs=[volgrad("v","#1A1A2E")],
 body=ball_body(), sparks=[(68,40,5,0.9),(40,72,3.5,0.8)])

# flower (daisy) ----------------------------------------------------------
def flower_body():
    cx,cy=50,50; pet=[]
    for k in range(8):
        pet.append(f'<ellipse cx="{cx}" cy="{cy-21}" rx="7.5" ry="13" fill="url(#pet)" transform="rotate({k*45} {cx} {cy})"/>')
    center=f'<circle cx="{cx}" cy="{cy}" r="12" fill="url(#c)"/><ellipse cx="46" cy="46" rx="3.5" ry="4.5" fill="#FFFFFF" opacity="0.5"/>'
    return "".join(pet)+center
icons["flower"]=dict(hc="#F783AC",
 defs=[rgrad("pet",50,50,70,[(0,"#FFFFFF",1),(60,"#FFC9DE",1),(100,"#F06595",1)]),
       rgrad("c",40,35,80,[(0,"#FFE066",1),(100,"#F08C00",1)])],
 body=flower_body(), sparks=[(50,30,5,0.9),(72,62,3.5,0.8)])

# heart -------------------------------------------------------------------
icons["heart"]=dict(hc="#FF6B6B",
 defs=[rgrad("b",38,30,85,[(0,"#FFC9C9",1),(40,"#FF5252",1),(100,"#A51111",1)]),
       volgrad("v","#5A0808")],
 body=('<path id="h" d="M50 84 C16 58 16 30 35 25 C45 22 50 31 50 36 C50 31 55 22 65 25 C84 30 84 58 50 84 Z" fill="url(#b)"/>'
       '<path d="M50 84 C16 58 16 30 35 25 C45 22 50 31 50 36 C50 31 55 22 65 25 C84 30 84 58 50 84 Z" fill="url(#v)"/>'
       '<path d="M30 34 C26 41 27 50 31 55 C35 47 36 39 41 33 C37 31 33 31 30 34 Z" fill="#FFFFFF" opacity="0.55"/>'),
 sparks=[(64,40,5.5,0.95),(44,66,3.5,0.85)])

# leaf --------------------------------------------------------------------
icons["leaf"]=dict(hc="#51CF66",
 defs=[rgrad("b",38,30,85,[(0,"#D3F9D8",1),(45,"#51CF66",1),(100,"#2B8A3E",1)])],
 body=('<path d="M50 14 C72 28 72 66 50 88 C28 66 28 28 50 14 Z" fill="url(#b)"/>'
       '<path d="M50 18 L50 84" stroke="#2B8A3E" stroke-width="2.4" stroke-linecap="round" opacity="0.7"/>'
       '<path d="M50 38 L62 32 M50 52 L64 48 M50 66 L60 64 M50 38 L38 32 M50 52 L36 48" stroke="#2B8A3E" stroke-width="1.6" opacity="0.5" fill="none"/>'
       '<path d="M40 30 C36 40 37 52 42 60" stroke="#FFFFFF" stroke-width="3" opacity="0.35" fill="none" stroke-linecap="round"/>'),
 sparks=[(58,28,5,0.9),(44,72,3,0.8)])

# rabbit (creature, face) -------------------------------------------------
icons["rabbit"]=dict(hc="#F8C5D8",
 defs=[rgrad("b",42,32,80,[(0,"#FFFFFF",1),(70,"#F5F0F7",1),(100,"#D9CFE0",1)])],
 body=('<ellipse cx="40" cy="30" rx="7" ry="19" fill="url(#b)" transform="rotate(-12 40 30)"/>'
       '<ellipse cx="60" cy="30" rx="7" ry="19" fill="url(#b)" transform="rotate(12 60 30)"/>'
       '<ellipse cx="40" cy="30" rx="3" ry="12" fill="#F8C5D8" transform="rotate(-12 40 30)"/>'
       '<ellipse cx="60" cy="30" rx="3" ry="12" fill="#F8C5D8" transform="rotate(12 60 30)"/>'
       '<circle cx="50" cy="60" r="23" fill="url(#b)"/>'
       '<circle cx="42" cy="57" r="2.6" fill="#5B4B57"/><circle cx="58" cy="57" r="2.6" fill="#5B4B57"/>'
       '<ellipse cx="50" cy="64" rx="3.2" ry="2.4" fill="#F06595"/>'
       '<circle cx="39" cy="64" r="3.6" fill="#FFC9DE" opacity="0.7"/><circle cx="61" cy="64" r="3.6" fill="#FFC9DE" opacity="0.7"/>'),
 sparks=[(66,48,5,0.9),(34,68,3,0.8)])

# bug (ladybug, face) -----------------------------------------------------
icons["bug"]=dict(hc="#FF6B6B",
 defs=[rgrad("b",40,30,82,[(0,"#FF8787",1),(45,"#FA5252",1),(100,"#C92A2A",1)])],
 body=('<path d="M40 30 L42 24 M60 30 L58 24" stroke="#222" stroke-width="2.2" stroke-linecap="round"/>'
       '<circle cx="40" cy="22" r="2.4" fill="#222"/><circle cx="60" cy="22" r="2.4" fill="#222"/>'
       '<ellipse cx="50" cy="56" rx="25" ry="22" fill="url(#b)"/>'
       '<path d="M50 36 A20 20 0 0 0 31 44 A25 22 0 0 1 50 34 Z" fill="#222"/>'
       '<path d="M50 36 A20 20 0 0 1 69 44 A25 22 0 0 0 50 34 Z" fill="#222"/>'
       '<path d="M28 40 A28 28 0 0 0 28 50 Q40 46 40 40 Z" fill="#222"/>'  # head left top
       '<path d="M36 38 A18 14 0 0 1 64 38 L64 40 A24 22 0 0 0 36 40 Z" fill="#222"/>'
       '<path d="M50 36 L50 78" stroke="#222" stroke-width="2.4"/>'
       '<circle cx="40" cy="52" r="3.6" fill="#222"/><circle cx="60" cy="52" r="3.6" fill="#222"/>'
       '<circle cx="36" cy="66" r="3" fill="#222"/><circle cx="64" cy="66" r="3" fill="#222"/>'
       '<circle cx="43" cy="40" r="2.4" fill="#FFF"/><circle cx="57" cy="40" r="2.4" fill="#FFF"/>'
       '<ellipse cx="40" cy="48" rx="6" ry="8" fill="#FFFFFF" opacity="0.18"/>'),
 sparks=[(70,46,4.5,0.9),(30,62,3,0.8)])

# anchor ------------------------------------------------------------------
icons["anchor"]=dict(hc="#4DABF7",
 defs=[lgrad("m",0,0,0,1,[(0,"#A5D8FF",1),(1,"#1971C2",1)])],
 body=('<g fill="none" stroke="url(#m)" stroke-width="6" stroke-linecap="round" stroke-linejoin="round">'
       '<circle cx="50" cy="16" r="7"/>'
       '<path d="M50 23 L50 80"/>'
       '<path d="M34 34 L66 34"/>'
       '<path d="M27 56 C28 70 38 78 49 79"/>'
       '<path d="M73 56 C72 70 62 78 51 79"/>'
       '</g>'
       '<path d="M27 56 L17 50 L18 66 Z" fill="url(#m)"/><path d="M73 56 L83 50 L82 66 Z" fill="url(#m)"/>'
       '<path d="M50 78 L45 86 L55 86 Z" fill="url(#m)"/>'
       '<circle cx="50" cy="16" r="3" fill="#1971C2"/>'
       '<circle cx="46" cy="13" r="1.5" fill="#FFFFFF" opacity="0.7"/>'),
 sparks=[(70,40,4.5,0.9),(30,72,3,0.75)])

# swimmer (swim ring) -----------------------------------------------------
def ring_body():
    cx,cy,R=50,52,28
    segs=[]; cols=["#FF6B6B","#FFFFFF","#FF6B6B","#FFFFFF"]
    for k in range(4):
        a1=math.radians(-90+90*k); a2=math.radians(-90+90*(k+1))
        x1,y1=cx+R*math.cos(a1),cy+R*math.sin(a1); x2,y2=cx+R*math.cos(a2),cy+R*math.sin(a2)
        segs.append(f'<path d="M{cx} {cy} L{x1:.1f} {y1:.1f} A{R} {R} 0 0 1 {x2:.1f} {y2:.1f} Z" fill="{cols[k]}"/>')
    return (f'<circle cx="{cx}" cy="{cy}" r="{R}" fill="#FFF"/>'+"".join(segs)+
            f'<circle cx="{cx}" cy="{cy}" r="{R}" fill="url(#v)"/>'+
            f'<circle cx="{cx}" cy="{cy}" r="12" fill="#FFFFFF"/>'+
            f'<ellipse cx="38" cy="40" rx="6" ry="9" fill="#FFFFFF" opacity="0.5"/>')
icons["swimmer"]=dict(hc="#22B8CF", defs=[volgrad("v","#0B3D4A")],
 body=ring_body(), sparks=[(70,42,5,0.9),(40,76,3,0.8)])

# umbrella ----------------------------------------------------------------
icons["umbrella"]=dict(hc="#FF8787",
 defs=[rgrad("b",40,40,80,[(0,"#FFC9C9",1),(50,"#FA5252",1),(100,"#C92A2A",1)])],
 body=('<path d="M18 54 A32 24 0 0 1 82 54 Z" fill="url(#b)"/>'
       '<path d="M18 54 Q26 63 34 54 Q42 63 50 54 Q58 63 66 54 Q74 63 82 54 L82 54 L18 54 Z" fill="url(#b)"/>'
       '<rect x="48" y="16" width="4" height="10" rx="2" fill="#5A3A2A"/>'
       '<path d="M50 26 L50 80 Q50 86 43 84" fill="none" stroke="#5A3A2A" stroke-width="4" stroke-linecap="round"/>'
       '<path d="M34 50 Q42 24 50 22 M50 22 Q58 24 66 50" stroke="#FFFFFF" stroke-width="1.6" opacity="0.45" fill="none"/>'),
 sparks=[(30,38,5,0.9),(70,40,4,0.8)])

# car ---------------------------------------------------------------------
icons["car"]=dict(hc="#FF8787",
 defs=[lgrad("b",0,0,0,1,[(0,"#FF8787",1),(1,"#E03131",1)]),
       lgrad("g",0,0,0,1,[(0,"#D0EBFF",1),(1,"#74C0FC",1)])],
 body=('<path d="M18 64 L22 50 Q26 40 38 40 L62 40 Q74 40 78 50 L82 64 Q82 70 76 70 L24 70 Q18 70 18 64 Z" fill="url(#b)"/>'
       '<path d="M34 41 L40 30 Q42 27 48 27 L58 27 Q64 27 66 32 L70 41 Z" fill="url(#g)"/>'
       '<circle cx="32" cy="70" r="9" fill="#343A40"/><circle cx="32" cy="70" r="4" fill="#CED4DA"/>'
       '<circle cx="68" cy="70" r="9" fill="#343A40"/><circle cx="68" cy="70" r="4" fill="#CED4DA"/>'
       '<circle cx="78" cy="54" r="3" fill="#FFE066"/>'
       '<path d="M24 52 Q40 46 60 48" stroke="#FFFFFF" stroke-width="2" opacity="0.35" fill="none"/>'),
 sparks=[(30,44,4.5,0.9),(64,58,3,0.7)])

# key ---------------------------------------------------------------------
icons["key"]=dict(hc="#FFD43B",
 defs=[rgrad("b",40,35,80,[(0,"#FFF3BF",1),(45,"#FFD43B",1),(100,"#E8950C",1)])],
 body=('<circle cx="34" cy="34" r="16" fill="url(#b)"/><circle cx="34" cy="34" r="6.5" fill="#FFF7E0"/>'
       '<rect x="44" y="44" width="40" height="9" rx="4" fill="url(#b)" transform="rotate(45 44 44)"/>'
       '<rect x="66" y="62" width="10" height="9" rx="2" fill="url(#b)" transform="rotate(45 66 62)"/>'
       '<rect x="74" y="70" width="10" height="9" rx="2" fill="url(#b)" transform="rotate(45 74 70)"/>'
       '<circle cx="29" cy="29" r="3" fill="#FFFFFF" opacity="0.7"/>'),
 sparks=[(60,40,5,0.9),(48,66,3,0.8)])

# cake --------------------------------------------------------------------
icons["cake"]=dict(hc="#FFA8C5",
 defs=[lgrad("cream",0,0,0,1,[(0,"#FFF0F6",1),(1,"#FFC9DE",1)]),
       lgrad("base",0,0,0,1,[(0,"#FFE3A3",1),(1,"#E8950C",1)])],
 body=('<rect x="22" y="58" width="56" height="22" rx="6" fill="url(#base)"/>'
       '<rect x="28" y="42" width="44" height="20" rx="6" fill="url(#cream)"/>'
       '<path d="M28 50 q6 8 11 0 q6 8 11 0 q6 8 11 0 q5 7 11 0 L72 60 L28 60 Z" fill="#FF8FB1"/>'
       '<rect x="48" y="26" width="4" height="16" rx="2" fill="#74C0FC"/>'
       '<path d="M50 18 q4 4 0 8 q-4 -4 0 -8 Z" fill="#FF922B"/>'
       '<circle cx="36" cy="70" r="2" fill="#FFD43B"/><circle cx="50" cy="72" r="2" fill="#74C0FC"/><circle cx="64" cy="70" r="2" fill="#51CF66"/>'),
 sparks=[(34,44,4.5,0.9),(68,50,3,0.8)])

# gift --------------------------------------------------------------------
icons["gift"]=dict(hc="#FF8787",
 defs=[lgrad("box",0,0,0,1,[(0,"#FF8787",1),(1,"#C92A2A",1)])],
 body=('<rect x="24" y="44" width="52" height="40" rx="5" fill="url(#box)"/>'
       '<rect x="20" y="36" width="60" height="12" rx="4" fill="#FA5252"/>'
       '<rect x="45" y="36" width="10" height="48" fill="#FFD43B"/>'
       '<path d="M50 36 C40 22 26 28 34 34 C40 38 50 36 50 36 Z" fill="#FFD43B"/>'
       '<path d="M50 36 C60 22 74 28 66 34 C60 38 50 36 50 36 Z" fill="#FFD43B"/>'
       '<circle cx="50" cy="35" r="4" fill="#FFE066"/>'
       '<rect x="28" y="48" width="6" height="32" fill="#FFFFFF" opacity="0.18"/>'),
 sparks=[(34,54,4.5,0.9),(66,66,3,0.8)])

# gem ---------------------------------------------------------------------
icons["gem"]=dict(hc="#4DABF7",
 defs=[lgrad("b",0,0,0,1,[(0,"#D0EBFF",1),(1,"#1C7ED6",1)])],
 body=('<path d="M30 36 L70 36 L84 50 L50 86 L16 50 Z" fill="url(#b)"/>'
       '<path d="M30 36 L40 50 L16 50 Z" fill="#A5D8FF" opacity="0.8"/>'
       '<path d="M70 36 L60 50 L84 50 Z" fill="#4DABF7" opacity="0.9"/>'
       '<path d="M30 36 L40 50 L60 50 L70 36 Z" fill="#74C0FC"/>'
       '<path d="M40 50 L60 50 L50 86 Z" fill="#1C7ED6"/>'
       '<path d="M16 50 L40 50 L50 86 Z" fill="#1971C2" opacity="0.9"/>'
       '<path d="M33 40 L44 40" stroke="#FFFFFF" stroke-width="2" opacity="0.6" stroke-linecap="round"/>'),
 sparks=[(64,44,5,0.95),(40,64,3.5,0.85),(72,56,2.5,0.7)])

# music note --------------------------------------------------------------
icons["music"]=dict(hc="#B197FC",
 defs=[lgrad("b",0,0,0,1,[(0,"#B197FC",1),(1,"#6741D9",1)])],
 body=('<rect x="58" y="22" width="6" height="44" rx="3" fill="url(#b)"/>'
       '<rect x="38" y="28" width="6" height="44" rx="3" fill="url(#b)"/>'
       '<path d="M41 22 L64 18 L64 30 L41 34 Z" fill="url(#b)"/>'
       '<ellipse cx="36" cy="72" rx="11" ry="8" fill="url(#b)" transform="rotate(-18 36 72)"/>'
       '<ellipse cx="56" cy="66" rx="11" ry="8" fill="url(#b)" transform="rotate(-18 56 66)"/>'
       '<ellipse cx="33" cy="69" rx="3.5" ry="2.5" fill="#FFFFFF" opacity="0.4" transform="rotate(-18 33 69)"/>'),
 sparks=[(70,30,4.5,0.9),(48,52,3,0.8)])

# cloud -------------------------------------------------------------------
icons["cloud"]=dict(hc="#74C0FC",
 defs=[lgrad("b",0,0,0,1,[(0,"#FFFFFF",1),(1,"#C5D9EC",1)])],
 body=('<g fill="url(#b)">'
       '<circle cx="36" cy="56" r="16"/><circle cx="54" cy="48" r="20"/><circle cx="68" cy="58" r="14"/>'
       '<rect x="32" y="56" width="40" height="16" rx="8"/></g>'
       '<ellipse cx="48" cy="42" rx="10" ry="5" fill="#FFFFFF" opacity="0.6"/>'),
 sparks=[(70,42,5,0.9),(34,68,3,0.8)])

# moon --------------------------------------------------------------------
icons["moon"]=dict(hc="#FFE066",
 defs=[lgrad("b",0,0,1,1,[(0,"#FFF9DB",1),(1,"#FFD43B",1)])],
 body=('<path d="M64 16 A36 36 0 1 0 64 84 A28 28 0 1 1 64 16 Z" fill="url(#b)"/>'
       '<circle cx="40" cy="38" r="4" fill="#F2C200" opacity="0.5"/>'
       '<circle cx="34" cy="58" r="3" fill="#F2C200" opacity="0.5"/>'
       '<circle cx="48" cy="64" r="2.4" fill="#F2C200" opacity="0.5"/>'),
 sparks=[(70,30,5,0.95),(74,60,3.5,0.85)])

# icecream ----------------------------------------------------------------
icons["icecream"]=dict(hc="#FFB6C1",
 defs=[lgrad("cone",0,0,0,1,[(0,"#F0C27B",1),(1,"#B07B2E",1)]),
       rgrad("s1",40,35,80,[(0,"#FFF0F6",1),(100,"#FF8FB1",1)]),
       rgrad("s2",40,35,80,[(0,"#FFFDEB",1),(100,"#FFD8A8",1)])],
 body=('<path d="M34 52 L66 52 L50 90 Z" fill="url(#cone)"/>'
       '<path d="M40 56 L60 56 M37 62 L63 62" stroke="#8C5A1E" stroke-width="1.4" opacity="0.5"/>'
       '<circle cx="42" cy="46" r="14" fill="url(#s2)"/>'
       '<circle cx="58" cy="46" r="14" fill="url(#s1)"/>'
       '<circle cx="50" cy="36" r="13" fill="url(#s1)"/>'
       '<circle cx="50" cy="24" r="4" fill="#E03131"/>'
       '<ellipse cx="46" cy="32" rx="3" ry="4" fill="#FFFFFF" opacity="0.5"/>'),
 sparks=[(68,34,4.5,0.9),(34,40,3,0.8)])

# cookie ------------------------------------------------------------------
icons["cookie"]=dict(hc="#D9A066",
 defs=[rgrad("b",40,35,80,[(0,"#F0C27B",1),(60,"#D9A066",1),(100,"#A6713A",1)])],
 body=('<circle cx="50" cy="52" r="30" fill="url(#b)"/>'
       '<circle cx="40" cy="42" r="4" fill="#5A3A22"/><circle cx="62" cy="44" r="4.5" fill="#5A3A22"/>'
       '<circle cx="54" cy="60" r="4" fill="#5A3A22"/><circle cx="36" cy="60" r="3.5" fill="#5A3A22"/>'
       '<circle cx="66" cy="62" r="3" fill="#5A3A22"/><circle cx="50" cy="36" r="3" fill="#5A3A22"/>'
       '<ellipse cx="40" cy="40" rx="8" ry="6" fill="#FFFFFF" opacity="0.18"/>'),
 sparks=[(70,38,4.5,0.9),(34,68,3,0.8)])

# pizza -------------------------------------------------------------------
icons["pizza"]=dict(hc="#FFA94D",
 defs=[lgrad("ch",0,0,0,1,[(0,"#FFE066",1),(1,"#FFC078",1)])],
 body=('<path d="M50 16 L80 78 Q50 90 20 78 Z" fill="url(#ch)"/>'
       '<path d="M20 78 Q50 90 80 78 L84 84 Q50 96 16 84 Z" fill="#E8950C"/>'
       '<circle cx="44" cy="50" r="5" fill="#E03131"/><circle cx="60" cy="58" r="5" fill="#E03131"/>'
       '<circle cx="50" cy="70" r="4.5" fill="#E03131"/><circle cx="38" cy="66" r="3.5" fill="#C92A2A"/>'
       '<circle cx="52" cy="38" r="2.6" fill="#51CF66"/><circle cx="62" cy="44" r="2.4" fill="#51CF66"/>'),
 sparks=[(40,34,4,0.9),(66,68,3,0.75)])

# bell --------------------------------------------------------------------
icons["bell"]=dict(hc="#FFD43B",
 defs=[rgrad("b",40,32,80,[(0,"#FFF3BF",1),(50,"#FFD43B",1),(100,"#E8950C",1)])],
 body=('<rect x="46" y="18" width="8" height="8" rx="3" fill="#E8950C"/>'
       '<path d="M50 24 C34 24 32 44 28 62 Q26 70 24 72 L76 72 Q74 70 72 62 C68 44 66 24 50 24 Z" fill="url(#b)"/>'
       '<rect x="24" y="70" width="52" height="7" rx="3.5" fill="#E8950C"/>'
       '<circle cx="50" cy="82" r="5" fill="#C77800"/>'
       '<path d="M40 34 C36 42 35 54 35 62" stroke="#FFFFFF" stroke-width="3" opacity="0.4" fill="none" stroke-linecap="round"/>'),
 sparks=[(66,34,4.5,0.9),(38,62,3,0.8)])

# lightbulb ---------------------------------------------------------------
icons["lightbulb"]=dict(hc="#FFE066",
 defs=[rgrad("b",42,36,80,[(0,"#FFFDEB",1),(55,"#FFE066",1),(100,"#FAB005",1)])],
 body=('<g stroke="#FFD43B" stroke-width="3" stroke-linecap="round">'
       '<path d="M50 8 L50 16"/><path d="M22 22 L28 28"/><path d="M78 22 L72 28"/><path d="M14 50 L22 50"/><path d="M86 50 L78 50"/></g>'
       '<circle cx="50" cy="48" r="24" fill="url(#b)"/>'
       '<path d="M40 66 Q50 72 60 66 L60 74 Q50 78 40 74 Z" fill="#ADB5BD"/>'
       '<rect x="42" y="74" width="16" height="5" rx="2" fill="#868E96"/>'
       '<path d="M44 40 C42 48 44 56 50 62 M56 40 C58 48 56 56 50 62" stroke="#E8950C" stroke-width="2" fill="none" opacity="0.6"/>'
       '<ellipse cx="40" cy="38" rx="5" ry="8" fill="#FFFFFF" opacity="0.5"/>'),
 sparks=[(70,30,5,0.95),(30,60,3,0.8)])

# cat (creature, face) ----------------------------------------------------
icons["cat"]=dict(hc="#FFB066",
 defs=[rgrad("b",42,34,80,[(0,"#FFD8A8",1),(60,"#FFA94D",1),(100,"#E8590C",1)])],
 body=('<path d="M30 34 L36 54 L24 52 Z" fill="url(#b)"/><path d="M70 34 L64 54 L76 52 Z" fill="url(#b)"/>'
       '<path d="M33 38 L37 50 L29 49 Z" fill="#FF8FB1"/><path d="M67 38 L63 50 L71 49 Z" fill="#FF8FB1"/>'
       '<circle cx="50" cy="58" r="25" fill="url(#b)"/>'
       '<ellipse cx="41" cy="54" rx="3" ry="4.5" fill="#3B2B22"/><ellipse cx="59" cy="54" rx="3" ry="4.5" fill="#3B2B22"/>'
       '<path d="M47 64 Q50 67 53 64" fill="none" stroke="#3B2B22" stroke-width="2" stroke-linecap="round"/>'
       '<path d="M50 61 L50 64" stroke="#3B2B22" stroke-width="2" stroke-linecap="round"/>'
       '<g stroke="#3B2B22" stroke-width="1.4" stroke-linecap="round"><path d="M30 60 L20 58 M30 64 L20 65 M70 60 L80 58 M70 64 L80 65"/></g>'
       '<circle cx="38" cy="64" r="3.5" fill="#FF8FB1" opacity="0.6"/><circle cx="62" cy="64" r="3.5" fill="#FF8FB1" opacity="0.6"/>'),
 sparks=[(70,44,4.5,0.9),(32,72,3,0.8)])

# sailboat ----------------------------------------------------------------
icons["sailboat"]=dict(hc="#74C0FC",
 defs=[lgrad("hull",0,0,0,1,[(0,"#FF8787",1),(1,"#C92A2A",1)]),
       lgrad("wave",0,0,0,1,[(0,"#A5D8FF",1),(1,"#4DABF7",1)])],
 body=('<path d="M52 20 L52 60 L80 60 Z" fill="#FFFFFF"/>'
       '<path d="M48 24 L48 60 L24 60 Z" fill="#E9ECEF"/>'
       '<rect x="49" y="18" width="3" height="44" rx="1.5" fill="#8C5A1E"/>'
       '<path d="M20 64 L80 64 L72 78 Q50 84 28 78 Z" fill="url(#hull)"/>'
       '<path d="M14 82 Q26 76 38 82 T62 82 T86 82" stroke="url(#wave)" stroke-width="4" fill="none" stroke-linecap="round"/>'),
 sparks=[(70,36,4.5,0.9),(30,40,3,0.8)])

# crown -------------------------------------------------------------------
icons["crown"]=dict(hc="#FFD43B",
 defs=[lgrad("b",0,0,0,1,[(0,"#FFF3BF",1),(1,"#E8950C",1)])],
 body=('<path d="M22 70 L18 36 L34 50 L50 26 L66 50 L82 36 L78 70 Z" fill="url(#b)"/>'
       '<rect x="22" y="70" width="56" height="10" rx="3" fill="#E8950C"/>'
       '<circle cx="50" cy="28" r="4" fill="#FF6B6B"/>'
       '<circle cx="18" cy="36" r="3.5" fill="#4DABF7"/><circle cx="82" cy="36" r="3.5" fill="#4DABF7"/>'
       '<circle cx="36" cy="74" r="2.6" fill="#51CF66"/><circle cx="50" cy="74" r="2.6" fill="#FF6B6B"/><circle cx="64" cy="74" r="2.6" fill="#4DABF7"/>'),
 sparks=[(34,46,4.5,0.9),(66,46,3.5,0.85)])

# fire --------------------------------------------------------------------
icons["fire"]=dict(hc="#FF922B",
 defs=[lgrad("o",0,0,0,1,[(0,"#FFD43B",1),(1,"#E8590C",1)]),
       lgrad("y",0,0,0,1,[(0,"#FFF3BF",1),(1,"#FFA94D",1)])],
 body=('<path d="M50 12 C66 30 74 42 74 58 A24 24 0 0 1 26 58 C26 46 32 40 38 34 C40 44 46 44 46 36 C46 26 48 18 50 12 Z" fill="url(#o)"/>'
       '<path d="M50 40 C58 50 62 56 62 64 A12 12 0 0 1 38 64 C38 56 42 52 46 48 C48 54 52 52 50 46 Z" fill="url(#y)"/>'),
 sparks=[(68,32,4.5,0.9),(32,46,3,0.8)])

# kite --------------------------------------------------------------------
icons["kite"]=dict(hc="#FF8787",
 defs=[],
 body=('<path d="M50 14 L74 44 L50 74 L26 44 Z" fill="#FF6B6B"/>'
       '<path d="M50 14 L50 74 M26 44 L74 44" stroke="#FFFFFF" stroke-width="2.5"/>'
       '<path d="M50 14 L74 44 L50 44 Z" fill="#FFD43B"/>'
       '<path d="M50 44 L74 44 L50 74 Z" fill="#4DABF7"/>'
       '<path d="M26 44 L50 44 L50 74 Z" fill="#51CF66"/>'
       '<path d="M50 74 Q54 82 48 86 Q56 90 50 96" stroke="#E8950C" stroke-width="2.5" fill="none"/>'
       '<path d="M48 84 a3 3 0 1 0 0.1 0" fill="#FF6B6B"/><path d="M50 94 a2.6 2.6 0 1 0 0.1 0" fill="#4DABF7"/>'),
 sparks=[(60,30,4.5,0.9),(40,56,3,0.8)])

# cover_leaves ------------------------------------------------------------
icons["cover_leaves"]=dict(hc="#51CF66",
 defs=[lgrad("l1",0,0,1,1,[(0,"#B2F2BB",1),(1,"#2F9E44",1)]),
       lgrad("l2",0,0,1,1,[(0,"#8CE99A",1),(1,"#2B8A3E",1)])],
 body=('<path d="M50 40 C72 44 76 64 60 76 C40 72 38 52 50 40 Z" fill="url(#l2)" transform="rotate(20 55 58)"/>'
       '<path d="M50 38 C28 42 24 62 40 74 C60 70 62 50 50 38 Z" fill="url(#l1)" transform="rotate(-18 45 56)"/>'
       '<path d="M50 46 C58 54 58 66 52 74" stroke="#2B8A3E" stroke-width="2" fill="none" opacity="0.6"/>'),
 sparks=[(64,44,4.5,0.9),(36,68,3,0.8)])

# cover_snow --------------------------------------------------------------
icons["cover_snow"]=dict(hc="#A5D8FF",
 defs=[lgrad("b",0,0,0,1,[(0,"#FFFFFF",1),(1,"#C4DCF0",1)])],
 body=('<path d="M14 76 Q20 50 38 54 Q46 38 60 48 Q78 46 84 66 Q88 78 80 80 L20 80 Q12 80 14 76 Z" fill="url(#b)"/>'
       '<path d="M14 76 Q20 52 38 55" fill="none" stroke="#9CC3E6" stroke-width="2" opacity="0.6"/>'
       '<g stroke="#4DABF7" stroke-width="2.4" stroke-linecap="round" opacity="0.9"><path d="M40 28 L40 46 M32 32 L48 42 M48 32 L32 42"/></g>'
       '<circle cx="66" cy="32" r="2.6" fill="#4DABF7" opacity="0.8"/>'),
 sparks=[(72,54,4.5,0.9),(28,66,3,0.8)])

# cover_box ---------------------------------------------------------------
icons["cover_box"]=dict(hc="#D9A066",
 defs=[lgrad("b",0,0,0,1,[(0,"#E6B877",1),(1,"#A6713A",1)]),
       lgrad("t",0,0,0,1,[(0,"#F0C896",1),(1,"#C68A4A",1)])],
 body=('<rect x="22" y="44" width="56" height="38" rx="4" fill="url(#b)"/>'
       '<rect x="20" y="38" width="60" height="12" rx="3" fill="url(#t)"/>'
       '<rect x="44" y="38" width="12" height="44" fill="#B5824A" opacity="0.7"/>'
       '<path d="M44 38 L50 30 L56 38 Z" fill="#C68A4A"/>'
       '<rect x="26" y="48" width="5" height="30" fill="#FFFFFF" opacity="0.14"/>'),
 sparks=[(34,52,4,0.85),(66,64,3,0.7)])

# rare_gem (rainbow) ------------------------------------------------------
icons["rare_gem"]=dict(hc="#E599F7",
 defs=[lgrad("b",0,0,1,1,[(0,"#FF9AA2",1),(25,"#FFD43B",1),(50,"#69DB7C",1),(75,"#4DABF7",1),(100,"#B197FC",1)])],
 body=('<path d="M30 36 L70 36 L84 50 L50 88 L16 50 Z" fill="url(#b)"/>'
       '<path d="M30 36 L40 50 L60 50 L70 36 Z" fill="#FFFFFF" opacity="0.35"/>'
       '<path d="M40 50 L60 50 L50 88 Z" fill="#FFFFFF" opacity="0.12"/>'
       '<path d="M33 40 L44 40" stroke="#FFFFFF" stroke-width="2" opacity="0.7" stroke-linecap="round"/>'),
 sparks=[(66,42,6,1.0),(38,62,4,0.9),(74,56,3,0.85),(50,30,3.5,0.9)])

# rare_crown (jeweled) ----------------------------------------------------
icons["rare_crown"]=dict(hc="#FFD43B",
 defs=[lgrad("b",0,0,0,1,[(0,"#FFF9DB",1),(1,"#E8950C",1)])],
 body=('<path d="M20 72 L16 32 L34 48 L50 22 L66 48 L84 32 L80 72 Z" fill="url(#b)"/>'
       '<rect x="20" y="72" width="60" height="11" rx="3" fill="#E8950C"/>'
       '<circle cx="50" cy="24" r="5" fill="#FF6B6B"/><circle cx="50" cy="24" r="2" fill="#FFFFFF" opacity="0.7"/>'
       '<circle cx="16" cy="32" r="4" fill="#4DABF7"/><circle cx="84" cy="32" r="4" fill="#51CF66"/>'
       '<circle cx="34" cy="76" r="3" fill="#51CF66"/><circle cx="50" cy="76" r="3" fill="#FF6B6B"/><circle cx="66" cy="76" r="3" fill="#4DABF7"/>'
       '<circle cx="34" cy="50" r="3" fill="#E599F7"/><circle cx="66" cy="50" r="3" fill="#E599F7"/>'),
 sparks=[(32,44,5,1.0),(68,44,4,0.9),(50,60,3,0.85)])

# rare_medal --------------------------------------------------------------
icons["rare_medal"]=dict(hc="#FFD43B",
 defs=[rgrad("b",42,34,80,[(0,"#FFF9DB",1),(50,"#FFD43B",1),(100,"#E8950C",1)])],
 body=('<path d="M36 14 L48 50 L40 52 L30 18 Z" fill="#FF6B6B"/>'
       '<path d="M64 14 L52 50 L60 52 L70 18 Z" fill="#4DABF7"/>'
       '<circle cx="50" cy="64" r="24" fill="url(#b)"/>'
       '<circle cx="50" cy="64" r="17" fill="none" stroke="#E8950C" stroke-width="2" opacity="0.6"/>'
       '<path d="M50 52 L54 62 L65 62 L56 69 L59 80 L50 73 L41 80 L44 69 L35 62 L46 62 Z" fill="#FFB000"/>'
       '<ellipse cx="42" cy="56" rx="5" ry="7" fill="#FFFFFF" opacity="0.35"/>'),
 sparks=[(70,52,5,0.95),(32,72,3.5,0.85)])

# ===== めくり露出(A1)用の追加カバー（テーマ別箱隠し） ==========================
# 既存: cover_leaves / cover_snow / cover_box。以下はステージのイメージに合わせた箱。

# cover_chest（木の宝箱）森/山/海/城など
icons["cover_chest"]=dict(hc="#C68A4A",
 defs=[lgrad("wood",0,0,0,1,[(0,"#D9A066",1),(1,"#8C5A2B",1)]),
       lgrad("lid",0,0,0,1,[(0,"#C68A4A",1),(1,"#9A6633",1)])],
 body=('<rect x="22" y="52" width="56" height="30" rx="3" fill="url(#wood)"/>'
       '<path d="M20 52 Q50 32 80 52 L80 56 L20 56 Z" fill="url(#lid)"/>'
       '<rect x="20" y="53" width="60" height="6" fill="#6E4423"/>'
       '<rect x="24" y="56" width="4" height="26" fill="#E8A100" opacity="0.85"/>'
       '<rect x="72" y="56" width="4" height="26" fill="#E8A100" opacity="0.85"/>'
       '<rect x="44" y="48" width="12" height="14" rx="2" fill="#FFD43B"/>'
       '<circle cx="50" cy="56" r="2.4" fill="#8C5A2B"/>'),
 sparks=[(68,46,4,0.85)])

# cover_shell（貝）海/海中
icons["cover_shell"]=dict(hc="#FFC9DE",
 defs=[rgrad("sh",50,80,80,[(0,"#FFF0F6",1),(60,"#FFC9DE",1),(100,"#F06595",1)])],
 body=('<path d="M50 26 C24 30 14 64 22 80 Q50 72 78 80 C86 64 76 30 50 26 Z" fill="url(#sh)"/>'
       '<g stroke="#E08DAA" stroke-width="2" opacity="0.55" fill="none" stroke-linecap="round">'
       '<path d="M50 34 L50 74"/><path d="M40 36 L33 72"/><path d="M60 36 L67 72"/>'
       '<path d="M32 42 L23 74"/><path d="M68 42 L77 74"/></g>'
       '<circle cx="50" cy="30" r="5" fill="#FFE0EC"/>'),
 sparks=[(70,40,4,0.85)])

# cover_cloud（雲）夜/宇宙/虹/銀河
icons["cover_cloud"]=dict(hc="#A5D8FF",
 defs=[lgrad("cl",0,0,0,1,[(0,"#FFFFFF",1),(1,"#CBE2F5",1)])],
 body=('<g fill="url(#cl)"><circle cx="34" cy="58" r="16"/><circle cx="52" cy="48" r="21"/>'
       '<circle cx="68" cy="58" r="15"/><rect x="30" y="58" width="42" height="18" rx="9"/></g>'
       '<ellipse cx="46" cy="44" rx="11" ry="5" fill="#FFFFFF" opacity="0.65"/>'),
 sparks=[(72,44,4,0.85)])

# cover_bush（茂み）森/街/花畑/海中
icons["cover_bush"]=dict(hc="#51CF66",
 defs=[rgrad("bs",42,34,82,[(0,"#B2F2BB",1),(60,"#51CF66",1),(100,"#2B8A3E",1)])],
 body=('<g fill="url(#bs)"><circle cx="35" cy="60" r="15"/><circle cx="52" cy="50" r="18"/>'
       '<circle cx="66" cy="60" r="14"/><circle cx="50" cy="64" r="16"/></g>'
       '<circle cx="46" cy="49" r="4" fill="#D3F9D8" opacity="0.5"/>'
       '<circle cx="62" cy="56" r="3" fill="#D3F9D8" opacity="0.45"/>'),
 sparks=[(70,46,4,0.85)])

# cover_rock（岩）山/砂漠/海中/宇宙/城/銀河
icons["cover_rock"]=dict(hc="#CED4DA",
 defs=[lgrad("rk",0,0,0,1,[(0,"#CED4DA",1),(1,"#868E96",1)])],
 body=('<path d="M22 78 Q19 56 36 50 Q44 40 58 46 Q80 44 80 66 Q82 78 72 78 Z" fill="url(#rk)"/>'
       '<path d="M36 54 Q47 49 57 54" stroke="#FFFFFF" stroke-width="2.5" opacity="0.3" fill="none" stroke-linecap="round"/>'
       '<path d="M50 56 L46 72 M59 60 L63 74" stroke="#5C636A" stroke-width="1.6" opacity="0.5" fill="none"/>'),
 sparks=[(68,46,3.5,0.8)])

# cover_star（星のかたまり）夜/宇宙/銀河
icons["cover_star"]=dict(hc="#FFE066",
 defs=[rgrad("st",50,40,70,[(0,"#FFFDEB",1),(45,"#FFE066",1),(100,"#F08C00",1)])],
 body=('<path d="M50 28 L57 44 L74 45 L61 56 L65 73 L50 63 L35 73 L39 56 L26 45 L43 44 Z" '
       'fill="url(#st)" stroke="#E8950C" stroke-width="2" stroke-linejoin="round"/>'
       '<path d="M50 28 L57 44 L50 56 L43 44 Z" fill="#FFFFFF" opacity="0.35"/>'),
 sparks=[(76,34,4.5,0.9),(28,66,3.5,0.85)])

# ===== ステージ別テーマ宝/ダミー 追加アイコン =====================================

# --- 森 ---
icons["mushroom"]=dict(hc="#FF8787",
 defs=[rgrad("c",42,30,80,[(0,"#FFC9C9",1),(45,"#FA5252",1),(100,"#C92A2A",1)])],
 body=('<rect x="42" y="52" width="16" height="28" rx="7" fill="#FFF3E0"/>'
       '<path d="M22 54 C22 32 78 32 78 54 Q50 64 22 54 Z" fill="url(#c)"/>'
       '<circle cx="38" cy="46" r="4" fill="#FFFFFF"/><circle cx="58" cy="44" r="5" fill="#FFFFFF"/>'
       '<circle cx="50" cy="52" r="3" fill="#FFFFFF"/>'),
 sparks=[(66,40,4,0.85)])
icons["acorn"]=dict(hc="#D9A066",
 defs=[lgrad("n",0,0,0,1,[(0,"#E6B877",1),(1,"#A6713A",1)])],
 body=('<path d="M30 44 Q50 84 70 44 Z" fill="url(#n)"/>'
       '<path d="M26 44 Q50 28 74 44 Q50 52 26 44 Z" fill="#7B4B2A"/>'
       '<rect x="47" y="22" width="6" height="10" rx="3" fill="#5A3A22"/>'
       '<ellipse cx="42" cy="54" rx="4" ry="6" fill="#FFFFFF" opacity="0.25"/>'),
 sparks=[(66,40,4,0.85)])
icons["fox"]=dict(hc="#FF922B",
 defs=[lgrad("f",0,0,0,1,[(0,"#FFB066",1),(1,"#E8590C",1)])],
 body=('<path d="M26 30 L36 52 L24 50 Z" fill="url(#f)"/><path d="M74 30 L64 52 L76 50 Z" fill="url(#f)"/>'
       '<path d="M50 34 C32 34 28 52 34 66 Q50 80 66 66 C72 52 68 34 50 34 Z" fill="url(#f)"/>'
       '<path d="M50 52 C42 52 40 64 50 72 C60 64 58 52 50 52 Z" fill="#FFF3E0"/>'
       '<circle cx="42" cy="52" r="3" fill="#3B2B22"/><circle cx="58" cy="52" r="3" fill="#3B2B22"/>'
       '<circle cx="50" cy="64" r="3" fill="#3B2B22"/>'),
 sparks=[(70,40,4,0.85)])
icons["owl"]=dict(hc="#C68A4A",
 defs=[lgrad("o",0,0,0,1,[(0,"#C68A4A",1),(1,"#8C5A2B",1)])],
 body=('<path d="M30 26 L40 40 L26 40 Z" fill="url(#o)"/><path d="M70 26 L60 40 L74 40 Z" fill="url(#o)"/>'
       '<ellipse cx="50" cy="56" rx="24" ry="26" fill="url(#o)"/>'
       '<circle cx="40" cy="48" r="10" fill="#FFFFFF"/><circle cx="60" cy="48" r="10" fill="#FFFFFF"/>'
       '<circle cx="40" cy="48" r="5" fill="#3B2B22"/><circle cx="60" cy="48" r="5" fill="#3B2B22"/>'
       '<path d="M46 56 L54 56 L50 64 Z" fill="#FFA94D"/>'),
 sparks=[(72,42,4,0.85)])
icons["butterfly"]=dict(hc="#E599F7",
 defs=[rgrad("w",50,50,70,[(0,"#FFD6F5",1),(60,"#DA77F2",1),(100,"#9C36B5",1)])],
 body=('<ellipse cx="34" cy="40" rx="16" ry="14" fill="url(#w)"/><ellipse cx="66" cy="40" rx="16" ry="14" fill="url(#w)"/>'
       '<ellipse cx="36" cy="64" rx="13" ry="12" fill="url(#w)"/><ellipse cx="64" cy="64" rx="13" ry="12" fill="url(#w)"/>'
       '<rect x="47" y="32" width="6" height="40" rx="3" fill="#5A3A57"/>'
       '<circle cx="34" cy="40" r="4" fill="#FFFFFF" opacity="0.6"/><circle cx="66" cy="40" r="4" fill="#FFFFFF" opacity="0.6"/>'),
 sparks=[(74,30,4,0.85)])
icons["bird"]=dict(hc="#74C0FC",
 defs=[lgrad("b",0,0,0,1,[(0,"#A5D8FF",1),(1,"#1C7ED6",1)])],
 body=('<ellipse cx="48" cy="54" rx="24" ry="20" fill="url(#b)"/>'
       '<circle cx="64" cy="42" r="13" fill="url(#b)"/>'
       '<path d="M76 42 L88 46 L76 50 Z" fill="#FFA94D"/>'
       '<circle cx="67" cy="40" r="2.6" fill="#1A1A2E"/>'
       '<path d="M30 50 Q40 64 52 58 Q44 54 36 48 Z" fill="#1971C2"/>'),
 sparks=[(70,62,4,0.8)])
icons["squirrel"]=dict(hc="#E6B877",
 defs=[lgrad("s",0,0,0,1,[(0,"#E6B877",1),(1,"#A6713A",1)])],
 body=('<path d="M66 82 C94 78 94 28 66 26 C84 40 82 62 60 64 C54 66 58 78 66 82 Z" fill="url(#s)"/>'
       '<ellipse cx="44" cy="62" rx="17" ry="19" fill="url(#s)"/>'
       '<ellipse cx="44" cy="66" rx="9" ry="11" fill="#FFE6C8" opacity="0.75"/>'
       '<circle cx="42" cy="38" r="12" fill="url(#s)"/>'
       '<circle cx="38" cy="28" r="5" fill="url(#s)"/>'
       '<circle cx="40" cy="38" r="2.6" fill="#3B2B22"/>'
       '<circle cx="32" cy="40" r="2.2" fill="#5A3A22"/>'),
 sparks=[(74,46,4,0.8)])
icons["hedgehog"]=dict(hc="#C68A4A",
 defs=[lgrad("h",0,0,0,1,[(0,"#A6713A",1),(1,"#5A3A22",1)])],
 body=('<ellipse cx="52" cy="60" rx="28" ry="19" fill="url(#h)"/>'
       '<path d="M28 58 L34 38 L42 58 Z" fill="#8C5A2B"/>'
       '<path d="M40 58 L48 32 L56 58 Z" fill="#A6713A"/>'
       '<path d="M54 58 L62 34 L70 58 Z" fill="#8C5A2B"/>'
       '<path d="M66 58 L74 40 L80 58 Z" fill="#A6713A"/>'
       '<ellipse cx="32" cy="64" rx="12" ry="10" fill="#F0C896"/>'
       '<circle cx="24" cy="66" r="3" fill="#3B2B22"/>'
       '<circle cx="34" cy="60" r="2.4" fill="#3B2B22"/>'),
 sparks=[(72,52,4,0.8)])

# --- 海 / 海中 ---
icons["starfish"]=dict(hc="#FF922B",
 defs=[rgrad("s",50,42,70,[(0,"#FFD8A8",1),(45,"#FF922B",1),(100,"#E8590C",1)])],
 body=('<path d="M50 16 L60 42 L88 44 L64 60 L72 86 L50 70 L28 86 L36 60 L12 44 L40 42 Z" '
       'fill="url(#s)" stroke="#D9480F" stroke-width="2" stroke-linejoin="round"/>'
       '<circle cx="50" cy="50" r="3" fill="#FFE0C2"/><circle cx="42" cy="44" r="2" fill="#FFE0C2"/>'
       '<circle cx="58" cy="44" r="2" fill="#FFE0C2"/><circle cx="46" cy="58" r="2" fill="#FFE0C2"/>'
       '<circle cx="54" cy="58" r="2" fill="#FFE0C2"/>'),
 sparks=[(74,36,4,0.85)])
icons["crab"]=dict(hc="#FF6B6B",
 defs=[rgrad("c",42,34,80,[(0,"#FF8787",1),(45,"#FA5252",1),(100,"#C92A2A",1)])],
 body=('<ellipse cx="50" cy="56" rx="24" ry="16" fill="url(#c)"/>'
       '<g stroke="#C92A2A" stroke-width="3" stroke-linecap="round"><path d="M30 60 L18 70 M34 64 L24 76 M70 60 L82 70 M66 64 L76 76"/></g>'
       '<path d="M30 48 C20 42 16 50 22 54 C26 50 30 50 30 50 Z" fill="url(#c)"/>'
       '<circle cx="18" cy="48" r="5" fill="url(#c)"/>'
       '<path d="M70 48 C80 42 84 50 78 54 C74 50 70 50 70 50 Z" fill="url(#c)"/>'
       '<circle cx="82" cy="48" r="5" fill="url(#c)"/>'
       '<circle cx="43" cy="50" r="3" fill="#FFFFFF"/><circle cx="57" cy="50" r="3" fill="#FFFFFF"/>'
       '<circle cx="43" cy="50" r="1.6" fill="#1A1A2E"/><circle cx="57" cy="50" r="1.6" fill="#1A1A2E"/>'),
 sparks=[(72,44,4,0.8)])
icons["shell"]=dict(hc="#FFD8A8",
 defs=[rgrad("s",50,82,80,[(0,"#FFF3E0",1),(55,"#FFC078",1),(100,"#E8950C",1)])],
 body=('<path d="M50 24 C24 28 16 64 24 80 Q50 72 76 80 C84 64 76 28 50 24 Z" fill="url(#s)"/>'
       '<g stroke="#D9881F" stroke-width="2" opacity="0.6" fill="none" stroke-linecap="round">'
       '<path d="M50 32 L50 76"/><path d="M40 34 L33 74"/><path d="M60 34 L67 74"/>'
       '<path d="M32 40 L23 76"/><path d="M68 40 L77 76"/></g>'
       '<circle cx="50" cy="28" r="5" fill="#FFF7E0"/>'),
 sparks=[(72,40,4,0.8)])
icons["fish"]=dict(hc="#4DABF7",
 defs=[lgrad("f",0,0,0,1,[(0,"#A5D8FF",1),(1,"#1971C2",1)])],
 body=('<ellipse cx="46" cy="52" rx="26" ry="17" fill="url(#f)"/>'
       '<path d="M70 52 L88 38 L86 66 Z" fill="url(#f)"/>'
       '<path d="M44 35 L52 44 L40 46 Z" fill="#74C0FC"/>'
       '<circle cx="34" cy="48" r="3.5" fill="#FFFFFF"/><circle cx="34" cy="48" r="1.8" fill="#1A1A2E"/>'
       '<path d="M50 52 q8 5 16 0" stroke="#1971C2" stroke-width="2" fill="none" opacity="0.5"/>'),
 sparks=[(64,40,4,0.8)])
icons["octopus"]=dict(hc="#E599F7",
 defs=[rgrad("o",42,34,80,[(0,"#FFD6F5",1),(50,"#DA77F2",1),(100,"#9C36B5",1)])],
 body=('<path d="M28 54 C28 32 72 32 72 54 L72 64 Q66 60 62 66 Q58 60 54 66 Q50 60 46 66 Q42 60 38 66 Q34 60 28 64 Z" fill="url(#o)"/>'
       '<circle cx="42" cy="48" r="5" fill="#FFFFFF"/><circle cx="58" cy="48" r="5" fill="#FFFFFF"/>'
       '<circle cx="42" cy="48" r="2.4" fill="#3B1B47"/><circle cx="58" cy="48" r="2.4" fill="#3B1B47"/>'
       '<circle cx="50" cy="42" r="6" fill="#FFFFFF" opacity="0.25"/>'),
 sparks=[(70,40,4,0.8)])
icons["seahorse"]=dict(hc="#FFA94D",
 defs=[lgrad("s",0,0,0,1,[(0,"#FFE066",1),(1,"#E8590C",1)])],
 body=('<path d="M44 22 C30 22 28 40 38 46 C30 54 30 70 44 78 C40 64 48 58 52 50 C56 40 60 36 56 28 C54 22 50 22 44 22 Z" fill="url(#s)"/>'
       '<path d="M44 20 Q40 14 34 18 Q42 18 44 24 Z" fill="#E8950C"/>'
       '<path d="M50 28 L62 24 L56 32 Z" fill="#FFD43B"/>'
       '<circle cx="42" cy="30" r="2.6" fill="#3B2B22"/>'
       '<path d="M44 70 q6 4 4 10 q-6 -2 -4 -10" fill="#E8950C"/>'),
 sparks=[(66,36,4,0.8)])
icons["jellyfish"]=dict(hc="#FFB6E1",
 defs=[rgrad("j",50,40,75,[(0,"#FFF0F6",1),(55,"#FFA8D5",1),(100,"#E64980",1)])],
 body=('<path d="M24 50 C24 28 76 28 76 50 Q50 60 24 50 Z" fill="url(#j)"/>'
       '<g stroke="#F783AC" stroke-width="3" stroke-linecap="round" opacity="0.85">'
       '<path d="M32 52 Q30 66 36 78"/><path d="M44 54 Q42 70 46 82"/><path d="M56 54 Q58 70 54 82"/><path d="M68 52 Q70 66 64 78"/></g>'
       '<ellipse cx="44" cy="42" rx="8" ry="4" fill="#FFFFFF" opacity="0.6"/>'),
 sparks=[(72,40,4,0.85)])

# --- 街 ---
icons["balloon"]=dict(hc="#FF8787",
 defs=[rgrad("b",40,32,80,[(0,"#FFC9C9",1),(45,"#FA5252",1),(100,"#C92A2A",1)])],
 body=('<path d="M50 18 C30 18 26 48 50 64 C74 48 70 18 50 18 Z" fill="url(#b)"/>'
       '<path d="M48 64 L52 64 L50 70 Z" fill="#C92A2A"/>'
       '<path d="M50 70 Q56 80 48 88" stroke="#ADB5BD" stroke-width="2" fill="none"/>'
       '<ellipse cx="42" cy="34" rx="6" ry="9" fill="#FFFFFF" opacity="0.5"/>'),
 sparks=[(66,30,4,0.85)])
icons["trafficlight"]=dict(hc="#868E96",
 defs=[lgrad("c",0,0,0,1,[(0,"#5C636A",1),(1,"#343A40",1)])],
 body=('<rect x="36" y="20" width="28" height="60" rx="8" fill="url(#c)"/>'
       '<circle cx="50" cy="34" r="8" fill="#FF6B6B"/>'
       '<circle cx="50" cy="50" r="8" fill="#FFD43B"/>'
       '<circle cx="50" cy="66" r="8" fill="#51CF66"/>'
       '<circle cx="47" cy="31" r="2.5" fill="#FFFFFF" opacity="0.5"/>'),
 sparks=[(70,30,4,0.8)])
icons["house"]=dict(hc="#FFB066",
 defs=[lgrad("w",0,0,0,1,[(0,"#FFF0E0",1),(1,"#FFD8A8",1)])],
 body=('<rect x="28" y="48" width="44" height="34" rx="3" fill="url(#w)"/>'
       '<path d="M22 50 L50 24 L78 50 Z" fill="#E8590C"/>'
       '<rect x="44" y="62" width="12" height="20" rx="2" fill="#8C5A2B"/>'
       '<rect x="33" y="54" width="9" height="9" rx="1.5" fill="#74C0FC"/>'
       '<rect x="58" y="54" width="9" height="9" rx="1.5" fill="#74C0FC"/>'),
 sparks=[(68,40,4,0.8)])
icons["bus"]=dict(hc="#FFD43B",
 defs=[lgrad("b",0,0,0,1,[(0,"#FFE066",1),(1,"#F08C00",1)])],
 body=('<rect x="20" y="34" width="60" height="40" rx="8" fill="url(#b)"/>'
       '<rect x="26" y="42" width="14" height="12" rx="2" fill="#D0EBFF"/>'
       '<rect x="44" y="42" width="14" height="12" rx="2" fill="#D0EBFF"/>'
       '<rect x="62" y="42" width="12" height="12" rx="2" fill="#D0EBFF"/>'
       '<rect x="22" y="60" width="56" height="5" fill="#E8590C"/>'
       '<circle cx="34" cy="76" r="7" fill="#343A40"/><circle cx="66" cy="76" r="7" fill="#343A40"/>'),
 sparks=[(70,38,4,0.8)])

# --- 山 ---
icons["pinetree"]=dict(hc="#51CF66",
 defs=[lgrad("g",0,0,0,1,[(0,"#69DB7C",1),(1,"#2B8A3E",1)])],
 body=('<rect x="45" y="70" width="10" height="14" rx="2" fill="#8C5A2B"/>'
       '<path d="M50 18 L66 42 L34 42 Z" fill="url(#g)"/>'
       '<path d="M50 34 L70 58 L30 58 Z" fill="url(#g)"/>'
       '<path d="M50 48 L74 74 L26 74 Z" fill="url(#g)"/>'
       '<circle cx="50" cy="22" r="3" fill="#FFE066"/>'),
 sparks=[(70,40,4,0.8)])
icons["backpack"]=dict(hc="#FF8787",
 defs=[lgrad("b",0,0,0,1,[(0,"#FF8787",1),(1,"#C92A2A",1)])],
 body=('<rect x="28" y="30" width="44" height="52" rx="12" fill="url(#b)"/>'
       '<path d="M40 32 Q50 22 60 32" stroke="#C92A2A" stroke-width="4" fill="none"/>'
       '<rect x="36" y="52" width="28" height="22" rx="6" fill="#FFE0E0"/>'
       '<rect x="46" y="40" width="8" height="14" rx="3" fill="#FFD43B"/>'),
 sparks=[(68,40,4,0.8)])

# --- 夜 / 宇宙 / 銀河 ---
icons["firefly"]=dict(hc="#D8F36B",
 defs=[rgrad("g",50,50,70,[(0,"#FBFFD6",1),(50,"#D8F36B",1),(100,"#82C91E",1)])],
 body=('<circle cx="50" cy="52" r="20" fill="url(#g)"/>'
       '<circle cx="50" cy="62" r="9" fill="#FFFDE7"/>'
       '<path d="M40 36 L30 26 M60 36 L70 26" stroke="#5C7C12" stroke-width="2.4" stroke-linecap="round"/>'
       '<circle cx="44" cy="46" r="2.6" fill="#3B4B12"/><circle cx="56" cy="46" r="2.6" fill="#3B4B12"/>'),
 sparks=[(72,40,4.5,0.9),(30,62,3,0.8)])
icons["comet"]=dict(hc="#74C0FC",
 defs=[rgrad("h",38,38,70,[(0,"#FFFFFF",1),(45,"#A5D8FF",1),(100,"#4DABF7",1)]),
       lgrad("t",0,0,1,1,[(0,"#A5D8FF",0.95),(60,"#4DABF7",0.5),(100,"#4DABF7",0)])],
 body=('<path d="M40 38 L90 80 L72 86 L34 54 Z" fill="url(#t)"/>'
       '<path d="M44 42 L82 74 L74 80 Z" fill="#FFFFFF" opacity="0.35"/>'
       '<circle cx="36" cy="38" r="17" fill="url(#h)"/>'),
 sparks=[(58,28,5,0.95),(76,62,3.5,0.85)])
icons["rocket"]=dict(hc="#FF8787",
 defs=[lgrad("b",0,0,0,1,[(0,"#FFFFFF",1),(1,"#CED4DA",1)])],
 body=('<path d="M50 14 C64 28 64 52 58 66 L42 66 C36 52 36 28 50 14 Z" fill="url(#b)"/>'
       '<path d="M50 14 C58 24 60 40 58 52 L42 52 C40 40 42 24 50 14 Z" fill="#FF6B6B" opacity="0.25"/>'
       '<circle cx="50" cy="38" r="7" fill="#74C0FC"/><circle cx="50" cy="38" r="3" fill="#1971C2"/>'
       '<path d="M42 60 L30 72 L42 70 Z" fill="#FA5252"/><path d="M58 60 L70 72 L58 70 Z" fill="#FA5252"/>'
       '<path d="M44 66 Q50 86 56 66 Z" fill="#FFA94D"/>'),
 sparks=[(70,30,4,0.85)])
icons["planet"]=dict(hc="#B197FC",
 defs=[rgrad("p",40,34,80,[(0,"#D0BFFF",1),(50,"#9775FA",1),(100,"#6741D9",1)])],
 body=('<circle cx="50" cy="50" r="24" fill="url(#p)"/>'
       '<ellipse cx="50" cy="52" rx="40" ry="11" fill="none" stroke="#FFD43B" stroke-width="4" transform="rotate(-18 50 52)"/>'
       '<circle cx="42" cy="44" r="4" fill="#C0A8FF" opacity="0.7"/>'
       '<circle cx="58" cy="56" r="3" fill="#6741D9" opacity="0.6"/>'),
 sparks=[(74,34,4,0.85)])
icons["ufo"]=dict(hc="#63E6BE",
 defs=[lgrad("d",0,0,0,1,[(0,"#C3FAE8",1),(1,"#20C997",1)]),
       lgrad("s",0,0,0,1,[(0,"#CED4DA",1),(1,"#868E96",1)])],
 body=('<path d="M30 38 C30 26 70 26 70 38 Z" fill="url(#d)"/>'
       '<ellipse cx="50" cy="46" rx="34" ry="12" fill="url(#s)"/>'
       '<circle cx="34" cy="46" r="3" fill="#FFD43B"/><circle cx="50" cy="50" r="3" fill="#FF6B6B"/><circle cx="66" cy="46" r="3" fill="#74C0FC"/>'
       '<path d="M40 56 L36 74 L64 74 L60 56 Z" fill="#FFF3BF" opacity="0.45"/>'),
 sparks=[(74,34,4,0.85)])
icons["astronaut"]=dict(hc="#A5D8FF",
 defs=[lgrad("s",0,0,0,1,[(0,"#FFFFFF",1),(1,"#CED4DA",1)])],
 body=('<rect x="34" y="50" width="32" height="30" rx="12" fill="url(#s)"/>'
       '<circle cx="50" cy="40" r="20" fill="url(#s)"/>'
       '<path d="M38 40 a12 9 0 0 1 24 0 a12 9 0 0 1 -24 0 Z" fill="#1A1A2E"/>'
       '<ellipse cx="44" cy="38" rx="4" ry="6" fill="#74C0FC" opacity="0.8"/>'
       '<rect x="44" y="58" width="12" height="10" rx="2" fill="#FF6B6B"/>'),
 sparks=[(72,30,4,0.85)])
icons["saturn"]=dict(hc="#FFD43B",
 defs=[rgrad("p",40,34,72,[(0,"#FFE9A8",1),(45,"#FCC419",1),(100,"#D9881F",1)])],
 body=('<ellipse cx="50" cy="54" rx="40" ry="12" fill="none" stroke="#C97A1F" stroke-width="6" transform="rotate(-20 50 54)" opacity="0.55"/>'
       '<circle cx="50" cy="50" r="24" fill="url(#p)"/>'
       '<ellipse cx="50" cy="48" rx="40" ry="12" fill="none" stroke="#FFE9A8" stroke-width="6" transform="rotate(-20 50 48)"/>'
       '<ellipse cx="42" cy="42" rx="5" ry="7" fill="#FFFFFF" opacity="0.4"/>'),
 sparks=[(78,34,4.5,0.9)])
icons["galaxy"]=dict(hc="#B197FC",
 defs=[rgrad("g",50,50,75,[(0,"#3B1B6E",1),(100,"#1A0B3E",1)])],
 body=('<circle cx="50" cy="50" r="30" fill="url(#g)"/>'
       '<path d="M50 50 C58 34 80 40 74 56 C70 66 56 64 50 50 Z" fill="#DA77F2" opacity="0.85"/>'
       '<path d="M50 50 C42 66 20 60 26 44 C30 34 44 36 50 50 Z" fill="#9775FA" opacity="0.85"/>'
       '<circle cx="50" cy="50" r="7" fill="#FFFDE7"/>'
       '<circle cx="36" cy="38" r="1.6" fill="#FFFFFF"/><circle cx="66" cy="62" r="1.6" fill="#FFFFFF"/>'
       '<circle cx="62" cy="34" r="1.2" fill="#FFFFFF"/>'),
 sparks=[(74,36,4,0.85),(28,62,3,0.8)])

# --- 砂漠 ---
icons["cactus"]=dict(hc="#51CF66",
 defs=[lgrad("g",0,0,0,1,[(0,"#69DB7C",1),(1,"#2F9E44",1)])],
 body=('<rect x="44" y="30" width="12" height="50" rx="6" fill="url(#g)"/>'
       '<path d="M44 50 L34 50 Q28 50 28 42 L28 38" fill="none" stroke="url(#g)" stroke-width="9" stroke-linecap="round"/>'
       '<path d="M56 56 L66 56 Q72 56 72 48 L72 44" fill="none" stroke="url(#g)" stroke-width="9" stroke-linecap="round"/>'
       '<rect x="38" y="78" width="24" height="8" rx="3" fill="#E8950C"/>'
       '<circle cx="48" cy="40" r="3" fill="#FF6B6B"/>'),
 sparks=[(70,40,4,0.8)])
icons["camel"]=dict(hc="#E6B877",
 defs=[lgrad("c",0,0,0,1,[(0,"#F0C896",1),(1,"#C68A4A",1)])],
 body=('<path d="M22 70 C22 56 30 56 34 60 C36 48 44 48 46 60 C48 50 56 50 58 60 C62 54 72 52 74 64 L72 72 L66 72 L66 66 L30 66 L30 72 Z" fill="url(#c)"/>'
       '<path d="M70 60 C78 54 78 38 72 34 C74 42 70 50 66 54 Z" fill="url(#c)"/>'
       '<circle cx="74" cy="34" r="2.4" fill="#3B2B22"/>'
       '<rect x="26" y="70" width="5" height="12" fill="#A6713A"/><rect x="62" y="70" width="5" height="12" fill="#A6713A"/>'),
 sparks=[(40,46,4,0.8)])
icons["sun"]=dict(hc="#FFD43B",
 defs=[rgrad("s",50,46,65,[(0,"#FFFDEB",1),(50,"#FFD43B",1),(100,"#F59F00",1)])],
 body=('<g stroke="#FCC419" stroke-width="5" stroke-linecap="round">'
       '<path d="M50 8 L50 18"/><path d="M50 82 L50 92"/><path d="M8 50 L18 50"/><path d="M82 50 L92 50"/>'
       '<path d="M20 20 L28 28"/><path d="M80 20 L72 28"/><path d="M20 80 L28 72"/><path d="M80 80 L72 72"/></g>'
       '<circle cx="50" cy="50" r="24" fill="url(#s)"/>'
       '<ellipse cx="42" cy="42" rx="6" ry="8" fill="#FFFFFF" opacity="0.4"/>'),
 sparks=[(74,30,4.5,0.9)])
icons["snake"]=dict(hc="#69DB7C",
 defs=[lgrad("s",0,0,0,1,[(0,"#8CE99A",1),(1,"#2F9E44",1)])],
 body=('<path d="M24 78 Q16 64 32 60 Q52 56 44 44 Q38 34 54 30 Q70 26 64 40" '
       'fill="none" stroke="url(#s)" stroke-width="11" stroke-linecap="round"/>'
       '<circle cx="64" cy="40" r="8" fill="url(#s)"/>'
       '<circle cx="62" cy="38" r="2" fill="#1A1A2E"/>'
       '<path d="M70 42 L78 44 L70 46" stroke="#FF6B6B" stroke-width="2" fill="none"/>'),
 sparks=[(40,64,4,0.8)])
icons["pyramid"]=dict(hc="#FFD8A8",
 defs=[lgrad("p",0,0,1,1,[(0,"#FFE9C2",1),(100,"#C68A4A",1)])],
 body=('<path d="M50 20 L82 78 L18 78 Z" fill="url(#p)"/>'
       '<path d="M50 20 L50 78 L18 78 Z" fill="#A6713A" opacity="0.35"/>'
       '<path d="M50 20 L58 36 L42 36 Z" fill="#FFF3E0" opacity="0.6"/>'
       '<circle cx="74" cy="30" r="6" fill="#FFD43B"/>'),
 sparks=[(72,40,4,0.8)])

# --- 雪 ---
icons["snowman"]=dict(hc="#A5D8FF",
 defs=[rgrad("s",42,30,80,[(0,"#FFFFFF",1),(100,"#D0E2F2",1)])],
 body=('<circle cx="50" cy="64" r="20" fill="url(#s)"/>'
       '<circle cx="50" cy="38" r="14" fill="url(#s)"/>'
       '<path d="M38 26 h24 v-3 h-24 Z" fill="#343A40"/><rect x="42" y="14" width="16" height="10" rx="2" fill="#343A40"/>'
       '<circle cx="46" cy="36" r="2" fill="#343A40"/><circle cx="54" cy="36" r="2" fill="#343A40"/>'
       '<path d="M50 40 L60 42 L50 44 Z" fill="#FFA94D"/>'
       '<circle cx="50" cy="58" r="2.4" fill="#343A40"/><circle cx="50" cy="68" r="2.4" fill="#343A40"/>'),
 sparks=[(72,40,4,0.85)])
icons["snowflake"]=dict(hc="#A5D8FF",
 defs=[lgrad("s",0,0,0,1,[(0,"#FFFFFF",1),(1,"#74C0FC",1)])],
 body=('<g stroke="url(#s)" stroke-width="4" stroke-linecap="round">'
       '<path d="M50 16 L50 84"/><path d="M22 32 L78 68"/><path d="M78 32 L22 68"/>'
       '<path d="M50 26 L42 32 M50 26 L58 32 M50 74 L42 68 M50 74 L58 68"/>'
       '<path d="M30 38 L30 46 M30 38 L38 38 M70 62 L70 54 M70 62 L62 62"/>'
       '<path d="M70 38 L62 38 M70 38 L70 46 M30 62 L38 62 M30 62 L30 54"/></g>'
       '<circle cx="50" cy="50" r="4" fill="#FFFFFF"/>'),
 sparks=[(74,30,4.5,0.9)])
icons["mitten"]=dict(hc="#FF8787",
 defs=[lgrad("m",0,0,0,1,[(0,"#FF8787",1),(1,"#C92A2A",1)])],
 body=('<path d="M38 38 C30 38 28 58 32 72 Q36 82 52 82 Q68 82 68 66 L68 42 C68 36 40 36 38 38 Z" fill="url(#m)"/>'
       '<path d="M30 50 C21 48 19 62 29 66 L35 58 Z" fill="url(#m)"/>'
       '<rect x="30" y="32" width="40" height="10" rx="5" fill="#FFFFFF"/>'
       '<path d="M46 52 Q54 56 62 52" stroke="#FFFFFF" stroke-width="2" fill="none" opacity="0.4"/>'),
 sparks=[(66,42,4,0.8)])
icons["penguin"]=dict(hc="#A5D8FF",
 defs=[lgrad("b",0,0,0,1,[(0,"#495057",1),(1,"#212529",1)])],
 body=('<ellipse cx="50" cy="54" rx="22" ry="28" fill="url(#b)"/>'
       '<ellipse cx="50" cy="58" rx="14" ry="22" fill="#FFFFFF"/>'
       '<circle cx="43" cy="40" r="2.6" fill="#FFFFFF"/><circle cx="57" cy="40" r="2.6" fill="#FFFFFF"/>'
       '<circle cx="43" cy="40" r="1.4" fill="#1A1A2E"/><circle cx="57" cy="40" r="1.4" fill="#1A1A2E"/>'
       '<path d="M46 46 L54 46 L50 52 Z" fill="#FFA94D"/>'
       '<path d="M40 80 L34 86 L46 84 Z" fill="#FFA94D"/><path d="M60 80 L66 86 L54 84 Z" fill="#FFA94D"/>'),
 sparks=[(70,38,4,0.85)])
icons["sled"]=dict(hc="#FF8787",
 defs=[lgrad("s",0,0,0,1,[(0,"#FF8787",1),(1,"#C92A2A",1)])],
 body=('<rect x="24" y="48" width="52" height="12" rx="4" fill="url(#s)"/>'
       '<path d="M20 66 Q16 56 28 56 L74 56 Q82 56 80 66" fill="none" stroke="#74C0FC" stroke-width="5" stroke-linecap="round"/>'
       '<rect x="32" y="44" width="6" height="10" fill="#C92A2A"/><rect x="62" y="44" width="6" height="10" fill="#C92A2A"/>'
       '<rect x="28" y="50" width="44" height="3" fill="#FFFFFF" opacity="0.4"/>'),
 sparks=[(70,44,4,0.8)])

# --- 花畑 ---
icons["bee"]=dict(hc="#FFD43B",
 defs=[lgrad("b",0,0,0,1,[(0,"#FFE066",1),(1,"#F59F00",1)])],
 body=('<ellipse cx="50" cy="56" rx="22" ry="16" fill="url(#b)"/>'
       '<path d="M44 42 L46 70 M54 42 L56 70" stroke="#343A40" stroke-width="5"/>'
       '<path d="M72 56 L84 62 Z" fill="#343A40"/>'
       '<ellipse cx="38" cy="40" rx="11" ry="8" fill="#FFFFFF" opacity="0.7" transform="rotate(-25 38 40)"/>'
       '<ellipse cx="58" cy="38" rx="11" ry="8" fill="#FFFFFF" opacity="0.7" transform="rotate(25 58 38)"/>'
       '<circle cx="34" cy="52" r="3" fill="#343A40"/>'
       '<path d="M32 44 L28 36 M40 44 L44 36" stroke="#343A40" stroke-width="2" stroke-linecap="round"/>'),
 sparks=[(72,46,4,0.8)])
icons["sunflower"]=dict(hc="#FFD43B",
 defs=[rgrad("c",50,50,70,[(0,"#A6713A",1),(100,"#5A3A22",1)])],
 body=('<g fill="#FFC400">'
       + "".join(f'<ellipse cx="{50+22*math.cos(math.radians(k*36)):.1f}" cy="{50+22*math.sin(math.radians(k*36)):.1f}" rx="6" ry="11" transform="rotate({k*36} {50+22*math.cos(math.radians(k*36)):.1f} {50+22*math.sin(math.radians(k*36)):.1f})"/>' for k in range(10))
       + '</g>'
       '<circle cx="50" cy="50" r="13" fill="url(#c)"/>'
       '<rect x="47" y="62" width="6" height="22" fill="#2F9E44"/>'),
 sparks=[(74,30,4,0.85)])

# --- 虹丘 ---
icons["rainbow"]=dict(hc="#FF8FB1",
 defs=[],
 body=('<g fill="none" stroke-width="6" stroke-linecap="round">'
       '<path d="M16 74 A34 34 0 0 1 84 74" stroke="#FF6B6B"/>'
       '<path d="M24 74 A26 26 0 0 1 76 74" stroke="#FFA94D"/>'
       '<path d="M32 74 A18 18 0 0 1 68 74" stroke="#FFD43B"/>'
       '<path d="M40 74 A10 10 0 0 1 60 74" stroke="#51CF66"/></g>'
       '<g fill="#FFFFFF"><circle cx="18" cy="76" r="8"/><circle cx="26" cy="78" r="7"/>'
       '<circle cx="82" cy="76" r="8"/><circle cx="74" cy="78" r="7"/></g>'),
 sparks=[(50,30,4.5,0.85)])

# --- 城 ---
icons["shield"]=dict(hc="#4DABF7",
 defs=[lgrad("s",0,0,0,1,[(0,"#74C0FC",1),(1,"#1971C2",1)])],
 body=('<path d="M50 16 L78 26 C78 56 66 76 50 84 C34 76 22 56 22 26 Z" fill="url(#s)"/>'
       '<path d="M50 16 L50 84 C34 76 22 56 22 26 Z" fill="#1864AB" opacity="0.3"/>'
       '<path d="M50 30 L50 64 M36 47 L64 47" stroke="#FFD43B" stroke-width="6" stroke-linecap="round"/>'
       '<circle cx="42" cy="30" r="3" fill="#FFFFFF" opacity="0.5"/>'),
 sparks=[(70,32,4,0.85)])
icons["flag"]=dict(hc="#FF6B6B",
 defs=[lgrad("f",0,0,1,0,[(0,"#FF8787",1),(1,"#E03131",1)])],
 body=('<rect x="30" y="16" width="5" height="68" rx="2" fill="#8C5A2B"/>'
       '<path d="M35 20 L78 30 L35 44 Z" fill="url(#f)"/>'
       '<circle cx="32" cy="16" r="4" fill="#FFD43B"/>'
       '<path d="M40 26 L58 30 L40 34 Z" fill="#FFFFFF" opacity="0.3"/>'),
 sparks=[(70,30,4,0.8)])

# --- バケツ（海） ---
icons["bucket"]=dict(hc="#4DABF7",
 defs=[lgrad("b",0,0,0,1,[(0,"#74C0FC",1),(1,"#1971C2",1)])],
 body=('<path d="M30 40 L70 40 L64 80 L36 80 Z" fill="url(#b)"/>'
       '<path d="M30 40 Q50 28 70 40" fill="none" stroke="#FFD43B" stroke-width="4"/>'
       '<rect x="28" y="38" width="44" height="6" rx="3" fill="#1864AB"/>'
       '<path d="M40 50 L60 50" stroke="#FFFFFF" stroke-width="2" opacity="0.4"/>'
       '<ellipse cx="50" cy="82" rx="16" ry="4" fill="#FFE066" opacity="0.7"/>'),
 sparks=[(68,44,4,0.8)])

for slug,cfg in icons.items():
    wrap(slug,cfg["hc"],cfg["defs"],cfg["body"],cfg["sparks"])
print("generated",len(icons),"icons")
print(sorted(icons.keys()))

# ===== 称号バッジ（assets/badges/）======================================
# 共通のメダル土台（リボン＋丸メダリオン）＋中央エンブレム。統一感のある勲章風。
BADGE_OUT = os.path.normpath(os.path.join(HERE, "..", "assets", "badges"))
os.makedirs(BADGE_OUT, exist_ok=True)

def medal(emblem, ring="#E8950C", face_top="#FFF3BF", face_bot="#FCC419", ribbon="#FF6B6B"):
    return (
      # リボン（2枚）
      f'<path d="M38 18 L34 44 L46 38 Z" fill="{ribbon}"/>'
      f'<path d="M62 18 L66 44 L54 38 Z" fill="#FA5252"/>'
      # メダリオン
      '<defs><radialGradient id="mf" cx="42%" cy="34%" r="75%">'
      f'<stop offset="0" stop-color="{face_top}"/><stop offset="100%" stop-color="{face_bot}"/>'
      '</radialGradient></defs>'
      f'<circle cx="50" cy="58" r="26" fill="{ring}"/>'
      '<circle cx="50" cy="58" r="21" fill="url(#mf)"/>'
      # ギザギザ縁
      + "".join(f'<circle cx="{50+24*math.cos(math.radians(k*30)):.1f}" cy="{58+24*math.sin(math.radians(k*30)):.1f}" r="2.4" fill="{ring}"/>' for k in range(12))
      + emblem +
      '<ellipse cx="42" cy="50" rx="5" ry="7" fill="#FFFFFF" opacity="0.35"/>'
    )

badges = {}
badges["badge_star"]=dict(hc="#FFD43B", ring="#E8950C", emblem=(
  '<path d="M50 46 L54 56 L65 56 L56 63 L59 74 L50 67 L41 74 L44 63 L35 56 L46 56 Z" fill="#FF8F00"/>'))
badges["badge_flag"]=dict(hc="#FF8787", ring="#C92A2A", ribbon="#FFD43B", emblem=(
  '<rect x="40" y="44" width="3.5" height="30" rx="1.5" fill="#8C5A2B"/>'
  '<path d="M43 46 L64 50 L43 56 Z" fill="#FA5252"/>'))
badges["badge_world"]=dict(hc="#4DABF7", ring="#1971C2", ribbon="#74C0FC", emblem=(
  '<circle cx="50" cy="58" r="13" fill="#4DABF7"/>'
  '<path d="M38 56 Q50 52 62 56 M38 60 Q50 64 62 60 M50 45 L50 71" stroke="#1864AB" stroke-width="1.6" fill="none" opacity="0.7"/>'
  '<path d="M44 48 Q40 58 44 68 M56 48 Q60 58 56 68" stroke="#1864AB" stroke-width="1.6" fill="none" opacity="0.7"/>'))
badges["badge_easy"]=dict(hc="#51CF66", ring="#2F9E44", ribbon="#69DB7C", face_top="#D3F9D8", face_bot="#69DB7C", emblem=(
  '<path d="M40 58 L47 66 L62 50" stroke="#2B8A3E" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'))
badges["badge_normal"]=dict(hc="#4DABF7", ring="#1971C2", ribbon="#74C0FC", face_top="#D0EBFF", face_bot="#74C0FC", emblem=(
  '<path d="M40 58 L47 66 L62 50" stroke="#1864AB" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
  '<path d="M50 46 L53 53 L60 53 L54 58 L57 65 L50 60 L43 65 L46 58 L40 53 L47 53 Z" fill="#1971C2" opacity="0.25"/>'))
badges["badge_hard"]=dict(hc="#FF6B6B", ring="#C92A2A", ribbon="#FFA94D", face_top="#FFE3E3", face_bot="#FF8787", emblem=(
  '<path d="M50 44 C58 52 60 58 58 64 A8 8 0 0 1 42 64 C42 58 46 56 48 52 C49 57 52 56 50 50 Z" fill="#E8590C"/>'))
badges["badge_book"]=dict(hc="#FFB066", ring="#8C5A2B", ribbon="#FFD43B", face_top="#FFF0E0", face_bot="#FFD8A8", emblem=(
  '<path d="M50 48 C44 44 36 44 34 47 L34 68 C36 65 44 65 50 69 Z" fill="#74C0FC"/>'
  '<path d="M50 48 C56 44 64 44 66 47 L66 68 C64 65 56 65 50 69 Z" fill="#4DABF7"/>'
  '<path d="M50 48 L50 69" stroke="#1864AB" stroke-width="1.6"/>'))
badges["badge_gem"]=dict(hc="#E599F7", ring="#9C36B5", ribbon="#DA77F2", face_top="#F3D9FA", face_bot="#DA77F2", emblem=(
  '<path d="M40 50 L60 50 L66 57 L50 72 L34 57 Z" fill="#4DABF7"/>'
  '<path d="M40 50 L44 57 L56 57 L60 50 Z" fill="#A5D8FF"/>'
  '<path d="M44 57 L56 57 L50 72 Z" fill="#1971C2"/>'))
badges["badge_crown"]=dict(hc="#FFD43B", ring="#E8950C", emblem=(
  '<path d="M37 66 L34 48 L43 55 L50 44 L57 55 L66 48 L63 66 Z" fill="#FCC419"/>'
  '<rect x="37" y="66" width="26" height="5" rx="2" fill="#E8950C"/>'
  '<circle cx="50" cy="46" r="2.6" fill="#FF6B6B"/>'))
badges["badge_compass"]=dict(hc="#63E6BE", ring="#0CA678", ribbon="#74C0FC", face_top="#E6FCF5", face_bot="#63E6BE", emblem=(
  '<circle cx="50" cy="58" r="14" fill="#E6FCF5" stroke="#0CA678" stroke-width="2"/>'
  '<path d="M50 58 L58 50 L52 60 Z" fill="#FA5252"/>'
  '<path d="M50 58 L42 66 L48 56 Z" fill="#495057"/>'
  '<circle cx="50" cy="58" r="2.2" fill="#343A40"/>'))

for slug,cfg in badges.items():
    emblem = cfg["emblem"]
    body = medal(emblem,
                 ring=cfg.get("ring","#E8950C"),
                 face_top=cfg.get("face_top","#FFF3BF"),
                 face_bot=cfg.get("face_bot","#FCC419"),
                 ribbon=cfg.get("ribbon","#FF6B6B"))
    wrap(slug, cfg["hc"], [], body, [(70,30,4,0.85),(30,40,3,0.8)], out=BADGE_OUT)
print("generated",len(badges),"badges ->",BADGE_OUT)
print(sorted(badges.keys()))
