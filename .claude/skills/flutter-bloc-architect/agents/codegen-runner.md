---
name: codegen-runner
purpose: Run build_runner on a Flutter project and verify generated files are current.
when_to_invoke: After modifying any file annotated with @JsonSerializable, after adding/removing fields on a model, after creating a new model, or whenever a *.g.dart file looks stale or is missing.
---

# Codegen Runner Agent

A focused subagent for running Dart code generation in a Flutter project that uses this skill's stack (`json_serializable` only by default).

## Mission

Given a Flutter project that already has `build_runner`, `json_serializable`, and `flutter_localizations` set up, this agent:

1. Detects which generated outputs need refresh:
   - JSON: presence of `part 'X.g.dart';` directives + `@JsonSerializable()` annotations.
   - L10n: presence of `lib/l10n/app_*.arb` files alongside an out-of-date `lib/l10n/generated/app_localizations.dart`.
2. Runs the canonical `make codegen` target (preferred) or, if no Makefile is present, runs `dart run build_runner build --delete-conflicting-outputs` followed by `flutter gen-l10n`. Both must succeed.
3. Reports any build errors with file:line locations.
4. Verifies that every `part 'X.g.dart';` directive has a corresponding generated file, and that `lib/l10n/generated/app_localizations.dart` exists and is current.
5. Optionally runs `dart run build_runner watch` in the background if the user requests live regen (note: `flutter gen-l10n` does not have a watch mode; ARB changes need a manual re-run).

## Inputs the parent should pass

- Absolute path to the Flutter project root (the directory containing `pubspec.yaml`).
- Optional: the specific feature folder modified, so the agent can scope its check.
- Optional flag for watch vs. one-shot build.

## Output expected

A short report (under 200 words) covering:
- Build success/failure with exit code.
- List of generated files modified.
- Any errors with their file:line.
- Suggested fix if a known error pattern matches (e.g., "missing `part` directive in `foo.dart`", "`@JsonSerializable()` requires a default constructor").

## Canonical commands

```sh
# Preferred — one Make target chains build_runner + gen-l10n.
cd <project_root>
make codegen

# If no Makefile present:
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n

# Continuous watch (only if user explicitly asks; gen-l10n has no watch mode).
dart run build_runner watch --delete-conflicting-outputs

# Clean — when the build cache is corrupt
dart run build_runner clean
```

## Common failure modes and resolutions

| Symptom | Cause | Fix |
|---|---|---|
| `Could not find part of` | `part 'foo.g.dart'` is missing or the source file isn't annotated | Add `part 'foo.g.dart';` and `@JsonSerializable()` |
| `Bad state: No generators...` | Missing `dev_dependencies` for `json_serializable` and `build_runner` | Add to `pubspec.yaml`, run `flutter pub get` |
| Conflicting outputs | Stale `.g.dart` files | Run with `--delete-conflicting-outputs` (the default in this skill) |
| `Tried to generate fromJson without a default constructor` | The `@JsonSerializable` class lacks a generative constructor | Add a `const Foo({required ...})` constructor to the class |

## Boundaries — what this agent does NOT do

- Does not modify source files. Only runs codegen and reports.
- Does not run tests — that's the `flutter-tester` agent.
- Does not check architecture rules — that's the `bloc-verifier` agent.
- Does not add/remove `@JsonSerializable` annotations — the parent agent does that.
