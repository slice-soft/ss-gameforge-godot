# Changelog

## [2.0.0-rc.1](https://github.com/slice-soft/ss-gameforge-godot/compare/ss-gameforge-wired-v1.1.0...ss-gameforge-wired-v2.0.0-rc.1) (2026-11-27)


### ⚠ BREAKING CHANGES

* **wired:** GWBinding.key_code is now a physical key position (US QWERTY names). Bindings made with from_key() keep working on QWERTY, but on other layouts they now follow the key's position instead of its label, and saved profiles are read the same way.

### Features

* **wired:** physical key bindings and complete axis actions ([#59](https://github.com/slice-soft/ss-gameforge-godot/issues/59)) ([#62](https://github.com/slice-soft/ss-gameforge-godot/issues/62)) ([9734f45](https://github.com/slice-soft/ss-gameforge-godot/commit/9734f45c354475202282cd2d80d59400f8679072))


### Bug Fixes

* **wired:** make runtime rebinding safe ([#58](https://github.com/slice-soft/ss-gameforge-godot/issues/58)) ([#61](https://github.com/slice-soft/ss-gameforge-godot/issues/61)) ([001f554](https://github.com/slice-soft/ss-gameforge-godot/commit/001f554eac939182d8e2b23f1ae4bf54cf177c39))
* **wired:** track input edges per player and device ([#57](https://github.com/slice-soft/ss-gameforge-godot/issues/57)) ([#60](https://github.com/slice-soft/ss-gameforge-godot/issues/60)) ([9b05e54](https://github.com/slice-soft/ss-gameforge-godot/commit/9b05e5418deb074c47839b24901b6780e4b42076))
