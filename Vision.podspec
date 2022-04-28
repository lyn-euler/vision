#
# Be sure to run `pod lib lint Vision.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Vision'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Vision.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/lyn-euler/vision'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lyn-euler' => 'logasync@gmail.com' }
  s.source           = { :git => 'https://github.com/lyn-euler/vision.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'
  
  s.default_subspec = 'All'
  s.swift_version = '5.0'
  s.subspec 'All' do |ss|
      ss.dependency 'Vision/Launch'
      ss.dependency 'Vision/Util'
      ss.dependency 'Vision/FPS'
      ss.dependency 'Vision/Metric'
      ss.dependency 'Vision/Zombie'
  end
  
  s.subspec 'Launch' do |ss|
      ss.source_files = ['Vision/Classes/Launch/*']
      ss.frameworks = 'Foundation'
  end
  
  s.subspec 'Util' do |ss|
      ss.source_files = [
      'Vision/Classes/Interval/*',
      'Vision/Classes/Interval/Private/*',
      'Vision/Classes/Util/*'
      ]
      ss.frameworks = 'Foundation', 'QuartzCore'
  end
  
  s.subspec 'FPS' do |ss|
      ss.source_files = ['Vision/Classes/FPS/*']
      ss.frameworks = 'Foundation', 'QuartzCore'
  end
  
  s.subspec 'Metric' do |ss|
      s.ios.deployment_target = '13.0'
    ss.source_files = 'Vision/Classes/Metric/*'
    ss.frameworks = 'MetricKit'
  end
  
  # s.resource_bundles = {
  #   'Vision' => ['Vision/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
   
  # s.dependency 'AFNetworking', '~> 2.3'
  
  s.subspec 'Zombie-Arc' do |ss|
    ss.source_files = 'Vision/Classes/Zombie/*'
    ss.frameworks = 'Foundation'
  end
  s.subspec 'Zombile-NoArc' do |ss|
    ss.source_files = 'Vision/Classes/Zombie/NoArc/*'
    ss.requires_arc = false
  end
  
  s.subspec 'Zombie' do |ss|
      ss.dependency 'Vision/Zombie-Arc'
      ss.dependency 'Vision/Zombile-NoArc'
  end
end
