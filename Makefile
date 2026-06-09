.PHONY: build check lint test verify

TRAVELLER_CONSTANTS := traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java

check: verify

lint:
	sh -n scripts/check-baseline.sh
	sh -n scripts/prepare-traveller-constants.sh
	scripts/check-baseline.sh

test:
	scripts/check-baseline.sh

build:
	@if [ -z "$${ANDROID_HOME}$${ANDROID_SDK_ROOT}" ]; then \
		echo "Android SDK not configured; skipping Traveller Gradle build"; \
	elif [ ! -f "$(TRAVELLER_CONSTANTS)" ]; then \
		echo "Traveller Constants.java not configured; skipping Traveller Gradle build"; \
	else \
		cd traveller-android-app && ./gradlew assembleDebug --no-daemon; \
	fi

verify: lint test build
