Pod::Spec.new do |s|
  s.name         = "AtatusLogs"
  s.version      = "3.15.0"
  s.summary      = "Atatus Logs Module."

  s.homepage     = "https://www.atatus.com"

  s.license            = { :type => "Apache", :file => 'LICENSE' }
  s.authors            = { "Atatus" => "info@atatus.com" }

  s.swift_version = '5.9'
  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'
  s.watchos.deployment_target = '7.0'
  s.visionos.deployment_target = '1.0'

  s.source = { :git => "https://github.com/Atatus/atatus-sdk-ios.git", :tag => s.version.to_s }

  s.source_files = ["AtatusLogs/Sources/**/*.swift"]

  s.dependency 'AtatusInternal', s.version.to_s

end
