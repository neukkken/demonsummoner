# Changelog

## [0.7.0-alpha] - 2026-10-15

### Added
- **Generador de Ciudadela Gótica Monumental** (`scripts/generador_mapa.gd`):
  - **Escala Colosal**: Expansión de grilla a 7×7 celdas (~224m × 224m) con celdas de 32m y muros catedralicios de 18 metros de altura (`WALL_HEIGHT = 18.0`), empequeñeciendo intencionadamente al jugador (1.8m) dentro de una sobrecogedora arquitectura dark fantasy.
  - **3 Pisos de Elevación Extrema**: Tiers de elevación en $Y = 0.0$m (La Gran Nave y Criptas Bajas), $Y = 10.0$m (Bóvedas y Terrazas de Guardia) y $Y = 22.0$m (El Trono del Abismo y Cúspide Demoníaca).
  - **Columnatas y Nervios de Bóveda**: Columnas ciclópeas de 18m con plintos escalonados, fustes cilíndricos, capiteles góticos, nervios de crucería cruzados en techos y pebeteros de hierro forjado con llamas eternas de 18m de alcance omnidireccional.
  - **Arcadas Ojivales y Grandes Escaleras**: Puertas de paso de 7m de ancho por 11m de altura con tímpanos de piedra y molduras doradas; escaleras monumentales de 7m de ancho con rampas de colisión de 32° y pretiles de contención.
  - **Centros Monumentales**:
    - *Atrio / Spawn Hall*: Doble columnata de 8 titanes de 18m con crucería gótica y sello de obsidiana ceremonial.
    - *Santuario Demoníaco*: Monolito de obsidiana de 14m con núcleo luminoso amatista a 15m de altura, altar de piedra escalonado y anillo ceremonial de 8 columnas.
    - *Foso Abisal de Lava*: Caverna de 28m con grieta de magma de 26m × 14m y puente de piedra fortificado central de 7m con pretiles laterales.
  - **Atmósfera Gótica Acentuada**: Luz de luna azulada con sombras volumétricas y niebla baja (`volumetric_fog`) que desvanece las alturas de las columnas.
- **Overhaul Integral del HUD Gótico** (`scripts/gothic_hud.gd`):
  - **Integración Tipográfica Cinzel**: Incorporación sistemática de las fuentes auténticas `CinzelDecorative-Bold.ttf` (títulos, nivel, almas, jefes, atajos) y `Cinzel.ttf` (números de vida/maná, cronómetro, descripciones y barras).
  - **Orbes de Cristal Esféricos de 100px**: Reemplazo de los círculos planos por orbes volumétricos procedurales con gradiente esférico profundo, caústicas internas, arco especular de cristal curvado e insignias góticas doradas "HP" y "MP".
  - **Marcos de Relicario en Orbes**: Biseles metálicos biselados de bronce y oro con garras góticas en diagonales y alas de gárgola ornamentales.
  - **Relicario de Hechizos y Demonios**: Ranuras de 64px con marcos de obsidiana chamfered, filigranas de esquina doradas, sellos de teclas `[1]`, `[2]`, `[3]`, `[4]` y enfriamientos con tipografía de alto contraste.
  - **Barra de XP Monumental de 380px**: Barra de amatista luminosa con núcleo blanco, marco dorado con remaches y divisiones de progresión al 25%, 50% y 75%.
  - **Modal de Mejoras Dark Fantasy**:
    - Ventana modal centrada de 520×360 px con velo oscurecedor amatista.
    - Título gótico ceremonial `✦ ELEGIR BENDICIÓN ARCANO ✦` y subtítulo explicativo.
    - 3 Cartas arcanas alargadas (500×74 px) con marco de obsidiana, reborde dorado brillante al hacer hover, icono con ranura de relicario, título en CinzelDecorative, etiqueta de nivel `[ Nv. 1 → 2 ]`, descripción fluida y sello circular de acceso rápido `[1]`, `[2]`, `[3]`.
  - **Reloj y Estado de Almas**: Cronómetro centrado superior en plata antigua estilo reloj de catedral, contador de almas con glifo `✦ ALMAS: X/Y` y medidor de ritual del pentagrama con runas `⛧ RITUAL: ⬟ ⬟ ○`.
- **Cofres de Tesoro Interactivos** (`scripts/dungeon_chest.gd`): Modelo 3D procedural con tapa abisagrada animada mediante Tween, prompt flotante `[E] Abrir Cofre`, y recompensas (subida de nivel de item del `ItemManager`, gemas grandes de XP y orbes de curación expulsados físicamente).
- **Interacción con Tecla E** (`scripts/player.gd`): Soporte para interactuar con cofres y objetos del entorno.
- **Menú Principal RPG de Fantasía Oscura** (`scripts/main_menu.gd`):
  - Nuevo fondo panorámico cinematográfico (`sprites/rpg_menu_background.jpg`): Catedral gótica ancestral en ruinas con vórtice de invocación demoníaca, antorchas ardientes y luz de luna azul entrando por vidrieras.
  - Nuevo logotipo heráldico de Demon Summoner (`sprites/rpg_title_logo.png`): Tipografía gótica en obsidiana con grietas de magma volcánico, filigrana de oro y cuernos demoníacos estilizados.
  - Shader de resplandor y calor ígneo (`shaders/rpg_title_glow.gdshader`): Destellos dinámicos y pulso respiratorio sobre las runas y magma del logo sin necesidad de chroma key destructivo.
  - Botones de Menú Gothic Obsidian (`sprites/rpg_button_normal.png`, `hover`, `pressed`): Rediseño vectorial con piedra obsidiana chamfered, doble reborde dorado, remaches de rubí y 9-slice limpio (380×52 px) con 80 px de margen respecto al borde inferior.
  - Marco de Diálogos y Modales (`sprites/rpg_panel_frame.png`): Placa gótica simétrica de 500×500 px con filigranas de esquina y márgenes de 28 px que elimina el solapamiento de textos sobre ilustraciones.
  - Rediseño de Ventanas Modales: Títulos con línea divisoria dorada, tarjetas oscuras con bordes de categoría ("⚔️ Movimiento", "🔥 Hechizos", etc.) y botones de cierre amplios (220×44 px) con padding profesional.
  - Sigilo demoníaco giratorio (`sprites/rpg_sigil.png`) y partículas de ascuas flotantes 2D (`CPUParticles2D`).
  - Toggle de **Pantalla Completa** y ajustes de volumen con tipografía Cinzel y sliders estilizados.
  - Hover animado con escala suave en botones y marcadores rúnicos (`✧`).

### Performance
- **Caché Global de Animaciones FBX** (`scripts/asset_loader.gd`): Eliminado el lag y congelamiento durante el spawn de enemigos; las animaciones FBX se cargan y remapean una sola vez en memoria.
- **Optimización de GPU**: Eliminada la creación de decenas de `OmniLight3D` en gemas de almas (`scripts/alma_espectral.gd`) y suicidas (`scripts/suicide_enemy.gd`), apoyándose en materiales emisivos y Bloom.
- **Throttling de Pathfinding**: Actualizaciones de `NavigationAgent3D` reguladas cada 0.25–0.35s en lugar de ejecutarse cada tick de física.
- **Reutilización de Materiales**: Eliminada la instanciación repetitiva de `StandardMaterial3D` en impactos de proyectiles (`scripts/spell_projectile.gd`) y explosiones (`scripts/fire_blast_effect.gd`).
- **Física Ligera**: Sustitución de mallas triangulares complejas dinámicas (*Trimesh*) por colisiones primitivas de caja (`BoxShape3D`) y un único horneado de NavMesh al iniciar.

## [0.6.2-alpha] - 2026-06-12

### Added
- **Menú principal con arte**: fondo `Main menu bg 2.jpg` (paisaje nocturno con cuevas y luna), título `Title_bg_white.jpg` con shader chroma key que quita fondo blanco
- **Shader de fuego en título** (`shaders/title_chroma_key.gdshader`): efecto de llamas que suben desde el texto usando fbm procedural, degradado amarillo→naranja→rojo, parpadeo animado
- **Música del menú** (`music/main theme.mp3`): AudioStreamPlayer con fade in desde -40dB a -12dB en 2s, fade out al jugar
- **Recuadro "N"**: PanelContainer negro 60×60 abajo a la derecha con letra "N" blanca en cursiva monospace

### Changed
- Fondo del menú: `Main menu bg.jpg` → `Main menu bg 2.jpg`
- Título del menú: Logo PNG → `Title_bg_white.jpg` con transparencia via shader

## [0.6.1-alpha] - 2026-06-09

### Fixed
- **Grimorio desbordado** (`scripts/grimoire_book.gd`): el libro de invocaciones ahora escala proporcionalmente al viewport (factor `mini(vs.x/800, vs.y/600)`) para evitar que sus elementos se salgan de la pantalla en resoluciones menores a 800×600

## [0.6.0-alpha] - 2026-06-04

### Added
#### Enemigos
- **Arquero** (`scripts/archer_enemy.gd`): enemigo de rango con IA de 3 zonas (se acerca/strafear/retrocede). Flecha procedural con tracking. Cuerpo procedural (BoxMesh) por compatibilidad D3D12
- **Chamán** (`scripts/shaman_enemy.gd`): `Wizard.glb` que buffea enemigos cercanos (+50% speed/dmg, -30% shoot interval). Aura naranja pulsante. Aro naranja visible en enemigos buffeados. Proyectil de hielo con freeze (congela al jugador 2s)
- **Guardián** (`scripts/guardian_enemy.gd`): `Dwarf_Warrior.glb` tanque cuerpo a cuerpo 120 HP, 20 daño. Trail de ataque procedural. Shield eliminado — es un tanque de horda simple
- **Miniboss** (`scripts/miniboss_enemy.gd`): `Paladin.glb` 500 HP, 30 daño. Suelta 3 almas + 1 gema big azul (50 XP)

#### Sistema de Items VS (reemplaza stats mejorables)
- **ItemManager** autoload (`scripts/item_manager.gd`): 10 items con nivel máximo 10
- **Auto-weapons** visibles (3 items):
  - 🗡️ Almas dentadas: orbes rojos orbitando (1 por nivel), daño nivel×5 cada 0.5s
  - 🔮 Proyectil fantasma: cristal sobre hombro, dispara `spell_projectile` al enemigo más cercano cada 1.5s
  - 💀 Rastro de veneno: cubos verdes en el suelo que dañan enemigos al contacto
- **Pasivos** (7 items):
  - ❤️ Corazón de sangre (+30 HP/nivel)
  - ⚡ Batería arcana (+30 Maná +2 regen/nivel)
  - 👢 Botas de viento (+1.5 speed/nivel)
  - 🛡️ Armadura de sombra (+1 armadura/nivel)
  - 🧲 Imán de almas (+1 rango succión/nivel)
  - 📖 Grimorio antiguo (-20% coste maná/nivel)
  - 💎 Gema de experiencia (+25% XP/nivel)
- **HUD item grid**: cuadrícula 5×2 abajo a la derecha mostrando items y niveles
- **Panel de elección**: al subir nivel, elegir entre 3 items aleatorios con botones + teclas 1-3

#### Sistema de eventos de oleadas
- **⚠️ EL MURO** (5:00): spawnea miniboss 3× HP + 8 magos alrededor + banner + `play_dragon_roar`
- **🏁 EL FIN** (10:00): detiene spawn, guarda score con tiempo en leaderboard, game over automático
- **Spawn en bordes**: magos post-2min spawnean en bordes del mapa (55u)
- **Banner de eventos**: `show_event_banner()` para "EL MURO" y "EL FIN"

#### Nuevos hechizos (8 gestos, luego simplificados a FIRE/ICE básicos)
- FIRE: UP (bola), DOWN (explosión), RIGHT (bola rápida)
- ICE: UP (lanza), DOWN (muro), RIGHT (muro)
- Gestos extra removidos al implementar sistema VS

#### Mejoras de efectos necromancia (luego removidos con sistema VS)
- Drain: rayo rojo CylinderMesh entre enemigo→player + 15 gotas de sangre escalonadas + luz
- Soul Wall: 5 orbes púrpura pulsando + chispa al impactar + StaticBody3D (bloquean enemigos)
- Necro Explosion: 4 anillos púrpura expandiéndose + flash blanco + 30 partículas + luz
- Blood Barrier: escala 0→4 + 8 partículas orbitando
- Double Summon: círculo ritual TorusMesh en el suelo

#### Interfaz y calidad de vida
- **XP flotante en HUD**: texto "+X XP" junto a la barra de XP, se desvanece tras 0.8s
- **Tiempo de partida** guardado en leaderboard.json y mostrado en game over (`get_elapsed_str()`)
- **Item grid**: cuadrícula 5×2 con colores por tipo de item y nivel mostrado
- **Grimorio actualizado**: instrucciones de invocación con teclas F y R

### Changed
- **Suelo**: CSGBox3D (`size.y=0`) reemplazado por `StaticBody3D` + `BoxShape3D` — arregla bug crítico que lanzaba al jugador al spawnear
- **Paredes duplicadas**: eliminados Wall5/Wall6/Wall7 (idénticas a Wall2/Wall3/Wall4)
- **Mapa de teclas**:
  - **Space** → FIRE (gestos con Shift)
  - **Shift+R** → ICE (gestos con Shift)
  - **R** → Invocación directa (Segador)
  - **F** → NECROMANCIA (gestos con Shift) — luego removido con sistema VS
- **Devorador de Almas**: requisito 10→50 almas. Solo se invoca vía pentagrama (↑↓←↑↓), no más R directo
- **Necro-nube** → **Rastro de veneno**: esfera púrpura → cubos verdes trail
- **fire_blast_effect**: reducido de 53 a 28 piezas por cast
- **Orbes Almas dentadas**: radio 0.15→0.4, órbita 2.0→3.5, velocidad 2.0→1.5
- **ItemManager autoload**: registrado en project.godot, accesible vía `get_node("/root/ItemManager")`
- **apply_upgrade**: ahora recibe `item_id` de ItemManager en vez de strings de stat
- **mana_cost_mult** y **xp_mult** agregados al jugador (para items pasivos)

### Fixed
- **Floor CSGBox3D colisión degenerada** — jugador salía volando al spawnear. Reemplazado por StaticBody3D + BoxShape3D
- **timer_label nil** — creado en `_build_choice_panel()` en vez de `_refresh_choice_items()` (ejecutado muy tarde)
- **ItemManager compile error** — acceso vía `get_node("/root/ItemManager")` en vez de identificador global
- **_build_demon_bar missing** — función perdida durante refactor, re-agregada
- **Ghost projectile autodaño** — nacía en posición del jugador y se destruía contra sí mismo. Ahora nace 3u adelante en dirección al enemigo
- **Type inference errors** — variables con tipado explícito (`: Array`, `: Array[String]`)
- **Choice panel no se refrescaba** — separado `_refresh_choice_items()` para regenerar items cada nivel
- **Parse errors** — `ConeMesh`→`CylinderMesh`, `EXPAND_*`→constantes correctas, `PRESET_END`→`PRESET_BOTTOM_RIGHT`
- **Eliminados ~22 archivos .fbx** huérfanos (Characters + Weapons + Horror, ~50MB)
- **Miniboss ahora ataca** — sistema de Area3D hitbox + distance check inmediato + cooldown 0.8s

### Removed
- **Stats mejorables** (FIRE, ICE, HP, MANA, REGEN, VEL, DAÑO, RANGO, ARMADURA, ROBO) — reemplazados por items VS
- **Hechizos NECRO y diagonales** — eliminados del match de `cast_spell()`, solo quedan FIRE/ICE básicos
- **NECRO+RIGHT gesture** — R ahora invoca directamente, no selecciona NECROMANCIA
- **Necro-cloud** — reemplazado por Rastro de veneno
- **FBX huérfanos** — borrados modelos sin usar (Characters + Weapons + Horror .fbx)

## [0.5.1-alpha] - 2026-06-04

### Added
- **Nuevo enemigo: Guardián** (Dwarf_Warrior.glb + Hero_Shield_01.glb)
  - Tanque cuerpo a cuerpo con 120 HP y escudo direccional
  - Bloquea 100% daño frontal (cono 150°): chispa blanca + sonido metal
  - Daño lateral reducido 50%, daño trasero 100%
  - Shield attachado a mixamorig_LeftHand del skeleton
  - Animaciones FBX idle/walk/attack/die
  - Escudo de maná: semiesfera translúcida azul al frente, visible solo desde el frente
  - Escudo absorbe daño frontal (50 HP), se rompe con 25 partículas + luz, cooldown 5s
  - Pulso del escudo (escala 1.0↔1.05) mientras está activo
  - Vulnerable por detrás: el escudo no protege
  - Eliminado shield GLB (no funcionaba en D3D12)
  - Desbloqueo a los 150s, XP=20
- **Nuevo enemigo: Chamán** (Wizard.glb)
  - Buffea enemigos cercanos: +50% velocidad, +50% daño, -30% cadencia
  - Aura naranja pulsante visible (SphereMesh semitransparente)
  - Proyectil débil (8 daño, misma pool que mage)
  - IA: se acerca a aliados para buffearlos, huye si está solo
  - Animaciones FBX (idle/walk/attack/die) con remapeo Mixamo
  - Desbloqueo a los 90s, XP=12
- **Suelo CSGBox3D → StaticBody3D**: arreglado bug crítico de colisión que lanzaba al jugador
- **Flags de spawn por enemigo**: enable_melee/mage/suicide/archer/shaman toggleables desde inspector
- **Nuevo enemigo: Arquero** (Elf_Archer.glb + Hero_Bow.glb)
  - IA con 3 zonas: se acerca si lejos, strafea+dispara en rango medio, retrocede si cerca
  - Flecha procedural (BoxMesh + ConeMesh) con movimiento físico y colisión
  - Arco visible (Hero_Bow.glb) attachado al hueso de la mano derecha
  - Health bar, drop de alma al morir, soporte de freeze/parálisis
  - Desbloqueo a los 60s, escala por nivel (daño + cadencia)
- `scripts/archer_enemy.gd` — lógica completa del arquero
- `scripts/arrow_projectile.gd` — proyectil flecha con velocidad
- `scenes/archer_enemy.tscn` — escena del arquero

### Removed
- Carpeta `models/Dragon/` completa (no referenciada, ~40MB, 2 .glb + 1 .fbx)

## [0.1.0-alpha] - 2026-06-01

### Added
- Movimiento WASD del jugador con varita procedural
- Sistema de canalización de hechizos (fuego/hielo)
- Pool de proyectiles con trail y efecto de impacto
- Enemigos: esqueleto (dummy) y gato mago (mage)
- Wave spawner con progresión de oleadas
- Sistema de experiencia y subida de nivel con 5 stats mejorables
- HUD gótico con globos de vida/maná, hotbar, barra de XP, banner y panel de elección
- UI de canalización con runas
- Pantalla de Game Over con leaderboard local (JSON)
- Menú principal con fondo procedural y leaderboard
- Muro de hielo como habilidad defensiva
- Escenario con CSGBox3D y skybox procedural

## [0.2.0-alpha] - 2026-06-02

### Added
- Sistema de invocación (sacrificio de sangre): cubo rojo que ataca enemigos
- Vórtice de sangre: área de efecto que daña y atrae enemigos
- Elemento NECROMANCIA con color rojo sangre en canalización y varita
- Push de enemigos al invocar

### Changed
- Limpieza de assets de modelo de demonio (no compatibles con D3D12)
- Refactor de animaciones a procedurales (bob, sway, squash/stretch)

### Fixed
- Push de enemigos con fuerza reducida para evitar clipping
- Proyectiles de hielo ahora atraviesan muros de hielo

## [0.3.0-alpha] - 2026-06-02

### Added
- Grimorio procedural 800×600 con diagrama de invocación
- Invocación de sangre: demonio cubo rojo con 300 HP, 30s de duración
- Cooldown de 60s entre invocaciones
- Vórtice de sangre completo: textura procedural, shards, partículas, haz de luz, atracción de enemigos
- Enemigos pueden atacar al summon (target prioritario)
- Animaciones procedurales: flote, balanceo, respiración, cast con squash/stretch
- Label3D con contador de tiempo restante del summon

### Changed
- Proyectiles de hielo atraviesan muros de hielo
- Push de enemigos reducido para evitar clipping

### Removed
- Assets de modelo de demonio FBX/OBJ (incompatibles con D3D12)
- Escena grimoire_book.tscn y scripts asociados

## [0.4.0-alpha] - 2026-06-03

### Added
- Segundo demonio: **Devorador de Almas** (Soul Feeder)
  - Invocación mediante pentagrama (→↑←↓→) con NECROMANCIA + 10 almas
  - Festín del Inframundo: grietas, espinas, pilares de energía, haz de luz y explosión masiva
  - Daño pulsante cada 0.5s a todos los enemigos durante 4s
  - Almas de curación (verde/dorado) que vuelan al jugador al morir (10% HP + 15% maná cada una)
- **Sistema de almas**: orbes blancos que flotan 0.5s y vuelan magnéticamente al jugador
  - Cada enemigo suelta un alma al morir
  - Contador global `DatosJuego` con autoload y señal para el HUD
- **Efecto de ritual**: oscurecimiento gradual de todas las luces + ambiente + niebla volumétrica
  - Volumetric fog emission cambia a rojo sangre durante la habilidad
  - Restauración completa al valor original al terminar
- **Mapa procedural 120×120**: 10-15 pilares góticos con antorchas en posiciones aleatorias
  - CSGBox3D con colisión (proyectiles chocan)
  - Distancia mínima entre pilares y zona de spawn segura
- **Sistema de escalado por nivel**:
  - Enemigos ganan +15% HP y +10% daño por nivel
  - Spawn rate exponencial (3s base → 0.8s mínimo)
  - Múltiples enemigos por tick (1 + nivel/3, máximo 5)
  - Esqueletos más rápidos, magos disparan más rápido
- Hotbar con 4 hechizos + 2 demonios y cooldowns visibles
- Segador de Escarcha ahora se invoca con NECROMANCIA + RIGHT siempre (sin condiciones)

### Changed
- Pentagrama cambiado a (↑↓←↑↓) para no competir con el gesto RIGHT
- Devorador de Almas nace en el centro del mapa (no sigue al jugador)
- WaveSpawner escala por nivel del jugador (no por timer de dificultad)
- Mapa expandido de 60×60 a 120×120 (suelo, paredes, bounds de spawn)
- RIGHT con FIRE/ICE ahora lanza hechizo (explosión/muro) en vez de invocar
- "REQUISITO_DEVORADOR" vuelve a 10 almas tras pruebas

### Fixed
- Error "get_meta on freed instance" en loops de limpieza de festin_root
- Error "get_meta key angle" en _process (rings temporales sin meta)
- Error "!is_inside_tree()" al spawnear alma en muerte de enemigo (posición pasada por parámetro)
- Parse error por variable y función con mismo nombre `_pulse_damage`
- HUD no encontraba al wave_spawner por orden de _ready() (ahora se notifica explícitamente)

### Removed
- Sistema de tracking de almas en wave_spawner (reemplazado por DatosJuego + alma_espectral física)
- Script `soul_orb.gd` (reemplazado por `alma_espectral.gd`)
- Timer de dificultad fijo (reemplazado por escalado por nivel)

## [0.5.0-alpha] - 2026-06-04

### Added
- **AudioManager** (autoload): 20 sonidos procedurales generados con `AudioStreamWAV` (seno/square/ruido/LFO)
  - UI: click, hover, error, level up, element select, pentagram tick/complete, grimoire open/close
  - Jugador: fireball, ice lance, ice wall, channel, hit
  - Summons: summon spawn/death, XP gain, wave spawn, game over
- **Proyectiles con tracking**: auto-aim + seguimiento continuo hacia el target
- **8 direcciones de gestos** (UP_RIGHT, DOWN_RIGHT, UP_LEFT, DOWN_LEFT)
- **3 nuevos hechizos**: Ráfaga triple (FIRE+UP_RIGHT), Explosión de Escarcha (ICE+DOWN_RIGHT), Barrera de Sangre (NECRO+UP)
- **5 nuevas mejoras**: VEL (+0.5 walk_speed), DAÑO (+3 todos proyectiles), RANGO (+2m auto-aim), ARMADURA (-5% daño recibido, max 10), ROBO (+5% daño→vida, max 50)
- **Wave spawner VS-style**: spawn desde bordes, escalado por tiempo (10 min), eventos por tiempo
- **Suicide enemy**: enemigo rojo pulsante que explota al morir (radio 3u, 25 daño)
- **Mage cat como élite**: HP 80→240, daño 15→20, shoot rate más rápido
- **Timer visible** en HUD (M:SS, cambia a rojo al último minuto)
- **XP gems**: 3 colores (blanca/azul/verde), succión a 10u, pulso, flotación, glow brillante
  - Al recolectar: texto "+10 XP"/"+50 XP"/"CURA" flotante grande (48px)
- **Pentagrama** alimentado por gemas (cada 3 gems → +1 alma → Devorador)
- **Summons escalan con nivel**: Segador (HP 300×1.1, cooldown 30s), Devorador (daño 35×1.15, duración 6s)
- **Lifesteal**: `_on_projectile_hit()` para robo de vida
- TODO.md con lista de pendientes
- Logo en menú principal: `sprites/Logo DEMON-SUMMOER.png` reemplaza texto "DEMON SUMMONER"

### Changed
- Wave spawner: spawn desde bordes continuo (antes oleadas por intervalo)
- Auto-aim range: 30→50u, ángulo: 20→35°
- Proyectiles: radio colisión 0.15→0.5
- Sacrificio de sangre: coste 30%→20% HP, cooldown 60s→30s
- Gesture recognizer: 4→8 direcciones (ángulos corregidos)
- Gema alma: radio 0.15→0.4, trail removido, bright + float + pulse añadidos
- XP bar: ahora usa texturas procedurales (antes styleboxes)
- Icono de la aplicación: `icon.svg` → `sprites/Logo DEMON-SUMMOER.png`

### Fixed
- Parse error por `if cond: return` en una línea (Godot 4 no lo permite)
- Parse error por tab en `var mana_costs := {` a nivel de clase
- Gestos invertidos (UP↔DOWN, UP_RIGHT↔DOWN_RIGHT)
- `find_child("*", "OmniLight3D")` → `find_child("OmniLight3D")` en ice explosion
- `launch_triple_shot()` pasaba daño 0.7 en vez de 25*0.7
- Eliminado `alma_curacion.gd` (reemplazado por xp_gem gemas verdes)
- Eliminado `xp_gem.gd` (redundante con alma_espectral.gd)
- `preload("alma_curacion.gd")` en soul_feeder cambiado a runtime load

### Removed
- `scripts/xp_gem.gd` (redundante con alma_espectral.gd)
- `scripts/alma_curacion.gd` (reemplazado por gemas verdes de alma_espectral)
- `icon.svg`, `icon.svg.import` (reemplazado por logo PNG)
