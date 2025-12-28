# Repository Guidelines

## Project Structure & Module Organization
- `project.godot` is the Godot 4.5 project entry.
- `docs/` holds design and architecture references (see `docs/architecture.md` and `docs/specs/`).

## Build, Test, and Development Commands
- Open the project in the Godot editor (4.5): select `project.godot`, then use the editor’s Run button to play the active scene.
- Optional CLI run (if Godot is installed in PATH): `godot --path .` opens the editor for this project.
- No scripted build/test commands are present yet; add them to this file when introduced.

## Coding Style & Naming Conventions
- GDScript: 4-space indentation; avoid tabs.
- Prefer PascalCase for scene/resource files (e.g., `Player.tscn`, `HealthComponent.gd`) and snake_case for folders (e.g., `scenarios/chip_delivery/`).
- Keep data-only components as `Resource` scripts and keep game logic in autoload systems (per `docs/architecture.md`).

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
