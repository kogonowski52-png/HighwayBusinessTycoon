"""Original BOOST, treasury, gems, Builder kits and bonus aircraft."""
from math import cos, pi, sin, tau
from pathlib import Path
import sys
import wave
import struct

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from kit import Model, clear_objects, export, bake_occlusion, output_root
from characters import Outfit, actor
from portraits import RARE, EPIC, LEGENDARY, render as portrait

GOLD = "f8bd4e"
LIT = "fff09e"
COPPER = "a96535"
PETROL = "28636a"


def coin(m, at, radius=.35):
    x,y,z=at
    m.pipe([(x,y-.075,z),(x,y+.075,z)],radius,GOLD,"Metal",24)
    m.pipe([(x,y+.076,z),(x,y+.091,z)],radius*.85,LIT,"Metal",24)
    m.pipe([(x,y+.092,z),(x,y+.108,z)],radius*.72,"e1a449","Metal",20)
    for i in range(16):
        t=tau*i/16
        m.orb((x+cos(t)*radius*.94,y+.093,z+sin(t)*radius*.94),(.027,.019,.025),
              "e4a449",7,4,"Metal")
    m.box((x,y+.117,z),(.10,.03,.26),"ffd475",.024,"Metal")
    m.box((x,y+.117,z),(.21,.029,.064),"ffd475",.022,"Metal")


def gem(m, at, width, hue):
    x,y,z=at
    points=[]
    for height,radius in ((0,.06),(.38,1),(.73,.61)):
        for i in range(8):
            angle=tau*i/8+pi/8
            points.append((x+cos(angle)*width*radius,y+height*width,z+sin(angle)*width*radius))
    for i in range(8):
        side=(i+1)%8
        p=[points[n] for n in (i,side,side+8,i+8)]
        m.add(p, [(0,1,2,3)],hue[i%len(hue)],"Ceramic")
        m.add([points[n] for n in (i+8,side+8,side+16,i+16)],[(0,1,2,3)],hue[(i+2)%len(hue)],"Metal")
    m.add(points[16:], [tuple(range(7,-1,-1))], hue[-1],"Tint")


def bolt(m, at=(0,0,0), scale=1):
    polygon=[(-.12,.26),(.61,1.52),(.91,1.56),(.71,.86),(1.14,.87),(.31,-.24),(.40,.42),(.06,.40)]
    x,y,z=at
    coords=[(x+(a-.47)*scale,y+b*scale,z+c*scale) for c in (-.16,.16) for a,b in polygon]
    triangles=[(0,1,2),(0,2,3),(0,3,7),(3,4,5),(3,5,6),(3,6,7)]
    m.add(coords,[tuple(reversed(t)) for t in triangles]+[tuple(i+8 for i in t) for t in triangles],
          GOLD,"Metal")
    for i in range(8):
        j=(i+1)%8
        m.add(coords,[(i,j,j+8,i+8)],COPPER,"Metal")
    for i in range(8):
        a,b=coords[8+i],coords[8+(i+1)%8]
        m.pipe([a,b],.027*scale,LIT,"Light",7)


def chest(m, tint=PETROL):
    m.custom_box((0,.32,0),(1.67,.64,1.03),tint,.17,.12,"Paint")
    m.custom_box((0,.71,-.04),(1.71,.25,1.07),tint,.19,.09,"Paint")
    for offset in [-.59,.59]:
        m.box((offset,.36,.54),(.15,.67,.08),COPPER,.038,"Metal")
        m.box((offset,.86,-.02),(.18,.06,1.05),GOLD,.031,"Metal")
        for zz in [-.49,.55]:
            m.orb((offset,.67,zz),(.06,.066,.025),LIT,9,6,"Metal")
    m.box((0,.52,.575),(.36,.34,.16),GOLD,.072,"Metal")
    m.box((0,.52,.66),(.11,.126,.024),COPPER,.018,"Metal")


def treasure():
    m=Model()
    chest(m)
    greens=["669e70","85b983","ded9a8"]
    for row in range(4):
        m.box((-.26,.87+.052*row,-.07),(.72,.047,.53),greens[row%3],.045,yaw=.12*row)
    for x,z,levels in [(.64,.69,3),(-.73,.74,1),(.8,-.63,2)]:
        for row in range(levels):
            coin(m,(x,.075+.145*row,z),.24)
    return m


def lightning():
    m=Model()
    bolt(m,(0,.15,.16),1.03)
    for i,(x,z) in enumerate([(-.56,.46),(.70,.48),(-.52,-.24)]):
        for row in range(1+i%2):
            coin(m,(x,.087+row*.14,z),.29)
    return m


def crystal():
    m=Model()
    m.custom_box((0,.066,0),(1.75,.13,1.04),"527784",.29,.048,"Paint")
    colors=["6387c9","8578b9","56a8bc","a6e2dc","bc95e3","c7f7f0"]
    gem(m,(.10,.18,-.10),.61,colors)
    gem(m,(-.49,.17,.18),.43,colors)
    gem(m,(.55,.17,.25),.41,colors)
    return m


def builder():
    m=Model()
    chest(m,"9e6752")
    m.box((.13,.96,-.18),(1.35,.26,.36),"d0a775",.057,yaw=.36)
    for z in [-.38,.17]:
        m.box((.19,1.03,z),(1.10,.20,.24),"bd9c74",.045,"Ceramic",yaw=-.14)
    clip=[(-.50,.84,.18),(-.04,1.12,.48),(.32,1.29,.50)]
    m.pipe(clip,.086,"c7d8ca","Metal",10)
    m.orb((.38,1.29,.51),(.26,.098,.16),"bfcfce",12,6,"Metal")
    return m


def banner():
    m=Model()
    for x in [-.58,.58]:
        m.pipe([(x,0,0),(x,1.62,0)],.054,COPPER,"Metal",10)
        m.orb((x,1.63,0),(.091,.091,.091),GOLD,11,7,"Metal")
    m.custom_box((0,.92,.064),(1.06,1.23,.11),"486f92",.15,.038,"Paint")
    m.box((0,1.42,.13),(.89,.083,.057),GOLD,.030,"Metal")
    for i in range(3):
        m.orb(((i-1)*.225,.75 if i%2 else 1.00,.156),(.09,.09,.052),"fff2ae",11,7,"Light")
    m.box((0,.56,.14),(.76,.052,.055),"95acbd",.015,"Metal")
    return m


def helicopter():
    m=Model()
    m.orb((0,.49,.14),(.65,.44,1.17),"d69a49",17,8,"CoachPaint")
    m.orb((0,.64,.67),(.56,.39,.58),"658d9f",16,8,"Tint")
    for x in [-.52,.52]:
        m.box((x,.32,-.04),(.087,.17,1.20),"f8d27b",.033,"Paint")
        m.pipe([(x,.44,-.40),(x,.13,-.44),(x,.055,-.78),(x,.05,.88)],.056,"486066","Metal",9)
    m.pipe([(0,.50,-.41),(0,.66,-1.29),(0,.88,-2.16)],[.26,.18,.095],COPPER,"Paint",10)
    m.box((0,.96,-2.04),(.10,.61,.38),"cf8851",.08,"Metal")
    m.box((0,.89,-1.59),(.82,.10,.32),PETROL,.068,"Paint")
    m.pipe([(0,.84,0),(0,1.13,0)],.097,"536b77","Metal",12)
    m.box((0,.13,.08),(.45,.35,.53),"a07e62",.07)
    return m


def rotor():
    m=Model()
    m.orb((0,0,0),(.22,.086,.22),"a0aeb1",14,6,"Metal")
    for angle in (0,pi/2):
        m.box((0,0,0),(.17,.056,3.77),"617b81",.062,"Metal",angle)
    return m


def stationary(asset, model):
    clear_objects()
    obj=model.mesh(asset)
    bake_occlusion(obj, radius=.60, strength=.4)
    export(output_root()/"assets/models/premium"/f"{asset}.glb")


def thumbnail(asset, model):
    stationary(asset, model)
    scene=bpy.context.scene
    target=Vector((0,0,.57))
    camera=bpy.data.objects.new(asset+"Camera",bpy.data.cameras.new(asset+"Camera"))
    bpy.context.collection.objects.link(camera)
    camera.location=target+Vector((2.4,-4.4,3.01))
    camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.type="ORTHO"
    camera.data.ortho_scale=2.73
    scene.camera=camera
    for pos,power,tint,size in [((-2,-3,4),305,(1,.89,.72),3),((2.5,-2.8,2),100,(.71,.86,1),2.2),
                                ((1,1.6,4),162,(1,.72,.47),2)]:
        light=bpy.data.lights.new("Studio","AREA")
        light.energy,light.color,light.size=power,tint,size
        node=bpy.data.objects.new("Studio",light)
        bpy.context.collection.objects.link(node)
        node.location=pos
        node.rotation_euler=(target-node.location).to_track_quat("-Z","Y").to_euler()
    scene.render.engine="CYCLES"
    scene.cycles.samples=44
    scene.cycles.use_denoising=False
    scene.render.film_transparent=True
    scene.render.resolution_x=scene.render.resolution_y=400
    scene.render.resolution_percentage=100
    scene.render.image_settings.color_mode="RGBA"
    folder=output_root()/"assets/ui/premium"
    folder.mkdir(parents=True,exist_ok=True)
    scene.render.filepath=str(folder/f"{asset}.png")
    bpy.ops.render.render(write_still=True)


def chime():
    sample_rate=44_100
    frames=[]
    for sample in range(int(sample_rate*.79)):
        t=sample/sample_rate
        value=0.0
        for i,pitch in enumerate([523.25,659.25,783.99,1046.50]):
            age=t-i*.094
            if age>=0:
                envelope=min(1.0,age*95)*max(0.0,1-age*2.65)**2
                value+=envelope*(.66*sin(tau*pitch*age)+.18*sin(tau*pitch*2*age)+.13*sin(tau*pitch*3*age))
        frames.append(struct.pack("<h",int(max(-.9,min(.9,value*.41))*32767)))
    with wave.open(str(output_root()/"assets/audio/boost.wav"),"wb") as file:
        file.setparams((1,2,sample_rate,0,"NONE","not compressed"))
        file.writeframes(b"".join(frames))


for key,model in {"bolt":lightning(),"treasury":treasure(),"gems":crystal(),"builder":builder(),"season":banner()}.items():
    thumbnail(key,model)
stationary("helicopter",helicopter())
stationary("rotor",rotor())
gate=Model()
for x in [-1.21,1.21]:
    gate.box((x,.79,0),(.25,1.58,.28),COPPER,.077,"Metal")
gate.custom_box((0,1.60,.0),(2.74,.29,.41),GOLD,.19,.086,"Paint")
gate.box((0,1.66,.23),(2.32,.088,.042),LIT,.028,"Light")
stationary("gold_gate",gate)
RARE.add("reese")
EPIC.add("sana")
LEGENDARY.add("rhea")
for index,outfit in enumerate([
    Outfit("sana","bb805e","3e3236","5f8690","f5cc85","44535e",hair_style="bun",accessory="earrings"),
    Outfit("reese","96634d","2e3537","a66f4f","efd6ab","515667",hair_style="fade",accessory="glasses"),
    Outfit("rhea","d7a381","784939","9b657a","f0bd69","4c4c62",hair_style="curl",accessory="earrings"),
]):
    clear_objects()
    actor(outfit)
    export(output_root()/"assets/models/characters"/f"{outfit.key}.glb")
    portrait(outfit,index,output_root()/"assets/ui/managers")
chime()
