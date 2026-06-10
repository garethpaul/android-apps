.PHONY: build check lint test verify

ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TRAVELLER_CONSTANTS := $(ROOT)traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java

check: verify

lint:
	sh -n $(ROOT)scripts/check-baseline.sh
	sh -n $(ROOT)scripts/prepare-traveller-constants.sh
	$(ROOT)scripts/check-baseline.sh

test:
	$(ROOT)scripts/check-baseline.sh

build:
	@if [ -z "$${ANDROID_HOME}$${ANDROID_SDK_ROOT}" ]; then \
		echo "Android SDK not configured; skipping Traveller Gradle build"; \
	elif [ ! -f "$(TRAVELLER_CONSTANTS)" ]; then \
		echo "Traveller Constants.java not configured; skipping Traveller Gradle build"; \
	else \
		cd $(ROOT)traveller-android-app && ./gradlew assembleDebug --no-daemon; \
	fi

verify: lint test build
