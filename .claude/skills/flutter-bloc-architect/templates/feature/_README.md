# Feature Scaffold

A complete three-layer feature template. Copy `feature/` to `lib/features/<your_feature>/` and substitute the placeholder name.

## Substitution map

The templates use `example` / `Example` as the placeholder feature name. Replace as follows:

| Placeholder | Substitute |
|---|---|
| `example` (lowercase, snake_case) | your feature name (e.g. `cart`, `auth`, `user_profile`) |
| `Example` (UpperCamelCase) | the corresponding class prefix (e.g. `Cart`, `Auth`, `UserProfile`) |

A safe sed substitution (run from inside the new feature folder):

```sh
# rename folder content
find . -type f -name "example_*.dart" -exec rename 's/example/cart/' {} \;

# rewrite identifiers (run twice — once per case)
find . -type f -name "*.dart" -exec sed -i '' 's/example/cart/g; s/Example/Cart/g' {} \;
```

Or invoke the `feature-scaffolder` agent (`agents/feature-scaffolder.md`) which handles substitution + DI wiring + route registration in one pass.

## What this scaffold gives you

- **Bloc trio** with native sealed state, `Equatable`, `@immutable`, `const` constructors, hand-written `copyWith`, and a `bloc_concurrency` transformer on the user-input event.
- **Repository pattern** with abstract domain class + concrete data impl returning `Result<T, AppFailure>`.
- **Data source** that throws typed `AppException`s.
- **Page** wired with `BlocProvider(create: (_) => getIt<ExampleBloc>())`.

Cubit and HydratedBloc variants:
- For load-only screens with no concurrency, see `_cubit_variant/`.
- For state that must survive app restart, see `_hydrated_variant/`.

## After scaffolding

1. Add the data source + repo + bloc to `lib/app/injection.dart` in the right layers.
2. Add the route to `lib/core/router/app_router.dart` and to `routes.dart`.
3. Run codegen: `dart run build_runner build --delete-conflicting-outputs`.
4. Add a test under `test/features/<feature>/`.
5. Run `flutter analyze && flutter test`.
