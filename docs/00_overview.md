# Overview

This document provides a high-level overview of the Lua scripting pipeline in Unreal Engine 4 (UE4) applications, as explored in this repository.

The goal of this project is to explain **how Lua scripting is integrated at runtime**, how the Lua virtual machine (VM) fits into the UE4 architecture, and how scripts are executed in coordination with engine lifecycle events. The focus is on **structure and flow**, not on any specific application or game.

---

## What This Project Is

This repository is a **research and documentation project** that:

- Describes the internal structure of Lua scripting pipelines in UE4
- Explains how Lua virtual machines are embedded and managed
- Shows how native code interfaces with Lua through the C API
- Documents safe, lifecycle-aware script execution models
- Provides a sanitized reference implementation for learning and tooling

The project is intended for **developers, researchers, and students** who want to understand script VM behavior inside UE4-based applications.

---

## What This Project Is Not

This project does **not**:

- Target any specific game or commercial application
- Include offsets, signatures, or binary patches
- Circumvent security or protection mechanisms
- Provide exploit payloads or weaponized tooling
- Replace official Unreal Engine scripting solutions

All examples are generic and abstracted.

---

## Why Lua in Unreal Engine

Lua is frequently chosen for scripting because it is:

- Lightweight and fast
- Easy to embed in native applications
- Well-supported by tooling
- Suitable for gameplay logic, UI scripting, and automation

In UE4, Lua is typically integrated through:
- Custom engine plugins
- Script environment wrappers
- Native bindings to engine APIs

Understanding how these components interact is essential for tooling, modding frameworks, and engine research.

---

## Key Concepts Introduced

This repository is built around the following core concepts:

- **Script Environment Wrapper**  
  A UE4 object that owns or references the Lua VM and provides helper functions.

- **Lua Virtual Machine (`lua_State`)**  
  The execution context that holds Lua globals, stack, and loaded scripts.

- **Native ↔ Script Boundary**  
  The interface between C++ and Lua, typically through the Lua C API.

- **Engine Lifecycle Integration**  
  Executing scripts only when the engine and scripting environment are fully initialized.

- **Runtime Discovery**  
  Locating existing scripting components dynamically rather than creating new ones.

---

## Project Structure Philosophy

The repository is organized to separate:

- **Documentation** (architecture, flow, concepts)
- **Core logic** (pipeline and execution model)
- **Engine-specific abstractions** (UE4 object access)
- **Platform-specific notes** (Android / iOS differences)

This separation keeps the project readable, extensible, and safe to share.

---

## How to Read This Repository

Recommended reading order:

1. `01_lua_pipeline.md` — Overall Lua scripting pipeline architecture  
2. `02_runtime_discovery.md` — How Lua state and script environments are found  
3. `03_injection_flow.md` — Lifecycle-based script integration flow  
4. `04_error_handling.md` — Error propagation and stability  
5. `05_cross_platform.md` — Platform-specific considerations  

Each document builds on the previous one.

---

## Summary

This project serves as a **clear, structured reference** for understanding how Lua scripting pipelines work inside Unreal Engine 4 applications.

It is meant to help readers reason about:
- Script VM behavior
- Engine ↔ script interactions
- Safe execution timing
- Cross-platform design

without relying on proprietary code or unsafe techniques.
