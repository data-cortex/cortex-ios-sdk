
Pod::Spec.new do |s|
  s.name = "DataCortex"
  s.version  = "1.0.2"
  s.summary = "Data Cortex iOS SDK"
  s.description = "iOS SDK to interact with Data Cortex."
  s.homepage = "https://github.com/data-cortex/cortex-ios-sdk"
  s.license = 'MIT'
  s.author = { "Yanko Bolanos" => "y@rem7.com", "Jim Lake" => "jim@data-cortex.com" }
  s.source = { :git => "https://github.com/data-cortex/cortex-ios-sdk.git", :tag => s.version.to_s }

  s.platform = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.public_header_files = 'Pod/Classes/**/*.h'

end
