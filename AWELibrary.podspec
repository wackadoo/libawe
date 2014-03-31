Pod::Spec.new do |s|
  s.name             = "AWELibrary"
  s.version          = "0.0.1"
  s.summary          = "Client-Side library for the Augmented World Engine"
  s.description      = <<-DESC
                       Client-Side library for the Augmented World Engine
                       DESC
  s.homepage         = "http://www.5dlab.com"
  s.license          = 'MIT'
  s.author           = { "Kevin Steinle" => "Kevin@5dlab.com" }
  s.source           = { :git => "https://github.com/wackadoo/libawe.git", :tag => "0.0.1" }

  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.source_files = 'Classes/ios/*.{h,m}'
  
  s.ios.exclude_files = 'Classes/osx'
  s.osx.exclude_files = 'Classes/ios'
  # s.public_header_files = 'Classes/**/*.h'
  # s.frameworks = 'SomeFramework', 'AnotherFramework'
  # s.dependency 'JSONKit', '~> 1.4'
end
