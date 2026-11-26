"""Canopy forms from a common palette; vertices carry leaf light and shade."""
from math import cos, sin, tau, pi
from random import Random

from kit import Model, ring_faces


def canopy(m, center, size, colors, variation, segments=13):
    x, y, z = center
    w, h, d = size
    rings = [(-.83,.28),(-.62,.71),(-.25,.94),(.15,1.0),(.53,.81),(.82,.49),(.93,.18)]
    points, tones = [], []
    for row,(level,radius) in enumerate(rings):
        for i in range(segments):
            a = i*tau/segments
            amplitude = .097*sin(3*a+variation+row*.27)+.064*cos(7*a-row*.58+variation)
            rim = radius*(1+amplitude)
            points.append((x+cos(a)*w*rim,y+h*(level+.05*sin(a*4+variation)),z+sin(a)*d*rim))
            tones.append(colors[min(len(colors)-1,max(0,row//2 + int(i%7==1) - int(i%7==4)))])
    faces, flags = ring_faces(segments,len(rings),caps=True)
    m.add(points,faces,colors[0],smooth=flags,vertex_colors=tones)


def deciduous(autumn=False):
    m=Model()
    rng=Random(370 if autumn else 72)
    bark = "825947" if autumn else "7f6550"
    m.pipe([(0,-.04,0),(-.045,.27,0),(.084,.89,.12),(.13,1.48,.09),(-.14,2.47,-.04)],
           [.245,.215,.171,.132,.042],bark,sides=11)
    for i in range(4):
        a=i*tau/4+.81
        m.pipe([(.035,.24,.036),(cos(a)*.32,.063,sin(a)*.36),(cos(a)*.55,.004,sin(a)*.51)],
               [.096,.059,.011],bark,sides=6)
    outer = [(-1.02,2.52,.22,.91),(-.67,3.05,-.42,.87),(.53,3.43,.02,.98),
             (.97,2.72,.28,.92),(.61,3.04,-.70,.83),(-.26,3.65,.19,1.04),(-.19,2.67,.79,.87)]
    palettes = [("83573e","a76737","d18c43","e3ae5c"),("8a5844","b76c44","cd9f58","ecc371")]         if autumn else [("346049","4b7850","60944c","87ab5c"),("295b4d","407957","65995d","8ab86d")]
    for i,(x,y,z,s) in enumerate(outer):
        m.pipe([(.08,1.41,.10),(x*.41,y*.72,z*.31),(x*.86,y*.92,z*.8),(x,y,z)],
               [.074,.056,.037,.019],bark,sides=6)
        canopy(m,(x,y,z),(s,s*.69,s*.86),palettes[i%2],rng.uniform(-pi,pi))
        if i%2==0:
            canopy(m,(x*1.10,y+.30,z+.22),(s*.57,s*.44,s*.56),palettes[(i+1)%2],i,10)
    return m


def shrub():
    m=Model()
    for i,(x,y,z,s) in enumerate([(-.59,.26,.11,.53),(-.20,.45,-.10,.62),(.28,.38,.09,.54),(.71,.26,-.18,.42)]):
        shade=("315d49","4d8152","75a052","9bb569") if i%2 else ("426d52","53824c","83a356","aeb86c")
        canopy(m,(x,y,z),(s,s*.71,s*.77),shade,i,10)
    for i in range(9):
        x=(i-4)*.159
        y=.48+.17*sin(i*.86)
        z=.30+.06*cos(i*.57)
        m.orb((x,y,z),(.069,.047,.055),("ebbf74","d87960","d9d49a")[i%3],7,4)
    return m


def conifer_outline(m, x, z, snow=False):
    m.pipe([(x,0,z),(x+.05,1.58,z),(x-.06,3.13,z+.059)], [.165,.099,.019],
           "6f6151",sides=8)
    for i,(height,radius) in enumerate(((1.13,1.03),(1.72,.87),(2.27,.68),(2.83,.48))):
        s=i*.27
        palette = ("295753","376d60","639586","bbd5d4") if snow else ("305a50","42765b","588761","759965")
        canopy(m,(x+s*.13,height,z+s*.08),(radius,.68-i*.04,radius*.89),palette,1.3-i,12)
        if snow:
            canopy(m,(x+.035,height+.28,z),(radius*.82,.42,radius*.79),
                   ("7dadad","bfd5d9","e3e7ed","f7f4ec"), i+.31,10)


def palms():
    m=Model()
    m.pipe([(0,-.02,0),(.08,.68,0),(.21,1.44,.05),(.30,2.67,.13),(.16,3.63,.23)],
           [.186,.148,.119,.101,.123],"a58761","Ceramic",11)
    for step in [1,3,4,6,7,9]:
        y=step*.34+.24
        x=min(.23,y*.091)
        m.pipe([(x,y,.046*y),(x+.004,y+.035,.047*y)], .134 if y<1.78 else .111,"b59a71","Ceramic",10)
    for i in range(12):
        a=i*tau/12
        dx,dz=cos(a),sin(a)
        length=1.30+.43*(i%3==1)+.2*(i%3==2)
        origin=(.17,3.61+.13*(i%2),.23)
        ribs=[(0,0),(.33,.29),(.68,.23),(1.0,-.10),(1.24,-.52)]
        def point(d,y,w):
            return (origin[0]+dx*d*length-dz*w,origin[1]+y,origin[2]+dz*d*length+dx*w)
        m.pipe([point(d,y,0) for d,y in ribs],[.054,.039,.025,.012,.006],"9eb06e","Ceramic",7)
        for row in range(1,8):
            t=row/8
            y=.40*sin(pi*t)-.29*t*t
            w=sin(pi*t)*(.48+.10*(i%2))
            for side in [-1,1]:
                points=[point(t-.15,y-.038,.016*side),point(t+.027,y+.025,0),
                        point(t+.17,y-.074,w*side),point(t+.055,y-.102,w*.77*side)]
                m.add(points,[(0,1,2),(0,2,3)] if side<0 else [(0,2,1),(0,3,2)],
                      "609663",smooth=True,vertex_colors=["407d59","508d62","83b477","689f68"])
        m.orb((origin[0]-.13*dz,3.52,origin[2]+.13*dx),(.103,.137,.104),"a9825a",7,4)
    return m
