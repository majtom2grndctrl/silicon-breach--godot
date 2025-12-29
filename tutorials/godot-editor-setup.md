# Godot Editor Setup (for this repo)

This repo is a standard Godot 4.5 project. The scaffolding exists in `res://autoloads/`, `res://entities/`, `res://components/`, `res://ui/`, and `res://scenarios/`.

## 1) Open the project

- Launch Godot 4.5.
- **Import** the folder that contains `project.godot` (repo root).

## 2) Set the main scene (so “Play” works)

- Open `res://ui/TitleScreen.tscn`.
- Go to **Project → Project Settings → Application → Run → Main Scene** and set it to `res://ui/TitleScreen.tscn`.
- Press **Play (F5)** to confirm the project runs (it will be a static UI scaffold for now).

## 3) Register Autoload systems (singletons)

Godot doesn’t “discover” autoloads from folders; you must register them in the editor:

- **Project → Project Settings → Autoload**
- Add and enable each script below, using the same **Name** as the filename/class:
  - `res://autoloads/GameStateSystem.gd` → `GameStateSystem`
  - `res://autoloads/SpawningSystem.gd` → `SpawningSystem`
  - `res://autoloads/InteractionSystem.gd` → `InteractionSystem`
  - `res://autoloads/DialogSystem.gd` → `DialogSystem`
  - `res://autoloads/ObjectiveSystem.gd` → `ObjectiveSystem`

After this, these nodes exist globally at runtime as `/root/GameStateSystem`, etc.

## 4) Confirm the Input Map

You’ll define custom gameplay actions, while `ui_*` actions already exist in Godot.

- **Project → Project Settings → Input Map**
- Ensure these custom actions exist and have bindings (keyboard + gamepad where relevant):
  - `move_forward`, `move_back`, `move_left`, `move_right`
  - `look_x`, `look_y` (mouse motion)
  - `sprint`
  - `interact`
  - `dialog_next`
  - `dialog_choice_1`, `dialog_choice_2`, `dialog_choice_3`, `dialog_choice_4`
- Confirm built-in actions have sensible bindings:
  - `ui_up`, `ui_down`, `ui_accept`, `ui_cancel`

Keep the authoritative list in `docs/specs/demo-spec.md`.

## 5) Wire “component data” onto entities (inspector authoring)

Entities use `ComponentHost` (already attached on the scaffold scenes). Author the component resources via the Inspector:

### Player

- Open `res://entities/Player.tscn`
- Select root `Player` node (has `ComponentHost` script).
- In `components_list`, add:
  - New `PlayerStateComponent` resource
    - On that resource, set `inventory` to a new `InventoryComponent` resource

### Kess (NPC)

- Open `res://entities/Kess_the_Fixer.tscn`
- In `components_list`, add:
  - New `NPCStateComponent` resource (you can leave `dialog_tree` empty until `DialogTree` exists)
  - New `InteractionComponent` resource with `interaction_prompt = "Speak"`

### Chip item

- Open `res://entities/chip_item.tscn`
- In `components_list`, add:
  - New `InteractionComponent` resource with `interaction_prompt = "Take Chip"`

## 6) Add objective spawn markers to the map

Markers are just `Marker3D` nodes with `ComponentHost` + `ObjectiveSpawnPointComponent`.

- Open `res://scenarios/chip_delivery/maps/exterior.tscn`
- Add two `Marker3D` nodes:
  - `PickupSpawn`
  - `DeliverySpawn`
- For each marker:
  - Attach `res://entities/ComponentHost.gd`
  - Add a new `ObjectiveSpawnPointComponent` to `components_list`
  - Set `pool_name` to `pickup` on `PickupSpawn`, and `delivery` on `DeliverySpawn`

## 7) UI scene placeholders (optional sanity check)

These are scaffolded and can be opened/edited now:

- `res://ui/TitleScreen.tscn`
- `res://ui/DialogBox.tscn`
- `res://ui/HUD.tscn`
- `res://ui/DemoCompletePrompt.tscn`

## What’s next

Once the editor setup above is done, the next step is implementing runtime behavior (systems + `ComponentHost` API) while keeping code simple and typed (see `docs/architecture.md` and `AGENTS.md`).
