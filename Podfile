platform :ios, '10.0'
use_frameworks! :linkage => :static


def allPods
    pod 'AcknowList'
    pod 'AsyncSwift'
    pod 'DifferenceKit'
    pod 'DropDown'
    pod 'Firebase/Messaging'
    pod 'Firebase/Crashlytics'
    pod 'Firebase/AnalyticsWithoutAdIdSupport'
    pod 'Firebase/RemoteConfig'
    pod 'GoogleMaps'
    pod 'Google-Maps-iOS-Utils'
    pod 'Kingfisher', '~> 6.0'
    pod 'KCOrderedAccessorFix'
    pod 'libPhoneNumber-iOS', '~> 0.8'
    pod 'M13Checkbox', '~> 1.2.0'
    pod 'MaterialComponents/Buttons'
    pod 'MaterialComponents/Buttons+Theming'
    pod 'MaterialComponents/Cards'
    pod 'MaterialComponents/Dialogs'
    pod 'MaterialComponents/TextFields'
    pod 'MaterialComponents/TextFields+Theming'
    pod 'MKNetworkKit', :inhibit_warnings => true
    pod 'OAStackView'
    pod 'OverlayContainer'
    pod 'Protobuf'
    pod 'QRCodeReader.swift'
    pod 'RMDateSelectionViewController', '~> 2.3.1'
    pod 'SnapKit', '~> 5.0.0'
    pod 'Toast-Swift', '~> 5.0.0'
    pod 'UIImage-Resize'
end

target 'Riista' do
    allPods
end

# let pods inherit deployment version from the project
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
        end
    end
end
