# Contributing to ss-gameforge-godot

The base contributing guide, commit conventions, PR rules, and community
standards live in the
[ss-community](https://github.com/slice-soft/ss-community/blob/main/CONTRIBUTING.md)
repository. Read that first.

This document covers only what is specific to this repository.

---

## Requirements

- Godot 4.x
- Git

## Setup

```bash
git clone https://github.com/your-username/ss-gameforge-godot.git
cd ss-gameforge-godot
```

Open the project in Godot and enable the plugin from `Project Settings -> Plugins`.

## Validation

There is no automated test suite for this addon yet. For every behavior change,
validate the affected module manually in Godot before opening a PR.

Recommended validation checklist:

- Open the repository project in Godot without editor errors
- Enable the plugin and confirm the addon loads correctly
- Smoke test the module you changed in a sample scene or integration project
- Update the corresponding documentation when behavior, API, or setup changes

## Repository-specific rules

- Keep each PR focused on a single module or a single documentation concern
- Use Slice Soft repository naming in docs and repo metadata: `ss-gameforge-godot`
- Do not rename `addons/jcd-gameforge-godot` or embedded Godot resource paths as
  part of unrelated work; that internal migration must happen in a dedicated PR
- If you add a new module, include usage documentation in both `README` and the
  relevant file under `docs/`
- Breaking changes must follow the policy in
  [VERSIONING.md](https://github.com/slice-soft/ss-community/blob/main/VERSIONING.md)

## Questions

Open a
[Discussion](https://github.com/slice-soft/ss-gameforge-godot/discussions)
instead of an issue for questions about implementation details or design direction.
