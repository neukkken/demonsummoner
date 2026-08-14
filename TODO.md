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
- [ ] Menú de pausa: reactivar guía de invocaciones (segador + devorador)
- [ ] Indicador de oleada especial (horda/miniboss)

## Audio
- [ ] Música de fondo procedural (loop con senos + ruido)

## Bugs conocidos
- [ ] Las gemas azules (big) spawnean pero nadie las crea actualmente

## Rendimiento
- [ ] Pool de MeshInstance3D para partículas y efectos (reducir lag con muchos enemigos)
- [ ] Revisar `fire_blast_effect.tscn` — crea 53 MeshInstance por uso

## Calidad de vida
- [ ] Mostrar tiempo de partida al morir (game over)
- [ ] Mostrar nivel alcanzado y enemigos derrotados al morir
