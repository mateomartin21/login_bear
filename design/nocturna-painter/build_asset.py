"""Export this RML scene to the Rive 7 subset used by Flutter's Rive runtime."""

from pathlib import Path
import struct
import xml.etree.ElementTree as ET


def uint(value):
    value = int(value)
    if value < 0:
        raise ValueError(f"Expected unsigned integer: {value}")
    result = bytearray()
    while value >= 128:
        result.append((value & 127) | 128)
        value >>= 7
    result.append(value)
    return bytes(result)


def string(value):
    data = value.encode("utf-8")
    return uint(len(data)) + data


def real(value):
    return struct.pack("<f", float(value))


def color(value):
    return struct.pack("<I", int(value, 16))


def field(key, value, encode=uint):
    return uint(key) + encode(value)


def record(kind, *fields):
    return uint(kind) + b"".join(fields) + b"\0"


def optional(node, mappings):
    return [field(key, node.attrib[name], encode)
            for name, key, encode in mappings if name in node.attrib]


COMPONENTS = {"Node": 2, "Shape": 3, "Ellipse": 4, "Rectangle": 7,
              "SolidColor": 18, "Fill": 20, "Event": 128, "PointsPath": 16,
              "StraightVertex": 5, "CubicDetachedVertex": 6}
TRANSFORMS = [("x", 13, real), ("y", 14, real), ("rotation", 15, real),
              ("opacity", 18, real), ("width", 20, real), ("height", 21, real),
              ("cornerRadiusTL", 31, real), ("colorValue", 37, color)]
ANIMATED = {"x": 13, "y": 14, "rotation": 15, "opacity": 18, "scaleY": 17, "trigger": 395}
STATES = {"AnimationState": 61, "AnyState": 62, "EntryState": 63,
          "ExitState": 64, "BlendState1DInput": 76}
INPUTS = {"StateMachineNumber": 56, "StateMachineTrigger": 58, "StateMachineBool": 59}


def compile_scene(root):
    artboard = root.find("Artboard")
    components = []
    component_ids = {}
    vertices = set()

    def visit(node, parent_id):
        index = len(components) + 1
        if "id" in node.attrib:
            component_ids[node.attrib["id"]] = index
        mappings = TRANSFORMS
        if node.tag == "StraightVertex":
            mappings = [("x", 24, real), ("y", 25, real), ("radius", 26, real)]
        if node.tag == "CubicDetachedVertex":
            mappings = [("x", 24, real), ("y", 25, real), ("inRotation", 84, real),
                        ("inDistance", 85, real), ("outRotation", 86, real),
                        ("outDistance", 87, real)]
            if "id" in node.attrib:
                vertices.add(node.attrib["id"])
        if node.tag == "PointsPath":
            mappings = [("isClosed", 32, lambda value: uint(value == "true"))]
        components.append(record(COMPONENTS[node.tag], field(5, parent_id),
                                 *optional(node, [("name", 4, string), *mappings])))
        for child in node:
            visit(child, index)

    for visual in (node for node in artboard if node.tag in COMPONENTS):
        visit(visual, 0)

    # The editor nests easing under its owner. Rive 7 references an artboard object.
    curve_ids = {}
    curves = {}
    for curve in artboard.iter("CubicEaseInterpolator"):
        points = tuple(float(curve.attrib[key]) for key in ("x1", "y1", "x2", "y2"))
        if points not in curve_ids:
            curve_ids[points] = len(components) + 1
            components.append(record(28, *(field(63 + i, point, real)
                                          for i, point in enumerate(points))))
        curves[curve] = curve_ids[points]

    def easing(owner, type_key, id_key):
        curve = owner.find("CubicEaseInterpolator")
        return (field(type_key, 2) + field(id_key, curves[curve])
                if curve is not None else field(type_key, 1))

    animations = artboard.findall("LinearAnimation")
    animation_ids = {node.attrib["id"]: index for index, node in enumerate(animations)}
    output = bytearray(b"RIVE\x07\x00\x00\x00")
    output += record(23)
    output += record(1, field(4, artboard.attrib["name"], string),
                     field(7, artboard.attrib["width"], real),
                     field(8, artboard.attrib["height"], real), field(236, len(animations)))
    output += b"".join(components)
    for animation in animations:
        output += record(31, *optional(animation, [("name", 55, string),
                         ("duration", 57, uint), ("loopValue", 59, uint)]))
        properties = {}
        for keyed in animation:
            properties.setdefault(keyed.attrib["objectId"], []).extend(keyed)
        for object_id, tracks in properties.items():
            output += record(25, field(51, component_ids[object_id]))
            for prop in tracks:
                keys = {"x": 24, "y": 25} if object_id in vertices else ANIMATED
                output += record(26, field(53, keys[prop.attrib["property"]]))
                for frame in prop:
                    time = field(67, frame.attrib["frame"])
                    if frame.tag == "KeyFrameCallback":
                        output += record(171, time)
                    else:
                        output += record(30, time, easing(frame, 68, 69),
                                         field(70, frame.attrib["value"], real))

    machine = artboard.find("StateMachine")
    output += record(53, field(55, machine.attrib["name"], string))
    inputs = [node for node in machine if node.tag in INPUTS]
    input_ids = {node.attrib["id"]: index for index, node in enumerate(inputs)}
    for node in inputs:
        output += record(INPUTS[node.tag], field(138, node.attrib["name"], string),
                         *optional(node, [("value", 140, real)]))
    for layer in machine.findall("StateMachineLayer"):
        output += record(57, field(138, layer.attrib["name"], string))
        state_ids = {state.attrib["id"]: index for index, state in enumerate(layer)
                     if "id" in state.attrib}
        for state in layer:
            attrs = state.attrib
            fields = []
            if "animationId" in attrs:
                fields.append(field(149, animation_ids[attrs["animationId"]]))
            if "inputId" in attrs:
                fields.append(field(167, input_ids[attrs["inputId"]]))
            if attrs.get("reset") == "true":
                fields.append(field(536, 2))
            output += record(STATES[state.tag], *fields)
            for child in state:
                attrs = child.attrib
                if child.tag == "BlendAnimation1D":
                    output += record(75, field(165, animation_ids[attrs["animationId"]]),
                                     field(166, attrs["value"], real))
                    continue
                flags = sum(bit for name, bit in [("enableExitTime", 4),
                            ("exitTimeIsPercetange", 8), ("enableEarlyExit", 32)]
                            if attrs.get(name) == "true")
                blend = easing(child, 349, 350) if child.find("CubicEaseInterpolator") is not None else b""
                output += record(65, field(151, state_ids[attrs["stateToId"]]), blend,
                                 field(152, flags), *optional(child, [
                                     ("duration", 158, uint), ("exitTime", 160, uint)]))
                for cond in child:
                    if cond.tag == "CubicEaseInterpolator":
                        continue
                    input_id = field(155, input_ids[cond.attrib["inputId"]])
                    if cond.tag == "TransitionTriggerCondition":
                        output += record(68, input_id)
                    else:
                        output += record(71, input_id, field(156,
                                         int(cond.get("opValue") == "notEqual")))
    return output


if __name__ == "__main__":
    source = Path(__file__).resolve().parent
    root = ET.parse(source / "scene.rml").getroot()
    (source.parents[1] / "assets" / "nocturna-painter.riv").write_bytes(compile_scene(root))
