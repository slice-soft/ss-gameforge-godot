<img src="icon.svg" width="128" height="128">

# jcd-gameforge

[Versión en Español](README.es.md)

**GameForge** is a set of reusable tools and patterns for **Godot Engine 4.x**, designed to accelerate development without imposing a rigid style.

It's not an engine fork, not a disposable starter-kit.  
It's a **gameplay and architecture foundation** you can carry from project to project.

> Less code repetition.  
> More focus on design, gameplay, and experience.

---

## ✨ What is GameForge?

GameForge is a **modular addon** that brings together practical solutions to common Godot problems:

- Singleton management without boilerplate  
- Decoupled communication between systems  
- Clear and extensible state machines  
- Ready-to-use utility UI  
- Dialogs decoupled from logic  

All written in **GDScript 2.0**, targeting Godot 4.x, with simple APIs and readable code.

---

## 🧱 Core Modules

### 🔹 SingletonNode
Clean and safe access to global services.

```gdscript
SaveService.i.save_game()
BossFightDirector.i.next_phase()
```

- Avoid `get_node()` throughout the project  
- Clear error messages  
- Optional: auto-load if it doesn't exist  

---

### 🔹 EventBus
Decoupled global communication, without direct dependencies.

```gdscript
EventBus.on(self, {
  "player_died": "_on_player_died",
  "health_changed": "_on_health_changed",
})

EventBus.emit("player_died", player_id)
```

- Registration by paths  
- Method validation  
- No duplicate connections  

---

### 🔹 State Machine (FSM)
State machines designed for real gameplay.

- States with `enter / exit / update / physics`  
- Explicit and controlled transitions  
- Compatible with animations without coupling  

Ideal for:
- Characters  
- Enemies  
- UI states  
- Game flows  

---

### 🔹 Toast UI
Quick and consistent visual feedback.

```gdscript
Toast.show("Saved ✅")
Toast.warn("No connection")
Toast.error("Load error")
```

- Message queue  
- Smooth animations  
- Immediate use, no complex setup  

---

### 🔹 Dialogue Manager
Dialog system decoupled from UI.

- Line and choice handling  
- Emits signals, doesn't control the view  
- Ready to grow (quests, triggers, tags)

```gdscript
Dialogue.play("intro")
Dialogue.choose(0)
```

---

## 🧩 Philosophy

GameForge follows these principles:

- **Opt-in**: nothing is imposed, you decide what to use  
- **Modular**: use only the modules you need  
- **Readable**: code is documentation  
- **Scalable**: works for prototypes and large projects  
- **No hidden magic**: what happens is visible  

---

## 📦 Installation

1. Copy the addon to your project:
```
res://addons/jcd-gameforge/
```

2. Enable the plugin from:
```
Project Settings → Plugins
```

3. (Optional) Install autoloads from the plugin panel.

---

## 🗺️ Roadmap (high level)

- [ ] Autoloads wizard  
- [ ] Scene / Feature generator  
- [ ] Dialogue importers (JSON / CSV)  
- [ ] Module documentation  
- [ ] Demo scenes  

---

## 👤 Author

Created by **JuanCaDev**  
Software engineer, content creator, and game developer with Godot.

This project is born from real experience in personal and professional projects, seeking a balance between **clean architecture** and **daily practicality**.

---

## 📜 License

MIT – use it, modify it, take it to production.  
If it helps you, enjoy it. If you improve it, even better.
