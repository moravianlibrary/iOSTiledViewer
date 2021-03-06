#
# Be sure to run `pod lib lint iOSTiledViewer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'iOSTiledViewer'
  s.version          = '0.2.7'
  s.summary          = 'High-resolution images Viewer with support for IIIF and Zoomify protocols.'
  s.description      = <<-DESC
                        The library can be used to display high-resolution images with usage of IIIF Image API or Zoomify standards. It is able to display a raw image file of formats JPG, PNG, GIF and WebP.
                       DESC

  s.homepage         = 'https://github.com/moravianlibrary/iOSTiledViewer'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jakub Fiser' => 'fiser33@seznam.cz' }

  s.source           = { :git => 'https://github.com/moravianlibrary/iOSTiledViewer.git', :tag => s.version.to_s }
  s.source_files     = 'iOSTiledViewer/Classes/**/*'
  s.frameworks       = 'UIKit', 'Foundation'

  s.ios.deployment_target = '9.0'

  s.dependency 'SDWebImage/WebP'
  
end
