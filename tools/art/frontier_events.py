"""Original festive installations. Each combines business equipment with a district motif."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from frontier_art import add_model, gate
from kit import Model
from legacy_works import write_model
from premium_facades import awning, lamp
from venue_works import foot, pallet, post


def exhibit(key):
    m=Model()
    foot(m,0,0,0,2.45,1.71)
    if key=="supercar_run":
        for i in range(3):
            m.custom_box(((i-1)*.63,.36-i*.067,.11),(.61,.54-i*.13,.87),
                         ("b97586","efb065","588c83")[i],.12,.048,"Paint")
        for side in (-1,1):
            post(m,side*.87,-.48,1.61,"607d86",wide=.10)
            for row in range(3):
                for col in range(3):
                    m.box((side*.87+(col-1)*.111,1.44-row*.11,-.41),(.111,.111,.035),
                          "efdebc" if (col+row)%2 else "445460",.008)
    elif key=="island_week":
        for x in (-.84,.84):
            post(m,x,-.26,1.54,"8b7357",wide=.12)
        awning(m,0,1.51,-.39,1.98,1.12,("d57565","eed6a7"),8)
        for idx,x in enumerate((-.48,0,.47)):
            m.custom_box((x,.65,.26),(.23,1.18,.16),
                         ("609c98","e8af65","cb7f71")[idx],.115,.043,"Paint",yaw=(idx-1)*.18)
    elif key=="logistics_week":
        for x in (-.86,.86):
            post(m,x,-.22,2.03,"72939a",wide=.12)
        m.custom_box((0,1.98,-.22),(1.95,.23,.25),"cf9c63",.095,.040,"Metal")
        m.box((.28,1.79,-.20),(.47,.15,.48),"4e6b79",.04,"Metal")
        m.pipe([(.28,1.74,-.04),(.28,1.11,-.04)],.032,"4d5a60","Metal",7)
        pallet(m,-.57,.16,.43,"b7845a")
        pallet(m,.44,.16,.22,"688e88",1)
    elif key=="akari_matsuri":
        add_model(m,gate(),(0,.18,-.16),.48)
        for x in (-.77,-.30,.30,.77):
            m.pipe([(x,1.48,-.10),(x,1.29,.045)],.022,"524f64","Metal",7)
            m.orb((x,1.18,.06),(.116,.147,.115),"ecaa73",12,8,"Light")
    elif key=="classic_rally":
        post(m,0,-.20,1.63,"916c55",wide=.13)
        m.custom_box((0,1.31,-.07),(1.97,.58,.20),"945957",.23,.098,"Paint")
        for dx in (-.44,.44):
            m.pipe([(dx,1.31,.038),(dx,1.31,.13)],.18,"cfb181","Metal",15)
            m.pipe([(dx,1.31,.12),(dx,1.31,.16)],.088,"eeb26a","Light",15)
        m.box((0,1.29,.054),(.42,.046,.035),"f3d295",.011,"Light")
    else:
        for i in range(5):
            x=(i%3-1)*.38+(i//3)*.18
            y=.31+(i//3)*.33
            m.pipe([(x,y,-.61),(x,y,.59)],.171,"a58156",sides=12)
            m.pipe([(x,y,.59),(x,y,.623)],.143,"d8be8d",sides=12)
        for x in (-.78,.78):
            post(m,x,-.28,1.61,"667c80",wide=.13)
        m.custom_box((0,1.52,-.20),(1.72,.33,.28),"698e8f",.16,.058,"Metal")
        lamp(m,0,1.38,.08,.13)
    return m


if __name__=="__main__":
    for name in ("supercar_run","island_week","logistics_week","akari_matsuri","classic_rally","timber_convoy"):
        write_model("desert","event_"+name,exhibit(name))
