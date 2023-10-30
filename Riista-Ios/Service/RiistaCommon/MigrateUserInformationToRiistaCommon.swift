import Foundation
import Async
import RiistaCommon


class MigrateUserInformationToRiistaCommon {
    private static let logger = AppLogger(for: MigrateUserInformationToRiistaCommon.self, printTimeStamps: true)

    /**
     * Schedules the user information migration to be performed.
     */
    class func scheduleMigration() {
        // Don't migrate immediately but instead give few seconds for the login to succeed. The reasons for this are
        // - application side user info does not contain all data (e.g. unregisterDateTime is missing)
        // - we don't have access to raw json which could then be deserialized to UserInfoDTO. It is therefore
        //   possible that some part of the manual conversion fails (even though it has been manually tested)
        //   which could possibly cause app to crash continuously.
        //
        // By delaying we at least try to mitigate above mentioned issues

        logger.v { "Scheduling user information migration in few seconds.." }
        Async.main(after: 5) {
            migrateUserInformation()
        }
    }

    private class func migrateUserInformation() {
        if (RiistaSDK.shared.currentUserContext.userInformation != nil) {
            // there's already user information. Since it can only be for the current user (it is cleared upon logout)
            // there's nothing we need to do
            logger.v { "RiistaSDK already contains user information, not attempting to migrate." }
            return
        }
        // cannot use userInfo().dictionaryRepresentation() and convert that to json as all the dates in the
        // dictionary are in incorrect format and there's an exception.
        guard let userInfo = RiistaSettings.userInfo() else {
            logger.v { "No user information, not attempting to migrate." }
            return
        }

        logger.v { "Starting user information migration to common lib.."}

        let userInfoDTO = userInfo.toUserInfoDTO()
        RiistaSDK.shared.currentUserContext.migrateUserInformationFromApplication(userInfo: userInfoDTO) { result, _ in
            logger.v { "User info migration result: \(result)"}
        }
    }
}

fileprivate extension UserInfo {
    func toUserInfoDTO() -> UserInfoDTO {
        return UserInfoDTO(
            username: self.username,
            personId: nil, // data not available
            firstName: self.firstName,
            lastName: self.lastName,
            unregisterRequestedTime: nil, // data not available
            birthDate: self.birthDate?.toLocalDate().toStringISO8601(),
            address: self.address?.toAddressDTO(),
            homeMunicipality: localizedStringFrom(self.homeMunicipality),
            rhy: self.rhy?.toOrganizationDTO(),
            hunterNumber: self.hunterNumber,
            hunterExamDate: self.hunterExamDate?.toLocalDate().toStringISO8601(),
            huntingCardStart: self.huntingCardStart?.toLocalDate().toStringISO8601(),
            huntingCardEnd: self.huntingCardEnd?.toLocalDate().toStringISO8601(),
            huntingBanStart: self.huntingBanStart?.toLocalDate().toStringISO8601(),
            huntingBanEnd: self.huntingBanEnd?.toLocalDate().toStringISO8601(),
            huntingCardValidNow: self.huntingCardValidNow,
            qrCode: self.qrCode,
            timestamp: self.timestamp,
            shootingTests: self.shootingTests?.compactMap { shootingTest in
                (shootingTest as? Oma_riista.ShootingTest)?.toShootingTestDTO()
            } ?? [],
            occupations: self.occupations?.compactMap { occupation in
                (occupation as? Oma_riista.Occupation)?.toOccupationDTO()
            } ?? [],
            enableSrva: self.enableSrva?.boolValue ?? false,
            enableShootingTests: self.enableShootingTests?.boolValue ?? false,
            deerPilotUser: self.deerPilotUser
        )
    }


}

fileprivate extension Oma_riista.Address {
    func toAddressDTO() -> AddressDTO {
        return AddressDTO(
            id: Int64(self.addressIdentifier),
            rev: Int32(self.rev),
            editable: self.editable,
            streetAddress: self.streetAddress,
            postalCode: self.postalCode,
            city: self.city,
            country: self.country
        )
    }
}

fileprivate extension Rhy {
    func toOrganizationDTO() -> OrganizationDTO {
        return OrganizationDTO(
            id: Int64(self.rhyIdentifier),
            name: localizedStringFrom(self.name),
            officialCode: self.officialCode ?? ""
        )
    }
}

fileprivate extension Organisation {
    func toOrganizationDTO() -> OrganizationDTO? {
        guard let organizationId = self.organisationIdentifier?.int64Value else {
            return nil
        }

        return OrganizationDTO(
            id: organizationId,
            name: localizedStringFrom(self.name),
            officialCode: self.officialCode ?? ""
        )
    }
}

fileprivate extension Oma_riista.ShootingTest {
    func toShootingTestDTO() -> ShootingTestDTO? {
        guard let shootingTestType = self.type,
              let beginDate = self.begin,
              let endDate = self.end else {
            // should not happen but it is better to ignore these than to crash
            return nil
        }

        return ShootingTestDTO(
            rhyCode: self.officialCode,
            rhyName: self.rhyName,
            type: shootingTestType,
            typeName: nil, // data not available
            begin: beginDate,
            end: endDate,
            expired: self.expired
        )
    }
}

fileprivate extension Oma_riista.Occupation {
    func toOccupationDTO() -> OccupationDTO? {
        guard let occupationId = self.occupationId?.int64Value,
              let occupationType = self.occupationType,
              let organizationDTO = self.organisation?.toOrganizationDTO() else {
            // should not happen but it is better to ignore these than to crash
            return nil
        }

        return OccupationDTO(
            id: occupationId,
            occupationType: occupationType,
            name: localizedStringFrom(self.name),
            beginDate: self.beginDate?.toLocalDate().toStringISO8601(),
            endDate: self.endDate?.toLocalDate().toStringISO8601(),
            organisation: organizationDTO
        )
    }
}

fileprivate func localizedStringFrom(_ hashable: [AnyHashable: Any]?) -> LocalizedStringDTO {
    guard let hashable = hashable else {
        return LocalizedStringDTO(fi: nil, sv: nil, en: nil)
    }

    return LocalizedStringDTO(
        fi: hashable["fi"] as? String,
        sv: hashable["sv"] as? String,
        en: hashable["en"] as? String
    )
}
