import Foundation
import RiistaCommon

class CurrentLanguageProvider: RiistaCommon.LanguageProvider {
    func getCurrentLanguage() -> Language {
        var language: Language?
        if let languageCode = RiistaSettings.language() {
            language = Language.companion.fromLanguageCode(languageCode: languageCode)
        }

        return language ?? AppConstants.defaultLanguage
    }

    func setCurrentLanguage(language: Language) {
        RiistaSettings.setLanguageSetting(language.languageCode)

        RiistaLocalization.sharedInstance().setLanguageFromSettings()
    }
}
