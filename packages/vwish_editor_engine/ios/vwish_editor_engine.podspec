# OWNER: ENG-07 (minimal placeholder created by ENG-01's scaffold; frozen by ENG-06)
#
# Placeholder podspec so the plugin builds from M0. The platform is already iOS 15.0 (INT-01 raised
# the app target; D-29, D-43(c) owner defaults 2026-10-08, revisable). ENG-07 adds OTHER_CFLAGS
# -Werror=unguarded-availability-new, the PrivacyInfo.xcprivacy resource bundle (FileTimestamp
# C617.1, DiskSpace E174.1, SystemBootTime 35F9.1); ENG-06 the Metal CI kernel build settings. No
# bundled media resources: the spacer is generated at runtime by IOS-08.
Pod::Spec.new do |s|
  s.name             = 'vwish_editor_engine'
  s.version          = '1.1.0'
  s.summary          = 'Vwish video editor engine (AVFoundation + Core Image on Metal).'
  s.description      = 'Native preview, export and media services for the Vwish video editor.'
  s.homepage         = 'https://vecvel.com'
  s.license          = { :type => 'Proprietary', :text => 'Copyright Vecvel' }
  s.author           = { 'Vecvel' => 'support@vecvel.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  # Same as the app's IOS_DEPLOYMENT_TARGET (ios/Podfile, ARCH §3.1, D-41).
  s.platform = :ios, '15.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
