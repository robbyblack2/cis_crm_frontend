# flutter-bloc-architect

An opinionated Claude Code skill that enforces a single, consistent Flutter+BLoC architecture across every project. Drop it into a Flutter project, run `/configure-flutter-app`, and Claude builds against a locked stack, three-layer feature-first folder structure, typed `Result<T, AppFailure>` error contract, mandatory TDD, and accessibility/performance rules that are auditable rather than aspirational.

Current version: **v1.9.0** (production-ready). Verified clean on Flutter 3.41.4 / Dart 3.11.1.

---

## What this skill does

When this skill is loaded into a Flutter project's `.claude/skills/` directory, every Claude Code session in that project conforms to one set of architectural rules:

- **State management:** `flutter_bloc` only. No Riverpod, Provider, MobX, GetX. Sealed state hierarchies + `Equatable`. Single documented exemption for forms (`FormzSubmissionStatus`).
- **Cross-feature reactions:** App-root `MultiBlocListener` per the official BLoC team's "no bloc imports another bloc" rule. Reactive repositories only when non-bloc code (e.g. auth interceptor) is the trigger.
- **Folder structure:** Three-layer feature-first (`features/<x>/{data,domain,presentation}/`). Dependencies point inward toward `domain/`.
- **Error handling:** Repos return `Future<Result<T, AppFailure>>` and never throw. Data sources throw typed `AppException`. Bloc handlers exhaustively switch.
- **Routing:** `go_router` only. Top-level redirect chain (force-upgrade → onboarding → auth) driven by `AuthRepository.status` via `refreshListenable`. `StatefulShellRoute` for adaptive bottom-nav / rail / drawer.
- **Adaptive UI:** Material 3 + dark+light parity mandatory. `ColorScheme.fromSeed`. `LayoutBuilder` against canonical breakpoints (`compact 600 / medium 840 / expanded 1200`).
- **Localization:** Built-in `flutter gen-l10n`. ARB files in `lib/l10n/`. Bloc-verifier flags hardcoded strings in `presentation/`.
- **Performance:** `RepaintBoundary` around frequently-repainting subtrees, `BlocSelector` for one-slice reads, `ListView.builder` mandatory, `Image.network` requires `cacheWidth/cacheHeight`.
- **TDD enforced mechanically:** lefthook pre-commit blocks `lib/` changes without `test/` changes; CI does the same on PRs; `bloc-verifier` flags missing test files.
- **Flavors:** Path A — Dart-side flavors only via `--dart-define=FLAVOR=<name>` with prod default. Bare `flutter run` works on every platform (Android, iOS, web, macOS, Windows, Linux). Native flavors opt-in per-project.

The full hard-rule list is in `SKILL.md`. The decision history with citations is in `MEMORY.md`.

---

## Installing it on a Flutter project

```sh
# 1. From the master copy:
cp -r /path/to/flutter-bloc-architect <your-project-root>/.claude/skills/

# 2. Verify the layout:
ls <your-project-root>/.claude/skills/flutter-bloc-architect/
# → SKILL.md  MEMORY.md  agents/  commands/  references/  templates/  README.md
```

That's it. Claude Code auto-discovers skills under `.claude/skills/` and loads `SKILL.md` whenever the conversation touches Flutter / Dart / BLoC.

If you maintain multiple Flutter projects, each one gets its own copy — no symlinks, no shared state. When the master copy gets updates, run `cp -r` again into each project that wants the update.

---

## Day-1 workflow — bootstrap a new project

```sh
# 1. Start with a clean Flutter project.
flutter create my_app --org com.acme --platforms=ios,android,web,macos
cd my_app

# 2. Install this skill.
cp -r /path/to/flutter-bloc-architect .claude/skills/

# 3. In Claude Code:
/configure-flutter-app
```

`/configure-flutter-app` is interactive. It asks:
- App display name.
- Bundle ID prefix (default placeholder: `com.example.<app>` — never assumed).
- Flavor scheme (default: `dev | prod`).
- Default flavor (default: `prod`).
- Target platforms.
- Launcher-icon source PNG (or "skip" to auto-generate a placeholder).
- Theme seed color.
- Optional features: Sentry, Firebase Analytics, Connectivity, Feature flags, Push notifications, Deep links, Force-upgrade.

Then it writes `pubspec.yaml`, the full `lib/` scaffold, `l10n.yaml`, `Makefile`, `.vscode/launch.json`, `lefthook.yml`, the CI workflow, generates launcher icons + native splash, runs codegen, and smoke-tests with `dart format` + `flutter analyze` + `flutter test` + per-platform builds. Idempotent — safe to re-run.

After it finishes:
```sh
make run         # bare flutter run, defaults to prod
make run-dev     # flutter run --dart-define=FLAVOR=dev
make run-web     # flutter run -d chrome
make test        # flutter test
make codegen     # build_runner + flutter gen-l10n
```

---

## Day-N workflow — add a feature

The skill ships agents that Claude invokes automatically. The interaction looks like:

> User: *"Add a cart feature."*

Behind the scenes:

1. **`feature-scaffolder`** generates `lib/features/cart/{data,domain,presentation}/...` with **failing tests + minimum stubs**. Running `flutter test` immediately produces an expected red bar.
2. The TDD loop walks layer by layer (entity → bloc → repo impl → data source → widget). Each layer: Claude writes the impl that turns a red green, then `flutter test` confirms.
3. **`codegen-runner`** runs `make codegen` after any `@JsonSerializable` model changes.
4. **`bloc-verifier`** audits the new code against ~50 rules (sealed state, transformers, layering, naming, accessibility, TDD coverage, performance) and reports violations with file:line + fixes.
5. **`flutter-tester`** runs `dart format` + `flutter analyze` + `flutter test` before declaring "done."

You don't invoke these by name — Claude does it as needed. The agents live in `agents/` if you want to read what they do.

---

## When you have a question

The skill is multi-tier so context stays small:

| Need | Where to look |
|---|---|
| The hard rules (always loaded) | `SKILL.md` |
| Why a rule exists, with citations | `MEMORY.md` (dated decision log) |
| Deep-dive on a topic | `references/<topic>.md` (loaded on demand) |
| What an agent does | `agents/<name>.md` |
| Slash commands | `commands/<name>.md` |

Reference docs available:
- `references/architecture.md` — three-layer Clean Architecture
- `references/state-design.md` — sealed states, formz exemption, pagination shape
- `references/error-handling.md` — `Result<T, AppFailure>`, `ValidationFailure(fieldErrors)`
- `references/bloc-vs-cubit.md` — capability-based decision rule
- `references/hydrated-bloc.md` — persistence patterns + migration + race-with-stream
- `references/di-patterns.md` — `get_it` registration order, factories vs singletons
- `references/routing.md` — `refreshListenable`, redirect chain, `StatefulShellRoute`
- `references/theming.md` — Material 3, `ColorScheme.fromSeed`, Inter font
- `references/testing.md` — TDD loop, blocTest params, MockBloc/MockCubit, HydratedBloc setUp
- `references/performance.md` — `RepaintBoundary`, `BlocSelector`, image cache sizing, DevTools
- `references/situational-packages.md` — Sentry, connectivity, feature flags, push, etc.

---

## Authoritative sources

Every architectural rule traces back to one of these (canonical-sources index in `SKILL.md` and `agents/bloc-researcher.md`):

- **Tier 1 — official docs:** [bloclibrary.dev](https://bloclibrary.dev/) (architecture, bloc concepts, modeling state, naming conventions, testing, migration).
- **Tier 2 — felangel/bloc:** repo source, examples (login, weather, todos, infinite_list), issues, discussions, CHANGELOGs.
- **Tier 3 — pub.dev:** flutter_bloc, bloc_concurrency, hydrated_bloc, bloc_test, equatable, formz.
- **Tier 4 — aligned tooling:** Very Good Ventures blog, [DCM Bloc lint rules](https://dcm.dev/docs/rules/bloc/).

When you (or Claude) hit a question whose answer should come from an authoritative source, invoke the **`bloc-researcher`** agent — it fetches and quotes directly with confidence ratings.

---

## Where this skill is opinionated vs the official docs

Most rules quote the BLoC team verbatim. A few are **deliberately stricter** (each carries a callout in its reference doc):

| Rule | Skill | Official |
|---|---|---|
| Cross-feature reactions | App-widget root `MultiBlocListener` only | Any presentation-layer location |
| Reactive repository sharing | Only the owning bloc subscribes | Multiple blocs may share one reactive repo |
| `bloc_concurrency` transformer | Mandatory on every user-input handler | Opt-in |
| Repo error path | Returns `Result<T, AppFailure>`, never throws | Examples let typed exceptions propagate |
| DI | `get_it` for full graph | `RepositoryProvider` for non-bloc deps |
| TDD | Mandatory; lefthook + CI enforce | `bloc_test` is a tool, not a workflow |
| Pagination | Sealed `LoadingMore` variant | Flat `Initial / Success / Failure + hasReachedMax` |
| Functional types | No `Either` / `dartz` | Silent — neither endorsed nor banned |

If a rule feels too strict for a specific project, supersede it with a new entry in **that project's** local MEMORY.md — never silently deviate.

---

## Updating the skill

This skill ships with a versioned `MEMORY.md`. To change a rule:

1. Append a new dated entry under "Decision log" describing what changes and why.
2. If the change supersedes an earlier decision, reference it by date.
3. Update `SKILL.md` and any affected templates / references / agents.
4. Bump the `version:` field in `SKILL.md` frontmatter.

The MEMORY file is the spine. SKILL.md and templates are the limbs.

For ecosystem updates (Flutter SDK bumps, package version bumps), the e2e flow is:

```sh
# Spin up a throwaway test project to verify the templates still resolve.
cd /tmp && flutter create skill_test_app --org com.example
cp -r /path/to/flutter-bloc-architect/templates/pubspec.yaml skill_test_app/
cp -r /path/to/flutter-bloc-architect/templates/lib skill_test_app/
cd skill_test_app
flutter pub get && flutter analyze && flutter test
```

Any breakage gets fixed in the templates, not in the throwaway project.

---

## What this skill is NOT

- **A boilerplate generator with a magic CLI.** The `/configure-flutter-app` slash command is a Claude-driven pipeline, not a standalone tool. It runs from inside a Claude Code session.
- **A general Flutter architecture guide.** It encodes one specific opinionated architecture. If you want Riverpod, Provider, freezed, dartz, or `injectable`, fork and rewrite — they're all explicitly rejected.
- **A backend or auth provider.** `AuthRepository` is the contract; the data source you wire it to (Firebase Auth, custom REST, Auth0, etc.) is project-by-project.
- **A design system.** It ships Material 3 with a swappable seed color, Inter font, and a state-widget library (`PageLoading`, `EmptyState`, `PageError`, etc.). Anything beyond that is project work.

---

## Troubleshooting

**`flutter pub get` fails on `intl` resolution.**
The skill pins `intl: any` so it always defers to whatever `flutter_localizations` requires. If your local pubspec hardpins a version, remove the constraint.

**`HydratedStorageDirectory` undefined.**
You're on `hydrated_bloc < 10.x`. The skill requires `^10.1.1`. Check `pubspec.yaml`.

**`flutter build apk` fails with AGP 9 / `android.newDsl`.**
Environmental, not skill-related. Update Flutter SDK or follow the [AGP 9 migration guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-agp-9). Web + iOS + desktop builds are unaffected.

**`flutter analyze` shows ~80 info messages about `always_use_package_imports`.**
The templates use relative imports because they don't know the project name in advance. `/configure-flutter-app` rewrites them to `package:<your_app>/...` during the substitution step. If you copied templates manually, run a find/replace.

**Lefthook blocks a commit because "lib/ changed without test/ changing."**
That's the TDD diff check working as intended. Write the failing test first, stage both `lib/` and `test/` together. `git commit --no-verify` is the emergency escape; it gets caught again by the CI diff-check job.

**The bloc-verifier agent flags a rule I disagree with.**
Read the rationale in the relevant `references/*.md` callout. If the rationale doesn't apply to your project's context, supersede the rule in your project's local `MEMORY.md`. Don't silently fight the lint.

---

## License + provenance

This skill is Robby's personal architectural opinion, encoded so it doesn't have to be re-litigated every project. Use it, fork it, change it. The patterns inside are derived from the official BLoC team's documentation; quoted excerpts and URLs are in `MEMORY.md` and the references.
