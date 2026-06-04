# Changelog

## [0.1.0] - 2026-06-01

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

## [0.2.0] - 2026-06-02

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

## [0.3.0] - 2026-06-02

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
