#
# Be sure to run `pod lib lint SignalCoreKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SignalCoreKit"
  s.version          = "1.0.0"
  s.summary          = "A Swift & Objective-C library used by other Signal libraries."

  s.description      = <<-DESC
A Swift & Objective-C library used by other Signal libraries.
  DESC

  s.homepage         = "https://github.com/signalapp/SignalCoreKit"
  s.license          = 'GPLv3'
  s.author           = { "iOS Team" => "ios@signal.org" }
  s.source           = { :git => "https://github.com/signalapp/SignalCoreKit.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/signalapp'

  s.platform     = :ios, '9.0'
  #s.ios.deployment_target = '9.0'
  #s.osx.deployment_target = '10.9'
  s.requires_arc = true

  s.source_files  = 'SignalCoreKit/src/**/*.{h,m,mm,swift}', 'SignalCoreKit/Private/**/*.{h,m,mm,swift}'

  s.public_header_files = 'SignalCoreKit/src/*.h', 'SignalCoreKit/src/**/*.h'

  # We want to use modules to avoid clobbering CocoaLumberjack macros defined
  # by other OWS modules which *also* import CocoaLumberjack. But because we
  # also use Objective-C++, modules are disabled unless we explicitly enable
  # them
  s.compiler_flags = "-fcxx-modules"

  s.prefix_header_file = 'SignalCoreKit/SCKPrefix.h'
  s.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DSQLITE_HAS_CODEC' }

  s.resources = ["SignalCoreKit/Resources/Certificates/*"]

  s.dependency 'CocoaLumberjack'


  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'SignalCoreKitTests/src/**/*.{h,m,swift}'
  end
end
