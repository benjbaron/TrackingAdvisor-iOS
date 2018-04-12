# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'TrackingAdvisor' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # Pods for TrackingAdvisor
  pod "Fuse"
  pod 'Alamofire', '~> 4.6'
  pod 'Eureka', '~> 4.0'
  pod 'Mapbox-iOS-SDK', '~> 3.7'
  pod 'Cosmos', '~> 15.0'

  target 'TrackingAdvisorTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'TrackingAdvisorUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        
        if  target.name == 'Eureka'
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
        end
    end
end
