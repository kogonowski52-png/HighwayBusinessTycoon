"""Group opaque surfaces in existing GLBs without changing their geometry.

Each triangle retains its exported vertex tint, normals and winding. Metalness
and roughness are stored per vertex in the unused UV channel. Separate
emissive and transparent surfaces keep their original materials and properties.

Run after regenerating the original six regions' models.
"""
import argparse
import collections
import json
from pathlib import Path
import struct


COMPONENT_BYTES = {5121: 1, 5123: 2, 5125: 4, 5126: 4}
CHANNELS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}
REGIONS = ("valley", "alpine", "ocean", "metro")
ATTRIBUTES = ("POSITION", "NORMAL", "COLOR_0")


class StaticModel:
    def __init__(self, path):
        self.path = path
        contents = path.read_bytes()
        marker, version, _, length, kind = struct.unpack_from("<5I", contents)
        if marker != 0x46546C67 or version != 2 or kind != 0x4E4F534A:
            raise ValueError(f"Unsupported model {path}")
        self.doc = json.loads(contents[20:20 + length])
        self.binary = bytearray(contents[28 + length:])

    def finish(self, primitive):
        if tuple(sorted(primitive.get("attributes", {}))) != tuple(sorted(ATTRIBUTES)):
            return None
        if primitive.get("mode", 4) != 4 or "indices" not in primitive or "material" not in primitive:
            return None
        material = self.doc["materials"][primitive["material"]]
        if not material.get("doubleSided", False) or set(material) - {"name", "doubleSided", "pbrMetallicRoughness"}:
            return None
        pbr = material.get("pbrMetallicRoughness", {})
        if set(pbr) - {"metallicFactor", "roughnessFactor"}:
            return None
        signature = tuple((self.doc["accessors"][primitive["attributes"][k]]["componentType"],
                           self.doc["accessors"][primitive["attributes"][k]].get("normalized", False))
                          for k in ATTRIBUTES)
        return signature

    def bytes_of(self, view_id):
        view = self.doc["bufferViews"][view_id]
        start = view.get("byteOffset", 0)
        return self.binary[start:start + view["byteLength"]]

    def read(self, index):
        item = self.doc["accessors"][index]
        view = self.doc["bufferViews"][item["bufferView"]]
        size = COMPONENT_BYTES[item["componentType"]] * CHANNELS[item["type"]]
        start = view.get("byteOffset", 0) + item.get("byteOffset", 0)
        stride = view.get("byteStride", size)
        if stride == size:
            return self.binary[start:start + size * item["count"]]
        return b"".join(self.binary[i:i + size] for i in range(start, start + stride * item["count"], stride))

    def add_view(self, data, target=0):
        self.binary.extend(b"\0" * (-len(self.binary) % 4))
        view = {"buffer": 0, "byteOffset": len(self.binary), "byteLength": len(data)}
        if target:
            view["target"] = target
        self.binary.extend(data)
        self.doc["bufferViews"].append(view)
        return len(self.doc["bufferViews"]) - 1

    def add_accessor(self, data, details, target):
        details["bufferView"] = self.add_view(data, target)
        self.doc["accessors"].append(details)
        return len(self.doc["accessors"]) - 1

    def merged_surface(self, primitives):
        materials = self.doc["materials"]
        data = {k: bytearray() for k in (*ATTRIBUTES, "TEXCOORD_0")}
        bounds = collections.defaultdict(list)
        indices = []
        vertex_count = 0
        for primitive in primitives:
            attrs = primitive["attributes"]
            count = self.doc["accessors"][attrs["POSITION"]]["count"]
            for name in ATTRIBUTES:
                item = self.doc["accessors"][attrs[name]]
                data[name].extend(self.read(attrs[name]))
                if "min" in item and "max" in item:
                    bounds[name].append((item["min"], item["max"]))
            component = self.doc["accessors"][primitive["indices"]]["componentType"]
            indices.extend(vertex_count + row[0] for row in struct.iter_unpack(
                {5121: "<B", 5123: "<H", 5125: "<I"}[component], self.read(primitive["indices"])))
            vertex_count += count
            pbr = materials[primitive["material"]].get("pbrMetallicRoughness", {})
            properties = (float(pbr.get("metallicFactor", 1.0)), float(pbr.get("roughnessFactor", 1.0)))
            data["TEXCOORD_0"].extend(struct.pack("<ff", *properties) * count)
        merged = {}
        for name, payload in data.items():
            source = self.doc["accessors"][primitives[0]["attributes"][name]] if name in ATTRIBUTES else {}
            item = {"type": source.get("type", "VEC2"), "componentType": source.get("componentType", 5126), "count": vertex_count}
            if source.get("normalized"):
                item["normalized"] = True
            if name == "POSITION":
                item["min"] = [min(limit[0][i] for limit in bounds[name]) for i in range(3)]
                item["max"] = [max(limit[1][i] for limit in bounds[name]) for i in range(3)]
            merged[name] = self.add_accessor(payload, item, 34962)
        short = vertex_count <= 65535
        index = self.add_accessor(struct.pack(f"<{len(indices)}{'H' if short else 'I'}", *indices),
            {"type": "SCALAR", "componentType": 5123 if short else 5125, "count": len(indices)}, 34963)
        materials.append({"name": "Packed surface finishes", "doubleSided": True})
        return {"attributes": merged, "indices": index, "material": len(materials) - 1}

    def pack(self):
        reduced = 0
        for mesh in self.doc["meshes"]:
            groups = collections.defaultdict(list)
            separate = []
            for primitive in mesh["primitives"]:
                key = self.finish(primitive)
                if key is None:
                    separate.append(primitive)
                else:
                    groups[key].append(primitive)
            for primitives in groups.values():
                if len(primitives) < 2:
                    separate.extend(primitives)
                    continue
                separate.append(self.merged_surface(primitives))
                reduced += len(primitives) - 1
            mesh["primitives"] = separate
        if reduced:
            self.write()
        return reduced

    def write(self):
        # The models being compacted are static and have no animation/sparse accessors.
        assert "animations" not in self.doc and "skins" not in self.doc
        assert all("sparse" not in accessor for accessor in self.doc["accessors"])
        used = []
        for mesh in self.doc["meshes"]:
            for primitive in mesh["primitives"]:
                used.extend(primitive["attributes"].values())
                used.append(primitive["indices"])
        indices = sorted(set(used))
        remap = {original: new for new, original in enumerate(indices)}
        for mesh in self.doc["meshes"]:
            for primitive in mesh["primitives"]:
                primitive["indices"] = remap[primitive["indices"]]
                primitive["attributes"] = {k: remap[v] for k, v in primitive["attributes"].items()}
        self.doc["accessors"] = [self.doc["accessors"][i] for i in indices]
        references = self.doc["accessors"] + [i for i in self.doc.get("images", []) if "bufferView" in i]
        converted = {}
        binary = bytearray()
        views = []
        for reference in references:
            original = reference["bufferView"]
            if original not in converted:
                binary.extend(b"\0" * (-len(binary) % 4))
                view = self.doc["bufferViews"][original].copy()
                view["byteOffset"] = len(binary)
                binary.extend(self.bytes_of(original))
                converted[original] = len(views)
                views.append(view)
            reference["bufferView"] = converted[original]
        binary.extend(b"\0" * (-len(binary) % 4))
        self.doc["bufferViews"] = views
        self.doc["buffers"] = [{"byteLength": len(binary)}]
        document = json.dumps(self.doc, separators=(",", ":")).encode()
        document += b" " * (-len(document) % 4)
        self.path.write_bytes(struct.pack("<5I", 0x46546C67, 2, 28 + len(document) + len(binary),
            len(document), 0x4E4F534A) + document + struct.pack("<2I", len(binary), 0x004E4942) + binary)


def existing_buildings(root):
    models = root / "assets/models"
    for pattern in ("annex_*.glb", "station_*.glb", "fuel_*.glb", "market*.glb", "workshop*.glb",
                    "restaurant*.glb", "wash*.glb", "motel*.glb", "parking*.glb"):
        yield from (models / "architecture").glob(pattern)
    yield from (models / "desert").glob("*.glb")
    for region in REGIONS:
        yield from (models / "regions").glob(f"{region}_*.glb")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("models", nargs="*", type=Path)
    names = parser.parse_args().models
    count = saved = 0
    for path in sorted(set(names or existing_buildings(Path(__file__).resolve().parents[2]))):
        result = StaticModel(path).pack()
        if result:
            count += 1
            saved += result
    print(f"Packed {count} models, removed {saved} separate surface draws")
