"""Export the original businesses, landmarks, modules, palettes and service plots for a district."""
from math import cos, sin, tau
from pathlib import Path
from random import Random
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))

from frontier_design import DISTRICTS
from kit import Model, output_root, offset
from legacy_works import write_model
from premium_botany import palms, conifer_outline, canopy
from premium_facades import awning, garage_portal, gutter, lamp, sawlight
from regional_atlas import gable, mountain
from venue_works import annex, bench, counter, fixture, foot, pallet, post, roof_work

IVORY = "f2dfb5"
DARK = "344b56"
GLASS = "7eaab1"


def add_model(target, model, center=(0,0,0), scale=1.0, yaw=0.0):
    for part in model.parts:
        part.vertices = [offset(tuple(c*scale for c in point),center,yaw) for point in part.vertices]
        target.parts.append(part)


def windows(m,x,y,z,width,height,shade,trim,split=3):
    m.box((x,y,z-.077),(width+.12,height+.13,.155),trim,.041,"Metal")
    for i in range(split):
        sx=x+(i-(split-1)*.5)*width/split
        m.box((sx,y,z),(width/split-.11,height,.06),shade,.038,"Tint")
        if i%2==0:
            m.box((sx-width/split*.23,y+.06,z+.039),(.051,height*.74,.010),"aaccc5",.004,"Paint")


def roof(m, region, w, d, h, trim, wall, accent, shell):
    if region in ("tropical","wilderness","japan"):
        ratio={"tropical":.66,"wilderness":1.19,"japan":.86}[region]
        if shell in ("parking","multilevel","ev","freight","logging","haulage","wash"):
            ratio *= .63
        gable(m,w+.56,d+.49,h,ratio,trim,region=="wilderness")
        m.box((0,h-.06,d*.51),(w*.84,.18,.13),accent,.035,"Paint")
        if region=="japan":
            for dx in (-w*.40,w*.40):
                m.pipe([(dx,h,d*.58),(dx+(.22 if dx>0 else -.22),h+.19,d*.58),
                        (dx+(.30 if dx>0 else -.30),h+.31,d*.58)],.073,trim,"Paint",8)
            for x in (-w*.38,w*.38):
                m.box((x,h-.21,d*.508),(.3,.05,.066),accent,.017,"Light")
        return
    if region=="route66":
        m.custom_box((0,h,0),(w+.58,.37,d+.46),trim,.55,.091,"Paint")
        m.custom_box((0,h+.25,-.18),(w-.67,.25,d-.10),wall,.37,.067)
        m.box((0,h-.08,d*.54),(w*.89,.071,.086),accent,.022,"Light")
        gutter(m,w*.45,h-.17,0,d*.94)
    elif region=="harbor":
        ridge = w*.34
        for x in (-ridge,0,ridge):
            part = w*.31
            m.custom_box((x,h,-.04),(part+.04,.39,d+.35),trim,.29,.070,"Metal")
            sawlight(m,x,h+.20,-.29,part*.75,d*.58,.43,accent,3)
    else:
        cap = w*.66 if shell in ("hotel","motor") else w*.88
        m.custom_box((0,h,0),(w+.50,.31,d+.42),trim,.49,.098,"Paint")
        m.custom_box((.14,h+.21,-.22),(cap,.24,d*.84),wall,.48,.075)
        m.box((0,h-.13,d*.52),(w*.79,.061,.09),IVORY,.027,"Light")


def canopy_bay(m, w,d,h,wall,trim,accent,mode):
    for x in (-w*.41,w*.41):
        for z in (-d*.37,d*.37):
            post(m,x,z,h,trim,wide=.26 if mode!="fuel" else .30)
    for x in (-w*.28,w*.28):
        lamp(m,x,h-.20,d*.23,.18)
    if mode=="multilevel":
        for y in (1.77,3.23):
            m.custom_box((0,y,-.05),(w,.19,d),wall,.44,.064)
            for x in (-w*.42,w*.42):
                m.pipe([(x,y+.26,-d*.48),(x,y+.26,d*.48)],.056,trim,"Metal",8)
        m.box((w*.38,.97,d*.33),(1.12,.119,d*.67),accent,.045,"Paint")
    if mode in ("parking","transport"):
        for x in (-w*.20,w*.22):
            m.box((x,.204,.65),(.055,.014,d*.64),IVORY,.006,"Paint")
            m.box((x-.30,.253,-d*.33),(.59,.13,.24),accent,.037)
        bench(m,0,.14,-d*.40,1.65)
    if mode=="ev":
        fixture(m,"ev",0,.16,0.1,accent)


def hospitality(m, region, mode,w,d,h,wall,trim,accent,tint):
    front = d*.50
    sides = w*.42
    floors = 2 if mode=="hotel" else 1
    for x in (-sides,sides):
        m.custom_box((x,h*.47,-.20),(w*.15,h*.86,d-.45),wall,.18,.076)
    m.custom_box((0,h*.51,-d*.41),(w,h*.91,d*.23),wall,.23,.081)
    for x in (-w*.44,w*.44):
        post(m,x,front-.13,h-.23,trim,wide=.25)
    if mode=="hotel":
        m.custom_box((0,h*.54,front-.20),(w+.47,.24,1.35),trim,.41,.070,"Paint")
        for x in (-w*.42,0,w*.42):
            post(m,x,front+.35,.69,accent,h*.55,.09)
        m.pipe([(-w*.44,h*.55+.58,front+.35),(w*.44,h*.55+.58,front+.35)],
               .043,IVORY,"Metal",10)
    for level in range(floors):
        y=h*(.33+level*.41)
        for x in (-w*.27,w*.27):
            windows(m,x,y,front+.01,w*.39,h*(.32 if floors>1 else .39),tint,trim,3)
        if level==0:
            windows(m,0,y,front+.043,w*.17,h*.62,tint,trim,2)
    if mode in ("food","rent","scooter","retail"):
        for x in (-w*.31,w*.31):
            awning(m,x,h*.72,front+.06,w*.39,.88,(accent,IVORY),6)
            lamp(m,x,h*.56,front+.40,.12)
    for i in range(2 if mode!="food" else 3):
        x=(i-1)*w*.30 if mode=="food" else (i-.5)*w*.50
        if mode=="food":
            m.pipe([(x,.16,front+.87),(x,.78,front+.87)],.07,trim,"Metal",8)
            m.pipe([(x,.77,front+.87),(x,.90,front+.87)],.44,IVORY,sides=14)
            bench(m,x,.12,front+.24,.66,accent)
        elif mode!="hotel":
            counter(m,x,.12,front-1.25,w*.22,wall,mode=="retail")
        else:
            bench(m,x,.14,front+.51,1.45,accent)
    if region=="luxury":
        for x in (-w*.46,w*.46):
            m.custom_box((x,.30,front+.51),(.55,.43,.62),IVORY,.12,.047)
            m.orb((x,.64,front+.51),(.38,.38,.36),"588c70",11,7)
    if mode=="scooter":
        for i in range(3):
            x=(i-1)*.72
            for z in (front-.08,front+.47):
                m.pipe([(x,.23,z),(x+.107,.23,z)],.17,DARK,"Rubber",9)
            m.pipe([(x,.28,front-.04),(x,.29,front+.37),(x,.62,front+.45)],
                   .075,accent,"Paint",7)
            m.pipe([(x-.15,.62,front+.45),(x+.16,.62,front+.45)],.045,IVORY,"Metal",6)


def garage(m,kind,shell,w,d,h,wall,trim,accent):
    # Front openings and narrow painted shutters frame the actual active bays.
    face=d*.50
    m.custom_box((0,h*.49,-d*.42),(w,h*.94,d*.18),wall,.23,.076)
    for x in (-w*.46,w*.46):
        m.custom_box((x,h*.48,-.25),(w*.085,h*.93,d-.50),wall,.21,.068)
    width = w*.38
    for sign in (-1,1):
        x=sign*w*.23
        garage_portal(m,x,.20,face,width,h*.77,accent if sign>0 else trim)
        lamp(m,x,h*.76,face-.20,.13)
        m.custom_box((x,.190,.47),(width*.92,.15,d*.63),"90958c",.22,.054)
        if kind in ("freight","cold"):
            m.box((x,.32,face-.32),(width*.94,.37,.68),trim,.055,"Metal")
            for j in range(4):
                m.box((x+(j-1.5)*width*.2,.51,face-.27),(.24,.037,.12),IVORY,.009,"Paint")
            if shell in ("logging","haulage"):
                for j in range(4):
                    m.pipe([(x+(.42-(j%2)*.84),.37+j*.15,-1.25),
                            (x+(.42-(j%2)*.84),.37+j*.15,.44)],.15,"a88858",sides=8)
            else:
                pallet(m,x,.15,-.68,accent)
        elif kind=="wash":
            for side in (-1,1):
                xx=x+side*width*.36
                m.pipe([(xx,h*.67,face-.49),(xx,h*.67,-.14)],.056,DARK,"Metal",8)
            fixture(m,"wash",x,.165,-1.30,accent)
        else:
            fixture(m,"repair",x,.17,-.65,accent)
            for side in (-1,1):
                m.box((x+side*width*.23,.34,.16),(.25,.20,1.61),trim,.043,"Metal")
    if shell in ("terminal","transfer","distribution","logging"):
        for x in (-w*.48,w*.48):
            post(m,x,-1.12,h+1.31,trim,wide=.27)
        m.custom_box((0,h+1.2,-1.12),(w,.44,.42),accent,.155,.069,"Metal")
        m.box((-.78,h+.89,-1.13),(1.14,.24,.55),DARK,.060,"Metal")
    if shell=="cold":
        for x in (-w*.34,w*.34):
            m.custom_box((x,h*.89,-d*.25),(1.28,.62,.91),DARK,.15,.068,"Metal")
            m.pipe([(x,h*.88,-d*.25+.46),(x,h*.88,-d*.25+.51)],.22,GLASS,"Metal",14)


VARIANTS = {
    "fuel": "e2af64", "rent": "69aa9a", "scooter": "df8b72", "hotel": "b88376",
    "food": "de9d60", "retail": "89a66e", "parking": "729c9c",
    "wash": "78b8b1", "repair": "b48161", "freight": "c38b61",
    "cold": "86a6bb", "motor": "bd84a0", "ev": "8cbba9",
}


def identity(m, region, kind, shell, w, d, h, wall, trim, accent):
    if kind=="hotel":
        x=w*.34
        m.custom_box((x,h+.68,-d*.23),(w*.26,1.38,d*.45),wall,.24,.086)
        windows(m,x,h+.64,-d*.23+d*.226,w*.21,.55,GLASS,trim,2)
        roof(m,region,w*.27,d*.46,h+1.44,trim,wall,accent,"suite")
        if region in ("tropical","luxury"):
            x=w*.59
            m.custom_box((x,.20,-d*.14),(2.44,.34,3.64),IVORY,.53,.088)
            m.custom_box((x,.40,-d*.14),(1.99,.096,3.18),"6aaeb2",.48,.028,"Tint")
            for side in (-1,1):
                m.pipe([(x+side*.22,.43,-d*.14+1.30),(x+side*.22,.83,-d*.14+1.37),
                        (x+side*.22,.82,-d*.14+1.73)],.032,"c4cabb","Metal",7)
    elif kind=="food":
        x=-w*.28
        bench(m,0,.14,d*.55+.71,1.55,accent)
        sawlight(m,x,h+.23,-.60,min(2.43,w*.46),1.49,.53,accent,3)
        if region in ("tropical","route66"):
            awning(m,0,h-.36,d*.55,w*.49,.98,(accent,IVORY),8)
            for offset in (-w*.28,w*.28):
                post(m,offset,d*.55+.94,h*.55,trim,wide=.14)
    elif kind in ("rent","scooter"):
        x=-w*.53
        for z in (-.66,.68):
            post(m,x-.18,z,2.43,trim,wide=.135)
        m.custom_box((x,2.44,0),(1.63,.26,2.32),accent,.22,.052,"Paint")
        fixture(m,kind,x,.15,-.18,trim)
        m.box((x,2.28,1.10),(1.31,.052,.056),IVORY,.016,"Light")
    elif kind=="motor":
        for x in (-w*.46,w*.46):
            m.custom_box((x,2.11,d*.49),(1.1,4.0,.56),trim,.16,.077,"Metal")
            m.box((x,2.57,d*.50+.30),(.33,1.78,.026),accent,.10,"Light")
        sawlight(m,0,h+.17,-.62,w*.73,d*.39,.71,accent,6)
    elif kind=="repair" and shell in ("restoration","tuning"):
        x=w*.38
        m.custom_box((x,h+.52,-.72),(2.80,.92,2.34),wall,.33,.080)
        windows(m,x,h+.57,.51,2.32,.49,GLASS,trim,3)
        m.custom_box((x,h+1.06,-.73),(2.98,.19,2.49),trim,.28,.064,"Paint")
        lamp(m,x,h+.98,.35,.15)
    elif kind=="wash":
        sawlight(m,w*.18,h+.13,-d*.15,w*.53,d*.48,.63,accent,5)
    elif kind=="fuel":
        for x in (-w*.29,w*.29):
            sawlight(m,x,h+.23,-.38,w*.31,d*.43,.39,accent,4)
    elif kind=="ev":
        for x in (-w*.31,w*.31):
            lamp(m,x,h-.21,d*.38,.17)
            m.box((x,h+.31,-.19),(w*.27,.10,d*.47),GLASS,.066,"Tint")


def business(region, plan, definition):
    wall,trim,accent,tint,_ = plan["colors"]
    key,kind,shell = definition["key"],definition["kind"],definition["shell"]
    accent=VARIANTS.get(kind,accent) if kind!="fuel" else accent
    w,d,h = definition["size"]
    m = Model()
    foot(m,0,0,0,w+.58,d+.52)
    if kind in ("fuel","parking","ev"):
        canopy_bay(m,w,d,h,wall,trim,accent,shell)
    elif kind in ("freight","cold","repair","wash"):
        garage(m,kind,shell,w,d,h,wall,trim,accent)
    elif kind=="motor":
        hospitality(m,region,"retail",w,d,h,wall,trim,accent,tint)
        for x in (-w*.32,w*.32):
            m.pipe([(x,.17,d*.5-.38),(x,.26,d*.5-.38)],.82,trim,"Metal",25)
            m.pipe([(x,.26,d*.5-.38),(x,.29,d*.5-.38)],.79,accent,"Light",25)
    else:
        hospitality(m,region,kind,w,d,h,wall,trim,accent,tint)
    roof(m,region,w,d,h,trim,wall,accent,shell)
    identity(m,region,kind,shell,w,d,h,wall,trim,accent)
    badge=min(w*.70,len(definition["marque"])*.32)
    sign_y=h-.31 if key=="fuel" or kind in ("parking","ev") else h-.18
    m.custom_box((0,sign_y,d*.53),(badge+.48,.51,.21),trim,.18,.056,"Paint")
    m.box((0,sign_y-.24,d*.548),(badge,.050,.045),accent,.012,"Light")
    return m


def upgrade(region, plan, definition, stage):
    wall,trim,accent,_,_ = plan["colors"]
    w,d,h=definition["size"]
    kind = definition["kind"]
    if stage==1:
        return annex(kind,1,-w*.57,-d*.25,wall,trim,accent,1.95)
    if stage==2:
        return annex(kind,2,w*.56,-d*.26,wall,trim,accent,2.18)
    m=Model()
    peak = .63 if region in ("tropical","wilderness","japan") else .20
    roof_work(m,kind,stage,-.63 if stage==3 else w*.23,h+peak,-d*.12,trim,accent)
    if stage==4:
        m.parts.extend(annex(kind,4,-w*.31,-d*.55,wall,trim,accent,2.36).parts)
    return m


def island_ground(seed=313):
    rng=Random(seed)
    m=Model()
    rim=[]
    rings=[(.14,-.123),(.67,-.123),(.83,-.123),(.91,-.127),(.99,-.176),(1.04,-.444)]
    n=48
    radius=[1+.095*cos(k*tau*3/n)+.051*sin(k*tau*7/n)+rng.uniform(-.025,.028) for k in range(n)]
    tint=[]
    for index,(scale,h) in enumerate(rings):
        for slot in range(n):
            a=slot*tau/n
            reach=radius[slot]*scale
            rim.append((77.0*cos(a)*reach, h, 43.0*sin(a)*reach-10))
            tint.append(("9cab72","acb478","dcc087","ebcc91","c99e69","97856b")[index])
    faces=[]
    for j in range(len(rings)-1):
        for k in range(n):
            a=j*n+k
            b=j*n+(k+1)%n
            faces.append((a,b,b+n,a+n))
    faces.append(tuple(reversed(range(n))))
    m.add(rim,faces,tint[0],smooth=True,vertex_colors=tint)
    return m


def coast_pier():
    m=Model()
    for x in (-.83,.83):
        for z in (-3.6,-2,-.4,1.2,2.8):
            m.pipe([(x,-.30,z),(x,.79,z)],.089,"795b4f",sides=10)
    for j in range(24):
        z=3.51-j*.323
        m.box((0,.22,z),(2.25,.18,.312),("b89165","c89c65","bc9464")[j%3],.041)
    for side in (-1,1):
        m.pipe([(side*.83,.67,3.14),(side*.83,.67,-3.74)],.043,IVORY,"Paint",8)
    return m


def mesa():
    m=Model()
    rng=Random(62)
    outline=[(.81+rng.uniform(-.13,.13),i*tau/13.0) for i in range(13)]
    colors=[]
    points=[]
    for i,(height,size) in enumerate([(0,1.25),(.53,.97),(1.49,.82),(3.40,.72),(4.05,.63),(4.43,.48)]):
        for wobble,side in outline:
            points.append((cos(side)*4.4*wobble*size+i*.13,height+sin(side*3)*.12,sin(side)*2.99*wobble*size))
            colors.append(("8b614f","a17155","aa6c50","bf7e58","d28d61","deb579")[i])
    faces=[]
    for layer in range(5):
        for a in range(13):
            b=(a+1)%13
            c=layer*13
            faces.append((c+a,c+a+13,c+b+13,c+b))
    faces.append(tuple(reversed(range(65,78))))
    m.add(points,faces,colors[0],smooth=True,vertex_colors=colors)
    return m


def cargo_ship():
    m=Model()
    for i,(h,w,d) in enumerate([(-.25,3.1,12.4),(.48,4.0,14.0),(1.24,4.17,14.0),(1.42,3.96,13.7)]):
        m.custom_box((0,h,.4),(w,.84,d),("815b55","485f6a","63838a","c4bda1")[i],d*.23,.21,"Paint")
    for x in (-.88,.87):
        for z in (-4.8,-2.0,.7,3.4):
            for y in (1.98,2.66):
                m.box((x,y,z),(1.54,.72,2.48),("ce8b58","568881","bd695c")[int((z+y+9)*3)%3],.060)
                for k in range(6):
                    m.box((x-.71,y,z-.99+.39*k),(.09,.65,.10),"6c6b69",.021,"Metal")
    for level in range(2):
        y=1.88+level*.77
        m.custom_box((0,y,5.1),(2.61,.81,1.73),IVORY,.20,.071)
        windows(m,0,y+.10,6.0,2.15,.42,GLASS,DARK,4)
    m.pipe([(0,2.98,5.24),(0,3.94,5.24)],.089,DARK,"Metal",8)
    return m


def fountain():
    m=Model()
    for y,w,h,col in [(0.08,2.96,.16,"a19584"),(.24,2.79,.29,"d4c5a1"),(.41,2.48,.11,"6faeb3")]:
        m.pipe([(0,y-h*.5,0),(0,y+h*.5,0)],w,col,sides=34)
    for i in range(18):
        a=i*tau/18
        m.orb((cos(a)*2.72,.40,sin(a)*2.72),(.12,.097,.12),IVORY,9,5,"Light")
    for y,w in [(.65,.43),(1.27,.72),(1.60,.29)]:
        m.pipe([(0,y-.20,0),(0,y+.13,0)],[w*.59,w],IVORY,sides=18)
    return m


def gate():
    m=Model()
    for x in (-1.55,1.55):
        post(m,x,0,3.02,"aa606d",wide=.29)
        for y in (.35,2.45):
            m.pipe([(x,y,0),(x,y+.19,0)],.208,"5d536e","Metal",10)
        m.box((x,2.59,.31),(.31,.36,.23),"e3a169",.052,"Light")
    for y,w in [(2.12,3.68),(3.04,4.75)]:
        m.custom_box((0,y,0),(w,.337,.45),"a96378",.25,.077,"Paint")
    m.pipe([(-2.66,3.36,0),(-2.0,3.20,0),(0,3.26,0),(2.0,3.20,0),(2.66,3.36,0)],.135,"595f78","Metal",10)
    return m


def tower(seed):
    rng=Random(seed)
    m=Model()
    height=4.7+rng.random()*3.8
    w=3.0+rng.random()*1.2
    for lo,count in [(0,1),(.18,4),(.73,2)]:
        cap=w*(1.22-lo*.62)
        center=height*(lo+.21)
        m.custom_box((0,center,0),(cap,height*.39,2.61-lo),"839d9d",.32,.09,"Tint")
        for row in range(count):
            y=center+height*.28*(row-(count-1)*.5)/max(1,count-1)
            m.box((0,y,0),(cap+.15,.078,2.73-lo),"c8c5aa",.03,"Paint")
            for x in (-cap*.26,cap*.26):
                m.box((x,y+.16,1.34-lo*.5),(cap*.29,.19,.022),("517884","d7bf97")[rng.randrange(2)],.014,
                      "Light" if rng.random()<.23 else "Tint")
    return m


def foliage(region):
    if region in ("tropical","luxury"):
        return palms()
    m=Model()
    if region=="wilderness":
        conifer_outline(m,0,0,True)
    elif region=="japan":
        m.pipe([(0,0,0),(.08,1.39,0),(-.13,2.49,.047)], [.22,.13,.06],"876a63",sides=11)
        for k,(x,z) in enumerate([(.60,.20),(0,-.21),(-.62,.19),(-.24,-.7),(.5,-.43)]):
            m.pipe([(0,.91,0),(x*.68,1.94,z*.55),(x,2.36,z)], [.09,.062,.026],"876a63",sides=7)
            canopy(m,(x,2.36+k*.15,z),(.82,.58,.70),("a9617f","cb8399","e3a4b4","efbcc0"),k,12)
    elif region=="route66":
        m.pipe([(0,0,0),(.02,1.97,0)], [.23,.194],"628b60",sides=13)
        for side in [-1,1]:
            m.pipe([(0,1.06,0),(side*.42,1.14,0),(side*.49,1.82,0)], [.13,.14,.09],"78a171",sides=11)
            m.orb((side*.49,1.82,0),(.097,.14,.11),"87ac68",10,6)
        m.orb((.02,1.96,0),(.204,.25,.214),"7ba265",12,7)
    else:
        m.custom_box((0,.24,0),(1.43,.46,.8),"8e9480",.14,.065)
        for x in (-.46,0,.46):
            canopy(m,(x,.65,0),(.43,.39,.4),("4f7767","688c66","81a171","b3b381"),x*2,10)
    return m


def landmark(region):
    return {"tropical":coast_pier, "route66":mesa, "harbor":cargo_ship,
            "luxury":fountain, "japan":gate,"wilderness":lambda:mountain(25, True)}[region]()


def miniature(region, plan):
    m=Model()
    _,trim,accent,_,_=plan["colors"]
    m.custom_box((0,-.22,0),(10.8,.38,6.54),plan["surface"][1],.85,.108)
    m.custom_box((0,-.007,1.98),(10.1,.052,1.37),plan["surface"][2],.16,.024)
    for x in range(-4,5,2):
        m.box((x,.05,1.98),(1.1,.017,.062),IVORY,.007)
    add_model(m,business(region,plan,plan["scenes"][0]),(-.85,.02,.23),.57)
    add_model(m,landmark(region),(3.45,.03,-1.35),.32,.17)
    add_model(m,foliage(region),(-3.87,.03,.67),.52)
    m.box((.48,.12,1.93),(1.03,.22,.53),accent,.09,"Paint",yaw=-.12)
    return m


def export_region(region):
    plan=DISTRICTS[region]
    for definition in plan["scenes"]:
        key=definition["key"]
        write_model("regions",f"{region}_{key}",business(region,plan,definition))
        for stage in range(1,5):
            write_model("regions",f"{region}_{key}_{stage}",upgrade(region,plan,definition,stage))
    write_model("regions",region+"_foliage",foliage(region))
    write_model("regions",region+"_landmark",landmark(region))
    write_model("regions",region+"_atlas",miniature(region,plan))
    if region=="tropical":
        write_model("regions","tropical_shore",island_ground())
    if region in ("luxury","japan"):
        for i in range(3):
            write_model("regions",f"{region}_skyline_{i}",tower(i+23+(4 if region=="japan" else 0)))


if __name__=="__main__":
    for region in (sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else DISTRICTS):
        export_region(region)
