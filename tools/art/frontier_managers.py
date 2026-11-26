"""Original rigs and portraits for the World Expansion team."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from characters import Outfit, actor
from kit import clear_objects, export, output_root
from portraits import RARE, EPIC, LEGENDARY, render

TEAM = [
    Outfit("noa","b57858","302f31","57968d","efcb8a","415a64",hair_style="curl",accessory="earrings"),
    Outfit("talia","935c4b","33262f","b26d65","ffd691","4f6d66",hair_style="wrap",accessory="glasses"),
    Outfit("mona","d69b76","674335","a95e53","f7cc82","59686a",hair_style="bob",accessory="earrings"),
    Outfit("iman","8d5647","332d34","4b899c","e8d09b","444f62",hat="a67445",accessory="beard"),
    Outfit("hugo","bc8a70","4f3838","7a8486","e4bc6c","455264",hair_style="fade",accessory="glasses"),
    Outfit("selene","d7a17b","4a3244","7f7193","ead8a8","4b5664",hair_style="bun",accessory="earrings"),
    Outfit("akio","c99675","342d3c","5b6e9d","e5b6b0","59647d",hair_style="fade",accessory="glasses"),
    Outfit("soren","bc8b70","6a4938","6e8467","d8bf82","505c59",hat="637b71",accessory="beard"),
]
RARE.update({"talia","mona","hugo"})
EPIC.update({"noa","iman","akio","soren"})
LEGENDARY.add("selene")

for index, outfit in enumerate(TEAM):
    clear_objects()
    actor(outfit)
    root = output_root()
    export(root / "assets/models/characters" / (outfit.key+".glb"))
    render(outfit, index, root / "assets/ui/managers")
