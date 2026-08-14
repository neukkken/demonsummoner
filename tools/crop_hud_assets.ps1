Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Image]::FromFile((Resolve-Path "art/HUD.jpg"))
$w = $src.Width
$h = $src.Height
Write-Output "Source: ${w}x${h}"

function Crop-And-Save([string]$relPath, [int]$x, [int]$y, [int]$cw, [int]$ch) {
    $outDir = Split-Path (Join-Path "art\HUD" $relPath) -Parent
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

    $x = [Math]::Max(0, [Math]::Min($x, $w - 1))
    $y = [Math]::Max(0, [Math]::Min($y, $h - 1))
    $cw = [Math]::Min($cw, $w - $x)
    $ch = [Math]::Min($ch, $h - $y)

    $rect = New-Object System.Drawing.Rectangle($x, $y, $cw, $ch)
    $crop = $src.Clone($rect, $src.PixelFormat)
    $outPath = Join-Path "art\HUD" $relPath
    $crop.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
    Write-Output "  OK: $relPath ($($cw)x$($ch)) @ ($x,$y)"
}

# ═══════════════════════════════════════════════════
# CRITICAL: Spell Icons (frame + icon, ~73x70 each)
# ═══════════════════════════════════════════════════
Crop-And-Save "critical\fireball_56.png"     45   82  73  70
Crop-And-Save "critical\icewall_56.png"    145   82  75  70
Crop-And-Save "critical\icelance_56.png"   245   82  77  70
Crop-And-Save "critical\blackhole_56.png"   45  178  73  62
Crop-And-Save "critical\segador_56.png"    145  178  71  62
Crop-And-Save "critical\devorador_56.png"  245  178  77  62

# CRITICAL: Crosshair (between icon rows)
Crop-And-Save "critical\crosshair_48.png"  255  155  63  20

# CRITICAL: Runes (below crosshair, 3 side by side)
Crop-And-Save "critical\rune_fire_48.png"  248  179  47  30
Crop-And-Save "critical\rune_ice_48.png"   265  179  45  30
Crop-And-Save "critical\rune_void_48.png"  280  179  40  30

# ═══════════════════════════════════════════════════
# HIGH: HP & MP Globes (spheres with frames)
# ═══════════════════════════════════════════════════
Crop-And-Save "high\globe_hp_fill_96.png"   560   82  80  78
Crop-And-Save "high\globe_hp_frame_96.png"  560   82  80  78
Crop-And-Save "high\globe_mp_fill_96.png"   655   82  90  78
Crop-And-Save "high\globe_mp_frame_96.png"  655   82  90  78

# HIGH: Slot Frame 64x64
Crop-And-Save "high\slot_frame_64.png"      750  110  70  70

# HIGH: XP Bar 320x14
Crop-And-Save "high\xp_fill_320x14.png"     770  160 230  40
Crop-And-Save "high\xp_frame_320x14.png"    770  160 230  40

# HIGH: Banner 400x120 (Level Up with wings)
Crop-And-Save "high\banner_400x120.png"     770  170 230  60

# ═══════════════════════════════════════════════════
# BUTTONS: 3 columns (Main Menu, Game Over, Upgrade)
#          x ranges: 424-562 | 634-750 | 766-876
#          3 rows: Normal y=270-310 | Hover y=310-350 | Pressed y=350-395
# ═══════════════════════════════════════════════════
# Main Menu buttons
Crop-And-Save "buttons\menu_240x48_normal.png"    424  270  138  40
Crop-And-Save "buttons\menu_240x48_hover.png"     424  310  138  40
Crop-And-Save "buttons\menu_240x48_pressed.png"   424  350  138  45

# Game Over buttons
Crop-And-Save "buttons\gameover_200x36_normal.png"   634  270  116  40
Crop-And-Save "buttons\gameover_200x36_hover.png"    634  310  116  40
Crop-And-Save "buttons\gameover_200x36_pressed.png"  634  350  116  45

# Upgrade buttons
Crop-And-Save "buttons\upgrade_320x50_normal.png"    766  270  110  40
Crop-And-Save "buttons\upgrade_320x50_hover.png"     766  310  110  40
Crop-And-Save "buttons\upgrade_320x50_pressed.png"   766  350  110  45

# ═══════════════════════════════════════════════════
# MEDIUM: Panels & Grimoire
# ═══════════════════════════════════════════════════
# Grimoire (left side book, ~390x210)
Crop-And-Save "medium\grimoire_800x600.png"         0  310  390  210

# Game Over panel (center-right)
Crop-And-Save "medium\gameover_panel_440x320.png"  634  310  242  130

# Upgrade Choice panel
Crop-And-Save "medium\upgrade_panel_360x280.png"   634  310  242  130

# Leaderboard panel (far right)
Crop-And-Save "medium\leaderboard_400x300.png"     766  310  234  130

# Close button (X)
Crop-And-Save "medium\close_btn_28.png"            850  390  30  30
Crop-And-Save "medium\close_btn_28_hover.png"      850  390  30  30

# ═══════════════════════════════════════════════════
# LOW: Effects
# ═══════════════════════════════════════════════════
Crop-And-Save "low\vortex_128.png"          870  415  130  130
Crop-And-Save "low\healthbar3d_64x12.png"   890  485   65   15

$src.Dispose()
Write-Output ""
Write-Output "All assets exported to art/HUD/"
