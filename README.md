# Android Apps

Personal Android app experiments. The current checked-in project is the legacy
Traveller app under `traveller-android-app/`.

## Traveller Toolchain

Traveller uses an old Android build stack:

- Gradle wrapper 1.10
- Android Gradle Plugin 0.8.3
- compile SDK 19 / target SDK 19
- Android build-tools 19.1.0
- Parse 1.5.0 from `traveller/libs/Parse-1.5.0.jar`

Configure an Android SDK path before running Gradle:

```sh
export ANDROID_HOME=/path/to/android-sdk
```

or create an untracked `traveller-android-app/local.properties` file:

```properties
sdk.dir=/path/to/android-sdk
```

## Parse Credentials

`App.java` expects a local `Constants.java` file with Parse credentials. Copy
the template and fill it with local values:

```sh
cp traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java.example \
  traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java
```

`Constants.java` is ignored and must not be committed with real credentials.

## Verify

Run the SDK-free baseline check first:

```sh
scripts/check-baseline.sh
```

Then run Gradle from the nested project directory after configuring an Android
SDK:

```sh
cd traveller-android-app
./gradlew tasks --no-daemon
./gradlew assembleDebug --no-daemon
```

If Gradle reports that the SDK location cannot be found, configure
`ANDROID_HOME` or `local.properties` and rerun the command. If it reports
`failed to find Build Tools revision 19.1.0`, install that legacy build-tools
package into the configured SDK.

## Modernization Notes

The current baseline pins the Android Gradle Plugin and appcompat dependencies
instead of resolving dynamic `+` versions, and uses HTTPS for wrapper and Maven
resolution. A future modernization pass should migrate Gradle, the Android
Gradle Plugin, SDK levels, appcompat/AndroidX, Parse, credential injection, and
Android tests together in an SDK-capable environment.
