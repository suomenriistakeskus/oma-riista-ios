## Development environment

### Getting started

Using macOS based development environment is required

### Prerequisites
The following dependencies must be installed to successfully compile, test and run the project:

  - Xcode >= 11.0
  - Cocoapods

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

(Optional) Change backend if necessary (Riista-Ios/Environment.swift)
