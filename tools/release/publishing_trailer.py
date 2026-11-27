"""Edit the four marked Godot Movie Maker shots without stretching the gameplay."""

from argparse import ArgumentParser
import io
import json
from pathlib import Path
from subprocess import check_output, run
from tempfile import TemporaryDirectory

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

from publishing_art import FONT, LOGO, RESAMPLE, ROOT


DISPLAY = (1920, 1080)
PICTURE = (540, 960)
POSITION = (1135, 60)
FPS = 24
COPY = {
    "station": ("Start with one\ngas station", "Build your roadside business from the ground up."),
    "services": ("Build a service\ncomplex", "Open a car wash, workshop and more."),
    "copper-mile": ("On to\nCopper Mile", "Grow your network on Desert Highway."),
    "riverbend": ("Expand into\nGreen Valley", "Discover 12 playable regions."),
}


def command(*args):
    run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *map(str, args)], check=True)


def movie_frame(source, index):
    pixels = check_output(["ffmpeg", "-v", "error", "-ss", f"{index / FPS:.6f}", "-i", str(source),
                           "-frames:v", "1", "-f", "image2pipe", "-vcodec", "png", "-"])
    return Image.open(io.BytesIO(pixels)).convert("RGB")


def card(scene, frame):
    image = ImageOps.fit(frame, DISPLAY, RESAMPLE, centering=(.5, .32)).filter(ImageFilter.GaussianBlur(34))
    image = Image.blend(image, Image.new("RGB", DISPLAY, "#132934"), .83).convert("RGBA")
    draw = ImageDraw.Draw(image)
    x, y = POSITION
    w, h = PICTURE
    draw.rounded_rectangle((x - 19, y - 13, x + w + 19, y + h + 20), radius=32, fill="#101e29")
    draw.rounded_rectangle((x - 5, y - 5, x + w + 4, y + h + 4),
                           radius=12, fill="#f2c87c")
    wordmark = Image.open(LOGO).convert("RGBA")
    wordmark.thumbnail((640, 187), RESAMPLE)
    image.alpha_composite(wordmark, (108, 138))
    title, detail = COPY[scene]
    draw.multiline_text((120, 401), title, fill="#fff0cc", font=ImageFont.truetype(FONT, 90), spacing=4)
    draw.rounded_rectangle((121, 683, 280, 690), radius=3, fill="#e7b56b")
    draw.text((120, 732), detail, fill="#e8e3cf",
              font=ImageFont.truetype(ROOT / "assets/fonts/OpenSans-Bold.ttf", 31))
    return image


def compose(raw, output):
    cuts = json.loads((raw / "cuts.json").read_text())
    source = raw / "game.avi"
    output.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory(prefix="hbt-publishing-video-") as name:
        temp = Path(name)
        segments = []
        for index, shot in enumerate(cuts):
            scene = shot["scene"]
            first = shot["frame"]
            count = shot["length"]
            frame = movie_frame(source, first + count // 2)
            shot_card = card(scene, frame)
            background_path = temp / f"{scene}.png"
            shot_card.save(background_path)
            if index == 0:
                shot_card.paste(frame.resize(PICTURE, RESAMPLE), POSITION)
                shot_card.convert("RGB").resize((1280, 720), RESAMPLE).save(
                    output / "thumbnail_1280x720.jpg", quality=94, optimize=True)
            clip = temp / f"{scene}.mp4"
            fade_in = 8 if index == 0 else 4
            fade_out = 12 if index == len(cuts) - 1 else 4
            command("-filter_complex_threads", 2, "-ss", f"{first / FPS:.6f}", "-i", source,
                    "-loop", 1, "-framerate", FPS, "-i", background_path,
                    "-filter_complex",
                    f"[0:v]scale={PICTURE[0]}:{PICTURE[1]}:flags=lanczos,setsar=1[game];"
                    f"[1:v][game]overlay={POSITION[0]}:{POSITION[1]}:shortest=1,"
                    f"fade=in:s=0:n={fade_in}:color=0x132934,"
                    f"fade=out:s={count - fade_out}:n={fade_out}:color=0x132934[out]",
                    "-map", "[out]", "-frames:v", count, "-an", "-c:v", "libx264", "-threads", 3,
                    "-preset", "fast", "-crf", 19, "-pix_fmt", "yuv420p", clip)
            segments.append(f"file '{clip.name}'\n")
        playlist = temp / "clips.txt"
        playlist.write_text("".join(segments))
        duration = sum(shot["length"] for shot in cuts) / FPS
        command("-f", "concat", "-safe", 1, "-i", playlist, "-stream_loop", -1, "-i",
                ROOT / "assets/audio/music_day.ogg", "-map", "0:v", "-map", "1:a", "-c:v", "copy",
                "-c:a", "aac", "-b:a", "160k", "-af",
                f"volume=0.85,afade=t=in:d=0.25,afade=t=out:st={duration - 1.5}:d=1.5",
                "-t", duration, "-movflags", "+faststart", output / "trailer_1920x1080.mp4")


def main():
    args = ArgumentParser(description=__doc__)
    args.add_argument("raw", type=Path)
    args.add_argument("output", type=Path)
    options = args.parse_args()
    compose(options.raw, options.output)


if __name__ == "__main__":
    main()
