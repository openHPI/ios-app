<h1 align="center">
    Xikolo iOS App
</h1>

<p align="center">
    <img src="assets/banner.png?raw=true" alt="xikolo-ios banner" />
</p>

<p align="center">
    iOS application for the HPI MOOC Platform
</p>

## Development Toolchain

- Xcode 12.5
- bundler: `gem install bundler`

The following tools will be installed via bundler:
- [CocoaPods](https://cocoapods.org/)
- [fastlane](https://fastlane.tools/)

The following tools will be installed via CocoaPods:
- [SwiftLint](https://github.com/realm/SwiftLint)
- [BartyCrouch](https://github.com/Flinesoft/BartyCrouch)

## Contribute

Take a look at our [Contribution Guide](CONTRIBUTING.md) to learn about the key components, our development process, the tools we use, programming guidelines and more.

### Get Started

1. Clone this repository 
1. Install development tools
   ```
   bundle install
   ```
1. Update CocoaPods index & install dependencies
   ```
   bundle exec pod repo update
   bundle exec pod install
   ```
1. Copy initial branded app assets to prevent build errors
   ```
   cp -R ./iOS/Branding/openHPI/assets-ios-brand.xcassets ./iOS/assets-ios-brand.generated.xcassets
   ```
1. Open `xikolo-ios.xcworkspace` (or simply `xed .` in the terminal)
1. Build and run one of the targets

### Setup Testing

1. Create the initial credentials file (to avoid build errors on the first test run)
   ```
   cp iOS-UITests/Credentials.plist.dummy iOS-UITests/Credentials.plist
   ```
1. Create the default credentials file
   ```
   cp iOS-UITests/Credentials.plist.dummy iOS-UITests/Credentials-default.plist
   ```
1. Optional: Create a brand specific credentials file
   ```
   cp iOS-UITests/Credentials.plist.dummy iOS-UITests/Credentials-<BRAND_NAME>.plist
   ```
1. Enter your login credentials for testing in the respective credentials files

## Overall Architecture

For the overall architecture, we follow a plain MVC approach. However we make use of some reactive programming by using futures and promises provided by [BrightFutures](https://github.com/Thomvis/BrightFutures).

### Naming Schema

The application fetches multiple resources from the backend. For a `Resource`, all related classes follow most of the time the following naming schema.
 - `Resource`: The respective CoreData model
 - `ResourceListViewController`: The view controller listing multiple resources -- usually in a table or collection view
 - `ResourceViewController`: The detail view controller for a single resource
 - `ResourceHelper`: The controller resonsible for synchronizing the resources with the server
 - `ResourceHelper+FetchRequests`: CoreData fetch requests for the resource

### Modules & Targets

To allow better code reusability, we restructured the codebase in multiple modules. For one, this reduces the application size as resources are not additionally bundled when used in an app extension. It also prevents you from going crazy by ticking hundreds of checkboxes for the target membership.  
Important modules are listed below. If applicalble and neccesary, those modules can be further split up.

#### Common

The `Common` module holds the core functionality of the app, which is required in all targets. It includes the CoreData models, API abstraction layer, common functionalities and generic helpers.

#### Stockpile

The `Stockpile` module is responsible for retrieving resources from the backend and synchronizing them with the local storage. It is capable of sending network requests depending on the protocol of the backend. 

#### Binge

The `Binge` module provides a custom video player which in contrast to `AVPlayerViewController` allows entering the full-screen mode programmatically and provides controls for changing the playback rate.

#### iOS

The `iOS` target is the main application.

#### TodayExtension

The `TodayExtension` target provides the today app extension (widget in the today view, considered legacy in iOS 14 and later).

#### WidgetExtension

The `WidgetExtension` target provides the widget extension for iOS 14 and later (widgets on homescreen)

## Code of Conduct

Help us keep this project open and inclusive. Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## License

This project is licensed under the terms of the MIT license. See the [LICENSE](LICENSE) file.
