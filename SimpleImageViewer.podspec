Pod::Spec.new do |s|
  s.platform = :ios
  s.ios.deployment_target = '11.0'
  s.name = "SimpleImageViewer"
  s.summary = "A snappy image viewer with zoom and interactive dismissal transition."
  s.requires_arc = true
  s.version = "2.0"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Jonathan Sahoo" => "jsahoo@outlook.com" }
  s.homepage = "https://github.com/jsahoo/SimpleImageViewer"
  s.source = { :git => "https://github.com/jsahoo/SimpleImageViewer.git", :tag => s.version.to_s }
  s.source_files = "SimpleImageViewer/**/*.{swift}"
  s.resources = ["SimpleImageViewer/**/*.{xib}", "SimpleImageViewer/**/*.{xcassets}"]

  s.dependency 'SDWebImage', '~> 5.10'

end
