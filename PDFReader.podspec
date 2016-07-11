Pod::Spec.new do |s|
  s.name                  = "PDFReader"
  s.version               = "1.0.0"
  s.license               = { :type => "MIT" }
  s.homepage              = "https://github.com/ranunez/iOS-PDF-Reader"
  s.author                = { "Ricardo Nunez" => "ranunez@icloud.com" }
  s.summary               = "PDF Reader for iOS written in Swift"
  s.source                = { :git => "https://github.com/ranunez/iOS-PDF-Reader.git", :tag => s.version.to_s }
  s.ios.deployment_target = "9.0"
  s.source_files          = "PDFReader/Sources/*.swift"
  s.resources             = "PDFReader/Sources/*.storyboard"
  s.requires_arc          = true
end
