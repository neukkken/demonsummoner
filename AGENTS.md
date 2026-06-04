# Demon Summoner — Project Context

## Stack
- Godot 4.6.3, Direct3D 12, Forward+
- Todo procedural (sin assets externos): modelos 3D generados via código, texturas pixel-iteradas, UI construida en _ready()
- Sistema operativo: Windows, NVIDIA RTX 3050

## Convenciones Críticas
- **FBX no funciona** en D3D12 (valid=false). Usar GLTF o modelos procedurales vía SurfaceTool/ArrayMesh.
- **GPUParticles3D no renderiza** en D3D12. Usar MeshInstance3D + pool de nodos + tween, o CPUParticles3D.
- **MeshInstance3D no tiene `modulate`** en Godot 4. Para fade/color por instancia: `material_override` individual + tween sobre `albedo_color` y `emission_energy_multiplier`.
- **Evitar `create_tween()` en el nodo padre** para efectos que deben sobrevivir a `queue_free()`. Usar `piece.create_tween()` (dueño = la pieza).
- **Pool de nodos**: pre-crear MeshInstance3D con BoxMesh compartido y materiales estáticos, reciclar por `visible == false` o `scale.length_squared() < 0.001`.
- **Recursos estáticos**: materiales, meshes y shaders compartidos entre instancias vía `static var` para evitar crear/destruir en cada uso.

## Arquitectura

### Escenas
- `scenes/main_menu.tscn` → `world.tscn` → `scenes/main_menu.tscn` (loop)
- `world.tscn` contiene Player, WaveSpawner, escenario (CSGBox3D)

### Enemigos
- Spawneados por wave_spawner como hijos de `get_tree().root` (no de la escena).
- Grupo "enemies" para búsquedas y limpieza al morir.
- `tree_exited` conectado con `bind(instance_id)` y diccionario de XP (evita acceder a nodo en cleanup).
- Al morir el jugador: se limpian todos via `get_tree().get_nodes_in_group("enemies")`.

### Proyectiles
- Pool global compartido (140 MeshInstance3D, estático entre instancias).
- Materiales estáticos por tipo (fire_trail, ice_trail, fire_hit, ice_hit, ice_shard).
- Trail: `piece.create_tween()` → escala a 0 en 0.7s → callback esconde y recicla.

### Sistema de XP
- wave_spawner trackea `_total_xp` y `_xp_to_next` (escala ×1.3 por nivel).
- `_hud` se guarda en `_ready()` del spawner iterando `get_children()` del player.
- Al subir nivel: banner → pausa → panel de elección → reanuda.

### UI
- HUD, Channel UI, Game Over: todos CanvasLayer con `process_mode = PROCESS_MODE_ALWAYS`.
- Game Over se pausa (`get_tree().paused = true`) y muestra ratón (`MOUSE_MODE_VISIBLE`).
- Leaderboard: `user://leaderboard.json` con JSON, top 10 ordenado por nivel.

## Input Map (agregar en Proyecto → Mapa de Input)
```
move_forward, move_back, move_left, move_right   → movimiento WASD
element_fire, element_ice, element_necromancia    → seleccionar elemento (Space, Shift+R, R)
channel_spell                                      → mantener Shift + click der. para canalizar/gestos
ui_cancel                                          → Escape: pausa/menú
upgrade_slot_1..5                                  → teclas 1-5: elegir mejora al subir nivel
grimoire_toggle                                    → G: abrir/cerrar grimorio
```

## Stats Mejorables (al subir nivel)
| Stat   | Efecto              | Acumulación |
|--------|---------------------|-------------|
| FIRE   | +5 daño fuego       | fire_damage_bonus |
| ICE    | +5 daño hielo       | ice_damage_bonus  |
| HP     | +20 vida máxima     | max_health += 20  |
| MANA   | +20 maná máxima     | max_mana += 20    |
| REGEN  | +1 maná/s regeneración | mana_regen_rate += 1 |

## Archivos Clave
| Archivo | Rol |
|---------|-----|
| `scripts/player.gd` | Movimiento, hechizos, upgrades, muerte |
| `scripts/wave_spawner.gd` | Spawn enemigos, XP, trigger level-up |
| `scripts/gothic_hud.gd` | HUD completo (globos, hotbar, XP bar, level-up banner, choice panel) |
| `scripts/game_over.gd` | Pantalla muerte, leaderboard, botones retry/quit |
| `scripts/spell_projectile.gd` | Proyectil con pool de trail + impact |
| `scripts/wizard_wand.gd` | Varita procedural con trail pool |
| `scripts/channel_ui.gd` | UI de canalización con runas y trail pool |
| `scripts/mage_enemy.gd` | Gato mago: flota, dispara, black hole death |
| `scripts/dummy_enemy.gd` | Esqueleto: outline, animaciones FBX, ice death |
| `scripts/main_menu.gd` | Menú principal con background procedural + leaderboard |
| `scripts/ice_wall.gd` | Muro de hielo con frost particles |
| `scripts/grimoire_book.gd` | Grimorio procedural 800×600 con diagrama de invocación |

## Decisiones Técnicas Registradas
- Reemplazar `get_tree().is_inside_tree()` por `_player.is_inside_tree()` en callbacks post-mortem.
- `find_children("*", "CanvasLayer")` no funcionaba → usar `get_children()` directo.
- Las texturas procedurales se generan cada vez que se abre el menú/HUD (futuro: cachear a disco).
- El shader de anillo en channel_ui se crea una sola vez vía `static var`.
- Grimorio: `scenes/grimoire_book.tscn`, toggle con tecla **G**.
- `grimoire_book.gd` genera textura procedural 800×600: fondo madera + páginas pergamino + diagrama triángulo brillante + placeholders texto gótico.
- Labels sobrepuestos (no horneados en textura) para textos variables.
