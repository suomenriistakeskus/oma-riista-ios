## Development environment

### Getting started

Using macOS based development environment is required

### Prerequisites
The following dependencies must be installed to successfully compile, test and run the project:

  - Xcode >= 11.0
    - if using Xcode 13, then at least version 13.2 is required
  - Cocoapods
  - JDK 11. Configured so that either
    - JAVA_HOME points to it or
    - `/usr/libexec/java_home -v 11` is able to find it

### Download source code

Clone the GIT repository

    git clone https://github.com/suomenriistakeskus/oma-riista-ios.git

### Setup project

Install pods

    pod install

Open project with Xcode

Add necessary plist files

1. Add necessary GoogleServices plist files under Firebase directory.
    - GoogleService-Info-Production.plist
    - GoogleService-Info-Staging.plist
    - GoogleService-Info-Dev.plist
    - these can be found e.g. from Firebase console

In order to build mobile-common lib JDK 11 is required. Add JAVA_HOME to .bash_profile e.g.

    export JAVA_HOME=/Applications/Android\ Studio.app/Contents/jre/Contents/Home/

or use JDK that can be found using `/usr/libexec/java_home -v 11`

(Optional) Change backend if necessary (Riista-Ios/Environment.swift)

