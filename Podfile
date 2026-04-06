platform :ios, '26.0'

target 'GlowDash' do
  use_frameworks!

  # Google Mobile Ads SDK (includes UMP consent SDK)
  # Check https://developers.google.com/admob/ios/download for latest version
  pod 'Google-Mobile-Ads-SDK', '~> 11.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '26.0'
    end
  end
end
