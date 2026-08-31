<div align="center">

# DEMON SUMMONER

**Sobrevive a la horda. Invoca demonios. Conviértete en leyenda.**

Un *survivors-like* gótico hecho en **Godot 4** con assets 100% procedurales — sin un solo archivo de arte externo en el gameplay.

**Versión actual:** `0.6.2-alpha` · **Motor:** Godot 4.6+ (Forward+ / D3D12) · **Plataforma:** Windows

</div>

---

## ¿Qué es?

Demon Summoner es un juego de supervivencia de hordas en arena. Controlas a un mago en un escenario gótico nocturno, lanzas hechizos de fuego y hielo, recolectas almas y experiencia, y mejoras con un sistema de *items* estilo Vampire Survivors mientras oleadas de esqueletos, magos, arqueros, chamanes y demonios intentan matarte.

**La guinda:** cada 10 minutos, el juego termina solo. Sobrevive lo máximo, acumula la mayor puntuación y compite contra ti mismo en el leaderboard local.

---

## Características

### Combate
- **3 elementos** con gestos de canalización: **Fuego**, **Hielo** y **Necromancia** (invocación)
- Hechizos con **tracking automático**, explosiones, muros de hielo y proyección con trail
- **Canalización de hechizos**: mantén Shift + clic derecho y dibuja el gesto con el ratón
- Pool de proyectiles reutilizado (140 instancias) — sin lag con hordas enormes

### 💀 Sistema de Items VS
Al subir de nivel eliges entre 3 items aleatorios (máximo nivel 10):

| Tipo | Item | Efecto por nivel |
|------|------|------------------|
| Auto-arma | **Almas dentadas** | Orbes rojos orbitando, daño nivel×5 |
| Auto-arma | **Proyectil fantasma** | Cristal que dispara al enemigo más cercano |
| Auto-arma | **Rastro de veneno** | Cubos de veneno en el suelo |
| Pasivo | **Corazón de sangre** | +30 HP máx. |
| Pasivo | **Batería arcana** | +30 maná y +2 regen |
| Pasivo | **Botas de viento** | +1.5 velocidad |
| Pasivo | **Armadura de sombra** | +1 armadura |
| Pasivo | **Imán de almas** | +1 rango de succión |
| Pasivo | **Grimorio antiguo** | -20% coste de maná |
| Pasivo | **Gema de experiencia** | +25% XP |

### Enemigos

| Enemigo | Descripción | Desbloqueo |
|---------|-------------|------------|
| **Esqueleto** | Tanque cuerpo a cuerpo básico | Inicio |
| **Gato mago** | Flota y dispara proyectiles (élite: 3× HP) | Inicio |
| **Suicida** | Explota al morir (25 daño en radio 3u) | +30s |
| **Arquero** | IA de 3 zonas: persigue, strafea, retrocede | +60s |
| **Chamán** | Buffea enemigos cercanos (+50% vel/daño) | +90s |
| **Guardián** | Tanque con escudo direccional (150° frontal) | +150s |
| **Miniboss** | Paladín 500 HP, suelta 3 almas + gema grande | Evento |

### Eventos de oleada
- ** EL MURO (5:00)** — Miniboss gigante (3× HP) + 8 magos alrededor
- ** EL FIN (10:00)** — Se detiene el spawn y se guarda tu puntuación

### Técnica
- **100% procedural**: modelos 3D generados con `SurfaceTool`/`ArrayMesh`, texturas pixel-iteradas, UI construida en `_ready()`
- **Sin assets externos**: todo el arte, audio y shaders se generan con código
- Compatible con **Direct3D 12 / Forward+** (FBX y GPUParticles no renderizan → se evitan deliberadamente)

---

## Controles

| Acción | Tecla |
|--------|-------|
| Movimiento | `W A S D` |
| Seleccionar Fuego | `Espacio` |
| Seleccionar Hielo | `Shift + R` |
| Invocar Segador | `R` |
| Canalizar hechizo | `Shift` + clic derecho (mantener) |
| Pausa / Menú | `Escape` |
| Elegir item al subir nivel | `1 2 3` |
| Abrir/Cerrar Grimorio | `G` |

---

## Estructura del proyecto

```
demon-summoner/
├── scenes/          # Escenas .tscn (menú, mundo, enemigos, proyectiles)
├── scripts/         # Lógica GDScript (player, enemigos, HUD, spawner...)
├── shaders/         # Shaders procedurales (fuego, chroma key, cielo)
├── sprites/         # Logo y arte del menú
├── art/             # Arte 2D adicional
├── music/           # Música del menú
├── materials/       # Materiales compartidos
├── textures/        # Texturas procedurales
├── tools/           # Utilidades
├── CHANGELOG.md     # Historial completo de versiones
├── TODO.md          # Roadmap y pendientes
└── project.godot    # Configuración del proyecto
```

### Archivos clave

| Archivo | Rol |
|---------|-----|
| `scripts/player.gd` | Movimiento, hechizos, upgrades, muerte |
| `scripts/wave_spawner.gd` | Spawn de enemigos, XP, eventos, level-up |
| `scripts/item_manager.gd` | Sistema de items VS (autoload) |
| `scripts/gothic_hud.gd` | HUD completo (globos, hotbar, XP, elección) |
| `scripts/game_over.gd` | Pantalla de muerte + leaderboard JSON |
| `scripts/channel_ui.gd` | UI de canalización con runas y trail |
| `scripts/main_menu.gd` | Menú principal procedural |

---

## Cómo jugar

### Requisitos
- **Godot 4.6+** (modo compatibilidad opcional si tu GPU no soporta Forward+)

### Pasos
1. Clona el repositorio:
   ```bash
   git clone https://github.com/neukkken/demonsummoner.git
   ```
2. Abre `project.godot` con Godot 4.6+
3. Presiona **F5** (o ejecuta la escena `scenes/main_menu.tscn`)

> **Nota D3D12:** en Windows usa el renderer **Forward+** con **Direct3D 12**. No se usan FBX ni GPUParticles3D porque no renderizan en esa configuración — todo es procedural.

---

## Changelog

El historial completo está en [`CHANGELOG.md`](CHANGELOG.md). Resumen:

- **0.6.2-alpha** — Menú con arte (fondo nocturno, título con shader de fuego), música con fade, recuadro "N"
- **0.6.1-alpha** — Grimorio escalable a cualquier resolución
- **0.6.0-alpha** — Sistema de items VS (10 items), arquero/chamán/guardián/miniboss, eventos EL MURO y EL FIN, fix crítico de colisión del suelo
- **0.5.1-alpha** — Guardián con escudo direccional, chamán buffeador, arquero con IA de 3 zonas
- **0.5.0-alpha** — AudioManager procedural, 8 direcciones de gesto, gemas XP, enemigo suicida
- **0.4.0-alpha** — Devorador de Almas, sistema de almas, mapa procedural 120×120
- **0.3.0-alpha** — Grimorio, invocación de sangre, vórtice de sangre
- **0.2.0-alpha** — Necromancia, vórtice de sangre, animaciones procedurales
- **0.1.0-alpha** — Base: movimiento, hechizos, HUD, wave spawner

---

## Roadmap

Pendientes en [`TODO.md`](TODO.md):

- [ ] Sistema de evolución de armas (nivel 8 → poder mejorado)
- [ ] Evento Horda (7:00) y enemigos Élite (3× HP)
- [ ] Música procedural en bucle
- [ ] Pool de partículas para reducir lag
- [ ] Indicador de oleada especial en HUD

---

## Leaderboard

Las puntuaciones se guardan localmente en `user://leaderboard.json` (top 10 por nivel y tiempo de partida).

---

## Notas de desarrollo

- **Godot 4.6.3 · Direct3D 12 · Forward+** · RTX 3050
- Las texturas procedurales se regeneran al abrir menús/HUD (futuro: cachear a disco)
- Materiales, meshes y shaders compartidos vía `static var` para minimizar asignaciones

<div align="center">

*Hecho con opencode.*

</div>
