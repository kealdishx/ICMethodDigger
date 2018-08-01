Pod::Spec.new do |s|
  s.name         = "ICMethodDigger"
  s.version      = "1.0.0"
  s.summary      = "An easy way to print almost methods including private methods (supported arm64 architecture devices)."
  s.homepage     = "https://github.com/iiiCeBlink/ICMethodDigger"
  s.license      = "MIT"
  s.author       = { "iiiCeBlink" => "zakariyyasv@gmail.com" }
  s.source       = { :git => "https://github.com/iiiCeBlink/ICMethodDigger.git"}
  s.source_files = "ICMethodDigger/Source/*.{h,m,s}", "ICMethodDigger/Source/PublicHeader/*.h"
  s.module_name  = "ICMethodDigger"
  s.private_header_files = "ICMethodDigger/Source/*.h"
  s.requires_arc = true
  s.frameworks   = 'UIKit', 'Foundation'
  s.platform     = :ios, '8.0'

 # other_frameworks =  ['UIKit', 'Foundation']
  
 # other_ldflags = '$(inherited) -framework ' + other_frameworks.join(' -framework ') + 
    ' -lz -lstdc++'

 # s.xcconfig     = {  'OTHER_LDFLAGS[arch=arm64]'  => other_ldflags, 'NATIVE_ARCH' => '"arm64"', 'CURRENT_ARCH' => '"arm64"', 'VALID_ARCHS' => '"arm64"'}

end