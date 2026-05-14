# Companion Agents

Four agents the skill defines for delegating repetitive or verification work. Invoke them as subagents (via the `Agent` tool) when the work matches their purpose.

| Agent | Read-only? | When |
|---|---|---|
| `feature-scaffolder` | No (writes files) | Adding a new feature — generates the full data/domain/presentation tree. |
| `codegen-runner` | No (runs build_runner) | After modifying any `@JsonSerializable` class or adding a new one. |
| `bloc-verifier` | Yes | After a feature is scaffolded, after non-trivial state-class or repo changes, periodically as a full audit. |
| `flutter-tester` | Yes | Before declaring any change "done". After codegen-runner and bloc-verifier pass. |

## Standard sequence for a new feature

```
feature-scaffolder  → generates the folder + reports DI/router lines
   ↓ (parent applies the lines)
codegen-runner      → regenerates *.g.dart for the new model
   ↓
bloc-verifier       → audits the new code against rules
   ↓
flutter-tester      → flutter analyze && flutter test
```

If any step fails, fix the issue and re-run from that step downward.

## Other agents you might consider adding

These are not bundled but are reasonable additions for projects with specific needs. Add a corresponding `*.md` file to `agents/` and link it from `SKILL.md`'s "When to invoke which agent" table.

- **integration-test-runner** — runs `patrol` or `flutter test integration_test`, reports per-screen pass/fail.
- **icon-splash-generator** — runs `flutter_launcher_icons:generate` and `flutter_native_splash:create` from `pubspec.yaml` config; useful before TestFlight/Play uploads.
- **i18n-extractor** — scans `lib/` for hardcoded strings and reports candidates for `.arb` extraction.
- **dependency-auditor** — runs `flutter pub outdated` and reports which packages have new majors that need attention.
- **performance-profiler** — runs the app in profile mode and reports startup time + first frame time, frame budget violations.
- **bundle-size-checker** — builds release artifacts (`flutter build apk --release`, `--analyze-size`) and reports bundle size deltas vs. main.

Add these as you encounter the recurring need for them. Don't proliferate agents preemptively.
