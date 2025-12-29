# Technical Specification: Demo Scenario "Chip Delivery"

This document provides the technical implementation details for the "Chip Delivery" demo scenario. It assumes the Hybrid ECS architecture defined in `architecture.md`.

## 1. Scenario Flow & System-Level Events

This sequence breaks down the demo's event flow and the systems responsible for each step.

1.  **Title Screen**:
    -   A `UI` scene (`TitleScreen.tscn`) displays scenario options.
    -   `GameStateSystem` reads the `/scenarios/` directory and populates the UI list. The only option will be "Chip Delivery".

2.  **Scenario Start**:
    -   Player selects "Chip Delivery".
    -   `GameStateSystem` loads the `scenario.json` from the `scenarios/chip_delivery/` directory.
    -   `GameStateSystem` loads the specified map (`exterior.tscn`) and spawns the player entity.
    -   `GameStateSystem` attaches the initial job resource (`report_to_kess.tres`) to the player's `PlayerStateComponent`.

3.  **Interact with Kess**:
    -   Player approaches Kess (an NPC entity).
    -   `InteractionSystem` detects player proximity and input.
    -   `InteractionSystem` triggers the `DialogSystem`, passing a reference to Kess's entity.
    -   `DialogSystem` loads the dialog tree from Kess's `NPCStateComponent`.
    -   `ObjectiveSystem` monitors the dialog progression. When the "Reported to Kess" dialog node is reached, it marks the first job as complete.

4.  **Accept "Chip Delivery" Job**:
    -   The dialog concludes with an option to accept a new job.
    -   Upon acceptance, `DialogSystem` adds the `chip_delivery.tres` job to the player's `PlayerStateComponent`.
    -   `SpawningSystem` is triggered by the new active job. It reads the job's objective list:
        -   It finds all `Marker3D` nodes with an `ObjectiveSpawnPointComponent` and `pool_name == "pickup"`.
        -   It randomly selects one and spawns a `chip_item.tscn` entity at its location.
        -   It finds all spawns with `pool_name == "delivery"` and randomly selects one as the delivery target.
        -   It updates the job's objective instances with these runtime targets.

5.  **Retrieve & Deliver Chip**:
    -   Player navigates to the pickup location.
    -   `InteractionSystem` handles the "take" action, moving the chip entity from the scene into the player's `InventoryComponent`.
    -   `ObjectiveSystem` detects the inventory change and marks the "retrieve" objective complete.
    -   Player navigates to the delivery location.
    -   `InteractionSystem` handles the "deliver" action at the target marker. This removes the chip from inventory.
    -   `ObjectiveSystem` marks the "deliver" objective complete.

6.  **Return to Kess & Demo End**:
    -   With all objectives done, `ObjectiveSystem` marks the `chip_delivery` job status as "Awaiting Turn-in".
    -   The player talks to Kess again. `DialogSystem` presents payment dialog.
    -   The job is marked `complete` in `PlayerStateComponent`.
    -   A UI prompt appears: "Demo Complete. Return to Title?"

## 2. Player Controls & Interaction Rules

### Input Map (Project Settings > Input Map)

Custom actions to add or confirm:

-   `move_forward`, `move_back`, `move_left`, `move_right`: `W/S/A/D`, Arrow keys
-   `look_x`, `look_y`: Mouse motion (camera yaw/pitch)
-   `sprint`: `Shift`
-   `interact`: `E`
-   `dialog_next`: `Space`, `Enter`
-   `dialog_choice_1`..`dialog_choice_4`: `1`..`4`

Built-in UI actions (already defined by Godot; just confirm bindings):

-   `ui_up`, `ui_down`: Arrow keys, `W/S`, gamepad left stick
-   `ui_accept`: `Enter`, `Space`, gamepad south button
-   `ui_cancel`: `Esc`

### Movement & Camera

-   **Movement model**: 3rd-person, camera-relative movement using `CharacterBody3D`. Default is walk; hold `sprint` for run. Keep movement grounded with slope limit and snap to floor enabled.
-   **Camera**: `SpringArm3D` + `Camera3D` follow camera. Mouse controls yaw/pitch; clamp pitch to avoid flipping (e.g., `-35` to `55` degrees). Camera collision enabled to avoid clipping through geometry.

### Interaction Detection & Prompt Rules

-   **Detection**: Player owns an `Area3D` sensor. Each frame, `InteractionSystem` gathers overlapping nodes with `InteractionComponent`, filters by distance (e.g., <= 2.5m), and ensures line-of-sight using a raycast from the camera to the candidate.
-   **Target selection**: Choose the nearest valid target; if distance ties, prefer the one closest to screen center.
-   **Prompt**: Show a single prompt when a target is selected. Format: `"[E] {interaction_prompt}"`. Hide when no valid target or when dialog UI is active.

### Item Pickup & Delivery Rules

-   **Pickup**: On `interact` with `chip_item.tscn`, remove or disable the item node, add its scene reference to `InventoryComponent.items`, and emit an `item_taken(item_id)` signal for `ObjectiveSystem`.
-   **Delivery**: On `interact` at a delivery marker, check for the chip in inventory. If present, remove it, emit `item_delivered(item_id, marker_id)`, and allow `ObjectiveSystem` to complete the delivery objective. If missing, show a short UI hint (e.g., "You need the chip.").

## 3. New Component Definitions

These components are `Resource` scripts (`.gd`) to be stored in `/components/`.

-   **`PlayerStateComponent.gd`**: Manages player-specific state.
    -   `active_jobs: Array[Job]`
    -   `completed_jobs: Array[Job]`
    -   `inventory: InventoryComponent`
-   **`NPCStateComponent.gd`**: Manages NPC-specific state.
    -   `dialog_tree: DialogTree` (a custom `Resource` for conversations)
    -   `offers_jobs: Array[Job]`
-   **`InventoryComponent.gd`**: Holds entity items.
    -   `items: Array[PackedScene]`
-   **`InteractionComponent.gd`**: Marks an entity as interactable.
    -   `interaction_prompt: String` (e.g., "Speak", "Take Chip")
-   **`ObjectiveSpawnPointComponent.gd`**: A tag for `Marker3D` nodes used by spawning logic.
    -   `pool_name: String` (e.g., "pickup", "delivery")

## 4. System Implementation Details

Logic for the primary `Autoload` systems.

-   **`InteractionSystem.gd`**:
    -   In `_process`, checks for player input and proximity to nodes with `InteractionComponent`.
    -   Emits signals to notify other systems (e.g., `start_dialog(npc_node)`, `item_taken(item_node)`).
-   **`DialogSystem.gd`**:
    -   Connects to `InteractionSystem` signals.
    -   Loads and displays UI for conversations based on a `DialogTree` resource.
    -   Manages the flow of conversation, job offers, and acceptance.
    -   Updates `PlayerStateComponent` and signals `ObjectiveSystem` on job-related events.
-   **`ObjectiveSystem.gd`**:
    -   Continuously scans entities with `PlayerStateComponent`.
    -   For each active job, it checks the completion criteria of its objectives against world state (e.g., item in inventory, signal from `DialogSystem`).
    -   Updates the status of `Job` and `Objective` resources.

## 5. UI Requirements

### Title Screen

-   **Layout**: Scenario list on the left, details pane on the right with scenario name and a short description. Show a single primary action button: "Start Demo".
-   **Population**: `GameStateSystem` provides scenario entries from `/scenarios/` using `scenario_name` in `scenario.json`.
-   **Navigation**: `ui_up`/`ui_down` to select, `ui_accept` to start, `ui_cancel` to exit (if supported by platform).
-   **Transition**: On confirm, fade out the UI, call `GameStateSystem` to load the map, then fade into gameplay.

### Dialog UI & Choice Flow

-   **Dialog box**: Bottom screen, left-aligned speaker name, body text centered in a readable box.
-   **Choices**: Present up to 4 choices with numeric labels (`1`..`4`) and highlight the current selection.
-   **Input**: `dialog_next` advances non-choice lines. Choices use `ui_up`/`ui_down` + `ui_accept` or number keys.
-   **Job surfacing**: When a dialog node offers/accepts a job, show a short toast (e.g., "Job Accepted: Chip Delivery").

### Job & Objective HUD

-   **Placement**: Top-left HUD panel with current job title and objective checklist.
-   **Updates**: When objectives complete, mark them with a check icon and briefly flash the line.
-   **Feedback**: Show a transient banner when the job status changes (e.g., "Objectives Complete — Return to Kess").

### "Demo Complete" Prompt

-   **Trigger**: Fired when `DialogSystem` emits the final completion event after `chip_delivery` is turned in.
-   **Modal**: Centered prompt with text: "Demo Complete" and subtext: "Return to title?" Buttons: "Return to Title" and "Quit".
-   **Behavior**: Locks player input behind the modal. `ui_accept` confirms the highlighted option; `ui_cancel` defaults to "Return to Title".

## 6. Resource & Scene Definitions

-   **/scenarios/chip_delivery/scenario.json**:
    ```json
    {
      "scenario_name": "Chip Delivery",
      "starting_map": "res://scenarios/chip_delivery/maps/exterior.tscn",
      "initial_player_jobs": ["res://scenarios/chip_delivery/jobs/report_to_kess.tres"]
    }
    ```
-   **/entities/Player.tscn**: A `CharacterBody3D` with a `ComponentHost` containing:
    -   `PlayerStateComponent` (with a nested, empty `InventoryComponent`)
-   **/entities/Kess_the_Fixer.tscn**: A `CharacterBody3D` with a `ComponentHost` containing:
    -   `NPCStateComponent` (referencing `chip_delivery_dialog.tres` and `chip_delivery.tres`)
    -   `InteractionComponent` (`interaction_prompt = "Speak"`)
-   **/entities/chip_item.tscn**: A `StaticBody3D` (or `Area3D`) with a `ComponentHost` containing:
    -   `InteractionComponent` (`interaction_prompt = "Take Chip"`)
-   **/jobs/report_to_kess.tres**: `Job` resource (script: `res://data/Job.gd`).
    -   `title: "Report to Kess the Fixer"`
    -   `objectives: [Objective resource for speaking to Kess]`
-   **/jobs/chip_delivery.tres**: `Job` resource (script: `res://data/Job.gd`).
    -   `title: "Chip Delivery"`
    -   `giver: "Kess the Fixer"`
    -   `objectives: [Objective resource for retrieve, Objective resource for deliver]`
-   **/ui/DialogBox.tscn**: Dialog UI layout for speaker text, choices, and job toasts.
-   **/ui/HUD.tscn**: Active job/objective panel.
-   **/ui/DemoCompletePrompt.tscn**: End-of-demo modal prompt.

### Quick Reference Paths

-   `res://scenarios/chip_delivery/scenario.json`
-   `res://scenarios/chip_delivery/maps/exterior.tscn`
-   `res://scenarios/chip_delivery/jobs/report_to_kess.tres`
-   `res://scenarios/chip_delivery/jobs/chip_delivery.tres`
-   `res://scenarios/chip_delivery/dialog/chip_delivery_dialog.tres`
-   `res://entities/Player.tscn`
-   `res://entities/Kess_the_Fixer.tscn`
-   `res://entities/chip_item.tscn`
-   `res://data/Job.gd`
-   `res://data/Objective.gd`
-   `res://data/DialogTree.gd`
-   `res://ui/TitleScreen.tscn`
-   `res://ui/DialogBox.tscn`
-   `res://ui/HUD.tscn`
-   `res://ui/DemoCompletePrompt.tscn`
-   `res://autoloads/GameStateSystem.gd`
-   `res://autoloads/SpawningSystem.gd`
-   `res://autoloads/InteractionSystem.gd`
-   `res://autoloads/DialogSystem.gd`
-   `res://autoloads/ObjectiveSystem.gd`
-   `res://components/PlayerStateComponent.gd`
-   `res://components/NPCStateComponent.gd`
-   `res://components/InventoryComponent.gd`
-   `res://components/InteractionComponent.gd`
-   `res://components/ObjectiveSpawnPointComponent.gd`

## 7. File Structure

The required file and directory structure for this demo is detailed in the main `architecture.md` document.

## 8. Editor vs Code Responsibilities

Use the Godot editor for scene setup and default resources; use code for runtime logic and state changes.

### Manual in Godot Editor

-   **Input Map**: Define the actions and default bindings in Project Settings.
-   **Scenes**: Build `Player.tscn`, `Kess_the_Fixer.tscn`, `chip_item.tscn`, and `TitleScreen.tscn` with their nodes and scripts.
-   **Autoloads**: Register `GameStateSystem`, `SpawningSystem`, `InteractionSystem`, `DialogSystem`, and `ObjectiveSystem` in Project Settings.
-   **Resources**: Create `.tres` assets for jobs, objectives, and dialog trees using `res://data/Job.gd`, `res://data/Objective.gd`, and `res://data/DialogTree.gd`.
-   **Map Markers**: Place `Marker3D` nodes with `ObjectiveSpawnPointComponent` on `exterior.tscn`.

### Implemented in Code

-   **Systems**: Runtime logic for spawning, interaction checks, dialog flow, and objective evaluation.
-   **Signals**: Emit and connect signals between systems (`item_taken`, `item_delivered`, dialog events).
-   **State Updates**: Modify `PlayerStateComponent`, `Job` status, and `Objective` instances at runtime.
-   **Target Resolution**: Resolve objective targets (marker selection, item refs) when a job activates.
