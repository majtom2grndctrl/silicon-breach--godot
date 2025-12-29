# Repository Guidelines

## About Silicon Breach

Silicon Breach is a single player cyberpunk RPG where the city streets may stay the same, but what goes on is always changing. This initial demo focuses on a jobs system, but the game will expand to focus on infiltration, combat, hacking, and character progression.

In this game, **information is power** in a world where power is very unevenly distributed. Cybernetic augmentations are a key part of how players build their power, which in turn enables them to acquire information.

**Above all else:** Everything in this game should be `cyberpunk af`.

## Project Structure & Module Organization
- `project.godot` is the Godot 4.5 project entry.
- `docs/` holds design and architecture references (see `docs/architecture.md` and `docs/specs/`).

## Build, Test, and Development Commands
- Open the project in the Godot editor (4.5): select `project.godot`, then use the editor’s Run button to play the active scene.
- Optional CLI run (if Godot is installed in PATH): `godot --path .` opens the editor for this project.
- Check for GDScript errors (headless): `godot --headless --path . --check-only --quit`.
- No scripted build/test commands are present yet; add them to this file when introduced.

## Editor Setup Checklist
- Configure Input Map actions listed in `docs/specs/demo-spec.md` (movement, dialog, UI navigation).
- Register autoloads in Project Settings: `GameStateSystem`, `SpawningSystem`, `InteractionSystem`, `DialogSystem`, `ObjectiveSystem`.
- Assemble demo scenes in `res://entities/` and `res://ui/` (see `docs/specs/demo-spec.md` quick reference paths).
- Author `.tres` resources for jobs, objectives, and dialog trees under `res://scenarios/chip_delivery/`.

## Coding Style & Naming Conventions
- GDScript: 4-space indentation; avoid tabs.
- Prefer PascalCase for scene/resource files (e.g., `Player.tscn`, `HealthComponent.gd`) and snake_case for folders (e.g., `scenarios/chip_delivery/`).
- Keep data-only components as `Resource` scripts and keep game logic in autoload systems (per `docs/architecture.md`).
- Favor simple, readable code over clever abstractions.
- Use types where applicable (typed GDScript, typed arrays).

## Testing Guidelines
- No automated tests are defined in this repository yet.
- When adding tests, document the framework and a one-line run command here, and keep test files grouped under a dedicated `tests/` directory.

## Commit & Pull Request Guidelines
- No established commit convention yet (no git history). Use short, imperative summaries (e.g., “Add dialog system stubs”).
- PRs should include: a brief description, linked bd issue ID (if applicable), and screenshots/GIFs for UI or scene changes.
- Note any manual testing performed (scene name, steps).

## Agent-Specific Instructions
- This repo uses **bd** for issue tracking. Start with `bd onboard` and use `bd ready`, `bd show <id>`, and `bd update <id> --status in_progress`.
- End-of-session workflow must include `bd sync` and a successful `git push` (see `AGENTS.bd.md`).
