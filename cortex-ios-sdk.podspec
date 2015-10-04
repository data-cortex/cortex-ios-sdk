#
# Be sure to run `pod lib lint cortex-ios-sdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "cortex-ios-sdk"
  s.version          = "0.1.0"
  s.summary          = "data-cortex iOS SDK"
  s.description      = "iOS SDK to interact with data-cortex."

  s.homepage         = "https://github.com/data-cortex/cortex-ios-sdk"
  s.license          = 'MIT'
  s.author           = { "Yanko Bolanos" => "y@rem7.com" }
  s.source           = { :git => "https://github.com/data-cortex/cortex-ios-sdk.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'cortex-ios-sdk' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
