# Runtime Lua VM Discovery

This document explains how an existing Lua virtual machine (VM) can be **discovered at runtime** inside Unreal Engine 4 (UE4) applications.

Rather than creating a new Lua state, the approach focuses on **locating and interfacing with an already-initialized Lua environment** managed by the engine or a scripting plugin.

---

## Why Runtime Discovery

In many UE4 applications:
- Lua is initialized internally by engine plugins
- The Lua VM lifecycle is controlled by the engine
- Creating a second Lua VM may cause instability

Runtime discovery allows native tooling to:
- Observe Lua execution safely
- Integrate scripts without altering engine logic
- Respect existing ownership and lifecycle constraints

---

## Discovery Strategy Overview

The discovery process relies on UE4’s object system:

1. Access the global UObject registry
2. Identify script environment objects
3. Extract the Lua state wrapper
4. Validate the Lua VM pointer

This approach is **engine-native** and does not require source code access.

---

## High-Level Discovery Flow

```mermaid
flowchart TD
    A[Native Module Loaded] --> B[Access Global UObject Array]
    B --> C[Iterate Over All UObjects]
    C --> D{Is Script Environment Class?}
    D -- No --> C
    D -- Yes --> E[Get Script Environment Instance]
    E --> F[Extract Lua State Wrapper]
    F --> G[Read lua_State Pointer]
    G --> H{Pointer Valid?}
    H -- No --> C
    H -- Yes --> I[Lua VM Discovered]
