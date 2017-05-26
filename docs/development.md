## Development environment

### Getting started

Using macOS based development environment is required

### Prerequisites
The following dependencies must be installed to successfully compile, test and run the project:

  - Xcode >= 8.3
  - Cocoapods

### Download source code

Clone the GIT repository

    git clone https://github.com/suomenriistakeskus/oma-riista-ios.git

### Setup project

Install pods

    pod install

Open project with Xcode

Create Riista-ios/Keys.plist
  - Add key MapsApiKey with the value of your Google Maps API key
  - Value can be left empty if you don’t want to display map tiles
