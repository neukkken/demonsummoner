---
name: release
description: Use when the user says "end of day", "release", "bump version", "cortar version", "nueva version", or "changelog" to bump the project version and update the changelog.
---

# Release Skill

Al ejecutarse:

1. Lee `project.godot` y extrae la versión actual de `config/version`.
2. Lee `CHANGELOG.md`.
3. Pregunta al usuario: **qué cambios hubo** (lista de cambios).
4. **Determina automáticamente el bump** según los cambios:
   - **patch** (0.0.X) — bugfixes, tweaks, refactors, optimizaciones, cambios cosméticos.
   - **minor** (0.X.0) — nuevas features, nuevas mecánicas, nuevos enemigos, nueva UI, new content.
   - **major** (X.0.0) — breaking changes, reworks grandes, cambios en sistema de guardado, cambios en API.
   - Si el usuario menciona explícitamente "major"/"minor"/"patch", respetar eso.
5. Muestra la versión resultante y pide confirmación antes de aplicar.
6. Actualiza `config/version` en `project.godot` con la nueva versión.
7. Agrega una entrada `## [NuevaVersión] - YYYY-MM-DD` al inicio de `CHANGELOG.md` con los cambios ingresados.
8. Si hay repo git, pregunta si quiere hacer `git add`, `git commit`, `git tag`.
