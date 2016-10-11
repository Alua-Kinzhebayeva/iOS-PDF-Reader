Pod::Spec.new do |s|
  s.name                  = "PDFReader"
  s.version               = "1.1.1"
  s.license               = { :type => "MIT" }
  s.homepage              = "https://github.com/Alua-Kinzhebayeva/iOS-PDF-Reader"
  s.author                = { "Alua Kinzhebayeva" => "alua.kinzhebayeva@gmail.com" }
  s.summary               = "PDF Reader for iOS written in Swift"
  s.source                = { :git => "https://github.com/Alua-Kinzhebayeva/iOS-PDF-Reader.git", :tag => s.version.to_s }
  s.ios.deployment_target = "9.0"
  s.source_files          = "Sources/Classes/*.swift"
  s.resources             = "Sources/Assets/*.storyboard"
  s.requires_arc          = true
end
