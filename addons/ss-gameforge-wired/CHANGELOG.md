# Changelog

## [2.0.0](https://github.com/slice-soft/ss-gameforge-godot/compare/ss-gameforge-wired-v1.1.0...ss-gameforge-wired-v2.0.0) (2026-11-28)


### ⚠ BREAKING CHANGES

* **wired:** GWBinding.key_code is now a physical key position (US QWERTY names). Bindings made with from_key() keep working on QWERTY, but on other layouts they now follow the key's position instead of its label, and saved profiles are read the same way.

### Features

* **wired:** physical key bindings and complete axis actions ([#59](https://github.com/slice-soft/ss-gameforge-godot/issues/59)) ([#62](https://github.com/slice-soft/ss-gameforge-godot/issues/62)) ([9734f45](https://github.com/slice-soft/ss-gameforge-godot/commit/9734f45c354475202282cd2d80d59400f8679072))


### Bug Fixes

* **wired:** describe the plugin accurately ([#69](https://github.com/slice-soft/ss-gameforge-godot/issues/69)) ([#70](https://github.com/slice-soft/ss-gameforge-godot/issues/70)) ([4c2e6af](https://github.com/slice-soft/ss-gameforge-godot/commit/4c2e6afcb1d34023b01cdf18387108b1732fafe4))
* **wired:** make runtime rebinding safe ([#58](https://github.com/slice-soft/ss-gameforge-godot/issues/58)) ([#61](https://github.com/slice-soft/ss-gameforge-godot/issues/61)) ([001f554](https://github.com/slice-soft/ss-gameforge-godot/commit/001f554eac939182d8e2b23f1ae4bf54cf177c39))
* **wired:** safe, unambiguous binding display names ([#66](https://github.com/slice-soft/ss-gameforge-godot/issues/66)) ([#67](https://github.com/slice-soft/ss-gameforge-godot/issues/67)) ([101766c](https://github.com/slice-soft/ss-gameforge-godot/commit/101766ccf0317b5c52e0ce3e2ed448b77c4a0c35))
* **wired:** track input edges per player and device ([#57](https://github.com/slice-soft/ss-gameforge-godot/issues/57)) ([#60](https://github.com/slice-soft/ss-gameforge-godot/issues/60)) ([9b05e54](https://github.com/slice-soft/ss-gameforge-godot/commit/9b05e5418deb074c47839b24901b6780e4b42076))

## [1.1.0](https://github.com/slice-soft/ss-gameforge-godot/compare/ss-gameforge-wired-v1.0.0...ss-gameforge-wired-v1.1.0) (2026-03-29)


### Features

* enhance input management with unassigned device detection and profile persistence ([#19](https://github.com/slice-soft/ss-gameforge-godot/issues/19)) ([9fd3ca1](https://github.com/slice-soft/ss-gameforge-godot/commit/9fd3ca106b7df7579babd7b43d62f5c44132171b))

## 1.0.0 (2026-03-29)


### Features

* **wired:** Add GameForge Wired plugin with advanced input system ([b64586e](https://github.com/slice-soft/ss-gameforge-godot/commit/b64586ef88b3fc6920d4a55b86e19556bf0d0896))
