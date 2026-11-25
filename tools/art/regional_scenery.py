"""Landmarks for the regional maps. Dimensions are in Godot metres."""
from math import cos, pi, sin
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from kit import Model, bake_occlusion, clear_objects, export, output_root


def bridge():
    m = Model()
    for side in [-1, 1]:
        z = side * 2.87
        for x in [-4.35,-2.18,0,2.18,4.35]:
            m.box((x,.40,z),(.28,.79,.31),"a49680",.055)
            m.box((x,.82,z),(.38,.15,.40),"dfc191",.055)
            m.box((x,-.32,z),(.46,.33,.43),"847f70",.045)
        m.box((0,.56,z),(8.82,.14,.15),"426762",.042,"Metal")
        m.box((0,.31,z),(8.82,.12,.15),"6a8379",.035,"Metal")
        for i in range(16):
            m.box(((i-7.5)*.54,-.12,z),(.51,.25,.59),"b4a58a" if i%3 else "a69982",.06)
    m.custom_box((0,-.20,0),(9.05,.36,6.12),"8e8574",.34,.085)
    return m


def pier():
    m=Model()
    for i in range(16):
        m.box((0,.08,i*.55),(3.18,.24,.54),"bf9772" if i%3 else "ba8c68",.046)
    for side in [-1,1]:
        x=side*1.52
        for z in (0,2.13,4.27,6.39,8.30):
            m.box((x,-.37,z),(.33,1.25,.34),"926e58",.063)
            m.box((x,.50,z),(.19,.73,.20),"e5cc9b",.05)
            m.box((x,.88,z),(.31,.13,.29),"f2d9aa",.044)
        m.box((x,.70,4.18),(.11,.08,8.46),"e8c499",.028)
    for x in (-.84,.84):
        m.box((x,.27,6.8),(.31,.24,1.70),"edc8a1",.059)
    return m


def lighthouse():
    m=Model()
    for y,s,c in [(.3,1.53,"a59584"),(.73,1.32,"e5c9a6"),(1.45,1.03,"eee1c9"),(2.46,.99,"d78060"),(3.43,.92,"f4e6c7"),(4.30,.84,"d67b5f")]:
        m.pipe([(0,y-.50,0),(0,y+.50,0)],s,c,sides=12)
    m.pipe([(0,4.73,0),(0,4.90,0)],1.13,"446c77","Metal",14)
    m.pipe([(0,4.93,0),(0,5.60,0)],.73,"73b6b5","Tint",12)
    m.pipe([(0,5.64,0),(0,6.20,0)],.84,"508f97","Paint",12)
    m.orb((0,6.04,0),(.84,.38,.84),"3f7f90",14,7)
    for i in range(12):
        t=i*pi/6
        x,z=.73*cos(t),.73*sin(t)
        m.pipe([(x,4.92,z),(x,5.62,z)],.042,"3d6871","Metal",6)
    m.box((0,1.26,.97),(.53,1.19,.12),"5d8a87",.06)
    m.box((0,1.45,1.035),(.30,.43,.06),"9ebdbc",.045,"Tint")
    return m


def skyline(kind):
    m=Model()
    w,d,h,trim,finish=[(6.3,5.4,10.2,"5b7d91","7c9aa4"),(7.9,6.2,14.1,"556983","7a859b"),
                        (5.1,5.8,8.6,"648b96","91a9ad")][kind]
    m.custom_box((0,h*.5,0),(w,h,d),finish,.56,.16)
    m.custom_box((0,h+.13,-.15),(w+.23,.52,d+.18),trim,.56,.12,"Paint")
    m.custom_box((0,h+.51,-.65),(w*.65,.40,d*.60),"a0b3bb",.37,.115)
    for row in range(int(h/1.18)):
        y=.95+row*1.19
        for i in range(4):
            x=w*(i-1.5)*.214
            m.box((x,y,d*.5+.051),(w*.18,.74,.117),trim,.064)
            shade="ebbc90" if (i+row+kind)%3==0 else "84a6b4"
            m.box((x,y,d*.5+.126),(w*.155,.61,.061),shade,.047,"Light" if shade=="ebbc90" else "Tint")
            z=d*(i-1.5)*.210
            m.box((w*.5+.05,y,z),(.12,.74,d*.18),trim,.064)
            m.box((w*.5+.127,y,z),(.06,.60,d*.155),shade,.046,"Light" if shade=="ebbc90" else "Tint")
    for x in [-w*.38,w*.38]:
        m.pipe([(x,.08,d*.55),(x,h-.1,d*.55)],.079,"a6bbc1","Metal",8)
    return m


def gondola():
    m=Model()
    for x in [-1.15,1.15]:
        m.box((x,2.76,0),(.34,5.44,.48),"747d83",.085,"Metal",yaw=.08)
        m.box((x,.36,0),(1.20,.64,1.44),"adb9bc",.12)
    m.box((0,5.52,0),(3.24,.33,.66),"d38e55",.09,"Metal")
    for x in (-1.37,1.37):
        m.pipe([(x,5.55,-.5),(x,5.60,.5)],.24,"465c67","Metal",10)
    m.pipe([(-.92,5.6,0),(-.92,4.74,0)],.071,"586776","Metal",8)
    m.custom_box((-.92,4.06,0),(1.37,1.36,1.22),"aa5455",.27,.11,"Paint")
    m.box((-.92,4.21,.64),(1.14,.73,.10),"80a5ae",.10,"Tint")
    return m


assets={"valley_bridge":bridge(),"ocean_pier":pier(),"ocean_lighthouse":lighthouse(),
        "alpine_gondola":gondola(),**{f"metro_tower_{i}":skyline(i) for i in range(3)}}
for key,model in assets.items():
    clear_objects()
    obj=model.mesh(key.title())
    bake_occlusion(obj,radius=1.1,strength=.45)
    export(output_root()/"assets/models/regions"/f"{key}.glb")
