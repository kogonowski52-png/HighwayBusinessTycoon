"""Make the rig and studio portrait for each regional manager."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from characters import Outfit, actor
from kit import clear_objects, export, output_root
from portraits import EPIC, LEGENDARY, RARE, render

DIRECTORS = [
    Outfit("tess", "dcaa82", "744733", "68836a", "f6c68b", "526759", hair_style="curl", accessory="earrings"),
    Outfit("roan", "b58269", "513935", "567589", "e9cc8d", "44535e", hat="526785", accessory="beard"),
    Outfit("ines", "aa6d53", "362e2e", "459b9c", "ffe4aa", "3e6173", hair_style="bun", accessory="earrings"),
    Outfit("dev", "925d4c", "303a3e", "cd8b52", "f5d48e", "455464", hat="a6794f", accessory="glasses"),
    Outfit("mila", "d4ad8c", "846048", "658e97", "f1d0a3", "4c5a69", hair_style="wrap", accessory="glasses"),
    Outfit("ren", "8b5745", "3c2f35", "a96778", "ffe1ba", "535673", hair_style="fade", accessory="beard"),
    Outfit("ellis", "c68564", "3d302c", "4f7993", "e9e0bd", "485e71", hair_style="bob", accessory="glasses"),
]
RARE.update({"tess", "ines", "ellis"})
EPIC.update({"roan", "mila", "ren"})
LEGENDARY.add("dev")

root = output_root()
for index, role in enumerate(DIRECTORS):
    clear_objects()
    actor(role)
    export(root / "assets/models/characters" / f"{role.key}.glb")
    render(role, index, root / "assets/ui/managers")
