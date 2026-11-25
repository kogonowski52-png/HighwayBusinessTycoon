"""Run with blender -b -t 2 --python tools/art/generate.py -- [families ...]."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from kit import output_root

families = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
for family in families or ["architecture", "extensions", "landscape", "vehicles", "characters", "expansion_characters"]:
    if family == "directors":
        from characters import generate_directors
        generate_directors(output_root())
    elif family == "expansion_characters":
        from characters import generate_expansion
        generate_expansion(output_root())
    else:
        module = __import__(family)
        module.generate(output_root())
        if family == "characters":
            module.generate_directors(output_root())
