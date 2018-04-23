# iOSTiledViewer

<!-- [![Pod Version](http://img.shields.io/cocoapods/v/CocoaLumberjack.svg?style=flat)](http://cocoadocs.org/docsets/iOSTiledViewer/) -->
[![Dependency Status](https://www.versioneye.com/objective-c/sdwebimage/badge.svg?style=flat)](https://www.versioneye.com/objective-c/iostiledviewer)
[![Reference Status](https://www.versioneye.com/objective-c/iostiledviewer/reference_badge.svg?style=flat-square)](https://www.versioneye.com/objective-c/iostiledviewer/references)

[Release Notes](https://github.com/moravianlibrary/iOSTiledViewer/blob/master/release_notes.txt)

[Documentation](http://htmlpreview.github.io/?https://github.com/moravianlibrary/iOSTiledViewer/blob/master/docs/index.html)

The library displays large image files effectively without quality loss. It can display files that support protocol IIIF or Zoomify as well as an ordinary image of format JPG, PNG, GIF and WebP.

## Requirements

iOS 9.0+

## Installation

iOSTiledViewer is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'iOSTiledViewer'
```

## Usage

The entry point of the library is class **ITVScrollView** and its method `loadImage(_ imageUrl: String, api: ITVImageAPI)`. Please read the documentation (link above) for more information.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Author

Jakub Fiser, fiser33@seznam.cz

## License

iOSTiledViewer is available under the MIT license. See the LICENSE file for more info.
