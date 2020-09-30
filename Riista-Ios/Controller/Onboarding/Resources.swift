import Foundation
import UIKit

struct Resources {

    static let bundle: Bundle = {
        var bundle = Bundle(for: OnboardingImageCell.self)
        let bundleURL = bundle.url(forResource: "OnboardingImageCell", withExtension: "bundle")
        if let bundleURL = bundleURL {
            bundle = Bundle(url: bundleURL)!
        }
        return bundle
    }()

    static let landingBundle: Bundle = {
        var bundle = Bundle(for: OnboardingLandingCell.self)
        let bundleURL = bundle.url(forResource: "OnboardingLandingCell", withExtension: "bundle")
        if let bundleURL = bundleURL {
            bundle = Bundle(url: bundleURL)!
        }
        return bundle
    }()

}
