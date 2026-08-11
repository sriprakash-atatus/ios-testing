Pod::Spec.new do |s|
  s.name         = "AtatusProfiling"
  s.version      = "3.15.0"
  s.summary      = "Official Atatus Profiling module of the Swift SDK."
  
  s.homepage     = "https://www.atatus.com"

  s.license            = { :type => "Apache", :file => 'LICENSE' }
  s.authors            = "Atatus, Inc."

  s.swift_version = '5.9'
  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'
  s.visionos.deployment_target = '1.0'

  s.source = { :git => "https://github.com/Atatus/atatus-sdk-ios.git", :tag => s.version.to_s }
  
  s.source_files = ["AtatusProfiling/Sources/**/*.swift",
                    "AtatusProfiling/Mach/**/*.{h,c,cpp}"]
  
  s.private_header_files = ["AtatusProfiling/Mach/**/*.h"]

  s.preserve_paths = "AtatusProfiling/Mach/include/module.modulemap"

  s.dependency 'AtatusInternal', s.version.to_s

  # Configure C++ compilation
  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/AtatusProfiling/Mach/include'
  }

end
