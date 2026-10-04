fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android metadata

```sh
[bundle exec] fastlane android metadata
```

Upload metadata, store images, and screenshots to Google Play Store without binary

### android build

```sh
[bundle exec] fastlane android build
```

Build a signed release App Bundle locally (version code from BUILD_NUMBER or a timestamp)

### android internal

```sh
[bundle exec] fastlane android internal
```

Build and upload to the internal testing track

### android alpha

```sh
[bundle exec] fastlane android alpha
```

Build and upload to the closed testing (alpha) track

### android beta

```sh
[bundle exec] fastlane android beta
```

Build and upload to the open/closed beta track

### android production

```sh
[bundle exec] fastlane android production
```

Build and upload to production

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
