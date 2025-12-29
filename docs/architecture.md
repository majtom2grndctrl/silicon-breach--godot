# Godot Hybrid ECS Architecture

This document outlines the technical architecture for a 3D cyberpunk RPG built with the Godot Engine. The architecture uses a "Hybrid ECS" pattern, blending Godot's node-based scene tree with core Entity-Component-System (ECS) principles for data management and game logic.

This design is intended for agentic coding tools. It uses clear, concise language and is token-efficient while providing enough detail to implement the architecture.

## 1. Core Concepts: Hybrid ECS

The architecture avoids a pure ECS implementation in favor of a hybrid model that leverages Godot's strengths.

-   **Components as Resources**: Components are data containers, implemented as Godot `Resource` objects (`.gd` scripts extending `Resource`). They hold data but no logic (e.g., `HealthComponent`, `PositionComponent`). These are saved as `.tres` files.
-   **Entities as Nodes**: Entities are represented by Godot `Node`s or full `PackedScene` instances within the scene tree. Any Node meant to act as an entity will have a `ComponentHost.gd` script attached. This script manages a dictionary of the components associated with that entity.
-   **Systems as Autoloads**: Game logic is implemented in "Systems," which are GDScript files registered as Godot Autoload singletons. These systems run globally and operate on entities by iterating through the scene tree, finding nodes with a `ComponentHost`, and processing their components.

### Implementation Guidelines

-   Favor simple, readable code over clever abstractions.
-   Use types where applicable (typed GDScript, typed arrays) to keep intent clear.

### ComponentHost API and Conventions

`ComponentHost.gd` is the single source of truth for component storage and lookup on an entity node.

-   **Storage**: Components are stored in a dictionary keyed by component type (use the script `class_name` or script path as the key, e.g., `HealthComponent`).
-   **Initialization**: Expose an exported array of `Resource` components for authoring in the inspector. On `_ready`, register each component into the dictionary.
-   **Access**: Provide helpers like `has_component(type_name)`, `get_component(type_name)`, `add_component(resource)`, and `remove_component(type_name)` for systems to use.
-   **Signals**: Emit `component_added(component)` and `component_removed(type_name)` so systems can react without polling when needed.
-   **Usage**: Systems should never reach into component arrays directly; always resolve via `ComponentHost` to keep access patterns consistent.

## 2. File Structure

A clear file structure is crucial for organization and moddability. The following is an example structure based on a potential demo scenario.

```
/
|-- autoloads/                 # Systems (Singletons)
|   |-- GameStateSystem.gd
|   |-- ObjectiveSystem.gd
|   |-- SpawningSystem.gd
|   |-- InteractionSystem.gd
|   |-- DialogSystem.gd
|-- data/                      # Custom Resource scripts for data assets
|   |-- Job.gd
|   |-- Objective.gd
|   |-- DialogTree.gd
|-- components/                # Component definitions (.gd) and data (.tres)
|   |-- PlayerStateComponent.gd
|   |-- NPCStateComponent.gd
|   |-- InteractionComponent.gd
|-- entities/                  # Entity scenes (.tscn)
|   |-- Player.tscn
|   |-- Kess_the_Fixer.tscn
|-- scenarios/                 # Moddable game content
|   |-- chip_delivery/
|   |   |-- scenario.json
|   |   |-- maps/
|   |   |   |-- exterior.tscn
|   |   |-- jobs/
|   |   |   |-- chip_delivery.tres
|   |   |-- dialog/
|   |       |-- chip_delivery_dialog.tres
|-- ui/                        # UI scenes and scripts
|   |-- TitleScreen.tscn
|   |-- DialogBox.tscn
|-- main.tscn                  # Main scene, entry point
|-- project.godot
```

## 2.1 Editor vs Code Responsibilities

Keep authored content in the editor; keep runtime behavior in code.

-   **Editor**: Configure Input Map, assemble scenes (`res://entities/`, `res://ui/`), register Autoloads, and author `.tres` resources in the inspector.
-   **Code**: Implement system logic, connect signals, resolve runtime targets, and update component data and job/objective state.

## 3. Systems and Logic

Systems are decoupled. Spawning systems set up the world, while Logic systems react to changes in it.

### Spawning Systems

-   `SpawningSystem.gd` (Autoload): Responsible for procedural generation. It reads `Job` and `Objective` resource files and dynamically adds nodes and components to the active scene. It uses metadata within the target map scene (e.g., `Marker3D` nodes) to determine placement for characters, items, and interactive objects.

### Logic Systems

-   `ObjectiveSystem.gd` (Autoload): The core of objective tracking. It continuously (e.g., in `_process`) scans the scene tree for entities with relevant components. It checks their data against the completion criteria defined in the active objectives. For example, it might check if an NPC's `HealthComponent` `alive` property is `false` to complete an "assassinate" objective.
-   Other systems (`CombatSystem.gd`, `InteractionSystem.gd`) handle specific gameplay logic, modifying component data. They do not need to know about objectives; they only need to know how to modify components.

## 4. Jobs and Objectives

Jobs are procedurally generated from objective templates.

-   **Job Resource (`.tres`)**: A custom resource using `res://data/Job.gd`. It contains metadata (title, description, reward) and a list of objective specifications.
    -   **Fields**: `id`, `title`, `description`, `giver`, `reward`, `objectives`, `status`.
    -   **Objective specs**: Each entry in `objectives` is either a direct `Objective` resource reference or a category token (e.g., `"assassination"`). `SpawningSystem` resolves tokens into concrete objective resources at runtime.
    -   **Runtime instances**: On accept, `SpawningSystem` builds a resolved list (e.g., `objective_instances`) so `ObjectiveSystem` evaluates concrete objectives, not category tokens.
    -   **Status lifecycle**: `available` -> `active` on accept; `active` -> `awaiting_turn_in` when all objectives complete; `awaiting_turn_in` -> `complete` on turn-in; `active` -> `failed` only if a failure condition is defined.
    -   An objective can be a direct reference to an `Objective` resource.
    -   It can be a reference to a category (e.g., "assassination"), allowing `SpawningSystem` to randomly select an objective from `/scenarios/[scenario]/objectives/[category]/`.
-   **Objective Resource (`.tres`)**: A custom resource using `res://data/Objective.gd`. It contains:
    -   **Fields**: `id`, `title`, `description`, `type`, `target_ref`, `completion_rules`, `failure_rules`.
    -   **Targeting**: `target_ref` is resolved at runtime (e.g., an entity path, a spawned marker, or an inventory item). `SpawningSystem` writes resolved targets into the objective instance.
    -   **Evaluation inputs**: `ObjectiveSystem` reads component data (e.g., inventory contents, dialog events, interaction signals) plus the resolved `target_ref`.
    -   **Completion rules**: A small set of rule types (e.g., `dialog_node_reached`, `item_in_inventory`, `deliver_item_to_marker`) keeps evaluation predictable.
    -   **Attributes**: Optional parameters per rule (e.g., dialog node id, marker pool name, item scene path).

## 4.1 Dialog Resources

-   **DialogTree Resource (`.tres`)**: A custom resource using `res://data/DialogTree.gd` defining a dialog graph.
    -   **Fields**: `id`, `start_node_id`, `nodes`.
    -   **Node shape**: `node_id`, `speaker`, `text`, `choices`, `events`.
    -   **Choices**: Each choice has `label`, `next_node_id`, and optional `event` for actions (e.g., `offer_job`, `accept_job`, `complete_job`).
    -   **Events**: `DialogSystem` emits signals for events; systems update `PlayerStateComponent` or `ObjectiveSystem` accordingly.
    -   **Conventions**: Node IDs must be unique, and dialog trees should be pure data (no logic beyond events).

## 5. Game Flow & Moddability

The game is designed to be data-driven and easily moddable.

1.  **Main Menu**: The game starts with a main menu scene. A script reads the `/scenarios/` directory to populate a list of available scenarios for the player to choose from.
2.  **Scenario Loading**:
    -   Upon selection, a `GameStateSystem` reads the corresponding `scenario.json` file.
    -   This JSON file contains information about the starting map (`.tscn`), player start position, initial characters, and available jobs.
    -   The system loads the map scene and populates a `JobBoard` or NPC with the available `Job` resources.
3.  **Job Execution**:
    -   The player accepts a job.
    -   `SpawningSystem` reads the `Job` resource, resolves its objectives (randomizing where necessary), and populates the current map with the required entities and components.
4.  **Gameplay Loop**:
    -   The player interacts with the world.
    -   Logic Systems (Autoloads) process player actions and world events, updating component data on the relevant `ComponentHost` nodes.
    -   `ObjectiveSystem` monitors these component changes. When completion criteria are met, it updates the job status and notifies the player.

Adding a new scenario with new maps, jobs, and objectives is as simple as adding a new folder to the `/scenarios/` directory. The game's core systems will automatically detect and integrate the new content.
