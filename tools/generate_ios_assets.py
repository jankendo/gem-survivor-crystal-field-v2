from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "ios"


def make_icon() -> None:
    size = 1024
    image = Image.new("RGB", (size, size), (5, 10, 28))
    draw = ImageDraw.Draw(image)
    for radius, color in [
        (410, (13, 40, 78)),
        (340, (20, 66, 105)),
        (270, (22, 104, 136)),
    ]:
        box = (size // 2 - radius, size // 2 - radius, size // 2 + radius, size // 2 + radius)
        draw.ellipse(box, fill=color)

    crystal = [
        (512, 150),
        (758, 410),
        (650, 790),
        (512, 900),
        (374, 790),
        (266, 410),
    ]
    draw.polygon(crystal, fill=(62, 225, 255), outline=(220, 252, 255))
    draw.polygon([(512, 150), (512, 900), (266, 410)], fill=(66, 150, 245))
    draw.polygon([(512, 150), (758, 410), (512, 900)], fill=(88, 240, 218))
    draw.polygon([(266, 410), (758, 410), (512, 900)], outline=(230, 255, 255), width=12)
    draw.ellipse((438, 410, 586, 558), fill=(255, 213, 71), outline=(255, 250, 210), width=10)
    draw.ellipse((481, 453, 543, 515), fill=(255, 255, 255))
    image.save(OUT / "app_icon_1024.png", optimize=True)


def make_launch() -> None:
    width, height = 2732, 2048
    image = Image.new("RGB", (width, height), (5, 9, 24))
    glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    center = (width // 2, height // 2)
    for radius, alpha in [(720, 24), (540, 36), (360, 54)]:
        box = (center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius)
        draw.ellipse(box, fill=(30, 190, 255, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(80))
    image = Image.alpha_composite(image.convert("RGBA"), glow)
    icon = Image.open(OUT / "app_icon_1024.png").resize((640, 640), Image.Resampling.LANCZOS)
    image.alpha_composite(icon.convert("RGBA"), (center[0] - 320, center[1] - 360))
    image.convert("RGB").save(OUT / "launch_landscape.png", optimize=True)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    make_icon()
    make_launch()
    print(f"Generated iOS assets in {OUT}")


if __name__ == "__main__":
    main()
