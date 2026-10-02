# Airlock

> Working title: **"Adrift"**
>
> **Status:** Early design. The core mechanics are defined, but the background and story are still to be decided.

Airlock is a narrative survival-management game. You are one of five people stranded and drifting in space. There aren't enough supplies for everyone, so every seven days you have to decide who goes out the airlock. Your goal is to keep **your own character** alive until Day 30.

---

## Core Concept

| | |
|---|---|
| **Survival period** | 30 days |
| **Cycle length** | 7 days per round |
| **Decision rounds** | ~4–5 |
| **Characters** | 5 (including the player) |
| **Ejections** | 4 (one per 7-day cycle) |
| **Win goal** | The player character survives to Day 30 |

**Core tension:** there are too few resources for everyone to live. In each cycle you hand out supplies, watch how each character is doing and how they get along, and then decide who to **eject from the ship**.

## Characters

Each character should have at least one distinct personality trait so players can read them quickly. Example traits (not final):

- **Irritable:** more likely to start a conflict when supplies are split unevenly.
- **Cowardly:** passive when threatened or facing ejection, but may be easier to persuade.
- *More traits to be designed.*

### Relationship Web

- Some characters have a **bonded relationship**, such as close friends, relatives or allies.
- If one member of a bonded pair is ejected, the other may trigger a **negative event**, such as a riot, refusing to cooperate or sabotaging resources.
- Keep the web simple at first: start with **one bonded pair**, validate the mechanic, then expand.

## Gameplay Loop

Each round covers 7 days:

```
┌─────────────────────┐
│ 1. Resource         │  Split limited food / water / other supplies
│    Allocation       │  among the five characters
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 2. Event            │  A random or fixed event fires, which can affect
│                     │  character states, relationships or remaining supplies
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 3. Ejection         │  The player picks one person and ejects them
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 4. Resolution       │  Show the round's results: remaining supplies,
│                     │  relationship changes, special events triggered
└─────────┬───────────┘
          ▼
   Next round, until all 4 others are ejected or Day 30 is reached
```

## Win / Loss Conditions *(open for discussion)*

**Current idea:** there is one correct ejection order that lets the player survive.

**Design concern:** with only one correct answer, the game can turn into trial-and-error guessing, which tends to feel frustrating rather than strategic.

**Alternative:** have no single correct answer. Different orders lead to different endings and costs, and players make informed choices from personality and relationship clues instead of guessing blindly.

The team still has to choose which approach to use.

## Open Items

- [ ] Story background: why are they adrift in space, and what mission or accident led there?
- [ ] Identities, names, personalities and appearances of the five characters
- [ ] Detailed relationship web: how many bonded pairs, and of what types?
- [ ] Resource types and amounts (food, water, oxygen, others?)
- [ ] Content and size of the random event pool
- [ ] How ejection works in the UI (click, drag or dialogue choice?)
- [ ] Win/loss logic: one correct answer or multiple branching endings
- [ ] Art style and UI presentation

## Development Roadmap

The core systems are mostly UI and a state machine, with no complex physics or animation, which suits the team's current technical level.

Build the simplest version of a **single round loop** first, with no art and no relationship web. Once that works, add complexity in this order:

1. **Core loop**: allocation → event → ejection → resolution
2. **Personality trait effects**
3. **Relationship web interactions**
4. **Expanded event pool**
5. **Art polish**

## Getting Started

This project uses **[Godot 4.7](https://godotengine.org/)** with the GL Compatibility renderer. It was created with the .NET build of Godot (C# assembly name `Airlock`), so use the .NET editor if you plan to write C# scripts.

```bash
git clone https://github.com/UnZzz/airlock.git
```

Then open Godot, choose **Import**, and select `project.godot` in the cloned folder.

## Project Structure

```
airlock/
├── project.godot   # Godot project configuration
├── icon.svg        # Project icon
└── README.md
```
