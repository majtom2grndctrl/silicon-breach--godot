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

## 2. New Component Definitions

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

## 3. System Implementation Details

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

## 4. Resource & Scene Definitions

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
-   **/jobs/report_to_kess.tres**: `Job` resource.
    -   `title: "Report to Kess the Fixer"`
    -   `objectives: [Objective resource for speaking to Kess]`
-   **/jobs/chip_delivery.tres**: `Job` resource.
    -   `title: "Chip Delivery"`
    -   `giver: "Kess the Fixer"`
    -   `objectives: [Objective resource for retrieve, Objective resource for deliver]`

## 5. File Structure

The required file and directory structure for this demo is detailed in the main `architecture.md` document.
