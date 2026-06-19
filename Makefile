.PHONY: build check lint test verify

override ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

check: verify

lint:
	sh -n $(ROOT)scripts/check-baseline.sh
	sh -n $(ROOT)scripts/prepare-traveller-constants.sh
	$(ROOT)scripts/check-baseline.sh

test:
	$(ROOT)scripts/test-build-gate.sh
	$(ROOT)scripts/test-constants-generation.sh
	$(ROOT)scripts/test-task-description-normalizer.sh

build:
	@if [ -z "$${ANDROID_HOME}$${ANDROID_SDK_ROOT}" ]; then \
		echo "Android SDK not configured; refusing to skip Traveller Gradle build" >&2; \
		exit 1; \
	else \
		cd $(ROOT)traveller-android-app && ./gradlew lint assembleDebug --no-daemon; \
	fi

verify: lint test build
