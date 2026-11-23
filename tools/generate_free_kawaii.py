#!/usr/bin/env python3
"""Original scalable kawaii FREE paper-doll artwork, no borrowed illustration assets.
3 original characters, 25 coordinated items per character. 1024x1536 RGBA.
Each SVG is aligned to the same full-canvas paper-doll body coordinates.
"""
from __future__ import annotations
import argparse
import hashlib
import math
import os
import random
import xml.sax.saxutils as xml
from pathlib import Path

import cairosvg
from PIL import Image

SIZE=(1024,1536)
DOLLS=[
 {"name":"Amora","skin":"#E7A87C","shadow":"#C77D62","hair":"#75432F","hair_light":"#AA7050","eyes":"#855339","tint":"#A6D9C5","lip":"#9B5454","theme":"Jardim de Amora"},
 {"name":"Céu","skin":"#A9694E","shadow":"#854736","hair":"#2D2A49","hair_light":"#5B5383","eyes":"#604D76","tint":"#A6BEE8","lip":"#8E4C55","theme":"Sonho de Nuvens"},
 {"name":"Mel","skin":"#E6B98E","shadow":"#CB946B","hair":"#CA6948","hair_light":"#F1A56E","eyes":"#8E633F","tint":"#F4C66E","lip":"#A45D59","theme":"Doce Girassol"},
]
SLOTS=("top","bottom","dress","shoes","accessory")
NAMES={
 "top":[["Blusa de hortelã","Cardigã de morangos","Camiseta dos passarinhos","Suéter creme delicado","Blusa coral de babados"],
        ["Blusa de nuvens","Jaqueta lilás","Top de estrelas","Suéter azul noite","Camisa de marinheira"],
        ["Blusa de girassol","Cardigã de pêssego","Camiseta de abelhinhas","Blusa floral creme","Moletom tangerina"]],
 "bottom":[["Saia verde plissada","Short jeans de flores","Calça rosa confortável","Saia creme de renda","Short coral com laço"],
           ["Saia azul de nuvens","Calça jeans roxa","Short lilás esportivo","Saia de estrelas","Calça céu de inverno"],
           ["Saia de girassóis","Short amarelo","Calça coral de folhas","Saia pêssego rodada","Short creme de bolinhas"]],
 "dress":[["Vestido de jardim","Vestido morango rosé","Vestido lavanda de festa","Vestido de primavera","Vestido menta de baile"],
          ["Vestido lua dourada","Vestido azul celeste","Vestido lilás de laços","Vestido noite estrelada","Vestido princesa das nuvens"],
          ["Vestido girassol","Vestido pêssego de festa","Vestido laranja floral","Vestido creme bordado","Vestido abelha doce"]],
 "shoes":[["Sapatilhas rosa","Tênis menta","Botinhas creme","Sandálias de laço","Sapatos coral"],
          ["Sapatilhas lilás","Tênis estrelado","Botas azul noite","Sandálias de nuvem","Sapatos roxos"],
          ["Sapatilhas girassol","Tênis creme","Botas pêssego","Sandálias douradas","Sapatos de flor"]],
 "accessory":[["Laço de hortelã","Bolsa de coração","Óculos de flor","Colar de margaridas","Tiara de morangos"],
              ["Tiara de nuvens","Bolsa de estrelas","Óculos de coração","Colar de lua","Laço violeta"],
              ["Laço de girassol","Bolsa pêssego","Óculos redondos","Colar de abelhinha","Tiara floral"]],
}
PALETTES=[
 [("#A9DDC6","#F0FFF5"),("#F0A3B2","#FFF1E7"),("#8EB7D8","#E5F2FF"),("#E8D2A4","#FFF9E7"),("#EE9689","#FFE2D9")],
 [("#A9CDEB","#E7F6FF"),("#B8A4E5","#EFE6FF"),("#FFCE82","#FFF0CB"),("#566697","#D6DDF5"),("#89B6C9","#EBF8FF")],
 [("#F3CB72","#FFF3B7"),("#F5B28A","#FFF0DD"),("#E09A72","#FFDDC6"),("#F4E0BB","#FFF9E8"),("#EEB565","#FFF5CE")],
]
def path(d,fill,stroke="#764B51",w=6,extra=""):
 return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round" {extra}/>'
def ell(cx,cy,rx,ry,fill,stroke="none",w=2,extra=""):
 return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{w}" {extra}/>'
def cir(cx,cy,r,fill,stroke="none",w=2):return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{w}"/>'
def rect(x,y,w,h,rx,fill,stroke="none",sw=2):
 return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def grad(name,a,b):
 return f'<linearGradient id="{name}" x1="0" y1="0" x2=".9" y2="1"><stop stop-color="{a}"/><stop offset=".52" stop-color="{b}"/><stop offset="1" stop-color="{a}"/></linearGradient>'
def heart(x,y,s,c="#EB91A9"):
 return f'<g transform="translate({x} {y}) scale({s})">'+path('M0 31 C-57 -7 -53 -49 -17 -51 C-7 -50 0 -44 0 -34 C15 -59 53 -52 54 -18 C56 1 23 23 0 31',c,"#996C78",4)+'</g>'
def star(x,y,r,c="#FFDB76"):
 pts=[]
 for i in range(10):
  a=i*math.pi/5-math.pi/2;rr=r if i%2==0 else r*.48
  pts.append(f'{x+math.cos(a)*rr:.2f},{y+math.sin(a)*rr:.2f}')
 return f'<polygon points="{" ".join(pts)}" fill="{c}" stroke="#896171" stroke-width="3" stroke-linejoin="round"/>'
def flower(x,y,r=23,c="#FAF0F2"):
 out=f'<g transform="translate({x} {y})">'
 for j in range(6):
  out+=ell(0,-r*.60,r*.41,r*.72,c,"#976A78",2,extra=f'transform="rotate({j*60})"')
 out+=cir(0,0,r*.35,"#F1C770","#9C7658",2)+'</g>'
 return out
def bow(x,y,s=1,c="#FFC8D6"):
 return f'<g transform="translate({x} {y}) scale({s})">'+path('M-8 10 L-36 86 L-3 69 L14 88 L14 10Z',c)+path('M8 10 L36 86 L5 68 L-12 90 L-12 10Z',c)+path('M0 3 C-89 -63 -100 42 -8 27 C0 21 3 13 0 3Z',c)+path('M0 3 C85 -63 100 42 8 27 C0 21 -3 13 0 3Z',c)+cir(0,13,16,"#FFF7E8","#885769",3)+'</g>'
def sparkle(x,y,r=11):return path(f'M{x} {y-r} Q{x+3} {y-2} {x+r} {y} Q{x+3} {y+2} {x} {y+r} Q{x-3} {y+2} {x-r} {y} Q{x-3} {y-2} {x} {y-r}Z',"#FFFAE7","none",0)
def mot(x,y,j,variant):
 return (flower(x,y,22) if (j+variant)%4==0 else star(x,y,21) if (j+variant)%4==1
         else heart(x,y,.31) if (j+variant)%4==2 else sparkle(x,y,25))
def svg_wrap(elements,defs=""):
 return f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1536" viewBox="0 0 1024 1536"><defs>{defs}</defs>'+elements+'</svg>'

def doll(i):
 d=DOLLS[i];skin=d["skin"];shade=d["shadow"];hair=d["hair"];light=d["hair_light"]
 defs=grad("skin", "#FFE1BE" if i==2 else skin,shade)+grad("hair",light,hair)+grad("base","#FFFEF7","#EFDCCE")
 s=[]
 # Hair back: layered wavy curls, each tinted with hand-drawn highlight strands.
 s.append(path("M315 388 Q251 198 385 136 Q481 41 618 115 Q769 165 720 370 L741 591 Q691 685 632 670 Q510 751 392 666 Q288 699 282 571Z","url(#hair)",hair,11))
 for side in (-1,1):
  for j in range(5):
   x=512+side*(162+j%2*24);y=190+j*80
   s.append(ell(x,y,57,80,"url(#hair)",hair,5,extra=f'transform="rotate({side*(16+j*4)} {x} {y})"'))
   s.append(path(f'M{x-side*15} {y-37} Q{x+side*20} {y-64} {x+side*35} {y-3}',"none",light,5))
 # legs behind shorts
 for x in (416,555):
  s.append(path(f'M{x} 920 Q{x-29} 1057 {x+3} 1206 Q{x-17} 1370 {x-12} 1432 Q{x+16} 1486 {x+72} 1460 Q{x+87} 1441 {x+68} 1419 Q{x+52} 1298 {x+82} 1214 Q{x+109} 1040 {x+85} 920Z',"url(#skin)",shade,8))
  for k in range(4):
   s.append(path(f'M{x+25+k*11} 1451 q2 10 4 14',"none",shade,3))
 # arms and neck, body
 s.append(path("M435 548 L436 638 Q511 678 581 638 L580 546Z","url(#skin)",shade,6))
 for side in (-1,1):
  x=512+side*122
  s.append(path(f'M{x} 628 Q{x+side*45} 660 {x+side*65} 736 Q{x+side*92} 798 {x+side*160} 849 Q{x+side*188} 879 {x+side*174} 902 Q{x+side*148} 922 {x+side*118} 887 Q{x+side*53} 838 {x+side*18} 785 Q{x-side*17} 719 {x-side*12} 666Z',"url(#skin)",shade,8))
  s.append(path(f'M{x+side*72} 807 Q{x+side*101} 842 {x+side*137} 865',"none","#FFD8C1",8))
 s.append(path("M410 615 Q442 584 461 607 Q507 643 554 605 Q598 587 619 617 L643 789 Q629 872 600 934 L425 934 Q398 857 391 784Z","url(#skin)",shade,8))
 # base ivory camisole and bloomers
 s.append(path("M418 629 Q466 625 475 644 Q512 670 551 645 Q582 625 609 629 L623 845 Q514 873 403 844Z","url(#base)","#B88782",7))
 s.append(path("M424 648 L413 586 M601 648 L611 586","none","#FFFEF4",22))
 s.append(path("M401 856 Q512 877 628 856 L644 958 Q592 1003 532 974 L512 939 L494 974 Q431 996 385 960Z","url(#base)","#B88782",7))
 s.append(path("M392 960 Q438 980 492 971 M532 973 Q584 989 638 959","none","#FFFBED",9))
 # Face: cheeks, eye glass reflections and freckles
 s.append(ell(512,384,187,204,"url(#skin)",shade,9))
 for x in (402,622):
  s.append(ell(x,451,48,22,"#EE8D8B","none",0,extra='opacity=".38"'))
 for x in (443,581):
  s.append(ell(x,382,51,66,"#FFF8F2","#6A3A37",8))
  s.append(ell(x,390,35,49,d["eyes"],"#4D3434",5))
  s.append(ell(x,399,20,36,"#33252B"))
  s.append(cir(x-15,370,15,"#FFFFFF"))
  s.append(cir(x+16,403,7,"#FFFFFF"))
  s.append(path(f'M{x-48} 338 Q{x} 306 {x+45} 340',"none",hair,10))
  for k in (0,1,2):
   px=x-46+k*10
   s.append(path(f'M{px} 342 l{-12+k*3} -19',"none",hair,5))
 s.append(path("M499 445 q12 8 24 0","none",shade,4))
 s.append(path("M478 497 Q512 524 546 495","none",d["lip"],6))
 s.append(path("M492 496 Q512 507 532 496","none","#F7B1A8",4))
 for x in (395,410,426,596,612,627):
  s.append(cir(x,450+(x%3)*3,2.1,"#AA6C63"))
 # hair fringe overlapping face
 s.append(path("M325 321 Q330 147 438 150 Q513 96 607 160 Q705 182 700 321 Q644 283 632 235 Q592 315 543 284 Q509 277 497 233 Q446 307 404 280 Q378 334 325 321Z","url(#hair)",hair,10))
 for off in (-60,10,75):
  s.append(path(f'M{510+off} 162 Q{475+off} 244 {453+off} 269',"none",light,6))
 # hairstyle specific
 if i==1:
  for side in (-1,1):
   x=512+side*162
   for k in range(5):
    y=540+k*47
    s.append(ell(x+side*(k%2*10),y,31,23,"url(#hair)",hair,5))
   s.append(bow(x+side*12,655,.35,"#A5BEEA"))
 if i==2:
  s.append(path("M359 216 Q340 93 457 111 Q551 66 628 134 Q717 186 687 263", "none",light,21))
  s.append(bow(663,230,.45,"#FFDC79"))
 else:
  s.append(bow(361,215,.62,d["tint"]))
  s.append(bow(661,215,.62,d["tint"]))
 # lace highlights
 for x in range(411,630,22):
  s.append(cir(x,855,3.5,"#FFFDF2"))
 s.append(sparkle(384,240,11))
 return svg_wrap("".join(s),defs)

def top(i,j):
 a,b=PALETTES[i][j]
 defs=grad("cloth",b,a)
 s=[]
 # matching body in front/neutral arms spread
 if j==0:
  s.append(path("M408 626 L357 653 Q323 710 364 759 L409 742 L410 860 Q508 886 624 862 L624 742 L658 766 Q700 708 661 652 L612 626 Q558 659 512 660 Q462 660 408 626Z","url(#cloth)"))
 elif j==1:
  s.append(path("M418 627 L370 651 L353 770 L413 789 L400 871 Q511 891 627 866 L615 789 L667 771 L649 652 L603 627 L546 652 L510 680 L480 655Z","url(#cloth)"))
  s.append(path("M507 682 L507 872 M512 698 L518 871","none","#FFF3E6",10))
  for y in (728,789,845): s.append(cir(515,y,7,"#FFF2CD","#B49077",2))
 elif j==2:
  s.append(path("M413 624 L373 649 L331 732 L399 769 L428 729 L413 862 Q514 886 621 860 L605 728 L647 772 L696 726 L642 648 L604 623 Q511 670 413 624Z","url(#cloth)"))
 elif j==3:
  s.append(path("M410 629 L365 663 L340 818 L408 835 L427 765 L413 878 Q512 894 621 877 L606 765 L638 835 L685 815 L656 667 L604 627 Q510 671 410 629Z","url(#cloth)"))
  for x in range(419,628,25):s.append(path(f'M{x} 738 v112',"none",a,3))
 elif j==4:
  s.append(path("M421 629 L380 651 Q355 681 375 731 L400 754 L413 862 Q511 889 622 859 L627 753 L650 731 Q671 690 641 650 L601 626 Q516 665 421 629Z","url(#cloth)"))
  for x in (391,632):s.append(bow(x,702,.26,b))
 s.append(path("M451 645 Q511 684 573 646","none","#FFF6E9",7))
 s.append(path("M416 858 Q514 878 616 858","none","#FFF5E6",6))
 for k in range(6):
  s.append(mot(439+k*28,810+(k%2)*6,j,i) if j==4 and k%2==0 else cir(430+k*29,824,3.5,"#FFFEF7"))
 s.append(mot(513,756,j,i))
 for x,y in ((444,706),(584,709),(475,801),(570,797)):s.append(sparkle(x,y,7))
 return svg_wrap("".join(s),defs)

def bottom(i,j):
 a,b=PALETTES[i][j];defs=grad("cloth",b,a);s=[]
 if j in (0,3):
  s.append(path("M394 852 Q512 888 631 852 L661 997 Q579 1044 514 1062 Q437 1038 364 997Z","url(#cloth)"))
  for k in range(10):
   x=385+k*27
   s.append(path(f'M{x} 881 q{-9+(k%3)*4} 55 {-12+(k%2)*10} 112',"none",a,3))
  for k in range(7):s.append(mot(420+k*31,991,j,i) if k%3==0 else cir(417+k*31,1001,3,"#FFF9E0"))
 elif j in (1,4):
  s.append(path("M397 857 Q514 879 628 857 L652 993 L520 989 L511 944 L497 989 L374 996Z","url(#cloth)"))
  for x in (411,593):
   s.append(path(f'M{x} 903 v55',"none","#FFF1D8",5))
   s.append(heart(x+14,927,.24))
 else:
  s.append(path("M393 854 Q515 886 628 854 L634 1208 Q594 1234 542 1211 L512 973 L485 1214 Q444 1239 395 1210Z","url(#cloth)"))
  s.append(path("M398 1200 Q435 1217 486 1198 M537 1197 Q590 1222 632 1202","none","#FFF5E1",7))
  for x,y in ((429,1010),(591,1021),(432,1123),(592,1150)): s.append(mot(x,y,j,i))
 s.append(path("M398 878 Q512 905 627 876","none","#FFF5E4",10))
 s.append(bow(513,880,.25,b))
 return svg_wrap("".join(s),defs)

def dress(i,j):
 a,b=PALETTES[i][j];defs=grad("cloth",b,a);s=[]
 # matching the top and skirt on the same doll
 s.append(path("M412 631 L370 652 Q343 687 369 734 L403 757 L421 869 Q513 894 609 867 L620 755 L659 732 Q676 681 643 649 L607 625 Q516 668 412 631Z","url(#cloth)"))
 s.append(path("M424 866 Q512 889 606 866 Q690 968 712 1130 Q597 1221 512 1190 Q402 1229 313 1131 Q345 971 424 866Z","url(#cloth)"))
 s.append(path("M378 1105 Q511 1192 646 1103 M338 1139 Q502 1236 692 1137","none",b,22,extra='opacity=".65"'))
 s.append(path("M365 1142 Q520 1220 678 1142","none","#FFF8EA",9))
 s.append(path("M405 901 Q511 930 625 899","none","#FFF4E5",6))
 s.append(bow(511,889,.47,b))
 # stitched trims and delicate fabric pattern
 for k in range(11):
  x=343+k*33; y=1118-31*math.sin((k/10)*math.pi)
  s.append(mot(x,y,j,i) if (k+j)%3==0 else cir(x,y,5,"#FFF8EC"))
 for x,y in ((450,757),(558,758),(421,967),(609,975),(502,1028)):
  s.append(mot(x,y,j,i))
 for k in (0,1,2,3):
  s.append(sparkle(409+k*74,1060+(-1)**k*18,10))
 return svg_wrap("".join(s),defs)

def shoes(i,j):
 a,b=PALETTES[i][j];defs=grad("cloth",b,a);s=[]
 for x in (373,541):
  if j==2: # boots
   s.append(path(f'M{x+15} 1284 Q{x+61} 1270 {x+83} 1284 L{x+91} 1417 Q{x+114} 1426 {x+116} 1468 L{x+5} 1469 Q{x-7} 1426 {x+10} 1408Z',"url(#cloth)"))
   s.append(path(f'M{x+21} 1312 h58 M{x+22} 1356 h62',"none","#FFF9E5",10))
  else:
   s.append(path(f'M{x+12} 1391 Q{x+43} 1374 {x+83} 1388 Q{x+112} 1395 {x+123} 1444 Q{x+117} 1475 {x+8} 1474 Q{x-5} 1438 {x+12} 1391Z',"url(#cloth)"))
   s.append(path(f'M{x+15} 1453 Q{x+57} 1461 {x+118} 1451',"none","#FFFDF2",7))
   if j==1:s.append(path(f'M{x+12} 1408 L{x+83} 1436 M{x+74} 1395 L{x+25} 1436',"none","#FFF7E5",7))
  s.append(mot(x+64,1421,j,i))
  if j!=2:s.append(bow(x+57,1402,.22,b))
 return svg_wrap("".join(s),defs)

def accessory(i,j):
 a,b=PALETTES[i][j];defs=grad("cloth",b,a);s=[]
 if j==0:
  s.append(path("M308 292 Q350 122 512 114 Q666 125 716 292","none","#784960",29))
  s.append(path("M308 292 Q350 122 512 114 Q666 125 716 292","none",a,18))
  s.append(bow(676,184,.86,b))
  for k in range(4):s.append(mot(397+72*k,157+20*(k%2),j,i))
 elif j==1:
  s.append(path("M735 747 Q749 601 827 601 Q905 601 916 747","none","#745260",22))
  s.append(path("M735 747 Q749 601 827 601 Q905 601 916 747","none",a,14))
  s.append(path("M715 750 Q825 710 928 750 L933 956 Q825 1008 709 960Z","url(#cloth)"))
  s.append(path("M733 760 Q828 787 913 759","none","#FFF2DE",8))
  s.append(mot(821,856,j,i))
  s.append(bow(827,748,.37,b))
 elif j==2:
  for x in (443,581):
   s.append(ell(x,376,79,65,"url(#cloth)","#785164",11))
   s.append(ell(x,376,66,53,"#E3F5FF","none",0,extra='opacity=".3"'))
   s.append(sparkle(x-27,354,12))
  s.append(path("M513 370 Q505 352 499 370 M363 367 L305 351 M661 367 L715 353","none","#785164",11))
 elif j==3:
  s.append(path("M419 626 Q419 743 514 769 Q607 735 609 625","none","#BE8B73",14))
  s.append(path("M419 626 Q419 743 514 769 Q607 735 609 625","none","#FFF1C7",7))
  s.append(cir(513,765,43,"url(#cloth)","#81556C",6))
  s.append(mot(513,765,j,i))
 else:
  s.append(path("M309 293 Q366 145 512 138 Q666 143 715 293","none","#845367",27))
  s.append(path("M309 293 Q366 145 512 138 Q666 143 715 293","none",a,18))
  for k in range(6):
   x=365+59*k;y=211-66*math.sin(math.pi*k/5)
   s.append(flower(x,y,20,b))
  s.append(bow(512,143,.45,a))
 return svg_wrap("".join(s),defs)

def render_svg(doll_idx,slot,idx):
 if slot=="model":return doll(doll_idx)
 if slot=="top":return top(doll_idx,idx)
 if slot=="bottom":return bottom(doll_idx,idx)
 if slot=="dress":return dress(doll_idx,idx)
 if slot=="shoes":return shoes(doll_idx,idx)
 if slot=="accessory":return accessory(doll_idx,idx)
 raise ValueError(slot)
def filename(doll_idx,slot,idx):
 if slot=="model":return f"free_model_{doll_idx:02}.png"
 return f"free_{slot}_{doll_idx:02}_{idx:02}.png"
def manifest():
 return [{"model":d,"slot":slot,"index":idx,"file":filename(d,slot,idx),
          "name": DOLLS[d]["name"] if slot=="model" else NAMES[slot][d][idx],
          "palette": DOLLS[d]["theme"]}
         for d in range(3) for slot in ("model",)+SLOTS
         for idx in (range(1) if slot=="model" else range(5))]
def generate(target:Path,d:int,slot:str,index:int,svg_out:Path|None=None):
 raw=render_svg(d,slot,index)
 target.parent.mkdir(parents=True,exist_ok=True)
 if svg_out:
  svg_out.parent.mkdir(parents=True,exist_ok=True)
  svg_out.write_text(raw,encoding="utf-8")
 cairosvg.svg2png(bytestring=raw.encode(),write_to=str(target),
                 output_width=1024,output_height=1536)
 with Image.open(target) as im:
  assert im.mode=="RGBA", (target,im.mode)
  assert im.size==SIZE,(target,im.size)
  assert im.getpixel((0,0))[3]==0, target
  assert im.getpixel((1023,1535))[3]==0,target
  bbox=im.getchannel("A").getbbox()
  assert bbox and bbox[2]-bbox[0]>=80 and bbox[3]-bbox[1]>=30,(target,bbox)
 return target

def main():
 p=argparse.ArgumentParser()
 p.add_argument("--doll",type=int,choices=range(3))
 p.add_argument("--slot",choices=("model",)+SLOTS)
 p.add_argument("--index",type=int,default=0)
 p.add_argument("--list",action="store_true")
 p.add_argument("--all",action="store_true")
 p.add_argument("--out",default="assets/free_kawaii")
 p.add_argument("--svg-source",action="store_true")
 args=p.parse_args()
 if args.list:
  import json
  print(json.dumps(manifest(),ensure_ascii=False,indent=2));return
 tasks=manifest() if args.all else [dict(model=args.doll,slot=args.slot,index=args.index,file=filename(args.doll,args.slot,args.index))]
 for item in tasks:
  d,slot,idx=item["model"],item["slot"],item["index"]
  pth=Path(args.out)/item["file"]
  src=pth.with_suffix(".svg") if args.svg_source else None
  generate(pth,d,slot,idx,src)
  print(f"OK {pth}: {pth.stat().st_size} bytes")
if __name__=="__main__":main()
