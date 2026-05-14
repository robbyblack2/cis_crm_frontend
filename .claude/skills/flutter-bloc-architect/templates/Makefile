# Makefile for a Flutter project under flutter-bloc-architect skill.
#
# Path A flavors: bare `flutter run` works (defaults to prod via dart-define).
# These targets exist for convenience and to lock CI commands.

.PHONY: run run-dev run-web run-macos run-windows run-linux \
        build-prod build-dev build-web build-macos build-windows build-linux \
        test analyze format coverage codegen icons splash clean

run:
	flutter run

run-dev:
	flutter run --dart-define=FLAVOR=dev

run-web:
	flutter run -d chrome

run-web-dev:
	flutter run -d chrome --dart-define=FLAVOR=dev

run-macos:
	flutter run -d macos

run-windows:
	flutter run -d windows

run-linux:
	flutter run -d linux

build-prod:
	flutter build apk --release

build-dev:
	flutter build apk --release --dart-define=FLAVOR=dev

build-web:
	flutter build web --release

build-macos:
	flutter build macos --release

build-windows:
	flutter build windows --release

build-linux:
	flutter build linux --release

test:
	flutter test

analyze:
	flutter analyze

format:
	dart format --set-exit-if-changed lib test

coverage:
	flutter test --coverage
	@command -v genhtml >/dev/null 2>&1 && genhtml coverage/lcov.info -o coverage/html || echo "Install lcov for HTML coverage report (brew install lcov)"

codegen:
	dart run build_runner build --delete-conflicting-outputs
	flutter gen-l10n

icons:
	dart run flutter_launcher_icons

splash:
	dart run flutter_native_splash:create

clean:
	flutter clean
	rm -rf build .dart_tool coverage
