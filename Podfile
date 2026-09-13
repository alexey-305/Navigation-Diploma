platform :ios, '13.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
    end
  end
end

target 'Navigation' do
  use_frameworks!
  
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'RealmSwift'

  target 'NavigationTests' do
    inherit! :search_paths
  end
end
