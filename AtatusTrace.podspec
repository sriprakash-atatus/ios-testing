Pod::Spec.new do |s|
  s.name         = "AtatusTrace"
  s.version      = "3.15.0"
  s.summary      = "Atatus Trace Module."

  s.homepage     = "https://www.atatus.com"

  s.license            = { :type => "Apache", :file => 'LICENSE' }
  s.authors            = { "Atatus" => "info@atatus.com" }

  s.swift_version = '6.0'
  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'
  s.watchos.deployment_target = '7.0'
  s.visionos.deployment_target = '1.0'

  s.source = { :git => "https://github.com/Atatus/atatus-sdk-ios.git", :tag => s.version.to_s }

  s.source_files = ["AtatusTrace/Sources/**/*.swift"]

  s.dependency 'AtatusInternal', s.version.to_s
  s.dependency 'OpenTelemetry-Swift-Api', '~> 2.5.0'
end
