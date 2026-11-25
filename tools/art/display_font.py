"""Build Route 17's original beveled counter numerals as a small TrueType font."""
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen


SEGMENTS = {
    "a": [(114, 718), (469, 718), (526, 666), (470, 592), (113, 592), (54, 656)],
    "b": [(476, 582), (546, 640), (583, 597), (583, 401), (530, 351), (469, 419)],
    "c": [(470, 273), (530, 337), (583, 285), (583, 91), (543, 47), (476, 103)],
    "d": [(112, 99), (468, 99), (527, 32), (472, -20), (113, -20), (54, 39)],
    "e": [(55, 337), (119, 273), (114, 104), (50, 49), (15, 93), (15, 290)],
    "f": [(50, 639), (117, 584), (121, 420), (55, 351), (15, 405), (15, 588)],
    "g": [(118, 406), (467, 406), (515, 345), (465, 284), (118, 284), (71, 347)],
}
DIGITS = ["abcdef", "bc", "abdeg", "abcdg", "bcfg", "acdfg", "acdefg", "abc", "abcdefg", "abcdfg"]


def glyph(contours):
    pen = TTGlyphPen(None)
    for contour in contours:
        pen.moveTo(contour[0])
        for point in contour[1:]:
            pen.lineTo(point)
        pen.closePath()
    return pen.glyph()


def main():
    dot = [(73, 119), (145, 119), (168, 96), (168, 21), (144, 0), (73, 0), (49, 24), (49, 94)]
    contours = {str(i): [SEGMENTS[segment] for segment in segments] for i, segments in enumerate(DIGITS)}
    contours.update({".": [dot], ",": [dot, [(70, 17), (139, 17), (133, -29), (76, -101), (28, -101)]],
                     "-": [[(44, 391), (390, 391), (428, 345), (387, 296), (43, 296), (9, 344)]],
                     " ": []})
    names = {char: f"uni{ord(char):04X}" for char in contours}
    shapes = {names[char]: glyph(points) for char, points in contours.items()}
    shapes[".notdef"] = glyph([])
    advances = {names[char]: (654 if char.isdigit() else 465 if char == "-" else 223, 0) for char in contours}
    advances[".notdef"] = (640, 0)
    font = FontBuilder(1000, isTTF=True)
    font.setupGlyphOrder([".notdef", *names.values()])
    font.setupCharacterMap({ord(char): name for char, name in names.items()})
    font.setupGlyf(shapes)
    font.setupHorizontalMetrics(advances)
    font.setupHorizontalHeader(ascent=825, descent=-175)
    font.setupNameTable({"familyName": "Route 17 Counter", "styleName": "Display", "uniqueFontIdentifier": "Route17Counter32",
                         "fullName": "Route 17 Counter Display", "psName": "Route17Counter-Display"})
    font.setupOS2(sTypoAscender=825, sTypoDescender=-175, usWinAscent=825, usWinDescent=175, sCapHeight=718)
    font.setupPost()
    font.save(Path(__file__).resolve().parents[2] / "assets/fonts/Route17Counter.ttf")


if __name__ == "__main__":
    main()
