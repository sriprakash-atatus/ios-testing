Pod::Spec.new do |s|
  s.name         = "TestUtilities"
  s.version      = "3.15.0"
  s.summary      = "Atatus Testing Utilities. This module is for internal testing and should not be published."

  s.homepage     = "https://www.atatus.com"

  s.license            = { :type => "Apache", :file => 'LICENSE' }
  s.authors            = { "Atatus" => "info@atatus.com" }

  s.swift_version = '5.9'
  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'

  s.source = { :git => "https://github.com/Atatus/atatus-sdk-ios.git", :tag => s.version.to_s }

  s.pod_target_xcconfig = {
    'ENABLE_TESTING_SEARCH_PATHS'=>'YES'
  }

  s.framework = 'XCTest'

  s.source_files = [
    "TestUtilities/Sources/**/*.swift"
  ]

  s.dependency 'AtatusCore'
  s.dependency 'AtatusInternal'
  s.dependency 'AtatusLogs'
  s.dependency 'AtatusRUM'
  s.dependency 'AtatusSessionReplay'
  s.dependency 'AtatusTrace'
  s.dependency 'AtatusCrashReporting'
  s.dependency 'AtatusWebViewTracking'

end