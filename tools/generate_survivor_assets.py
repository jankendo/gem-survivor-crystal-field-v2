from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "survivor"


def write_svg(name: str, body: str, size: int = 128) -> None:
    target = OUT / name
    target.parent.mkdir(parents=True, exist_ok=True)
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">
<defs>
  <radialGradient id="glow" cx="50%" cy="50%" r="55%">
    <stop offset="0%" stop-color="#ffffff" stop-opacity="0.95"/>
    <stop offset="45%" stop-color="#6ee7ff" stop-opacity="0.55"/>
    <stop offset="100%" stop-color="#7c3cff" stop-opacity="0.0"/>
  </radialGradient>
  <linearGradient id="metal" x1="0%" y1="0%" x2="100%" y2="100%">
    <stop offset="0%" stop-color="#e6fbff"/>
    <stop offset="48%" stop-color="#4aa3ff"/>
    <stop offset="100%" stop-color="#20123f"/>
  </linearGradient>
</defs>
<rect width="{size}" height="{size}" fill="none"/>
{body}
</svg>
'''
    target.write_text(svg, encoding="utf-8")


def core(name: str, color: str, accent: str) -> None:
    write_svg(
        name,
        f'''
<circle cx="64" cy="64" r="48" fill="url(#glow)"/>
<path d="M64 10 L96 34 L108 74 L82 112 L46 112 L20 74 L32 34 Z" fill="{color}" stroke="{accent}" stroke-width="5"/>
<circle cx="64" cy="64" r="22" fill="#10172f" stroke="#fff4a3" stroke-width="5"/>
<circle cx="64" cy="64" r="10" fill="{accent}"/>
''',
    )


def enemy(name: str, color: str, shape: str) -> None:
    write_svg(
        name,
        f'''
<circle cx="64" cy="64" r="54" fill="{color}" opacity="0.18"/>
{shape}
<circle cx="50" cy="56" r="5" fill="#08111f"/>
<circle cx="78" cy="56" r="5" fill="#08111f"/>
''',
    )


def weapon(name: str, color: str, shape: str) -> None:
    write_svg(
        name,
        f'''
<circle cx="64" cy="64" r="52" fill="{color}" opacity="0.16"/>
{shape}
''',
    )


def character(name: str, primary: str, accent: str, silhouette: str, prop: str = "") -> None:
    write_svg(
        f"characters/{name}.svg",
        f'''
<circle cx="64" cy="64" r="56" fill="{accent}" opacity="0.12"/>
<path d="{silhouette}" fill="{primary}" stroke="{accent}" stroke-width="5"/>
<circle cx="64" cy="48" r="18" fill="#10172f" stroke="#eaf8ff" stroke-width="4"/>
<circle cx="57" cy="46" r="3" fill="{accent}"/>
<circle cx="71" cy="46" r="3" fill="{accent}"/>
{prop}
<path d="M42 92 Q64 108 86 92" stroke="#ffffff" stroke-width="4" fill="none" opacity="0.55"/>
''',
    )


def locked_character(name: str, accent: str) -> None:
    write_svg(
        f"characters/{name}_locked.svg",
        f'''
<rect x="0" y="0" width="128" height="128" fill="#07040f"/>
<circle cx="64" cy="64" r="54" fill="{accent}" opacity="0.14"/>
<path d="M64 14 C92 24 104 54 94 104 H34 C24 54 36 24 64 14 Z" fill="#080812" stroke="{accent}" stroke-width="5"/>
<circle cx="55" cy="54" r="5" fill="{accent}"/>
<circle cx="73" cy="54" r="5" fill="{accent}"/>
<path d="M22 100 C48 86 78 114 108 92" stroke="{accent}" stroke-width="3" fill="none" opacity="0.65"/>
''',
    )


def passive_icon(name: str, color: str, glyph: str) -> None:
    write_svg(
        f"passives/passive_{name}.svg",
        f'''
<rect x="10" y="10" width="108" height="108" rx="22" fill="#071126" stroke="{color}" stroke-width="6"/>
<circle cx="64" cy="64" r="38" fill="{color}" opacity="0.20"/>
{glyph}
''',
    )


def ui_asset(name: str, color: str, body: str) -> None:
    write_svg(
        f"ui/{name}.svg",
        f'''
<rect x="8" y="8" width="112" height="112" rx="14" fill="#071126" stroke="{color}" stroke-width="5"/>
{body}
''',
    )


def effect_asset(name: str, color: str, body: str) -> None:
    write_svg(
        f"effects/{name}.svg",
        f'''
<circle cx="64" cy="64" r="56" fill="{color}" opacity="0.10"/>
{body}
''',
    )


def drop_asset(name: str, color: str, glyph: str) -> None:
    write_svg(
        f"drops/{name}.svg",
        f'''
<circle cx="64" cy="64" r="54" fill="{color}" opacity="0.16"/>
<path d="M64 12 L104 48 L88 110 H40 L24 48 Z" fill="#071126" stroke="{color}" stroke-width="6"/>
{glyph}
''',
    )


def gimmick_asset(name: str, color: str, glyph: str) -> None:
    write_svg(
        f"gimmicks/{name}.svg",
        f'''
<rect x="8" y="8" width="112" height="112" rx="18" fill="#071126" stroke="{color}" stroke-width="5"/>
<circle cx="64" cy="64" r="44" fill="{color}" opacity="0.14"/>
{glyph}
''',
    )


def synergy_asset(name: str, color: str, glyph: str) -> None:
    write_svg(
        f"synergies/{name}.svg",
        f'''
<path d="M64 10 L112 38 V90 L64 118 L16 90 V38 Z" fill="#071126" stroke="{color}" stroke-width="5"/>
{glyph}
''',
    )


def field(name: str, c1: str, c2: str) -> None:
    write_svg(
        name,
        f'''
<rect x="0" y="0" width="128" height="128" fill="{c1}"/>
<path d="M0 24 H128 M0 64 H128 M0 104 H128 M24 0 V128 M64 0 V128 M104 0 V128" stroke="{c2}" stroke-width="2" opacity="0.34"/>
<circle cx="32" cy="34" r="4" fill="{c2}" opacity="0.55"/>
<circle cx="92" cy="78" r="5" fill="{c2}" opacity="0.45"/>
<path d="M16 112 L44 92 L70 112 L104 86" stroke="{c2}" stroke-width="3" opacity="0.28" fill="none"/>
''',
    )


def main() -> None:
    core("player_core.svg", "#234a85", "#ffe56d")
    core("player_core_hit.svg", "#82243a", "#ff4c4c")

    enemy("enemy_slime.svg", "#52f27d", '<ellipse cx="64" cy="72" rx="44" ry="34" fill="#52f27d" stroke="#d8ffe1" stroke-width="4"/>')
    enemy("enemy_bat.svg", "#df61ff", '<path d="M14 70 L42 34 L64 62 L86 34 L114 70 L82 84 L64 72 L46 84 Z" fill="#df61ff" stroke="#f6d4ff" stroke-width="4"/>')
    enemy("enemy_golem.svg", "#bd8866", '<rect x="28" y="24" width="72" height="80" rx="10" fill="#bd8866" stroke="#ffe0b8" stroke-width="5"/>')
    enemy("enemy_ghost.svg", "#9acfff", '<path d="M30 92 V48 C30 22 98 22 98 48 V92 L82 80 L66 94 L50 80 Z" fill="#9acfff" stroke="#eff9ff" stroke-width="4" opacity="0.86"/>')
    enemy("enemy_elite.svg", "#ffad32", '<path d="M64 14 L104 42 L96 100 L64 116 L32 100 L24 42 Z" fill="#ffad32" stroke="#fff09b" stroke-width="5"/>')
    enemy("enemy_splitter.svg", "#65ff86", '<path d="M26 68 C26 28 72 18 96 46 C120 76 92 108 58 100 C36 96 26 86 26 68 Z" fill="#65ff86" stroke="#d8ffe1" stroke-width="4"/>')
    enemy("enemy_charger.svg", "#ff463d", '<path d="M16 64 L86 20 L112 64 L86 108 Z" fill="#ff463d" stroke="#ffd0cb" stroke-width="5"/>')
    enemy("enemy_shooter.svg", "#ffc857", '<circle cx="64" cy="64" r="34" fill="#ffc857" stroke="#fff1b2" stroke-width="5"/><path d="M64 18 V110 M18 64 H110" stroke="#5d3510" stroke-width="7"/>')
    enemy("enemy_shield_bug.svg", "#80a7dc", '<rect x="30" y="26" width="68" height="76" rx="30" fill="#80a7dc" stroke="#eaf6ff" stroke-width="5"/><path d="M28 46 Q64 20 100 46" stroke="#ffffff" stroke-width="8" fill="none"/>')
    enemy("enemy_healer.svg", "#6dff9d", '<circle cx="64" cy="64" r="36" fill="#6dff9d" stroke="#e2ffe9" stroke-width="5"/><path d="M64 38 V90 M38 64 H90" stroke="#0d5832" stroke-width="10"/>')
    enemy("enemy_crystal_golem.svg", "#62dfff", '<path d="M64 10 L102 42 L92 104 L64 120 L36 104 L26 42 Z" fill="#62dfff" stroke="#e9fbff" stroke-width="5"/>')
    enemy("enemy_reaper.svg", "#b84cff", '<path d="M64 16 C94 30 104 58 88 104 H40 C24 58 34 30 64 16 Z" fill="#b84cff" stroke="#f0d1ff" stroke-width="5"/><path d="M24 34 Q80 18 110 64" stroke="#ffffff" stroke-width="8" fill="none"/>')
    enemy("enemy_leech.svg", "#d91f3b", '<ellipse cx="64" cy="68" rx="42" ry="26" fill="#d91f3b" stroke="#ffc5cf" stroke-width="5"/><path d="M34 70 Q64 100 94 70" stroke="#440818" stroke-width="8" fill="none"/>')
    enemy("enemy_bomber.svg", "#ff6d22", '<circle cx="64" cy="70" r="34" fill="#ff6d22" stroke="#ffd0a6" stroke-width="5"/><path d="M64 36 Q76 18 96 20" stroke="#ffe66d" stroke-width="7" fill="none"/>')
    enemy("enemy_crystal_sniper.svg", "#5ee7ff", '<path d="M20 70 L82 24 L110 50 L48 104 Z" fill="#5ee7ff" stroke="#eaffff" stroke-width="5"/><path d="M38 86 L96 40" stroke="#102447" stroke-width="7"/>')
    enemy("enemy_swarm_mother.svg", "#85f052", '<ellipse cx="64" cy="70" rx="42" ry="34" fill="#85f052" stroke="#e8ffd8" stroke-width="5"/><circle cx="42" cy="90" r="9" fill="#3ab64b"/><circle cx="84" cy="92" r="9" fill="#3ab64b"/>')
    enemy("enemy_void_knight.svg", "#7046b8", '<path d="M64 12 L98 42 L90 104 L64 120 L38 104 L30 42 Z" fill="#7046b8" stroke="#dac8ff" stroke-width="5"/><path d="M44 52 H84 V86 H44 Z" fill="#141026"/>')
    enemy("enemy_curse_eye.svg", "#ff4fd8", '<circle cx="64" cy="64" r="42" fill="#ff4fd8" stroke="#ffd4f5" stroke-width="5"/><ellipse cx="64" cy="64" rx="26" ry="16" fill="#ffffff"/><circle cx="64" cy="64" r="9" fill="#28051f"/>')

    weapon("weapon_magic_bolt.svg", "#ffd95a", '<path d="M18 70 L82 30 L110 58 L46 98 Z" fill="#ffd95a" stroke="#fff7c1" stroke-width="5"/>')
    weapon("weapon_starbreaker_bolt.svg", "#fff1a8", '<path d="M64 10 L78 48 L118 50 L86 74 L98 114 L64 90 L30 114 L42 74 L10 50 L50 48 Z" fill="#fff1a8" stroke="#ffffff" stroke-width="4"/>')
    weapon("weapon_ice_orbit.svg", "#72e8ff", '<circle cx="64" cy="64" r="42" fill="none" stroke="#72e8ff" stroke-width="10"/><circle cx="94" cy="34" r="10" fill="#eaffff"/>')
    weapon("weapon_eternal_ice_ring.svg", "#d9fbff", '<circle cx="64" cy="64" r="48" fill="none" stroke="#d9fbff" stroke-width="8"/><circle cx="64" cy="64" r="28" fill="none" stroke="#65cfff" stroke-width="6"/>')
    weapon("weapon_thunder_chain.svg", "#d9c4ff", '<path d="M74 8 L30 70 H62 L50 120 L102 52 H68 Z" fill="#d9c4ff" stroke="#ffffff" stroke-width="5"/>')
    weapon("weapon_divine_chain.svg", "#ffffff", '<path d="M66 4 L22 74 H58 L42 124 L108 42 H72 Z" fill="#ffffff" stroke="#b87cff" stroke-width="6"/>')
    weapon("weapon_bomb_seed.svg", "#ff7a2f", '<circle cx="64" cy="70" r="34" fill="#ff7a2f" stroke="#ffd1a5" stroke-width="5"/><path d="M64 36 Q76 20 98 22" stroke="#72ff8a" stroke-width="6" fill="none"/>')
    weapon("weapon_final_fireworks.svg", "#ffb347", '<circle cx="64" cy="64" r="12" fill="#ffffff"/><path d="M64 8 V38 M64 90 V120 M8 64 H38 M90 64 H120 M24 24 L46 46 M82 82 L104 104 M104 24 L82 46 M46 82 L24 104" stroke="#ffb347" stroke-width="7"/>')
    weapon("weapon_laser_lance.svg", "#80f4ff", '<path d="M14 74 L94 18 L114 38 L34 94 Z" fill="#80f4ff" stroke="#ffffff" stroke-width="5"/>')
    weapon("weapon_aurora_lance.svg", "#ff8cff", '<path d="M8 76 L96 10 L122 36 L34 102 Z" fill="#ff8cff" stroke="#ffffff" stroke-width="5"/><path d="M28 86 L106 28" stroke="#80ffea" stroke-width="5"/>')
    weapon("weapon_poison_mist.svg", "#65ff62", '<circle cx="48" cy="70" r="28" fill="#65ff62" opacity="0.72"/><circle cx="78" cy="54" r="34" fill="#b85cff" opacity="0.48"/>')
    weapon("weapon_corrosion_domain.svg", "#9cff5e", '<circle cx="64" cy="64" r="48" fill="#9cff5e" opacity="0.30"/><circle cx="64" cy="64" r="32" fill="#b85cff" opacity="0.42"/><circle cx="64" cy="64" r="14" fill="#eaffd7"/>')
    weapon("weapon_bit.svg", "#66ffe5", '<rect x="40" y="42" width="48" height="40" rx="12" fill="#66ffe5" stroke="#ffffff" stroke-width="5"/><circle cx="64" cy="62" r="10" fill="#13223f"/>')
    weapon("weapon_star_guard_bit.svg", "#ffd45e", '<path d="M64 18 L78 50 L112 52 L84 72 L94 106 L64 86 L34 106 L44 72 L16 52 L50 50 Z" fill="#ffd45e" stroke="#ffffff" stroke-width="5"/>')
    weapon("weapon_rune_gate.svg", "#ff8a3d", '<rect x="28" y="18" width="72" height="92" rx="22" fill="none" stroke="#ff8a3d" stroke-width="10"/><path d="M48 48 H80 M48 64 H80 M48 80 H80" stroke="#fff2c4" stroke-width="6"/>')
    weapon("weapon_eternal_gate.svg", "#ffd06d", '<rect x="18" y="10" width="92" height="108" rx="26" fill="none" stroke="#ffd06d" stroke-width="10"/><path d="M40 36 H88 M34 64 H94 M40 92 H88" stroke="#ffffff" stroke-width="7"/>')
    weapon("weapon_comet_staff.svg", "#ffbf45", '<path d="M18 106 L86 22" stroke="#ffbf45" stroke-width="12"/><circle cx="88" cy="24" r="18" fill="#ffffff"/><path d="M72 42 L108 6" stroke="#ff7a2f" stroke-width="8"/>')
    weapon("weapon_meteor_cluster.svg", "#ffd36e", '<circle cx="46" cy="50" r="14" fill="#ffffff"/><circle cx="76" cy="34" r="12" fill="#ffd36e"/><circle cx="92" cy="72" r="16" fill="#ff7a2f"/><path d="M24 100 L96 28" stroke="#ffd36e" stroke-width="8"/>')
    weapon("weapon_soul_scythe.svg", "#d8f2ff", '<path d="M34 106 C72 96 102 58 96 26 C66 40 42 66 30 100" fill="none" stroke="#d8f2ff" stroke-width="10"/><path d="M34 106 L74 22" stroke="#7c4dff" stroke-width="8"/>')
    weapon("weapon_death_soul_scythe.svg", "#ffffff", '<path d="M24 108 C78 100 114 54 104 16 C66 30 36 62 20 102" fill="none" stroke="#ffffff" stroke-width="11"/><path d="M34 108 L82 18" stroke="#ff4fd8" stroke-width="9"/>')
    weapon("weapon_mirror_shard.svg", "#bdecff", '<path d="M64 12 L104 54 L78 116 L24 84 Z" fill="#bdecff" stroke="#ffffff" stroke-width="5"/><path d="M44 80 L84 38" stroke="#3d7cff" stroke-width="5"/>')
    weapon("weapon_kaleido_shard.svg", "#ffffff", '<path d="M64 8 L116 44 L94 112 L34 112 L12 44 Z" fill="#ffffff" stroke="#80eaff" stroke-width="5"/><path d="M64 8 V112 M12 44 L116 44 M34 112 L94 112" stroke="#9b5cff" stroke-width="4"/>')
    weapon("weapon_sonic_wave.svg", "#9dffed", '<circle cx="64" cy="64" r="20" fill="#9dffed"/><path d="M24 64 Q44 34 64 64 Q84 94 104 64" fill="none" stroke="#9dffed" stroke-width="9"/><path d="M16 64 Q44 18 64 64 Q84 110 112 64" fill="none" stroke="#ffffff" stroke-width="5"/>')
    weapon("weapon_sonic_domain.svg", "#eaffff", '<circle cx="64" cy="64" r="48" fill="none" stroke="#eaffff" stroke-width="7"/><circle cx="64" cy="64" r="28" fill="none" stroke="#70ffe3" stroke-width="8"/>')
    weapon("weapon_gem_turret.svg", "#5dffc8", '<rect x="42" y="50" width="44" height="42" rx="10" fill="#5dffc8" stroke="#ffffff" stroke-width="5"/><path d="M64 50 V20" stroke="#5dffc8" stroke-width="10"/><path d="M34 102 H94" stroke="#ffffff" stroke-width="8"/>')
    weapon("weapon_gem_star_cannon.svg", "#fff06e", '<rect x="34" y="48" width="60" height="46" rx="12" fill="#fff06e" stroke="#ffffff" stroke-width="5"/><path d="M64 48 V12" stroke="#5dffc8" stroke-width="12"/><path d="M20 106 H108" stroke="#ffffff" stroke-width="9"/>')
    expansion_weapon_colors = {
        "corridor_blade": "#62ddff", "wall_bounce_blaster": "#bdecff", "drill_charge": "#ffad45",
        "mine_lantern": "#ffe36b", "relic_chain": "#c66cff", "shrine_beam": "#fff4a3",
        "thorn_seed": "#70ff72", "frost_wall": "#80eaff", "coin_orbit": "#ffd45e",
        "echo_bell": "#70ffe3", "void_mirror": "#9b5cff", "magma_core": "#ff5d2e",
        "compass_star": "#6ee7ff", "guardian_wall": "#8db7ff", "gravity_anchor": "#895cff",
    }
    for name, color in expansion_weapon_colors.items():
        weapon(
            "weapon_%s.svg" % name,
            color,
            '<path d="M64 16 L104 48 L92 104 L64 116 L36 104 L24 48 Z" fill="%s" stroke="#ffffff" stroke-width="5"/><circle cx="64" cy="64" r="16" fill="#071126"/>' % color,
        )

    field("tile_star_plain.svg", "#071126", "#6ee7ff")
    field("tile_amethyst_forest.svg", "#160a2a", "#c77dff")
    field("tile_red_mine.svg", "#210d09", "#ff7a2f")
    field("tile_void_zone.svg", "#070512", "#9b5cff")
    field("field_outer_crystal_wall.svg", "#130922", "#6ee7ff")
    field("field_small_crystal.svg", "#0b1a2f", "#83efff")
    field("field_wall_crystal.svg", "#10152e", "#9b7cff")
    field("field_rich_crystal.svg", "#0f241f", "#ffe66d")
    field("field_cursed_crystal.svg", "#220822", "#ff4fd8")
    field("field_danger_overlay.svg", "#260616", "#ff2d65")

    weapon("ui_hp_bar_frame.svg", "#42ff6a", '<rect x="12" y="42" width="104" height="44" rx="10" fill="none" stroke="#eaffef" stroke-width="8"/><rect x="24" y="54" width="80" height="20" rx="5" fill="#42ff6a"/>')
    weapon("ui_exp_bar_frame.svg", "#58c7ff", '<rect x="12" y="42" width="104" height="44" rx="10" fill="none" stroke="#eaf8ff" stroke-width="8"/><rect x="24" y="54" width="80" height="20" rx="5" fill="#58c7ff"/>')
    weapon("ui_chest_arrow.svg", "#ffd45e", '<path d="M14 64 H86" stroke="#ffd45e" stroke-width="14"/><path d="M70 28 L112 64 L70 100 Z" fill="#ffd45e" stroke="#fff2b0" stroke-width="5"/>')
    weapon("ui_evolution_ready.svg", "#fff1a8", '<path d="M64 12 L78 48 L116 48 L86 72 L98 112 L64 88 L30 112 L42 72 L12 48 L50 48 Z" fill="#fff1a8" stroke="#ffffff" stroke-width="5"/>')
    weapon("ui_danger_icon.svg", "#ff2d65", '<path d="M64 12 L118 110 H10 Z" fill="#ff2d65" stroke="#ffd8e3" stroke-width="6"/><path d="M64 44 V78" stroke="#ffffff" stroke-width="10"/><circle cx="64" cy="94" r="6" fill="#ffffff"/>')
    weapon("ui_fever.svg", "#5df4ff", '<circle cx="64" cy="64" r="42" fill="#5df4ff" opacity="0.35"/><path d="M64 18 L74 56 L112 60 L80 80 L90 114 L64 92 L38 114 L48 80 L16 60 L54 56 Z" fill="#ffffff"/>')
    weapon("ui_overclock.svg", "#ff9d2e", '<circle cx="64" cy="64" r="46" fill="#ff9d2e" opacity="0.34"/><path d="M64 18 L82 64 H66 L76 110 L44 58 H62 Z" fill="#ffffff" stroke="#ff9d2e" stroke-width="4"/>')
    weapon("ui_rune_contract.svg", "#ff304a", '<path d="M64 12 L112 42 V86 L64 116 L16 86 V42 Z" fill="#ff304a" opacity="0.42" stroke="#ffd7dc" stroke-width="5"/><path d="M42 48 H86 M42 66 H86 M42 84 H72" stroke="#ffffff" stroke-width="7"/>')
    weapon("ui_recall_drone.svg", "#62f5ff", '<circle cx="64" cy="64" r="42" fill="none" stroke="#62f5ff" stroke-width="8"/><path d="M64 30 V64 H98" stroke="#ffffff" stroke-width="8"/><path d="M42 92 L28 108 M86 92 L100 108" stroke="#62f5ff" stroke-width="8"/>')

    character("noah", "#24558f", "#6ee7ff", "M32 104 L40 42 L64 18 L88 42 L96 104 Z", '<path d="M42 28 H86 L78 14 H50 Z" fill="#ffd65a" stroke="#fff0a8" stroke-width="4"/><circle cx="64" cy="28" r="6" fill="#6ee7ff"/>')
    character("mio", "#d9f6ff", "#72dfff", "M28 110 L42 34 L64 14 L86 34 L100 110 Z", '<path d="M64 12 L72 30 L92 34 L76 46 L82 66 L64 54 L46 66 L52 46 L36 34 L56 30 Z" fill="#eaffff"/>')
    character("rai", "#2a2b45", "#ffd85a", "M30 106 L44 36 L64 16 L84 36 L98 106 Z", '<path d="M74 10 L48 60 H66 L54 104 L92 46 H70 Z" fill="#ffd85a"/>')
    character("bomb", "#75312b", "#ff7a2f", "M30 106 L42 40 L64 20 L86 40 L98 106 Z", '<circle cx="42" cy="82" r="8" fill="#ff7a2f"/><circle cx="86" cy="82" r="8" fill="#ff7a2f"/>')
    character("gantz", "#364252", "#8df1ff", "M20 108 L34 34 L64 14 L94 34 L108 108 Z", '<path d="M88 48 L114 34 L120 56 L96 74 Z" fill="#8df1ff" stroke="#ffffff" stroke-width="4"/>')
    character("kaede", "#10251e", "#63ff86", "M38 110 L44 36 L64 14 L84 36 L90 110 Z", '<path d="M30 76 C54 52 78 52 104 28" stroke="#63ff86" stroke-width="8" fill="none"/>')
    character("sera", "#1b1741", "#ffdfff", "M24 110 L42 36 L64 10 L86 36 L104 110 Z", '<path d="M64 16 L72 40 L98 42 L76 58 L84 84 L64 68 L44 84 L52 58 L30 42 L56 40 Z" fill="#ffdfff"/>')
    character("rei", "#1d3140", "#bdecff", "M30 108 L42 34 L64 18 L86 34 L98 108 Z", '<path d="M28 54 L52 28 L64 56 L76 28 L100 54 L76 86 L64 60 L52 86 Z" fill="#bdecff" opacity="0.75"/>')
    character("atlas", "#283243", "#b7d0ff", "M18 110 L34 30 L64 10 L94 30 L110 110 Z", '<path d="M64 58 L92 74 L84 104 H44 L36 74 Z" fill="#b7d0ff" opacity="0.65"/>')
    character("nero", "#140b22", "#b85cff", "M24 110 L42 32 L64 12 L86 32 L104 110 Z", '<path d="M50 22 L42 6 L60 18 M78 22 L86 6 L68 18" stroke="#b85cff" stroke-width="6" fill="none"/>')
    character("lily", "#4b2346", "#ffb7df", "M30 110 L44 38 L64 18 L84 38 L98 110 Z", '<path d="M34 80 Q64 58 94 80 L88 110 H40 Z" fill="#ffd45e" opacity="0.72"/>')
    character("zero", "#e8ecf7", "#a8f7ff", "M26 110 L42 30 L64 12 L86 30 L102 110 Z", '<circle cx="78" cy="46" r="10" fill="none" stroke="#10172f" stroke-width="5"/><path d="M20 88 Q64 64 108 88" stroke="#a8f7ff" stroke-width="5" fill="none"/>')
    character("ghost", "#94eaff", "#b85cff", "M30 108 V44 C30 18 98 18 98 44 V108 L82 94 L64 110 L46 94 Z", '<path d="M24 100 C48 88 78 112 104 96" stroke="#ffffff" stroke-width="4" fill="none" opacity="0.55"/>')
    character("collector", "#ffd45e", "#fff2a8", "M26 110 L42 34 L64 16 L86 34 L102 110 Z", '<circle cx="64" cy="78" r="34" fill="none" stroke="#fff2a8" stroke-width="6"/><path d="M28 78 H100" stroke="#ffd45e" stroke-width="5"/>')
    character("nameless_reaper", "#080812", "#ff2d55", "M28 110 C18 58 34 22 64 12 C94 22 110 58 100 110 Z", '<path d="M24 32 Q72 10 108 66" stroke="#ffffff" stroke-width="7" fill="none"/><circle cx="56" cy="52" r="5" fill="#ff2d55"/><circle cx="74" cy="52" r="5" fill="#ff2d55"/>')
    character("corridor_knight", "#26384a", "#62ddff", "M22 110 L34 30 L64 12 L94 30 L106 110 Z", '<path d="M30 72 H98" stroke="#ffe56d" stroke-width="8"/>')
    character("cave_mapper", "#254033", "#74ffb5", "M28 110 L40 34 L64 16 L88 34 L100 110 Z", '<path d="M30 76 L48 62 L66 78 L96 48" stroke="#fff4a3" stroke-width="6" fill="none"/>')
    character("relic_hunter", "#291636", "#d66cff", "M26 110 L40 30 L64 12 L88 30 L102 110 Z", '<path d="M36 82 Q64 58 92 82" stroke="#ff5f8c" stroke-width="7" fill="none"/>')
    character("shrine_guardian", "#3b3827", "#ffe36b", "M20 110 L36 28 L64 10 L92 28 L108 110 Z", '<path d="M64 20 V104 M32 62 H96" stroke="#fff8cc" stroke-width="6"/>')
    character("tunnel_runner", "#182f3e", "#55e9ff", "M34 110 L42 36 L64 14 L86 36 L94 110 Z", '<path d="M20 92 L108 42" stroke="#ffb84c" stroke-width="8"/>')
    character("crystal_witch", "#2d1838", "#a8f7ff", "M24 110 L42 30 L64 8 L86 30 L104 110 Z", '<path d="M64 10 L78 36 L108 40 L84 58 L92 88 L64 70 L36 88 L44 58 L20 40 L50 36 Z" fill="#8df1ff" opacity="0.55"/>')
    character("forge_master", "#4a2e22", "#ff9a45", "M18 110 L34 30 L64 12 L94 30 L110 110 Z", '<path d="M26 82 H102 M42 64 L86 104" stroke="#ffd08c" stroke-width="9"/>')
    character("storm_pilgrim", "#29253e", "#e3ccff", "M28 110 L42 30 L64 12 L86 30 L100 110 Z", '<path d="M74 12 L46 62 H66 L54 108 L94 48 H70 Z" fill="#fff36b"/>')
    character("blast_miner", "#453026", "#ff7c3a", "M18 110 L34 28 L64 12 L94 28 L110 110 Z", '<circle cx="92" cy="82" r="15" fill="#ff7c3a" stroke="#fff0bc" stroke-width="5"/>')
    character("oasis_saint", "#d9fbff", "#56ffc2", "M24 110 L40 30 L64 10 L88 30 L104 110 Z", '<path d="M64 20 C40 50 42 72 64 86 C86 72 88 50 64 20 Z" fill="#56ffc2" opacity="0.62"/>')
    character("void_cartographer", "#080713", "#9b5cff", "M24 110 L40 28 L64 8 L88 28 L104 110 Z", '<path d="M24 88 C46 54 78 104 106 46" stroke="#ff52d6" stroke-width="6" fill="none"/>')
    character("abyss_merchant", "#17101f", "#ffd45e", "M22 110 L38 30 L64 12 L90 30 L106 110 Z", '<circle cx="64" cy="80" r="28" fill="none" stroke="#ffd45e" stroke-width="7"/><path d="M42 80 H86" stroke="#ff52d6" stroke-width="6"/>')
    locked_character("secret_ghost", "#b85cff")
    locked_character("secret_collector", "#ffd45e")
    locked_character("secret_nameless_reaper", "#ff2d55")

    passive_icon("move_speed", "#8df1ff", '<path d="M28 82 C48 42 74 94 100 46" stroke="#8df1ff" stroke-width="10" fill="none"/>')
    passive_icon("magnet", "#ff5fd8", '<path d="M38 34 V72 C38 104 90 104 90 72 V34" stroke="#ff5fd8" stroke-width="12" fill="none"/>')
    passive_icon("might", "#ffd65a", '<path d="M64 22 L78 58 H112 L84 78 L96 112 L64 90 L32 112 L44 78 L16 58 H50 Z" fill="#ffd65a"/>')
    passive_icon("cooldown", "#72dfff", '<circle cx="64" cy="64" r="34" fill="none" stroke="#72dfff" stroke-width="10"/><path d="M64 34 V66 H90" stroke="#ffffff" stroke-width="8"/>')
    passive_icon("area", "#63ff86", '<circle cx="64" cy="64" r="44" fill="none" stroke="#63ff86" stroke-width="8"/><circle cx="64" cy="64" r="20" fill="none" stroke="#ffffff" stroke-width="5"/>')
    passive_icon("max_hp", "#ff5d6e", '<path d="M64 104 C20 74 28 30 52 36 C60 38 64 48 64 48 C64 48 68 38 76 36 C100 30 108 74 64 104 Z" fill="#ff5d6e"/>')
    passive_icon("regen", "#72ff9a", '<path d="M64 26 V102 M28 64 H100" stroke="#72ff9a" stroke-width="14"/>')
    passive_icon("greed", "#ffd45e", '<circle cx="64" cy="64" r="34" fill="#ffd45e"/><path d="M52 48 H78 M48 64 H82 M54 80 H76" stroke="#071126" stroke-width="7"/>')
    passive_icon("armor", "#b7d0ff", '<path d="M64 18 L104 36 V70 C104 94 82 110 64 116 C46 110 24 94 24 70 V36 Z" fill="#b7d0ff"/>')
    passive_icon("revival", "#ffffff", '<path d="M64 20 C42 40 38 76 64 104 C90 76 86 40 64 20 Z" fill="#ffffff"/><path d="M34 58 Q64 30 94 58" stroke="#ffd45e" stroke-width="7" fill="none"/>')
    passive_icon("curse", "#b85cff", '<circle cx="64" cy="64" r="36" fill="#b85cff"/><path d="M44 48 H84 M50 80 H78" stroke="#080812" stroke-width="8"/>')
    passive_icon("projectile_count", "#ff9d2e", '<circle cx="40" cy="64" r="12" fill="#ff9d2e"/><circle cx="64" cy="44" r="12" fill="#ff9d2e"/><circle cx="88" cy="64" r="12" fill="#ff9d2e"/><circle cx="64" cy="88" r="12" fill="#ff9d2e"/>')
    passive_icon("pickup_heal", "#5dffc8", '<path d="M64 22 V106 M22 64 H106" stroke="#5dffc8" stroke-width="10"/><circle cx="64" cy="64" r="42" fill="none" stroke="#ffffff" stroke-width="4"/>')
    passive_icon("elite_hunter", "#ff7a2f", '<path d="M64 18 L82 54 L122 60 L92 84 L100 120 L64 100 L28 120 L36 84 L6 60 L46 54 Z" fill="#ff7a2f"/>')
    passive_icon("crystal_breaker", "#83efff", '<path d="M64 14 L100 52 L82 114 H46 L28 52 Z" fill="#83efff"/><path d="M38 86 L92 32" stroke="#071126" stroke-width="8"/>')
    passive_icon("luck", "#fff2a8", '<path d="M64 22 C86 22 100 42 92 62 C118 66 112 106 82 96 C72 120 36 108 46 82 C18 76 26 36 54 44 C56 34 58 22 64 22 Z" fill="#fff2a8"/>')
    expansion_passives = [
        "corridor_sense", "room_mastery", "wall_breaker", "route_memory", "treasure_instinct",
        "event_focus", "relic_resist", "boss_pressure", "choke_point", "open_field",
        "mining_luck", "map_reader", "hunter_mark", "chain_reward", "emergency_route",
        "terrain_core", "relic_appraiser", "safe_pocket", "reroll_ticket", "banish_mark",
        "reflect_prism", "poison_vessel", "crystal_wallet",
    ]
    for index, name in enumerate(expansion_passives):
        colors = ["#6ee7ff", "#63ff86", "#ffd65a", "#ff7a2f", "#c77dff"]
        color = colors[index % len(colors)]
        passive_icon(name, color, '<path d="M64 24 L96 48 L86 100 H42 L32 48 Z" fill="%s" opacity="0.72"/><circle cx="64" cy="64" r="14" fill="#ffffff"/>' % color)

    ui_asset("button_crystal", "#6ee7ff", '<rect x="22" y="42" width="84" height="44" rx="10" fill="#0d203a" stroke="#6ee7ff" stroke-width="4"/><path d="M36 64 H92" stroke="#ffffff" stroke-width="5"/>')
    ui_asset("card_weapon", "#ff7a2f", '<rect x="18" y="22" width="92" height="84" rx="12" fill="#1b1620" stroke="#ff7a2f" stroke-width="4"/><path d="M34 78 L90 34" stroke="#ffd6b8" stroke-width="8"/>')
    ui_asset("card_passive", "#63ff86", '<rect x="18" y="22" width="92" height="84" rx="12" fill="#0d1e19" stroke="#63ff86" stroke-width="4"/><circle cx="64" cy="64" r="24" fill="none" stroke="#e8ffe8" stroke-width="7"/>')
    ui_asset("card_evolution", "#ffd65a", '<rect x="18" y="22" width="92" height="84" rx="12" fill="#211b0d" stroke="#ffd65a" stroke-width="4"/><path d="M64 28 L76 58 L108 60 L82 78 L92 110 L64 90 L36 110 L46 78 L20 60 L52 58 Z" fill="#fff2a8"/>')
    ui_asset("minimap_arrow", "#6ee7ff", '<path d="M20 64 H82" stroke="#6ee7ff" stroke-width="14"/><path d="M72 28 L112 64 L72 100 Z" fill="#6ee7ff" stroke="#ffffff" stroke-width="5"/>')
    ui_asset("boss_warning", "#ff2d55", '<path d="M64 14 L116 108 H12 Z" fill="#ff2d55"/><path d="M64 44 V78" stroke="#ffffff" stroke-width="10"/><circle cx="64" cy="94" r="6" fill="#ffffff"/>')
    ui_asset("objective_arrow", "#6ee7ff", '<path d="M18 64 H78" stroke="#6ee7ff" stroke-width="12"/><path d="M70 30 L112 64 L70 98 Z" fill="#6ee7ff" stroke="#ffffff" stroke-width="5"/>')
    ui_asset("melee_rush_gauge", "#63ff86", '<rect x="18" y="54" width="92" height="20" rx="8" fill="#10251e" stroke="#63ff86" stroke-width="5"/><rect x="28" y="60" width="62" height="8" rx="4" fill="#63ff86"/><path d="M34 96 C56 74 78 74 100 44" stroke="#ffffff" stroke-width="7" fill="none"/>')
    ui_asset("field_event", "#ff5fd8", '<path d="M64 18 L78 48 L112 52 L86 76 L94 110 L64 92 L34 110 L42 76 L16 52 L50 48 Z" fill="#ff5fd8" stroke="#ffffff" stroke-width="5"/><circle cx="64" cy="64" r="10" fill="#071126"/>')
    ui_asset("field_scan", "#6ee7ff", '<circle cx="56" cy="56" r="30" fill="none" stroke="#ffffff" stroke-width="8"/><path d="M78 78 L108 108" stroke="#6ee7ff" stroke-width="12"/><path d="M28 56 H84 M56 28 V84" stroke="#6ee7ff" stroke-width="4" opacity="0.72"/>')
    ui_asset("exploration_chain", "#63ff86", '<path d="M32 48 C18 48 18 80 32 80 H54 C68 80 68 48 54 48 Z M74 48 C60 48 60 80 74 80 H96 C110 80 110 48 96 48 Z" fill="none" stroke="#63ff86" stroke-width="9"/><path d="M52 64 H76" stroke="#ffffff" stroke-width="8"/>')
    ui_asset("virtual_joystick_outer", "#6ee7ff", '<circle cx="64" cy="64" r="42" fill="#0d203a" opacity="0.64" stroke="#6ee7ff" stroke-width="6"/><circle cx="64" cy="64" r="22" fill="none" stroke="#ffffff" stroke-width="3" opacity="0.58"/>')
    ui_asset("virtual_joystick_knob", "#eaffff", '<circle cx="64" cy="64" r="30" fill="#2dd7ff" opacity="0.82" stroke="#ffffff" stroke-width="6"/><circle cx="64" cy="64" r="10" fill="#071126"/>')
    ui_asset("touch_scan", "#6ee7ff", '<circle cx="54" cy="54" r="28" fill="none" stroke="#ffffff" stroke-width="8"/><path d="M74 74 L106 106" stroke="#6ee7ff" stroke-width="12"/><path d="M30 54 H78 M54 30 V78" stroke="#6ee7ff" stroke-width="4"/>')
    ui_asset("touch_recall", "#63ff86", '<path d="M30 48 C46 24 86 24 100 50" fill="none" stroke="#63ff86" stroke-width="9"/><path d="M98 34 L106 54 L84 58" fill="#63ff86"/><path d="M98 80 C82 104 42 104 28 78" fill="none" stroke="#ffffff" stroke-width="9"/><path d="M30 94 L22 74 L44 70" fill="#ffffff"/>')
    ui_asset("touch_speed", "#ffd65a", '<path d="M42 24 L80 64 L42 104 Z" fill="#ffd65a" stroke="#ffffff" stroke-width="5"/><path d="M72 24 L110 64 L72 104 Z" fill="#ff9d2e" stroke="#ffffff" stroke-width="5"/>')
    ui_asset("touch_pause", "#ff5d68", '<rect x="34" y="28" width="20" height="72" rx="6" fill="#ffffff"/><rect x="74" y="28" width="20" height="72" rx="6" fill="#ff5d68"/>')
    ui_asset("touch_back", "#6ee7ff", '<path d="M28 64 L62 30 V50 H104 V78 H62 V98 Z" fill="#6ee7ff" stroke="#ffffff" stroke-width="5"/>')
    ui_asset("touch_card_frame", "#ffd65a", '<rect x="18" y="14" width="92" height="100" rx="10" fill="#071126" stroke="#ffd65a" stroke-width="6"/><path d="M34 94 H94" stroke="#ffffff" stroke-width="5"/><circle cx="64" cy="54" r="20" fill="#ffd65a" opacity="0.35"/>')
    ui_asset("ios_shop_card", "#63ff86", '<rect x="18" y="18" width="92" height="92" rx="10" fill="#0d1e19" stroke="#63ff86" stroke-width="5"/><circle cx="50" cy="52" r="18" fill="#ffd65a"/><rect x="34" y="82" width="60" height="12" rx="6" fill="#ffffff"/>')
    ui_asset("ios_tab_bar", "#6ee7ff", '<rect x="14" y="72" width="100" height="30" rx="10" fill="#0d203a" stroke="#6ee7ff" stroke-width="4"/><circle cx="34" cy="87" r="7" fill="#ffffff"/><circle cx="64" cy="87" r="7" fill="#6ee7ff"/><circle cx="94" cy="87" r="7" fill="#63ff86"/>')
    ui_asset("ios_safe_area", "#6ee7ff", '<rect x="18" y="22" width="92" height="84" rx="18" fill="none" stroke="#6ee7ff" stroke-width="5"/><rect x="30" y="32" width="68" height="62" rx="10" fill="#6ee7ff" opacity="0.18" stroke="#ffffff" stroke-width="3"/>')
    ui_asset("handed_right", "#6ee7ff", '<path d="M48 102 C34 82 36 52 48 34 C56 22 68 30 66 44 V58 L78 34 C84 24 96 30 92 42 L78 86 C74 104 58 112 48 102 Z" fill="#6ee7ff" stroke="#ffffff" stroke-width="5"/>')
    ui_asset("handed_left", "#ffd65a", '<path d="M80 102 C94 82 92 52 80 34 C72 22 60 30 62 44 V58 L50 34 C44 24 32 30 36 42 L50 86 C54 104 70 112 80 102 Z" fill="#ffd65a" stroke="#ffffff" stroke-width="5"/>')
    ui_asset("touch_tutorial_move", "#6ee7ff", '<circle cx="42" cy="82" r="26" fill="#0d203a" stroke="#6ee7ff" stroke-width="5"/><circle cx="52" cy="68" r="10" fill="#ffffff"/><path d="M70 82 H108 M94 68 L108 82 L94 96" stroke="#63ff86" stroke-width="7" fill="none"/>')
    ui_asset("touch_tutorial_actions", "#63ff86", '<circle cx="36" cy="78" r="18" fill="#6ee7ff"/><circle cx="72" cy="56" r="18" fill="#63ff86"/><circle cx="94" cy="90" r="18" fill="#ffd65a"/><path d="M28 30 H100" stroke="#ffffff" stroke-width="6"/>')
    ui_asset("touch_tutorial_cards", "#ffd65a", '<rect x="18" y="30" width="28" height="64" rx="6" fill="#0d203a" stroke="#6ee7ff" stroke-width="4"/><rect x="50" y="22" width="28" height="72" rx="6" fill="#0d203a" stroke="#ffd65a" stroke-width="5"/><rect x="82" y="30" width="28" height="64" rx="6" fill="#0d203a" stroke="#63ff86" stroke-width="4"/><circle cx="64" cy="108" r="8" fill="#ffffff"/>')
    ui_asset("touch_press_effect", "#ffffff", '<circle cx="64" cy="64" r="18" fill="#ffffff" opacity="0.50"/><circle cx="64" cy="64" r="42" fill="none" stroke="#6ee7ff" stroke-width="6" opacity="0.80"/>')
    terrain_assets = {
        "safe_room": "#56ffc2", "crystal_corridor": "#62ddff", "mine_chamber": "#ffad45",
        "danger_den": "#ff365d", "healing_oasis": "#63ff86", "relic_vault": "#c77dff",
        "boss_arena": "#ff5d2e", "event_room": "#ff5fd8", "shortcut_wall": "#ffe36b",
        "sealed_room": "#9b5cff",
    }
    for name, color in terrain_assets.items():
        ui_asset("terrain_%s" % name, color, '<rect x="24" y="28" width="80" height="72" fill="%s" opacity="0.24"/><path d="M24 64 H104 M64 28 V100" stroke="#ffffff" stroke-width="6"/>' % color)
    shop_categories = ["characters", "meta", "weapon_license", "passive_license", "blessings", "exploration", "forge", "research", "cosmetic", "difficulty"]
    for index, name in enumerate(shop_categories):
        colors = ["#6ee7ff", "#63ff86", "#ffd65a", "#ff7a2f", "#c77dff"]
        color = colors[index % len(colors)]
        ui_asset("shop_%s" % name, color, '<circle cx="64" cy="64" r="30" fill="%s" opacity="0.55"/><path d="M42 64 H86 M64 42 V86" stroke="#ffffff" stroke-width="8"/>' % color)
    rank_colors = {
        "d": "#8b98ad",
        "c": "#6ee7ff",
        "b": "#63ff86",
        "a": "#ffd65a",
        "s": "#ff7a2f",
        "ss": "#ff5fd8",
    }
    for rank, color in rank_colors.items():
        stars = '<path d="M64 22 L75 50 L106 52 L82 72 L90 104 L64 86 L38 104 L46 72 L22 52 L53 50 Z" fill="%s" stroke="#ffffff" stroke-width="5"/>' % color
        if rank == "ss":
            stars += '<circle cx="24" cy="30" r="7" fill="#ffffff"/><circle cx="104" cy="30" r="7" fill="#ffffff"/>'
        ui_asset("exploration_rank_%s" % rank, color, stars)

    effect_asset("slash_arc", "#63ff86", '<path d="M18 84 C46 28 92 18 112 54" stroke="#ffffff" stroke-width="10" fill="none"/><path d="M24 92 C52 44 92 34 106 62" stroke="#63ff86" stroke-width="8" fill="none"/>')
    effect_asset("slash_wave", "#9dffed", '<path d="M16 72 C48 28 88 28 116 72" stroke="#9dffed" stroke-width="10" fill="none"/><path d="M24 88 C52 54 84 54 104 88" stroke="#ffffff" stroke-width="5" fill="none"/>')
    effect_asset("lightning_chain", "#d9c4ff", '<path d="M28 18 L70 52 H50 L100 110 L74 66 H96 Z" fill="#d9c4ff" stroke="#ffffff" stroke-width="5"/>')
    effect_asset("shock_icon", "#9fc8ff", '<path d="M72 12 L34 72 H60 L48 118 L96 52 H68 Z" fill="#9fc8ff" stroke="#ffffff" stroke-width="5"/>')
    effect_asset("shock_ring", "#b87cff", '<circle cx="64" cy="64" r="44" fill="none" stroke="#b87cff" stroke-width="8"/><path d="M42 42 L28 58 L48 62 L36 84 M86 42 L100 58 L80 62 L92 84" stroke="#ffffff" stroke-width="6" fill="none"/>')

    drop_asset("weapon_core", "#6ee7ff", '<path d="M34 82 L88 30" stroke="#ffffff" stroke-width="9"/><path d="M44 92 L98 40" stroke="#6ee7ff" stroke-width="6"/>')
    drop_asset("passive_core", "#63ff86", '<circle cx="64" cy="64" r="24" fill="none" stroke="#ffffff" stroke-width="8"/><circle cx="64" cy="64" r="10" fill="#63ff86"/>')
    drop_asset("evolution_core", "#ffd65a", '<path d="M64 28 L76 56 L106 58 L82 76 L92 106 L64 88 L36 106 L46 76 L22 58 L52 56 Z" fill="#ffd65a" stroke="#ffffff" stroke-width="4"/>')
    drop_asset("overclock_core", "#ff9d2e", '<path d="M64 24 L82 64 H66 L76 104 L44 58 H62 Z" fill="#ff9d2e" stroke="#ffffff" stroke-width="5"/>')
    drop_asset("cursed_relic", "#b85cff", '<circle cx="64" cy="60" r="26" fill="#b85cff" stroke="#ffffff" stroke-width="5"/><path d="M44 86 H84" stroke="#ffffff" stroke-width="7"/>')
    drop_asset("heal_ore", "#63ff86", '<path d="M64 34 V94 M34 64 H94" stroke="#63ff86" stroke-width="12"/><path d="M64 34 V94 M34 64 H94" stroke="#ffffff" stroke-width="5"/>')
    drop_asset("magnet_ore", "#6ee7ff", '<path d="M38 34 V72 C38 102 90 102 90 72 V34" stroke="#6ee7ff" stroke-width="12" fill="none"/><path d="M38 34 H54 M74 34 H90" stroke="#ffffff" stroke-width="6"/>')
    drop_asset("crystal_cache", "#d9fbff", '<rect x="34" y="44" width="60" height="44" rx="8" fill="#d9fbff" stroke="#ffffff" stroke-width="5"/><path d="M34 58 H94" stroke="#071126" stroke-width="6"/>')

    gimmick_asset("reflect_crystal", "#bdecff", '<path d="M64 16 L104 52 L82 112 H36 L24 48 Z" fill="#bdecff" stroke="#ffffff" stroke-width="5"/><path d="M44 86 L88 34" stroke="#357dff" stroke-width="7"/>')
    gimmick_asset("lightning_crystal", "#d9c4ff", '<path d="M72 14 L34 70 H60 L50 114 L96 50 H68 Z" fill="#d9c4ff" stroke="#ffffff" stroke-width="5"/>')
    gimmick_asset("explosive_vein", "#ff7a2f", '<path d="M20 70 L48 44 L76 58 L106 36 L94 92 L58 82 L34 102 Z" fill="#ff7a2f" stroke="#ffffff" stroke-width="5"/>')
    gimmick_asset("healing_spring", "#63ff86", '<circle cx="64" cy="70" r="34" fill="none" stroke="#63ff86" stroke-width="8"/><path d="M64 42 V92 M39 67 H89" stroke="#ffffff" stroke-width="8"/>')
    gimmick_asset("spawn_rift", "#ff4fd8", '<ellipse cx="64" cy="64" rx="24" ry="46" fill="#ff4fd8" opacity="0.58" stroke="#ffffff" stroke-width="5"/><path d="M50 32 C82 44 46 76 78 100" stroke="#071126" stroke-width="6" fill="none"/>')
    gimmick_asset("sealed_chest_pillar", "#ffd65a", '<rect x="42" y="20" width="44" height="88" rx="10" fill="#ffd65a" stroke="#ffffff" stroke-width="5"/><path d="M44 64 H84 M64 22 V106" stroke="#071126" stroke-width="6"/>')

    synergy_asset("thunder_circuit", "#d9c4ff", '<path d="M72 18 L40 66 H62 L52 108 L90 54 H68 Z" fill="#d9c4ff"/>')
    synergy_asset("melee_ashura", "#63ff86", '<path d="M26 84 C54 30 92 24 106 58" stroke="#63ff86" stroke-width="9" fill="none"/><path d="M36 98 C58 62 88 58 100 78" stroke="#ffffff" stroke-width="5" fill="none"/>')
    synergy_asset("star_reader", "#ffd65a", '<path d="M64 24 L74 54 L106 56 L80 74 L90 104 L64 86 L38 104 L48 74 L22 56 L54 54 Z" fill="#ffd65a"/>')
    synergy_asset("mining_king", "#6ee7ff", '<path d="M34 92 L86 32" stroke="#6ee7ff" stroke-width="10"/><path d="M76 24 L104 52" stroke="#ffffff" stroke-width="8"/>')
    synergy_asset("toxic_curse", "#9cff5e", '<circle cx="64" cy="64" r="30" fill="#9cff5e" opacity="0.55"/><path d="M42 86 C64 108 86 86 82 58 C76 24 52 24 46 58" stroke="#b85cff" stroke-width="7" fill="none"/>')
    synergy_asset("gem_engine", "#5dffc8", '<rect x="40" y="48" width="48" height="40" rx="10" fill="#5dffc8"/><circle cx="64" cy="68" r="12" fill="#ffffff"/>')
    synergy_asset("blast_core", "#ff7a2f", '<circle cx="64" cy="64" r="18" fill="#ffffff"/><path d="M64 16 V42 M64 86 V112 M16 64 H42 M86 64 H112" stroke="#ff7a2f" stroke-width="8"/>')
    synergy_asset("guardian_field", "#b7d0ff", '<path d="M64 22 L100 38 V70 C100 94 80 108 64 114 C48 108 28 94 28 70 V38 Z" fill="#b7d0ff"/>')


if __name__ == "__main__":
    main()
