#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint persistent_device_id.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'persistent_device_id'
  s.version          = '2.0.0'
  s.summary          = 'Persistent app-scoped device identifiers for Flutter.'
  s.description      = <<-DESC
Provides a persistent app-scoped device identifier for Flutter apps on iOS.
                       DESC
  s.homepage         = 'https://github.com/maeltoukap/persistent_device_id'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mael Toukap' => 'https://github.com/maeltoukap' }
  s.source           = { :path => '.' }
  s.source_files = 'persistent_device_id/Sources/persistent_device_id/**/*.swift'
  s.resource_bundles = {
    'persistent_device_id_privacy' => ['persistent_device_id/Sources/persistent_device_id/PrivacyInfo.xcprivacy']
  }
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'
end
