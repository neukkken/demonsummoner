# TODO — Demon Summoner

## Enemigos (pendientes)
- [x] **Arquero** — enemigo de rango con proyectil con tracking
- [x] **Chamán** — buffea enemigos cercanos (+vel, +daño)
- [x] **Guardián** — tanque de horda cuerpo a cuerpo (Dwarf_Warrior, 120 HP)
- [ ] **Élite** — cualquier enemigo con 3× HP y 2× daño (actualmente solo mage)
- [x] **Miniboss** — Paladín 500 HP (evento El Muro a 5:00)
- [ ] **Horda** — evento cada 7 min (10-15 suicidas o melees)

## Eventos del timer (wave_spawner)
- [x] Miniboss a los 5:00 (El Muro)
- [ ] Horda a los 7:00
- [x] El Fin a los 10:00 (game over automático)

## Jugador
- [x] Más poderes para gestos diagonales (8/8 direcciones implementadas)
- [ ] Sistema de evolución de armas (nivel 8 → desbloquear poder mejorado)

## UI
- [x] Guía y controles accesibles (menú principal y pausa)
- [ ] Indicador de oleada especial (horda/miniboss)

## Audio
- [ ] Música de fondo procedural (loop con senos + ruido)

## Bugs conocidos
- [x] Las gemas azules (big) ahora se generan y expulsan desde cofres de tesoro

## Rendimiento
- [x] Pool y reutilización de MeshInstance3D y StandardMaterial3D (sin lag en hordas)
- [x] Revisar `fire_blast_effect.tscn` — optimizado con recursos estáticos compartidos
- [x] Caché global de animaciones FBX para enemigos humanoides
- [x] Eliminada sobrecarga de luces OmniLight3D en gemas y suicidas
- [x] Sustitución de mallas de colisión Trimesh por BoxShape3D ultrarrápido en mazmorras

## Calidad de vida
- [ ] Mostrar tiempo de partida al morir (game over)
- [ ] Mostrar nivel alcanzado y enemigos derrotados al morir
