"""Build original game meshes in metres, with +Y up and +Z toward the viewer."""
from dataclasses import dataclass
from math import cos, pi, sin, sqrt, tau
from pathlib import Path

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree


@dataclass
class Part:
    finish: str
    color: tuple
    vertices: list
    faces: list
    smooth: list
    bone: str | None
    vertex_colors: list | None = None


FINISHES = {
    "Ceramic": (0.58, 0.04),
    "Paint": (0.30, 0.24),
    "CoachPaint": (0.28, 0.20),
    "Metal": (0.34, 0.63),
    "Rubber": (0.84, 0.00),
    "Glass": (0.17, 0.06),
    "Tint": (0.22, 0.11),
    "Light": (0.36, 0.00),
}

MATERIALS = {}


def linear(channel):
    return channel / 12.92 if channel < 0.04045 else ((channel + 0.055) / 1.055) ** 2.4


def rgba(hex_color):
    value = hex_color.removeprefix("#")
    if len(value) == 6:
        value += "ff"
    rgb = tuple(int(value[i:i + 2], 16) / 255.0 for i in range(0, 8, 2))
    return (*(linear(channel) for channel in rgb[:3]), rgb[3])


def material(finish):
    if finish in MATERIALS:
        return MATERIALS[finish]
    mat = bpy.data.materials.new(finish)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    shader = nodes.get("Principled BSDF")
    vertex = nodes.new("ShaderNodeVertexColor")
    vertex.layer_name = "Tint"
    mat.node_tree.links.new(vertex.outputs["Color"], shader.inputs["Base Color"])
    shader.inputs["Roughness"].default_value, shader.inputs["Metallic"].default_value = FINISHES[finish]
    if finish == "Glass":
        mat.surface_render_method = "BLENDED"
        shader.inputs["Alpha"].default_value = 0.18
        mat.use_backface_culling = True
    if finish == "Light":
        mat.node_tree.links.new(vertex.outputs["Color"], shader.inputs["Emission Color"])
        shader.inputs["Emission Strength"].default_value = 0.55
    MATERIALS[finish] = mat
    return mat


def orientation(point):
    x, y, z = point
    return (x, -z, y)


def offset(point, centre, yaw):
    x, y, z = point
    c, s = cos(yaw), sin(yaw)
    return (centre[0] + x * c + z * s, centre[1] + y, centre[2] - x * s + z * c)


class Model:
    parts: list[Part]

    def __init__(self):
        self.parts = []

    def add(self, vertices, faces, color, finish="Ceramic", smooth=False, bone=None, vertex_colors=None):
        if isinstance(smooth, bool):
            smooth = [smooth] * len(faces)
        colors = [rgba(tint) for tint in vertex_colors] if vertex_colors else None
        self.parts.append(Part(finish, rgba(color), vertices, faces, smooth, bone, colors))

    def box(self, pos, size, color, radius=0.04, finish="Ceramic", yaw=0.0, bone=None):
        """A rounded rectangle footprint with bevels around the top and bottom."""
        x, y, z = (value / 2 for value in size)
        bevel = min(radius, x * 0.48, y * 0.48, z * 0.48)
        corner = min(max(bevel * 2.0, radius), x * 0.66, z * 0.66)
        if bevel <= 0.0001:
            rim = [(-x, -z), (x, -z), (x, z), (-x, z)]
            vertices = [(a, h, b) for h in (-y, y) for a, b in rim]
            faces = [(0, 1, 2, 3), (7, 6, 5, 4)]
            faces.extend((i, i + 4, (i + 1) % 4 + 4, (i + 1) % 4) for i in range(4))
            self.add([offset(v, pos, yaw) for v in vertices], faces, color, finish, bone=bone)
            return
        layers = [(-y, bevel), (-y + bevel * 0.38, bevel * 0.25),
                  (-y + bevel, 0), (y - bevel, 0), (y - bevel * 0.38, bevel * 0.25), (y, bevel)]
        vertices = []
        for height, inset in layers:
            for i, sign_x, sign_z in ((0, 1, 1), (1, -1, 1), (2, -1, -1), (3, 1, -1)):
                for j in range(3):
                    theta = (i + j / 2.0) * pi / 2.0
                    local = (sign_x * (x - corner) + (corner - inset) * cos(theta),
                             height,
                             sign_z * (z - corner) + (corner - inset) * sin(theta))
                    vertices.append(offset(local, pos, yaw))
        segments = 12
        faces, flags = ring_faces(segments, len(layers), caps=True)
        self.add(vertices, faces, color, finish, flags, bone)

    def custom_box(self, pos, size, color, corner, thickness, finish="Ceramic", yaw=0.0):
        """A thin, broad panel with deeper corner radii than a regular edge bevel."""
        x, y, z = (value / 2 for value in size)
        corner = min(corner, x * 0.95, z * 0.95)
        bevel = min(thickness, corner * 0.5, y * 0.77)
        layers = [(-y, bevel), (-y + bevel, 0), (y - bevel, 0), (y, bevel)]
        vertices = []
        for height, inset in layers:
            for i, sign_x, sign_z in ((0, 1, 1), (1, -1, 1), (2, -1, -1), (3, 1, -1)):
                for j in range(5):
                    theta = (i + j / 4.0) * pi / 2.0
                    vertices.append(offset((sign_x * (x - corner) + (corner - inset) * cos(theta),
                                            height,
                                            sign_z * (z - corner) + (corner - inset) * sin(theta)),
                                           pos, yaw))
        faces, flags = ring_faces(20, len(layers), caps=True)
        self.add(vertices, faces, color, finish, flags)

    def orb(self, pos, size, color, segments=12, rings=8, finish="Ceramic", bone=None,
            yaw=0.0, irregular=0.0):
        """Ellipsoid with optional coherent lobes for stone, foliage and hair."""
        vertices = []
        for row in range(1, rings):
            elevation = -pi / 2 + pi * row / rings
            for j in range(segments):
                azimuth = tau * j / segments
                swell = 1 + irregular * (0.5 * sin(azimuth * 3 + row)
                                          + 0.35 * cos(azimuth * 5 - row * 2))
                vertices.append(offset((size[0] * cos(azimuth) * cos(elevation) * swell,
                                        size[1] * sin(elevation),
                                        size[2] * sin(azimuth) * cos(elevation) * swell), pos, yaw))
        faces, _ = ring_faces(segments, rings - 1)
        bottom, top = len(vertices), len(vertices) + 1
        vertices.extend([(pos[0], pos[1] - size[1], pos[2]), (pos[0], pos[1] + size[1], pos[2])])
        for i in range(segments):
            j = (i + 1) % segments
            faces.append((i, j, bottom))
            faces.append((top - segments - 1 + j, top - segments - 1 + i, top))
        self.add(vertices, faces, color, finish, True, bone)

    def pipe(self, path, radius, color, finish="Ceramic", sides=10, bone=None):
        positions = [Vector(pos) for pos in path]
        guide = (positions[-1] - positions[0]).normalized()
        reference = Vector((1, 0, 0)) if abs(guide.x) < 0.85 else Vector((0, 1, 0))
        vertices = []
        for i, pos in enumerate(positions):
            direction = (positions[min(len(positions) - 1, i + 1)] - positions[max(0, i - 1)]).normalized()
            if abs(direction.dot(reference)) > 0.96:
                reference = Vector((0, 0, 1))
            first = direction.cross(reference).normalized()
            second = first.cross(direction).normalized()
            width = radius[i] if isinstance(radius, (tuple, list)) else radius
            for j in range(sides):
                t = j * tau / sides
                vertices.append(tuple(pos + (first * cos(t) + second * sin(t)) * width))
        faces, flags = ring_faces(sides, len(positions), caps=True)
        self.add(vertices, faces, color, finish, flags, bone)

    def mesh(self, name, armature=None):
        vertices, faces, colors, materials, indices, smooth, bones = [], [], [], [], [], [], []
        for part in self.parts:
            base = len(vertices)
            vertices.extend(orientation(point) for point in part.vertices)
            faces.extend(tuple(base + index for index in face) for face in part.faces)
            colors.extend(part.vertex_colors or [part.color] * len(part.vertices))
            if part.finish not in materials:
                materials.append(part.finish)
            indices.extend([materials.index(part.finish)] * len(part.faces))
            smooth.extend(part.smooth)
            bones.append((part.bone, base, len(part.vertices)))
        geometry = bpy.data.meshes.new(name)
        geometry.from_pydata(vertices, [], faces)
        geometry.update()
        tint = geometry.color_attributes.new(name="Tint", type="FLOAT_COLOR", domain="POINT")
        tint.data.foreach_set("color", [value for color in colors for value in color])
        for finish in materials:
            geometry.materials.append(material(finish))
        for face, index, is_smooth in zip(geometry.polygons, indices, smooth):
            face.material_index = index
            face.use_smooth = is_smooth
        obj = bpy.data.objects.new(name, geometry)
        bpy.context.collection.objects.link(obj)
        if armature:
            obj.parent = armature
            groups = {bone.name: obj.vertex_groups.new(name=bone.name) for bone in armature.data.bones}
            for bone, base, length in bones:
                groups[bone].add(list(range(base, base + length)), 1.0, "REPLACE")
            modifier = obj.modifiers.new(name="Deform", type="ARMATURE")
            modifier.object = armature
        return obj


def ring_faces(segments, count, caps=False):
    faces = []
    for layer in range(count - 1):
        for i in range(segments):
            a = layer * segments + i
            b = layer * segments + (i + 1) % segments
            faces.append((a, a + segments, b + segments, b))
    smooth = [True] * len(faces)
    if caps:
        faces.extend([tuple(range(segments)), tuple(reversed(range((count - 1) * segments, count * segments)))])
        smooth.extend([False, False])
    return faces, smooth


def clear_objects():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for mesh in list(bpy.data.meshes):
        if mesh.users == 0:
            bpy.data.meshes.remove(mesh)


def bake_occlusion(obj, radius=0.95, strength=0.42):
    """Bake short-range hemisphere occlusion into the palette carried by the GLB."""
    mesh = obj.data
    positions = [vertex.co.copy() for vertex in mesh.vertices]
    polygons = [tuple(face.vertices) for face in mesh.polygons
                if mesh.materials[face.material_index].name not in ("Glass", "Light")]
    if not polygons:
        return
    bvh = BVHTree.FromPolygons(positions, polygons)
    colors = mesh.color_attributes["Tint"].data
    samples = 8
    golden_angle = pi * (3 - sqrt(5))
    for vertex in mesh.vertices:
        normal = vertex.normal
        if normal.length_squared < 0.5:
            continue
        tangent = normal.cross(Vector((0, 0, 1)) if abs(normal.z) < 0.88 else Vector((1, 0, 0))).normalized()
        bitangent = normal.cross(tangent)
        origin = vertex.co + normal * 0.014
        blocked = 0.0
        for index in range(samples):
            cone = (index + 0.5) / samples
            azimuth = index * golden_angle
            ray = normal * sqrt(1 - cone) + sqrt(cone) * (tangent * cos(azimuth) + bitangent * sin(azimuth))
            _, _, _, distance = bvh.ray_cast(origin, ray, radius)
            if distance is not None and distance > 0.003:
                blocked += (1 - distance / radius) ** 0.75
        if blocked > 0.0:
            shade = 1 - strength * blocked / samples
            r, g, b, a = colors[vertex.index].color
            colors[vertex.index].color = (r * shade, g * shade, b * shade, a)


def export(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(path), export_format="GLB", export_texcoords=False,
        export_vertex_color="MATERIAL", export_normals=True, export_animations=False,
        export_cameras=False, export_lights=False,
    )


def output_root():
    return Path(__file__).resolve().parents[2]
