# Theming

Single source of truth for colors, typography, and component shapes is `core/theme/`. Three files:

- `app_colors.dart` — color palette (brand, semantic, neutral).
- `app_text_styles.dart` — `TextTheme` definition.
- `app_theme.dart` — `ThemeData` factory composing the above.

`app/app.dart` passes `AppTheme.light` and `AppTheme.dark` to `MaterialApp.router`.

## Material 3 — mandatory

**`useMaterial3: true` only.** No M2 fallbacks. Component themes follow M3 defaults; the template only overrides what's reasonable to standardize (`elevatedButtonTheme`, `inputDecorationTheme`, `cardTheme`, `appBarTheme`).

**Dark + light theme parity is mandatory from day one.** Every project ships both `AppTheme.light` and `AppTheme.dark`. `MaterialApp.router` is wired with both regardless of whether the project plans to expose a manual toggle.

## ColorScheme.fromSeed — single source of truth

The skill builds both schemes from a single seed color via `ColorScheme.fromSeed`. Material 3 generates compliant contrast pairs automatically — accessibility contrast checks pass without per-color tuning.

```dart
final lightScheme = ColorScheme.fromSeed(
  seedColor: AppColors.seed,
  brightness: Brightness.light,
);
final darkScheme = ColorScheme.fromSeed(
  seedColor: AppColors.seed,
  brightness: Brightness.dark,
);
```

`AppColors.seed` is the single hex constant projects override per brand. Everything else flows from it.

## Adding a new color

1. Add a `static const` to `AppColors` only if it's outside the `ColorScheme` slots.
2. Prefer reading from `Theme.of(context).colorScheme.X` everywhere — `primary`, `surface`, `onSurface`, `error`, `outline`, etc.
3. For brand-specific tokens that don't fit any `ColorScheme` role (a custom highlight glow, etc.), use a `ThemeExtension` (see below) — never hardcode `AppColors.X` in widget code outside the theme.

## Dark mode toggle

Three approaches:

1. **System-driven (default in template)**: `themeMode: ThemeMode.system`. Honors the OS setting.
2. **App-driven, persisted**: a `ThemeCubit extends HydratedCubit<ThemeMode>` that `MaterialApp.router` reads via `BlocBuilder<ThemeCubit, ThemeMode>`. User can pick light/dark/system in Settings.
3. **Per-route override**: rare; needed only for specific brand pages with fixed light/dark.

For (2), the cubit looks like:

```dart
class ThemeCubit extends HydratedCubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);
  void setLight() => emit(ThemeMode.light);
  void setDark() => emit(ThemeMode.dark);
  void setSystem() => emit(ThemeMode.system);

  @override
  ThemeMode? fromJson(Map<String, dynamic> json) =>
      ThemeMode.values.firstWhereOrNull((m) => m.name == json['mode']);
  @override
  Map<String, dynamic>? toJson(ThemeMode state) => {'mode': state.name};
}
```

Register as a singleton in `injection.dart`. Provide in `MultiBlocProvider` at app root.

## Custom fonts — Inter is the default

The skill bundles **Inter** as a single variable font (one file covers all weights):

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-VariableFont.ttf
```

`AppTextStyles` sets `fontFamily: 'Inter'` on the base text theme; M3's typescale carries through automatically. Inter is licensed under SIL OFL 1.1 (commercial-use safe to bundle).

To swap fonts: replace the file in `assets/fonts/`, update the `family:` and `asset:` lines in `pubspec.yaml`, and update the `fontFamily:` reference in `app_theme.dart`. Three edits.

`google_fonts` (runtime download) is **not** used. Initial-launch latency and a network dependency for typography are unacceptable for production apps.

## Theme extension for app-specific tokens

If you have brand tokens that don't fit `ColorScheme` (e.g., a "highlight glow" color, custom spacing tokens), use `ThemeExtension`:

```dart
@immutable
class AppExtras extends ThemeExtension<AppExtras> {
  const AppExtras({required this.spacingUnit, required this.glow});
  final double spacingUnit;
  final Color glow;

  @override
  AppExtras copyWith({double? spacingUnit, Color? glow}) =>
      AppExtras(spacingUnit: spacingUnit ?? this.spacingUnit, glow: glow ?? this.glow);

  @override
  AppExtras lerp(ThemeExtension<AppExtras>? other, double t) =>
      other is! AppExtras ? this : AppExtras(
        spacingUnit: lerpDouble(spacingUnit, other.spacingUnit, t)!,
        glow: Color.lerp(glow, other.glow, t)!,
      );
}
```

Add via `ThemeData(extensions: [const AppExtras(...)])`. Read in widgets with `Theme.of(context).extension<AppExtras>()`.

## When to reach for `flex_color_scheme`

If you find yourself overriding 10+ component themes by hand, switch to `flex_color_scheme` (situational package). It generates fully-themed `ThemeData` from a small config and includes M3 expressivity not yet in raw Flutter. Don't add it on day one — earn it.
