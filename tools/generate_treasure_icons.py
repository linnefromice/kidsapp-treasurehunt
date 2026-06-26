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

def wrap(slug, hc, defs, body, sparks, shadow=True):
    d = halo(color=hc)+"".join(defs)
    sh = '<ellipse cx="50" cy="92" rx="22" ry="4.5" fill="#000000" opacity="0.11"/>' if shadow else ""
    sp = "".join(spark(*s) for s in sparks)
    svg=(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">'
         f'<defs>{d}</defs>'
         f'<circle cx="50" cy="52" r="52" fill="url(#halo)"/>{sh}{body}{sp}</svg>')
    open(f"{OUT}/{slug}.svg","w").write(svg)

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

for slug,cfg in icons.items():
    wrap(slug,cfg["hc"],cfg["defs"],cfg["body"],cfg["sparks"])
print("generated",len(icons),"icons")
print(sorted(icons.keys()))
