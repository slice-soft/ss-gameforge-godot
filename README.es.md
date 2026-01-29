<img src="icon.svg" width="128" height="128">

# jcd-gameforge

[English Version](README.md)

**GameForge** es un conjunto de herramientas y patrones reutilizables para **Godot Engine 4.x**, pensado para acelerar el desarrollo sin imponer un estilo rígido.

No es un fork del engine, no es un starter-kit desechable.  
Es una **base de gameplay y arquitectura** que puedes llevar de proyecto en proyecto.

> Menos repetir código.  
> Más foco en diseño, juego y experiencia.

---

## ✨ ¿Qué es GameForge?

GameForge es un **addon modular** que reúne soluciones prácticas a problemas comunes en Godot:

- Manejo de singletons sin boilerplate  
- Comunicación desacoplada entre sistemas  
- Máquinas de estado claras y extensibles  
- UI utilitaria lista para usar  
- Diálogos desacoplados de la lógica  

Todo escrito en **GDScript 2.0**, orientado a Godot 4.x, con APIs simples y código legible.

---

## 🧱 Módulos principales

### 🔹 SingletonNode
Acceso limpio y seguro a servicios globales.

```gdscript
SaveService.i.save_game()
BossFightDirector.i.next_phase()
```

- Evita `get_node()` por todo el proyecto  
- Mensajes de error claros  
- Opcional: auto-carga si no existe  

---

### 🔹 EventBus
Comunicación global desacoplada, sin dependencias directas.

```gdscript
EventBus.on(self, {
  "player_died": "_on_player_died",
  "health_changed": "_on_health_changed",
})

EventBus.emit("player_died", player_id)
```

- Registro por rutas  
- Validación de métodos  
- Sin conexiones duplicadas  

---

### 🔹 State Machine (FSM)
Máquinas de estado pensadas para gameplay real.

- Estados con `enter / exit / update / physics`  
- Cambios explícitos y controlados  
- Compatible con animaciones sin acoplarse  

Ideal para:
- Personajes  
- Enemigos  
- UI states  
- Flujos de juego  

---

### 🔹 Toast UI
Feedback visual rápido y consistente.

```gdscript
Toast.show("Guardado ✅")
Toast.warn("Sin conexión")
Toast.error("Error al cargar")
```

- Cola de mensajes  
- Animaciones suaves  
- Uso inmediato, sin setup complejo  

---

### 🔹 Dialogue Manager
Sistema de diálogos desacoplado del UI.

- Manejo de líneas y elecciones  
- Emite señales, no controla la vista  
- Preparado para crecer (quests, triggers, tags)

```gdscript
Dialogue.play("intro")
Dialogue.choose(0)
```

---

## 🧩 Filosofía

GameForge sigue estas ideas:

- **Opt-in**: nada se impone, tú decides qué usar  
- **Modular**: usa solo los módulos que necesites  
- **Legible**: el código es documentación  
- **Escalable**: sirve para prototipos y proyectos grandes  
- **Sin magia oculta**: lo que pasa, se ve  

---

## 📦 Instalación

1. Copia el addon en tu proyecto:
```
res://addons/jcd-gameforge/
```

2. Activa el plugin desde:
```
Project Settings → Plugins
```

3. (Opcional) Instala los autoloads desde el panel del plugin.

---

## 🗺️ Roadmap (alto nivel)

- [ ] Wizard de autoloads  
- [ ] Scene / Feature generator  
- [ ] Importadores de diálogos (JSON / CSV)  
- [ ] Documentación por módulo  
- [ ] Escenas demo  

---

## 👤 Autor

Creado por **JuanCaDev**  
Ingeniero de software, creador de contenido y desarrollador de juegos con Godot.

Este proyecto nace de experiencia real en proyectos personales y profesionales, buscando un equilibrio entre **arquitectura limpia** y **practicidad diaria**.

---

## 📜 Licencia

MIT – úsalo, modifícalo, llévalo a producción.  
Si te sirve, disfrútalo. Si lo mejoras, mejor aún.
