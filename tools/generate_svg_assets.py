from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets" / "sprites"


def write_svg(name: str, body: str, size: int = 64) -> None:
    SPRITES.mkdir(parents=True, exist_ok=True)
    (SPRITES / name).write_text(
        f"""<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">
  <rect width="{size}" height="{size}" rx="10" fill="#0b1020"/>
  {body}
</svg>
""",
        encoding="utf-8",
    )


def icon_block_cannon() -> str:
    return """
  <circle cx="32" cy="32" r="25" fill="#f05a28"/>
  <rect x="25" y="15" width="14" height="32" rx="4" fill="#321006"/>
  <rect x="31" y="7" width="18" height="12" rx="3" transform="rotate(22 31 7)" fill="#ffb247"/>
  <circle cx="32" cy="36" r="9" fill="#ffd46b"/>
"""


def icon_block_frost() -> str:
    return """
  <circle cx="32" cy="32" r="25" fill="#1d79d9"/>
  <g stroke="#bff1ff" stroke-width="4" stroke-linecap="round">
    <path d="M32 12v40"/>
    <path d="M14 22l36 20"/>
    <path d="M50 22L14 42"/>
    <path d="M24 17l8 8 8-8"/>
    <path d="M24 47l8-8 8 8"/>
  </g>
"""


def icon_block_reactor() -> str:
    return """
  <circle cx="32" cy="32" r="25" fill="#69b832"/>
  <circle cx="32" cy="32" r="15" fill="#f7f06d"/>
  <circle cx="32" cy="32" r="7" fill="#14220a"/>
  <g stroke="#d9ff86" stroke-width="3">
    <path d="M32 5v11"/>
    <path d="M32 48v11"/>
    <path d="M5 32h11"/>
    <path d="M48 32h11"/>
  </g>
"""


def icon_block_wall() -> str:
    return """
  <rect x="10" y="13" width="44" height="38" rx="5" fill="#87909c"/>
  <g fill="#59616d">
    <rect x="13" y="16" width="16" height="9"/>
    <rect x="31" y="16" width="20" height="9"/>
    <rect x="13" y="28" width="21" height="9"/>
    <rect x="36" y="28" width="15" height="9"/>
    <rect x="13" y="40" width="14" height="8"/>
    <rect x="29" y="40" width="22" height="8"/>
  </g>
"""


def enemy_crawler() -> str:
    return """
  <circle cx="32" cy="35" r="22" fill="#b86cff"/>
  <circle cx="25" cy="29" r="4" fill="#12051e"/>
  <circle cx="39" cy="29" r="4" fill="#12051e"/>
  <path d="M19 45c8 6 18 6 26 0" stroke="#12051e" stroke-width="4" fill="none" stroke-linecap="round"/>
"""


def enemy_runner() -> str:
    return """
  <path d="M17 10l31 19-31 25 8-22z" fill="#ffcf4d"/>
  <path d="M10 20h18M8 32h15M10 44h13" stroke="#fff3a6" stroke-width="4" stroke-linecap="round"/>
  <circle cx="38" cy="30" r="4" fill="#1c1300"/>
"""


def enemy_tank() -> str:
    return """
  <rect x="10" y="18" width="44" height="34" rx="12" fill="#ff7048"/>
  <rect x="18" y="11" width="28" height="16" rx="6" fill="#a93622"/>
  <circle cx="24" cy="35" r="5" fill="#1c0905"/>
  <circle cx="40" cy="35" r="5" fill="#1c0905"/>
"""


def enemy_jammer() -> str:
    return """
  <circle cx="32" cy="32" r="22" fill="#52e0d1"/>
  <path d="M17 23h12l-8 11h13l-9 14" stroke="#062a2a" stroke-width="5" fill="none" stroke-linejoin="round"/>
  <path d="M43 15c6 5 8 12 5 20M49 10c10 8 13 21 7 33" stroke="#bffff9" stroke-width="3" fill="none"/>
"""


def enemy_chrono_eater() -> str:
    return """
  <circle cx="32" cy="32" r="25" fill="#e8edf8"/>
  <circle cx="32" cy="32" r="16" fill="#111827"/>
  <circle cx="26" cy="28" r="4" fill="#f05a28"/>
  <circle cx="38" cy="28" r="4" fill="#45b7ff"/>
  <path d="M23 40c5 6 13 6 18 0" stroke="#e8edf8" stroke-width="4" fill="none"/>
  <path d="M32 12v9l8 4" stroke="#111827" stroke-width="4" stroke-linecap="round"/>
"""


def simple_ui_icon(color: str, glyph: str) -> str:
    return f"""
  <circle cx="32" cy="32" r="25" fill="{color}"/>
  <text x="32" y="41" text-anchor="middle" font-family="Arial, sans-serif" font-size="26" font-weight="700" fill="#07111c">{glyph}</text>
"""


def board_asset(fill: str, stroke: str = "#334155") -> str:
    return f"""
  <rect x="8" y="8" width="48" height="48" rx="7" fill="{fill}" stroke="{stroke}" stroke-width="3"/>
"""


def title_logo() -> str:
    return """
  <defs>
    <linearGradient id="g" x1="0" x2="1">
      <stop offset="0" stop-color="#f05a28"/>
      <stop offset="0.52" stop-color="#45b7ff"/>
      <stop offset="1" stop-color="#9ee24f"/>
    </linearGradient>
  </defs>
  <rect x="4" y="9" width="56" height="46" rx="12" fill="url(#g)"/>
  <circle cx="32" cy="32" r="16" fill="#0b1020"/>
  <path d="M32 18v14l10 7" stroke="#f7f06d" stroke-width="5" stroke-linecap="round" fill="none"/>
"""


def main() -> None:
    assets = {
        "block_cannon.svg": icon_block_cannon(),
        "block_frost.svg": icon_block_frost(),
        "block_reactor.svg": icon_block_reactor(),
        "block_wall.svg": icon_block_wall(),
        "enemy_crawler.svg": enemy_crawler(),
        "enemy_runner.svg": enemy_runner(),
        "enemy_tank.svg": enemy_tank(),
        "enemy_jammer.svg": enemy_jammer(),
        "enemy_chrono_eater.svg": enemy_chrono_eater(),
        "icon_hp.svg": simple_ui_icon("#ff5a5f", "HP"),
        "icon_score.svg": simple_ui_icon("#ffcf4d", "S"),
        "icon_wave.svg": simple_ui_icon("#45b7ff", "W"),
        "icon_energy.svg": simple_ui_icon("#9ee24f", "E"),
        "icon_sync.svg": simple_ui_icon("#d889ff", "Y"),
        "icon_timer.svg": simple_ui_icon("#d6e1ff", "T"),
        "board_cell.svg": board_asset("#1b2430"),
        "board_cell_hover.svg": board_asset("#2f3b4c", "#f8c43a"),
        "board_cell_danger.svg": board_asset("#3a1820", "#f05a28"),
        "grid_frame.svg": board_asset("#0f172a", "#6aa8ff"),
        "title_logo.svg": title_logo(),
    }
    for name, body in assets.items():
        write_svg(name, body)
    print(f"generated {len(assets)} SVG assets in {SPRITES}")


if __name__ == "__main__":
    main()
