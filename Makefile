# Uses the FVM-pinned Flutter when FVM is installed, the global one otherwise.
# Override with e.g. `make test FLUTTER=flutter DART=dart`.
ifneq ($(shell command -v fvm 2>/dev/null),)
FLUTTER ?= fvm flutter
DART ?= fvm dart
else
FLUTTER ?= flutter
DART ?= dart
endif

PACKAGES := . \
	example/simple_app \
	example/multi_packages_app/app \
	example/multi_packages_app/theme

.PHONY: full-checks analyze test gen-golden deps

## Run analyze then test on the package and all example apps.
full-checks: analyze test

## Fetch dependencies for the package and all example apps.
deps:
	@set -e; for pkg in $(PACKAGES); do \
		echo "==> pub get: $$pkg"; \
		(cd $$pkg && $(FLUTTER) pub get); \
	done

## Check formatting and run the analyzer on the package and all example apps.
analyze: deps
	@set -e; for pkg in $(PACKAGES); do \
		echo "==> format: $$pkg"; \
		(cd $$pkg && $(DART) format --set-exit-if-changed lib test); \
		echo "==> analyze: $$pkg"; \
		(cd $$pkg && $(FLUTTER) analyze --no-pub lib test); \
	done

## Run the tests (including goldens) of the package and all example apps.
test: deps
	@set -e; for pkg in $(PACKAGES); do \
		echo "==> test: $$pkg"; \
		(cd $$pkg && $(FLUTTER) test --no-pub --test-randomize-ordering-seed random); \
	done

## Regenerate the golden files of the package and all example apps.
gen-golden: deps
	@set -e; for pkg in $(PACKAGES); do \
		echo "==> update goldens: $$pkg"; \
		(cd $$pkg && $(FLUTTER) test --no-pub --update-goldens); \
	done
