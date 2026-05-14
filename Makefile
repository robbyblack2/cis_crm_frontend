.PHONY: run run-dev run-web run-macos \
        build-prod build-dev build-web build-macos \
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

build-prod:
	flutter build apk --release

build-dev:
	flutter build apk --release --dart-define=FLAVOR=dev

build-web:
	flutter build web --release

build-macos:
	flutter build macos --release

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
