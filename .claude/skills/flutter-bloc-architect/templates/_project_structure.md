# Project Structure

The full layout every Flutter project under this skill uses. Copy this tree into a new project at init.

```
my_flutter_app/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── .gitignore
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart                # MaterialApp.router + theme + MultiBlocProvider for app-wide blocs
│   │   ├── injection.dart          # get_it registration, ordered bottom-up
│   │   └── bloc_observer.dart      # global onChange/onError logging
│   ├── core/
│   │   ├── constants/
│   │   │   └── env.dart            # Env.apiUrl etc.
│   │   ├── error/
│   │   │   ├── result.dart         # sealed Result<T, F>
│   │   │   ├── failures.dart       # sealed AppFailure hierarchy
│   │   │   └── exceptions.dart     # sealed AppException hierarchy
│   │   ├── network/
│   │   │   ├── dio_module.dart     # Dio factory + interceptor wiring
│   │   │   ├── auth_interceptor.dart
│   │   │   └── error_interceptor.dart
│   │   ├── storage/
│   │   │   └── secure_storage.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   └── app_text_styles.dart
│   │   ├── router/
│   │   │   ├── app_router.dart
│   │   │   └── routes.dart         # route name constants
│   │   ├── extensions/             # context, datetime, string extensions
│   │   └── widgets/
│   │       ├── loading_view.dart
│   │       ├── error_view.dart
│   │       └── empty_state.dart
│   ├── features/
│   │   └── <feature_name>/
│   │       ├── data/
│   │       │   ├── datasources/
│   │       │   ├── models/         # @JsonSerializable DTOs
│   │       │   └── repositories/   # *_repository_impl.dart
│   │       ├── domain/
│   │       │   ├── entities/
│   │       │   └── repositories/   # ABSTRACT
│   │       └── presentation/
│   │           ├── bloc/
│   │           │   ├── <feature>_bloc.dart
│   │           │   ├── <feature>_event.dart
│   │           │   └── <feature>_state.dart
│   │           ├── pages/
│   │           └── widgets/
│   └── l10n/
│       ├── app_en.arb
│       └── app_es.arb              # add locales as needed
├── test/                           # mirrors lib/ exactly
│   ├── core/
│   ├── features/
│   │   └── <feature_name>/
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   └── helpers/
│       ├── test_helpers.dart
│       └── fixtures/
├── integration_test/
└── assets/
    ├── images/
    ├── icons/
    └── fonts/
```

## Naming conventions

- Folders and files: `snake_case`. Always.
- Dart classes: `UpperCamelCase`.
- Dart variables, methods, parameters: `lowerCamelCase`.
- Constants: `lowerCamelCase` (Dart convention, not `SCREAMING_SNAKE_CASE`).
- Private members: leading underscore `_privateField`.
- Test files: `<source_file_name>_test.dart`.
- Bloc trio: `<feature>_bloc.dart`, `<feature>_event.dart`, `<feature>_state.dart`.
- Repository abstract vs impl: `auth_repository.dart` (abstract) lives in `domain/`, `auth_repository_impl.dart` (concrete) lives in `data/`.

## Why this layout

**Feature-first not layer-first.** Two devs (or two agents) can work on `auth/` and `cart/` in parallel with zero merge conflicts. Deleting a feature = `rm -rf features/that_one`. Removing a feature in a layer-first layout means hunting through every top-level folder.

**`core/` is shared, not a junk drawer.** Anything in `core/` must be genuinely cross-feature. If only one feature uses it, it belongs in that feature.

**`app/` is the only place that knows the full feature list.** `lib/app/injection.dart` enumerates every repo and bloc. `lib/core/router/app_router.dart` enumerates every route. Adding or removing a feature touches these two files and the feature folder — nothing else.
