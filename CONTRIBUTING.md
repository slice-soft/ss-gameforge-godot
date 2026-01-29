# Contributing to jcd-gameforge

Hi! 👋  
Thanks for your interest in contributing to **jcd-gameforge**. Contributions from the community help make this project better for everyone.

This document outlines how to contribute in a way that keeps the project maintainable, consistent, and reliable.

---

## How to contribute

Contributions can take many forms, including:
- Bug reports
- Documentation improvements
- Bug fixes
- Small improvements to existing modules

Before investing time in a large change, please read the guidelines below carefully.

---

## Reporting bugs and opening issues

If you encounter a bug or unexpected behavior, please open an issue.

When possible, include:
- A clear description of the problem
- Steps to reproduce it
- Expected vs actual behavior
- Godot version and relevant context

Please don’t worry if your report is incomplete or turns out to be a duplicate. This project is maintained by volunteers, and all reports are appreciated.

---

## Feature requests and new functionality

If you want to add a **new feature or major functionality**, please **open an issue or contact me first** to discuss it before starting work.

This helps ensure that:
- The feature aligns with the project’s vision
- The scope is well defined
- The change does not introduce breaking behavior
- The implementation fits the existing architecture

Large pull requests created without prior discussion may be declined, even if well implemented.

---

## Pull request guidelines

To keep the project healthy and easy to review, please follow these rules when submitting a pull request:

### 1. One pull request per responsibility
Each pull request must focus on **a single functionality or module**.

Please avoid:
- Mixing changes across multiple modules
- Combining refactors, new features, and bug fixes in the same PR
- Including unrelated formatting or cleanup changes

If you want to modify multiple modules, submit **separate pull requests**, one per module or concern.

---

### 2. Code quality expectations
All contributions must:
- Be compatible with **Godot 4.x**
- Use **typed GDScript** where applicable
- Follow existing patterns and conventions
- Avoid introducing hidden side effects or tight coupling

Code should be clear, readable, and maintainable.

---

### 3. Documentation is required
Any change that affects behavior, APIs, or usage **must update the relevant documentation**.

This includes:
- Module documentation
- README sections
- Inline comments when appropriate

If the documentation is missing or outdated, the pull request may be requested to be updated before review.

---

### 4. Testing and validation
Before submitting a pull request, make sure that:
- The feature or fix works as intended
- Existing functionality is not broken
- The change has been tested in a real Godot project

Pull requests should be in a **clean, mergeable state** before review.

---

## Branches

All development happens on the `main` branch.

Please create a new branch in your fork for your changes and submit pull requests targeting `main`.

---

## Licensing

By contributing to this project, you agree that your contributions will be licensed under the **MIT License**, the same license as the project.

---

## Code of Conduct

This project follows the **Contributor Covenant Code of Conduct**.  
By participating, you agree to uphold its standards.

Please see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for details.