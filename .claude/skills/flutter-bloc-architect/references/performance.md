# Performance

How to keep apps fast under this skill's architecture. Load when working on a screen with animations, long lists, video, charts, or measurable jank.

The five baseline rules in `SKILL.md` are mechanical (verifier-enforced where possible). This reference covers judgment calls and patterns the verifier can't reliably flag.

## RepaintBoundary — when to use it

`RepaintBoundary` isolates a subtree's painting layer. When the subtree marks itself dirty, the dirty region stops at the boundary instead of cascading up. The trade-off is real: each boundary creates a new compositing layer with its own GPU texture and rasterization cost.

### Use it when

- **Lottie animations.** They repaint every frame; the parent rarely needs to follow.
- **Video players** (`video_player`, `chewie`).
- **Custom paint** widgets that animate (`CustomPainter` with a `repaint` Listenable, particle systems, draw-on-touch surfaces).
- **Shimmer placeholders** (already done in the shipped `core/widgets/state/skeleton/shimmer.dart`).
- **Animated icons** that loop while neighboring widgets are static.
- **Charts** that update on a stream (e.g., live-data line charts).
- **Each item in a long scrolling list** where items are visually complex (images + text + interactions). Wrap the item itself, not the whole list.

### Don't use it when

- The widget rarely changes (it's overhead with no payoff).
- The widget is small (e.g., a single `Text`).
- The parent already repaints whenever the child does (boundary saves nothing).
- You haven't profiled and have no measurable jank — speculative wrapping is a regression.

### The DevTools test

Open Flutter DevTools → Performance tab → toggle **"Highlight Repaints"**. Every repainted region flashes a different color. Run the suspect screen:

- If a tiny animating widget is causing a giant region to flash, add a `RepaintBoundary` around the animator.
- If a `RepaintBoundary` you added doesn't change the highlighted region, remove it — it's not earning its keep.

This is the only honest way to decide. Profile before adding boundaries.

### Pattern

```dart
class WeatherIconAnimation extends StatelessWidget {
  const WeatherIconAnimation({super.key, required this.condition});
  final WeatherCondition condition;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Lottie.asset(_assetFor(condition)),
    );
  }
}
```

## BlocBuilder vs BlocSelector

For any non-trivial widget under a `BlocBuilder`, use `buildWhen` to gate rebuilds. When the widget reads only one slice of state, `BlocSelector` is cleaner and faster:

```dart
// Rebuilds only when state.cartCount changes — even if state.user changes.
BlocSelector<CartBloc, CartState, int>(
  selector: (state) => state.items.length,
  builder: (context, count) => Badge(
    label: Text('$count'),
    child: const Icon(Icons.shopping_cart),
  ),
)
```

`BlocSelector` skips the rebuild when the *selected* value is `==` to the previous selection, regardless of whether other state fields changed. It's the preferred shape for app-wide blocs (auth, theme, locale) consumed by many small widgets.

For `BlocBuilder` with `buildWhen`:

```dart
BlocBuilder<FeedBloc, FeedState>(
  buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
  builder: (context, state) => switch (state) {
    FeedLoading() => const PageLoading(),
    FeedLoaded(:final items) => FeedList(items),
    FeedError(:final failure) => PageError(...),
    _ => const SizedBox.shrink(),
  },
)
```

The `runtimeType != runtimeType` predicate avoids rebuilding when only payload contents change inside the same state subclass — useful for paginated `FeedLoaded` where item-list updates should re-render but state-class transitions matter for layout.

## ListView.builder — never `ListView(children: [...])` for variable lists

`ListView(children: [...])` builds **every child eagerly**, even off-screen ones. For lists of more than a handful of items it's a catastrophe — a 1000-item list builds 1000 widgets at first frame.

`ListView.builder` lazily builds only the visible items + a small overdraw buffer. Same rule applies to `GridView.builder`, `SliverList.builder`, `SliverGrid.builder`.

The exceptions where `ListView(children: [...])` is fine:

- Fixed list with ≤5 items, all small, all known at compile time.
- The "list" is actually a settings page with `ListTile` rows that are visually heterogeneous and total under ~10.

For everything else: `.builder` constructor.

## Image cache sizing

`Image.network` and `Image.asset` decode the source image at its native resolution by default. A 4000×3000 photo decoded into a 100×100 thumbnail wastes ~48 MB of GPU memory per image — multiply by 50 visible thumbnails and the app OOMs on low-end devices.

Always pass `cacheWidth` / `cacheHeight` sized to the actual render dimensions:

```dart
Image.network(
  url,
  width: 80,
  height: 80,
  cacheWidth: 80 * MediaQuery.devicePixelRatioOf(context).round(),
  cacheHeight: 80 * MediaQuery.devicePixelRatioOf(context).round(),
  fit: BoxFit.cover,
)
```

Multiply by `devicePixelRatio` so retina displays still get crisp images without over-decoding.

For network images at scale, `cached_network_image` (situational) gives you disk caching for free; pass `memCacheWidth` / `memCacheHeight` to its widget the same way.

## AnimatedBuilder — use the `child:` parameter to skip rebuilding the static subtree

`AnimatedBuilder` rebuilds its `builder` on every animation tick. If the builder constructs an expensive widget tree that doesn't actually depend on the animation value, you're rebuilding it 60×/sec for no reason.

The `child:` parameter is the escape: build the static subtree once, pass it in, the builder receives it as a parameter:

```dart
AnimatedBuilder(
  animation: _controller,
  child: const ExpensiveStaticChild(),       // built once
  builder: (context, child) => Transform.scale(
    scale: _controller.value,
    child: child,                             // reused, not rebuilt
  ),
)
```

Same pattern applies to `AnimatedSwitcher`, `TweenAnimationBuilder`, and any `ListenableBuilder`.

## Hot-path animations — avoid bloc emissions

A bloc emit fires the BlocObserver, runs through `Equatable` props comparison, schedules a rebuild, and walks the widget tree. That's overhead measured in milliseconds. For 60fps animations driven by user input (drag-to-reorder, gesture-driven sheets, scrubber UIs), use a `ValueNotifier<double>` or an `AnimationController` directly and bind via `ValueListenableBuilder` / `AnimatedBuilder`. Reserve bloc emissions for state changes the user perceives, not animation frames.

## State-preservation across tabs

`StatefulShellRoute.indexedStack` (in this skill's `core/router/shell.dart`) keeps each tab's `Navigator` alive across switches by default. Within a single tab, if you're using `TabBarView` for sub-tabs, set `keepAlive: true` on each tab's `AutomaticKeepAliveClientMixin` so scroll position and bloc state survive switching.

## Profiling — the only honest source of truth

Performance "rules" without measurement are folklore. Run **`flutter run --profile`** on a real device (not the simulator — it lies about timing), open DevTools, and:

1. **CPU profiler** — find the hottest functions. Anything called 60×/sec that takes more than 1ms is a problem.
2. **Performance tab → Highlight Repaints** — see which regions repaint and how often.
3. **Memory tab** — watch for image-cache bloat. Spikes during scrolling = missing `cacheWidth/cacheHeight`.
4. **Timeline (Performance Overlay)** — `flutter run --profile` with the overlay shows GPU/CPU frame budget. Spikes in the GPU bar = expensive paints (consider `RepaintBoundary`); spikes in the CPU bar = expensive `build()` (consider `BlocSelector` or `const`).

Don't add a `RepaintBoundary` because this doc says so. Add it because the overlay shows a region repainting that doesn't need to.

## Common offenders to scan for

- `Opacity(opacity: x)` on a complex subtree — repaints the whole subtree every animation tick. Replace with `FadeTransition` or `AnimatedOpacity` which use `RepaintBoundary` internally.
- `ClipRRect` / `ClipPath` on animated content — clipping forces a save layer. Use `BorderRadius` on a `Container.decoration` if possible, or `ClipRRect` outside the animator.
- Building widgets in `setState` callbacks based on cheap-but-non-`const` literals — adds GC pressure. Hoist to `static const` fields.
- `MediaQuery.of(context)` in builders that don't need it — listens to all MediaQuery changes. Use `MediaQuery.sizeOf(context)` / `MediaQuery.textScalerOf(context)` for granular subscription.

## What NOT to do

- Do not wrap the entire `MaterialApp` body in a `RepaintBoundary`. It defeats the purpose; everything below is one boundary.
- Do not add `RepaintBoundary` "just in case." Measure first.
- Do not pre-cache every image at every size. Disk + memory cost.
- Do not switch from `Bloc` to `ValueNotifier` for normal app state to "improve performance." The bloc layer's overhead is sub-millisecond per emit; if it's hot enough to matter, the screen is animating, and animations belong on a `ValueNotifier` / `AnimationController` *in addition to* the bloc, not instead of it.
