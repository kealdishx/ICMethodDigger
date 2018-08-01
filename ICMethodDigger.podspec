Pod::Spec.new do |s|
  s.name         = "ICMethodDigger"
  s.version      = "1.0.1"
  s.summary      = "An easy way to print almost methods including private methods (supported arm64 architecture devices)."
  s.homepage     = "https://github.com/iiiCeBlink/ICMethodDigger"
  s.license      = "MIT"
  s.author       = { "iiiCeBlink" => "zakariyyasv@gmail.com" }
  s.source       = { :git => "https://github.com/iiiCeBlink/ICMethodDigger.git", :tag => '1.0.1'}
  s.source_files = "ICMethodDigger/Source/*.{h,m,s}", "ICMethodDigger/Source/PublicHeader/*.h"
  s.module_name  = "ICMethodDigger"
  s.private_header_files = "ICMethodDigger/Source/*.h"
  s.requires_arc = true
  s.frameworks   = 'UIKit', 'Foundation'
  s.platform     = :ios, '8.0'

end