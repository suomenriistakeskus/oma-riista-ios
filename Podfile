platform :ios, '10.0'
use_frameworks! :linkage => :static

$materialComponentsVersion = '~> 124.2.0'

def allPods
    pod 'AcknowList'
    pod 'Alamofire'
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
    pod 'MaterialComponents/Buttons', $materialComponentsVersion
    pod 'MaterialComponents/Buttons+Theming', $materialComponentsVersion
    pod 'MaterialComponents/Cards', $materialComponentsVersion
    pod 'MaterialComponents/Chips', $materialComponentsVersion
    pod 'MaterialComponents/Dialogs', $materialComponentsVersion
    pod 'MaterialComponents/ProgressView', $materialComponentsVersion
    pod 'MaterialComponents/TextControls+FilledTextAreas', $materialComponentsVersion
    pod 'MaterialComponents/TextControls+UnderlinedTextFields', $materialComponentsVersion
    pod 'MKNetworkKit', :inhibit_warnings => true
    pod 'MultiSelectSegmentedControl'
    pod 'OAStackView'
    pod 'OverlayContainer'
    pod 'Protobuf'
    pod 'QRCodeReader.swift'
    pod 'RMDateSelectionViewController', '~> 2.3.1'
    pod 'Siren'
    pod 'SnapKit', '~> 5.0.0'
    pod 'Tabman', '~> 2.12'
    pod 'Toast-Swift', '~> 5.0.0'
    pod 'UIImage-Resize'
end

target 'Riista' do
    allPods
end

pre_install do |installer|
  patch_kingfisher_for_ios10()
end

# let pods inherit deployment version from the project
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
        end
    end
end


# kingfisher doesn't compile for iOS10 on xcode 13 when armv7 is enabled
# fix according to https://github.com/onevcat/Kingfisher/issues/1725
def patch_kingfisher_for_ios10
  system("rm -rf ./Pods/Kingfisher/Sources/SwiftUI")
  code_file = "./Pods/Kingfisher/Sources/General/KFOptionsSetter.swift"
  code_text = File.read(code_file)
  code_text.gsub!(/#if canImport\(SwiftUI\) \&\& canImport\(Combine\)(.|\n)+#endif/,'')
  system("rm -rf " + code_file)
  aFile = File.new(code_file, 'w+')
  aFile.syswrite(code_text)
  aFile.close()
end
