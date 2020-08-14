<h1 align="center">
    Xikolo iOS App
</h1>

<img align="center" src="assets/banner.png?raw=true" alt="xikolo-ios banner" width="933" />


<p align="center">
    iOS application for openHPI, openSAP, mooc.house, lernen.cloud and OpenWHO
</p>

## Development Toolchain

- Xcode 11.5
- bundler: `gem install bundler`

The following tools will be installed via bundler:
- [CocoaPods](https://cocoapods.org/)
- [fastlane](https://fastlane.tools/)

The following tools will be installed via CocoaPods:
- [SwiftLint](https://github.com/realm/SwiftLint)
- [BartyCrouch](https://github.com/Flinesoft/BartyCrouch)

## Contribute to _xikolo-ios_

Take a look at our [Contribution Guide](CONTRIBUTING.md) to learn about the key components, our development process, the tools we use, programming guidelines and more.

### How to Get Started

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

1. Copy the credentials plist dummy file
   ```
   cp iOS-UITests/Credentials.plist.dummy iOS-UITests/Credentials-default.plist
   ```
1. Enter your login credentials for testing
1. To create a brand specific credentials plist
   ```
   cp iOS-UITests/Credentials.plist.dummy iOS-UITests/Credentials-<BRAND_NAME>.plist
   ```

## Code of Conduct
Help us keep this project open and inclusive. Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## License
This project is licensed under the terms of the MIT license. See the [LICENSE](LICENSE) file.
