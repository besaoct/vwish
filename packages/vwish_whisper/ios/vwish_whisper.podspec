# OWNER: AI-05 (placeholder created by AI-02's scaffold: builds without the native library)
#
# AI-05 adds the static WhisperCore.xcframework (built by tool/build_ios_xcframework.sh with
# CMake >= 3.28, deployment target 15.0, Metal only on iOS >= 16.4 and GPU family >= 6,
# Accelerate/BLAS off), ios/Classes/vw_whisper_forwarder.cpp, the PrivacyInfo.xcprivacy resource
# (DiskSpace E174.1) and raises the platform to 15.0 together with INT-01.
Pod::Spec.new do |s|
  s.name             = 'vwish_whisper'
  s.version          = '1.1.0'
  s.summary          = 'On-device speech recognition (whisper.cpp) for Vwish Auto captions.'
  s.description      = 'FFI plugin wrapping a small C ABI over whisper.cpp; iOS and Android only.'
  s.homepage         = 'https://vecvel.com'
  s.license          = { :type => 'Proprietary', :text => 'Copyright Vecvel; third-party notices in LICENSE-THIRD-PARTY.md' }
  s.author           = { 'Vecvel' => 'support@vecvel.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
