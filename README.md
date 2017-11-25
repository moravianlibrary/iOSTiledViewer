# iOSTiledViewer

[Release Notes](https://www.fi.muni.cz/~xfiser1/mp/itv/notes.txt)

[Documentation](https://www.fi.muni.cz/~xfiser1/mp/itv/docs/index.html)

The library displays large image files effectively without quality loss. It can display files that support protocol IIIF or Zoomify as well as an ordinary image of format JPG, PNG, GIF and WebP.

## Requirements

iOS 9.0+

## Installation

iOSTiledViewer is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

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
