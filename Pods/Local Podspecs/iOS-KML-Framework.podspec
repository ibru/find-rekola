Pod::Spec.new do |s|
  s.name         = "iOS-KML-Framework"
  s.version      = "1.0.0"
  s.summary      = "The iOS framework for parsing/generating KML files."
  s.description  = <<-DESC
                    This is a iOS framework for parsing/generating KML files.
                    This Framework parses the KML from a URL or Strings and create Objective-C Instances of KML structure. 
                   DESC
  s.homepage     = "http://kmlframework.com"
  s.screenshots  = "kmlframework.com/img/kml_viewer.png", "kmlframework.com/img/kml_logger.png"
  s.license      = 'MIT'
  s.author       = { "Watanabe Toshinori" => "t@flcl.jp" }
  s.source       = { :git => "http://FLCLjp/iOS-KML-Framework.git", :tag => s.version.to_s }

  s.platform     = :ios, '6.0'
  s.ios.deployment_target = '6.0'
  s.requires_arc = true

  s.source_files = 'Classes'
  s.resources = 'Assets'

  s.ios.framework = 'UIKit'  
  s.dependency 'TBXML', '~> 1.5'
end
